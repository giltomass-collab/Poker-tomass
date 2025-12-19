class Player {
  final String id;
  String name;
  int chips;
  bool seated;
  int seat; // 1..9
  int tableNumber; // 1, 2, ...
  int buyins; // número de buy-ins
  int rebuys; // número de rebuys
  int addons; // número de add-ons
  int totalSpent; // total gasto (buy-in + rebuys + add-ons)
  bool paid; // se já pagou a conta
  int? finishingRank; // null se ainda não foi eliminado

  Player({
    required this.id,
    required this.name,
    this.chips = 0,
    this.seated = false,
    this.seat = 0,
    this.tableNumber = 0,
    this.buyins = 0,
    this.rebuys = 0,
    this.addons = 0,
    this.totalSpent = 0,
    this.paid = false,
    this.finishingRank,
  });

  void resetForNewTournament() {
    chips = 0;
    seated = false;
    seat = 0;
    tableNumber = 0;
    buyins = 0;
    rebuys = 0;
    addons = 0;
    totalSpent = 0;
    paid = false;
    finishingRank = null;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'chips': chips,
        'seated': seated,
        'seat': seat,
        'tableNumber': tableNumber,
        'buyins': buyins,
        'rebuys': rebuys,
        'addons': addons,
        'totalSpent': totalSpent,
        'paid': paid,
        'finishingRank': finishingRank,
      };

  factory Player.fromMap(Map<dynamic, dynamic> m) => Player(
        id: m['id'] as String,
        name: m['name'] as String,
        chips: (m['chips'] ?? 0) as int,
        seated: (m['seated'] ?? false) as bool,
        seat: (m['seat'] ?? 0) as int,
        tableNumber: (m['tableNumber'] ?? 0) as int,
        buyins: (m['buyins'] ?? 0) as int,
        rebuys: (m['rebuys'] ?? 0) as int,
        addons: (m['addons'] ?? 0) as int,
        totalSpent: (m['totalSpent'] ?? 0) as int,
        paid: (m['paid'] ?? false) as bool,
        finishingRank: m['finishingRank'] as int?,
      );
}
