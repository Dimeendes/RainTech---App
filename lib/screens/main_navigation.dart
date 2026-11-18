import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/alerts_state.dart';
import '../state/mananciais_state.dart';
import '../state/settings_state.dart';
import '../widgets/notificador_alertas.dart';
import 'alerts/alerts_page.dart';
import 'cidadao/cidadao_avisos_page.dart';
import 'cidadao/cidadao_home_page.dart';
import 'cidadao/cidadao_preparar_page.dart';
import 'dashboards/dashboards_page.dart';
import 'home_page.dart';
import 'mananciais/mananciais_page.dart';
import 'mananciais/rmsp_alerts_page.dart';
import 'mananciais/rmsp_dashboards_page.dart';
import 'settings_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // Perfil Cidadão: linguagem simples, só avisos confirmados pela gestão.
  static const _paginasCidadao = [
    CidadaoHomePage(),
    CidadaoAvisosPage(),
    CidadaoPrepararPage(),
    SettingsPage(),
  ];

  // Perfil Gestor, visão RMSP: dados reais via HidroData.
  static const _paginasRmsp = [
    MananciaisPage(),
    RmspDashboardsPage(),
    RmspAlertsPage(),
    SettingsPage(),
  ];

  // Perfil Gestor, visão Chennai: demonstração com base pública.
  static const _paginasChennai = [
    HomePage(),
    DashboardsPage(),
    AlertsPage(),
    SettingsPage(),
  ];

  void _abrirAlertasGestor() {
    context.read<SettingsState>().setVisao(VisaoDados.rmsp);
    setState(() => _selectedIndex = 2);
  }

  void _abrirAvisosCidadao() => setState(() => _selectedIndex = 1);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final alertasChennai = context.watch<AlertsState>().pending.length;
    final rmsp = context.watch<MananciaisState>();

    final cidadao = settings.ehCidadao;
    final visaoRmsp = settings.visao == VisaoDados.rmsp;
    final pages = cidadao
        ? _paginasCidadao
        : visaoRmsp
        ? _paginasRmsp
        : _paginasChennai;
    final contador = cidadao
        ? rmsp.avisosAtivos.length
        : visaoRmsp
        ? rmsp.pendentes.length
        : alertasChennai;

    return NotificadorAlertas(
      onVerAlertasGestor: _abrirAlertasGestor,
      onVerAvisosCidadao: _abrirAvisosCidadao,
      child: Scaffold(
        body: IndexedStack(
          key: ValueKey('${settings.perfil.name}-${settings.visao.name}'),
          index: _selectedIndex,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Início',
            ),
            if (cidadao)
              NavigationDestination(
                icon: Badge.count(
                  count: contador,
                  isLabelVisible: contador > 0,
                  child: const Icon(Icons.campaign_outlined),
                ),
                selectedIcon: const Icon(Icons.campaign),
                label: 'Avisos',
                tooltip: '$contador avisos ativos',
              )
            else
              const NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Painéis',
              ),
            if (cidadao)
              const NavigationDestination(
                icon: Icon(Icons.checklist_outlined),
                selectedIcon: Icon(Icons.checklist),
                label: 'Preparar',
              )
            else
              NavigationDestination(
                icon: Badge.count(
                  count: contador,
                  isLabelVisible: contador > 0,
                  child: const Icon(Icons.notifications_outlined),
                ),
                selectedIcon: Badge.count(
                  count: contador,
                  isLabelVisible: contador > 0,
                  child: const Icon(Icons.notifications),
                ),
                label: 'Alertas',
                tooltip: '$contador alertas aguardando revisão',
              ),
            const NavigationDestination(
              icon: Icon(Icons.tune),
              selectedIcon: Icon(Icons.tune),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}
