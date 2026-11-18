import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_spacing.dart';
import '../services/notificacoes_sistema.dart';
import '../state/alerts_state.dart';
import '../state/mananciais_state.dart';
import '../state/settings_state.dart';
import '../widgets/section_header.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final alerts = context.watch<AlertsState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Preferências')),
      body: ListView(
        key: const ValueKey('settings-list'),
        padding: AppSpacing.page,
        children: [
          const SectionHeader(
            eyebrow: 'Aparência',
            title: 'Tema do aplicativo',
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: SwitchListTile(
              key: const ValueKey('dark-mode-switch'),
              secondary: Icon(
                settings.isDarkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
              title: const Text('Modo escuro'),
              subtitle: Text(
                settings.isDarkMode ? 'Tema escuro ativo' : 'Tema claro ativo',
              ),
              value: settings.isDarkMode,
              onChanged: settings.setDarkMode,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(
            eyebrow: 'Acessibilidade',
            title: 'Ajustes de leitura',
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: SwitchListTile(
              key: const ValueKey('high-contrast-switch'),
              secondary: const Icon(Icons.contrast_outlined),
              title: const Text('Alto contraste'),
              subtitle: Text(
                settings.highContrast
                    ? 'Contraste reforçado ativo'
                    : 'Reforça o contraste de textos e componentes',
              ),
              value: settings.highContrast,
              onChanged: settings.setHighContrast,
            ),
          ),
          Card(
            child: Padding(
              padding: AppSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.text_fields),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Tamanho do texto',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text('${(settings.fontScale * 100).round()}%'),
                    ],
                  ),
                  Slider(
                    key: const ValueKey('font-scale-slider'),
                    value: settings.fontScale,
                    min: SettingsState.minFontScale,
                    max: SettingsState.maxFontScale,
                    divisions: 13,
                    label: '${(settings.fontScale * 100).round()}%',
                    semanticFormatterCallback: (value) =>
                        '${(value * 100).round()} por cento',
                    onChanged: settings.setFontScale,
                  ),
                  Text(
                    'O ajuste é aplicado ao app e combinado com a escala de texto do sistema.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(
            eyebrow: 'Perfil de uso',
            title: 'Para quem é o app agora',
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: AppSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<PerfilUsuario>(
                    key: const ValueKey('perfil-usuario'),
                    segments: const [
                      ButtonSegment(
                        value: PerfilUsuario.cidadao,
                        icon: Icon(Icons.person_outline),
                        label: Text('Cidadão'),
                      ),
                      ButtonSegment(
                        value: PerfilUsuario.gestor,
                        icon: Icon(Icons.admin_panel_settings_outlined),
                        label: Text('Gestor'),
                      ),
                    ],
                    selected: {settings.perfil},
                    onSelectionChanged: (selecao) => settings.setPerfil(selecao.first),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${settings.perfil.descricao} Em produção, o perfil Gestor exigiria login institucional.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!settings.ehCidadao) ...[
          const SectionHeader(
            eyebrow: 'Fonte de dados',
            title: 'Visão do aplicativo',
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: AppSpacing.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<VisaoDados>(
                    key: const ValueKey('visao-dados'),
                    segments: const [
                      ButtonSegment(
                        value: VisaoDados.rmsp,
                        icon: Icon(Icons.location_city),
                        label: Text('RMSP'),
                      ),
                      ButtonSegment(
                        value: VisaoDados.chennai,
                        icon: Icon(Icons.public),
                        label: Text('Chennai'),
                      ),
                    ],
                    selected: {settings.visao},
                    onSelectionChanged: (selecao) => settings.setVisao(selecao.first),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    settings.visao.descricao,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          ],
          Card(
            child: SwitchListTile(
              key: const ValueKey('notificacoes-sistema'),
              secondary: const Icon(Icons.notifications_active_outlined),
              title: const Text('Notificações de novos alertas'),
              subtitle: Text(
                !notificacoesSistemaSuportadas
                    ? 'Disponível no navegador (Edge ou Chrome) e no Android. Nesta plataforma os novos alertas aparecem como aviso dentro do app.'
                    : settings.ehCidadao
                    ? 'Receba uma notificação quando a gestão confirmar um aviso de abastecimento.'
                    : 'Receba os novos alertas do modelo que aguardam a sua validação.',
              ),
              value: settings.notificacoesSistema && notificacoesSistemaPermitidas,
              onChanged: !notificacoesSistemaSuportadas
                  ? null
                  : (ativar) async {
                      if (!ativar) {
                        await settings.setNotificacoesSistema(false);
                        return;
                      }
                      final permitido = await pedirPermissaoNotificacoes();
                      await settings.setNotificacoesSistema(permitido);
                      if (!permitido && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'O navegador bloqueou as notificações. Libere no cadeado ao lado do endereço e tente de novo.',
                            ),
                          ),
                        );
                      }
                    },
            ),
          ),
          const _EnderecoHidrodata(),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(
            eyebrow: 'Privacidade',
            title: 'Dados e consentimento',
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: AppSpacing.card,
              child: Semantics(
                container: true,
                excludeSemantics: true,
                label:
                    'Os níveis de reservatórios e chuva vêm de uma base pública e são apresentados por reservatório (Chennai, Índia) na demonstração; a aba RMSP usa dados da Sabesp. '
                    'Os dados são agregados, sem identificação de pessoas. A população atendida é uma estimativa sintética. '
                    'Justificativas digitadas podem conter dados pessoais e só são salvas localmente com consentimento explícito. '
                    'Não inclua identificadores pessoais.',
                child: const Text(
                  'Níveis de reservatórios e chuva vêm de uma base pública e são apresentados por reservatório (Chennai, Índia) na demonstração; a aba RMSP usa dados da Sabesp. '
                  'Os dados são agregados, sem identificação de pessoas. A população atendida exibida é uma estimativa sintética para demonstração. '
                  'Justificativas digitadas podem conter dados pessoais e só são salvas localmente com consentimento explícito. Não inclua identificadores pessoais.',
                ),
              ),
            ),
          ),
          Card(
            child: SwitchListTile(
              key: const ValueKey('review-storage-consent'),
              secondary: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Salvar avaliações neste dispositivo'),
              subtitle: const Text(
                'Autorizo salvar decisões e justificativas de alertas somente neste aparelho. '
                'Elas não são enviadas. Não inclua dados pessoais.',
              ),
              value: alerts.canPersistReviews,
              onChanged: alerts.setReviewStorageConsent,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              'Sem consentimento, as avaliações ficam apenas durante a sessão. Você pode revogar a autorização a qualquer momento; os dados locais serão apagados.',
            ),
          ),
        ],
      ),
    );
  }
}

