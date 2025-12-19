import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/blind_level.dart';
import '../models/player.dart';
import '../services/storage_service.dart';
import '../models/player_transaction.dart';
import '../models/player_move.dart';
import '../models/payout.dart';
import '../models/tournament_preset.dart';

class TournamentController extends ChangeNotifier {
  List<Player> players = [];
  List<BlindLevel> levels = [];

  int _currentLevelIndex = 0;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool isRunning = false;

  // Configurações de valores do torneio
  int buyInAmount = 1000;
  int rebuyAmount = 1000;
  int addonAmount = 2000;

  // Presets
  List<TournamentPreset> presets = [];

  // Payouts
  List<Payout> payouts = [];

  // Table Balancing
  List<PlayerMove> pendingPlayerMoves = [];
  bool _storageAvailable = false;
  int? testSeed; // optional seed for deterministic test randomization

  TournamentController({bool initStorage = true, int? testSeed})
    : testSeed = testSeed {
    _loadDefaultLevels();
    _setLevel(0);
    // initialize storage and load players (skip in tests if requested)
    if (initStorage) {
      _initStorage().then((_) {
        // Calculate payouts after initial data is loaded
        calculatePayouts();
      });
    } else {
      calculatePayouts(); // For tests without storage init
    }
  }

  Future<void> _initStorage() async {
    try {
      await StorageService.init();
      final stored = StorageService.loadPlayers();
      players = stored;
      // load transactions
      final raw = StorageService.loadRawTransactions();
      transactions = raw
          .whereType<Map>()
          .map((m) => PlayerTransaction.fromMap(m))
          .toList();
      // Load tournament values
      buyInAmount = StorageService.loadValue('buyInAmount', defaultValue: 1000);
      rebuyAmount = StorageService.loadValue('rebuyAmount', defaultValue: 1000);
      addonAmount = StorageService.loadValue('addonAmount', defaultValue: 2000);
      // Load presets
      presets = StorageService.loadPresets();
      _storageAvailable = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Storage init failed: $e');
    }
  }

  List<PlayerTransaction> transactions = [];

  void addTransaction(PlayerTransaction tx) {
    transactions.add(tx);
    if (_storageAvailable) StorageService.saveTransaction(tx.id, tx.toMap());
    calculatePayouts(); // Recalculate payouts on transaction change
    notifyListeners();
  }

  List<PlayerTransaction> transactionsFor(String playerId) =>
      transactions.where((t) => t.playerId == playerId).toList();

  List<PlayerTransaction> getTransactionsForPlayer(
    String playerId, {
    String? type,
  }) {
    var playerTransactions = transactions.where((t) => t.playerId == playerId);
    if (type != null)
      playerTransactions = playerTransactions.where((t) => t.type == type);
    return playerTransactions.toList();
  }

  int balanceFor(String playerId) {
    final ts = transactionsFor(playerId);
    var sum = 0;
    for (final t in ts) {
      sum += t.amount;
    }
    return sum;
  }

  int get remainingSeconds => _remainingSeconds;

  String get formattedRemaining {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _loadDefaultLevels() {
    levels.clear();
    // Níveis 1-8 (com Rebuy)
    for (int i = 0; i < 8; i++) {
      final lvl = i + 1;
      levels.add(
        BlindLevel(
          level: lvl,
          label: 'N$lvl',
          smallBlind: 50 * lvl,
          bigBlind: 100 * lvl,
          durationSeconds: 15 * 60,
        ),
      );
    }
    // Nível de Intervalo (para Add-on)
    levels.add(
      BlindLevel(
        level: 9,
        label: 'INTERVALO',
        smallBlind: 0,
        bigBlind: 0,
        durationSeconds: 15 * 60, // 15 minutos de intervalo
        isBreak: true,
      ),
    );
    // Níveis 9-12 (sem Rebuy/Add-on)
    for (int i = 8; i < 12; i++) {
      final lvl = i + 1; // Starts at 9
      levels.add(
        BlindLevel(
          level: lvl,
          label: 'N$lvl',
          smallBlind: 100 * (i + 1),
          bigBlind: 200 * (i + 1),
          durationSeconds: 10 * 60,
        ),
      );
    }
  }

  void _setLevel(int index) {
    _currentLevelIndex = index;
    _remainingSeconds = levels[index].durationSeconds;
    notifyListeners();
  }

  int get currentLevelIndex => _currentLevelIndex;

  void toggleRunning() {
    if (isRunning) {
      _pause();
    } else {
      _start();
    }
  }

  void _start() {
    if (isRunning) return;
    isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
    notifyListeners();
  }

  void _pause() {
    _timer?.cancel();
    isRunning = false;
    notifyListeners();
  }

  void _tick() {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      notifyListeners();
    } else {
      _timer?.cancel();
      isRunning = false;
      nextLevel();
    }
  }

