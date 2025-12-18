import 'package:hive_flutter/hive_flutter.dart';
import '../models/player.dart';
import '../models/tournament_preset.dart';

class StorageService {
  static const _playersBox = 'players';
  static const _txBox = 'transactions';
  static const _settingsBox = 'settings';
  static const _presetsBox = 'presets';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_playersBox);
    await Hive.openBox(_txBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_presetsBox);
  }

  static List<Player> loadPlayers() {
    final box = Hive.box(_playersBox);
    final res = <Player>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        res.add(Player.fromMap(value));
      }
    }
    return res;
  }

  // Transactions
  static List<dynamic> loadRawTransactions() {
    final box = Hive.box(_txBox);
    return box.values.toList();
  }

  static Future<void> saveTransaction(String id, Map<String, dynamic> m) async {
    final box = Hive.box(_txBox);
    await box.put(id, m);
  }

  static Future<void> deleteTransaction(String id) async {
    final box = Hive.box(_txBox);
    await box.delete(id);
  }

  static Future<void> savePlayer(Player p) async {
    final box = Hive.box(_playersBox);
    await box.put(p.id, p.toMap());
  }

  static Future<void> deletePlayer(String id) async {
    final box = Hive.box(_playersBox);
    await box.delete(id);
  }

  // Generic value storage
  static Future<void> saveValue(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  static T loadValue<T>(String key, {required T defaultValue}) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue) as T;
  }

  // Preset storage
  static Future<void> savePreset(TournamentPreset preset) async {
    final box = Hive.box(_presetsBox);
    await box.put(preset.name, preset.toMap());
  }

  static List<TournamentPreset> loadPresets() {
    final box = Hive.box(_presetsBox);
    final res = <TournamentPreset>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        res.add(TournamentPreset.fromMap(value));
      }
    }
    return res;
  }

  static Future<void> deletePreset(String name) async {
    final box = Hive.box(_presetsBox);
    await box.delete(name);
  }
}
