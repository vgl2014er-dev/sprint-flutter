import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprint/data/repository/sprint_repository.dart';
import 'package:sprint/models/app_models.dart';
import 'package:sprint/platform/platform_channels.dart';
import 'package:sprint/state/sprint_controller.dart';
import 'package:sprint/ui/screens/sprint_app.dart';

void main() {
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    required _FakeSprintRepository repository,
    required _FakePlatformAdapter platform,
  }) async {
    final container = ProviderContainer(
      overrides: <Override>[
        sprintRepositoryProvider.overrideWithValue(repository),
        platformChannelsProvider.overrideWithValue(platform),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SprintApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('hides settings icon entry points across shell UI', (
    WidgetTester tester,
  ) async {
    final repository = _FakeSprintRepository();
    final platform = _FakePlatformAdapter();
    await pumpApp(tester, repository: repository, platform: platform);

    expect(find.byKey(const Key('settings-fab')), findsNothing);
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets(
    'leaderboard screen runs fullscreen without shell header/footer',
    (WidgetTester tester) async {
      final repository = _FakeSprintRepository();
      final platform = _FakePlatformAdapter();
      await pumpApp(tester, repository: repository, platform: platform);

      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();

      expect(find.text('LEADERBOARD'), findsOneWidget);
      expect(find.byType(AppHeader), findsNothing);
      expect(find.byType(AppFooter), findsNothing);
    },
  );

  testWidgets('programmatically opened settings modal closes on system back', (
    WidgetTester tester,
  ) async {
    final repository = _FakeSprintRepository();
    final platform = _FakePlatformAdapter();
    final container = await pumpApp(
      tester,
      repository: repository,
      platform: platform,
    );

    container.read(sprintControllerProvider.notifier).openSettingsModal();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-modal-close')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-modal-close')), findsNothing);
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
  final StreamController<bool> _remoteSyncController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _useClientAudioController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _manualFullscreenController =
      StreamController<bool>.broadcast();

  final List<Player> _players = const <Player>[];
  final List<MatchHistoryEntry> _history = const <MatchHistoryEntry>[];
  final SyncState _syncState = const SyncState();
  int _kFactor = 32;
  AppThemePreference _themePreference = AppThemePreference.light;
  bool _remoteSyncEnabled = true;
  bool _useClientAudio = false;
  bool _manualFullscreenEnabled = false;

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
  Stream<bool> get remoteSyncEnabled async* {
    yield _remoteSyncEnabled;
    yield* _remoteSyncController.stream;
  }

  @override
  Stream<bool> get useClientAudio async* {
    yield _useClientAudio;
    yield* _useClientAudioController.stream;
  }

  @override
  Stream<bool> get manualFullscreenEnabled async* {
    yield _manualFullscreenEnabled;
    yield* _manualFullscreenController.stream;
  }

  @override
  Future<void> submitRoundResults(List<RoundResultInput> results) async {}

  @override
  Future<void> deleteMatch(String matchId) async {}

  @override
  Future<void> resetAllData() async {}

  @override
  Future<void> resetLocalData() async {}

  @override
  Future<void> resetCloudData() async {}

  @override
  Future<void> seedCloudData() async {}

  @override
  Future<void> setKFactor(int kFactor) async {
    _kFactor = kFactor;
    _kFactorController.add(kFactor);
  }

  @override
  Future<void> setThemePreference(AppThemePreference preference) async {
    _themePreference = preference;
    _themeController.add(preference);
  }

  @override
  Future<void> setRemoteSyncEnabled(bool enabled) async {
    _remoteSyncEnabled = enabled;
    _remoteSyncController.add(enabled);
  }

  @override
  Future<void> setUseClientAudio(bool enabled) async {
    _useClientAudio = enabled;
    _useClientAudioController.add(enabled);
  }

  @override
  Future<void> setManualFullscreenEnabled(bool enabled) async {
    _manualFullscreenEnabled = enabled;
    _manualFullscreenController.add(enabled);
  }

  @override
  void dispose() {
    _playersController.close();
    _historyController.close();
    _syncStateController.close();
    _kFactorController.close();
    _themeController.close();
    _remoteSyncController.close();
    _useClientAudioController.close();
    _manualFullscreenController.close();
  }
}

class _FakePlatformAdapter implements SprintPlatformAdapter {
  final StreamController<LocalSessionState> _localSessionController =
      StreamController<LocalSessionState>.broadcast();
  final StreamController<LocalLeaderboardSnapshot> _localSnapshotController =
      StreamController<LocalLeaderboardSnapshot>.broadcast();
  final StreamController<LocalControlEvent> _localControlController =
      StreamController<LocalControlEvent>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  @override
  Stream<LocalSessionState> get localSessionState =>
      _localSessionController.stream;

  @override
  Stream<LocalLeaderboardSnapshot> get localSnapshot =>
      _localSnapshotController.stream;

  @override
  Stream<LocalControlEvent> get localControlEvents =>
      _localControlController.stream;

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
  Future<void> sendStartMatchBeepControl() async {}

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
    _localControlController.close();
    _errorController.close();
  }
}
