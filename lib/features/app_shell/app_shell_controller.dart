import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_logger.dart';
import '../../data/local/app_database.dart' as db;
import '../../core/repositories/sprint_repository.dart';
import '../../core/repositories/sprint_repository_impl.dart';
import '../../core/logic/defaults.dart';
import '../../core/logic/pairing_engine.dart';
import '../../core/models/app_models.dart';
import '../../platform/platform_channels.dart';

final sprintRepositoryProvider = Provider<SprintRepository>((ref) {
  final repository = SprintRepositoryImpl(database: db.AppDatabase());
  ref.onDispose(repository.dispose);
  return repository;
});

final platformChannelsProvider = Provider<SprintPlatformAdapter>((ref) {
  final platformChannels = SprintPlatformChannels();
  ref.onDispose(platformChannels.dispose);
  return platformChannels;
});

final sprintControllerProvider =
    StateNotifierProvider<SprintController, AppState>((ref) {
      final controller = SprintController(
        repository: ref.watch(sprintRepositoryProvider),
        platformChannels: ref.watch(platformChannelsProvider),
      );
      return controller;
    });

class SprintController extends StateNotifier<AppState> {
  SprintController({
    required SprintRepository repository,
    required SprintPlatformAdapter platformChannels,
  }) : _repository = repository,
       _platformChannels = platformChannels,
       super(AppState.initial()) {
    _subscriptions.addAll(<StreamSubscription<dynamic>>[
      _repository.players.listen((value) {
        _dbPlayers = value;
        _refreshProjectedData();
      }),
      _repository.history.listen((value) {
        _dbHistory = value;
        _refreshProjectedData();
      }),
      _repository.syncState.listen((value) {
        _dbSyncState = value;
        _refreshProjectedData();
      }),
      _repository.kFactor.listen((value) {
        _dbKFactor = value;
        _refreshProjectedData();
      }),
      _repository.themePreference.listen((value) {
        _dbThemePreference = value;
        _refreshProjectedData();
      }),
      _repository.remoteSyncEnabled.listen((value) {
        _dbRemoteSyncEnabled = value;
        _refreshProjectedData();
      }),
      _repository.useClientAudio.listen((value) {
        _dbUseClientAudio = value;
        _refreshProjectedData();
      }),
      _repository.manualFullscreenEnabled.listen((value) {
        _dbManualFullscreenEnabled = value;
        _refreshProjectedData();
      }),
      _platformChannels.localSessionState.listen(_onLocalSessionState),
      _platformChannels.localSnapshot.listen((value) {
        _localSnapshot = value;
        _refreshProjectedData();
      }),
      _platformChannels.errors.listen(_onPlatformError),
    ]);

    _syncImmersiveModeForState(state);
  }

  final SprintRepository _repository;
  final SprintPlatformAdapter _platformChannels;

  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  List<Player> _dbPlayers = <Player>[];
  List<MatchHistoryEntry> _dbHistory = <MatchHistoryEntry>[];
  SyncState _dbSyncState = const SyncState();
  int _dbKFactor = Defaults.eloK;
  AppThemePreference _dbThemePreference = AppThemePreference.light;
  bool _dbRemoteSyncEnabled = true;
  bool _dbUseClientAudio = false;
  bool _dbManualFullscreenEnabled = false;
  bool _autoSuspendedRemoteSync = false;

  LocalLeaderboardSnapshot? _localSnapshot;
  PairingStrategy _currentPairingStrategy = PairingStrategy.random;
  bool? _immersiveShowStatusBar;

  void navigateTo(Screen screen) {
    if (screen == Screen.settings) {
      openSettingsModal();
      return;
    }
    if (_isClientLockedToLeaderboard() && screen != Screen.leaderboard) {
      return;
    }
    state = state.copyWith(screen: screen, isSettingsOpen: false);
  }

  void openSettingsModal() {
    if (_isClientLockedToLeaderboard()) {
      return;
    }
    state = state.copyWith(isSettingsOpen: true);
  }

