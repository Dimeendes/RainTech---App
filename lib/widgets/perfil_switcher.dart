import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_state.dart';

/// Atalho na barra superior para alternar entre os perfis Cidadão e Gestor.
/// Em produção, o perfil Gestor exigiria login institucional.
class PerfilSwitcher extends StatelessWidget {
  const PerfilSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    return PopupMenuButton<PerfilUsuario>(
      tooltip: 'Trocar perfil (atual: ${settings.perfil.rotulo})',
      icon: Icon(
        settings.ehCidadao ? Icons.person_outline : Icons.admin_panel_settings_outlined,
      ),
      initialValue: settings.perfil,
      onSelected: settings.setPerfil,
      itemBuilder: (_) => [
        for (final perfil in PerfilUsuario.values)
          CheckedPopupMenuItem(
            value: perfil,
            checked: perfil == settings.perfil,
            child: Text('Perfil ${perfil.rotulo}'),
          ),
      ],
    );
  }
}
