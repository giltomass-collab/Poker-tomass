import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; // Keep this import for Player model or general UUID if needed elsewhere
import '../controllers/tournament_controller.dart';
import '../models/player.dart';
import '../models/payout.dart';
import 'bubble_agreement_page.dart'; // Import the BubbleAgreementPage

class PayoutsPage extends StatefulWidget {
  const PayoutsPage({super.key});

  @override
  State<PayoutsPage> createState() => _PayoutsPageState();
}

class _PayoutsPageState extends State<PayoutsPage> {
  final Map<String, TextEditingController> _amountControllers = {};

  @override
  void dispose() {
    _amountControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TournamentController>(context);
    final totalPool = controller.transactions
        .where((t) => t.type == 'buyin' || t.type == 'addon' || t.type == 'rebuy')
        .fold<int>(0, (sum, tx) => sum + tx.amount);
    final prizePool = totalPool;

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
          const SizedBox(height: 12),
          // Conditional "Acordo" button for bubble phase
          if (controller.isBubblePhase)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Implement bubble agreement logic here, e.g., navigate to bubble agreement page
                  // or trigger a specific bubble agreement process in the controller
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => BubbleAgreementPage()),
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

                final TextEditingController amountController =
                    _amountControllers.putIfAbsent(
                  p.id,
                  () => TextEditingController(text: p.amount.toString()),
                );
                // Ensure the text is updated if payout amount changes externally
                if (amountController.text != p.amount.toString()) {
                  amountController.text = p.amount.toString();
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text('${p.position} — ${player.name}'),
                    subtitle: Text('Acordo: ${p.agreed ? "Sim" : "Não"}'),
                    trailing: SizedBox(
                      width: 150, // Adjust width as needed
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: amountController, // Use the managed controller
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                prefixText: 'R\$ ',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              onChanged: (value) {
                                final newAmount = int.tryParse(value);
                                if (newAmount != null && newAmount >= 0) {
                                  controller.updatePayoutAmount(p.id, newAmount);
                                }
                              },
                              // Disable editing if already agreed
                              enabled: !p.agreed,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!p.agreed) // Only show agree button if not agreed
                            ElevatedButton(
                              onPressed: () {
                                controller.agreePayout(p.id);
                              },
                              child: const Text('Concordar'),
                            ),
                        ],
                      ),
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