  void closeSettingsModal() {
    if (!state.isSettingsOpen) {
      return;
    }
    state = state.copyWith(isSettingsOpen: false);
  }

  void toggleRemoteSync(bool enabled) {
    if (state.localSessionState.phase == LocalSessionPhase.connected) {
      _autoSuspendedRemoteSync = false;
    }
    state = state.copyWith(remoteSyncEnabled: enabled);
    _runRepositoryWrite(
      () => _repository.setRemoteSyncEnabled(enabled),
      action: 'setRemoteSyncEnabled',
    );
  }

  void toggleClientAudio(bool enabled) {
    state = state.copyWith(useClientAudio: enabled);
    _runRepositoryWrite(
      () => _repository.setUseClientAudio(enabled),
      action: 'setUseClientAudio',
    );
  }

  void toggleFullscreen(bool enabled) {
    state = state.copyWith(manualFullscreenEnabled: enabled);
    _syncImmersiveModeForState(state);
    _runRepositoryWrite(
      () => _repository.setManualFullscreenEnabled(enabled),
      action: 'setManualFullscreenEnabled',
    );
  }

  void resetLocalData() {
    _runRepositoryWrite(_repository.resetLocalData, action: 'resetLocalData');
  }

  void resetCloudData() {
    if (!state.remoteSyncEnabled) {
      return;
    }
    _runRepositoryWrite(_repository.resetCloudData, action: 'resetCloudData');
  }

  void seedCloudData() {
    if (!state.remoteSyncEnabled) {
      return;
    }
    _runRepositoryWrite(_repository.seedCloudData, action: 'seedCloudData');
  }

  bool handleBackAction() {
    if (state.isSettingsOpen) {
      closeSettingsModal();
      return false;
    }
    if (state.manualFullscreenEnabled) {
      toggleFullscreen(false);
      return false;
    }

    switch (state.screen) {
      case Screen.landing:
        return true;
      case Screen.leaderboard:
      case Screen.playerList:
      case Screen.settings:
      case Screen.randomPlayerSelection:
      case Screen.eloPlayerSelection:
        navigateTo(Screen.landing);
        return false;
      case Screen.matchRunner:
        navigateTo(_playerSelectionBackTarget());
        return false;
      case Screen.playerProfile:
        navigateTo(Screen.playerList);
        return false;
    }
  }

  bool generateMatches(
    Set<String> selectedIds,
    PairingStrategy strategy, {
    int targetMatchesPerPlayer = _defaultStandardSessionTargetMatches,
  }) {
    _currentPairingStrategy = strategy;
    return _generateMatchesForStandardSession(
      selectedIds: selectedIds,
      strategy: strategy,
      targetMatchesPerPlayer: targetMatchesPerPlayer,
    );
  }

  void startMatch(String matchId) {
    final matches = state.roundMatches
        .map((match) {
          if (match.id != matchId) {
            return match;
          }
          return match.copyWith(started: true);
        })
        .toList(growable: false);

    state = state.copyWith(roundMatches: matches);

    final shouldSendClientBeep =
        state.useClientAudio &&
        state.localSessionState.role == LocalSessionRole.host &&
        state.localSessionState.phase == LocalSessionPhase.connected;
    if (shouldSendClientBeep) {
      _runPlatformCommand(
        _platformChannels.sendStartMatchBeepControl,
        action: 'sendStartMatchBeepControl',
      );
    }
  }

