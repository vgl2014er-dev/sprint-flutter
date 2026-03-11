import 'dart:math';

import '../models/app_models.dart';

class RoundPair {
  const RoundPair({required this.player1, required this.player2});

  final Player player1;
  final Player player2;
}

class PairingEngine {
  static List<RoundPair> generate(
    List<Player> players, {
    PairingStrategy strategy = PairingStrategy.random,
    Random? random,
  }) {
    switch (strategy) {
      case PairingStrategy.random:
        return _generateRandom(players, random ?? Random());
      case PairingStrategy.elo:
        return _generateByElo(players);
    }
  }

  static List<RoundPair> _generateRandom(List<Player> players, Random random) {
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
