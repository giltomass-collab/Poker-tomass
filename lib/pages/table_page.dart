import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tournament_controller.dart';
import '../models/player.dart';
import '../models/player_move.dart';

class TablePage extends StatefulWidget {
  const TablePage({super.key});

  @override
  State<TablePage> createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = Provider.of<TournamentController>(
      context,
      listen: false,
    );
    // Use a post-frame callback to show the dialog after the build is complete.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.pendingPlayerMoves.isNotEmpty) {
        _showTableBalancingDialog(context, controller.pendingPlayerMoves);
        controller.pendingPlayerMoves.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TournamentController>(context);
    final seatedPlayers = controller.players.where((p) => p.seated).toList();
    final numTables = seatedPlayers.isEmpty
        ? 1
        : (seatedPlayers.length / 9).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Make tables scrollable horizontally if they don't fit
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(numTables, (index) {
              final tableNumber = index + 1;
              final playersForTable = seatedPlayers
                  .where((p) => p.tableNumber == tableNumber)
                  .toList();
              return PokerTableWidget(
                tableNumber: tableNumber,
                players: playersForTable,
                controller: controller,
              );
            }),
          ),
        );
      },
    );
  }

  void _showTableBalancingDialog(BuildContext context, List<PlayerMove> moves) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Balanceamento de Mesas'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: moves.length,
            itemBuilder: (context, index) {
              final move = moves[index];
              return ListTile(
                leading: const Icon(Icons.sync_alt),
                title: Text(
                  move.player.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Mesa ${move.fromTable}:${move.fromSeat} → Mesa ${move.toTable}:${move.toSeat}',
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class PokerTableWidget extends StatelessWidget {
  final int tableNumber;
  final List<Player> players;
  final TournamentController controller;

  const PokerTableWidget({
    super.key,
    required this.tableNumber,
    required this.players,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Theme.of(context).colorScheme.surface.withGreen(100)),
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = min(
                constraints.maxWidth,
                constraints.maxHeight,
              ).clamp(300.0, 600.0);
              final tableWidth = size;
              final tableHeight = size * 0.7;
              final centerX = tableWidth / 2;
              final centerY = tableHeight / 2;
              // Definir raios elípticos para o posicionamento dos jogadores
              final radiusX = tableWidth * 0.47;
              final radiusY = tableHeight * 0.47;

              return SizedBox(
                width: tableWidth,
                height: tableHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Chip(label: Text('Mesa $tableNumber')),
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: tableWidth * 0.95,
                          height: tableHeight * 0.85,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 23, 80, 55),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color.fromARGB(255, 13, 49, 33),
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    for (int i = 0; i < 9; i++) ...[
                      _seatWidget(
                        index: i,
                        totalSeats: 9,
                        playersOnTable: players,
                        centerX: centerX,
                        centerY: centerY,
                        radiusX: radiusX,
                        radiusY: radiusY,
                        context: context,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _seatWidget({
    required int index,
    required int totalSeats,
    required List<Player> playersOnTable,
    required double centerX,
    required double centerY,
    required double radiusX,
    required double radiusY,
    required BuildContext context,
  }) {
    final seatNumber = index + 1;

    // Mapeia o número do assento (1-9) para um ângulo.
    // O assento 5 (índice 4) fica no topo (-PI/2).
    // Os assentos são distribuídos no sentido horário.
    // Ajuste para centralizar o assento 5 no topo e distribuir os outros simetricamente.
    // O ângulo inicial é deslocado para que o assento 1 fique à esquerda do topo.
    final angle =
        -pi / 2 - (pi / totalSeats) + (seatNumber * (2 * pi / totalSeats));

    // Calcula a posição usando raios elípticos
    final x = centerX + radiusX * cos(angle);
    final y = centerY + radiusY * sin(angle);

    final avatarRadius = 15.0;
    final Player? player = playersOnTable.firstWhereOrNull(
      (p) => p.seat == index + 1,
    );

    return Positioned(
      left: x - 35,
      top: y - 25,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (player != null && player.seated)
            GestureDetector(
              onTap: () => _showBuyinMenu(context, controller, player),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.8),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: Colors.blue[300],
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 65,
                      child: Text(
                        player.name,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      width: 65,
                      child: Text(
                        '💰 ${player.chips}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.yellowAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Show rebuy/addon counts
                    SizedBox(
                      width: 65,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (player.rebuys > 0)
                            Text(
                              '🔄${player.rebuys}',
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.orange,
                              ),
                            ),
                          if (player.rebuys > 0 && player.addons > 0)
                            const SizedBox(width: 2),
                          if (player.addons > 0)
                            Text(
                              '➕${player.addons}',
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.lightGreen,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => _showSeatPlayerMenu(context, controller, index + 1),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Colors.grey[500],
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 65,
                    child: Text(
                      'Vazio',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showBuyinMenu(
    BuildContext context,
    TournamentController controller,
    Player player,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${player.name} - Chips: ${player.chips}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Nível: ${controller.currentLevel.label}',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Botão de Rebuy
                  if (controller.isRebuyAllowed)
                    SizedBox(
                      width: 90,
                      child: ElevatedButton(
                        onPressed: () {
                          controller.rebuy(player.id, controller.rebuyAmount);
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Rebuy',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              'R\$ ${controller.rebuyAmount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Botão de Rebuy Duplo
                  if (controller.isRebuyAllowed)
                    SizedBox(
                      width: 90,
                      child: ElevatedButton(
                        onPressed: () {
                          controller.doubleRebuy(
                            player.id,
                            controller.rebuyAmount,
                          );
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '2x Rebuy',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              'R\$ ${controller.rebuyAmount * 2}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Botão de Add-on
                  if (controller.isAddonAllowed)
                    Builder(
                      builder: (context) {
                        final canAddon =
                            controller.isAddonAllowed && player.addons == 0;
                        return SizedBox(
                          width: 90,
                          child: ElevatedButton(
                            onPressed: canAddon
                                ? () {
                                    controller.addon(
                                      player.id,
                                      controller.addonAmount,
                                    );
                                    Navigator.of(ctx).pop();
                                  }
                                : null, // Desabilita se não puder fazer addon
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              disabledBackgroundColor: Colors.grey.shade700,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Add-On',
                                  style: TextStyle(
                                    color: canAddon
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  'R\$ ${controller.addonAmount}',
                                  style: TextStyle(
                                    color: canAddon
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      controller.eliminatePlayer(player.id);
                      Navigator.of(ctx).pop();
                    },
                    icon: const Icon(Icons.person_remove, size: 16),
                    label: const Text('Eliminar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                    ),
                    child: const Text(
                      'Fechar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSeatPlayerMenu(
    BuildContext context,
    TournamentController controller,
    int seat,
  ) {
    final unseatedPlayers = controller.players.where((p) => !p.seated).toList();
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sentar - Lugar $seat',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: unseatedPlayers.length,
                  itemBuilder: (ctx, i) {
                    final p = unseatedPlayers[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(p.name.isNotEmpty ? p.name[0] : '?'),
                      ),
                      title: Text(p.name),
                      onTap: () {
                        controller.seatPlayer(p.id, seat);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
