import 'player.dart';

class PlayerMove {
  final Player player;
  final int fromTable;
  final int fromSeat;
  final int toTable;
  final int toSeat;

  PlayerMove({
    required this.player,
    required this.fromTable,
    required this.fromSeat,
    required this.toTable,
    required this.toSeat,
  });
}
