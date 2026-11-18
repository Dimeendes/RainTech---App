import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/manancial.dart';
import '../../state/mananciais_state.dart';
import '../../widgets/charts/chart_card.dart';
import '../../widgets/charts/trend_line_chart.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/rmsp_estado.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';

/// Painéis da visão RMSP: reservatórios, chuva/vazão e captação/autonomia.
class RmspDashboardsPage extends StatelessWidget {
  const RmspDashboardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painéis • RMSP'),
          actions: [
            IconButton(
              tooltip: 'Atualizar dados',
              onPressed: context.read<MananciaisState>().carregar,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.water), text: 'Reservatórios'),
              Tab(icon: Icon(Icons.grain), text: 'Chuva e vazão'),
              Tab(icon: Icon(Icons.groups_outlined), text: 'Captação'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_ReservatoriosRmsp(), _ChuvaRmsp(), _CaptacaoRmsp()],
        ),
      ),
    );
  }
}

/// Série (mês, valor) ignorando meses sem o indicador.
List<(DateTime, double)> _serie(
  List<PontoHistorico> historico,
  double? Function(PontoHistorico ponto) valor,
) => [
  for (final p in historico)
    if (valor(p) != null) (p.mes, valor(p)!),
];

Widget _grafico({
  required String titulo,
  required String subtitulo,
  required List<(DateTime, double)> serie,
  required String Function(double valor) formatar,
  List<double> limites = const [],
  double? minY,
  double? maxY,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: ChartCard(
      title: titulo,
      subtitle: subtitulo,
      semanticSummary: serie.isEmpty
          ? 'Sem dados'
          : serie.map((p) => '${formatarMes(p.$1)}: ${formatar(p.$2)}').join('; '),
      chart: TrendLineChart(
        series: serie,
        formatValue: formatar,
        thresholds: limites,
        minY: minY,
        maxY: maxY,
        formatDate: formatarMes,
      ),
    ),
  );
}

String _pct(double v) => '${v.toStringAsFixed(0)}%';

class _ReservatoriosRmsp extends StatelessWidget {
  const _ReservatoriosRmsp();

