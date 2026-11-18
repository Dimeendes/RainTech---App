import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/manancial.dart';
import '../services/notificacoes_sistema.dart';
import '../state/mananciais_state.dart';
import '../state/settings_state.dart';

/// Observa o HidroData e avisa quando chegam alertas novos:
/// barra dentro do app (sempre) e notificação do sistema (se ativada nos Ajustes).
class NotificadorAlertas extends StatefulWidget {
  const NotificadorAlertas({
    super.key,
    required this.onVerAlertas,
    required this.child,
  });

  /// Abre a aba de alertas da visão RMSP.
  final VoidCallback onVerAlertas;
  final Widget child;

  @override
  State<NotificadorAlertas> createState() => _NotificadorAlertasState();
}

class _NotificadorAlertasState extends State<NotificadorAlertas> {
  int _ultimaVersao = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MananciaisState>();
    if (state.versaoNovosAlertas != _ultimaVersao) {
      _ultimaVersao = state.versaoNovosAlertas;
      final novos = state.novosAlertas;
      final sistemaAtivo = context.read<SettingsState>().notificacoesSistema;
      // Mostra depois do frame atual (não se pode abrir SnackBar durante o build)
      WidgetsBinding.instance.addPostFrameCallback((_) => _avisar(novos, sistemaAtivo));
    }
    return widget.child;
  }

  void _avisar(List<AlertaHidrodata> novos, bool notificarSistema) {
    if (!mounted || novos.isEmpty) return;
    final primeiro = novos.first;
    final titulo = novos.length == 1
        ? 'Novo alerta: ${nomeSistema(primeiro.sensorId)} • ${rotuloNivel(primeiro.nivel)}'
        : '${novos.length} novos alertas da RMSP';
    const corpo = 'Recomendação do modelo aguardando a decisão do gestor no RainTech.';

    if (notificarSistema) {
      mostrarNotificacaoSistema(titulo, corpo);
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Semantics(
          liveRegion: true,
          child: Text('$titulo. $corpo'),
        ),
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'Ver', onPressed: widget.onVerAlertas),
      ),
    );
  }
}
