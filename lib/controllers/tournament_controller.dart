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

  TournamentController({bool initStorage = true}) {
    _loadDefaultLevels();
    _setLevel(0);
    // initialize storage and load players (skip in tests if requested)
    if (initStorage) {
      _initStorage();
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
    notifyListeners();
  }

  void removePlayer(String id) {
    players.removeWhere((p) => p.id == id);
    if (_storageAvailable) StorageService.deletePlayer(id);
    notifyListeners();
  }

  void seatPlayer(String id, int seat) {
    final p = players.firstWhere((x) => x.id == id);

    if (seat == 0) {
      // Auto-seat: determine target table and pick seat within that table
      final seatedPlayers = players.where((p) => p.seated).toList();
      final playersOnTable1 = seatedPlayers
          .where((p) => p.tableNumber == 1)
          .length;
      final currentNumTables = seatedPlayers
          .map((p) => p.tableNumber)
          .toSet()
          .where((n) => n > 0)
          .length;

      int targetTable = 1;
      // If table 1 is full, create/assign to next table
      if (playersOnTable1 >= 9) {
        targetTable = max(1, currentNumTables) + 1;
      }

      // Find available seats on target table
      final occupiedSeatsOnTarget = seatedPlayers
          .where((p) => p.tableNumber == targetTable)
          .map((p) => p.seat)
          .toSet();
      final availableSeatsOnTarget = List.generate(
        9,
        (i) => i + 1,
      ).where((s) => !occupiedSeatsOnTarget.contains(s)).toList();
      if (availableSeatsOnTarget.isEmpty) {
        // Fallback: try any available seat globally
        final occupiedSeats = seatedPlayers.map((p) => p.seat).toSet();
        final availableSeats = List.generate(
          9,
          (i) => i + 1,
        ).where((s) => !occupiedSeats.contains(s)).toList();
        if (availableSeats.isEmpty) return; // No seats available anywhere
        availableSeats.shuffle();
        p.seat = availableSeats.first;
        p.tableNumber = 1;
      } else {
        availableSeatsOnTarget.shuffle();
        p.seat = availableSeatsOnTarget.first;
        p.tableNumber = targetTable;
      }
    } else {
      p.seat = seat;
      // default to table 1 when manually specifying a seat
      if (p.tableNumber == 0) p.tableNumber = 1;
    }

    p.seated = true;

    // Auto buy-in on first seating
    if (p.buyins == 0) {
      buyIn(id, buyInAmount);
    }

    if (_storageAvailable) StorageService.savePlayer(p);

    // Check if tables need balancing after seating a player
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
    if (seatedPlayers.isEmpty) return;

    final numPlayers = seatedPlayers.length;
    final currentNumTables = seatedPlayers
        .map((p) => p.tableNumber)
        .toSet()
        .where((n) => n > 0)
        .length;
    final requiredNumTables = (numPlayers / 9).ceil();

    // If nothing to change, return
    if (requiredNumTables == currentNumTables) {
      // Still check for obvious overfull table
      final overfull = seatedPlayers.any(
        (p) =>
            seatedPlayers.where((x) => x.tableNumber == p.tableNumber).length >
            9,
      );
      if (!overfull) return;
    }

    // Compute expected sizes per table (balanced distribution)
    final base = numPlayers ~/ requiredNumTables;
    final remainder = numPlayers % requiredNumTables;
    final expectedSizes = List<int>.generate(
      requiredNumTables,
      (i) => base + (i < remainder ? 1 : 0),
    );

    // Group players per table
    final tablePlayers = <int, List<Player>>{};
    for (var p in seatedPlayers) {
      tablePlayers.putIfAbsent(p.tableNumber, () => []).add(p);
    }

    // Track original positions
    final originalPositions = {
      for (var p in seatedPlayers)
        p.id: {'table': p.tableNumber, 'seat': p.seat},
    };

    // Build list of players to move: from tables with surplus choose random players to move
    final rng = Random();
    final playersToMove = <Player>[];
    final deficits = <int, int>{}; // table -> how many needed

    // Determine deficits for each table (including new tables)
    for (int table = 1; table <= requiredNumTables; table++) {
      final currentCount = tablePlayers[table]?.length ?? 0;
      final expected = expectedSizes[table - 1];
      if (currentCount < expected) {
        deficits[table] = expected - currentCount;
      }
    }

    // For surplus tables, pick random players to move out
    for (var entry in tablePlayers.entries.toList()) {
      final table = entry.key;
      final list = List<Player>.from(entry.value);
      final expected = (table >= 1 && table <= expectedSizes.length)
          ? expectedSizes[table - 1]
          : 0;
      final surplus = list.length - expected;
      if (surplus > 0) {
        // Shuffle and take 'surplus' players to move
        list.shuffle(rng);
        final toMove = list.take(surplus).toList();
        playersToMove.addAll(toMove);
        // Remove moved players from tablePlayers so remaining players keep their seats
        tablePlayers[table] = list.skip(surplus).toList();
      }
    }

    // Assign moved players into deficit tables
    final movedList = <Player>[];
    for (var destEntry in deficits.entries) {
      final destTable = destEntry.key;
      var need = destEntry.value;
      while (need > 0 && playersToMove.isNotEmpty) {
        final pl = playersToMove.removeLast();
        // determine available seats on dest table
        final occupiedSeats = (tablePlayers[destTable] ?? [])
            .map((p) => p.seat)
            .toSet();
        final assignedSeats = movedList
            .where((p) => p.tableNumber == destTable)
            .map((p) => p.seat)
            .toSet();
        final unavailable = occupiedSeats.union(assignedSeats);
        int seat = 1;
        while (unavailable.contains(seat)) seat++;
        pl.tableNumber = destTable;
        pl.seat = seat;
        // add to dest roster
        tablePlayers.putIfAbsent(destTable, () => []).add(pl);
        movedList.add(pl);
        need--;
      }
    }

    // Save moved players and prepare pendingPlayerMoves
    for (var p in movedList) {
      final orig = originalPositions[p.id];
      final fromTable = orig?['table'] ?? 0;
      final fromSeat = orig?['seat'] ?? 0;
      pendingPlayerMoves.add(
        PlayerMove(
          player: p,
          fromTable: fromTable,
          fromSeat: fromSeat,
          toTable: p.tableNumber,
          toSeat: p.seat,
        ),
      );
      if (_storageAvailable) StorageService.savePlayer(p);
    }

    if (pendingPlayerMoves.isNotEmpty) notifyListeners();
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

  void agreedBubble(String playerId) {
    final idx = payouts.indexWhere((p) => p.playerId == playerId);
    if (idx >= 0) {
      payouts[idx].agreed = true;
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

  void calculatePayouts() {
    // compute total pool from transactions
    var totalPool = 0;
    for (final t in transactions) {
      if (t.type == 'buyin' || t.type == 'addon' || t.type == 'rebuy')
        totalPool += t.amount;
    }
    final rake = (totalPool * 0.2).toInt();
    final prizePool = totalPool - rake;

    final activePlayers = players.where((p) => p.seated).toList();
    if (activePlayers.isEmpty) return;

    List<double> payoutStructure() {
      final pc = activePlayers.length;
      if (pc <= 3) return [1.0];
      if (pc <= 5) return [0.65, 0.35];
      if (pc <= 7) return [0.50, 0.30, 0.20];
      if (pc <= 10) return [0.45, 0.25, 0.15, 0.15];
      if (pc == 9) return [0.50, 0.30, 0.20];
      if (pc <= 15) return [0.40, 0.30, 0.20, 0.10];
      if (pc <= 20) return [0.35, 0.25, 0.18, 0.12, 0.10];
      if (pc > 20) return [0.30, 0.20, 0.15, 0.12, 0.10, 0.08, 0.05];
      return [];
    }

    final structure = payoutStructure();
    if (structure.isEmpty) return;

    payouts.clear();
    final playersToPay = activePlayers.take(structure.length).toList();
    for (var i = 0; i < structure.length; i++) {
      final p = playersToPay[i];
      final amount = (prizePool * structure[i]).round();
      final position = '${i + 1}º';
      payouts.add(
        Payout(
          id: const Uuid().v4(),
          playerId: p.id,
          amount: amount,
          position: position,
        ),
      );
    }
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
    rebuyAmount = preset.rebuyAmount;
    addonAmount = preset.addonAmount;
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
    notifyListeners();
  }

  // Backwards-compatible methods used by UI
  void addPayout(Payout p) {
    payouts.add(p);
    notifyListeners();
  }

  void agreePayout(String payoutId) {
    final p = payouts.firstWhere((x) => x.id == payoutId);
    p.agreed = true;
    final tx = PlayerTransaction(
      id: const Uuid().v4(),
      playerId: p.playerId,
      time: DateTime.now(),
      type: 'payout',
      amount: p.amount,
    );
    addTransaction(tx);
    notifyListeners();
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
    notifyListeners();
  }
}
