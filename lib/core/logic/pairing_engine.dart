import 'dart:math';

import '../models/app_models.dart';

class RoundPair {
  const RoundPair({required this.player1, required this.player2});

  final Player player1;
  final Player player2;
}

class PairingEngine {
  static const int _randomCandidateSampleCount = 12;

  static List<RoundPair> generate(
    List<Player> players, {
    PairingStrategy strategy = PairingStrategy.random,
    Random? random,
    Map<String, String>? recentOpponentByPlayerId,
    Map<String, int>? eloBlockByPlayerId,
  }) {
    switch (strategy) {
      case PairingStrategy.random:
        return _generateRandom(
          players,
          random ?? Random(),
          recentOpponentByPlayerId: recentOpponentByPlayerId,
          eloBlockByPlayerId: eloBlockByPlayerId,
        );
      case PairingStrategy.elo:
        return _generateByElo(players);
    }
  }

  static List<RoundPair> _generateRandom(
    List<Player> players,
    Random random, {
    Map<String, String>? recentOpponentByPlayerId,
    Map<String, int>? eloBlockByPlayerId,
  }) {
    final recent = recentOpponentByPlayerId ?? const <String, String>{};
    final blocks = eloBlockByPlayerId ?? const <String, int>{};
    if (recent.isEmpty && blocks.isEmpty) {
      return _generateRandomLegacy(players, random);
    }

    if (players.length < 2) {
      return const <RoundPair>[];
    }

    final candidates = List<List<RoundPair>>.generate(
      _randomCandidateSampleCount,
      (_) => _generateRandomLegacy(players, random),
      growable: false,
    );

    var bestImmediateRematches = 1 << 30;
    var bestCrossBlockPairs = 1 << 30;
    final bestCandidates = <List<RoundPair>>[];

    for (final candidate in candidates) {
      final immediateRematches = _countImmediateRematches(candidate, recent);
      final crossBlockPairs = _countCrossBlockPairs(candidate, blocks);
      final isBetter =
          immediateRematches < bestImmediateRematches ||
          (immediateRematches == bestImmediateRematches &&
              crossBlockPairs < bestCrossBlockPairs);
      final isTie =
          immediateRematches == bestImmediateRematches &&
          crossBlockPairs == bestCrossBlockPairs;

      if (isBetter) {
        bestImmediateRematches = immediateRematches;
        bestCrossBlockPairs = crossBlockPairs;
        bestCandidates
          ..clear()
          ..add(candidate);
        continue;
      }

      if (isTie) {
        bestCandidates.add(candidate);
      }
    }

    if (bestCandidates.isEmpty) {
      return _generateRandomLegacy(players, random);
    }
    return bestCandidates[random.nextInt(bestCandidates.length)];
  }

  static int _countImmediateRematches(
    List<RoundPair> pairs,
    Map<String, String> recentOpponentByPlayerId,
  ) {
    var rematches = 0;
    for (final pair in pairs) {
      final p1 = pair.player1.id;
      final p2 = pair.player2.id;
      if (recentOpponentByPlayerId[p1] == p2 ||
          recentOpponentByPlayerId[p2] == p1) {
        rematches += 1;
      }
    }
    return rematches;
  }

  static int _countCrossBlockPairs(
    List<RoundPair> pairs,
    Map<String, int> eloBlockByPlayerId,
  ) {
    var crossBlockPairs = 0;
    for (final pair in pairs) {
      final p1Block = eloBlockByPlayerId[pair.player1.id];
      final p2Block = eloBlockByPlayerId[pair.player2.id];
      if (p1Block != null && p2Block != null && p1Block != p2Block) {
        crossBlockPairs += 1;
      }
    }
    return crossBlockPairs;
  }

  static List<RoundPair> _generateRandomLegacy(
    List<Player> players,
    Random random,
  ) {
    if (players.length < 2) {
      return const <RoundPair>[];
    }

    final shuffled = List<Player>.from(players)..shuffle(random);
    final pairs = <RoundPair>[];

    for (var index = 0; index < shuffled.length ~/ 2; index += 1) {
      final first = shuffled[index * 2];
      final second = shuffled[index * 2 + 1];
      pairs.add(RoundPair(player1: first, player2: second));
    }

    if (shuffled.length.isOdd) {
      final lastPlayer = shuffled.last;
      late final Player duplicate;
      if (pairs.length > 1) {
        final pairIndex = random.nextInt(max(1, pairs.length - 1));
        final pair = pairs[pairIndex];
        duplicate = random.nextBool() ? pair.player1 : pair.player2;
      } else if (pairs.length == 1) {
        final pair = pairs.first;
        duplicate = random.nextBool() ? pair.player1 : pair.player2;
      } else {
        duplicate = shuffled.first;
      }
      pairs.add(RoundPair(player1: lastPlayer, player2: duplicate));
    }

    return pairs;
  }

  static List<RoundPair> _generateByElo(List<Player> players) {
    if (players.length < 2) {
      return const <RoundPair>[];
    }

    final sorted = List<Player>.from(players)
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

    final pairs = <RoundPair>[];

    for (var index = 0; index < sorted.length ~/ 2; index += 1) {
      final first = sorted[index * 2];
      final second = sorted[index * 2 + 1];
      pairs.add(RoundPair(player1: first, player2: second));
    }

    if (sorted.length.isOdd) {
      final lastPlayer = sorted.last;
      final candidates = sorted.take(sorted.length - 1).toList(growable: false);
      if (candidates.isNotEmpty) {
        candidates.sort((left, right) {
          final byDistance = (left.elo - lastPlayer.elo).abs().compareTo(
            (right.elo - lastPlayer.elo).abs(),
          );
          if (byDistance != 0) {
            return byDistance;
          }
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
        pairs.add(RoundPair(player1: lastPlayer, player2: candidates.first));
      }
    }

    return pairs;
  }
}