  @override
  Widget build(BuildContext context) {
    return RmspEstado(
      builder: (context, state) => [
        const SectionHeader(
          eyebrow: 'Recursos hídricos',
          title: 'Volume útil dos sistemas',
          subtitle:
              'Percentual do volume útil mês a mês. Linhas: faixas da Resolução ANA/DAEE 925/2017 (60%, 40% e 30%).',
        ),
        const SizedBox(height: AppSpacing.lg),
        if (state.lidos.isEmpty)
          const RmspSemLeitura()
        else ...[
          StatGrid(
            children: [
              for (final m in state.lidos)
                StatCard(
                  icon: Icons.water,
                  label: m.sistema,
                  value: '${m.volumeUtil!.toStringAsFixed(1)}%',
                  delta: m.indicadores['tendencia3m'],
                  deltaText: m.indicadores['tendencia3m'] == null
                      ? null
                      : '${m.indicadores['tendencia3m']!.toStringAsFixed(1)} p.p. em 3 meses',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final m in state.lidos)
            _grafico(
              titulo: 'Volume útil • ${m.sistema}',
              subtitulo: 'Mês de referência: ${m.mesReferencia}',
              serie: _serie(state.historicoDe(m.sensorId), (p) => p.volumeUtil),
              formatar: _pct,
              limites: const [60, 40, 30],
              minY: 0,
              maxY: 100,
            ),
          for (final m in state.lidos)
            _grafico(
              titulo: 'Risco previsto em 3 meses • ${m.sistema}',
              subtitulo: 'Probabilidade de o volume ficar abaixo de 40% (modelo de ML). Linhas: limiares 25% e 60%.',
              serie: _serie(state.historicoDe(m.sensorId), (p) => p.probRisco3m),
              formatar: _pct,
              limites: const [25, 60],
              minY: 0,
              maxY: 100,
            ),
        ],
      ],
    );
  }
}

class _ChuvaRmsp extends StatelessWidget {
  const _ChuvaRmsp();

  @override
  Widget build(BuildContext context) {
    return RmspEstado(
      builder: (context, state) => [
        const SectionHeader(
          eyebrow: 'Clima',
          title: 'Chuva e vazão natural',
          subtitle:
              'Diferença em relação à média histórica do mesmo período. Abaixo de zero = mais seco que o normal.',
        ),
        const SizedBox(height: AppSpacing.md),
        const InfoBanner(
          text:
              'O notebook de Data Science transforma a chuva e a vazão mensais do Portal dos Mananciais em '
              'anomalias, para comparar sistemas de tamanhos diferentes.',
        ),
        const SizedBox(height: AppSpacing.lg),
        if (state.lidos.isEmpty)
          const RmspSemLeitura()
        else ...[
          StatGrid(
            children: [
              for (final m in state.lidos)
                if (m.indicadores['anomChuva6m'] != null)
                  StatCard(
                    icon: Icons.grain,
                    label: 'Chuva 6 meses • ${m.sistema}',
                    value: '${m.indicadores['anomChuva6m']!.toStringAsFixed(0)}%',
                    delta: m.indicadores['anomChuva6m'],
                    deltaText: m.indicadores['anomChuva6m']! < 0 ? 'abaixo da média' : 'acima da média',
                  ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final m in state.lidos) ...[
            _grafico(
              titulo: 'Chuva dos últimos 6 meses • ${m.sistema}',
              subtitulo: '% em relação à média histórica',
              serie: _serie(state.historicoDe(m.sensorId), (p) => p.anomChuva6m),
              formatar: _pct,
              limites: const [0],
            ),
            _grafico(
              titulo: 'Vazão natural (3 meses) • ${m.sistema}',
              subtitulo: '% em relação ao típico do mês',
              serie: _serie(state.historicoDe(m.sensorId), (p) => p.anomVazao3m),
              formatar: _pct,
              limites: const [0],
            ),
          ],
        ],
      ],
    );
  }
}

class _CaptacaoRmsp extends StatelessWidget {
  const _CaptacaoRmsp();

  @override
  Widget build(BuildContext context) {
    return RmspEstado(
      builder: (context, state) => [
        const SectionHeader(
          eyebrow: 'Demanda',
          title: 'Captação e autonomia',
          subtitle:
              'Pressão = captação ÷ vazão natural (acima de 1, o sistema retira mais água do que recebe). '
              'Autonomia = meses de abastecimento com o volume atual.',
        ),
        const SizedBox(height: AppSpacing.lg),
        if (state.lidos.isEmpty)
          const RmspSemLeitura()
        else ...[
          StatGrid(
            children: [
              for (final m in state.lidos) ...[
                if (m.indicadores['pressao3m'] != null)
                  StatCard(
                    icon: Icons.speed,
                    label: 'Pressão • ${m.sistema}',
                    value: '${m.indicadores['pressao3m']!.toStringAsFixed(2)}x',
                  ),
                if (m.indicadores['autonomiaMeses'] != null)
                  StatCard(
                    icon: Icons.hourglass_bottom,
                    label: 'Autonomia • ${m.sistema}',
                    value: '${m.indicadores['autonomiaMeses']!.toStringAsFixed(0)} meses',
                  ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final m in state.lidos) ...[
            _grafico(
              titulo: 'Pressão de captação • ${m.sistema}',
              subtitulo: 'Linha: 1,0 (captação igual à vazão natural)',
              serie: _serie(state.historicoDe(m.sensorId), (p) => p.pressao3m),
              formatar: (v) => '${v.toStringAsFixed(2)}x',
              limites: const [1],
            ),
            _grafico(
              titulo: 'Autonomia • ${m.sistema}',
              subtitulo: 'Meses de abastecimento com o volume do mês',
              serie: _serie(state.historicoDe(m.sensorId), (p) => p.autonomiaMeses),
              formatar: (v) => '${v.toStringAsFixed(0)} m',
              minY: 0,
            ),
          ],
          const InfoBanner(
            text:
                'Dados agregados por sistema produtor. O app não usa consumo individual nem dados pessoais.',
            icon: Icons.privacy_tip_outlined,
          ),
        ],
      ],
    );
  }
}
