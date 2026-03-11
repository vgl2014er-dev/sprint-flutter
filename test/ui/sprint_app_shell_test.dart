import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprint/data/repository/sprint_repository.dart';
import 'package:sprint/models/app_models.dart';
import 'package:sprint/platform/platform_channels.dart';
import 'package:sprint/state/sprint_controller.dart';
import 'package:sprint/ui/screens/sprint_app.dart';

void main() {
  testWidgets('header theme toggle renders and toggles app preference', (
    WidgetTester tester,
  ) async {
    final repository = _FakeSprintRepository();
    final platform = _FakePlatformAdapter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sprintRepositoryProvider.overrideWithValue(repository),
          platformChannelsProvider.overrideWithValue(platform),
        ],
        child: const SprintApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Players'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pumpAndSettle();

    expect(repository.setThemePreferenceCalls, 1);
    expect(repository.lastSetThemePreference, AppThemePreference.dark);
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
  });

  testWidgets('leaderboard header shows theme toggle and reset actions', (
    WidgetTester tester,
  ) async {
    final repository = _FakeSprintRepository();
    final platform = _FakePlatformAdapter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sprintRepositoryProvider.overrideWithValue(repository),
          platformChannelsProvider.overrideWithValue(platform),
        ],
        child: const SprintApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leaderboard'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Reset Leaderboard?'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Reset Data'), findsOneWidget);
  });
}

class _FakeSprintRepository implements SprintRepository {
  final StreamController<List<Player>> _playersController =
      StreamController<List<Player>>.broadcast();
  final StreamController<List<MatchHistoryEntry>> _historyController =
      StreamController<List<MatchHistoryEntry>>.broadcast();
  final StreamController<SyncState> _syncStateController =
      StreamController<SyncState>.broadcast();
  final StreamController<int> _kFactorController =
      StreamController<int>.broadcast();
  final StreamController<AppThemePreference> _themeController =
      StreamController<AppThemePreference>.broadcast();

  final List<Player> _players = const <Player>[];
  final List<MatchHistoryEntry> _history = const <MatchHistoryEntry>[];
  final SyncState _syncState = const SyncState();
  int _kFactor = 32;
  AppThemePreference _themePreference = AppThemePreference.light;

  int setThemePreferenceCalls = 0;
  AppThemePreference? lastSetThemePreference;

  @override
  Stream<List<Player>> get players async* {
    yield _players;
    yield* _playersController.stream;
  }

  @override
  Stream<List<MatchHistoryEntry>> get history async* {
    yield _history;
    yield* _historyController.stream;
  }

  @override
  Stream<SyncState> get syncState async* {
    yield _syncState;
    yield* _syncStateController.stream;
  }

  @override
  Stream<int> get kFactor async* {
    yield _kFactor;
    yield* _kFactorController.stream;
  }

  @override
  Stream<AppThemePreference> get themePreference async* {
    yield _themePreference;
    yield* _themeController.stream;
  }

  @override
  Future<void> submitRoundResults(List<RoundResultInput> results) async {}

  @override
  Future<void> deleteMatch(String matchId) async {}

  @override
  Future<void> resetAllData() async {}

  @override
  Future<void> setKFactor(int kFactor) async {
    _kFactor = kFactor;
    _kFactorController.add(kFactor);
  }

  @override
  Future<void> setThemePreference(AppThemePreference preference) async {
    setThemePreferenceCalls += 1;
    lastSetThemePreference = preference;
    _themePreference = preference;
    _themeController.add(preference);
  }

  @override
  void dispose() {
    _playersController.close();
    _historyController.close();
    _syncStateController.close();
    _kFactorController.close();
    _themeController.close();
  }
}

class _FakePlatformAdapter implements SprintPlatformAdapter {
  final StreamController<LocalSessionState> _localSessionController =
      StreamController<LocalSessionState>.broadcast();
  final StreamController<LocalLeaderboardSnapshot> _localSnapshotController =
      StreamController<LocalLeaderboardSnapshot>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  @override
  Stream<LocalSessionState> get localSessionState =>
      _localSessionController.stream;

  @override
  Stream<LocalLeaderboardSnapshot> get localSnapshot =>
      _localSnapshotController.stream;

  @override
  Stream<String> get errors => _errorController.stream;

  @override
  Future<void> acceptLocalConnection() async {}

  @override
  Future<void> connectToLocalHost(String endpointId) async {}

  @override
  Future<void> disconnectLocalConnection() async {}

  @override
  Future<void> publishLocalHostedSnapshot(
    LocalLeaderboardSnapshot snapshot,
  ) async {}

  @override
  Future<void> rejectLocalConnection() async {}

  @override
  Future<void> scanLocalHosts(String localEndpointName) async {}

  @override
  Future<void> setImmersiveMode({bool showStatusBar = true}) async {}

  @override
  Future<void> startLocalHosting(String localEndpointName) async {}

  @override
  Future<void> stopLocalHosting() async {}

  @override
  Future<void> useDatabaseModeForLocal() async {}

  @override
  void dispose() {
    _localSessionController.close();
    _localSnapshotController.close();
    _errorController.close();
  }
}
