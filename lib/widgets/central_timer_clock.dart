import 'package:flutter/material.dart';
import 'dart:math';
import '../controllers/tournament_controller.dart';
import '../models/blind_level.dart';

class CentralTimerClock extends StatefulWidget {
  final TournamentController controller;

  const CentralTimerClock({super.key, required this.controller});

  @override
  State<CentralTimerClock> createState() => _CentralTimerClockState();
}

class _CentralTimerClockState extends State<CentralTimerClock> {
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

    final screenHeight = MediaQuery.of(context).size.height;
    final widgetHeight = screenHeight * 0.20; // occupy ~20% of screen height
    final circleSize = (widgetHeight * 0.9).clamp(60.0, 240.0);
    final innerCircleSize = circleSize * 0.9;
    final timeFontSize = (innerCircleSize * 0.25).clamp(18.0, 44.0);
    final sliderMaxWidth = min(MediaQuery.of(context).size.width * 0.35, 300.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: SizedBox(
        height: widgetHeight,
        child: Center(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: circleSize,
                    height: circleSize,
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
                            valueColor: AlwaysStoppedAnimation(controller.isRunning ? Colors.green : Colors.blue),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.formattedRemaining,
                              style: TextStyle(
                                fontSize: timeFontSize,
                                fontWeight: FontWeight.bold,
                                color: controller.isRunning ? Colors.green.shade800 : Colors.black87,
                                fontFamily: 'RobotoMono',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right side: level, blinds and controls in compact column
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: widgetHeight),
                    child: SingleChildScrollView(
                      physics: ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                        Text('Nível ${level.level}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 6),
                        _buildBlindsRow(level),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              tooltip: 'Iniciar / Pausar',
                              onPressed: () => controller.toggleRunning(),
                              icon: Icon(
                                controller.isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                size: 26,
                                color: controller.isRunning ? Colors.green : Colors.blue,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Nível anterior',
                              onPressed: () => controller.previousLevel(),
                              icon: const Icon(Icons.skip_previous, size: 20),
                            ),
                            IconButton(
                              tooltip: 'Próximo nível',
                              onPressed: () => controller.nextLevel(),
                              icon: const Icon(Icons.skip_next, size: 20),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: sliderMaxWidth,
                          child: Slider.adaptive(
                            min: 0,
                            max: duration.toDouble(),
                            value: remaining.clamp(0, duration).toDouble(),
                            onChanged: (v) => controller.setRemaining(v.toInt()),
                            onChangeEnd: (v) => controller.setRemaining(v.toInt()),
                          ),
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
      ),
    );
  }

  Widget _buildBlindsRow(BlindLevel level) {
    final anteText = (level.ante != null && level.ante! > 0) ? ' • A: ${level.ante}' : '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('SB ${level.smallBlind}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Text('BB ${level.bigBlind}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        if (anteText.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(anteText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]
      ],
    );
  }

}
