class Payout {
  final String id;
  final String playerId;
  final int amount; // amount due to player after rake
  final String position; // '1st', '2nd', etc or 'bubble' or 'agreement'
  bool agreed; // true if player and house agreed on amount

  Payout({
    required this.id,
    required this.playerId,
    required this.amount,
    required this.position,
    this.agreed = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'playerId': playerId,
    'amount': amount,
    'position': position,
    'agreed': agreed,
  };

  factory Payout.fromMap(Map<dynamic, dynamic> m) => Payout(
    id: m['id'] as String,
    playerId: m['playerId'] as String,
    amount: (m['amount'] ?? 0) as int,
    position: (m['position'] ?? '') as String,
    agreed: (m['agreed'] ?? false) as bool,
  );
}
