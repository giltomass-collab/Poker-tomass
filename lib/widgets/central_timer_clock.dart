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

    final isBreak = level.isBreak;
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Left panel: pending moves
                  if (controller.pendingPlayerMoves.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      constraints: BoxConstraints(maxWidth: 200),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Movimentos',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: controller.pendingPlayerMoves
                                    .map(
                                      (m) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 2.0,
                                        ),
                                        child: Text(
                                          '${m.player.name}\nT\$${m.fromTable}:S\$${m.fromSeat} → T\$${m.toTable}:S\$${m.toSeat}',
                                          style: const TextStyle(fontSize: 8),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),

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
                            valueColor: AlwaysStoppedAnimation(
                              isBreak
                                  ? Colors.red.shade700
                                  : (controller.isRunning
                                        ? Colors.green
                                        : Colors.blue),
                            ),
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
                                color: isBreak
                                    ? Colors.red.shade900
                                    : (controller.isRunning
                                          ? Colors.green.shade800
                                          : Colors.black87),
                                fontFamily: 'RobotoMono',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right side: level, blinds and controls in sophisticated column
                  ConstrainedBox(
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
                            children: [
                              Text(
                                'Nível: ${level.label}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isBreak
                                      ? Colors.red.shade700
                                      : Colors.grey.shade700,
                                ),
                              ),
                              if (isBreak)
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
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Current Blinds, Ante
                          _buildBlindsDisplayWidget(level),
                          const SizedBox(height: 8),

                          // Next Level Preview
                          _buildNextLevelPreview(),
                          const SizedBox(height: 10),

                          // Control buttons row
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              // Play/Pause
                              Tooltip(
                                message: controller.isRunning
                                    ? 'Pausar'
                                    : 'Iniciar',
                                child: IconButton(
                                  onPressed: () => controller.toggleRunning(),
                                  icon: Icon(
                                    controller.isRunning
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_fill,
                                    size: 28,
                                    color: controller.isRunning
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Previous Level
                              Tooltip(
                                message: 'Nível anterior',
                                child: IconButton(
                                  onPressed: () => controller.previousLevel(),
                                  icon: const Icon(
                                    Icons.skip_previous,
                                    size: 22,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Next Level
                              Tooltip(
                                message: 'Próximo nível',
                                child: IconButton(
                                  onPressed: () => controller.nextLevel(),
                                  icon: const Icon(Icons.skip_next, size: 22),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Reset current level
                              Tooltip(
                                message: 'Reiniciar tempo do nível',
                                child: IconButton(
                                  onPressed: () =>
                                      controller.resetCurrentLevel(),
                                  icon: const Icon(Icons.restart_alt, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),

                          // Time slider for director control
                          SizedBox(
                            width: sliderMaxWidth,
                            child: Column(
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
                                  value: remaining
                                      .clamp(0, duration)
                                      .toDouble(),
                                  divisions: duration > 0 ? 60 : 0,
                                  onChanged: (v) =>
                                      controller.setRemaining(v.toInt()),
                                  onChangeEnd: (v) =>
                                      controller.setRemaining(v.toInt()),
                                ),
                              ],
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