  void recordResult(String matchId, MatchResult result) {
    var shouldSubmit = false;
    UiRoundMatch? submittedMatch;

    final updatedMatches = state.roundMatches
        .map((match) {
          if (match.id != matchId) {
            return match;
          }
          final updated = switch (result) {
            MatchResult.p1 => match.copyWith(
              played: true,
              winnerId: match.player1.id,
              isDraw: false,
            ),
            MatchResult.p2 => match.copyWith(
              played: true,
              winnerId: match.player2.id,
              isDraw: false,
            ),
            MatchResult.draw => match.copyWith(
              played: true,
              winnerIdToNull: true,
              isDraw: true,
            ),
          };

          shouldSubmit = !match.played;
          submittedMatch = updated;
          return updated;
        })
        .toList(growable: false);

    var nextMatchIndex = state.currentMatchIndex;
    if (nextMatchIndex < updatedMatches.length - 1) {
      nextMatchIndex += 1;
    }

    var completedByPlayerId = state.standardSessionCompletedMatchesByPlayerId;
    if (state.isStandardSession && shouldSubmit && submittedMatch != null) {
      completedByPlayerId = Map<String, int>.from(completedByPlayerId);
      final p1Id = submittedMatch!.player1.id;
      final p2Id = submittedMatch!.player2.id;
      completedByPlayerId[p1Id] = (completedByPlayerId[p1Id] ?? 0) + 1;
      completedByPlayerId[p2Id] = (completedByPlayerId[p2Id] ?? 0) + 1;
    }

    state = state.copyWith(
      roundMatches: updatedMatches,
      currentMatchIndex: nextMatchIndex,
      standardSessionCompletedMatchesByPlayerId: completedByPlayerId,
    );

    if (!shouldSubmit || submittedMatch == null) {
      return;
    }

    _runRepositoryWrite(
      () => _repository.submitRoundResults(<RoundResultInput>[
        RoundResultInput(
          p1Id: submittedMatch!.player1.id,
          p2Id: submittedMatch!.player2.id,
          result: result,
        ),
      ]),
      action: 'submitRoundResults',
    );
  }

  void finishRound(Screen nextScreen) {
    state = state.copyWith(screen: nextScreen);
  }

  void startNextRound() {
    if (state.isStandardSession) {
      return;
    }

    final previousLastPairIds = state.roundMatches.isEmpty
        ? <String>{}
        : <String>{
            state.roundMatches.last.player1.id,
            state.roundMatches.last.player2.id,
          };

    final participantIds = state.roundMatches
        .expand((match) => <String>[match.player1.id, match.player2.id])
        .toSet();
    if (participantIds.length < 2) {
      closeRoundToLanding();
      return;
    }

    _generateMatchesForRound(
      selectedIds: participantIds,
      avoidFirstMatchPlayerIds: previousLastPairIds,
      strategy: _currentPairingStrategy,
    );
  }

  void closeRoundToLanding() {
    _currentPairingStrategy = PairingStrategy.random;
    state = state.copyWith(
      roundMatches: const <UiRoundMatch>[],
      currentMatchIndex: 0,
      screen: Screen.landing,
      clearStandardSessionStrategy: true,
      standardSessionParticipantIds: const <String>[],
      standardSessionTargetMatchesPerPlayer:
          _defaultStandardSessionTargetMatches,
      standardSessionCompletedMatchesByPlayerId: const <String, int>{},
      standardSessionScheduledMatchesByPlayerId: const <String, int>{},
    );
  }

  void resetData() {
    resetLocalData();
  }

  void setKFactor(int kFactor) {
    _runRepositoryWrite(
      () => _repository.setKFactor(kFactor),
      action: 'setKFactor',
    );
  }

  void toggleThemePreference() {
    final next = switch (state.themePreference) {
      AppThemePreference.light => AppThemePreference.dark,
      AppThemePreference.dark => AppThemePreference.light,
    };
    _runRepositoryWrite(
      () => _repository.setThemePreference(next),
      action: 'setThemePreference',
    );
  }

  void deleteMatch(String matchId) {
    _runRepositoryWrite(
      () => _repository.deleteMatch(matchId),
      action: 'deleteMatch',
    );
  }

  void openProfile(String playerId, Screen from) {
    if (_isClientLockedToLeaderboard()) {
      return;
    }

    state = state.copyWith(
      selectedPlayerId: playerId,
      profileBackScreen: from,
      screen: Screen.playerProfile,
    );
  }