  void nextLevel() {
    if (_currentLevelIndex < levels.length - 1) {
      _setLevel(_currentLevelIndex + 1);
    }
  }

  void previousLevel() {
    if (_currentLevelIndex > 0) {
      _setLevel(_currentLevelIndex - 1);
    }
  }

  BlindLevel get currentLevel => levels[_currentLevelIndex];

  // Regras do Torneio
  bool get isRebuyAllowed => _currentLevelIndex < 8; // Níveis 1-8 (índices 0-7)

  bool get isAddonAllowed => currentLevel.isBreak; // Apenas durante o intervalo

  // Player management
  void addPlayer(Player p) {
    players.add(p);
    if (_storageAvailable) StorageService.savePlayer(p);
    calculatePayouts(); // Recalculate payouts on player added
    notifyListeners();
  }

  void removePlayer(String id) {
    players.removeWhere((p) => p.id == id);
    if (_storageAvailable) StorageService.deletePlayer(id);
    calculatePayouts(); // Recalculate payouts on player removed
    notifyListeners();
  }

  void seatPlayer(String id, int seat) {
    final p = players.firstWhere((x) => x.id == id);

    if (seat == 0) {
      // Auto-seat: assign to least-full table
      final seatedPlayers = players.where((p) => p.seated).toList();

      // Calculate required tables: each table holds max 9, so distribute evenly
      final totalSeatedAfterAdding = seatedPlayers.length + 1;
      final requiredNumTables = (totalSeatedAfterAdding / 9).ceil();

      // Compute target size per table
      final playersPerTable = totalSeatedAfterAdding ~/ requiredNumTables;
      final remainder = totalSeatedAfterAdding % requiredNumTables;

      // Count current players per table
      final tableCounts = <int, int>{};
      for (var sp in seatedPlayers) {
        if (sp.tableNumber > 0) {
          tableCounts[sp.tableNumber] = (tableCounts[sp.tableNumber] ?? 0) + 1;
        }
      }

      // Find the table with the most room (least full relative to target)
      // Tables 1 to remainder get +1 extra seat
      int targetTable = 1;
      int maxRoom = -999;
      for (int t = 1; t <= requiredNumTables; t++) {
        final currentCount = tableCounts[t] ?? 0;
        final targetSize = playersPerTable + (t <= remainder ? 1 : 0);
        final room = targetSize - currentCount;

        if (room > maxRoom) {
          maxRoom = room;
          targetTable = t;
        }
      }

      // Find available seat on target table
      final occupiedSeatsOnTable = seatedPlayers
          .where((sp) => sp.tableNumber == targetTable)
          .map((sp) => sp.seat)
          .toSet();

      final availableSeats = List.generate(
        9,
        (i) => i + 1,
      ).where((s) => !occupiedSeatsOnTable.contains(s)).toList();

      if (availableSeats.isEmpty) {
        if (kDebugMode) print('No available seats on table $targetTable');
        return;
      }

      availableSeats.shuffle(Random(testSeed));
      p.tableNumber = targetTable;
      p.seat = availableSeats.first;
    } else {
      // Manual seat assignment
      p.seat = seat;
      if (p.tableNumber == 0) p.tableNumber = 1;
    }

    p.seated = true;

    // Auto buy-in on first seating
    if (p.buyins == 0) {
      buyIn(id, buyInAmount);
    }

    if (_storageAvailable) StorageService.savePlayer(p);

    // After seating, check if we need to rebalance
    balanceTables();
    notifyListeners();
  }

  void togglePlayerParticipation(String playerId) {
    final player = players.firstWhereOrNull((p) => p.id == playerId);
    if (player == null) return;

    if (player.seated) {
      unseatPlayer(playerId);
    } else {
      seatPlayer(playerId, 0); // Auto-seat
    }
  }

