import 'package:sprint/models/app_models.dart';

Player player(
  String id, {
  String? name,
  int elo = 1200,
  int wins = 0,
  int losses = 0,
  int draws = 0,
  int matchesPlayed = 0,
}) => Player(
    id: id,
    name: name ?? id,
    elo: elo,
    wins: wins,
    losses: losses,
    draws: draws,
    matchesPlayed: matchesPlayed,
  );

MatchHistoryEntry historyEntry({
  required String id,
  required String p1Id,
  required String p2Id,
  required String p1Name,
  required String p2Name,
  required int p1EloBefore,
  required int p2EloBefore,
  required int p1EloAfter,
  required int p2EloAfter,
  required MatchResult result,
  required int timestamp,
}) => MatchHistoryEntry(
    id: id,
    p1Id: p1Id,
    p2Id: p2Id,
    p1Name: p1Name,
    p2Name: p2Name,
    p1EloBefore: p1EloBefore,
    p2EloBefore: p2EloBefore,
    p1EloAfter: p1EloAfter,
    p2EloAfter: p2EloAfter,
    result: result,
    timestamp: timestamp,
  );
