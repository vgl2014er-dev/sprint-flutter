import '../models/app_models.dart';

class HeadToHeadCalculator {
  static HeadToHeadSummary calculateForPlayer(
    String playerId,
    String opponentId,
    List<MatchHistoryEntry> history,
  ) {
    final h2h = history
        .where(
          (entry) =>
              (entry.p1Id == playerId && entry.p2Id == opponentId) ||
              (entry.p1Id == opponentId && entry.p2Id == playerId),
        )
        .toList(growable: false);

    final wins = h2h
        .where(
          (entry) =>
              (entry.p1Id == playerId && entry.result == MatchResult.p1) ||
              (entry.p2Id == playerId && entry.result == MatchResult.p2),
        )
        .length;
    final draws = h2h.where((entry) => entry.result == MatchResult.draw).length;
    final losses = h2h.length - wins - draws;
    final winRatePercent = h2h.isEmpty ? 0 : ((wins / h2h.length) * 100).toInt();

    return HeadToHeadSummary(
      matches: h2h.length,
      wins: wins,
      losses: losses,
      draws: draws,
      winRatePercent: winRatePercent,
    );
  }
}