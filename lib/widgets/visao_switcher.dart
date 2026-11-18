import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_state.dart';

/// Atalho na barra superior para trocar entre a visão RMSP e a visão Chennai.
class VisaoSwitcher extends StatelessWidget {
  const VisaoSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    return PopupMenuButton<VisaoDados>(
      tooltip: 'Trocar a visão dos dados (atual: ${settings.visao.rotulo})',
      icon: const Icon(Icons.swap_horiz),
      initialValue: settings.visao,
      onSelected: settings.setVisao,
      itemBuilder: (_) => [
        for (final visao in VisaoDados.values)
          CheckedPopupMenuItem(
            value: visao,
            checked: visao == settings.visao,
            child: Text(visao.rotulo),
          ),
      ],
    );
  }
}
