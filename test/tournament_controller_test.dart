import 'package:flutter_test/flutter_test.dart';
import 'package:tomasspoker/controllers/tournament_controller.dart';
import 'package:tomasspoker/models/player.dart';

void main() {
  test('10th player creates table 2 and redistributes players', () {
    final controller = TournamentController(initStorage: false, testSeed: 42);

    // Create 10 players
    for (int i = 0; i < 10; i++) {
      controller.addPlayer(Player(id: 'p$i', name: 'Player $i'));
    }

    // Seat first 9 players manually into table 1 seats 1..9
    for (int i = 0; i < 9; i++) {
      controller.seatPlayer('p$i', i + 1);
    }

    // Ensure table 1 is full
    final seated = controller.players.where((p) => p.seated).toList();
    expect(seated.length, 9);
    expect(seated.where((p) => p.tableNumber == 1).length, 9);

    // Now seat the 10th player using auto-seat
    controller.seatPlayer('p9', 0);

    // After seating, balanceTables should have run and created table 2
    final allSeated = controller.players.where((p) => p.seated).toList();
    expect(allSeated.length, 10);

    final tables = allSeated.map((p) => p.tableNumber).toSet();
    // Expect at least 2 tables
    expect(tables.length >= 2, true);

    // Ensure no table has more than 9 players
    final counts = <int, int>{};
    for (var p in allSeated) {
      counts[p.tableNumber] = (counts[p.tableNumber] ?? 0) + 1;
    }
    for (var c in counts.values) {
      expect(c <= 9, true);
    }
  });
}
