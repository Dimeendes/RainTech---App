import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../widgets/alerta_hidrodata_tile.dart';
import '../../widgets/human_decision_banner.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/rmsp_estado.dart';
import '../../widgets/section_header.dart';

enum _Filtro { todos, pendentes, revisados }

/// Alertas do modelo de ML gravados no HidroData, com a decisão do gestor.
class RmspAlertsPage extends StatefulWidget {
  const RmspAlertsPage({super.key});

  @override
  State<RmspAlertsPage> createState() => _RmspAlertsPageState();
}

class _RmspAlertsPageState extends State<RmspAlertsPage> {
  _Filtro _filtro = _Filtro.todos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas • RMSP')),
      body: RmspEstado(
        builder: (context, state) {
          final visiveis = switch (_filtro) {
            _Filtro.todos => [...state.pendentes, ...state.validados],
            _Filtro.pendentes => state.pendentes,
            _Filtro.revisados => state.validados,
          };
          return [
            SectionHeader(
              eyebrow: 'Alertas preditivos • HidroData',
              title: '${state.pendentes.length + state.validados.length} alertas',
              subtitle: '${state.pendentes.length} aguardando a decisão do gestor',
            ),
            const SizedBox(height: AppSpacing.md),
            const HumanDecisionBanner(),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<_Filtro>(
              segments: const [
                ButtonSegment(value: _Filtro.todos, label: Text('Todos')),
                ButtonSegment(value: _Filtro.pendentes, label: Text('Pendentes')),
                ButtonSegment(value: _Filtro.revisados, label: Text('Revisados')),
              ],
              selected: {_filtro},
              showSelectedIcon: false,
              onSelectionChanged: (selecao) => setState(() => _filtro = selecao.first),
            ),
            const SizedBox(height: AppSpacing.md),
            if (visiveis.isEmpty)
              InfoBanner(
                text: switch (_filtro) {
                  _Filtro.todos =>
                    'Nenhum alerta ainda. Use "Avançar um mês" no Início para o HidroData analisar o próximo mês.',
                  _Filtro.pendentes => 'Todos os alertas já têm decisão do gestor.',
                  _Filtro.revisados => 'Nenhuma decisão registrada ainda.',
                },
                icon: Icons.verified_outlined,
              )
            else
              for (final alerta in visiveis) AlertaHidrodataTile(alerta: alerta),
          ];
        },
      ),
    );
  }
}