  void backFromProfile() {
    state = state.copyWith(screen: state.profileBackScreen);
  }

  void startLocalHosting(String localEndpointName) {
    state = state.copyWith(
      leaderboardSource: LeaderboardSource.db,
      isSettingsOpen: false,
    );
    _runPlatformCommand(
      _platformChannels.useDatabaseModeForLocal,
      action: 'useDatabaseModeForLocal',
    );
    _runPlatformCommand(
      () => _platformChannels.startLocalHosting(localEndpointName),
      action: 'startLocalHosting',
    );
  }

  void stopLocalHosting() {
    _runPlatformCommand(
      _platformChannels.stopLocalHosting,
      action: 'stopLocalHosting',
    );
  }

  void scanLocalHosts(String localEndpointName) {
    _runPlatformCommand(
      () => _platformChannels.scanLocalHosts(localEndpointName),
      action: 'scanLocalHosts',
    );
  }

  void connectToLocalHost(String endpointId) {
    _runPlatformCommand(
      () => _platformChannels.connectToLocalHost(endpointId),
      action: 'connectToLocalHost',
    );
  }

  void acceptLocalConnection() {
    _runPlatformCommand(
      _platformChannels.acceptLocalConnection,
      action: 'acceptLocalConnection',
    );
  }

  void rejectLocalConnection() {
    _runPlatformCommand(
      _platformChannels.rejectLocalConnection,
      action: 'rejectLocalConnection',
    );
  }

  void disconnectLocalConnection() {
    _runPlatformCommand(
      _platformChannels.disconnectLocalConnection,
      action: 'disconnectLocalConnection',
    );
  }

  void useDatabaseLeaderboard() {
    state = state.copyWith(
      leaderboardSource: LeaderboardSource.db,
      isSettingsOpen: false,
    );
    _syncImmersiveModeForState(state);
    _runPlatformCommand(
      _platformChannels.useDatabaseModeForLocal,
      action: 'useDatabaseModeForLocal',
    );
    _refreshProjectedData();
  }

  Screen _playerSelectionBackTarget() {
    return switch (state.standardSessionStrategy) {
      PairingStrategy.elo => Screen.eloPlayerSelection,
      PairingStrategy.random => Screen.randomPlayerSelection,
      null => Screen.landing,
    };
  }

