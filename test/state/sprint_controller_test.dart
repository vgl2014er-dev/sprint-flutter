import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprint/data/repository/sprint_repository.dart';
import 'package:sprint/models/app_models.dart';
import 'package:sprint/platform/platform_channels.dart';
import 'package:sprint/state/sprint_controller.dart';

import '../test_helpers.dart';

void main() {
  group('SprintController', () {
    late FakeSprintRepository repository;
    late FakeSprintPlatform platform;
    late SprintController controller;

    setUp(() async {
      repository = FakeSprintRepository();
      platform = FakeSprintPlatform();
      controller = SprintController(
        repository: repository,
        platformChannels: platform,
      );

      repository.emitPlayers(<Player>[
        player('a', name: 'A', elo: 1600),
        player('b', name: 'B', elo: 1500),
        player('c', name: 'C', elo: 1400),
        player('d', name: 'D', elo: 1300),
      ]);
      repository.emitHistory(const <MatchHistoryEntry>[]);
      repository.emitSync(const SyncState(lastSyncedEpochMillis: 1));
      repository.emitKFactor(32);
      repository.emitThemePreference(AppThemePreference.light);
      repository.emitRemoteSyncEnabled(true);
      repository.emitUseClientAudio(false);
      repository.emitManualFullscreenEnabled(false);
      await flushState();
    });

    tearDown(() {
      controller.dispose();
      repository.dispose();
      platform.dispose();
    });

    test('reorders first match away from excluded players', () {
      final matches = <UiRoundMatch>[
        UiRoundMatch(id: 'm1', player1: player('a'), player2: player('b')),
        UiRoundMatch(id: 'm2', player1: player('c'), player2: player('d')),
      ];

      final reordered = reorderRoundMatchesToAvoidFirstMatchPlayers(
        matches,
        excludedPlayerIds: const <String>{'a', 'b'},
      );

      expect(reordered.first.id, 'm2');
      expect(reordered.last.id, 'm1');
    });

    test('locks local client mode to leaderboard', () async {
      platform.emitLocalSession(
        const LocalSessionState(
          role: LocalSessionRole.client,
          phase: LocalSessionPhase.connected,
        ),
      );
      await flushState();

      expect(controller.state.leaderboardSource, LeaderboardSource.local);
      expect(controller.state.screen, Screen.leaderboard);

      controller.navigateTo(Screen.playerList);
      expect(controller.state.screen, Screen.leaderboard);
    });

    test('unlocks navigation when local client disconnects', () async {
      platform.emitLocalSession(
        const LocalSessionState(
          role: LocalSessionRole.client,
          phase: LocalSessionPhase.connected,
        ),
      );
      await flushState();
      expect(controller.state.isReadOnlyClientMode, isTrue);

      platform.emitLocalSession(
        const LocalSessionState(
          role: LocalSessionRole.client,
          phase: LocalSessionPhase.disconnected,
        ),
      );
      await flushState();

      expect(controller.state.isReadOnlyClientMode, isFalse);
      controller.navigateTo(Screen.playerList);
      expect(controller.state.screen, Screen.playerList);
    });

    test(
      'connect and disconnect apply source/screen/modal transitions',
      () async {
        controller.openSettingsModal();
        expect(controller.state.isSettingsOpen, isTrue);

        platform.emitLocalSession(
          const LocalSessionState(
            role: LocalSessionRole.client,
            phase: LocalSessionPhase.connected,
          ),
        );
        await flushState();

        expect(controller.state.screen, Screen.leaderboard);
        expect(controller.state.leaderboardSource, LeaderboardSource.local);
        expect(controller.state.isSettingsOpen, isFalse);

        platform.emitLocalSession(
          const LocalSessionState(
            role: LocalSessionRole.client,
            phase: LocalSessionPhase.disconnected,
          ),
        );
        await flushState();

        expect(controller.state.screen, Screen.landing);
        expect(controller.state.leaderboardSource, LeaderboardSource.db);
        expect(controller.state.isSettingsOpen, isFalse);
      },
    );

    test('sync and client-audio toggles propagate to repository', () async {
      controller.toggleRemoteSync(false);
      controller.toggleClientAudio(true);
      await flushState();

      expect(repository.setRemoteSyncEnabledCalls, 1);
      expect(repository.lastRemoteSyncEnabled, isFalse);
      expect(repository.setUseClientAudioCalls, 1);
      expect(repository.lastUseClientAudioEnabled, isTrue);
    });

    test(
      'auto-suspends remote sync while connected and restores on disconnect',
      () async {
        expect(controller.state.remoteSyncEnabled, isTrue);

        platform.emitLocalSession(
          const LocalSessionState(
            role: LocalSessionRole.host,
            phase: LocalSessionPhase.connected,
          ),
        );
        await flushState();

        expect(controller.state.remoteSyncEnabled, isFalse);
        expect(repository.setRemoteSyncEnabledCalls, 1);
        expect(repository.lastRemoteSyncEnabled, isFalse);

        platform.emitLocalSession(
          const LocalSessionState(
            role: LocalSessionRole.host,
            phase: LocalSessionPhase.disconnected,
          ),
        );
        await flushState();

        expect(controller.state.remoteSyncEnabled, isTrue);
        expect(repository.setRemoteSyncEnabledCalls, 2);
        expect(repository.lastRemoteSyncEnabled, isTrue);
      },
    );

    test(
      'does not auto-restore remote sync after explicit override while connected',
      () async {
        platform.emitLocalSession(
          const LocalSessionState(
            role: LocalSessionRole.host,
            phase: LocalSessionPhase.connected,
          ),
        );
        await flushState();
        expect(controller.state.remoteSyncEnabled, isFalse);
        expect(repository.setRemoteSyncEnabledCalls, 1);

        controller.toggleRemoteSync(true);
        await flushState();
        expect(controller.state.remoteSyncEnabled, isTrue);
        expect(repository.setRemoteSyncEnabledCalls, 2);
        expect(repository.lastRemoteSyncEnabled, isTrue);

        platform.emitLocalSession(
          const LocalSessionState(
            role: LocalSessionRole.host,
            phase: LocalSessionPhase.disconnected,
          ),
        );
        await flushState();

        expect(repository.setRemoteSyncEnabledCalls, 2);
        expect(controller.state.remoteSyncEnabled, isTrue);
      },
    );

    test(
      'sends start-match beep control only when host is connected and enabled',
      () async {
        final started = controller.generateMatches(
          const <String>{'a', 'b'},
          PairingStrategy.random,
          targetMatchesPerPlayer: 1,
        );
        expect(started, isTrue);
        final match = controller.state.roundMatches.single;

        controller.startMatch(match.id);
        await flushState();
        expect(platform.sendStartMatchBeepControlCalls, 0);

        repository.emitUseClientAudio(true);
        platform.emitLocalSession(
          const LocalSessionState(
            role: LocalSessionRole.host,
            phase: LocalSessionPhase.connected,
          ),
        );
        await flushState();

        controller.startMatch(match.id);
        await flushState();
        expect(platform.sendStartMatchBeepControlCalls, 1);
      },
    );

    test('surfaces platform errors in local session state', () async {
      platform.emitError('nearby_failed');
      await flushState();

      expect(controller.state.localSessionState.phase, LocalSessionPhase.error);
      expect(controller.state.localSessionState.errorMessage, 'nearby_failed');
    });

    test(
      'disconnect falls back to db source and local snapshot is no longer active',
      () async {
        final remotePlayers = <Player>[
          player('x', name: 'Remote X', elo: 1800),
          player('y', name: 'Remote Y', elo: 1700),
        ];

        platform.emitLocalSession(
          const LocalSessionState(
            role: LocalSessionRole.client,
            phase: LocalSessionPhase.connected,
          ),
        );
        await flushState();
        expect(controller.state.players.first.id, 'a');

        platform.emitLocalSnapshot(
          LocalLeaderboardSnapshot(
            hostDisplayName: 'Host',
            generatedAtEpochMillis: 10,
            kFactor: 24,
            lastSyncedEpochMillis: 9,
            players: remotePlayers,
          ),
        );
        await flushState();
        expect(controller.state.players, remotePlayers);

        platform.emitLocalSession(
          const LocalSessionState(
            role: LocalSessionRole.client,
            phase: LocalSessionPhase.disconnected,
          ),
        );
        await flushState();
        expect(controller.state.leaderboardSource, LeaderboardSource.db);
        expect(controller.state.players.first.id, 'a');
        expect(controller.state.screen, Screen.landing);

        controller.useDatabaseLeaderboard();
        await flushState();
        expect(controller.state.leaderboardSource, LeaderboardSource.db);
        expect(controller.state.players.first.id, 'a');
        expect(platform.useDbForLocalCalls, 1);
      },
    );

    test('starts local hosting using local-only platform flow', () async {
      controller.startLocalHosting('Sprint Device');
      await flushState();

      expect(platform.useDbForLocalCalls, 1);
      expect(platform.startLocalHostingCalls, 1);
    });

    test(
      'handles repository write failures without uncaught async errors',
      () async {
        repository.setKFactorError = StateError('set_k_failed');
        repository.setThemePreferenceError = StateError('set_theme_failed');
        repository.deleteMatchError = StateError('delete_failed');
        repository.submitRoundResultsError = StateError('submit_failed');

        final started = controller.generateMatches(
          const <String>{'a', 'b'},
          PairingStrategy.random,
          targetMatchesPerPlayer: 1,
        );
        expect(started, isTrue);

        controller.setKFactor(48);
        controller.toggleThemePreference();
        controller.deleteMatch('match-1');
        final match = controller.state.roundMatches.single;
        controller.recordResult(match.id, MatchResult.p1);
        await flushState();

        expect(repository.setKFactorCalls, 1);
        expect(repository.setThemePreferenceCalls, 1);
        expect(repository.deleteMatchCalls, 1);
        expect(repository.submitRoundResultsCalls, 1);
      },
    );

    test('applies theme preference stream updates and toggles theme', () async {
      expect(controller.state.themePreference, AppThemePreference.light);

      repository.emitThemePreference(AppThemePreference.dark);
      await flushState();

      expect(controller.state.themePreference, AppThemePreference.dark);

      controller.toggleThemePreference();
      await flushState();

      expect(repository.setThemePreferenceCalls, 1);
      expect(repository.lastSetThemePreference, AppThemePreference.light);
    });

    test(
      'handles platform command failures without uncaught async errors',
      () async {
        platform.useDbForLocalError = StateError('use_db_failed');
        platform.startLocalHostingError = StateError('start_host_failed');
        platform.scanLocalHostsError = StateError('scan_hosts_failed');

        controller.startLocalHosting('Sprint Device');
        controller.scanLocalHosts('Sprint Device');
        await flushState();

        expect(platform.useDbForLocalCalls, 1);
        expect(platform.startLocalHostingCalls, 1);
        expect(platform.scanLocalHostsCalls, 1);
      },
    );

    test('scanning local hosts keeps setup flow on landing', () async {
      expect(controller.state.screen, Screen.landing);

      controller.scanLocalHosts('Sprint Device');
      await flushState();

      expect(controller.state.screen, Screen.landing);
      expect(platform.scanLocalHostsCalls, 1);
    });

    test(
      'enters fullscreen immersive mode when local client connects',
      () async {
        expect(platform.immersiveShowStatusBarCalls, <bool>[true]);

        platform.emitLocalSession(
          const LocalSessionState(
            role: LocalSessionRole.client,
            phase: LocalSessionPhase.connected,
          ),
        );
        await flushState();

        expect(platform.immersiveShowStatusBarCalls, <bool>[true, false]);
      },
    );

    test('restores status bar immersive mode after local disconnect', () async {
      platform.emitLocalSession(
        const LocalSessionState(
          role: LocalSessionRole.client,
          phase: LocalSessionPhase.connected,
        ),
      );
      await flushState();
      expect(platform.immersiveShowStatusBarCalls, <bool>[true, false]);

      platform.emitLocalSession(
        const LocalSessionState(
          role: LocalSessionRole.client,
          phase: LocalSessionPhase.disconnected,
        ),
      );
      await flushState();

      expect(platform.immersiveShowStatusBarCalls, <bool>[true, false, true]);
    });

    test('manual fullscreen toggle updates immersive mode', () async {
      expect(platform.immersiveShowStatusBarCalls, <bool>[true]);

      controller.toggleFullscreen(true);
      await flushState();
      expect(platform.immersiveShowStatusBarCalls.last, isFalse);

      controller.toggleFullscreen(false);
      await flushState();
      expect(platform.immersiveShowStatusBarCalls.last, isTrue);
    });

    test(
      'generates standard session queue where everyone reaches target',
      () async {
        final started = controller.generateMatches(const <String>{
          'a',
          'b',
          'c',
        }, PairingStrategy.random);

        expect(started, isTrue);
        expect(controller.state.isStandardSession, isTrue);
        expect(controller.state.standardSessionTargetMatchesPerPlayer, 3);
        expect(
          controller.state.standardSessionParticipantIds,
          unorderedEquals(<String>['a', 'b', 'c']),
        );
        expect(controller.state.roundMatches, isNotEmpty);

        for (final id in controller.state.standardSessionParticipantIds) {
          expect(
            controller.state.standardSessionScheduledMatchesByPlayerId[id] ?? 0,
            greaterThanOrEqualTo(3),
          );
        }
      },
    );

    test(
      'recording standard session result updates contribution and index',
      () async {
        final started = controller.generateMatches(
          const <String>{'a', 'b'},
          PairingStrategy.elo,
          targetMatchesPerPlayer: 2,
        );
        expect(started, isTrue);

        final firstMatch = controller.state.roundMatches.first;
        controller.startMatch(firstMatch.id);
        controller.recordResult(firstMatch.id, MatchResult.draw);
        await flushState();

        expect(controller.state.currentMatchIndex, 1);
        expect(
          controller.state.standardSessionCompletedMatchesByPlayerId[firstMatch
              .player1
              .id],
          1,
        );
        expect(
          controller.state.standardSessionCompletedMatchesByPlayerId[firstMatch
              .player2
              .id],
          1,
        );
      },
    );

    test(
      'standard session does not auto-generate another queue when complete',
      () async {
        final started = controller.generateMatches(
          const <String>{'a', 'b'},
          PairingStrategy.random,
          targetMatchesPerPlayer: 1,
        );
        expect(started, isTrue);
        expect(controller.state.roundMatches.length, 1);

        final onlyMatch = controller.state.roundMatches.single;
        controller.startMatch(onlyMatch.id);
        controller.recordResult(onlyMatch.id, MatchResult.p1);
        await flushState();

        expect(controller.state.isStandardSessionComplete, isTrue);

        final beforeMatches = controller.state.roundMatches;
        controller.startNextRound();
        await flushState();

        expect(controller.state.roundMatches, beforeMatches);
        expect(controller.state.roundMatches.single.played, isTrue);
      },
    );

    test('resolves death match champion after elimination threshold', () async {
      final started = controller.startDeathMatch(
        const <String>{'a', 'b'},
        PairingStrategy.elo,
        2,
      );
      expect(started, isTrue);
      expect(controller.state.deathMatchInProgress, isTrue);

      final firstMatch = controller.state.roundMatches.single;
      controller.recordResult(firstMatch.id, MatchResult.p1);
      controller.startNextRound();
      await flushState();

      final secondMatch = controller.state.roundMatches.single;
      controller.recordResult(secondMatch.id, MatchResult.p1);
      controller.startNextRound();
      await flushState();

      expect(controller.state.deathMatchInProgress, isFalse);
      expect(controller.state.deathMatchChampionId, 'a');
      expect(controller.state.screen, Screen.deathMatchSelection);
      expect(repository.submittedResults.length, 2);
    });

    test('uses configured death match lives for elimination', () async {
      final started = controller.startDeathMatch(
        const <String>{'a', 'b'},
        PairingStrategy.elo,
        3,
      );
      expect(started, isTrue);
      expect(controller.state.deathMatchLives, 3);
      expect(controller.state.deathMatchInProgress, isTrue);

      for (var round = 1; round <= 2; round += 1) {
        final match = controller.state.roundMatches.single;
        controller.recordResult(
          match.id,
          match.player1.id == 'a' ? MatchResult.p1 : MatchResult.p2,
        );
        controller.startNextRound();
        await flushState();

        expect(controller.state.deathMatchInProgress, isTrue);
        expect(controller.state.deathMatchChampionId, isNull);
        expect(controller.state.deathMatchLossesByPlayerId['b'], round);
      }

      final finalMatch = controller.state.roundMatches.single;
      controller.recordResult(
        finalMatch.id,
        finalMatch.player1.id == 'a' ? MatchResult.p1 : MatchResult.p2,
      );
      controller.startNextRound();
      await flushState();

      expect(controller.state.deathMatchInProgress, isFalse);
      expect(controller.state.deathMatchChampionId, 'a');
      expect(controller.state.deathMatchLossesByPlayerId['b'], 3);
    });
  });
}

