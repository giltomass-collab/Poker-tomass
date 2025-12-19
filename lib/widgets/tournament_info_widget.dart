import 'package:flutter/material.dart';
import '../controllers/tournament_controller.dart';
import '../models/blind_level.dart';

class TournamentInfoWidget extends StatefulWidget {
  final TournamentController controller;

  const TournamentInfoWidget({super.key, required this.controller});

  @override
  State<TournamentInfoWidget> createState() => _TournamentInfoWidgetState();
}

class _TournamentInfoWidgetState extends State<TournamentInfoWidget> {
  late TournamentController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;
    controller.addListener(_onChange);
  }

  void _onChange() => setState(() {});

  @override
  void dispose() {
    controller.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = controller.currentLevel;
    final isBreak = level.isBreak;
    final screenHeight = MediaQuery.of(context).size.height;
    final widgetHeight = screenHeight * 0.20; // occupy ~20% of screen height

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widgetHeight),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Current Level
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Nível: ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isBreak
                        ? Colors.red.shade700
                        : Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${level.level}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isBreak
                        ? Colors.red.shade700
                        : Colors.grey.shade700,
                  ),
                ),
                if (isBreak) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Chip(
                      label: const Text(
                        'INTERVALO',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.red.shade700,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => controller.addonForAllEligiblePlayers(),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Add-on para Todos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ]
              ],
            ),
            const SizedBox(height: 8),

            // Current Blinds, Ante
            _buildBlindsDisplayWidget(level),
            const SizedBox(height: 8),

            // Next Level Preview
            _buildNextLevelPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildBlindsDisplayWidget(BlindLevel level) {
    final ante = level.bigBlind; // Ante igual ao BB
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SB',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  Text(
                    '${level.smallBlind}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BB',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  Text(
                    '${level.bigBlind}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ante',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  Text(
                    '$ante',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextLevelPreview() {
    final currentIdx = widget.controller.currentLevelIndex;
    final levels = widget.controller.levels;

    if (currentIdx >= levels.length - 1) {
      return const Text(
        'Último nível',
        style: TextStyle(fontSize: 10, color: Colors.grey),
      );
    }

    final nextLevel = levels[currentIdx + 1];
    final nextAnte = nextLevel.bigBlind;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Próxima Blind:',
            style: TextStyle(fontSize: 9, color: Colors.grey),
          ),
          Text(
            '${nextLevel.label}: SB ${nextLevel.smallBlind} / BB ${nextLevel.bigBlind} / A $nextAnte',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
