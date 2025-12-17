import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../controllers/tournament_controller.dart';
import '../models/player.dart';
import '../models/payout.dart';

class PayoutsPage extends StatefulWidget {
  const PayoutsPage({super.key});

  @override
  State<PayoutsPage> createState() => _PayoutsPageState();
}

class _PayoutsPageState extends State<PayoutsPage> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TournamentController>(context);
    final totalPool = _calculateTotalPool(controller);
    final rakeAmount = (totalPool * 0.2).toInt();
    final prizePool = totalPool - rakeAmount;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total (Pool):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('R\$ $totalPool'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rake (20%):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('R\$ $rakeAmount'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Prêmio Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'R\$ $prizePool',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _calculatePayouts(context, controller, prizePool),
            child: const Text('Calcular Premiação'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: controller.payouts.length,
              itemBuilder: (ctx, i) {
                final p = controller.payouts[i];
                final player = controller.players.firstWhere(
                  (pl) => pl.id == p.playerId,
                  orElse: () => Player(id: p.playerId, name: '—'),
                );
                return ListTile(
                  title: Text('${p.position} — ${player.name}'),
                  subtitle: Text('Acordo: ${p.agreed ? "Sim" : "Não"}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('R\$ ${p.amount}'),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: p.agreed
                            ? null
                            : () {
                                controller.agreePayout(p.id);
                              },
                        child: Text(p.agreed ? 'Acordado' : 'Concordar'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _calculateTotalPool(TournamentController controller) {
    var sum = 0;
    for (final t in controller.transactions) {
      if (t.type == 'buyin' || t.type == 'addon' || t.type == 'rebuy') {
        sum += t.amount;
      }
    }
    return sum;
  }

  void _calculatePayouts(
    BuildContext context,
    TournamentController controller,
    int prizePool,
  ) {
    // Get unique players in order: divide prizePool by number of players equally for now
    // In a real app: use a payout structure (e.g., 50%, 30%, 20%) // DONE
    final activePlayers = controller.players.where((p) => p.seated).toList();
    if (activePlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nenhum jogador sentado na mesa para calcular a premiação.',
          ),
        ),
      );
      return;
    }

    final payoutStructure = _getPayoutStructure(activePlayers.length);
    if (payoutStructure.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não há estrutura de premiação definida para este número de jogadores.',
          ),
        ),
      );
      return;
    }

    controller.payouts.clear();

    // Assume players are eliminated in reverse order of the list for now.
    // A real app would need a way to track elimination order.
    // For this simulation, we'll assign payouts to the first N players.
    final playersToPay = activePlayers.take(payoutStructure.length).toList();

    for (int i = 0; i < payoutStructure.length; i++) {
      final p = playersToPay[i];
      final percentage = payoutStructure[i];
      final amount = (prizePool * percentage).round();
      final position = '${i + 1}º';

      final payout = Payout(
        id: const Uuid().v4(),
        playerId: p.id,
        amount: amount,
        position: position,
      );
      controller.addPayout(payout);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Premiação calculada!')));
  }

  List<double> _getPayoutStructure(int playerCount) {
    if (playerCount <= 3) return [1.0]; // Winner takes all
    if (playerCount <= 5) return [0.65, 0.35]; // 2 places
    if (playerCount <= 7) return [0.50, 0.30, 0.20]; // 3 places
    if (playerCount <= 10) return [0.45, 0.25, 0.15, 0.15]; // 4 places
    // Example structures, can be expanded
    // Based on PokerStars 9-man SNG
    if (playerCount == 9) return [0.50, 0.30, 0.20];

    // A more generic approach for larger fields
    if (playerCount <= 15) {
      // 4 places
      return [0.40, 0.30, 0.20, 0.10];
    }
    if (playerCount <= 20) {
      // 5 places
      return [0.35, 0.25, 0.18, 0.12, 0.10];
    }

    // Default for very large fields (e.g., top 10%)
    // This is a simplification. Real structures are more complex.
    if (playerCount > 20) {
      return [0.30, 0.20, 0.15, 0.12, 0.10, 0.08, 0.05]; // 7 places
    }

    return []; // No structure defined
  }
}
