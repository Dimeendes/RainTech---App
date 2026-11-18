import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android: notificações locais. Windows/desktop: só o aviso dentro do app.
final _plugin = FlutterLocalNotificationsPlugin();
bool _inicializado = false;
int _proximoId = 0;

const _detalhes = NotificationDetails(
  android: AndroidNotificationDetails(
    'alertas_rmsp',
    'Alertas da RMSP',
    channelDescription: 'Novos alertas do modelo de ML aguardando a decisão do gestor',
    importance: Importance.high,
    priority: Priority.high,
  ),
);

bool get notificacoesSistemaSuportadas => Platform.isAndroid;

/// No Android a permissão é pedida ao ativar nos Ajustes; se o usuário a revogar
/// nas configurações do sistema, a notificação simplesmente não aparece.
bool get notificacoesSistemaPermitidas => Platform.isAndroid;

Future<void> _inicializar() async {
  if (_inicializado) return;
  await _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  _inicializado = true;
}

Future<bool> pedirPermissaoNotificacoes() async {
  if (!Platform.isAndroid) return false;
  try {
    await _inicializar();
    final permitido = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return permitido ?? true; // Android < 13 não pede permissão
  } on Object {
    return false;
  }
}

void mostrarNotificacaoSistema(String titulo, String corpo) {
  if (!Platform.isAndroid) return;
  _mostrar(titulo, corpo);
}

Future<void> _mostrar(String titulo, String corpo) async {
  try {
    await _inicializar();
    await _plugin.show(
      id: _proximoId++,
      title: titulo,
      body: corpo,
      notificationDetails: _detalhes,
    );
  } on Object {
    // Sem notificação do sistema; o aviso dentro do app continua aparecendo.
  }
}
