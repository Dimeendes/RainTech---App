import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../widgets/section_header.dart';

/// Orientações de preparo para períodos de escassez hídrica.
class CidadaoPrepararPage extends StatelessWidget {
  const CidadaoPrepararPage({super.key});

  static const _secoes = [
    (
      Icons.savings_outlined,
      'Economize no dia a dia',
      [
        'Banhos mais curtos e chuveiro fechado enquanto se ensaboa.',
        'Torneira fechada ao escovar os dentes e lavar a louça.',
        'Lave roupas com a máquina cheia e reutilize a água na limpeza do quintal.',
        'Use balde, não mangueira, para lavar calçadas e carros.',
      ],
    ),
    (
      Icons.plumbing,
      'Cuide da sua instalação',
      [
        'Feche todas as torneiras e veja se o hidrômetro continua girando: pode ser vazamento.',
        'Mantenha a caixa-d\'água tampada e faça a limpeza periodicamente.',
      ],
    ),
    (
      Icons.water_drop_outlined,
      'Guarde água com segurança',
      [
        'Use recipientes limpos, próprios para água e sempre tampados.',
        'Água parada e destampada vira criadouro do mosquito da dengue.',
        'Troque a água de reserva com frequência e guarde longe do sol.',
      ],
    ),
    (
      Icons.groups_outlined,
      'Se houver redução de pressão',
      [
        'Priorize a água para beber, cozinhar e higiene.',
        'Combine com vizinhos como ajudar idosos e pessoas com mobilidade reduzida.',
        'Acompanhe os horários e comunicados oficiais da Sabesp.',
      ],
    ),
    (
      Icons.support_agent,
      'Canais oficiais',
      [
        'Defesa Civil: ligue 199 em emergências.',
        'Alertas da Defesa Civil por SMS: envie seu CEP para 40199.',
        'Sabesp: informações de abastecimento no site, no aplicativo oficial e na conta de água.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Preparar')),
      body: ListView(
        padding: AppSpacing.page.copyWith(top: AppSpacing.lg),
        children: [
          const SectionHeader(
            eyebrow: 'Prevenção',
            title: 'Esteja pronto para a estiagem',
            subtitle: 'Pequenas atitudes agora reduzem o impacto de uma crise hídrica.',
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final (icone, titulo, itens) in _secoes)
            Card(
              child: Padding(
                padding: AppSpacing.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icone, color: theme.colorScheme.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            titulo,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final item in itens)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  '),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
