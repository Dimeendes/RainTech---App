import 'package:flutter/material.dart';

import '../data/app_storage.dart';

/// Para quem o app está sendo usado.
enum PerfilUsuario {
  cidadao(
    'Cidadão',
    'Situação da água em linguagem simples e avisos confirmados pela gestão, com orientações de preparo.',
  ),
  gestor(
    'Gestor',
    'Painéis técnicos, previsões do modelo e validação dos alertas antes de chegarem à população.',
  );

  const PerfilUsuario(this.rotulo, this.descricao);
  final String rotulo;
  final String descricao;
}

/// Qual conjunto de dados o app mostra.
enum VisaoDados {
  rmsp('RMSP (Sabesp)', 'Dados reais de Cantareira e Alto Tietê via HidroData (Java).'),
  chennai('Chennai, Índia', 'Demonstração com a base pública de reservatórios de Chennai.');

  const VisaoDados(this.rotulo, this.descricao);
  final String rotulo;
  final String descricao;
}

/// Preferências de aparência e acessibilidade, persistidas localmente.
class SettingsState extends ChangeNotifier {
  SettingsState(this._storage) {
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == _storage.themeMode,
      orElse: () => ThemeMode.light,
    );
    _highContrast = _storage.highContrast;
    _fontScale = _storage.fontScale.clamp(minFontScale, maxFontScale);
    _visao = VisaoDados.values.firstWhere(
      (visao) => visao.name == _storage.visao,
      orElse: () => VisaoDados.rmsp,
    );
    _notificacoesSistema = _storage.notificacoesSistema;
    _perfil = PerfilUsuario.values.firstWhere(
      (perfil) => perfil.name == _storage.perfil,
      orElse: () => PerfilUsuario.cidadao,
    );
  }

  static const minFontScale = 0.85;
  static const maxFontScale = 1.5;

  final AppStorage _storage;
  late ThemeMode _themeMode;
  late bool _highContrast;
  late double _fontScale;
  late VisaoDados _visao;
  late bool _notificacoesSistema;
  late PerfilUsuario _perfil;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get highContrast => _highContrast;
  double get fontScale => _fontScale;
  VisaoDados get visao => _visao;
  PerfilUsuario get perfil => _perfil;
  bool get ehCidadao => _perfil == PerfilUsuario.cidadao;

  /// Notificações do sistema operacional (pelo navegador) para novos alertas.
  bool get notificacoesSistema => _notificacoesSistema;

  Future<void> setDarkMode(bool enabled) async {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _storage.setThemeMode(_themeMode.name);
  }

  Future<void> setHighContrast(bool enabled) async {
    _highContrast = enabled;
    notifyListeners();
    await _storage.setHighContrast(enabled);
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(minFontScale, maxFontScale);
    notifyListeners();
    await _storage.setFontScale(_fontScale);
  }

  Future<void> setVisao(VisaoDados visao) async {
    if (visao == _visao) return;
    _visao = visao;
    notifyListeners();
    await _storage.setVisao(visao.name);
  }

  Future<void> setNotificacoesSistema(bool ativar) async {
    _notificacoesSistema = ativar;
    notifyListeners();
    await _storage.setNotificacoesSistema(ativar);
  }

  Future<void> setPerfil(PerfilUsuario perfil) async {
    if (perfil == _perfil) return;
    _perfil = perfil;
    notifyListeners();
    await _storage.setPerfil(perfil.name);
  }
}
