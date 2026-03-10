import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart' as db;
import '../data/repository/sprint_repository.dart';
import '../data/repository/sprint_repository_impl.dart';
import '../domain/defaults.dart';
import '../domain/pairing_engine.dart';
import '../models/app_models.dart';
import '../platform/platform_channels.dart';

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
      ref.onDispose(controller.dispose);
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
      _platformChannels.localSessionState.listen(_onLocalSessionState),
      _platformChannels.localSnapshot.listen((value) {
        _localSnapshot = value;
        _refreshProjectedData();
      }),
      _platformChannels.errors.listen((_) {}),
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

  LocalLeaderboardSnapshot? _localSnapshot;
  PairingStrategy _currentPairingStrategy = PairingStrategy.random;
  final Set<String> _deathMatchParticipantIds = <String>{};
  final Map<String, int> _deathMatchByeCountsByPlayerId = <String, int>{};
  String? _deathMatchPreviousByePlayerId;
  bool? _immersiveShowStatusBar;

  void navigateTo(Screen screen) {
    if (_isClientLockedToLeaderboard() && screen != Screen.leaderboard) {
      return;
    }
    state = state.copyWith(screen: screen);
  }

  bool generateMatches(
    Set<String> selectedIds,
    PairingStrategy strategy, {
    int targetMatchesPerPlayer = _defaultStandardSessionTargetMatches,
  }) {
    _currentPairingStrategy = strategy;
    _resetDeathMatchState();
    return _generateMatchesForStandardSession(
      selectedIds: selectedIds,
      strategy: strategy,
      targetMatchesPerPlayer: targetMatchesPerPlayer,
    );
  }

  bool startDeathMatch(
    Set<String> selectedIds,
    PairingStrategy pairingStrategy,
    int lives,
  ) {
    if (_isClientLockedToLeaderboard()) {
      return false;
    }

    final selectedPlayers = state.players
        .where((player) => selectedIds.contains(player.id))
        .toList(growable: false);
    if (selectedPlayers.length < 2) {
      return false;
    }

    final resolvedLives = lives.clamp(_minDeathMatchLives, _maxDeathMatchLives);

    _resetDeathMatchState();

    _deathMatchParticipantIds
      ..clear()
      ..addAll(selectedPlayers.map((player) => player.id));

    state = state.copyWith(
      deathMatchInProgress: true,
      deathMatchLives: resolvedLives,
      deathMatchParticipantIds: selectedPlayers
          .map((player) => player.id)
          .toList(growable: false),
      deathMatchPairingStrategy: pairingStrategy,
      deathMatchLossesByPlayerId: {
        for (final participantId in _deathMatchParticipantIds) participantId: 0,
      },
      deathMatchMatchesPlayedByPlayerId: {
        for (final participantId in _deathMatchParticipantIds) participantId: 0,
      },
      clearDeathMatchByePlayerId: true,
      clearDeathMatchChampionId: true,
    );

    _deathMatchByeCountsByPlayerId
      ..clear()
      ..addEntries(
        _deathMatchParticipantIds.map((id) => MapEntry<String, int>(id, 0)),
      );
    _deathMatchPreviousByePlayerId = null;

    return _generateDeathMatchRound();
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

    _applyDeathMatchResult(submittedMatch!, result);

    unawaited(
      _repository.submitRoundResults(<RoundResultInput>[
        RoundResultInput(
          p1Id: submittedMatch!.player1.id,
          p2Id: submittedMatch!.player2.id,
          result: result,
        ),
      ]),
    );
  }

  void finishRound(Screen nextScreen) {
    state = state.copyWith(screen: nextScreen);
  }

  void startNextRound() {
    if (state.deathMatchInProgress) {
      _generateDeathMatchRound();
      return;
    }

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

  void resetDeathMatch() {
    _resetDeathMatchState();
    state = state.copyWith(
      roundMatches: const <UiRoundMatch>[],
      currentMatchIndex: 0,
      screen: state.screen == Screen.matchRunner
          ? Screen.deathMatchSelection
          : state.screen,
    );
  }

  void resetData() {
    unawaited(_repository.resetAllData());
  }

  void setKFactor(int kFactor) {
    unawaited(_repository.setKFactor(kFactor));
  }

  void deleteMatch(String matchId) {
    unawaited(_repository.deleteMatch(matchId));
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
    state = state.copyWith(leaderboardSource: LeaderboardSource.db);
    unawaited(_platformChannels.useDatabaseModeForLocal());
    unawaited(_platformChannels.startLocalHosting(localEndpointName));
  }

  void stopLocalHosting() {
    unawaited(_platformChannels.stopLocalHosting());
  }

  void scanLocalHosts(String localEndpointName) {
    unawaited(_platformChannels.scanLocalHosts(localEndpointName));
  }

  void connectToLocalHost(String endpointId) {
    unawaited(_platformChannels.connectToLocalHost(endpointId));
  }

  void acceptLocalConnection() {
    unawaited(_platformChannels.acceptLocalConnection());
  }

  void rejectLocalConnection() {
    unawaited(_platformChannels.rejectLocalConnection());
  }

  void disconnectLocalConnection() {
    unawaited(_platformChannels.disconnectLocalConnection());
  }

  void useDatabaseLeaderboard() {
    state = state.copyWith(leaderboardSource: LeaderboardSource.db);
    _syncImmersiveModeForState(state);
    unawaited(_platformChannels.useDatabaseModeForLocal());
    _refreshProjectedData();
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

    final queue = <RoundPair>[];
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    final maxIterations = participantIds.length * resolvedTarget * 12;
    var iterations = 0;

    bool allScheduledToTarget() {
      return participantIds.every(
        (id) => (scheduledCounts[id] ?? 0) >= resolvedTarget,
      );
    }

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

  bool _generateDeathMatchRound() {
    final playersById = {for (final player in state.players) player.id: player};

    final activeParticipants = _deathMatchParticipantIds
        .map((id) => playersById[id])
        .whereType<Player>()
        .where(
          (participant) =>
              (state.deathMatchLossesByPlayerId[participant.id] ?? 0) <
              state.deathMatchLives,
        )
        .toList(growable: false);

    if (activeParticipants.length < 2) {
      state = state.copyWith(
        deathMatchInProgress: false,
        deathMatchChampionId: activeParticipants.length == 1
            ? activeParticipants.single.id
            : null,
        clearDeathMatchByePlayerId: true,
        roundMatches: const <UiRoundMatch>[],
        currentMatchIndex: 0,
        screen: Screen.deathMatchSelection,
      );
      return false;
    }

    final strategy = state.deathMatchPairingStrategy ?? PairingStrategy.random;

    final byePlayerId = activeParticipants.length.isOdd
        ? _chooseDeathMatchByePlayer(activeParticipants)
        : null;

    if (byePlayerId != null) {
      _deathMatchByeCountsByPlayerId[byePlayerId] =
          (_deathMatchByeCountsByPlayerId[byePlayerId] ?? 0) + 1;
      _deathMatchPreviousByePlayerId = byePlayerId;
    }

    final pairingPool = byePlayerId == null
        ? activeParticipants
        : activeParticipants
              .where((participant) => participant.id != byePlayerId)
              .toList(growable: false);

    if (pairingPool.length < 2) {
      state = state.copyWith(
        deathMatchInProgress: false,
        deathMatchChampionId: pairingPool.isNotEmpty
            ? pairingPool.single.id
            : byePlayerId,
        screen: Screen.deathMatchSelection,
      );
      return false;
    }

    final pairs = PairingEngine.generate(
      pairingPool,
      strategy: strategy,
      random: Random(DateTime.now().millisecondsSinceEpoch),
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    state = state.copyWith(
      roundMatches: pairs
          .asMap()
          .entries
          .map(
            (entry) => UiRoundMatch(
              id: 'death-$now-${entry.key}',
              player1: entry.value.player1,
              player2: entry.value.player2,
            ),
          )
          .toList(growable: false),
      currentMatchIndex: 0,
      deathMatchByePlayerId: byePlayerId,
      clearDeathMatchChampionId: true,
      screen: Screen.matchRunner,
    );

    return state.roundMatches.isNotEmpty;
  }

  String _chooseDeathMatchByePlayer(List<Player> activeParticipants) {
    final sorted = List<Player>.from(activeParticipants)
      ..sort((left, right) {
        final byeCountCompare = (_deathMatchByeCountsByPlayerId[left.id] ?? 0)
            .compareTo(_deathMatchByeCountsByPlayerId[right.id] ?? 0);
        if (byeCountCompare != 0) {
          return byeCountCompare;
        }

        final matchesCompare =
            (state.deathMatchMatchesPlayedByPlayerId[left.id] ?? 0).compareTo(
              state.deathMatchMatchesPlayedByPlayerId[right.id] ?? 0,
            );
        if (matchesCompare != 0) {
          return matchesCompare;
        }

        final lossesCompare = (state.deathMatchLossesByPlayerId[right.id] ?? 0)
            .compareTo(state.deathMatchLossesByPlayerId[left.id] ?? 0);
        if (lossesCompare != 0) {
          return lossesCompare;
        }

        final nameCompare = left.name.compareTo(right.name);
        if (nameCompare != 0) {
          return nameCompare;
        }

        return left.id.compareTo(right.id);
      });

    return sorted
        .firstWhere(
          (player) => player.id != _deathMatchPreviousByePlayerId,
          orElse: () => sorted.first,
        )
        .id;
  }

  void _applyDeathMatchResult(UiRoundMatch match, MatchResult result) {
    if (!state.deathMatchInProgress) {
      return;
    }

    final participantIds = _deathMatchParticipantIds;
    final p1Id = match.player1.id;
    final p2Id = match.player2.id;
    if (!participantIds.contains(p1Id) || !participantIds.contains(p2Id)) {
      return;
    }

    final updatedMatchesPlayed = Map<String, int>.from(
      state.deathMatchMatchesPlayedByPlayerId,
    );
    updatedMatchesPlayed[p1Id] = (updatedMatchesPlayed[p1Id] ?? 0) + 1;
    updatedMatchesPlayed[p2Id] = (updatedMatchesPlayed[p2Id] ?? 0) + 1;

    if (result == MatchResult.draw) {
      state = state.copyWith(
        deathMatchMatchesPlayedByPlayerId: updatedMatchesPlayed,
      );
      return;
    }

    final losingPlayerId = result == MatchResult.p1 ? p2Id : p1Id;
    final updatedLosses = Map<String, int>.from(
      state.deathMatchLossesByPlayerId,
    );
    updatedLosses[losingPlayerId] = (updatedLosses[losingPlayerId] ?? 0) + 1;

    state = state.copyWith(
      deathMatchMatchesPlayedByPlayerId: updatedMatchesPlayed,
      deathMatchLossesByPlayerId: updatedLosses,
    );
  }

  void _resetDeathMatchState() {
    _deathMatchParticipantIds.clear();
    _deathMatchByeCountsByPlayerId.clear();
    _deathMatchPreviousByePlayerId = null;

    state = state.copyWith(
      deathMatchInProgress: false,
      deathMatchParticipantIds: const <String>[],
      clearDeathMatchPairingStrategy: true,
      deathMatchLossesByPlayerId: const <String, int>{},
      deathMatchMatchesPlayedByPlayerId: const <String, int>{},
      clearDeathMatchByePlayerId: true,
      clearDeathMatchChampionId: true,
      clearStandardSessionStrategy: true,
      standardSessionParticipantIds: const <String>[],
      standardSessionTargetMatchesPerPlayer:
          _defaultStandardSessionTargetMatches,
      standardSessionCompletedMatchesByPlayerId: const <String, int>{},
      standardSessionScheduledMatchesByPlayerId: const <String, int>{},
    );
  }

  void _onLocalSessionState(LocalSessionState sessionState) {
    var nextState = state.copyWith(localSessionState: sessionState);

    if (sessionState.role == LocalSessionRole.client &&
        sessionState.phase == LocalSessionPhase.connected) {
      nextState = nextState.copyWith(
        screen: Screen.leaderboard,
        clearSelectedPlayerId: true,
      );
    }

    if (sessionState.role == LocalSessionRole.client &&
        sessionState.phase == LocalSessionPhase.connected) {
      nextState = nextState.copyWith(
        leaderboardSource: LeaderboardSource.local,
      );
    }

    state = nextState;
    _syncImmersiveModeForState(state);
    _refreshProjectedData();
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
    );

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
      unawaited(_platformChannels.publishLocalHostedSnapshot(snapshot));
    }
  }

  bool _isClientLockedToLeaderboard() {
    return state.isReadOnlyClientMode;
  }

  void _syncImmersiveModeForState(AppState targetState) {
    final showStatusBar = !_shouldUseFullscreenLeaderboard(targetState);
    if (_immersiveShowStatusBar == showStatusBar) {
      return;
    }
    _immersiveShowStatusBar = showStatusBar;
    unawaited(_platformChannels.setImmersiveMode(showStatusBar: showStatusBar));
  }

  bool _shouldUseFullscreenLeaderboard(AppState value) {
    return value.screen == Screen.leaderboard &&
        value.leaderboardSource == LeaderboardSource.local &&
        value.localSessionState.role == LocalSessionRole.client &&
        value.localSessionState.phase == LocalSessionPhase.connected;
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  static const int _minDeathMatchLives = 1;
  static const int _maxDeathMatchLives = 9;
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

  bool containsExcluded(UiRoundMatch match) {
    return excludedPlayerIds.contains(match.player1.id) ||
        excludedPlayerIds.contains(match.player2.id);
  }

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