  bool _generateMatchesForStandardSession({
    required Set<String> selectedIds,
    required PairingStrategy strategy,
    required int targetMatchesPerPlayer,
  }) {
    final selectedPlayers = state.players
        .where((player) => selectedIds.contains(player.id))
        .toList(growable: false);
    if (selectedPlayers.length < 2) {
      return false;
    }

    final resolvedTarget = targetMatchesPerPlayer.clamp(
      _minStandardSessionTargetMatches,
      _maxStandardSessionTargetMatches,
    );
    final participants = List<Player>.from(selectedPlayers)
      ..sort((left, right) {
        final byName = left.name.compareTo(right.name);
        if (byName != 0) {
          return byName;
        }
        return left.id.compareTo(right.id);
      });
    final participantIds = participants
        .map((player) => player.id)
        .toList(growable: false);
    final playersById = {for (final player in participants) player.id: player};
    final scheduledCounts = <String, int>{
      for (final id in participantIds) id: 0,
    };
    final recentOpponentByPlayerId = _buildRecentOpponentByPlayerId(
      participantIds.toSet(),
    );

    final queue = <RoundPair>[];
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    final maxIterations = participantIds.length * resolvedTarget * 12;
    var iterations = 0;

    bool allScheduledToTarget() => participantIds.every(
      (id) => (scheduledCounts[id] ?? 0) >= resolvedTarget,
    );

    while (!allScheduledToTarget()) {
      iterations += 1;
      if (iterations > maxIterations) {
        return false;
      }

      final belowTargetIds = participantIds
          .where((id) => (scheduledCounts[id] ?? 0) < resolvedTarget)
          .toList(growable: false);

      if (belowTargetIds.length >= 2) {
        final batchPlayers = belowTargetIds
            .map((id) => playersById[id])
            .whereType<Player>()
            .toList(growable: false);
        final generatedPairs = PairingEngine.generate(
          batchPlayers,
          strategy: strategy,
          random: random,
          recentOpponentByPlayerId: <String, String>{
            for (final id in belowTargetIds) id: ?recentOpponentByPlayerId[id],
          },
          eloBlockByPlayerId: _buildEloBlockByPlayerId(batchPlayers),
        );
        if (generatedPairs.isEmpty) {
          return false;
        }

        for (final pair in generatedPairs) {
          queue.add(pair);
          scheduledCounts[pair.player1.id] =
              (scheduledCounts[pair.player1.id] ?? 0) + 1;
          scheduledCounts[pair.player2.id] =
              (scheduledCounts[pair.player2.id] ?? 0) + 1;
          recentOpponentByPlayerId[pair.player1.id] = pair.player2.id;
          recentOpponentByPlayerId[pair.player2.id] = pair.player1.id;
        }
        continue;
      }

      if (belowTargetIds.length == 1) {
        final underTargetPlayerId = belowTargetIds.single;
        final opponentId = _chooseStandardFallbackOpponentId(
          underTargetPlayerId: underTargetPlayerId,
          participantIds: participantIds,
          playersById: playersById,
          scheduledCounts: scheduledCounts,
          queue: queue,
        );
        if (opponentId == null) {
          return false;
        }

        final underTargetPlayer = playersById[underTargetPlayerId];
        final opponent = playersById[opponentId];
        if (underTargetPlayer == null || opponent == null) {
          return false;
        }

        queue.add(RoundPair(player1: underTargetPlayer, player2: opponent));
        scheduledCounts[underTargetPlayerId] =
            (scheduledCounts[underTargetPlayerId] ?? 0) + 1;
        scheduledCounts[opponentId] = (scheduledCounts[opponentId] ?? 0) + 1;
        recentOpponentByPlayerId[underTargetPlayerId] = opponentId;
        recentOpponentByPlayerId[opponentId] = underTargetPlayerId;
        continue;
      }
    }

    if (queue.isEmpty || !allScheduledToTarget()) {
      return false;
    }

    final matches = _toUiRoundMatches(queue, idPrefix: 'standard');
    state = state.copyWith(
      roundMatches: matches,
      currentMatchIndex: 0,
      screen: Screen.matchRunner,
      standardSessionStrategy: strategy,
      standardSessionParticipantIds: participantIds,
      standardSessionTargetMatchesPerPlayer: resolvedTarget,
      standardSessionCompletedMatchesByPlayerId: {
        for (final id in participantIds) id: 0,
      },
      standardSessionScheduledMatchesByPlayerId: scheduledCounts,
    );
    return true;
  }

  String? _chooseStandardFallbackOpponentId({
    required String underTargetPlayerId,
    required List<String> participantIds,
    required Map<String, Player> playersById,
    required Map<String, int> scheduledCounts,
    required List<RoundPair> queue,
  }) {
    final immediateLastOpponentId = _lastOpponentForPlayer(
      underTargetPlayerId,
      queue,
    );
    final candidates = participantIds
        .where((id) => id != underTargetPlayerId)
        .toList(growable: false);
    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((left, right) {
      final leftScheduled = scheduledCounts[left] ?? 0;
      final rightScheduled = scheduledCounts[right] ?? 0;
      final byScheduled = leftScheduled.compareTo(rightScheduled);
      if (byScheduled != 0) {
        return byScheduled;
      }

      final leftIsLast = left == immediateLastOpponentId ? 1 : 0;
      final rightIsLast = right == immediateLastOpponentId ? 1 : 0;
      final byImmediateRepeat = leftIsLast.compareTo(rightIsLast);
      if (byImmediateRepeat != 0) {
        return byImmediateRepeat;
      }

      final leftPlayer = playersById[left];
      final rightPlayer = playersById[right];
      final byName = (leftPlayer?.name ?? left).compareTo(
        rightPlayer?.name ?? right,
      );
      if (byName != 0) {
        return byName;
      }
      return left.compareTo(right);
    });

    return candidates.first;
  }

