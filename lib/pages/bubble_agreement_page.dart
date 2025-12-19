import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tournament_controller.dart';
import '../models/player.dart'; // Import Player model for orElse

class BubbleAgreementPage extends StatelessWidget {
  const BubbleAgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TournamentController>(context);

    // This section is simplified as payouts are now automatically calculated
    // No need for a "Calcular Premiações" button here
    // No need to calculate totalPool and prizePool here, use controller's values if available
    final totalPool = controller.transactions
        .where((t) =>
            t.type == 'buyin' || t.type == 'addon' || t.type == 'rebuy')
        .fold<int>(0, (sum, tx) => sum + tx.amount);
    final prizePool = totalPool;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acordo de Bolha'),
      ),
      body: Padding(
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
                    orElse: () => Player(id: payout.playerId, name: '—'),
                  );

                  return Card(
                    color: payout.agreed ? Colors.green[100] : null,
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${payout.position}')),
                      title: Text(player.name),
                      subtitle: Text('R\$ ${payout.amount}'),
                      trailing: ElevatedButton(
                        onPressed: payout.agreed
                            ? null
                            : () {
                                controller.agreedBubble(payout.playerId);
                                // Optionally pop after agreement, or wait for all to agree
                                // Navigator.of(context).pop();
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
            // "Recalcular" button removed as payouts are automatic
            // Consider adding a "Voltar" or "Concluir Acordo" button here
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Go back to PayoutsPage
              },
              child: const Text('Voltar para Premiações'),
            ),
          ],
        ),
      ),
    );
  }
}