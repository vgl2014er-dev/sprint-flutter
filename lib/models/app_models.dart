import 'package:collection/collection.dart';

enum MatchResult {
  p1,
  p2,
  draw;

  String toWire() {
    switch (this) {
      case MatchResult.p1:
        return 'p1';
      case MatchResult.p2:
        return 'p2';
      case MatchResult.draw:
        return 'draw';
    }
  }

  static MatchResult fromWire(String? value) {
    switch (value) {
      case 'p1':
        return MatchResult.p1;
      case 'p2':
        return MatchResult.p2;
      default:
        return MatchResult.draw;
    }
  }
}

enum PairingStrategy {
  random,
  elo;

  String toWire() {
    switch (this) {
      case PairingStrategy.random:
        return 'random';
      case PairingStrategy.elo:
        return 'elo';
    }
  }

  static PairingStrategy? fromWire(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'random':
        return PairingStrategy.random;
      case 'elo':
        return PairingStrategy.elo;
      default:
        return null;
    }
  }
}

enum Screen {
  landing,
  randomPlayerSelection,
  eloPlayerSelection,
  deathMatchSelection,
  matchRunner,
  leaderboard,
  playerProfile,
  playerList,
  settings;

  String toWire() {
    switch (this) {
      case Screen.landing:
        return 'landing';
      case Screen.randomPlayerSelection:
        return 'select-random';
      case Screen.eloPlayerSelection:
        return 'select-elo';
      case Screen.deathMatchSelection:
        return 'select-death';
      case Screen.matchRunner:
        return 'run-matches';
      case Screen.leaderboard:
        return 'leaderboard';
      case Screen.playerProfile:
        return 'player-profile';
      case Screen.playerList:
        return 'player-list';
      case Screen.settings:
        return 'settings';
    }
  }

  static Screen? fromWire(String? value) {
    switch (value) {
      case 'landing':
        return Screen.landing;
      case 'select-random':
        return Screen.randomPlayerSelection;
      case 'select-elo':
        return Screen.eloPlayerSelection;
      case 'select-death':
        return Screen.deathMatchSelection;
      case 'run-matches':
        return Screen.matchRunner;
      case 'leaderboard':
        return Screen.leaderboard;
      case 'player-profile':
        return Screen.playerProfile;
      case 'player-list':
        return Screen.playerList;
      case 'settings':
        return Screen.settings;
      default:
        return null;
    }
  }
}

enum LeaderboardSource {
  db,
  local;

  String toWire() {
    switch (this) {
      case LeaderboardSource.db:
        return 'db';
      case LeaderboardSource.local:
        return 'local';
    }
  }

  static LeaderboardSource fromWire(String? value) {
    switch (value) {
      case 'local':
        return LeaderboardSource.local;
      default:
        return LeaderboardSource.db;
    }
  }
}

enum AppThemePreference {
  light,
  dark;

  String toWire() {
    switch (this) {
      case AppThemePreference.light:
        return 'light';
      case AppThemePreference.dark:
        return 'dark';
    }
  }

  static AppThemePreference fromWire(String? value) {
    switch (value) {
      case 'dark':
        return AppThemePreference.dark;
      default:
        return AppThemePreference.light;
    }
  }
}

enum LocalSessionRole {
  none,
  host,
  client;

  String toWire() {
    switch (this) {
      case LocalSessionRole.none:
        return 'none';
      case LocalSessionRole.host:
        return 'host';
      case LocalSessionRole.client:
        return 'client';
    }
  }

  static LocalSessionRole fromWire(String? value) {
    switch (value) {
      case 'host':
        return LocalSessionRole.host;
      case 'client':
        return LocalSessionRole.client;
      default:
        return LocalSessionRole.none;
    }
  }
}

enum LocalSessionPhase {
  idle,
  advertising,
  discovering,
  connecting,
  awaitingApproval,
  connected,
  disconnected,
  error;

