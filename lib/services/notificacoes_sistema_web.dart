import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Notificações pelo navegador (funciona em http://localhost, que o navegador
/// trata como origem segura).
bool get notificacoesSistemaSuportadas {
  try {
    web.Notification.permission;
    return true;
  } on Object {
    return false;
  }
}

bool get notificacoesSistemaPermitidas {
  try {
    return web.Notification.permission == 'granted';
  } on Object {
    return false;
  }
}

/// Pede permissão ao usuário. Deve ser chamado a partir de um toque (ex.: interruptor).
Future<bool> pedirPermissaoNotificacoes() async {
  try {
    final resultado = await web.Notification.requestPermission().toDart;
    return resultado.toDart == 'granted';
  } on Object {
    return false;
  }
}

void mostrarNotificacaoSistema(String titulo, String corpo) {
  if (!notificacoesSistemaPermitidas) return;
  try {
    web.Notification(titulo, web.NotificationOptions(body: corpo));
  } on Object {
    // Sem notificação do sistema; o aviso dentro do app continua aparecendo.
  }
}
