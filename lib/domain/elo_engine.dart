import 'dart:math';

import '../models/app_models.dart';

class EloUpdate {
  const EloUpdate({required this.p1Elo, required this.p2Elo});

  final int p1Elo;
  final int p2Elo;
}

class EloEngine {
  static EloUpdate apply(
    int p1Elo,
    int p2Elo,
    MatchResult result, {
    int kFactor = 32,
  }) {
    final expected1 = 1.0 / (1 + pow(10, (p2Elo - p1Elo) / 400));
    final expected2 = 1.0 / (1 + pow(10, (p1Elo - p2Elo) / 400));

    final score1 = switch (result) {
      MatchResult.p1 => 1.0,
      MatchResult.p2 => 0.0,
      MatchResult.draw => 0.5,
    };
    final score2 = switch (result) {
      MatchResult.p1 => 0.0,
      MatchResult.p2 => 1.0,
      MatchResult.draw => 0.5,
    };

    final newP1 = (p1Elo + kFactor * (score1 - expected1)).round();
    final newP2 = (p2Elo + kFactor * (score2 - expected2)).round();

    return EloUpdate(p1Elo: newP1, p2Elo: newP2);
  }
}