  String toWire() {
    switch (this) {
      case LocalSessionPhase.idle:
        return 'idle';
      case LocalSessionPhase.advertising:
        return 'advertising';
      case LocalSessionPhase.discovering:
        return 'discovering';
      case LocalSessionPhase.connecting:
        return 'connecting';
      case LocalSessionPhase.awaitingApproval:
        return 'awaiting-approval';
      case LocalSessionPhase.connected:
        return 'connected';
      case LocalSessionPhase.disconnected:
        return 'disconnected';
      case LocalSessionPhase.error:
        return 'error';
    }
  }

  static LocalSessionPhase fromWire(String? value) {
    switch (value) {
      case 'advertising':
        return LocalSessionPhase.advertising;
      case 'discovering':
        return LocalSessionPhase.discovering;
      case 'connecting':
        return LocalSessionPhase.connecting;
      case 'awaiting-approval':
        return LocalSessionPhase.awaitingApproval;
      case 'connected':
        return LocalSessionPhase.connected;
      case 'disconnected':
        return LocalSessionPhase.disconnected;
      case 'error':
        return LocalSessionPhase.error;
      default:
        return LocalSessionPhase.idle;
    }
  }
}

enum LocalConnectionMedium {
  unknown,
  ble,
  bt,
  wifi;

  String toWire() {
    switch (this) {
      case LocalConnectionMedium.unknown:
        return 'unknown';
      case LocalConnectionMedium.ble:
        return 'ble';
      case LocalConnectionMedium.bt:
        return 'bt';
      case LocalConnectionMedium.wifi:
        return 'wifi';
    }
  }

  static LocalConnectionMedium fromWire(String? value) {
    switch (value) {
      case 'ble':
        return LocalConnectionMedium.ble;
      case 'bt':
        return LocalConnectionMedium.bt;
      case 'wifi':
        return LocalConnectionMedium.wifi;
      default:
        return LocalConnectionMedium.unknown;
    }
  }
}

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.elo,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.matchesPlayed,
  });

  final String id;
  final String name;
  final int elo;
  final int wins;
  final int losses;
  final int draws;
  final int matchesPlayed;

  Player copyWith({
    String? id,
    String? name,
    int? elo,
    int? wins,
    int? losses,
    int? draws,
    int? matchesPlayed,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      elo: elo ?? this.elo,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'elo': elo,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'matchesPlayed': matchesPlayed,
    };
  }

  factory Player.fromJson(Map<String, Object?> json) {
    return Player(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      elo: _toInt(json['elo'], 1200),
      wins: _toInt(json['wins'], 0),
      losses: _toInt(json['losses'], 0),
      draws: _toInt(json['draws'], 0),
      matchesPlayed: _toInt(json['matchesPlayed'], 0),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Player &&
            id == other.id &&
            name == other.name &&
            elo == other.elo &&
            wins == other.wins &&
            losses == other.losses &&
            draws == other.draws &&
            matchesPlayed == other.matchesPlayed;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, elo, wins, losses, draws, matchesPlayed);
  }
}

class MatchHistoryEntry {
  const MatchHistoryEntry({
    required this.id,
    required this.p1Id,
    required this.p2Id,
    required this.p1Name,
    required this.p2Name,
    required this.p1EloBefore,
    required this.p2EloBefore,
    required this.p1EloAfter,
    required this.p2EloAfter,
    required this.result,
    required this.timestamp,
  });