  String? _lastOpponentForPlayer(String playerId, List<RoundPair> queue) {
    for (var index = queue.length - 1; index >= 0; index -= 1) {
      final pair = queue[index];
      if (pair.player1.id == playerId) {
        return pair.player2.id;
      }
      if (pair.player2.id == playerId) {
        return pair.player1.id;
      }
    }
    return null;
  }

  Map<String, String> _buildRecentOpponentByPlayerId(Set<String> selectedIds) {
    if (selectedIds.isEmpty) {
      return const <String, String>{};
    }

    final recentOpponentByPlayerId = <String, String>{};
    final sortedHistory = List<MatchHistoryEntry>.from(state.history)
      ..sort((left, right) => right.timestamp.compareTo(left.timestamp));
    for (final entry in sortedHistory) {
      if (!selectedIds.contains(entry.p1Id) ||
          !selectedIds.contains(entry.p2Id)) {
        continue;
      }
      recentOpponentByPlayerId.putIfAbsent(entry.p1Id, () => entry.p2Id);
      recentOpponentByPlayerId.putIfAbsent(entry.p2Id, () => entry.p1Id);
      if (recentOpponentByPlayerId.length >= selectedIds.length) {
        break;
      }
    }
    return recentOpponentByPlayerId;
  }

  Map<String, int> _buildEloBlockByPlayerId(List<Player> selectedPlayers) {
    if (selectedPlayers.isEmpty) {
      return const <String, int>{};
    }

    final sorted = List<Player>.from(selectedPlayers)
      ..sort((left, right) {
        final byElo = right.elo.compareTo(left.elo);
        if (byElo != 0) {
          return byElo;
        }
        final byName = left.name.compareTo(right.name);
        if (byName != 0) {
          return byName;
        }
        return left.id.compareTo(right.id);
      });

    final total = sorted.length;
    final baseSize = total ~/ 3;
    final remainder = total % 3;
    final blockSizes = <int>[
      baseSize + (remainder > 0 ? 1 : 0),
      baseSize + (remainder > 1 ? 1 : 0),
      baseSize,
    ];

    final blockByPlayerId = <String, int>{};
    var index = 0;
    for (var block = 0; block < blockSizes.length; block += 1) {
      final blockSize = blockSizes[block];
      for (
        var count = 0;
        count < blockSize && index < sorted.length;
        count += 1
      ) {
        blockByPlayerId[sorted[index].id] = block;
        index += 1;
      }
    }
    return blockByPlayerId;
  }

