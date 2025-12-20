import 'package:flutter/material.dart';
import 'dart:math';
import '../controllers/tournament_controller.dart';

class TimerClockWidget extends StatefulWidget {
  final TournamentController controller;

  const TimerClockWidget({super.key, required this.controller});

  @override
  State<TimerClockWidget> createState() => _TimerClockWidgetState();
}

class _TimerClockWidgetState extends State<TimerClockWidget> {
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
    final remaining = controller.remainingSeconds;
    final duration = level.durationSeconds;
    final progress = duration > 0 ? remaining / duration : 0.0;

    final isBreak = level.isBreak;
    final screenHeight = MediaQuery.of(context).size.height;
    final widgetHeight = screenHeight * 0.20; // occupy ~20% of screen height
    final circleSize = (widgetHeight * 0.8).clamp(60.0, 200.0);
    final innerCircleSize = circleSize * 0.9;
    final timeFontSize = (innerCircleSize * 0.25).clamp(18.0, 44.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: SizedBox(
        height: widgetHeight,
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: isBreak ? Colors.red.shade50 : Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 6.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Timer Section
                SizedBox(
                  height: widgetHeight, // Set height of timer section
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: innerCircleSize,
                          height: innerCircleSize,
                          child: CircularProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            strokeWidth: (circleSize * 0.07).clamp(6.0, 14.0),
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(
                              isBreak
                                  ? Colors.red.shade700
                                  : (controller.isRunning
                                      ? const Color.fromARGB(255, 18, 7, 82)
                                      : const Color.fromARGB(255, 3, 3, 74)),
                            ),
                          ),
                        ),
                        Text(
                          controller.formattedRemaining,
                          style: TextStyle(
                            fontSize: timeFontSize,
                            fontWeight: FontWeight.bold,
                            color: isBreak
                                ? Colors.red.shade900
                                : (controller.isRunning
                                    ? const Color.fromARGB(255, 17, 5, 84)
                                    : Colors.black87),
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16), // Spacer

                // Blinds, Level Info, and Controls Section
                Expanded(
                  child: SizedBox(
                    height: widgetHeight, // Set height of this combined section
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Controls and Current Level Text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Control buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                // Play/Pause
                                Tooltip(
                                  message: controller.isRunning
                                      ? 'Pausar'
                                      : 'Iniciar',
                                  child: IconButton(
                                    onPressed: () =>
                                        controller.toggleRunning(),
                                    icon: Icon(
                                      controller.isRunning
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                      size: 24, // Smaller size
                                      color: controller.isRunning
                                          ? Colors.green
                                          : Colors.blue,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Previous Level
                                Tooltip(
                                  message: 'Nível anterior',
                                  child: IconButton(
                                    onPressed: () =>
                                        controller.previousLevel(),
                                    icon: const Icon(
                                      Icons.skip_previous,
                                      size: 20, // Smaller size
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Next Level
                                Tooltip(
                                  message: 'Próximo nível',
                                  child: IconButton(
                                    onPressed: () => controller.nextLevel(),
                                    icon: const Icon(Icons.skip_next,
                                        size: 20), // Smaller size
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Reset current level
                                Tooltip(
                                  message: 'Reiniciar tempo do nível',
                                  child: IconButton(
                                    onPressed: () =>
                                        controller.resetCurrentLevel(),
                                    icon: const Icon(Icons.restart_alt,
                                        size: 18), // Smaller size
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ],
                            ),

                            // Current Level Text and Interval Chip
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Nível ${level.level}',
                                  style: const TextStyle(
                                    fontSize: 18, // Slightly smaller
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black, // Explicitly black
                                  ),
                                ),
                                if (isBreak) ...[
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: const Text('INTERVALO'),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                    labelStyle: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary),
                                    padding: EdgeInsets.zero, // Make chip smaller
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),

                        // Time slider for director control
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ajustar Tempo',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            Slider.adaptive(
                              min: 0,
                              max: duration.toDouble(),
                              value: remaining.clamp(0, duration).toDouble(),
                              onChanged: (v) =>
                                  controller.setRemaining(v.toInt()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
