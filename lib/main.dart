import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/tournament_controller.dart';
import 'pages/players_page.dart';
import 'pages/table_page.dart';
import 'pages/finance_page.dart';
import 'pages/bubble_agreement_page.dart';
import 'pages/payouts_page.dart';
import 'pages/settings_page.dart';
import 'widgets/central_timer_clock.dart';

void main() {
  runApp(const TomassPokerApp());
}

class TomassPokerApp extends StatelessWidget {
  const TomassPokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TournamentController(),
      child: MaterialApp(
        title: 'TomasPoker',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<String> _titles = [
    'Jogadores', // 0
    'Mesa', // 1
    'Financeiro', // 2
    'Bolha', // 3
    'Premiação', // 4
    'Configurações', // 5
  ];

  static const List<NavigationRailDestination> _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.people),
      label: Text('Jogadores'),
    ),
    NavigationRailDestination(icon: Icon(Icons.table_bar), label: Text('Mesa')),
    NavigationRailDestination(
      icon: Icon(Icons.attach_money),
      label: Text('Financeiro'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.handshake),
      label: Text('Acordo Bolha'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.card_giftcard),
      label: Text('Premiação'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings),
      label: Text('Configurações'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TournamentController>(context);

    final pages = <Widget>[
      const PlayersPage(),
      const TablePage(),
      const FinancePage(),
      const BubbleAgreementPage(),
      const PayoutsPage(),
      const SettingsPage(),
    ];

    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          labelType: NavigationRailLabelType.all,
          destinations: _destinations,
          leading: const FlutterLogo(),
          trailing: const Expanded(child: SizedBox()),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: Scaffold(
            appBar: AppBar(
              title: Text(_titles[_selectedIndex]),
              toolbarHeight: 80,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reiniciar Torneio',
                  onPressed: () => _showRestartDialog(context, controller),
                ),
                IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: 'Desfazer última ação',
                  onPressed: () {
                    final message = controller.undoLastTransaction();
                    if (message != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Column(
              children: [
                // Central clock shown at top center across pages
                CentralTimerClock(controller: controller),
                Expanded(child: pages[_selectedIndex]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showRestartDialog(
    BuildContext context,
    TournamentController controller,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reiniciar Torneio?'),
        content: const Text(
          'Esta ação apagará todos os jogadores, transações e dados do torneio atual. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              controller.restartTournament();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Torneio reiniciado.')),
              );
            },
            child: const Text('Reiniciar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
