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
                  title: Text(p.name, style: TextStyle(fontWeight: p.seated ? FontWeight.bold : FontWeight.normal)),
                  subtitle: p.seated ? Text('Lugar: ${p.seat} - Chips: ${p.chips}') : const Text('Fora do torneio'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => controller.removePlayer(p.id),
                      ),
                      Checkbox(value: p.seated, onChanged: (value) {
                        controller.togglePlayerParticipation(p.id);
                      }),
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
    final name = _nameCtrl.text.trim();

    // Verificar se o jogador já existe
    if (controller.players.any((Player p) => p.name.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jogador "$name" já existe.')),
      );
      return;
    }

    final p = Player(id: Random().nextInt(1 << 31).toString(), name: name);
    controller.addPlayer(p);
    // Senta o jogador e balanceia as mesas
    controller.seatPlayer(p.id, 0); // seat 0 para auto-atribuição

    _nameCtrl.clear();
    _nameFocusNode.requestFocus();
  }
}