  void unseatPlayer(String id) {
    final p = players.firstWhere((x) => x.id == id);
    p.seated = false;
    p.seat = 0;
    p.tableNumber = 0;
    if (_storageAvailable) StorageService.savePlayer(p);
    // Rebalance tables after player leaves to consolidate remaining players
    balanceTables();
    calculatePayouts(); // Recalculate payouts on player unseated
    notifyListeners();
  }

  // Reset blind levels to default
  void resetBlindLevels() {
    _loadDefaultLevels();
    notifyListeners();
  }

  // Timer controls for manager
  void setRemaining(int seconds) {
    _remainingSeconds = seconds;
    notifyListeners();
  }

  void resetCurrentLevel() {
    _remainingSeconds = levels[_currentLevelIndex].durationSeconds;
    notifyListeners();
  }

  // Auto-seating: assign random available seats
  void autoSeatPlayer(String id) {
    final index = players.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final unseatedPlayer = players[index];
    if (unseatedPlayer.seated) return;

    // Find available seats (1-9)
    final occupiedSeats = players
        .where((p) => p.seated)
        .map((p) => p.seat)
        .toSet();
    final availableSeats = List.generate(
      9,
      (i) => i + 1,
    ).where((s) => !occupiedSeats.contains(s)).toList();

    if (availableSeats.isNotEmpty) {
      availableSeats.shuffle();
      seatPlayer(id, availableSeats.first);
    }
  }

  void balanceTables() {
    pendingPlayerMoves.clear();
    final seatedPlayers = players.where((p) => p.seated).toList();
    if (seatedPlayers.isEmpty) {
      notifyListeners();
      return;
    }

    // Determine the ideal distribution of players
    final numTables =
        seatedPlayers.map((p) => p.tableNumber).toSet().where((n) => n > 0).length;
    if (numTables == 0) return;

    final requiredNumTables = (seatedPlayers.length / 9).ceil();
    final playersPerTable = seatedPlayers.length ~/ requiredNumTables;
    final remainder = seatedPlayers.length % requiredNumTables;

    // A map to hold the target size for each table
    final targetCounts = <int, int>{};
    for (int i = 0; i < requiredNumTables; i++) {
      final tableNum = i + 1;
      targetCounts[tableNum] = playersPerTable + (i < remainder ? 1 : 0);
    }

    // A map of current player counts for each table
    final currentCounts = <int, int>{};
    final tables = seatedPlayers.map((p) => p.tableNumber).toSet();
    for (final tableNum in tables) {
      if (tableNum > 0) {
        currentCounts[tableNum] =
            seatedPlayers.where((p) => p.tableNumber == tableNum).length;
      }
    }

    // If a table no longer exists after a player is eliminated, fill it up
    for(int i = 1; i <= numTables; i++) {
      if(!currentCounts.keys.contains(i)) {
        currentCounts[i] = 0;
      }
    }


    // Identify over-full and under-full tables
    final overFullTables = <int, int>{};
    final underFullTables = <int, int>{};

    for (final tableNum in currentCounts.keys) {
      final current = currentCounts[tableNum] ?? 0;
      final target = targetCounts[tableNum] ?? (requiredNumTables < tableNum ? 0 : playersPerTable);
      if (current > target) {
        overFullTables[tableNum] = current - target;
      } else if (current < target) {
        underFullTables[tableNum] = target - current;
      }
    }
    
    // If we need to close a table
    if(numTables > requiredNumTables) {
      final tableToClose = tables.last;
      overFullTables[tableToClose] = currentCounts[tableToClose] ?? 0;
    }


    if (overFullTables.isEmpty) {
      notifyListeners();
      return; // Already balanced
    }

    // Get players to move from over-full tables
    final playersToMove = <Player>[];
    overFullTables.forEach((tableNum, count) {
      playersToMove.addAll(
        seatedPlayers.where((p) => p.tableNumber == tableNum).take(count),
      );
    });

    // Get available seats in under-full tables
    final availableSeats = <Map<String, int>>[];
    underFullTables.forEach((tableNum, count) {
      final occupiedSeats = seatedPlayers
          .where((p) => p.tableNumber == tableNum)
          .map((p) => p.seat)
          .toSet();
      for (int i = 1; i <= 9; i++) {
        if (!occupiedSeats.contains(i)) {
          availableSeats.add({'table': tableNum, 'seat': i});
        }
      }
    });

    // Move players and create PlayerMove objects
    for (int i = 0; i < playersToMove.length; i++) {
      if (i >= availableSeats.length) break;

      final player = playersToMove[i];
      final newSeat = availableSeats[i];
      final fromTable = player.tableNumber;
      final fromSeat = player.seat;
      final toTable = newSeat['table']!;
      final toSeat = newSeat['seat']!;

      player.tableNumber = toTable;
      player.seat = toSeat;

      pendingPlayerMoves.add(
        PlayerMove(
          player: player,
          fromTable: fromTable,
          fromSeat: fromSeat,
          toTable: toTable,
          toSeat: toSeat,
        ),
      );
      if (_storageAvailable) StorageService.savePlayer(player);
    }
    notifyListeners();
  }

