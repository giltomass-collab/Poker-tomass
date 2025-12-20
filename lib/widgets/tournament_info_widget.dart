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

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Current Blinds, Ante and Next Level Preview
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildBlindsDisplayWidget(level),
                  ),
                  const SizedBox(width: 8),
                  const VerticalDivider(
                      width: 1, thickness: 1, indent: 8, endIndent: 8),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _buildNextLevelPreview(),
                  ),
                ],
              ),
            ),

            if (isBreak) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => controller.addonForAllEligiblePlayers(),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add-on para Todos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildBlindsDisplayWidget(BlindLevel level) {
    final ante = level.bigBlind; // Ante igual ao BB
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInfoBox('Small Blind', '${level.smallBlind}', Colors.blue),
        _buildInfoBox('Big Blind', '${level.bigBlind}', Colors.red),
        _buildInfoBox('Ante', '$ante', Colors.orange),
      ],
    );
  }

  Widget _buildNextLevelPreview() {
    final currentIdx = widget.controller.currentLevelIndex;
    final levels = widget.controller.levels;

    if (currentIdx >= levels.length - 1) {
      return const Text(
        'Último nível',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }

    final nextLevel = levels[currentIdx + 1];
    final nextAnte = nextLevel.bigBlind;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'PRÓXIMO NÍVEL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const Divider(height: 10),
          Text(
            '${nextLevel.label}: ${nextLevel.smallBlind} / ${nextLevel.bigBlind} / $nextAnte',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