  final String id;
  final String p1Id;
  final String p2Id;
  final String p1Name;
  final String p2Name;
  final int p1EloBefore;
  final int p2EloBefore;
  final int p1EloAfter;
  final int p2EloAfter;
  final MatchResult result;
  final int timestamp;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'p1Id': p1Id,
      'p2Id': p2Id,
      'p1Name': p1Name,
      'p2Name': p2Name,
      'p1EloBefore': p1EloBefore,
      'p2EloBefore': p2EloBefore,
      'p1EloAfter': p1EloAfter,
      'p2EloAfter': p2EloAfter,
      'result': result.toWire(),
      'timestamp': timestamp,
    };
  }

  factory MatchHistoryEntry.fromJson(Map<String, Object?> json) {
    return MatchHistoryEntry(
      id: (json['id'] ?? '').toString(),
      p1Id: (json['p1Id'] ?? '').toString(),
      p2Id: (json['p2Id'] ?? '').toString(),
      p1Name: (json['p1Name'] ?? '').toString(),
      p2Name: (json['p2Name'] ?? '').toString(),
      p1EloBefore: _toInt(json['p1EloBefore'], 1200),
      p2EloBefore: _toInt(json['p2EloBefore'], 1200),
      p1EloAfter: _toInt(json['p1EloAfter'], 1200),
      p2EloAfter: _toInt(json['p2EloAfter'], 1200),
      result: MatchResult.fromWire(json['result']?.toString()),
      timestamp: _toInt(
        json['timestamp'],
        DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MatchHistoryEntry &&
            id == other.id &&
            p1Id == other.p1Id &&
            p2Id == other.p2Id &&
            p1Name == other.p1Name &&
            p2Name == other.p2Name &&
            p1EloBefore == other.p1EloBefore &&
            p2EloBefore == other.p2EloBefore &&
            p1EloAfter == other.p1EloAfter &&
            p2EloAfter == other.p2EloAfter &&
            result == other.result &&
            timestamp == other.timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      p1Id,
      p2Id,
      p1Name,
      p2Name,
      p1EloBefore,
      p2EloBefore,
      p1EloAfter,
      p2EloAfter,
      result,
      timestamp,
    );
  }
}

class RoundResultInput {
  const RoundResultInput({
    required this.p1Id,
    required this.p2Id,
    required this.result,
  });

  final String p1Id;
  final String p2Id;
  final MatchResult result;
}

class UiRoundMatch {
  const UiRoundMatch({
    required this.id,
    required this.player1,
    required this.player2,
    this.winnerId,
    this.isDraw = false,
    this.played = false,
    this.started = false,
  });

  final String id;
  final Player player1;
  final Player player2;
  final String? winnerId;
  final bool isDraw;
  final bool played;
  final bool started;

  UiRoundMatch copyWith({
    String? id,
    Player? player1,
    Player? player2,
    String? winnerId,
    bool winnerIdToNull = false,
    bool? isDraw,
    bool? played,
    bool? started,
  }) {
    return UiRoundMatch(
      id: id ?? this.id,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      winnerId: winnerIdToNull ? null : (winnerId ?? this.winnerId),
      isDraw: isDraw ?? this.isDraw,
      played: played ?? this.played,
      started: started ?? this.started,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'player1': player1.toJson(),
      'player2': player2.toJson(),
      'winnerId': winnerId,
      'isDraw': isDraw,
      'played': played,
      'started': started,
    };
  }

  factory UiRoundMatch.fromJson(Map<String, Object?> json) {
    return UiRoundMatch(
      id: (json['id'] ?? '').toString(),
      player1: Player.fromJson(
        (json['player1'] as Map?)?.cast<String, Object?>() ??
            const <String, Object?>{},
      ),
      player2: Player.fromJson(
        (json['player2'] as Map?)?.cast<String, Object?>() ??
            const <String, Object?>{},
      ),
      winnerId: json['winnerId']?.toString(),
      isDraw: json['isDraw'] == true,
      played: json['played'] == true,
      started: json['started'] == true,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UiRoundMatch &&
            id == other.id &&
            player1 == other.player1 &&
            player2 == other.player2 &&
            winnerId == other.winnerId &&
            isDraw == other.isDraw &&
            played == other.played &&
            started == other.started;
  }

  @override
  int get hashCode {
    return Object.hash(id, player1, player2, winnerId, isDraw, played, started);
  }
}

class SyncState {
  const SyncState({this.isSyncing = false, this.lastSyncedEpochMillis});

