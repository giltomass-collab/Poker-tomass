import 'package:tomasspoker/models/payment_status.dart';

class FinancialSummary {
  final int totalBuyin;
  final int totalExpenses;
  final int prizePool;
  final List<PlayerBalance> playerBalances;

  FinancialSummary({
    required this.totalBuyin,
    required this.totalExpenses,
    required this.prizePool,
    required this.playerBalances,
  });
}

class PlayerBalance {
  final String playerId;
  final String playerName;
  final int buyins;
  final int rebuys;
  final int addons;
  final int totalSpent;
  final int payout;
  final int netBalance;
  final PaymentStatus paymentStatus;

  PlayerBalance({
    required this.playerId,
    required this.playerName,
    required this.buyins,
    required this.rebuys,
    required this.addons,
    required this.totalSpent,
    required this.payout,
    required this.netBalance,
    required this.paymentStatus,
  });
}
