import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tournament_controller.dart';
import '../models/blind_level.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.attach_money), text: 'Valores'),
            Tab(icon: Icon(Icons.hourglass_bottom), text: 'Níveis'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [const _ValuesSettingsTab(), _buildLevelsTab(context)],
          ),
        ),
      ],
    );
  }
}

class _ValuesSettingsTab extends StatefulWidget {
  const _ValuesSettingsTab();

  @override
  State<_ValuesSettingsTab> createState() => _ValuesSettingsTabState();
}

class _ValuesSettingsTabState extends State<_ValuesSettingsTab> {
  // Controllers for costs
  late TextEditingController _buyinCtrl;
  late TextEditingController _rebuyCtrl;
  late TextEditingController _addonCtrl;

  // Controllers for chips
  late TextEditingController _buyinChipsCtrl;
  late TextEditingController _rebuyChipsCtrl;
  late TextEditingController _doubleRebuyChipsCtrl;
  late TextEditingController _addonChipsCtrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = Provider.of<TournamentController>(
      context,
      listen: false,
    );
    // Init cost controllers
    _buyinCtrl = TextEditingController(text: controller.buyInAmount.toString());
    _rebuyCtrl = TextEditingController(text: controller.rebuyAmount.toString());
    _addonCtrl = TextEditingController(text: controller.addonAmount.toString());

    // Init chip controllers
    _buyinChipsCtrl =
        TextEditingController(text: controller.buyInChips.toString());
    _rebuyChipsCtrl =
        TextEditingController(text: controller.rebuyChips.toString());
    _doubleRebuyChipsCtrl =
        TextEditingController(text: controller.doubleRebuyChips.toString());
    _addonChipsCtrl =
        TextEditingController(text: controller.addonChips.toString());
  }

  @override
  void dispose() {
    // Dispose cost controllers
    _buyinCtrl.dispose();
    _rebuyCtrl.dispose();
    _addonCtrl.dispose();

    // Dispose chip controllers
    _buyinChipsCtrl.dispose();
    _rebuyChipsCtrl.dispose();
    _doubleRebuyChipsCtrl.dispose();
    _addonChipsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<TournamentController>(
      context,
      listen: false,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section for Costs
        const ListTile(
          leading: Icon(Icons.monetization_on_outlined),
          title: Text('Custos do Torneio'),
          subtitle: Text('Defina os valores em R\$ para cada ação.'),
        ),
        const Divider(),
        TextField(
          controller: _buyinCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Custo do Buy-in',
            prefixText: 'R\$ ',
          ),
          onChanged: (value) {
            final amount = int.tryParse(value);
            if (amount != null) {
              controller.updateBuyInAmount(amount);
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _rebuyCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Custo do Rebuy / Rebuy Duplo',
            prefixText: 'R\$ ',
          ),
          onChanged: (value) {
            final amount = int.tryParse(value);
            if (amount != null) {
              controller.updateRebuyAmount(amount);
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _addonCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Custo do Add-on',
            prefixText: 'R\$ ',
          ),
          onChanged: (value) {
            final amount = int.tryParse(value);
            if (amount != null) {
              controller.updateAddonAmount(amount);
            }
          },
        ),
        const SizedBox(height: 24),

        // Section for Chips
        const ListTile(
          leading: Icon(Icons.memory),
          title: Text('Fichas do Torneio'),
          subtitle: Text('Defina a quantidade de fichas para cada ação.'),
        ),
        const Divider(),
        TextField(
          controller: _buyinChipsCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Fichas do Buy-in',
          ),
          onChanged: (value) {
            final chips = int.tryParse(value);
            if (chips != null) {
              controller.updateBuyInChips(chips);
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _rebuyChipsCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Fichas do Rebuy',
          ),
          onChanged: (value) {
            final chips = int.tryParse(value);
            if (chips != null) {
              controller.updateRebuyChips(chips);
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _doubleRebuyChipsCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Fichas do Rebuy Duplo',
          ),
          onChanged: (value) {
            final chips = int.tryParse(value);
            if (chips != null) {
              controller.updateDoubleRebuyChips(chips);
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _addonChipsCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Fichas do Add-on',
          ),
          onChanged: (value) {
            final chips = int.tryParse(value);
            if (chips != null) {
              controller.updateAddonChips(chips);
            }
          },
        ),
      ],
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
                },
              ),
              TextField(
                controller: bbCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Big Blind'),
                onChanged: (v) {
                  widget.level.bigBlind =
                      int.tryParse(v) ?? widget.level.bigBlind;
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

extension on _SettingsPageState {
  Widget _buildLevelsTab(BuildContext context) {
    final controller = Provider.of<TournamentController>(context);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildPresetSection(context, controller),
        const Divider(height: 24),
        const ListTile(title: Text('Estrutura de Níveis (Atual)'), dense: true),
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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton.icon(
              onPressed: () => controller.resetBlindLevels(),
              icon: const Icon(Icons.restore),
              label: const Text('Padrão'),
            ),
            ElevatedButton.icon(
              onPressed: () => _showSavePresetDialog(context, controller),
              icon: const Icon(Icons.save),
              label: const Text('Salvar Preset'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetSection(
    BuildContext context,
    TournamentController controller,
  ) {
    return Column(
      children: [
        const ListTile(title: Text('Presets Salvos'), dense: true),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.presets.length,
          itemBuilder: (context, i) {
            final preset = controller.presets[i];
            return Card(
              child: ListTile(
                title: Text(preset.name),
                subtitle: Text(
                  '${preset.levels.length} níveis, Buy-in: ${preset.buyInAmount}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Excluir Preset',
                      onPressed: () {
                        controller.deletePreset(preset.name);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Preset "${preset.name}" excluído.'),
                          ),
                        );
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Carregar'),
                      onPressed: () {
                        controller.loadPreset(preset.name);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Preset "${preset.name}" carregado.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (controller.presets.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Nenhum preset salvo.',
              style: TextStyle(color: Colors.grey),
            ),
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
                controller.saveCurrentSettingsAsPreset(nameCtrl.text.trim());
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
