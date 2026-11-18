import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/alerts_state.dart';
import '../state/mananciais_state.dart';
import '../state/settings_state.dart';
import '../widgets/notificador_alertas.dart';
import 'alerts/alerts_page.dart';
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
  static const _abaAlertas = 2;

  int _selectedIndex = 0;

  // Mesmas 4 abas nas duas visões; muda só a fonte dos dados.
  static const _paginasRmsp = [
    MananciaisPage(),
    RmspDashboardsPage(),
    RmspAlertsPage(),
    SettingsPage(),
  ];

  static const _paginasChennai = [
    HomePage(),
    DashboardsPage(),
    AlertsPage(),
    SettingsPage(),
  ];

  /// Botão "Ver" da notificação: abre os alertas da RMSP.
  void _abrirAlertasRmsp() {
    context.read<SettingsState>().setVisao(VisaoDados.rmsp);
    setState(() => _selectedIndex = _abaAlertas);
  }

  @override
  Widget build(BuildContext context) {
    final visao = context.watch<SettingsState>().visao;
    final pendentesChennai = context.watch<AlertsState>().pending.length;
    final pendentesRmsp = context.watch<MananciaisState>().pendentes.length;

    final rmsp = visao == VisaoDados.rmsp;
    final pages = rmsp ? _paginasRmsp : _paginasChennai;
    final pending = rmsp ? pendentesRmsp : pendentesChennai;

    return NotificadorAlertas(
      onVerAlertas: _abrirAlertasRmsp,
      child: Scaffold(
        body: IndexedStack(
          key: ValueKey(visao),
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
            const NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Painéis',
            ),
            NavigationDestination(
              icon: Badge.count(
                count: pending,
                isLabelVisible: pending > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: Badge.count(
                count: pending,
                isLabelVisible: pending > 0,
                child: const Icon(Icons.notifications),
              ),
              label: 'Alertas',
              tooltip: '$pending alertas aguardando revisão',
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
