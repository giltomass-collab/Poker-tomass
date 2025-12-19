import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tournament_controller.dart';
import 'bubble_agreement_page.dart'; // Import the BubbleAgreementPage

class PayoutsPage extends StatelessWidget {
  const PayoutsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TournamentController>(context);
    final totalPool = controller.transactions
        .where((t) => t.type == 'buyin' || t.type == 'addon' || t.type == 'rebuy')
        .fold<int>(0, (sum, tx) => sum + tx.amount);
    final prizePool = totalPool;
    final payouts = controller.payouts;

    // Create a string for the payout positions, e.g., "1º, 2º, 3º"
    final payoutPositions = payouts.map((p) => p.position).join(', ');

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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prêmio Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'R\$ $prizePool',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (payoutPositions.isNotEmpty)
                              Text(
                                'Premiação para: $payoutPositions',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.right,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Conditional "Acordo" button for bubble phase
          if (controller.isBubblePhase)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const BubbleAgreementPage()),
                  );
                },
                icon: const Icon(Icons.handshake),
                label: const Text('Fazer Acordo de Bolha'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          const SizedBox(height: 20),
          // A title for the section below the card
          if (payouts.isNotEmpty)
            const Text(
              'Detalhes da Premiação',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 10),

          // Display payout details in a non-editable list
          Expanded(
            child: ListView.builder(
              itemCount: payouts.length,
              itemBuilder: (ctx, i) {
                final p = payouts[i];
                // Player name is not available here unless we search for it.
                // For now, just show position and amount.
                final player = controller.playerById(p.playerId);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        p.position.replaceAll('º', ''),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text('Posição: ${p.position}'),
                    subtitle: Text(player != null ? 'Jogador: ${player.name}' : 'Aguardando definição...'),
                    trailing: Text(
                      'R\$ ${p.amount}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}