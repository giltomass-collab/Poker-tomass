import 'package:tomasspoker/models/payment_status.dart';

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
  PaymentStatus paymentStatus; // se já pagou a conta
  String? phoneNumber;
  int? finishingRank; // null se ainda não foi eliminado

  Player({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.chips = 0,
    this.seated = false,
    this.seat = 0,
    this.tableNumber = 0,
    this.buyins = 0,
    this.rebuys = 0,
    this.addons = 0,
    this.totalSpent = 0,
    this.paymentStatus = PaymentStatus.none,
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
    paymentStatus = PaymentStatus.none;
    finishingRank = null;
    // phoneNumber is not reset, as it's part of the player's profile
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phoneNumber': phoneNumber,
        'chips': chips,
        'seated': seated,
        'seat': seat,
        'tableNumber': tableNumber,
        'buyins': buyins,
        'rebuys': rebuys,
        'addons': addons,
        'totalSpent': totalSpent,
        'paymentStatus': paymentStatus.name,
        'finishingRank': finishingRank,
      };

  factory Player.fromMap(Map<dynamic, dynamic> m) => Player(
        id: m['id'] as String,
        name: m['name'] as String,
        phoneNumber: m['phoneNumber'] as String?,
        chips: (m['chips'] ?? 0) as int,
        seated: (m['seated'] ?? false) as bool,
        seat: (m['seat'] ?? 0) as int,
        tableNumber: (m['tableNumber'] ?? 0) as int,
        buyins: (m['buyins'] ?? 0) as int,
        rebuys: (m['rebuys'] ?? 0) as int,
        addons: (m['addons'] ?? 0) as int,
        totalSpent: (m['totalSpent'] ?? 0) as int,
        paymentStatus: PaymentStatus.values
            .firstWhere((e) => e.name == m['paymentStatus'], orElse: () => PaymentStatus.none),
        finishingRank: m['finishingRank'] as int?,
      );
}
