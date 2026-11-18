import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/manancial.dart';
import '../../models/orientacoes.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/rmsp_estado.dart';
import '../../widgets/section_header.dart';
import '../../widgets/water_format.dart';

/// Avisos à população: somente alertas aprovados por um gestor, em linguagem simples.
class CidadaoAvisosPage extends StatelessWidget {
  const CidadaoAvisosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avisos')),
      body: RmspEstado(
        builder: (context, state) {
          final avisos = state.avisosConfirmados;
          final ativos = state.avisosAtivos.map((a) => a.id).toSet();
          return [
            SectionHeader(
              eyebrow: 'Avisos à população',
              title: avisos.isEmpty ? 'Nenhum aviso' : '${ativos.length} ativo(s) • ${avisos.length} no total',
              subtitle: 'Publicados somente depois da confirmação de um gestor.',
            ),
            const SizedBox(height: AppSpacing.md),
            if (avisos.isEmpty)
              const InfoBanner(
                icon: Icons.notifications_none,
                text:
                    'Quando a gestão confirmar um risco ao abastecimento, o aviso aparece aqui. '
                    'Ative as notificações em Ajustes para ser avisado na hora.',
              )
            else
              for (final aviso in avisos) _AvisoCard(aviso: aviso, ativo: ativos.contains(aviso.id)),
          ];
        },
      ),
    );
  }
}

class _AvisoCard extends StatelessWidget {
  const _AvisoCard({required this.aviso, required this.ativo});

  final AlertaHidrodata aviso;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orientacao = OrientacaoCidadao.paraNivel(aviso.nivel);
    final cor = AppTheme.riskColor(context, orientacao.risco);
    final validacao = aviso.validacao;
    final referencia = aviso.mesReferenciaFormatado ?? formatDate(aviso.dataHora);

    return Card(
      child: ExpansionTile(
        initiallyExpanded: ativo,
        leading: Icon(Icons.campaign, color: ativo ? cor : theme.colorScheme.onSurfaceVariant),
        title: Text(
          '${nomeSistema(aviso.sensorId)} • ${orientacao.titulo}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${ativo ? 'Ativo' : 'Anterior'} • referente a $referencia'),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(orientacao.resumo),
          if (validacao != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nota da gestão (${formatDate(validacao.dataHora)}): ${validacao.justificativa}',
              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text('O que fazer', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          for (final acao in orientacao.oQueFazer)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check, size: 18, color: cor),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(acao)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
