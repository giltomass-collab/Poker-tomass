import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tournament_controller.dart';
import '../models/player.dart';

class TablePage extends StatelessWidget {
  const TablePage({super.key});

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
        Container(color: Colors.green[700]),
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
              final radius = min(tableWidth, tableHeight) * 0.35;
              // offset to place player widgets outside the table rim
              final avatarOffset = 48.0;

              return SizedBox(
                width: tableWidth,
                height: tableHeight,
                child: Stack(
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
                            color: Colors.green[700],
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.green[900]!,
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
                        radius: radius,
                        avatarOffset: avatarOffset,
                        context: context,
                      ),
                    ],
                    _deckWidget(centerX, centerY),
                    _dealerWidget(centerX, centerY, radius),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _deckWidget(double centerX, double centerY) {
    return Positioned(
      left: centerX - 25, // Metade da largura do baralho
      top: centerY - 18, // Metade da altura do baralho
      child: Container(
        width: 50,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black54, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 5,
              offset: const Offset(2, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dealerWidget(double centerX, double centerY, double radius) {
    // Position the dealer at the top-center, similar to a seat
    final angle = -pi / 2; // Straight up
    final dealerRadius = radius + 10; // Slightly closer than players
    final x = centerX + dealerRadius * cos(angle);
    final y = centerY + dealerRadius * sin(angle);

    return Positioned(
      left: x - 35, // center the widget
      top: y - 15, // center the widget
      child: const Chip(
        label: Text('Dealer'),
        avatar: Icon(Icons.person, size: 16),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        backgroundColor: Colors.black54,
        labelStyle: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _seatWidget({
    required int index,
    required int totalSeats,
    required List<Player> playersOnTable,
    required double centerX,
    required double centerY,
    required double radius,
    required double avatarOffset,
    required BuildContext context,
  }) {
    // Shift so seat 5 (index 4) is top-center in front of dealer
    // Corrected angle calculation for standard poker layout
    // Dealer is at -PI/2 (top). Seat 1 is to the dealer's left.
    // We map seat number (1-9) to an angle.
    final seatNumber = index + 1;
    // Corrected angle for symmetry: Seat 1 is left of dealer, Seat 9 is right.
    // Map seats 1-9 to a range around the table.
    final angle =
        -pi / 2 - (pi / totalSeats) + (seatNumber * (2 * pi / totalSeats));
    final seatRadius = radius + avatarOffset;
    final x = centerX + seatRadius * cos(angle);
    final y = centerY + seatRadius * sin(angle);
    final avatarRadius = 15.0;
    final Player? player = playersOnTable.firstWhereOrNull(
      (p) => p.seat == index + 1,
    );

    // position player widget centered at calculated x,y (slightly outside table)
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
    final amounts = [100, 500, 1000, 2000, 5000];
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
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...amounts.map(
                    (amt) => SizedBox(
                      width: 90,
                      child: ElevatedButton(
                        onPressed: () {
                          controller.buyIn(player.id, amt);
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Buy-In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              'R\$ $amt',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ...amounts.map(
                    (amt) => SizedBox(
                      width: 90,
                      child: ElevatedButton(
                        onPressed: () {
                          controller.rebuy(player.id, amt);
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
                              'R\$ $amt',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ...amounts.map(
                    (amt) => SizedBox(
                      width: 90,
                      child: ElevatedButton(
                        onPressed: () {
                          controller.doubleRebuy(player.id, amt);
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
                              'R\$ ${amt * 2}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ...amounts.map(
                    (amt) => SizedBox(
                      width: 90,
                      child: ElevatedButton(
                        onPressed: () {
                          controller.addon(player.id, amt);
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Add-On',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              'R\$ $amt',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
