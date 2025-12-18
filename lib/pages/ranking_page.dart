import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tournament_controller.dart';

class RankingPage extends StatelessWidget {
  const RankingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TournamentController>(
      builder: (context, controller, _) {
        final players = controller.players;

        if (players.isEmpty) {
          return const Center(child: Text('Nenhum jogador adicionado'));
        }

        // Sort players by chips
        final sortedPlayers = List.from(players)
          ..sort((a, b) => b.chips.compareTo(a.chips));

        return ListView.builder(
          itemCount: sortedPlayers.length,
          itemBuilder: (context, index) {
            final player = sortedPlayers[index];
            return ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(player.name),
              subtitle: Text('Mesa: ${player.table}, Assento: ${player.seat}'),
              trailing: Text(
                'R\$ ${player.chips}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