Future<void> flushState() async {
  await Future<void>.delayed(const Duration(milliseconds: 1));
}

class FakeSprintRepository implements SprintRepository {
  final StreamController<List<Player>> _playersController =
      StreamController<List<Player>>.broadcast();
  final StreamController<List<MatchHistoryEntry>> _historyController =
      StreamController<List<MatchHistoryEntry>>.broadcast();
  final StreamController<SyncState> _syncController =
      StreamController<SyncState>.broadcast();
  final StreamController<int> _kFactorController =
      StreamController<int>.broadcast();
  final StreamController<AppThemePreference> _themePreferenceController =
      StreamController<AppThemePreference>.broadcast();
  final StreamController<bool> _remoteSyncEnabledController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _useClientAudioController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _manualFullscreenEnabledController =
      StreamController<bool>.broadcast();

  final List<List<RoundResultInput>> submittedResults =
      <List<RoundResultInput>>[];
  int submitRoundResultsCalls = 0;
  int deleteMatchCalls = 0;
  int setKFactorCalls = 0;
  int setThemePreferenceCalls = 0;
  int setRemoteSyncEnabledCalls = 0;
  int setUseClientAudioCalls = 0;
  int setManualFullscreenEnabledCalls = 0;
  int resetLocalDataCalls = 0;
  int resetCloudDataCalls = 0;
  int seedCloudDataCalls = 0;