  void togglePlayerPaidStatus(String playerId) {
    final p = players.firstWhere((x) => x.id == playerId);
    p.paid = !p.paid;
    if (_storageAvailable) StorageService.savePlayer(p);
    notifyListeners();
  }

  void buyIn(String playerId, int amount) {
    final p = players.firstWhere((x) => x.id == playerId);
    p.chips += amount;
    p.buyins++;
    p.totalSpent += amount;
    if (_storageAvailable) StorageService.savePlayer(p);
    final tx = PlayerTransaction(
      id: const Uuid().v4(),
      playerId: playerId,
      time: DateTime.now(),
      type: 'buyin',
      amount: amount,
    );
    addTransaction(tx);
  }

  void rebuy(String playerId, int amount) {
    final p = players.firstWhere((x) => x.id == playerId);
    p.chips += amount;
    p.rebuys++;
    p.totalSpent += amount;
    if (_storageAvailable) StorageService.savePlayer(p);
    final tx = PlayerTransaction(
      id: const Uuid().v4(),
      playerId: playerId,
      time: DateTime.now(),
      type: 'rebuy',
      amount: amount,
    );
    addTransaction(tx);
  }

  void doubleRebuy(String playerId, int amount) {
    final p = players.firstWhere((x) => x.id == playerId);
    p.chips += amount * 2;
    p.rebuys += 2;
    p.totalSpent += amount * 2;
    if (_storageAvailable) StorageService.savePlayer(p);
    final tx = PlayerTransaction(
      id: const Uuid().v4(),
      playerId: playerId,
      time: DateTime.now(),
      type: 'rebuy',
      amount: amount * 2,
    );
    addTransaction(tx);
  }

  void addon(String playerId, int amount) {
    final p = players.firstWhere((x) => x.id == playerId);
    p.chips += amount;
    p.addons++;
    p.totalSpent += amount;
    if (_storageAvailable) StorageService.savePlayer(p);
    final tx = PlayerTransaction(
      id: const Uuid().v4(),
      playerId: playerId,
      time: DateTime.now(),
      type: 'addon',
      amount: amount,
    );
    addTransaction(tx);
  }

  void addonForAllEligiblePlayers() {
    if (!isAddonAllowed) return;

    final eligiblePlayers = players
        .where((p) => p.seated && p.addons == 0)
        .toList();

    for (final player in eligiblePlayers) {
      addon(player.id, addonAmount);
    }
    notifyListeners();
  }

  // Métodos para atualizar valores do torneio
  void updateBuyInAmount(int amount) {
    buyInAmount = amount;
    if (_storageAvailable) StorageService.saveValue('buyInAmount', amount);
    notifyListeners();
  }

  void updateRebuyAmount(int amount) {
    rebuyAmount = amount;
    if (_storageAvailable) StorageService.saveValue('rebuyAmount', amount);
    notifyListeners();
  }

  void updateAddonAmount(int amount) {
    addonAmount = amount;
    if (_storageAvailable) StorageService.saveValue('addonAmount', amount);
    notifyListeners();
  }

  // Preset Management
  Future<void> saveCurrentSettingsAsPreset(String name) async {
    final preset = TournamentPreset(
      name: name,
      levels: levels,
      buyInAmount: buyInAmount,
      rebuyAmount: rebuyAmount,
      addonAmount: addonAmount,
    );
    // Save preset in memory and optionally persist
    presets.removeWhere((p) => p.name == name);
    presets.add(preset);
    if (_storageAvailable) await StorageService.savePreset(preset);
    notifyListeners();
  }

