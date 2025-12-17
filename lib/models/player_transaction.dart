class PlayerTransaction {
  final String id;
  final String playerId;
  final DateTime time;
  final String type; // 'buyin','rebuy','addon','payout','fee'
  final int
  amount; // positive values for money entering tournament (buyin), payouts as negative
  final String note;

  PlayerTransaction({
    required this.id,
    required this.playerId,
    required this.time,
    required this.type,
    required this.amount,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'playerId': playerId,
    'time': time.toIso8601String(),
    'type': type,
    'amount': amount,
    'note': note,
  };

  factory PlayerTransaction.fromMap(Map<dynamic, dynamic> m) =>
      PlayerTransaction(
        id: m['id'] as String,
        playerId: m['playerId'] as String,
        time: DateTime.parse(m['time'] as String),
        type: m['type'] as String,
        amount: (m['amount'] ?? 0) as int,
        note: (m['note'] ?? '') as String,
      );
}
