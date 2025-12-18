import 'package:tomasspoker/controllers/tournament_controller.dart';
import 'package:tomasspoker/models/player.dart';

void main() {
  final c = TournamentController();

  // add 10 players
  for (int i = 0; i < 10; i++) {
    c.addPlayer(Player(id: 'p$i', name: 'Player $i'));
  }

  // seat first 9 players into table 1 seats 1..9
  for (int i = 0; i < 9; i++) {
    c.seatPlayer('p$i', i + 1);
  }

  print('Before seating 10th:');
  for (var p in c.players.where((p) => p.seated)) {
    print('${p.name} -> Table ${p.tableNumber} Seat ${p.seat}');
  }

  // seat 10th
  c.seatPlayer('p9', 0);

  print('\nAfter seating 10th and balancing:');
  for (var p in c.players.where((p) => p.seated)) {
    print('${p.name} -> Table ${p.tableNumber} Seat ${p.seat}');
  }

  if (c.pendingPlayerMoves.isNotEmpty) {
    print('\nPending Moves:');
    for (var m in c.pendingPlayerMoves) {
      print(
        '${m.player.name}: ${m.fromTable}:${m.fromSeat} -> ${m.toTable}:${m.toSeat}',
      );
    }
  } else {
    print('\nNo pending moves');
  }
}
