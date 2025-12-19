import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tomasspoker/models/financial_summary.dart';
import 'package:tomasspoker/models/payment_status.dart';
import 'package:tomasspoker/models/player_transaction.dart';
import '../controllers/tournament_controller.dart';
import '../models/player.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  String _sortBy = 'name'; // 'name', 'balance'

  void _showAddExpenseDialog() {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Despesa'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira uma descrição.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira um valor.';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Por favor, insira um número válido.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final description = descriptionController.text;
                  final amount = int.parse(amountController.text);
                  Provider.of<TournamentController>(context, listen: false)
                      .addExpense(description, amount);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TournamentController>(context);
    final summary = controller.getFinancialSummary();

    // Sort players
    final sortedPlayerBalances =
        List<PlayerBalance>.from(summary.playerBalances);
    switch (_sortBy) {
      case 'balance':
        sortedPlayerBalances
            .sort((a, b) => b.netBalance.compareTo(a.netBalance));
        break;
      default: // name
        sortedPlayerBalances.sort((a, b) => a.playerName.compareTo(b.playerName));
    }

    return Scaffold(
      body: SingleChildScrollView(
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
                            'R\$ ${summary.totalBuyin}',
                            Colors.green,
                          ),
                          _buildStatBox(
                            'Despesas',
                            'R\$ ${summary.totalExpenses}',
                            Colors.red,
                          ),
                          _buildStatBox('Prêmio', 'R\$ ${summary.prizePool}',
                              Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Total: ${controller.players.length} jogadores',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onTertiaryContainer,
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
                        ButtonSegment(
                            value: 'balance', label: Text('Balanço')),
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
              if (sortedPlayerBalances.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  child: const Text(
                    'Nenhum jogador adicionado',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                _buildPlayerBalanceTable(context, sortedPlayerBalances),

              const SizedBox(height: 16),

              _buildExpensesCard(controller),

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
                      if (controller.transactions
                          .where((PlayerTransaction t) =>
                              t.type != 'expense' && t.type != 'fee')
                          .isEmpty)
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
                          itemCount: controller.transactions
                              .where((PlayerTransaction t) =>
                                  t.type != 'expense' && t.type != 'fee')
                              .length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final transactions = controller.transactions
                                .where((PlayerTransaction t) =>
                                    t.type != 'expense' && t.type != 'fee')
                                .toList();
                            final t =
                                transactions[transactions.length - 1 - i];
                            final player = controller.players.firstWhere(
                              (pl) => pl.id == t.playerId,
                              orElse: () =>
                                  Player(id: t.playerId, name: '—'),
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
                                child:
                                    Icon(icon, color: color, size: 18),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Despesa',
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

  Widget _buildPlayerBalanceTable(
      BuildContext context, List<PlayerBalance> balances) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Jogador')),
          DataColumn(label: Text('Buy-ins'), numeric: true),
          DataColumn(label: Text('Rebuys'), numeric: true),
          DataColumn(label: Text('Add-ons'), numeric: true),
          DataColumn(label: Text('Gasto'), numeric: true),
          DataColumn(label: Text('Prêmio'), numeric: true),
          DataColumn(label: Text('Balanço'), numeric: true),
          DataColumn(label: Text('Pago')),
        ],
        rows: balances.map((balance) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  balance.playerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(Text('${balance.buyins}')),
              DataCell(Text('${balance.rebuys}')),
              DataCell(Text('${balance.addons}')),
              DataCell(
                Text(
                  'R\$ ${balance.totalSpent}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
              DataCell(
                Text(
                  'R\$ ${balance.payout}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.purple),
                ),
              ),
              DataCell(
                Text(
                  'R\$ ${balance.netBalance}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: balance.netBalance == 0
                        ? Colors.grey
                        : balance.netBalance > 0
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
              ),
              DataCell(
                DropdownButton<PaymentStatus>(
                  value: balance.paymentStatus,
                  onChanged: (PaymentStatus? newValue) {
                    if (newValue != null) {
                      Provider.of<TournamentController>(context,
                              listen: false)
                          .updatePlayerPaymentStatus(
                              balance.playerId, newValue);
                    }
                  },
                  items: PaymentStatus.values
                      .map<DropdownMenuItem<PaymentStatus>>(
                          (PaymentStatus status) {
                    return DropdownMenuItem<PaymentStatus>(
                      value: status,
                      child: Text(_getPaymentStatusText(status)),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getPaymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Sim';
      case PaymentStatus.none:
        return 'Não';
      case PaymentStatus.partial:
        return 'Parcial';
      case PaymentStatus.credit:
        return 'Fiado';
      default:
        return '';
    }
  }

  Widget _buildExpensesCard(TournamentController controller) {
    final expenses = controller.transactions
        .where((PlayerTransaction t) => t.type == 'expense' || t.type == 'fee')
        .toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Despesas do Torneio',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Divider(),
            if (expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Nenhuma despesa adicionada',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final t = expenses[expenses.length - 1 - i];
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
                    title: Text(t.type
                        .toUpperCase()), // Or a description if available
                    subtitle: Text(
                      'Adicionado em ${_formatTime(t.time)}',
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
      case 'expense':
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
      case 'expense':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