/// Endereço da API do HidroData. No celular, use o IP do computador na mesma rede Wi-Fi.
class _EnderecoHidrodata extends StatefulWidget {
  const _EnderecoHidrodata();

  @override
  State<_EnderecoHidrodata> createState() => _EnderecoHidrodataState();
}

class _EnderecoHidrodataState extends State<_EnderecoHidrodata> {
  late final TextEditingController _controle;
  bool _testando = false;
  String? _resultado;
  bool _sucesso = false;

  @override
  void initState() {
    super.initState();
    _controle = TextEditingController(text: context.read<MananciaisState>().enderecoApi);
  }

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _testando = true;
      _resultado = null;
    });
    final erro = await context.read<MananciaisState>().alterarEndereco(_controle.text);
    if (!mounted) return;
    setState(() {
      _testando = false;
      _sucesso = erro == null;
      _resultado = erro ?? 'Conectado ao HidroData.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Endereço do HidroData (visão RMSP)', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'No navegador ou no Windows: http://localhost:8080/api. '
              'No celular: http://IP-DO-COMPUTADOR:8080/api, na mesma rede Wi-Fi.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const ValueKey('endereco-hidrodata'),
              controller: _controle,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Endereço da API'),
              onSubmitted: (_) => _salvar(),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonalIcon(
              onPressed: _testando ? null : _salvar,
              icon: _testando
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering),
              label: const Text('Salvar e testar conexão'),
            ),
            if (_resultado != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _resultado!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _sucesso ? theme.colorScheme.primary : theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
