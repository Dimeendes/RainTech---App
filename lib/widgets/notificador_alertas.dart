import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/manancial.dart';
import '../models/orientacoes.dart';
import '../services/notificacoes_sistema.dart';
import '../state/mananciais_state.dart';
import '../state/settings_state.dart';

/// Avisa quando chegam novidades do HidroData, conforme o perfil:
/// - Gestor: novos alertas do modelo aguardando validação.
/// - Cidadão: avisos que acabaram de ser APROVADOS pela gestão.
/// Mostra uma barra dentro do app (sempre) e a notificação do sistema (se ativada).
class NotificadorAlertas extends StatefulWidget {
  const NotificadorAlertas({
    super.key,
    required this.onVerAlertasGestor,
    required this.onVerAvisosCidadao,
    required this.child,
  });

  final VoidCallback onVerAlertasGestor;
  final VoidCallback onVerAvisosCidadao;
  final Widget child;

  @override
  State<NotificadorAlertas> createState() => _NotificadorAlertasState();
}

class _NotificadorAlertasState extends State<NotificadorAlertas> {
  int _versaoAlertas = 0;
  int _versaoAvisos = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MananciaisState>();
    final settings = context.read<SettingsState>();

    if (state.versaoNovosAlertas != _versaoAlertas) {
      _versaoAlertas = state.versaoNovosAlertas;
      if (!settings.ehCidadao) {
        final novos = state.novosAlertas;
        final primeiro = novos.first;
        _agendar(
          titulo: novos.length == 1
              ? 'Novo alerta: ${nomeSistema(primeiro.sensorId)} • ${rotuloNivel(primeiro.nivel)}'
              : '${novos.length} novos alertas da RMSP',
          corpo: 'Recomendação do modelo aguardando a decisão do gestor no RainTech.',
          aoVer: widget.onVerAlertasGestor,
          sistema: settings.notificacoesSistema,
        );
      }
    }

    if (state.versaoNovosAvisos != _versaoAvisos) {
      _versaoAvisos = state.versaoNovosAvisos;
      if (settings.ehCidadao) {
        final aviso = state.novosAvisos.first;
        final orientacao = OrientacaoCidadao.paraNivel(aviso.nivel);
        _agendar(
          titulo: 'Aviso de abastecimento: ${nomeSistema(aviso.sensorId)}',
          corpo: '${orientacao.titulo}. Confirmado pela gestão. Veja o que fazer no RainTech.',
          aoVer: widget.onVerAvisosCidadao,
          sistema: settings.notificacoesSistema,
        );
      }
    }
    return widget.child;
  }

  /// Não se pode abrir SnackBar durante o build: mostra depois do frame atual.
  void _agendar({
    required String titulo,
    required String corpo,
    required VoidCallback aoVer,
    required bool sistema,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (sistema) mostrarNotificacaoSistema(titulo, corpo);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Semantics(liveRegion: true, child: Text('$titulo. $corpo')),
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(label: 'Ver', onPressed: aoVer),
        ),
      );
    });
  }
}
