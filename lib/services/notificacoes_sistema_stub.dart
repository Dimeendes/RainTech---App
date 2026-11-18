/// Plataformas sem notificação do sistema implementada:
/// os alertas continuam aparecendo como aviso dentro do app.
bool get notificacoesSistemaSuportadas => false;

bool get notificacoesSistemaPermitidas => false;

Future<bool> pedirPermissaoNotificacoes() async => false;

void mostrarNotificacaoSistema(String titulo, String corpo) {}
