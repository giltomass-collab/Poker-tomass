import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../controllers/tournament_controller.dart';
import '../models/player.dart';

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
            t.type == 'buyin' ||
            t.type == 'rebuy' ||
            t.type == 'double_rebuy' ||
            t.type == 'addon')
        .fold<int>(0, (sum, t) => sum + t.amount);
    final payouts = controller.payouts;

    final List<Widget> stats = [
      _buildStat('Jogadores', '$activePlayers/$totalPlayers'),
      _buildStat('Fichas', '$totalChips'),
      _buildStat('Rebuys', '$totalRebuys'),
      _buildStat('Add-ons', '$totalAddons'),
      _buildStat(
        'Prêmio Total',
        'R\$ $prizePool',
        valueColor: Colors.green.shade300,
      ),
    ];

    if (payouts.isNotEmpty) {
      stats.addAll(payouts.map((payout) {
        final position = int.tryParse(payout.position.replaceAll('º', ''));
        Player? winner;
        if (position != null) {
          winner = controller.players
              .firstWhereOrNull((p) => p.finishingRank == position);
        }

        return _buildStat(
          '${payout.position}º Lugar',
          'R\$ ${payout.amount}',
          valueColor: position == 1 ? Colors.blue.shade300 : null,
          subValue: winner?.name,
        );
      }).toList());
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          spacing: 16.0,
          runSpacing: 8.0,
          alignment: WrapAlignment.spaceEvenly,
          children: stats,
        ),
      ),
    );
  }

  Widget _buildStat(
    String label,
    String value, {
    Color? valueColor,
    String? subValue,
  }) {
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        if (subValue != null) ...[
          const SizedBox(height: 2),
          Text(
            subValue,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade300,
              fontStyle: FontStyle.italic,
            ),
          ),
        ]
      ],
    );
  }
}