  Object? submitRoundResultsError;
  Object? deleteMatchError;
  Object? setKFactorError;
  Object? setThemePreferenceError;
  AppThemePreference? lastSetThemePreference;
  bool? lastRemoteSyncEnabled;
  bool? lastUseClientAudioEnabled;
  bool? lastManualFullscreenEnabled;

  @override
  Stream<List<Player>> get players => _playersController.stream;

  @override
  Stream<List<MatchHistoryEntry>> get history => _historyController.stream;

  @override
  Stream<SyncState> get syncState => _syncController.stream;

  @override
  Stream<int> get kFactor => _kFactorController.stream;

  @override
  Stream<AppThemePreference> get themePreference =>
      _themePreferenceController.stream;

  @override
  Stream<bool> get remoteSyncEnabled => _remoteSyncEnabledController.stream;

  @override
  Stream<bool> get useClientAudio => _useClientAudioController.stream;

  @override
  Stream<bool> get manualFullscreenEnabled =>
      _manualFullscreenEnabledController.stream;

  void emitPlayers(List<Player> value) => _playersController.add(value);

  void emitHistory(List<MatchHistoryEntry> value) =>
      _historyController.add(value);

  void emitSync(SyncState value) => _syncController.add(value);

  void emitKFactor(int value) => _kFactorController.add(value);

