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
  });

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
  );
}
