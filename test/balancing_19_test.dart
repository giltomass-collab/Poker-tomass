import 'package:flutter_test/flutter_test.dart';
import 'package:tomasspoker/controllers/tournament_controller.dart';
import 'package:tomasspoker/models/player.dart';

void main() {
  test('19 players are balanced across 3 tables', () {
    final controller = TournamentController(initStorage: false);

    // Add 19 players
    for (var i = 1; i <= 19; i++) {
      final p = Player(id: 'p$i', name: 'Player $i');
      controller.addPlayer(p);
      controller.seatPlayer(p.id, 0); // auto-seat
    }

    final seatedPlayers = controller.players.where((p) => p.seated).toList();
    print('Total seated: ${seatedPlayers.length}');
    expect(seatedPlayers.length, 19);

    final numTables = (seatedPlayers.length / 9).ceil();
    print('Required tables: $numTables');
    expect(numTables, 3);

    // Count players per table
    final counts = List<int>.generate(numTables, (i) {
      final tableNumber = i + 1;
      final count = seatedPlayers
          .where((p) => p.tableNumber == tableNumber)
          .length;
      print('Table $tableNumber: $count players');
      return count;
    });

    final total = counts.reduce((a, b) => a + b);
    print('Total from tables: $total');
    expect(total, 19);

    // Each table should have 7, 6, or 6 players (19 / 3 = 6.33 -> [7,6,6])
    for (final c in counts) {
      print('Checking count $c: ${c >= 6 && c <= 7}');
      expect(c >= 6 && c <= 7, true);
    }
  });
}