  void deletePreset(String name) {
    presets.removeWhere((p) => p.name == name);
    if (_storageAvailable) StorageService.deletePreset(name);
    notifyListeners();
  }

  void loadPreset(String name) {
    final preset = presets.firstWhereOrNull((p) => p.name == name);
    if (preset == null) return;
    levels = preset.levels;
    buyInAmount = preset.buyInAmount;
    rebuyAmount = rebuyAmount;
    addonAmount = addonAmount;
    if (_storageAvailable) {
      StorageService.saveValue('buyInAmount', buyInAmount);
      StorageService.saveValue('rebuyAmount', rebuyAmount);
      StorageService.saveValue('addonAmount', addonAmount);
    }
    notifyListeners();
  }

  Player? playerById(String id) {
    return players.firstWhereOrNull((p) => p.id == id);
  }

  void eliminatePlayer(String playerId) {
    final p = players.firstWhereOrNull((x) => x.id == playerId);
    if (p == null) return;
    p.seated = false;
    p.seat = 0;
    p.tableNumber = 0;
    if (_storageAvailable) StorageService.savePlayer(p);
    // rebalance remaining players
    balanceTables();
    calculatePayouts(); // Recalculate payouts on player eliminated
    notifyListeners();
  }

  void agreedBubble(String playerId) {
    final idx = payouts.indexWhere((p) => p.playerId == playerId);
    if (idx >= 0) {
      payouts[idx] = Payout(
        id: payouts[idx].id,
        playerId: payouts[idx].playerId,
        amount: payouts[idx].amount,
        position: payouts[idx].position,
        agreed: true,
      );
      final tx = PlayerTransaction(
        id: const Uuid().v4(),
        playerId: playerId,
        time: DateTime.now(),
        type: 'payout',
        amount: payouts[idx].amount,
      );
      addTransaction(tx);
      notifyListeners();
    }
  }

  List<double> _getPayoutStructure(int playerCount) {
    if (playerCount <= 3) return [1.0]; // Winner takes all
    if (playerCount <= 5) return [0.65, 0.35]; // 2 places
    if (playerCount <= 7) return [0.50, 0.30, 0.20]; // 3 places
    if (playerCount <= 10) return [0.45, 0.25, 0.15, 0.15]; // 4 places
    // Example structures, can be expanded
    // Based on PokerStars 9-man SNG
    if (playerCount == 9) return [0.50, 0.30, 0.20];

    // A more generic approach for larger fields
    if (playerCount <= 15) {
      // 4 places
      return [0.40, 0.30, 0.20, 0.10];
    }
    if (playerCount <= 20) {
      // 5 places
      return [0.35, 0.25, 0.18, 0.12, 0.10];
    }

    // Default for very large fields (e.g., top 10%)
    // This is a simplification. Real structures are more complex.
    if (playerCount > 20) {
      return [0.30, 0.20, 0.15, 0.12, 0.10, 0.08, 0.05]; // 7 places
    }

    return []; // No structure defined
  }

  void calculatePayouts() {
    // compute total pool from transactions
    var totalPool = 0;
    for (final t in transactions) {
      if (t.type == 'buyin' || t.type == 'addon' || t.type == 'rebuy') {
        totalPool += t.amount;
      }
    }
    final prizePool = totalPool;

    final activePlayers = players.where((p) => p.seated).toList();
    // Sort players by chips, then by total spent (more spent = higher rank in ties)
    activePlayers.sort((a, b) {
      if (a.chips != b.chips) return b.chips.compareTo(a.chips);
      return b.totalSpent.compareTo(a.totalSpent);
    });

    if (activePlayers.isEmpty) {
      payouts.clear();
      notifyListeners();
      return;
    }

    final structure = _getPayoutStructure(activePlayers.length);
    if (structure.isEmpty) {
      payouts.clear();
      notifyListeners();
      return;
    }

    final newPayouts = <Payout>[];
    final playersToPay = activePlayers.take(structure.length).toList();

    for (var i = 0; i < structure.length; i++) {
      final p = playersToPay[i];
      final amount = (prizePool * structure[i]).round();
      final position = '${i + 1}º';

      // Check if a payout for this player already exists and is agreed upon,
      // or if it was manually edited. Preserve these if possible.
      final existingPayout = payouts.firstWhereOrNull(
        (e) => e.playerId == p.id && e.position == position,
      );

      newPayouts.add(
        Payout(
          id: existingPayout?.id ?? const Uuid().v4(),
          playerId: p.id,
          amount: existingPayout?.amount ?? amount, // Preserve manually edited amount or calculated
          position: position,
          agreed: existingPayout?.agreed ?? false,
        ),
      );
    }
    payouts = newPayouts;
    notifyListeners();
  }

