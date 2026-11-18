// Cliente da API REST do HidroData (projeto Java de POO).
// Endereço padrão: http://localhost:8080/api (Windows, Chrome/Edge).
// Para outro endereço:  flutter run --dart-define=HIDRODATA_URL=http://10.0.2.2:8080/api
//   (10.0.2.2 = emulador Android; no celular físico use o IP do computador)

import 'dart:convert';

import 'package:http/http.dart' as http;

class HidrodataApi {
  HidrodataApi({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? const String.fromEnvironment(
        'HIDRODATA_URL',
        defaultValue: 'http://localhost:8080/api',
      ),
      _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  static const _timeout = Duration(seconds: 8);

  Future<List<dynamic>> reservatorios() async =>
      await _get('/reservatorios') as List<dynamic>;

  Future<List<dynamic>> historico(int sensorId) async =>
      await _get('/reservatorios/$sensorId/historico') as List<dynamic>;

  Future<List<dynamic>> alertas({int limite = 200}) async =>
      await _get('/alertas?limite=$limite') as List<dynamic>;

  /// Avança um mês: lê os sensores, roda as previsões e grava os alertas.
  Future<Map<String, dynamic>> executarCiclo() async =>
      await _send(_client.post(Uri.parse('$baseUrl/ciclos')))
          as Map<String, dynamic>;

  /// Validação humana. Lança [ApiException] com a mensagem do servidor
  /// (ex.: justificativa curta -> 400, alerta já validado -> 409).
  Future<Map<String, dynamic>> validarAlerta({
    required int alertaId,
    required bool aprovado,
    required String responsavel,
    required String justificativa,
  }) async {
    final corpo = jsonEncode({
      'decisao': aprovado ? 'APROVADO' : 'REJEITADO',
      'responsavel': responsavel,
      'justificativa': justificativa,
    });
    return await _send(
          _client.post(
            Uri.parse('$baseUrl/alertas/$alertaId/validacao'),
            headers: {'Content-Type': 'application/json'},
            body: corpo,
          ),
        )
        as Map<String, dynamic>;
  }

  Future<dynamic> _get(String caminho) =>
      _send(_client.get(Uri.parse('$baseUrl$caminho')));

  Future<dynamic> _send(Future<http.Response> requisicao) async {
    final resposta = await requisicao.timeout(_timeout);
    final corpo = resposta.bodyBytes.isEmpty
        ? null
        : jsonDecode(utf8.decode(resposta.bodyBytes));
    if (resposta.statusCode >= 400) {
      final mensagem = (corpo is Map && corpo['erro'] != null)
          ? corpo['erro'] as String
          : 'Erro ${resposta.statusCode} na API do HidroData.';
      throw ApiException(resposta.statusCode, mensagem);
    }
    return corpo;
  }
}

class ApiException implements Exception {
  ApiException(this.status, this.mensagem);

  final int status;
  final String mensagem;

  @override
  String toString() => mensagem;
}
