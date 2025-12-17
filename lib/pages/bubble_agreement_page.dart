import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tournament_controller.dart';

class BubbleAgreementPage extends StatelessWidget {
  const BubbleAgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TournamentController>(context);

    if (controller.payouts.isEmpty) {
      return Center(
        child: ElevatedButton(
          onPressed: () => controller.calculatePayouts(),
          child: const Text('Calcular Premiações'),
        ),
      );
    }

    final totalPool = _calculateTotalPool(controller);
    final rake = (totalPool * 0.2).toInt();
    final prizePool = totalPool - rake;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Prêmio Total:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'R\$ $prizePool',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rake:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'R\$ $rake',
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: controller.payouts.length,
              itemBuilder: (ctx, i) {
                final payout = controller.payouts[i];
                final player = controller.players.firstWhere(
                  (p) => p.id == payout.playerId,
                );

                return Card(
                  color: payout.agreed ? Colors.green[100] : null,
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${payout.position}°')),
                    title: Text(player.name),
                    subtitle: Text('R\$ ${payout.amount}'),
                    trailing: ElevatedButton(
                      onPressed: payout.agreed
                          ? null
                          : () {
                              controller.agreedBubble(payout.playerId);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: payout.agreed
                            ? Colors.green
                            : Colors.blue,
                      ),
                      child: Text(
                        payout.agreed ? 'Concordado' : 'Concordar',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              controller.calculatePayouts();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Recalcular'),
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
}
