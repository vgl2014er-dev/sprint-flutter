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

    test(
      'keeps snapshot while disconnected and falls back to db in db mode',
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
        expect(controller.state.players, remotePlayers);

        controller.useDatabaseLeaderboard();
        await flushState();
        expect(controller.state.leaderboardSource, LeaderboardSource.db);
        expect(controller.state.players.first.id, 'a');
        expect(platform.useDbForLocalCalls, greaterThanOrEqualTo(1));
        expect(platform.useDbForDirectCalls, greaterThanOrEqualTo(1));
      },
    );

    test('resolves death match champion after elimination threshold', () async {
      final started = controller.startDeathMatch(const <String>{
        'a',
        'b',
      }, PairingStrategy.elo);
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

  final List<List<RoundResultInput>> submittedResults =
      <List<RoundResultInput>>[];

  @override
  Stream<List<Player>> get players => _playersController.stream;

  @override
  Stream<List<MatchHistoryEntry>> get history => _historyController.stream;

  @override
  Stream<SyncState> get syncState => _syncController.stream;

  @override
  Stream<int> get kFactor => _kFactorController.stream;

  void emitPlayers(List<Player> value) => _playersController.add(value);

  void emitHistory(List<MatchHistoryEntry> value) =>
      _historyController.add(value);

  void emitSync(SyncState value) => _syncController.add(value);

  void emitKFactor(int value) => _kFactorController.add(value);

  @override
  Future<void> submitRoundResults(List<RoundResultInput> results) async {
    submittedResults.add(List<RoundResultInput>.from(results));
  }

  @override
  Future<void> deleteMatch(String matchId) async {}

  @override
  Future<void> resetAllData() async {}

  @override
  Future<void> setKFactor(int kFactor) async {}

  @override
  void dispose() {
    _playersController.close();
    _historyController.close();
    _syncController.close();
    _kFactorController.close();
  }
}

class FakeSprintPlatform implements SprintPlatformAdapter {
  final StreamController<LocalSessionState> _localSessionController =
      StreamController<LocalSessionState>.broadcast();
  final StreamController<LocalLeaderboardSnapshot> _localSnapshotController =
      StreamController<LocalLeaderboardSnapshot>.broadcast();
  final StreamController<DirectSessionState> _directSessionController =
      StreamController<DirectSessionState>.broadcast();
  final StreamController<LocalLeaderboardSnapshot> _directSnapshotController =
      StreamController<LocalLeaderboardSnapshot>.broadcast();
  final StreamController<SpeakerStartupState> _speakerController =
      StreamController<SpeakerStartupState>.broadcast();
  final StreamController<String> _errorsController =
      StreamController<String>.broadcast();

  int useDbForLocalCalls = 0;
  int useDbForDirectCalls = 0;

  @override
  Stream<LocalSessionState> get localSessionState =>
      _localSessionController.stream;

  @override
  Stream<LocalLeaderboardSnapshot> get localSnapshot =>
      _localSnapshotController.stream;

  @override
  Stream<DirectSessionState> get directSessionState =>
      _directSessionController.stream;

  @override
  Stream<LocalLeaderboardSnapshot> get directSnapshot =>
      _directSnapshotController.stream;

  @override
  Stream<SpeakerStartupState> get speakerStartupState =>
      _speakerController.stream;

  @override
  Stream<String> get errors => _errorsController.stream;

  void emitLocalSession(LocalSessionState state) =>
      _localSessionController.add(state);

  void emitLocalSnapshot(LocalLeaderboardSnapshot snapshot) =>
      _localSnapshotController.add(snapshot);

  @override
  Future<void> startLocalHosting(String localEndpointName) async {}

  @override
  Future<void> stopLocalHosting() async {}

  @override
  Future<void> scanLocalHosts(String localEndpointName) async {}

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
  }

  @override
  Future<void> connectDirectTransport(String localEndpointName) async {}

  @override
  Future<void> startDirectHosting(String localEndpointName) async {}

  @override
  Future<void> stopDirectHosting() async {}

  @override
  Future<void> disconnectDirectTransport() async {}

  @override
  Future<void> useDatabaseModeForDirect() async {
    useDbForDirectCalls += 1;
  }

  @override
  Future<void> publishLocalHostedSnapshot(
    LocalLeaderboardSnapshot snapshot,
  ) async {}

  @override
  Future<void> publishDirectHostedSnapshot(
    LocalLeaderboardSnapshot snapshot,
  ) async {}

  @override
  Future<void> refreshSpeakerStartupState() async {}

  @override
  Future<void> requestSpeakerPermission() async {}

  @override
  Future<void> openBluetoothSettings() async {}

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> setImmersiveMode() async {}

  @override
  void dispose() {
    _localSessionController.close();
    _localSnapshotController.close();
    _directSessionController.close();
    _directSnapshotController.close();
    _speakerController.close();
    _errorsController.close();
  }
}
