import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/manancial.dart';
import '../../state/mananciais_state.dart';
import '../../widgets/charts/chart_card.dart';
import '../../widgets/charts/trend_line_chart.dart';
import '../../widgets/confidence_meter.dart';
import '../../widgets/human_decision_banner.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/rmsp_estado.dart';
import '../../widgets/section_header.dart';
import '../../widgets/visao_switcher.dart';
import '../../widgets/water_format.dart';

/// Início da visão RMSP: dados reais (Sabesp) e o modelo de ML, via HidroData (Java).
class MananciaisPage extends StatelessWidget {
  const MananciaisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MananciaisState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('RainTech • RMSP'),
        actions: [
          const VisaoSwitcher(),
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: state.carregar,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.carregar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.page.copyWith(top: AppSpacing.lg),
          children: [
            const SectionHeader(
              eyebrow: 'Integração com o HidroData',
              title: 'Cantareira e Alto Tietê',
              subtitle:
                  'Volume real do Portal dos Mananciais (Sabesp) e risco previsto pelo modelo de machine learning.',
            ),
            const SizedBox(height: AppSpacing.md),
            const HumanDecisionBanner(compact: true),
            const SizedBox(height: AppSpacing.lg),
            ..._conteudo(context, state),
          ],
        ),
      ),
    );
  }

  List<Widget> _conteudo(BuildContext context, MananciaisState state) {
    if (state.conexao == ConexaoHidrodata.carregando) {
      return const [
        Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (state.conexao == ConexaoHidrodata.indisponivel) {
      return [
        InfoBanner(
          text: state.erro ?? 'HidroData indisponível.',
          icon: Icons.cloud_off,
          tone: InfoBannerTone.warning,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.tonalIcon(
          onPressed: state.carregar,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      ];
    }
    return [
      _BotaoAvancarMes(state: state),
      const SizedBox(height: AppSpacing.lg),
      for (final m in state.mananciais) ...[
        _ManancialCard(manancial: m, historico: state.historicoDe(m.sensorId)),
        const SizedBox(height: AppSpacing.lg),
      ],
      InfoBanner(
        text: state.pendentes.isEmpty
            ? 'Nenhum alerta aguardando decisão. Os alertas do modelo aparecem na aba Alertas.'
            : '${state.pendentes.length} alerta(s) aguardando a decisão do gestor na aba Alertas.',
        icon: Icons.notifications_outlined,
        tone: state.pendentes.isEmpty ? InfoBannerTone.info : InfoBannerTone.warning,
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(
        'Fonte: Portal dos Mananciais (Sabesp) → notebook de Data Science → HidroData (Java, ${state.enderecoApi}). '
        'Dados públicos e agregados por sistema produtor, sem informações pessoais.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ];
  }
}

class _BotaoAvancarMes extends StatelessWidget {
  const _BotaoAvancarMes({required this.state});

  final MananciaisState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Simulação mês a mês',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Cada toque lê o próximo mês da série real (a partir de 01/2025), '
              'roda as previsões no HidroData e grava os alertas.',
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: state.avancando
                  ? null
                  : () async {
                      final erro = await state.avancarMes();
                      if (erro != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
                      }
                    },
              icon: state.avancando
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.skip_next),
              label: const Text('Avançar um mês'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NivelChip extends StatelessWidget {
  const _NivelChip({required this.nivel});

  final String? nivel;

  @override
  Widget build(BuildContext context) {
    final cor = AppTheme.riskColor(context, riscoDoNivel(nivel));
    return Semantics(
      label: 'Nível ${rotuloNivel(nivel)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(color: cor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              nivel == 'NORMAL' ? Icons.check_circle_outline : Icons.warning_amber_rounded,
              size: 16,
              color: cor,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              rotuloNivel(nivel),
              style: TextStyle(color: cor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManancialCard extends StatelessWidget {
  const _ManancialCard({required this.manancial, required this.historico});

  final Manancial manancial;
  final List<PontoHistorico> historico;

  @override
  Widget build(BuildContext context) {
    final m = manancial;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sistema ${m.sistema}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (m.foiLido) _NivelChip(nivel: m.nivel),
              ],
            ),
            if (!m.foiLido) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(m.aviso ?? 'Sem leitura ainda. Toque em "Avançar um mês".'),
            ] else ...[
              Text('Mês de referência: ${m.mesReferencia}', style: muted),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _Valor(
                      rotulo: 'Volume útil',
                      valor: '${m.volumeUtil!.toStringAsFixed(1)}%',
                    ),
                  ),
                  Expanded(
                    child: _Valor(
                      rotulo: 'Risco em 3 meses',
                      valor: '${m.probRisco3m!.toStringAsFixed(0)}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                label: 'Volume útil ${m.volumeUtil!.toStringAsFixed(0)} por cento',
                excludeSemantics: true,
                child: LinearProgressIndicator(
                  value: (m.volumeUtil! / 100).clamp(0.0, 1.0),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.riskColor(context, riscoDoNivel(m.nivel)),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              if (m.antecipadoPeloModelo) ...[
                const SizedBox(height: AppSpacing.md),
                const InfoBanner(
                  text:
                      'Alerta antecipado pelo modelo: o volume ainda não está nesta faixa, '
                      'mas os indicadores apontam risco nos próximos 3 meses.',
                  icon: Icons.trending_down,
                  tone: InfoBannerTone.warning,
                ),
              ],
              if (m.confiancaNivel != null) ...[
                const SizedBox(height: AppSpacing.md),
                ConfidenceMeter(confidence: m.confiancaValor, label: m.confiancaRotulo),
                const SizedBox(height: AppSpacing.xs),
                Text(m.confiancaTexto ?? '', style: muted),
              ],
              const SizedBox(height: AppSpacing.md),
              Text('Por que este nível?', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(m.explicacao ?? ''),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final (rotulo, chave, sufixo) in const [
                    ('Chuva 6 meses', 'anomChuva6m', '% vs. média'),
                    ('Vazão 3 meses', 'anomVazao3m', '% vs. típico'),
                    ('Tendência 3 meses', 'tendencia3m', ' p.p.'),
                    ('Autonomia', 'autonomiaMeses', ' meses'),
                  ])
                    if (m.indicadores[chave] != null)
                      Chip(
                        label: Text(
                          '$rotulo: ${m.indicadores[chave]!.toStringAsFixed(chave == 'tendencia3m' ? 1 : 0)}$sufixo',
                        ),
                      ),
                ],
              ),
              if (historico.length >= 2) ...[
                const SizedBox(height: AppSpacing.md),
                ChartCard(
                  title: 'Volume útil mês a mês',
                  subtitle: 'Linhas de referência: 60%, 40% e 30% (faixas ANA/DAEE 925/2017)',
                  semanticSummary: historico
                      .map((p) => '${formatDate(p.mes)}: ${p.volumeUtil.toStringAsFixed(0)}%')
                      .join('; '),
                  chart: TrendLineChart(
                    series: [for (final p in historico) (p.mes, p.volumeUtil)],
                    formatValue: (v) => '${v.toStringAsFixed(0)}%',
                    minY: 0,
                    maxY: 100,
                    thresholds: const [60, 40, 30],
                    formatDate: formatarMes,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Valor extends StatelessWidget {
  const _Valor({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: theme.textTheme.bodySmall),
        Text(valor, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