  void updatePayoutAmount(String payoutId, int newAmount) {
    final index = payouts.indexWhere((p) => p.id == payoutId);
    if (index != -1) {
      payouts[index] = Payout(
        id: payouts[index].id,
        playerId: payouts[index].playerId,
        amount: newAmount,
        position: payouts[index].position,
        agreed: payouts[index].agreed,
      );
      notifyListeners();
    }
  }

  bool get isBubblePhase {
    final activePlayersCount = players.where((p) => p.seated).length;
    final payoutSpots = _getPayoutStructure(activePlayersCount).length;
    // Bubble phase if (payoutSpots + 1) players remain
    return activePlayersCount > payoutSpots && activePlayersCount <= payoutSpots + 1;
  }

  // Backwards-compatible methods used by UI
  // void addPayout(Payout p) {
  //   payouts.add(p);
  //   notifyListeners();
  // }

  void agreePayout(String payoutId) {
    final index = payouts.indexWhere((p) => p.id == payoutId);
    if (index != -1) {
      payouts[index] = Payout(
        id: payouts[index].id,
        playerId: payouts[index].playerId,
        amount: payouts[index].amount,
        position: payouts[index].position,
        agreed: true,
      );
      // No longer adding transaction here to avoid duplicates.
      // Transactions are handled when payouts are initially agreed through 'agreedBubble'
      notifyListeners();
    }
  }

  // Undo last transaction
  String? undoLastTransaction() {
    if (transactions.isEmpty) {
      return 'Nenhuma transação para desfazer.';
    }

    final lastTx = transactions.last;
    final playerIndex = players.indexWhere((p) => p.id == lastTx.playerId);

    if (playerIndex == -1) {
      // Player not found, just remove transaction
      if (_storageAvailable) StorageService.deleteTransaction(lastTx.id);
      transactions.removeLast();
      notifyListeners();
      return 'Transação órfã removida.';
    }

    final p = players[playerIndex];

    // Revert player stats

    switch (lastTx.type) {
      case 'buyin':
        p.totalSpent -= lastTx.amount;
        p.chips -= lastTx.amount;
        p.buyins--;
        break;
      case 'rebuy':
        p.totalSpent -= lastTx.amount;
        p.chips -= lastTx.amount;
        // This simplifies double-rebuy undo to a single step.
        // A double rebuy is one transaction, so we decrement by one transaction.
        // The amount is correct. The count of rebuys might be off if a double rebuy was done.
        // For now, we assume single rebuys or that this simplification is acceptable.
        if (p.rebuys > 0) p.rebuys--;
        break;
      case 'addon':
        p.totalSpent -= lastTx.amount;
        p.chips -= lastTx.amount;
        p.addons--;
        break;
      case 'payout':
        final payout = payouts.firstWhereOrNull(
          (p) => p.playerId == lastTx.playerId && p.amount == lastTx.amount,
        );
        if (payout != null) {
          payout.agreed = false;
        }
        break;
    }

    if (_storageAvailable) StorageService.savePlayer(p);
    if (_storageAvailable) StorageService.deleteTransaction(lastTx.id);
    transactions.removeLast();
    notifyListeners();

    return 'Ação "${lastTx.type.toUpperCase()}" de ${p.name} desfeita.';
  }

  void restartTournament() {
    // Pause timer
    _pause();

    // Reset timer e níveis
    _setLevel(0);

    // Limpa transações
    for (final t in transactions) {
      if (_storageAvailable) StorageService.deleteTransaction(t.id);
    }
    transactions.clear();
    payouts.clear();

    // Reseta os dados dos jogadores, mas não os remove
    for (final p in players) {
      p.resetForNewTournament();
      if (_storageAvailable) StorageService.savePlayer(p);
    }

    balanceTables();
    calculatePayouts(); // Recalculate payouts after restart
    notifyListeners();
  }
}
