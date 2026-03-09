import '../models/app_models.dart';

class MatchRollbackEngine {
  static Map<String, Player> revert(
    Map<String, Player> playersById,
    MatchHistoryEntry entry,
  ) {
    final mutable = Map<String, Player>.from(playersById);
    final p1 = mutable[entry.p1Id];
    final p2 = mutable[entry.p2Id];

    if (p1 == null || p2 == null) {
      return playersById;
    }

    final p1Delta = entry.p1EloAfter - entry.p1EloBefore;
    final p2Delta = entry.p2EloAfter - entry.p2EloBefore;

    final updatedP1 = p1.copyWith(
      elo: p1.elo - p1Delta,
      wins: (p1.wins - (entry.result == MatchResult.p1 ? 1 : 0))
          .clamp(0, 1 << 31)
          .toInt(),
      losses: (p1.losses - (entry.result == MatchResult.p2 ? 1 : 0))
          .clamp(0, 1 << 31)
          .toInt(),
      draws: (p1.draws - (entry.result == MatchResult.draw ? 1 : 0))
          .clamp(0, 1 << 31)
          .toInt(),
      matchesPlayed: (p1.matchesPlayed - 1).clamp(0, 1 << 31).toInt(),
    );

    final updatedP2 = p2.copyWith(
      elo: p2.elo - p2Delta,
      wins: (p2.wins - (entry.result == MatchResult.p2 ? 1 : 0))
          .clamp(0, 1 << 31)
          .toInt(),
      losses: (p2.losses - (entry.result == MatchResult.p1 ? 1 : 0))
          .clamp(0, 1 << 31)
          .toInt(),
      draws: (p2.draws - (entry.result == MatchResult.draw ? 1 : 0))
          .clamp(0, 1 << 31)
          .toInt(),
      matchesPlayed: (p2.matchesPlayed - 1).clamp(0, 1 << 31).toInt(),
    );

    mutable[updatedP1.id] = updatedP1;
    mutable[updatedP2.id] = updatedP2;
    return mutable;
  }
}
