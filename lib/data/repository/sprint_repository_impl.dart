import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_logger.dart';
import '../../domain/defaults.dart';
import '../../domain/elo_engine.dart';
import '../../domain/history_policy.dart';
import '../../domain/match_rollback_engine.dart';
import '../../models/app_models.dart' as models;
import '../local/app_database.dart' as db;
import 'sprint_repository.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

class SprintRepositoryImpl implements SprintRepository {
  SprintRepositoryImpl({
    required db.AppDatabase database,
    FirebaseDatabase? firebaseDatabase,
    SharedPreferencesLoader sharedPreferencesLoader =
        SharedPreferences.getInstance,
    bool enableRemoteSync = true,
  }) : _database = database,
       _firebaseDatabase = enableRemoteSync
           ? (firebaseDatabase ?? FirebaseDatabase.instance)
           : null,
       _loadSharedPreferences = sharedPreferencesLoader,
       _enableRemoteSync = enableRemoteSync {
    if (_enableRemoteSync) {
      final firebase = _firebaseDatabase!;
      _playersRef = firebase.ref(Defaults.dbPlayersPath);
      _historyRef = firebase.ref(Defaults.dbHistoryPath);
      _tournamentRef = firebase.ref(Defaults.dbTournamentPath);
      _settingsRef = firebase.ref(Defaults.dbSettingsPath);
    }

    _syncStateController.add(_syncStateValue);
    _kFactorController.add(_kFactorValue);
    _themePreferenceController.add(_themePreferenceValue);
    unawaited(
      _initialize().catchError((Object error, StackTrace stackTrace) {
        AppLogger.error(
          'Repository initialization failed.',
          name: 'sprint.repository',
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
  }

  final db.AppDatabase _database;
  final FirebaseDatabase? _firebaseDatabase;
  final SharedPreferencesLoader _loadSharedPreferences;
  final bool _enableRemoteSync;

  DatabaseReference? _playersRef;
  DatabaseReference? _historyRef;
  DatabaseReference? _tournamentRef;
  DatabaseReference? _settingsRef;

  final StreamController<models.SyncState> _syncStateController =
      StreamController<models.SyncState>.broadcast();
  final StreamController<int> _kFactorController =
      StreamController<int>.broadcast();
  final StreamController<models.AppThemePreference> _themePreferenceController =
      StreamController<models.AppThemePreference>.broadcast();

  models.SyncState _syncStateValue = const models.SyncState();
  int _kFactorValue = Defaults.eloK;
  models.AppThemePreference _themePreferenceValue =
      models.AppThemePreference.light;

  StreamSubscription<DatabaseEvent>? _playersSubscription;
  StreamSubscription<DatabaseEvent>? _historySubscription;
  StreamSubscription<DatabaseEvent>? _settingsSubscription;

  bool _isDisposed = false;

  @override
  Stream<List<models.Player>> get players => _database.watchPlayers().map(
      (rows) => rows.map(_playerFromRow).toList(growable: false),
    );

  @override
  Stream<List<models.MatchHistoryEntry>> get history => _database.watchHistory().map(
      (rows) => rows.map(_historyFromRow).toList(growable: false),
    );

  @override
  Stream<models.SyncState> get syncState => _syncStateController.stream;

  @override
  Stream<int> get kFactor => _kFactorController.stream;

  @override
  Stream<models.AppThemePreference> get themePreference async* {
    yield _themePreferenceValue;
    yield* _themePreferenceController.stream;
  }

  Future<void> _initialize() async {
    await _seedPlayersIfEmpty();
    await _loadInitialKFactor();
    await _loadInitialThemePreference();
    if (!_enableRemoteSync) {
      return;
    }
    await _clearLegacyTournamentOnce();
    _attachFirebaseListeners();
  }

  @override
  Future<void> submitRoundResults(List<models.RoundResultInput> results) async {
    if (results.isEmpty) {
      return;
    }

    final currentKFactor = _kFactorValue;
    var updatedPlayers = <models.Player>[];
    var updatedHistory = <models.MatchHistoryEntry>[];

    await _database.transactionRun(() async {
      final playersById = {
        for (final row in await _database.getPlayers())
          row.id: _playerFromRow(row),
      };
      final existingHistory = (await _database.getHistory())
          .map(_historyFromRow)
          .toList(growable: true);

      final now = DateTime.now().millisecondsSinceEpoch;

      for (var index = 0; index < results.length; index += 1) {
        final resultInput = results[index];
        final p1 = playersById[resultInput.p1Id];
        final p2 = playersById[resultInput.p2Id];
        if (p1 == null || p2 == null) {
          continue;
        }

        final elo = EloEngine.apply(
          p1.elo,
          p2.elo,
          resultInput.result,
          kFactor: currentKFactor,
        );

        final newP1 = p1.copyWith(
          elo: elo.p1Elo,
          wins: p1.wins + (resultInput.result == models.MatchResult.p1 ? 1 : 0),
          losses:
              p1.losses + (resultInput.result == models.MatchResult.p2 ? 1 : 0),
          draws:
              p1.draws +
              (resultInput.result == models.MatchResult.draw ? 1 : 0),
          matchesPlayed: p1.matchesPlayed + 1,
        );

        final newP2 = p2.copyWith(
          elo: elo.p2Elo,
          wins: p2.wins + (resultInput.result == models.MatchResult.p2 ? 1 : 0),
          losses:
              p2.losses + (resultInput.result == models.MatchResult.p1 ? 1 : 0),
          draws:
              p2.draws +
              (resultInput.result == models.MatchResult.draw ? 1 : 0),
          matchesPlayed: p2.matchesPlayed + 1,
        );

        playersById[newP1.id] = newP1;
        playersById[newP2.id] = newP2;

        existingHistory.add(
          models.MatchHistoryEntry(
            id: '$now-${resultInput.p1Id}-${resultInput.p2Id}-$index',
            p1Id: p1.id,
            p2Id: p2.id,
            p1Name: p1.name,
            p2Name: p2.name,
            p1EloBefore: p1.elo,
            p2EloBefore: p2.elo,
            p1EloAfter: newP1.elo,
            p2EloAfter: newP2.elo,
            result: resultInput.result,
            timestamp: now + index,
          ),
        );
      }

      updatedPlayers = playersById.values.toList(growable: false);
      updatedHistory = HistoryPolicy.cap(
        existingHistory,
      );

      await _database.clearPlayers();
      await _database.upsertPlayers(
        updatedPlayers.map(_playerToCompanion).toList(growable: false),
      );

      await _database.clearHistory();
      await _database.upsertHistory(
        updatedHistory.map(_historyToCompanion).toList(growable: false),
      );
    });

    await _pushToFirebase(updatedPlayers, updatedHistory);
  }

  @override
  Future<void> deleteMatch(String matchId) async {
    var deleted = false;
    var updatedPlayers = <models.Player>[];
    var updatedHistory = <models.MatchHistoryEntry>[];

    await _database.transactionRun(() async {
      final target = await _database.getHistoryById(matchId);
      if (target == null) {
        return;
      }

      final targetEntry = _historyFromRow(target);
      final playersById = {
        for (final row in await _database.getPlayers())
          row.id: _playerFromRow(row),
      };

      final revertedMap = MatchRollbackEngine.revert(playersById, targetEntry);

      await _database.clearPlayers();
      await _database.upsertPlayers(
        revertedMap.values.map(_playerToCompanion).toList(growable: false),
      );
      await _database.deleteHistoryById(matchId);

      updatedPlayers = revertedMap.values.toList(growable: false);
      updatedHistory = (await _database.getHistory())
          .map(_historyFromRow)
          .toList(growable: false);
      deleted = true;
    });

    if (deleted) {
      await _pushToFirebase(updatedPlayers, updatedHistory);
    }
  }

  @override
  Future<void> resetAllData() async {
    final players = Defaults.initialPlayers();
    const history = <models.MatchHistoryEntry>[];

    await _database.transactionRun(() async {
      await _database.clearPlayers();
      await _database.upsertPlayers(
        players.map(_playerToCompanion).toList(growable: false),
      );
      await _database.clearHistory();
    });

    await _pushToFirebase(players, history);
  }

  @override
  Future<void> setKFactor(int kFactor) async {
    if (!Defaults.supportedEloKPresets.contains(kFactor)) {
      return;
    }

    await _persistKFactor(kFactor);
    await _pushKFactorToFirebase(kFactor);
  }

  @override
  Future<void> setThemePreference(models.AppThemePreference preference) async {
    await _persistThemePreference(preference);
  }

  Future<void> _seedPlayersIfEmpty() async {
    final existingPlayers = await _database.getPlayers();
    if (existingPlayers.isNotEmpty) {
      return;
    }

    final initialPlayers = Defaults.initialPlayers();
    await _database.upsertPlayers(
      initialPlayers.map(_playerToCompanion).toList(growable: false),
    );
  }

  Future<void> _clearLegacyTournamentOnce() async {
    final tournamentRef = _tournamentRef;
    if (!_enableRemoteSync || tournamentRef == null) {
      return;
    }

    final prefs = await _loadSharedPreferences();
    if (prefs.getBool(_keyLegacyTournamentCleared) == true) {
      return;
    }

    try {
      await tournamentRef.set(null);
      await prefs.setBool(_keyLegacyTournamentCleared, true);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to clear legacy tournament path.',
        name: 'sprint.repository',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _attachFirebaseListeners() {
    final playersRef = _playersRef;
    final historyRef = _historyRef;
    final settingsRef = _settingsRef;
    if (playersRef == null || historyRef == null || settingsRef == null) {
      return;
    }

    _playersSubscription = playersRef.onValue.listen(
      (event) async {
        final remotePlayers = _parsePlayers(event.snapshot);
        if (remotePlayers.isEmpty) {
          return;
        }

        await _database.transactionRun(() async {
          await _database.clearPlayers();
          await _database.upsertPlayers(
            remotePlayers.map(_playerToCompanion).toList(growable: false),
          );
        });

        _setSyncState(
          _syncStateValue.copyWith(
            lastSyncedEpochMillis: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error(
          'Players sync listener failed.',
          name: 'sprint.repository',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    _historySubscription = historyRef.onValue.listen(
      (event) async {
        if (!event.snapshot.exists) {
          await _database.clearHistory();
          return;
        }

        final remoteHistory = _parseHistory(event.snapshot);
        await _database.transactionRun(() async {
          await _database.clearHistory();
          await _database.upsertHistory(
            remoteHistory.map(_historyToCompanion).toList(growable: false),
          );
        });

        _setSyncState(
          _syncStateValue.copyWith(
            lastSyncedEpochMillis: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error(
          'History sync listener failed.',
          name: 'sprint.repository',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    _settingsSubscription = settingsRef.onValue.listen(
      (event) async {
        final remoteKFactor = _parseKFactor(event.snapshot.value);
        if (remoteKFactor == null) {
          return;
        }
        await _persistKFactor(remoteKFactor);
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error(
          'Settings sync listener failed.',
          name: 'sprint.repository',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  Future<void> _pushToFirebase(
    List<models.Player> players,
    List<models.MatchHistoryEntry> history,
  ) async {
    if (!_enableRemoteSync || _playersRef == null || _historyRef == null) {
      _setSyncState(
        models.SyncState(
          lastSyncedEpochMillis: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return;
    }

    final playersRef = _playersRef!;
    final historyRef = _historyRef!;

    _setSyncState(_syncStateValue.copyWith(isSyncing: true));
    try {
      await playersRef.set(
        players.map((player) => player.toJson()).toList(growable: false),
      );
      await historyRef.set(
        history.map((entry) => entry.toJson()).toList(growable: false),
      );
      _setSyncState(
        models.SyncState(
          lastSyncedEpochMillis: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to push leaderboard state to Firebase.',
        name: 'sprint.repository',
        error: error,
        stackTrace: stackTrace,
      );
      _setSyncState(_syncStateValue.copyWith(isSyncing: false));
    }
  }

  Future<void> _persistKFactor(int kFactor) async {
    if (!Defaults.supportedEloKPresets.contains(kFactor)) {
      return;
    }

    final prefs = await _loadSharedPreferences();
    await prefs.setInt(_keyEloKFactor, kFactor);
    await _database.setSetting(_settingKFactor, kFactor.toString());

    _kFactorValue = kFactor;
    _kFactorController.add(kFactor);
  }

  Future<void> _loadInitialKFactor() async {
    final databaseValue = await _database.getSetting(_settingKFactor);
    final parsedDb = int.tryParse(databaseValue ?? '');
    if (parsedDb != null && Defaults.supportedEloKPresets.contains(parsedDb)) {
      _kFactorValue = parsedDb;
      _kFactorController.add(_kFactorValue);
      return;
    }

    final prefs = await _loadSharedPreferences();
    final persisted = prefs.getInt(_keyEloKFactor) ?? Defaults.eloK;
    _kFactorValue = Defaults.supportedEloKPresets.contains(persisted)
        ? persisted
        : Defaults.eloK;

    await _database.setSetting(_settingKFactor, _kFactorValue.toString());
    _kFactorController.add(_kFactorValue);
  }

  Future<void> _pushKFactorToFirebase(int kFactor) async {
    final settingsRef = _settingsRef;
    if (!_enableRemoteSync || settingsRef == null) {
      return;
    }

    try {
      await settingsRef.set(<String, Object>{'kFactor': kFactor});
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to push k-factor to Firebase.',
        name: 'sprint.repository',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _persistThemePreference(
    models.AppThemePreference preference,
  ) async {
    final prefs = await _loadSharedPreferences();
    await prefs.setString(_keyThemeMode, preference.toWire());
    await _database.setSetting(_settingThemeMode, preference.toWire());
    _themePreferenceValue = preference;
    _themePreferenceController.add(preference);
  }

  Future<void> _loadInitialThemePreference() async {
    final databaseValue = await _database.getSetting(_settingThemeMode);
    if (databaseValue != null && databaseValue.isNotEmpty) {
      _themePreferenceValue = models.AppThemePreference.fromWire(databaseValue);
      _themePreferenceController.add(_themePreferenceValue);
      return;
    }

    final prefs = await _loadSharedPreferences();
    final persisted = prefs.getString(_keyThemeMode);
    _themePreferenceValue = models.AppThemePreference.fromWire(persisted);
    await _database.setSetting(
      _settingThemeMode,
      _themePreferenceValue.toWire(),
    );
    await prefs.setString(_keyThemeMode, _themePreferenceValue.toWire());
    _themePreferenceController.add(_themePreferenceValue);
  }

  List<models.Player> _parsePlayers(DataSnapshot snapshot) {
    final players = <models.Player>[];
    for (final child in snapshot.children) {
      final raw = child.value;
      if (raw is! Map) {
        continue;
      }
      final normalized = raw.map(
        (key, value) =>
            MapEntry<String, Object?>(key.toString(), value as Object?),
      );
      final id = normalized['id']?.toString().trim() ?? '';
      final name = normalized['name']?.toString().trim() ?? '';
      if (id.isEmpty || name.isEmpty) {
        continue;
      }
      players.add(models.Player.fromJson(normalized));
    }
    return players;
  }

  List<models.MatchHistoryEntry> _parseHistory(DataSnapshot snapshot) {
    final history = <models.MatchHistoryEntry>[];
    for (final child in snapshot.children) {
      final raw = child.value;
      if (raw is! Map) {
        continue;
      }
      final normalized = raw.map(
        (key, value) =>
            MapEntry<String, Object?>(key.toString(), value as Object?),
      );
      final id = normalized['id']?.toString().trim() ?? '';
      if (id.isEmpty) {
        continue;
      }
      history.add(models.MatchHistoryEntry.fromJson(normalized));
    }

    history.sort((left, right) => right.timestamp.compareTo(left.timestamp));
    return history;
  }

  int? _parseKFactor(Object? rawValue) {
    final value = switch (rawValue) {
      final Map<dynamic, dynamic> map => map['kFactor'],
      _ => rawValue,
    };

    final parsed = switch (value) {
      final int v => v,
      final num v => v.toInt(),
      final String v => int.tryParse(v),
      _ => null,
    };

    if (parsed == null || !Defaults.supportedEloKPresets.contains(parsed)) {
      return null;
    }

    return parsed;
  }

  models.Player _playerFromRow(db.Player row) => models.Player(
      id: row.id,
      name: row.name,
      elo: row.elo,
      wins: row.wins,
      losses: row.losses,
      draws: row.draws,
      matchesPlayed: row.matchesPlayed,
    );

  db.PlayersCompanion _playerToCompanion(models.Player player) => db.PlayersCompanion(
      id: Value<String>(player.id),
      name: Value<String>(player.name),
      elo: Value<int>(player.elo),
      wins: Value<int>(player.wins),
      losses: Value<int>(player.losses),
      draws: Value<int>(player.draws),
      matchesPlayed: Value<int>(player.matchesPlayed),
    );

  models.MatchHistoryEntry _historyFromRow(db.MatchHistoryData row) => models.MatchHistoryEntry(
      id: row.id,
      p1Id: row.p1Id,
      p2Id: row.p2Id,
      p1Name: row.p1Name,
      p2Name: row.p2Name,
      p1EloBefore: row.p1EloBefore,
      p2EloBefore: row.p2EloBefore,
      p1EloAfter: row.p1EloAfter,
      p2EloAfter: row.p2EloAfter,
      result: models.MatchResult.fromWire(row.result),
      timestamp: row.timestamp,
    );

  db.MatchHistoryCompanion _historyToCompanion(models.MatchHistoryEntry entry) => db.MatchHistoryCompanion(
      id: Value<String>(entry.id),
      p1Id: Value<String>(entry.p1Id),
      p2Id: Value<String>(entry.p2Id),
      p1Name: Value<String>(entry.p1Name),
      p2Name: Value<String>(entry.p2Name),
      p1EloBefore: Value<int>(entry.p1EloBefore),
      p2EloBefore: Value<int>(entry.p2EloBefore),
      p1EloAfter: Value<int>(entry.p1EloAfter),
      p2EloAfter: Value<int>(entry.p2EloAfter),
      result: Value<String>(entry.result.toWire()),
      timestamp: Value<int>(entry.timestamp),
    );

  void _setSyncState(models.SyncState state) {
    _syncStateValue = state;
    _syncStateController.add(state);
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _playersSubscription?.cancel();
    _historySubscription?.cancel();
    _settingsSubscription?.cancel();
    _syncStateController.close();
    _kFactorController.close();
    _themePreferenceController.close();
    _database.close();
  }

  static const String _keyLegacyTournamentCleared =
      'legacy_tournament_cleared_v1';
  static const String _keyEloKFactor = 'elo_k_factor_v1';
  static const String _keyThemeMode = 'theme_mode_v1';
  static const String _settingKFactor = 'k_factor';
  static const String _settingThemeMode = 'theme_mode';
}
