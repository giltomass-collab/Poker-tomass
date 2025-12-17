import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tournament_controller.dart';
import '../models/player.dart';
import 'dart:math';

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  final _nameCtrl = TextEditingController();
  final _nameFocusNode = FocusNode();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TournamentController>(context);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  focusNode: _nameFocusNode,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  onSubmitted: (_) => _addPlayer(),
                ),
              ),
              ElevatedButton(
                onPressed: _addPlayer,
                child: const Text('Adicionar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: controller.players.length,
              itemBuilder: (context, i) {
                final p = controller.players[i];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(p.name.isNotEmpty ? p.name[0] : '?'),
                  ),
                  title: Text(p.name),
                  subtitle: Text('Chips: ${p.chips}  Seat: ${p.seat}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.event_seat),
                        onPressed: () => _showSeatDialog(context, p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => controller.removePlayer(p.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addPlayer() {
    if (_nameCtrl.text.trim().isEmpty) return;

    final controller = Provider.of<TournamentController>(
      context,
      listen: false,
    );
    final id = Random().nextInt(1 << 31).toString();
    final p = Player(id: id, name: _nameCtrl.text.trim(), chips: 0);
    controller.addPlayer(p);
    // Auto-seat o novo jogador
    Future.delayed(const Duration(milliseconds: 100), () {
      controller.autoSeatPlayer(id);
      controller.balanceTables();
    });
    _nameCtrl.clear();
    _nameFocusNode.requestFocus();
  }

  void _showSeatDialog(BuildContext context, Player p) {
    showDialog(
      context: context,
      builder: (ctx) {
        int selected = p.seat;
        return AlertDialog(
          title: const Text('Escolher lugar'),
          content: DropdownButton<int>(
            value: selected == 0 ? null : selected,
            hint: const Text('Selecione'),
            items: List.generate(9, (i) => i + 1)
                .map((s) => DropdownMenuItem(value: s, child: Text('Lugar $s')))
                .toList(),
            onChanged: (v) => setState(() => selected = v ?? 0),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (selected > 0) {
                  Provider.of<TournamentController>(
                    context,
                    listen: false,
                  ).seatPlayer(p.id, selected);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }
}