  void emitThemePreference(AppThemePreference value) =>
      _themePreferenceController.add(value);

  void emitRemoteSyncEnabled(bool value) =>
      _remoteSyncEnabledController.add(value);

  void emitUseClientAudio(bool value) => _useClientAudioController.add(value);

  void emitManualFullscreenEnabled(bool value) =>
      _manualFullscreenEnabledController.add(value);

  @override
  Future<void> submitRoundResults(List<RoundResultInput> results) async {
    submitRoundResultsCalls += 1;
    if (submitRoundResultsError != null) {
      return Future<void>.error(submitRoundResultsError!);
    }
    submittedResults.add(List<RoundResultInput>.from(results));
  }

  @override
  Future<void> deleteMatch(String matchId) async {
    deleteMatchCalls += 1;
    if (deleteMatchError != null) {
      return Future<void>.error(deleteMatchError!);
    }
  }

  @override
  Future<void> resetAllData() async {}

  @override
  Future<void> resetLocalData() async {
    resetLocalDataCalls += 1;
  }

  @override
  Future<void> resetCloudData() async {
    resetCloudDataCalls += 1;
  }

  @override
  Future<void> seedCloudData() async {
    seedCloudDataCalls += 1;
  }

  @override
  Future<void> setKFactor(int kFactor) async {
    setKFactorCalls += 1;
    if (setKFactorError != null) {
      return Future<void>.error(setKFactorError!);
    }
  }

