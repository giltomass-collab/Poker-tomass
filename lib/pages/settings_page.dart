import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tournament_controller.dart';
import '../models/blind_level.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TournamentController>(context);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const ListTile(title: Text('Configurações gerais'), dense: true),
        SwitchListTile(
          value: true,
          onChanged: (_) {},
          title: const Text('Português (pt-BR)'),
        ),
        const Divider(),
        const ListTile(title: Text('Níveis de Blind'), dense: true),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.levels.length,
          itemBuilder: (context, i) {
            final level = controller.levels[i];
            return _LevelEditTile(level: level, controller: controller);
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => controller.resetBlindLevels(),
              child: const Text('Restaurar Padrão'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _showSavePresetDialog(context, controller),
              child: const Text('Salvar Preset'),
            ),
          ],
        ),
      ],
    );
  }

  void _showSavePresetDialog(
    BuildContext context,
    TournamentController controller,
  ) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Salvar Preset'),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Nome do preset'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Save preset logic (could persist to storage)
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Preset "${nameCtrl.text}" salvo!')),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}

class _LevelEditTile extends StatefulWidget {
  final BlindLevel level;
  final TournamentController controller;

  const _LevelEditTile({required this.level, required this.controller});

  @override
  State<_LevelEditTile> createState() => _LevelEditTileState();
}

class _LevelEditTileState extends State<_LevelEditTile> {
  late TextEditingController sbCtrl;
  late TextEditingController bbCtrl;
  late TextEditingController durationCtrl;

  @override
  void initState() {
    super.initState();
    sbCtrl = TextEditingController(text: widget.level.smallBlind.toString());
    bbCtrl = TextEditingController(text: widget.level.bigBlind.toString());
    durationCtrl = TextEditingController(
      text: (widget.level.durationSeconds ~/ 60).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        '${widget.level.label}: ${widget.level.smallBlind}/${widget.level.bigBlind}',
      ),
      subtitle: Text('${widget.level.durationSeconds ~/ 60} min'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Column(
            children: [
              TextField(
                controller: sbCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Small Blind'),
                onChanged: (v) {
                  widget.level.smallBlind =
                      int.tryParse(v) ?? widget.level.smallBlind;
                  Provider.of<TournamentController>(
                    context,
                    listen: false,
                  ).notifyListeners();
                },
              ),
              TextField(
                controller: bbCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Big Blind'),
                onChanged: (v) {
                  widget.level.bigBlind =
                      int.tryParse(v) ?? widget.level.bigBlind;
                  Provider.of<TournamentController>(
                    context,
                    listen: false,
                  ).notifyListeners();
                },
              ),
              TextField(
                controller: durationCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duração (minutos)',
                ),
                onChanged: (v) {
                  final mins =
                      int.tryParse(v) ?? (widget.level.durationSeconds ~/ 60);
                  widget.level.durationSeconds = mins * 60;
                  Provider.of<TournamentController>(
                    context,
                    listen: false,
                  ).notifyListeners();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    sbCtrl.dispose();
    bbCtrl.dispose();
    durationCtrl.dispose();
    super.dispose();
  }
}