  final bool isSyncing;
  final int? lastSyncedEpochMillis;

  SyncState copyWith({
    bool? isSyncing,
    int? lastSyncedEpochMillis,
    bool clearLastSynced = false,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedEpochMillis: clearLastSynced
          ? null
          : (lastSyncedEpochMillis ?? this.lastSyncedEpochMillis),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SyncState &&
            isSyncing == other.isSyncing &&
            lastSyncedEpochMillis == other.lastSyncedEpochMillis;
  }

  @override
  int get hashCode => Object.hash(isSyncing, lastSyncedEpochMillis);
}

class DiscoveredHost {
  const DiscoveredHost({required this.endpointId, required this.displayName});

  final String endpointId;
  final String displayName;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'endpointId': endpointId,
      'displayName': displayName,
    };
  }

  factory DiscoveredHost.fromJson(Map<String, Object?> json) {
    return DiscoveredHost(
      endpointId: (json['endpointId'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DiscoveredHost &&
            endpointId == other.endpointId &&
            displayName == other.displayName;
  }

  @override
  int get hashCode => Object.hash(endpointId, displayName);
}

class LocalSessionState {
  const LocalSessionState({
    this.role = LocalSessionRole.none,
    this.phase = LocalSessionPhase.idle,
    this.connectionMedium = LocalConnectionMedium.unknown,
    this.discoveredHosts = const <DiscoveredHost>[],
    this.pendingConnectionName,
    this.connectedHostName,
    this.localEndpointName,
    this.authToken,
    this.lastLocalUpdateEpochMillis,
    this.errorMessage,
  });

  final LocalSessionRole role;
  final LocalSessionPhase phase;
  final LocalConnectionMedium connectionMedium;
  final List<DiscoveredHost> discoveredHosts;
  final String? pendingConnectionName;
  final String? connectedHostName;
  final String? localEndpointName;
  final String? authToken;
  final int? lastLocalUpdateEpochMillis;
  final String? errorMessage;

  LocalSessionState copyWith({
    LocalSessionRole? role,
    LocalSessionPhase? phase,
    LocalConnectionMedium? connectionMedium,
    List<DiscoveredHost>? discoveredHosts,
    String? pendingConnectionName,
    bool clearPendingConnectionName = false,
    String? connectedHostName,
    bool clearConnectedHostName = false,
    String? localEndpointName,
    bool clearLocalEndpointName = false,
    String? authToken,
    bool clearAuthToken = false,
    int? lastLocalUpdateEpochMillis,
    bool clearLastLocalUpdateEpochMillis = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return LocalSessionState(
      role: role ?? this.role,
      phase: phase ?? this.phase,
      connectionMedium: connectionMedium ?? this.connectionMedium,
      discoveredHosts: discoveredHosts ?? this.discoveredHosts,
      pendingConnectionName: clearPendingConnectionName
          ? null
          : (pendingConnectionName ?? this.pendingConnectionName),
      connectedHostName: clearConnectedHostName
          ? null
          : (connectedHostName ?? this.connectedHostName),
      localEndpointName: clearLocalEndpointName
          ? null
          : (localEndpointName ?? this.localEndpointName),
      authToken: clearAuthToken ? null : (authToken ?? this.authToken),
      lastLocalUpdateEpochMillis: clearLastLocalUpdateEpochMillis
          ? null
          : (lastLocalUpdateEpochMillis ?? this.lastLocalUpdateEpochMillis),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'role': role.toWire(),
      'phase': phase.toWire(),
      'connectionMedium': connectionMedium.toWire(),
      'discoveredHosts': discoveredHosts
          .map((host) => host.toJson())
          .toList(growable: false),
      'pendingConnectionName': pendingConnectionName,
      'connectedHostName': connectedHostName,
      'localEndpointName': localEndpointName,
      'authToken': authToken,
      'lastLocalUpdateEpochMillis': lastLocalUpdateEpochMillis,
      'errorMessage': errorMessage,
    };
  }

  factory LocalSessionState.fromJson(Map<String, Object?> json) {
    final discoveredHostsRaw = (json['discoveredHosts'] as List?) ?? const [];
    return LocalSessionState(
      role: LocalSessionRole.fromWire(json['role']?.toString()),
      phase: LocalSessionPhase.fromWire(json['phase']?.toString()),
      connectionMedium: LocalConnectionMedium.fromWire(
        json['connectionMedium']?.toString(),
      ),
      discoveredHosts: discoveredHostsRaw
          .map(
            (item) =>
                DiscoveredHost.fromJson((item as Map).cast<String, Object?>()),
          )
          .toList(growable: false),
      pendingConnectionName: json['pendingConnectionName']?.toString(),
      connectedHostName: json['connectedHostName']?.toString(),
      localEndpointName: json['localEndpointName']?.toString(),
      authToken: json['authToken']?.toString(),
      lastLocalUpdateEpochMillis: _toNullableInt(
        json['lastLocalUpdateEpochMillis'],
      ),
      errorMessage: json['errorMessage']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    const eq = DeepCollectionEquality();
    return identical(this, other) ||
        other is LocalSessionState &&
            role == other.role &&
            phase == other.phase &&
            connectionMedium == other.connectionMedium &&
            eq.equals(discoveredHosts, other.discoveredHosts) &&
            pendingConnectionName == other.pendingConnectionName &&
            connectedHostName == other.connectedHostName &&
            localEndpointName == other.localEndpointName &&
            authToken == other.authToken &&
            lastLocalUpdateEpochMillis == other.lastLocalUpdateEpochMillis &&
            errorMessage == other.errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(
      role,
      phase,
      connectionMedium,
      const DeepCollectionEquality().hash(discoveredHosts),
      pendingConnectionName,
      connectedHostName,
      localEndpointName,
      authToken,
      lastLocalUpdateEpochMillis,
      errorMessage,
    );
  }
}

class LocalLeaderboardSnapshot {
  const LocalLeaderboardSnapshot({
    required this.hostDisplayName,
    required this.generatedAtEpochMillis,
    required this.kFactor,
    required this.lastSyncedEpochMillis,
    required this.players,
  });

  final String hostDisplayName;
  final int generatedAtEpochMillis;
  final int kFactor;
  final int? lastSyncedEpochMillis;
  final List<Player> players;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'hostDisplayName': hostDisplayName,
      'generatedAtEpochMillis': generatedAtEpochMillis,
      'kFactor': kFactor,
      'lastSyncedEpochMillis': lastSyncedEpochMillis,
      'players': players
          .map((player) => player.toJson())
          .toList(growable: false),
    };
  }

  factory LocalLeaderboardSnapshot.fromJson(Map<String, Object?> json) {
    return LocalLeaderboardSnapshot(
      hostDisplayName: (json['hostDisplayName'] ?? '').toString(),
      generatedAtEpochMillis: _toInt(json['generatedAtEpochMillis'], 0),
      kFactor: _toInt(json['kFactor'], 32),
      lastSyncedEpochMillis: _toNullableInt(json['lastSyncedEpochMillis']),
      players: ((json['players'] as List?) ?? const [])
          .map((item) => Player.fromJson((item as Map).cast<String, Object?>()))
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    const eq = DeepCollectionEquality();
    return identical(this, other) ||
        other is LocalLeaderboardSnapshot &&
            hostDisplayName == other.hostDisplayName &&
            generatedAtEpochMillis == other.generatedAtEpochMillis &&
            kFactor == other.kFactor &&
            lastSyncedEpochMillis == other.lastSyncedEpochMillis &&
            eq.equals(players, other.players);
  }

  @override
  int get hashCode {
    return Object.hash(
      hostDisplayName,
      generatedAtEpochMillis,
      kFactor,
      lastSyncedEpochMillis,
      const DeepCollectionEquality().hash(players),
    );
  }
}

class HeadToHeadSummary {
  const HeadToHeadSummary({
    required this.matches,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winRatePercent,
  });

  final int matches;
  final int wins;
  final int losses;
  final int draws;
  final int winRatePercent;
}

class AppState {
  const AppState({
    required this.players,
    required this.history,
    required this.syncState,
    required this.kFactor,
    required this.screen,
    required this.roundMatches,
    required this.currentMatchIndex,
    required this.selectedPlayerId,
    required this.profileBackScreen,
    required this.leaderboardSource,
    required this.themePreference,
    required this.localSessionState,
    required this.standardSessionStrategy,
    required this.standardSessionParticipantIds,
    required this.standardSessionTargetMatchesPerPlayer,
    required this.standardSessionCompletedMatchesByPlayerId,
    required this.standardSessionScheduledMatchesByPlayerId,
    required this.deathMatchInProgress,
    required this.deathMatchLives,
    required this.deathMatchParticipantIds,
    required this.deathMatchPairingStrategy,
    required this.deathMatchLossesByPlayerId,
    required this.deathMatchMatchesPlayedByPlayerId,
    required this.deathMatchByePlayerId,
    required this.deathMatchChampionId,
  });

  final List<Player> players;
  final List<MatchHistoryEntry> history;
  final SyncState syncState;
  final int kFactor;
  final Screen screen;
  final List<UiRoundMatch> roundMatches;
  final int currentMatchIndex;
  final String? selectedPlayerId;
  final Screen profileBackScreen;
  final LeaderboardSource leaderboardSource;
  final AppThemePreference themePreference;
  final LocalSessionState localSessionState;
  final PairingStrategy? standardSessionStrategy;
  final List<String> standardSessionParticipantIds;
  final int standardSessionTargetMatchesPerPlayer;
  final Map<String, int> standardSessionCompletedMatchesByPlayerId;
  final Map<String, int> standardSessionScheduledMatchesByPlayerId;
  final bool deathMatchInProgress;
  final int deathMatchLives;
  final List<String> deathMatchParticipantIds;
  final PairingStrategy? deathMatchPairingStrategy;
  final Map<String, int> deathMatchLossesByPlayerId;
  final Map<String, int> deathMatchMatchesPlayedByPlayerId;
  final String? deathMatchByePlayerId;
  final String? deathMatchChampionId;

  bool get isLocalClientMode {
    return leaderboardSource == LeaderboardSource.local &&
        localSessionState.role == LocalSessionRole.client &&
        localSessionState.phase == LocalSessionPhase.connected;
  }

  bool get isReadOnlyClientMode => isLocalClientMode;

  bool get isStandardSession {
    return standardSessionStrategy != null &&
        standardSessionParticipantIds.length >= 2;
  }

  bool get isStandardSessionComplete {
    if (!isStandardSession) {
      return false;
    }
    final target = standardSessionTargetMatchesPerPlayer;
    return standardSessionParticipantIds.every(
      (id) => (standardSessionCompletedMatchesByPlayerId[id] ?? 0) >= target,
    );
  }

  AppState copyWith({
    List<Player>? players,
    List<MatchHistoryEntry>? history,
    SyncState? syncState,
    int? kFactor,
    Screen? screen,
    List<UiRoundMatch>? roundMatches,
    int? currentMatchIndex,
    String? selectedPlayerId,
    bool clearSelectedPlayerId = false,
    Screen? profileBackScreen,
    LeaderboardSource? leaderboardSource,
    AppThemePreference? themePreference,
    LocalSessionState? localSessionState,
    PairingStrategy? standardSessionStrategy,
    bool clearStandardSessionStrategy = false,
    List<String>? standardSessionParticipantIds,
    int? standardSessionTargetMatchesPerPlayer,
    Map<String, int>? standardSessionCompletedMatchesByPlayerId,
    Map<String, int>? standardSessionScheduledMatchesByPlayerId,
    bool? deathMatchInProgress,
    int? deathMatchLives,
    List<String>? deathMatchParticipantIds,
    PairingStrategy? deathMatchPairingStrategy,
    bool clearDeathMatchPairingStrategy = false,
    Map<String, int>? deathMatchLossesByPlayerId,
    Map<String, int>? deathMatchMatchesPlayedByPlayerId,
    String? deathMatchByePlayerId,
    bool clearDeathMatchByePlayerId = false,
    String? deathMatchChampionId,
    bool clearDeathMatchChampionId = false,
  }) {
    return AppState(
      players: players ?? this.players,
      history: history ?? this.history,
      syncState: syncState ?? this.syncState,
      kFactor: kFactor ?? this.kFactor,
      screen: screen ?? this.screen,
      roundMatches: roundMatches ?? this.roundMatches,
      currentMatchIndex: currentMatchIndex ?? this.currentMatchIndex,
      selectedPlayerId: clearSelectedPlayerId
          ? null
          : (selectedPlayerId ?? this.selectedPlayerId),
      profileBackScreen: profileBackScreen ?? this.profileBackScreen,
      leaderboardSource: leaderboardSource ?? this.leaderboardSource,
      themePreference: themePreference ?? this.themePreference,
      localSessionState: localSessionState ?? this.localSessionState,
      standardSessionStrategy: clearStandardSessionStrategy
          ? null
          : (standardSessionStrategy ?? this.standardSessionStrategy),
      standardSessionParticipantIds:
          standardSessionParticipantIds ?? this.standardSessionParticipantIds,
      standardSessionTargetMatchesPerPlayer:
          standardSessionTargetMatchesPerPlayer ??
          this.standardSessionTargetMatchesPerPlayer,
      standardSessionCompletedMatchesByPlayerId:
          standardSessionCompletedMatchesByPlayerId ??
          this.standardSessionCompletedMatchesByPlayerId,
      standardSessionScheduledMatchesByPlayerId:
          standardSessionScheduledMatchesByPlayerId ??
          this.standardSessionScheduledMatchesByPlayerId,
      deathMatchInProgress: deathMatchInProgress ?? this.deathMatchInProgress,
      deathMatchLives: deathMatchLives ?? this.deathMatchLives,
      deathMatchParticipantIds:
          deathMatchParticipantIds ?? this.deathMatchParticipantIds,
      deathMatchPairingStrategy: clearDeathMatchPairingStrategy
          ? null
          : (deathMatchPairingStrategy ?? this.deathMatchPairingStrategy),
      deathMatchLossesByPlayerId:
          deathMatchLossesByPlayerId ?? this.deathMatchLossesByPlayerId,
      deathMatchMatchesPlayedByPlayerId:
          deathMatchMatchesPlayedByPlayerId ??
          this.deathMatchMatchesPlayedByPlayerId,
      deathMatchByePlayerId: clearDeathMatchByePlayerId
          ? null
          : (deathMatchByePlayerId ?? this.deathMatchByePlayerId),
      deathMatchChampionId: clearDeathMatchChampionId
          ? null
          : (deathMatchChampionId ?? this.deathMatchChampionId),
    );
  }

  static AppState initial() {
    return const AppState(
      players: <Player>[],
      history: <MatchHistoryEntry>[],
      syncState: SyncState(),
      kFactor: 32,
      screen: Screen.landing,
      roundMatches: <UiRoundMatch>[],
      currentMatchIndex: 0,
      selectedPlayerId: null,
      profileBackScreen: Screen.leaderboard,
      leaderboardSource: LeaderboardSource.db,
      themePreference: AppThemePreference.light,
      localSessionState: LocalSessionState(),
      standardSessionStrategy: null,
      standardSessionParticipantIds: <String>[],
      standardSessionTargetMatchesPerPlayer: 3,
      standardSessionCompletedMatchesByPlayerId: <String, int>{},
      standardSessionScheduledMatchesByPlayerId: <String, int>{},
      deathMatchInProgress: false,
      deathMatchLives: 2,
      deathMatchParticipantIds: <String>[],
      deathMatchPairingStrategy: null,
      deathMatchLossesByPlayerId: <String, int>{},
      deathMatchMatchesPlayedByPlayerId: <String, int>{},
      deathMatchByePlayerId: null,
      deathMatchChampionId: null,
    );
  }

  @override
  bool operator ==(Object other) {
    const eq = DeepCollectionEquality();
    return identical(this, other) ||
        other is AppState &&
            eq.equals(players, other.players) &&
            eq.equals(history, other.history) &&
            syncState.isSyncing == other.syncState.isSyncing &&
            syncState.lastSyncedEpochMillis ==
                other.syncState.lastSyncedEpochMillis &&
            kFactor == other.kFactor &&
            screen == other.screen &&
            eq.equals(roundMatches, other.roundMatches) &&
            currentMatchIndex == other.currentMatchIndex &&
            selectedPlayerId == other.selectedPlayerId &&
            profileBackScreen == other.profileBackScreen &&
            leaderboardSource == other.leaderboardSource &&
            themePreference == other.themePreference &&
            localSessionState == other.localSessionState &&
            standardSessionStrategy == other.standardSessionStrategy &&
            eq.equals(
              standardSessionParticipantIds,
              other.standardSessionParticipantIds,
            ) &&
            standardSessionTargetMatchesPerPlayer ==
                other.standardSessionTargetMatchesPerPlayer &&
            eq.equals(
              standardSessionCompletedMatchesByPlayerId,
              other.standardSessionCompletedMatchesByPlayerId,
            ) &&
            eq.equals(
              standardSessionScheduledMatchesByPlayerId,
              other.standardSessionScheduledMatchesByPlayerId,
            ) &&
            deathMatchInProgress == other.deathMatchInProgress &&
            deathMatchLives == other.deathMatchLives &&
            eq.equals(
              deathMatchParticipantIds,
              other.deathMatchParticipantIds,
            ) &&
            deathMatchPairingStrategy == other.deathMatchPairingStrategy &&
            eq.equals(
              deathMatchLossesByPlayerId,
              other.deathMatchLossesByPlayerId,
            ) &&
            eq.equals(
              deathMatchMatchesPlayedByPlayerId,
              other.deathMatchMatchesPlayedByPlayerId,
            ) &&
            deathMatchByePlayerId == other.deathMatchByePlayerId &&
            deathMatchChampionId == other.deathMatchChampionId;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    const DeepCollectionEquality().hash(players),
    const DeepCollectionEquality().hash(history),
    syncState.isSyncing,
    syncState.lastSyncedEpochMillis,
    kFactor,
    screen,
    const DeepCollectionEquality().hash(roundMatches),
    currentMatchIndex,
    selectedPlayerId,
    profileBackScreen,
    leaderboardSource,
    themePreference,
    localSessionState,
    standardSessionStrategy,
    const DeepCollectionEquality().hash(standardSessionParticipantIds),
    standardSessionTargetMatchesPerPlayer,
    const DeepCollectionEquality().hash(
      standardSessionCompletedMatchesByPlayerId,
    ),
    const DeepCollectionEquality().hash(
      standardSessionScheduledMatchesByPlayerId,
    ),
    deathMatchInProgress,
    deathMatchLives,
    const DeepCollectionEquality().hash(deathMatchParticipantIds),
    deathMatchPairingStrategy,
    const DeepCollectionEquality().hash(deathMatchLossesByPlayerId),
    const DeepCollectionEquality().hash(deathMatchMatchesPlayedByPlayerId),
    deathMatchByePlayerId,
    deathMatchChampionId,
  ]);
}

int _toInt(Object? value, int defaultValue) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

int? _toNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
