import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprint/data/local/app_database.dart';
import 'package:sprint/data/repository/sprint_repository_impl.dart';
import 'package:sprint/domain/defaults.dart';
import 'package:sprint/models/app_models.dart';

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('SprintRepositoryImpl', () {
    late AppDatabase database;
    late SprintRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = SprintRepositoryImpl(
        database: database,
        enableRemoteSync: false,
      );
      await repository.players.firstWhere((players) => players.isNotEmpty);
      await _flush();
    });

    tearDown(() {
      repository.dispose();
    });

    test('submitRoundResults updates local players and history', () async {
      final seededPlayers = await repository.players.first;
      final p1 = seededPlayers[0];
      final p2 = seededPlayers[1];

      await repository.submitRoundResults(<RoundResultInput>[
        RoundResultInput(p1Id: p1.id, p2Id: p2.id, result: MatchResult.p1),
      ]);
      await _flush();

      final players = await repository.players.first;
      final history = await repository.history.first;
      final updatedP1 = players.firstWhere((player) => player.id == p1.id);
      final updatedP2 = players.firstWhere((player) => player.id == p2.id);

      expect(history.length, 1);
      expect(updatedP1.matchesPlayed, 1);
      expect(updatedP2.matchesPlayed, 1);
      expect(updatedP1.elo, greaterThan(p1.elo));
      expect(updatedP2.elo, lessThan(p2.elo));
    });

    test('deleteMatch rolls back elo and counters', () async {
      final seededPlayers = await repository.players.first;
      final p1 = seededPlayers[0];
      final p2 = seededPlayers[1];

      await repository.submitRoundResults(<RoundResultInput>[
        RoundResultInput(p1Id: p1.id, p2Id: p2.id, result: MatchResult.p1),
      ]);
      await _flush();

      final insertedHistory = await repository.history.first;
      expect(insertedHistory, hasLength(1));

      await repository.deleteMatch(insertedHistory.single.id);
      await _flush();

      final players = await repository.players.first;
      final history = await repository.history.first;
      final rolledBackP1 = players.firstWhere((player) => player.id == p1.id);
      final rolledBackP2 = players.firstWhere((player) => player.id == p2.id);

      expect(history, isEmpty);
      expect(rolledBackP1.matchesPlayed, 0);
      expect(rolledBackP2.matchesPlayed, 0);
      expect(rolledBackP1.elo, Defaults.initialElo);
      expect(rolledBackP2.elo, Defaults.initialElo);
    });

    test(
      'setKFactor persists supported values and rejects unsupported values',
      () async {
        await repository.setKFactor(48);
        await _flush();

        expect(await database.getSetting('k_factor'), '48');

        await repository.setKFactor(999);
        await _flush();

        expect(await database.getSetting('k_factor'), '48');
      },
    );

    test('theme preference defaults to light', () async {
      expect(await repository.themePreference.first, AppThemePreference.light);
      expect(await database.getSetting('theme_mode'), 'light');
    });

    test(
      'setThemePreference persists preference to database and shared preferences',
      () async {
        await repository.setThemePreference(AppThemePreference.dark);
        await _flush();

        expect(await repository.themePreference.first, AppThemePreference.dark);
        expect(await database.getSetting('theme_mode'), 'dark');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme_mode_v1'), 'dark');
      },
    );

    test(
      'theme preference load prioritizes database setting over shared preferences',
      () async {
        repository.dispose();
        SharedPreferences.setMockInitialValues(<String, Object>{
          'theme_mode_v1': 'light',
        });
        database = AppDatabase.forTesting(NativeDatabase.memory());
        await database.setSetting('theme_mode', 'dark');

        repository = SprintRepositoryImpl(
          database: database,
          enableRemoteSync: false,
        );
        await repository.players.firstWhere((players) => players.isNotEmpty);
        await _flush();

        expect(await repository.themePreference.first, AppThemePreference.dark);
      },
    );

    test(
      'persists remote-sync, client-audio and fullscreen settings locally',
      () async {
        expect(await repository.remoteSyncEnabled.first, isFalse);
        expect(await repository.useClientAudio.first, isFalse);
        expect(await repository.manualFullscreenEnabled.first, isFalse);

        await repository.setRemoteSyncEnabled(false);
        await repository.setUseClientAudio(true);
        await repository.setManualFullscreenEnabled(true);
        await _flush();

        expect(await database.getSetting('remote_sync_enabled'), 'false');
        expect(await database.getSetting('use_client_audio'), 'true');
        expect(await database.getSetting('manual_fullscreen_enabled'), 'true');
      },
    );

    test(
      'blocks cloud actions while sync is off and keeps local reset functional',
      () async {
        final seededPlayers = await repository.players.first;
        final p1 = seededPlayers[0];
        final p2 = seededPlayers[1];

        await repository.submitRoundResults(<RoundResultInput>[
          RoundResultInput(p1Id: p1.id, p2Id: p2.id, result: MatchResult.p1),
        ]);
        await _flush();
        expect(await repository.history.first, isNotEmpty);

        await repository.seedCloudData();
        await repository.resetCloudData();
        await _flush();

        expect(await repository.history.first, isNotEmpty);

        await repository.resetLocalData();
        await _flush();

        expect(await repository.history.first, isEmpty);
        final players = await repository.players.first;
        expect(
          players.every((player) => player.elo == Defaults.initialElo),
          isTrue,
        );
      },
    );
  });
}
