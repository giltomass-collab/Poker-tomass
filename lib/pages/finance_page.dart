import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tournament_controller.dart';
import '../models/player.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  String _sortBy = 'name'; // 'name', 'total', 'status'

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TournamentController>(context);

    // Calculate totals
    int totalBuyin = 0;
    int totalRake = 0;
    for (final p in controller.players) {
      totalBuyin += p.totalSpent;
    }
    totalRake = (totalBuyin * 0.2).toInt();
    final prizeFund = totalBuyin - totalRake;

    // Sort players
    final sortedPlayers = List<Player>.from(controller.players);
    switch (_sortBy) {
      case 'total':
        sortedPlayers.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
        break;
      case 'status':
        sortedPlayers.sort((a, b) {
          if (a.paid != b.paid) return (a.paid ? 1 : 0) - (b.paid ? 1 : 0);
          return a.name.compareTo(b.name);
        });
        break;
      default:
        sortedPlayers.sort((a, b) => a.name.compareTo(b.name));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // === Dashboard Header ===
            Card(
              elevation: 4,
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBox(
                          'Buy-in Total',
                          'R\$ $totalBuyin',
                          Colors.green,
                        ),
                        _buildStatBox(
                          'Rake (20%)',
                          'R\$ $totalRake',
                          Colors.red,
                        ),
                        _buildStatBox('Prêmio', 'R\$ $prizeFund', Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info,
                            size: 18,
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total: ${controller.players.length} jogadores',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // === Sort Controls ===
            Row(
              children: [
                const Text(
                  'Ordenar por:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'name', label: Text('Nome')),
                      ButtonSegment(value: 'total', label: Text('Gasto')),
                      ButtonSegment(value: 'status', label: Text('Status')),
                    ],
                    selected: {_sortBy},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _sortBy = newSelection.first;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // === Player List Table ===
            if (sortedPlayers.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: const Text(
                  'Nenhum jogador adicionado',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              _buildPlayerTable(sortedPlayers),

            const SizedBox(height: 16),

            // === Transaction History ===
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Histórico de Transações',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Divider(),
                    if (controller.transactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          'Sem transações',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.transactions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final t =
                              controller.transactions[controller
                                      .transactions
                                      .length -
                                  1 -
                                  i];
                          final player = controller.players.firstWhere(
                            (pl) => pl.id == t.playerId,
                            orElse: () => Player(id: t.playerId, name: '—'),
                          );
                          final icon = _getTransactionIcon(t.type);
                          final color = _getTransactionColor(t.type);

                          return ListTile(
                            leading: Container(
                              decoration: BoxDecoration(
                                color: color.withAlpha(50),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Icon(icon, color: color, size: 18),
                            ),
                            title: Text(player.name),
                            subtitle: Text(
                              '${t.type.toUpperCase()} • ${_formatTime(t.time)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              'R\$ ${t.amount}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[300],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerTable(List<Player> players) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Jogador')),
          DataColumn(label: Text('Buy-ins'), numeric: true),
          DataColumn(label: Text('Rebuys'), numeric: true),
          DataColumn(label: Text('Add-ons'), numeric: true),
          DataColumn(label: Text('Total Gasto'), numeric: true),
          DataColumn(label: Text('Status')),
        ],
        rows: players.map((p) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(Text('${p.buyins}')),
              DataCell(Text('${p.rebuys}')),
              DataCell(Text('${p.addons}')),
              DataCell(
                Text(
                  'R\$ ${p.totalSpent}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (p.paid)
                      const Text(
                        'Pago',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Text(
                        'Deve R\$ ${p.totalSpent}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (p.totalSpent > 0)
                      TextButton(
                        onPressed: () {
                          Provider.of<TournamentController>(
                            context,
                            listen: false,
                          ).togglePlayerPaidStatus(p.id);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          foregroundColor: p.paid ? Colors.grey : Colors.green,
                        ),
                        child: Text(
                          p.paid ? 'Desmarcar' : 'Marcar Pago',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'buyin':
        return Icons.monetization_on;
      case 'rebuy':
        return Icons.refresh;
      case 'addon':
        return Icons.add_circle;
      case 'payout':
        return Icons.card_giftcard;
      case 'fee':
        return Icons.calculate;
      default:
        return Icons.help;
    }
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'buyin':
        return Colors.blue;
      case 'rebuy':
        return Colors.orange;
      case 'addon':
        return Colors.green;
      case 'payout':
        return Colors.purple;
      case 'fee':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
