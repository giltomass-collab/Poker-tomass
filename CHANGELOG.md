# Changelog

All notable changes to this project are documented in this file.

## 2025-12-18 - Fixes and improvements

- Fix: Guard calls to `StorageService` with `_storageAvailable` so tests run without Flutter plugins (Hive/path_provider).
- Fix: Reworked `balanceTables()` to move only surplus players, choose movers randomly and preserve seats of players who remain.
- Fix: `seatPlayer()` now assigns `tableNumber = 1` for manual seat assignments and auto-creates additional tables when needed.
- Add: `payouts` support and methods in `TournamentController` (`calculatePayouts`, `loadPreset`, `deletePreset`).
- Add: `PlayerMove` usage fixed to use named parameters; `pendingPlayerMoves` populated for UI dialog.
- Add: `eliminatePlayer()` and `playerById()` helpers in `TournamentController`.
- Add: Unit test `test/tournament_controller_test.dart` validating auto-creation of table 2 and redistribution when seating the 10th player.
- Chore: UI tweak in `lib/main.dart` to show app title text used by widget tests.

All tests currently pass locally (`flutter test`).