  @override
  Future<void> setThemePreference(AppThemePreference preference) async {
    setThemePreferenceCalls += 1;
    if (setThemePreferenceError != null) {
      return Future<void>.error(setThemePreferenceError!);
    }
    lastSetThemePreference = preference;
  }

  @override
  Future<void> setRemoteSyncEnabled(bool enabled) async {
    setRemoteSyncEnabledCalls += 1;
    lastRemoteSyncEnabled = enabled;
    _remoteSyncEnabledController.add(enabled);
  }

  @override
  Future<void> setUseClientAudio(bool enabled) async {
    setUseClientAudioCalls += 1;
    lastUseClientAudioEnabled = enabled;
    _useClientAudioController.add(enabled);
  }

  @override
  Future<void> setManualFullscreenEnabled(bool enabled) async {
    setManualFullscreenEnabledCalls += 1;
    lastManualFullscreenEnabled = enabled;
    _manualFullscreenEnabledController.add(enabled);
  }

  @override
  void dispose() {
    _playersController.close();
    _historyController.close();
    _syncController.close();
    _kFactorController.close();
    _themePreferenceController.close();
    _remoteSyncEnabledController.close();
    _useClientAudioController.close();
    _manualFullscreenEnabledController.close();
  }
}

class FakeSprintPlatform implements SprintPlatformAdapter {
  final StreamController<LocalSessionState> _localSessionController =
      StreamController<LocalSessionState>.broadcast();
  final StreamController<LocalLeaderboardSnapshot> _localSnapshotController =
      StreamController<LocalLeaderboardSnapshot>.broadcast();
  final StreamController<LocalControlEvent> _localControlEventController =
      StreamController<LocalControlEvent>.broadcast();
  final StreamController<String> _errorsController =
      StreamController<String>.broadcast();

