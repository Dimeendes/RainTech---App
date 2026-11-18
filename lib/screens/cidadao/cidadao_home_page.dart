import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/manancial.dart';
import '../../models/orientacoes.dart';
import '../../state/mananciais_state.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/perfil_switcher.dart';
import '../../widgets/rmsp_estado.dart';
import '../../widgets/section_header.dart';

/// Início do perfil Cidadão: situação da água em linguagem simples.
/// Previsões do modelo só aparecem depois de confirmadas por um gestor.
class CidadaoHomePage extends StatelessWidget {
  const CidadaoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RainTech'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: context.read<MananciaisState>().carregar,
          ),
          const PerfilSwitcher(),
        ],
      ),
      body: RmspEstado(
        builder: (context, state) {
          final ativos = state.avisosAtivos;
          final lidos = state.lidos;
          final mes = lidos.isEmpty ? null : lidos.first.mesReferencia;
          final muted = Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
          return [
            SectionHeader(
              eyebrow: 'Abastecimento de água • Grande São Paulo',
              title: 'Como está a água na sua região',
              subtitle: mes == null
                  ? null
                  : 'Dados de ${mes.substring(5, 7)}/${mes.substring(0, 4)} do Portal dos Mananciais (Sabesp)',
            ),
            const SizedBox(height: AppSpacing.md),
            _ResumoAvisos(quantidade: ativos.length),
            const SizedBox(height: AppSpacing.lg),
            if (lidos.isEmpty)
              const InfoBanner(
                text: 'Ainda não há dados publicados. Assim que o sistema for atualizado, a situação aparece aqui.',
                icon: Icons.hourglass_empty,
              )
            else ...[
              const SubsectionTitle('Situação dos reservatórios'),
              const SizedBox(height: AppSpacing.sm),
              for (final m in lidos) _SistemaCidadaoCard(manancial: m, aviso: state.avisoAtivoDe(m)),
            ],
            const SizedBox(height: AppSpacing.lg),
            const InfoBanner(
              icon: Icons.verified_user_outlined,
              text:
                  'Os avisos só são publicados depois de confirmados por um gestor. As previsões automáticas '
                  'não chegam direto à população, para evitar alarmes falsos.',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Não sabe qual sistema abastece sua casa? Consulte a conta de água ou os canais oficiais da Sabesp. '
              'Os dados são públicos e agregados por sistema; o app não coleta informações pessoais.',
              style: muted,
            ),
          ];
        },
      ),
    );
  }
}

class _ResumoAvisos extends StatelessWidget {
  const _ResumoAvisos({required this.quantidade});

  final int quantidade;

  @override
  Widget build(BuildContext context) {
    final semAviso = quantidade == 0;
    final cor = AppTheme.riskColor(context, semAviso ? RiskLevel.low : RiskLevel.high);
    final texto = semAviso
        ? 'Nenhum aviso ativo. No momento, a gestão não confirmou risco para o abastecimento.'
        : '$quantidade aviso(s) ativo(s) para a sua região. Veja o que fazer na aba Avisos.';
    return Semantics(
      container: true,
      liveRegion: true,
      label: texto,
      excludeSemantics: true,
      child: Container(
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(color: cor, width: 1.4),
        ),
        child: Row(
          children: [
            Icon(semAviso ? Icons.check_circle_outline : Icons.campaign_outlined, color: cor, size: 32),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                texto,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SistemaCidadaoCard extends StatelessWidget {
  const _SistemaCidadaoCard({required this.manancial, this.aviso});

  final Manancial manancial;
  final AlertaHidrodata? aviso;

  @override
  Widget build(BuildContext context) {
    final m = manancial;
    final theme = Theme.of(context);
    // Com aviso confirmado vale o nível do aviso (pode ser antecipado);
    // sem aviso, só o nível observado pelo volume (fato, não previsão).
    final orientacao = OrientacaoCidadao.paraNivel(
      aviso?.nivel ?? OrientacaoCidadao.nivelPorVolume(m.volumeUtil!),
    );
    final cor = AppTheme.riskColor(context, orientacao.risco);

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: cor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Sistema ${m.sistema}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                  ),
                  child: Text(
                    orientacao.situacao,
                    style: TextStyle(color: cor, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              label: 'Reservatório com ${m.volumeUtil!.toStringAsFixed(0)} por cento da capacidade útil',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${m.volumeUtil!.toStringAsFixed(0)}% da capacidade útil'),
                  const SizedBox(height: AppSpacing.xs),
                  LinearProgressIndicator(
                    value: (m.volumeUtil! / 100).clamp(0.0, 1.0),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(8),
                    color: cor,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(orientacao.resumo),
            if (aviso != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.verified, size: 18, color: cor),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Aviso confirmado pela gestão. Veja as orientações na aba Avisos.',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
