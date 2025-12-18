import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tournament_controller.dart';
import '../models/player.dart';

class PlayerRanking {
  final Player player;
  final int totalPrizes;
  final int totalSpent;
  final int profit;
  final double roi;

  PlayerRanking({
    required this.player,
    required this.totalPrizes,
    required this.totalSpent,
  })  : profit = totalPrizes - totalSpent,
        roi = totalSpent > 0 ? (totalPrizes - totalSpent) / totalSpent * 100 : 0;
}

class RankingPage extends StatelessWidget {
  const RankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TournamentController>(context);

    final List<PlayerRanking> rankings = controller.players.map((player) {
      final prizes = controller.getTransactionsForPlayer(player.id, type: 'payout').fold<int>(0, (sum, tx) => sum + tx.amount);
      final spent = player.totalSpent; // totalSpent is already an aggregate

      return PlayerRanking(
        player: player,
        totalPrizes: prizes,
        totalSpent: spent,
      );
    }).toList();

    // Sort by profit (descending)
    rankings.sort((a, b) => b.profit.compareTo(a.profit));

    return Scaffold(
      body: rankings.isEmpty
          ? const Center(
              child: Text(
                'Nenhum jogador cadastrado para exibir o ranking.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: rankings.length,
              itemBuilder: (context, index) {
                final ranking = rankings[index];
                final player = ranking.player;
                final position = index + 1;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    leading: _buildPositionIndicator(position),
                    title: Text(
                      player.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: _buildStatsRow(ranking),
                    trailing: _buildProfitIndicator(ranking.profit),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildPositionIndicator(int position) {
    Color color;
    switch (position) {
      case 1:
        color = Colors.amber;
        break;
      case 2:
        color = Colors.grey.shade400;
        break;
      case 3:
        color = Colors.brown.shade400;
        break;
      default:
        color = Colors.transparent;
    }
    return CircleAvatar(
      backgroundColor: color,
      child: Text(
        '$position',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildStatsRow(PlayerRanking ranking) {
    final roiText = 'ROI: ${ranking.roi.toStringAsFixed(1)}%';
    final roiColor = ranking.roi >= 0 ? Colors.green : Colors.red;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Prêmios: R\$${ranking.totalPrizes}'),
        const Text(' • '),
        Text('Gasto: R\$${ranking.totalSpent}'),
        const Text(' • '),
        Text(roiText, style: TextStyle(color: roiColor, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildProfitIndicator(int profit) {
    final color = profit >= 0 ? Colors.green : Colors.red;
    final sign = profit >= 0 ? '+' : '';
    return Text(
      '${sign}R\$ $profit',
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
}