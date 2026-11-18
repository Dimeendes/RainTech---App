// Notificações do sistema operacional para novos alertas.
// Web (Edge/Chrome): API de notificações do navegador.
// Android: flutter_local_notifications.
// Outras plataformas: só o aviso dentro do app.
export 'notificacoes_sistema_stub.dart'
    if (dart.library.js_interop) 'notificacoes_sistema_web.dart'
    if (dart.library.io) 'notificacoes_sistema_io.dart';
