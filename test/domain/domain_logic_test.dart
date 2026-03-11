import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprint/domain/elo_engine.dart';
import 'package:sprint/domain/head_to_head_calculator.dart';
import 'package:sprint/domain/history_policy.dart';
import 'package:sprint/domain/match_rollback_engine.dart';
import 'package:sprint/domain/pairing_engine.dart';
import 'package:sprint/models/app_models.dart';

import '../test_helpers.dart';

void main() {
  group('EloEngine', () {
    test('applies expected k-factor deltas for equal ratings', () {
      final result = EloEngine.apply(1200, 1200, MatchResult.p1);
      expect(result.p1Elo, 1216);
      expect(result.p2Elo, 1184);
    });

    test('handles draw when ratings differ', () {
      final result = EloEngine.apply(1400, 1200, MatchResult.draw);
      expect(result.p1Elo, 1392);
      expect(result.p2Elo, 1208);
    });
  });

  group('PairingEngine', () {
    final players = <Player>[
      player('a', name: 'A', elo: 1600),
      player('b', name: 'B', elo: 1500),
      player('c', name: 'C', elo: 1400),
      player('d', name: 'D', elo: 1300),
      player('e', name: 'E'),
    ];

    test('random strategy creates odd-player duplicate pairing', () {
      final pairs = PairingEngine.generate(
        players,
        random: Random(7),
      );

      expect(pairs.length, 3);

      final appearances = <String, int>{};
      for (final pair in pairs) {
        appearances[pair.player1.id] = (appearances[pair.player1.id] ?? 0) + 1;
        appearances[pair.player2.id] = (appearances[pair.player2.id] ?? 0) + 1;
      }

      expect(appearances.length, 5);
      expect(appearances.values.where((count) => count == 2).length, 1);
    });

    test('elo strategy pairs by sorted elo and closest odd duplicate', () {
      final pairs = PairingEngine.generate(
        players,
        strategy: PairingStrategy.elo,
      );

      expect(pairs.length, 3);
      expect(pairs[0].player1.id, 'a');
      expect(pairs[0].player2.id, 'b');
      expect(pairs[1].player1.id, 'c');
      expect(pairs[1].player2.id, 'd');
      expect(pairs[2].player1.id, 'e');
      expect(pairs[2].player2.id, 'd');
    });
  });

  group('History and rollback', () {
    test('caps history and keeps newest entries', () {
      final entries = List<MatchHistoryEntry>.generate(
        8,
        (index) => historyEntry(
          id: 'm$index',
          p1Id: 'a',
          p2Id: 'b',
          p1Name: 'A',
          p2Name: 'B',
          p1EloBefore: 1200,
          p2EloBefore: 1200,
          p1EloAfter: 1200,
          p2EloAfter: 1200,
          result: MatchResult.draw,
          timestamp: index,
        ),
      );

      final capped = HistoryPolicy.cap(entries, maxEntries: 3);
      expect(capped.map((entry) => entry.id), <String>['m7', 'm6', 'm5']);
    });

    test('rolls back elo and counters for deleted match', () {
      final beforeA = player(
        'a',
        name: 'A',
      );
      final beforeB = player(
        'b',
        name: 'B',
      );
      final afterA = beforeA.copyWith(elo: 1216, wins: 1, matchesPlayed: 1);
      final afterB = beforeB.copyWith(elo: 1184, losses: 1, matchesPlayed: 1);

      final reverted = MatchRollbackEngine.revert(
        <String, Player>{'a': afterA, 'b': afterB},
        historyEntry(
          id: 'm1',
          p1Id: 'a',
          p2Id: 'b',
          p1Name: 'A',
          p2Name: 'B',
          p1EloBefore: 1200,
          p2EloBefore: 1200,
          p1EloAfter: 1216,
          p2EloAfter: 1184,
          result: MatchResult.p1,
          timestamp: 1,
        ),
      );

      expect(reverted['a'], beforeA);
      expect(reverted['b'], beforeB);
    });
  });

  group('HeadToHeadCalculator', () {
    test('computes wins/losses/draws and win rate', () {
      final summary =
          HeadToHeadCalculator.calculateForPlayer('a', 'b', <MatchHistoryEntry>[
            historyEntry(
              id: '1',
              p1Id: 'a',
              p2Id: 'b',
              p1Name: 'A',
              p2Name: 'B',
              p1EloBefore: 1200,
              p2EloBefore: 1200,
              p1EloAfter: 1216,
              p2EloAfter: 1184,
              result: MatchResult.p1,
              timestamp: 1,
            ),
            historyEntry(
              id: '2',
              p1Id: 'b',
              p2Id: 'a',
              p1Name: 'B',
              p2Name: 'A',
              p1EloBefore: 1184,
              p2EloBefore: 1216,
              p1EloAfter: 1200,
              p2EloAfter: 1200,
              result: MatchResult.p1,
              timestamp: 2,
            ),
            historyEntry(
              id: '3',
              p1Id: 'a',
              p2Id: 'b',
              p1Name: 'A',
              p2Name: 'B',
              p1EloBefore: 1200,
              p2EloBefore: 1200,
              p1EloAfter: 1200,
              p2EloAfter: 1200,
              result: MatchResult.draw,
              timestamp: 3,
            ),
          ]);

      expect(summary.matches, 3);
      expect(summary.wins, 1);
      expect(summary.losses, 1);
      expect(summary.draws, 1);
      expect(summary.winRatePercent, 33);
    });
  });
}