  int useDbForLocalCalls = 0;
  int startLocalHostingCalls = 0;
  int scanLocalHostsCalls = 0;
  int sendStartMatchBeepControlCalls = 0;
  final List<bool> immersiveShowStatusBarCalls = <bool>[];
  Object? startLocalHostingError;
  Object? scanLocalHostsError;
  Object? useDbForLocalError;

  @override
  Stream<LocalSessionState> get localSessionState =>
      _localSessionController.stream;

  @override
  Stream<LocalLeaderboardSnapshot> get localSnapshot =>
      _localSnapshotController.stream;

  @override
  Stream<LocalControlEvent> get localControlEvents =>
      _localControlEventController.stream;

  @override
  Stream<String> get errors => _errorsController.stream;

  void emitLocalSession(LocalSessionState state) =>
      _localSessionController.add(state);

  void emitLocalSnapshot(LocalLeaderboardSnapshot snapshot) =>
      _localSnapshotController.add(snapshot);

  void emitError(String message) => _errorsController.add(message);

  void emitControl(LocalControlEvent event) =>
      _localControlEventController.add(event);

  @override
  Future<void> startLocalHosting(String localEndpointName) async {
    startLocalHostingCalls += 1;
    if (startLocalHostingError != null) {
      return Future<void>.error(startLocalHostingError!);
    }
  }

  @override
  Future<void> stopLocalHosting() async {}

  @override
  Future<void> scanLocalHosts(String localEndpointName) async {
    scanLocalHostsCalls += 1;
    if (scanLocalHostsError != null) {
      return Future<void>.error(scanLocalHostsError!);
    }
  }

  @override
  Future<void> connectToLocalHost(String endpointId) async {}

  @override
  Future<void> acceptLocalConnection() async {}

  @override
  Future<void> rejectLocalConnection() async {}

  @override
  Future<void> disconnectLocalConnection() async {}

  @override
  Future<void> useDatabaseModeForLocal() async {
    useDbForLocalCalls += 1;
    if (useDbForLocalError != null) {
      return Future<void>.error(useDbForLocalError!);
    }
  }

  @override
  Future<void> publishLocalHostedSnapshot(
    LocalLeaderboardSnapshot snapshot,
  ) async {}

  @override
  Future<void> sendStartMatchBeepControl() async {
    sendStartMatchBeepControlCalls += 1;
  }

  @override
  Future<void> setImmersiveMode({bool showStatusBar = true}) async {
    immersiveShowStatusBarCalls.add(showStatusBar);
  }

  @override
  void dispose() {
    _localSessionController.close();
    _localSnapshotController.close();
    _localControlEventController.close();
    _errorsController.close();
  }
}
