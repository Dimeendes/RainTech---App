import '../core/theme/app_theme.dart';

/// Textos em linguagem simples para o cidadão, por nível de risco.
/// Evitam números técnicos e não prometem medidas que só a concessionária pode decidir.
class OrientacaoCidadao {
  const OrientacaoCidadao({
    required this.situacao,
    required this.titulo,
    required this.resumo,
    required this.oQueFazer,
    required this.risco,
  });

  /// Rótulo curto da situação (Normal, Atenção, Alerta, Crítico).
  final String situacao;
  final String titulo;
  final String resumo;
  final List<String> oQueFazer;
  final RiskLevel risco;

  static OrientacaoCidadao paraNivel(String? nivel) => switch (nivel) {
    'CRITICO' => critico,
    'ALERTA' => alerta,
    'ATENCAO' => atencao,
    _ => normal,
  };

  /// Nível pelo volume observado (faixas ANA/DAEE 925/2017): é um fato, não uma previsão.
  static String nivelPorVolume(double volume) {
    if (volume < 30) return 'CRITICO';
    if (volume < 40) return 'ALERTA';
    if (volume < 60) return 'ATENCAO';
    return 'NORMAL';
  }

  static const normal = OrientacaoCidadao(
    situacao: 'Normal',
    titulo: 'Abastecimento sem risco no momento',
    resumo: 'O reservatório está em nível adequado. Continue usando a água com consciência.',
    oQueFazer: [
      'Mantenha a caixa-d\'água tampada e limpa.',
      'Conserte vazamentos assim que perceber.',
    ],
    risco: RiskLevel.low,
  );

  static const atencao = OrientacaoCidadao(
    situacao: 'Atenção',
    titulo: 'Hora de economizar água',
    resumo:
        'O nível do reservatório está abaixo do ideal ou pode cair nos próximos meses. '
        'Economizar agora ajuda a evitar restrições mais adiante.',
    oQueFazer: [
      'Banhos mais curtos e torneira fechada ao escovar os dentes.',
      'Junte roupas para lavar de uma vez e reutilize a água da máquina na limpeza.',
      'Verifique se há vazamentos em torneiras, descargas e canos.',
    ],
    risco: RiskLevel.medium,
  );

  static const alerta = OrientacaoCidadao(
    situacao: 'Alerta',
    titulo: 'Risco de falta d\'água',
    resumo:
        'A gestão confirmou risco de nível baixo no reservatório. Pode haver redução de pressão '
        'em alguns horários. Reduza o consumo e prepare-se com segurança.',
    oQueFazer: [
      'Reduza o consumo ao essencial: beber, cozinhar e higiene.',
      'Se guardar água, use recipientes limpos e bem tampados (evita o mosquito da dengue).',
      'Combine com vizinhos e familiares como ajudar idosos e pessoas com mobilidade reduzida.',
      'Acompanhe os comunicados oficiais da Sabesp e da prefeitura.',
    ],
    risco: RiskLevel.high,
  );

  static const critico = OrientacaoCidadao(
    situacao: 'Crítico',
    titulo: 'Nível crítico do reservatório',
    resumo:
        'O reservatório está em nível crítico. Siga as orientações oficiais e priorize a água '
        'para beber, cozinhar e higiene.',
    oQueFazer: [
      'Priorize a água para beber, cozinhar e higiene pessoal.',
      'Mantenha toda água guardada tampada; troque a água de reserva com frequência.',
      'Não use água de fontes desconhecidas para beber sem tratamento.',
      'Em emergência, ligue para a Defesa Civil: 199.',
    ],
    risco: RiskLevel.high,
  );
}
