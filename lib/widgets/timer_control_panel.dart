import 'package:flutter/material.dart';
import '../controllers/tournament_controller.dart';

class TimerControlPanel extends StatelessWidget {
  final TournamentController controller;

  const TimerControlPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Large timer display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: controller.isRunning
                  ? Colors.green[200]
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black26),
            ),
            child: GestureDetector(
              onLongPress: () => _showEditTimeDialog(context),
              child: Text(
                controller.formattedRemaining,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: controller.isRunning
                      ? Colors.green[900]
                      : Colors.black,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Play/Pause
          Tooltip(
            message: controller.isRunning ? 'Pausar' : 'Iniciar',
            child: Container(
              decoration: BoxDecoration(
                color: controller.isRunning ? Colors.orange : Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                iconSize: 24,
                onPressed: controller.toggleRunning,
                icon: Icon(
                  controller.isRunning ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Next Level
          Tooltip(
            message: 'Próximo nível',
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 0, 0, 0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                iconSize: 20,
                onPressed: controller.nextLevel,
                icon: const Icon(Icons.skip_next, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Previous Level
          Tooltip(
            message: 'Nível anterior',
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 0, 0, 0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                iconSize: 20,
                onPressed: controller.previousLevel,
                icon: const Icon(Icons.skip_previous, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Reset
          Tooltip(
            message: 'Reiniciar nível',
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                iconSize: 20,
                onPressed: () => controller.resetCurrentLevel(),
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTimeDialog(BuildContext context) {
    final minCtrl = TextEditingController(
      text: (controller.remainingSeconds ~/ 60).toString(),
    );
    final secCtrl = TextEditingController(
      text: (controller.remainingSeconds % 60).toString().padLeft(2, '0'),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Ajustar tempo'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: TextField(
                  controller: minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minutos'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: secCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Segundos'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final mins = int.tryParse(minCtrl.text) ?? 0;
                final secs = int.tryParse(secCtrl.text) ?? 0;
                controller.setRemaining(mins * 60 + secs);
                Navigator.of(ctx).pop();
              },
              child: const Text('Definir'),
            ),
          ],
        );
      },
    );
  }
}
