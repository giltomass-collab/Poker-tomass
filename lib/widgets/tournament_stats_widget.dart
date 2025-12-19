import 'package:flutter/material.dart';
import '../controllers/tournament_controller.dart';

class TournamentStatsWidget extends StatefulWidget {
  final TournamentController controller;

  const TournamentStatsWidget({super.key, required this.controller});

  @override
  State<TournamentStatsWidget> createState() => _TournamentStatsWidgetState();
}

class _TournamentStatsWidgetState extends State<TournamentStatsWidget> {
  late TournamentController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    controller.addListener(_onChange);
  }

  void _onChange() => setState(() {});

  @override
  void dispose() {
    controller.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final players = controller.players;
    final activePlayers = players.where((p) => p.seated).length;
    final totalPlayers = players.length;
    final totalChips = players.fold<int>(0, (sum, p) => sum + p.chips);
    final totalRebuys = players.fold<int>(0, (sum, p) => sum + p.rebuys);
    final totalAddons = players.fold<int>(0, (sum, p) => sum + p.addons);
    final prizePool = controller.transactions
        .where((t) =>
            t.type == 'buyin' || t.type == 'rebuy' || t.type == 'addon')
        .fold<int>(0, (sum, t) => sum + t.amount);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                _buildStat('Jogadores', '$activePlayers/$totalPlayers'),
                _buildStat('Fichas', '$totalChips'),
                _buildStat('Rebuys', '$totalRebuys'),
                _buildStat('Add-ons', '$totalAddons'),
                _buildStat('Prêmio Total', 'R\$ $prizePool'),
              ],
            ),
            const Divider(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  controller.calculatePayouts();
                });
              },
              child: const Text('Calcular Premiação'),
            ),
            if (controller.payouts.isNotEmpty)
              ...controller.payouts.map(
                (payout) {
                  final player = controller.playerById(payout.playerId);
                  return ListTile(
                    dense: true,
                    title: Text(
                        '${payout.position} - ${player?.name ?? "Jogador não encontrado"}'),
                    trailing: Text('R\$ ${payout.amount}'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