  List<UiRoundMatch> _toUiRoundMatches(
    List<RoundPair> pairs, {
    String? idPrefix,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return pairs
        .asMap()
        .entries
        .map(
          (entry) => UiRoundMatch(
            id: idPrefix == null
                ? '$now-${entry.key}'
                : '$idPrefix-$now-${entry.key}',
            player1: entry.value.player1,
            player2: entry.value.player2,
          ),
        )
        .toList(growable: false);
  }

  bool _generateMatchesForRound({
    required Set<String> selectedIds,
    required Set<String> avoidFirstMatchPlayerIds,
    required PairingStrategy strategy,
  }) {
    final selectedPlayers = state.players
        .where((player) => selectedIds.contains(player.id))
        .toList(growable: false);

    if (selectedPlayers.length < 2) {
      return false;
    }

    final random = Random(DateTime.now().millisecondsSinceEpoch);
    final pairs = PairingEngine.generate(
      selectedPlayers,
      strategy: strategy,
      random: random,
      recentOpponentByPlayerId: _buildRecentOpponentByPlayerId(selectedIds),
      eloBlockByPlayerId: _buildEloBlockByPlayerId(selectedPlayers),
    );
    final generatedMatches = _toUiRoundMatches(pairs);

    final reordered = reorderRoundMatchesToAvoidFirstMatchPlayers(
      generatedMatches,
      excludedPlayerIds: avoidFirstMatchPlayerIds,
    );

    state = state.copyWith(
      roundMatches: reordered,
      currentMatchIndex: 0,
      screen: Screen.matchRunner,
      clearStandardSessionStrategy: true,
      standardSessionParticipantIds: const <String>[],
      standardSessionTargetMatchesPerPlayer:
          _defaultStandardSessionTargetMatches,
      standardSessionCompletedMatchesByPlayerId: const <String, int>{},
      standardSessionScheduledMatchesByPlayerId: const <String, int>{},
    );

    return true;
  }

  void _onLocalSessionState(LocalSessionState sessionState) {
    final previousSessionState = state.localSessionState;
    _applyConnectedSessionRemoteSyncPolicy(
      previous: previousSessionState,
      current: sessionState,
    );

    var nextState = state.copyWith(localSessionState: sessionState);

    if (sessionState.role == LocalSessionRole.client &&
        sessionState.phase == LocalSessionPhase.connected) {
      nextState = nextState.copyWith(
        screen: Screen.leaderboard,
        leaderboardSource: LeaderboardSource.local,
        isSettingsOpen: false,
        clearSelectedPlayerId: true,
      );
    }

    if (sessionState.role == LocalSessionRole.client &&
        sessionState.phase == LocalSessionPhase.disconnected) {
      nextState = nextState.copyWith(
        screen: Screen.landing,
        leaderboardSource: LeaderboardSource.db,
        isSettingsOpen: false,
        clearSelectedPlayerId: true,
      );
    }

    state = nextState;
    _syncImmersiveModeForState(state);
    _refreshProjectedData();
  }

  void _applyConnectedSessionRemoteSyncPolicy({
    required LocalSessionState previous,
    required LocalSessionState current,
  }) {
    final wasConnected = previous.phase == LocalSessionPhase.connected;
    final isConnected = current.phase == LocalSessionPhase.connected;

    if (!wasConnected && isConnected) {
      if (state.remoteSyncEnabled) {
        _autoSuspendedRemoteSync = true;
        toggleRemoteSync(false);
      }
      return;
    }

    if (wasConnected && !isConnected && _autoSuspendedRemoteSync) {
      _autoSuspendedRemoteSync = false;
      if (!state.remoteSyncEnabled) {
        toggleRemoteSync(true);
      }
    }
  }

  void _onPlatformError(String message) {
    AppLogger.warning(
      'Platform channel reported an error event.',
      name: 'sprint.controller',
      error: message,
    );
    state = state.copyWith(
      localSessionState: state.localSessionState.copyWith(
        phase: LocalSessionPhase.error,
        errorMessage: message,
      ),
    );
    _syncImmersiveModeForState(state);
  }

  void _refreshProjectedData() {
    final source = state.leaderboardSource;

    final projectedPlayers = switch (source) {
      LeaderboardSource.local when _localSnapshot != null =>
        _localSnapshot!.players,
      _ => _dbPlayers,
    };

    final projectedSync = switch (source) {
      LeaderboardSource.local when _localSnapshot != null => SyncState(
        lastSyncedEpochMillis: _localSnapshot!.lastSyncedEpochMillis,
      ),
      _ => _dbSyncState,
    };

    final projectedKFactor = switch (source) {
      LeaderboardSource.local when _localSnapshot != null =>
        _localSnapshot!.kFactor,
      _ => _dbKFactor,
    };

    state = state.copyWith(
      players: projectedPlayers,
      history: _dbHistory,
      syncState: projectedSync,
      kFactor: projectedKFactor,
      themePreference: _dbThemePreference,
      remoteSyncEnabled: _dbRemoteSyncEnabled,
      useClientAudio: _dbUseClientAudio,
      manualFullscreenEnabled: _dbManualFullscreenEnabled,
    );

    _syncImmersiveModeForState(state);
    _publishHostedSnapshots();
  }

  void _publishHostedSnapshots() {
    final localSession = state.localSessionState;
    if (localSession.role == LocalSessionRole.host) {
      final snapshot = LocalLeaderboardSnapshot(
        hostDisplayName:
            localSession.localEndpointName ?? _defaultLocalEndpointName,
        generatedAtEpochMillis: DateTime.now().millisecondsSinceEpoch,
        kFactor: _dbKFactor,
        lastSyncedEpochMillis: _dbSyncState.lastSyncedEpochMillis,
        players: _dbPlayers,
      );
      _runPlatformCommand(
        () => _platformChannels.publishLocalHostedSnapshot(snapshot),
        action: 'publishLocalHostedSnapshot',
      );
    }
  }

  bool _isClientLockedToLeaderboard() => state.isReadOnlyClientMode;

  void _syncImmersiveModeForState(AppState targetState) {
    final showStatusBar = !_shouldUseFullscreenLeaderboard(targetState);
    if (_immersiveShowStatusBar == showStatusBar) {
      return;
    }
    _immersiveShowStatusBar = showStatusBar;
    _runPlatformCommand(
      () => _platformChannels.setImmersiveMode(showStatusBar: showStatusBar),
      action: 'setImmersiveMode',
    );
  }

  bool _shouldUseFullscreenLeaderboard(AppState value) =>
      value.manualFullscreenEnabled ||
      (value.screen == Screen.leaderboard &&
          value.leaderboardSource == LeaderboardSource.local &&
          value.localSessionState.role == LocalSessionRole.client &&
          value.localSessionState.phase == LocalSessionPhase.connected);

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _runRepositoryWrite(
    Future<void> Function() operation, {
    required String action,
  }) {
    _runGuardedAsync(
      operation,
      message: 'Repository write failed: $action',
      loggerName: 'sprint.controller.repository',
    );
  }

  void _runPlatformCommand(
    Future<void> Function() operation, {
    required String action,
  }) {
    _runGuardedAsync(
      operation,
      message: 'Platform command failed: $action',
      loggerName: 'sprint.controller.platform',
    );
  }

  void _runGuardedAsync(
    Future<void> Function() operation, {
    required String message,
    required String loggerName,
  }) {
    try {
      final future = operation();
      unawaited(
        future.catchError((Object error, StackTrace stackTrace) {
          AppLogger.error(
            message,
            name: loggerName,
            error: error,
            stackTrace: stackTrace,
          );
        }),
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        message,
        name: loggerName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static const int _minStandardSessionTargetMatches = 1;
  static const int _maxStandardSessionTargetMatches = 20;
  static const int _defaultStandardSessionTargetMatches = 3;
  static const String _defaultLocalEndpointName = 'Sprint Device';
}

List<UiRoundMatch> reorderRoundMatchesToAvoidFirstMatchPlayers(
  List<UiRoundMatch> matches, {
  required Set<String> excludedPlayerIds,
}) {
  if (matches.length < 2 || excludedPlayerIds.isEmpty) {
    return matches;
  }

  bool containsExcluded(UiRoundMatch match) =>
      excludedPlayerIds.contains(match.player1.id) ||
      excludedPlayerIds.contains(match.player2.id);

  if (!containsExcluded(matches.first)) {
    return matches;
  }

  final replacementIndex = List<int>.generate(
    matches.length - 1,
    (i) => i + 1,
  ).firstWhere((index) => !containsExcluded(matches[index]), orElse: () => -1);

  if (replacementIndex == -1) {
    return matches;
  }

  final reordered = List<UiRoundMatch>.from(matches);
  final first = reordered.first;
  reordered[0] = reordered[replacementIndex];
  reordered[replacementIndex] = first;
  return reordered;
}
