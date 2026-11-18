import '../core/theme/app_theme.dart';

/// Modelos dos dados que chegam da API do HidroData.

double? _numero(Object? valor) => valor == null ? null : (valor as num).toDouble();

/// Nível de risco vindo do Java: NORMAL, ATENCAO, ALERTA ou CRITICO.
String rotuloNivel(String? nivel) => switch (nivel) {
  'CRITICO' => 'Crítico',
  'ALERTA' => 'Alerta',
  'ATENCAO' => 'Atenção',
  'NORMAL' => 'Normal',
  _ => 'Sem dado',
};

RiskLevel riscoDoNivel(String? nivel) => switch (nivel) {
  'CRITICO' || 'ALERTA' => RiskLevel.high,
  'ATENCAO' => RiskLevel.medium,
  _ => RiskLevel.low,
};

/// Nome do sistema produtor de um sensor do HidroData.
String nomeSistema(int sensorId) => switch (sensorId) {
  5 => 'Cantareira',
  6 => 'Alto Tietê',
  _ => 'Sensor $sensorId',
};

/// Situação atual de um sistema produtor (GET /api/reservatorios).
class Manancial {
  const Manancial({
    required this.sensorId,
    required this.sistema,
    required this.status,
    this.mesReferencia,
    this.volumeUtil,
    this.probRisco3m,
    this.nivel,
    this.origem,
    this.confiancaNivel,
    this.confiancaTexto,
    this.explicacao,
    this.indicadores = const {},
    this.aviso,
  });

  final int sensorId;
  final String sistema;
  final String status;
  final String? mesReferencia;

  /// Volume útil em % (0 a 100).
  final double? volumeUtil;

  /// Probabilidade (%) de o volume ficar abaixo de 40% em 3 meses.
  final double? probRisco3m;
  final String? nivel;

  /// VOLUME (situação observada) ou MODELO (antecipado pela previsão).
  final String? origem;
  final String? confiancaNivel;
  final String? confiancaTexto;
  final String? explicacao;
  final Map<String, double?> indicadores;

  /// Preenchido quando ainda não há leitura (antes do primeiro ciclo).
  final String? aviso;

  bool get foiLido => mesReferencia != null && volumeUtil != null;
  bool get antecipadoPeloModelo => origem == 'MODELO';

  /// Valor de 0 a 1 para o [ConfidenceMeter] do app.
  double get confiancaValor => confiancaNivel == 'ALTA' ? 0.9 : 0.6;
  String get confiancaRotulo => confiancaNivel == 'ALTA' ? 'Alta' : 'Moderada';

  factory Manancial.fromJson(Map<String, dynamic> json) {
    final confianca = json['confianca'] as Map<String, dynamic>?;
    final indicadores = json['indicadores'] as Map<String, dynamic>?;
    return Manancial(
      sensorId: json['sensorId'] as int,
      sistema: json['sistema'] as String,
      status: json['status'] as String,
      mesReferencia: json['mesReferencia'] as String?,
      volumeUtil: _numero(json['volumeUtil']),
      probRisco3m: _numero(json['probRisco3m']),
      nivel: json['nivel'] as String?,
      origem: json['origem'] as String?,
      confiancaNivel: confianca?['nivel'] as String?,
      confiancaTexto: confianca?['texto'] as String?,
      explicacao: json['explicacao'] as String?,
      indicadores: indicadores == null
          ? const {}
          : indicadores.map((chave, valor) => MapEntry(chave, _numero(valor))),
      aviso: json['aviso'] as String?,
    );
  }
}

/// Um mês da série (GET /api/reservatorios/{id}/historico).
class PontoHistorico {
  const PontoHistorico({
    required this.mes,
    required this.volumeUtil,
    required this.probRisco3m,
    this.anomChuva6m,
    this.anomVazao3m,
    this.pressao3m,
    this.tendencia3m,
    this.autonomiaMeses,
  });

  final DateTime mes;
  final double volumeUtil;
  final double probRisco3m;

  /// Chuva dos últimos 6 meses vs. média histórica (%).
  final double? anomChuva6m;

  /// Vazão natural dos últimos 3 meses vs. típico do mês (%).
  final double? anomVazao3m;

  /// Captação ÷ vazão natural (acima de 1 = retira mais do que recebe).
  final double? pressao3m;

  /// Variação do volume em 3 meses (pontos percentuais).
  final double? tendencia3m;

  /// Meses de abastecimento com o volume atual.
  final double? autonomiaMeses;

  factory PontoHistorico.fromJson(Map<String, dynamic> json) => PontoHistorico(
    mes: DateTime.parse('${json['mes']}-01'),
    volumeUtil: (json['volumeUtil'] as num).toDouble(),
    probRisco3m: (json['probRisco3m'] as num).toDouble(),
    anomChuva6m: _numero(json['anomChuva6m']),
    anomVazao3m: _numero(json['anomVazao3m']),
    pressao3m: _numero(json['pressao3m']),
    tendencia3m: _numero(json['tendencia3m']),
    autonomiaMeses: _numero(json['autonomiaMeses']),
  );
}

/// Decisão do gestor registrada no HidroData.
class ValidacaoHidrodata {
  const ValidacaoHidrodata({
    required this.aprovado,
    required this.responsavel,
    required this.justificativa,
    required this.dataHora,
  });

  final bool aprovado;
  final String responsavel;
  final String justificativa;
  final DateTime dataHora;

  factory ValidacaoHidrodata.fromJson(Map<String, dynamic> json) =>
      ValidacaoHidrodata(
        aprovado: json['decisao'] == 'APROVADO',
        responsavel: json['responsavel'] as String,
        justificativa: json['justificativa'] as String,
        dataHora: DateTime.parse(json['dataHora'] as String),
      );
}

/// Alerta gravado no HidroData (GET /api/alertas).
class AlertaHidrodata {
  const AlertaHidrodata({
    required this.id,
    required this.sensorId,
    required this.tipoSensor,
    required this.nivel,
    required this.valorPrevisto,
    required this.mensagem,
    required this.dataHora,
    this.validacao,
  });

  final int id;
  final int sensorId;
  final String tipoSensor;
  final String nivel;
  final double valorPrevisto;
  final String mensagem;
  final DateTime dataHora;
  final ValidacaoHidrodata? validacao;

  bool get pendente => validacao == null;
  bool get aprovado => validacao?.aprovado ?? false;

  /// Mês dos dados que geraram o alerta (ex.: 2025-06), lido da mensagem do HidroData.
  String? get mesReferencia => RegExp(r' em (\d{4}-\d{2})').firstMatch(mensagem)?.group(1);

  /// Mês de referência no formato 06/2025.
  String? get mesReferenciaFormatado {
    final mes = mesReferencia;
    return mes == null ? null : '${mes.substring(5, 7)}/${mes.substring(0, 4)}';
  }
  bool get ehReservatorio => tipoSensor == 'RESERVATORIO';

  factory AlertaHidrodata.fromJson(Map<String, dynamic> json) {
    final validacao = json['validacao'] as Map<String, dynamic>?;
    return AlertaHidrodata(
      id: json['id'] as int,
      sensorId: json['sensorId'] as int,
      tipoSensor: json['tipoSensor'] as String,
      nivel: json['nivel'] as String,
      valorPrevisto: (json['valorPrevisto'] as num).toDouble(),
      mensagem: json['mensagem'] as String,
      dataHora: DateTime.parse(json['dataHora'] as String),
      validacao: validacao == null ? null : ValidacaoHidrodata.fromJson(validacao),
    );
  }
}
