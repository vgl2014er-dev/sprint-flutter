import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Drift table containing player leaderboard stats.
class Players extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  IntColumn get elo => integer()();

  IntColumn get wins => integer()();

  IntColumn get losses => integer()();

  IntColumn get draws => integer()();

  IntColumn get matchesPlayed => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Drift table storing immutable match history entries.
class MatchHistory extends Table {
  TextColumn get id => text()();

  TextColumn get p1Id => text()();

  TextColumn get p2Id => text()();

  TextColumn get p1Name => text()();

  TextColumn get p2Name => text()();

  IntColumn get p1EloBefore => integer()();

  IntColumn get p2EloBefore => integer()();

  IntColumn get p1EloAfter => integer()();

  IntColumn get p2EloAfter => integer()();

  TextColumn get result => text()();

  IntColumn get timestamp => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Drift table for app-level key-value settings.
class AppSettings extends Table {
  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'sprint_elo.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(tables: <Type>[Players, MatchHistory, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Creates an instance backed by a custom executor (used in tests).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  Stream<List<Player>> watchPlayers() {
    return (select(players)).watch();
  }

  Stream<List<MatchHistoryData>> watchHistory() {
    return (select(matchHistory)..orderBy(<OrderingTerm Function(MatchHistory)>[
          (table) => OrderingTerm.desc(table.timestamp),
        ]))
        .watch();
  }

  Future<List<Player>> getPlayers() => select(players).get();

  Future<List<MatchHistoryData>> getHistory() {
    return (select(matchHistory)..orderBy(<OrderingTerm Function(MatchHistory)>[
          (table) => OrderingTerm.desc(table.timestamp),
        ]))
        .get();
  }

  Future<MatchHistoryData?> getHistoryById(String id) {
    return (select(
      matchHistory,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertPlayers(List<PlayersCompanion> companions) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(players, companions);
    });
  }

  Future<void> upsertHistory(List<MatchHistoryCompanion> companions) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(matchHistory, companions);
    });
  }

  Future<void> clearPlayers() => delete(players).go();

  Future<void> clearHistory() => delete(matchHistory).go();

  Future<void> deleteHistoryById(String id) {
    return (delete(matchHistory)..where((table) => table.id.equals(id))).go();
  }

  Future<void> setSetting(String key, String value) {
    return into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(
        key: Value<String>(key),
        value: Value<String>(value),
      ),
    );
  }

  Future<String?> getSetting(String key) async {
    final row = await (select(
      appSettings,
    )..where((table) => table.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> transactionRun(Future<void> Function() action) {
    return transaction(action);
  }
}
