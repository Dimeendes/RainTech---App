import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/app_storage.dart';
import '../data/hidrodata_api.dart';
import '../models/manancial.dart';

enum ConexaoHidrodata { carregando, conectado, indisponivel }

/// Estado da integração com o HidroData (Java): reservatórios, histórico,
/// alertas do modelo e decisões do gestor.
class MananciaisState extends ChangeNotifier {
  /// [intervalo]: de quanto em quanto tempo o app consulta o HidroData em busca
  /// de alertas novos (inclusive os gerados pelo menu do Java). null = não consulta.
  MananciaisState(
    this._api, {
    AppStorage? storage,
    Duration? intervalo = const Duration(seconds: 15),
  }) : _storage = storage {
    if (intervalo != null) {
      _consultaPeriodica = Timer.periodic(intervalo, (_) {
        if (!_buscando && !_avancando) carregar();
      });
    }
  }

  HidrodataApi _api;
  final AppStorage? _storage;
  Timer? _consultaPeriodica;
  bool _buscando = false;

  // Alertas já vistos: só os que aparecerem depois da primeira carga geram aviso
  final Set<int> _idsConhecidos = {};
  bool _primeiraCarga = true;
  List<AlertaHidrodata> _novosAlertas = const [];
  int _versaoNovosAlertas = 0;

  /// Alertas pendentes que chegaram na última atualização.
  List<AlertaHidrodata> get novosAlertas => _novosAlertas;

  /// Muda a cada lote de alertas novos (usado para disparar a notificação uma vez só).
  int get versaoNovosAlertas => _versaoNovosAlertas;

  @override
  void dispose() {
    _consultaPeriodica?.cancel();
    super.dispose();
  }

  ConexaoHidrodata _conexao = ConexaoHidrodata.carregando;
  String? _erro;
  bool _avancando = false;
  List<Manancial> _mananciais = const [];
  Map<int, List<PontoHistorico>> _historicos = const {};
  List<AlertaHidrodata> _alertas = const [];

  ConexaoHidrodata get conexao => _conexao;
  String? get erro => _erro;
  bool get avancando => _avancando;
  String get enderecoApi => _api.baseUrl;
  List<Manancial> get mananciais => _mananciais;
  List<Manancial> get lidos => _mananciais.where((m) => m.foiLido).toList();
  List<PontoHistorico> historicoDe(int sensorId) => _historicos[sensorId] ?? const [];

  /// Só os alertas dos reservatórios (os sensores de rede do Java ficam de fora).
  List<AlertaHidrodata> get pendentes =>
      _alertas.where((a) => a.ehReservatorio && a.pendente).toList();
  List<AlertaHidrodata> get validados =>
      _alertas.where((a) => a.ehReservatorio && !a.pendente).toList();

  AlertaHidrodata? alertaPorId(int id) =>
      _alertas.where((a) => a.id == id).firstOrNull;

  Future<void> carregar() async {
    _buscando = true;
    _erro = null;
    if (_mananciais.isEmpty) {
      _conexao = ConexaoHidrodata.carregando;
      notifyListeners();
    }
    try {
      final mananciais = (await _api.reservatorios())
          .map((j) => Manancial.fromJson(j as Map<String, dynamic>))
          .toList();
      final historicos = <int, List<PontoHistorico>>{};
      for (final m in mananciais.where((m) => m.foiLido)) {
        historicos[m.sensorId] = (await _api.historico(m.sensorId))
            .map((j) => PontoHistorico.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      final alertas = (await _api.alertas())
          .map((j) => AlertaHidrodata.fromJson(j as Map<String, dynamic>))
          .toList();

      _mananciais = mananciais;
      _historicos = historicos;
      _alertas = alertas;
      _conexao = ConexaoHidrodata.conectado;
      _detectarNovos(alertas);
    } on Object catch (e) {
      _conexao = ConexaoHidrodata.indisponivel;
      _erro = _mensagem(e);
    } finally {
      _buscando = false;
    }
    notifyListeners();
  }

  /// Troca o endereço da API (ex.: IP do computador na rede Wi-Fi), salva e testa.
  /// Retorna a mensagem de erro, ou null se conectou.
  Future<String?> alterarEndereco(String endereco) async {
    final url = endereco.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
      return 'Endereço inválido. Exemplo: http://192.168.0.10:8080/api';
    }
    _api = HidrodataApi(baseUrl: url);
    await _storage?.setHidrodataUrl(url);
    _mananciais = const [];
    _historicos = const {};
    _alertas = const [];
    _idsConhecidos.clear();
    _primeiraCarga = true;
    await carregar();
    return _conexao == ConexaoHidrodata.conectado ? null : _erro;
  }

  /// Avança um mês na série real. Retorna a mensagem de erro, ou null se deu certo.
  Future<String?> avancarMes() async {
    if (_avancando) return null;
    _avancando = true;
    notifyListeners();
    try {
      await _api.executarCiclo();
      await carregar();
      return _erro;
    } on Object catch (e) {
      return _mensagem(e);
    } finally {
      _avancando = false;
      notifyListeners();
    }
  }

  /// Envia a decisão do gestor. Retorna a mensagem de erro, ou null se deu certo.
  Future<String?> validar({
    required int alertaId,
    required bool aprovado,
    required String responsavel,
    required String justificativa,
  }) async {
    try {
      await _api.validarAlerta(
        alertaId: alertaId,
        aprovado: aprovado,
        responsavel: responsavel.trim(),
        justificativa: justificativa.trim(),
      );
      await carregar();
      return null;
    } on Object catch (e) {
      return _mensagem(e);
    }
  }

  void _detectarNovos(List<AlertaHidrodata> alertas) {
    final novos = alertas
        .where((a) => a.ehReservatorio && a.pendente && !_idsConhecidos.contains(a.id))
        .toList();
    _idsConhecidos.addAll(alertas.map((a) => a.id));
    if (_primeiraCarga) {
      _primeiraCarga = false; // alertas antigos não geram aviso ao abrir o app
      return;
    }
    if (novos.isNotEmpty) {
      _novosAlertas = novos;
      _versaoNovosAlertas++;
    }
  }

  String _mensagem(Object e) {
    if (e is ApiException) return e.mensagem;
    final texto = e.toString();
    if (texto.contains('SocketException') ||
        texto.contains('ClientException') ||
        texto.contains('TimeoutException') ||
        texto.contains('XMLHttpRequest') ||
        texto.contains('Failed to fetch')) {
      return 'Não foi possível conectar ao HidroData em $enderecoApi. '
          'Verifique se o projeto Java está rodando (mvn spring-boot:run).';
    }
    return texto;
  }
}
