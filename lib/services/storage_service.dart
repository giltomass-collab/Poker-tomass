import 'package:hive_flutter/hive_flutter.dart';
import '../models/player.dart';

class StorageService {
  static const _playersBox = 'players';
  static const _txBox = 'transactions';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_playersBox);
    await Hive.openBox(_txBox);
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
}
