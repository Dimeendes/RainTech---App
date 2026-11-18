import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_spacing.dart';
import '../state/mananciais_state.dart';
import 'info_banner.dart';

/// Lista rolável das telas da visão RMSP, com carregamento e erro de conexão
/// tratados em um só lugar.
class RmspEstado extends StatelessWidget {
  const RmspEstado({super.key, required this.builder});

  final List<Widget> Function(BuildContext context, MananciaisState state) builder;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MananciaisState>();
    final List<Widget> filhos = switch (state.conexao) {
      ConexaoHidrodata.carregando => const <Widget>[
        Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      ConexaoHidrodata.indisponivel => <Widget>[
        InfoBanner(
          text: state.erro ?? 'HidroData indisponível.',
          icon: Icons.cloud_off,
          tone: InfoBannerTone.warning,
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.tonalIcon(
          onPressed: state.carregar,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      ],
      ConexaoHidrodata.conectado => builder(context, state),
    };
    return RefreshIndicator(
      onRefresh: state.carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.page.copyWith(top: AppSpacing.lg),
        children: filhos,
      ),
    );
  }
}

/// Aviso para quando nenhum mês foi lido ainda.
class RmspSemLeitura extends StatelessWidget {
  const RmspSemLeitura({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoBanner(
      text: 'Ainda não há meses lidos. Toque em "Avançar um mês" no Início.',
      icon: Icons.hourglass_empty,
    );
  }
}

/// Rótulo mês/ano para gráficos de dados mensais (ex.: 06/25).
String formatarMes(DateTime data) =>
    '${data.month.toString().padLeft(2, '0')}/${(data.year % 100).toString().padLeft(2, '0')}';
