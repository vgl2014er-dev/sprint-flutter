import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprint/models/app_models.dart';
import 'package:sprint/ui/screens/sprint_app.dart';
import 'package:sprint/ui/theme/app_theme.dart';

import '../test_helpers.dart';

void main() {
  AppState stateWithPlayers(
    List<Player> players, {
    bool readOnlyClient = false,
    LocalSessionState? localSessionStateOverride,
  }) {
    final localSessionState =
        localSessionStateOverride ??
        (readOnlyClient
            ? const LocalSessionState(
                role: LocalSessionRole.client,
                phase: LocalSessionPhase.connected,
              )
            : const LocalSessionState());
    return AppState.initial().copyWith(
      players: players,
      leaderboardSource: readOnlyClient
          ? LeaderboardSource.local
          : LeaderboardSource.db,
      localSessionState: localSessionState,
    );
  }

  Future<void> pumpLeaderboard(
    WidgetTester tester, {
    required AppState state,
    required ValueChanged<Player> onViewProfile,
    Size size = const Size(420, 840),
    EdgeInsets mediaPadding = EdgeInsets.zero,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(padding: mediaPadding),
        child: MaterialApp(
          theme: buildSprintTheme(Brightness.light),
          darkTheme: buildSprintTheme(Brightness.dark),
          home: Scaffold(
            body: LeaderboardScreen(state: state, onViewProfile: onViewProfile),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('always shows connected-style leaderboard header', (
    WidgetTester tester,
  ) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(
        <Player>[player('p1', name: 'Alpha')],
        localSessionStateOverride: const LocalSessionState(
          role: LocalSessionRole.client,
          phase: LocalSessionPhase.connected,
          connectionMedium: LocalConnectionMedium.wifi,
        ),
      ),
      onViewProfile: (_) {},
    );

    expect(find.text('LEADERBOARD'), findsOneWidget);
    expect(find.text('SEASON 04 • GLOBAL RANKINGS'), findsOneWidget);
    expect(find.text('WiFi'), findsNothing);
  });

  testWidgets(
    'disconnected/default mode still shows connected-style title header',
    (WidgetTester tester) async {
      await pumpLeaderboard(
        tester,
        state: stateWithPlayers(<Player>[player('p1', name: 'Alpha')]),
        onViewProfile: (_) {},
      );

      expect(find.text('LEADERBOARD'), findsOneWidget);
      expect(find.text('SEASON 04 • GLOBAL RANKINGS'), findsOneWidget);
    },
  );

  testWidgets('leaderboard cards stay square in both client and default mode', (
    WidgetTester tester,
  ) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[
        player('p0', name: 'Alpha'),
      ], readOnlyClient: true),
      onViewProfile: (_) {},
    );
    final connectedCard = tester.widget<Container>(
      find.byKey(const Key('leaderboard-highlight-row-p0')),
    );
    final connectedDecoration = connectedCard.decoration! as BoxDecoration;
    expect(connectedDecoration.borderRadius, BorderRadius.circular(0));

    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[player('p0', name: 'Alpha')]),
      onViewProfile: (_) {},
    );
    final defaultCard = tester.widget<Container>(
      find.byKey(const Key('leaderboard-highlight-row-p0')),
    );
    final defaultDecoration = defaultCard.decoration! as BoxDecoration;
    expect(defaultDecoration.borderRadius, BorderRadius.circular(0));
  });

  testWidgets('sorts rows by Elo descending', (WidgetTester tester) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[
        player('p1', name: 'Low', elo: 1000),
        player('p2', name: 'High', elo: 1300),
        player('p3', name: 'Mid'),
      ]),
      onViewProfile: (_) {},
    );

    final highY = tester.getTopLeft(find.text('High')).dy;
    final midY = tester.getTopLeft(find.text('Mid')).dy;
    final lowY = tester.getTopLeft(find.text('Low')).dy;
    expect(highY, lessThan(midY));
    expect(midY, lessThan(lowY));
  });

  testWidgets('connected mode adapts full/half split to available height', (
    WidgetTester tester,
  ) async {
    final players = List<Player>.generate(
      10,
      (index) => player('p$index', name: 'P$index', elo: 2000 - index),
    );
    int connectedFullCount() => find
        .byWidgetPredicate(
          (widget) =>
              widget.key is Key &&
              widget.key.toString().contains('connected-full-card-'),
        )
        .evaluate()
        .length;
    int connectedHalfCount() => find
        .byWidgetPredicate(
          (widget) =>
              widget.key is Key &&
              widget.key.toString().contains('connected-half-card-'),
        )
        .evaluate()
        .length;

    await pumpLeaderboard(
      tester,
      size: const Size(720, 420),
      state: stateWithPlayers(players, readOnlyClient: true),
      onViewProfile: (_) {},
    );

    final compactFull = connectedFullCount();
    final compactHalf = connectedHalfCount();
    expect(compactFull + compactHalf, players.length);
    expect(compactFull, greaterThanOrEqualTo(3));
    expect(compactHalf, greaterThan(0));

    await pumpLeaderboard(
      tester,
      size: const Size(720, 900),
      state: stateWithPlayers(players, readOnlyClient: true),
      onViewProfile: (_) {},
    );

    final tallFull = connectedFullCount();
    final tallHalf = connectedHalfCount();
    expect(tallFull + tallHalf, players.length);
    expect(tallFull, greaterThan(compactFull));
    expect(tallHalf, lessThan(compactHalf));
  });

  testWidgets('connected mode scales card heights continuously by viewport', (
    WidgetTester tester,
  ) async {
    final players = List<Player>.generate(
      6,
      (index) => player('p$index', name: 'P$index', elo: 2200 - index),
    );

    await pumpLeaderboard(
      tester,
      size: const Size(720, 900),
      state: stateWithPlayers(players, readOnlyClient: true),
      onViewProfile: (_) {},
    );
    final tallHeight = tester
        .getSize(find.byKey(const Key('leaderboard-highlight-row-p0')))
        .height;

    await pumpLeaderboard(
      tester,
      size: const Size(720, 620),
      state: stateWithPlayers(players, readOnlyClient: true),
      onViewProfile: (_) {},
    );
    final compactHeight = tester
        .getSize(find.byKey(const Key('leaderboard-highlight-row-p0')))
        .height;

    expect(compactHeight, lessThan(tallHeight));
    expect(compactHeight, greaterThan(0));
  });

  testWidgets('connected mode scales down for larger player counts', (
    WidgetTester tester,
  ) async {
    final players = List<Player>.generate(
      28,
      (index) => player('p$index', name: 'P$index', elo: 2400 - index),
    );
    await pumpLeaderboard(
      tester,
      size: const Size(360, 360),
      state: stateWithPlayers(players, readOnlyClient: true),
      onViewProfile: (_) {},
    );

    final topRankCard = find.byKey(const Key('leaderboard-highlight-row-p0'));
    final topRankCardHeight = tester.getSize(topRankCard).height;
    final topRankLeft = tester.getTopLeft(topRankCard).dx;
    final topRankRight = tester.getTopRight(topRankCard).dx;
    expect(topRankCardHeight, lessThan(84));
    expect(topRankLeft, closeTo(0, 0.01));
    expect(topRankRight, closeTo(360, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'default mode keeps connected layout and row tap is interactive',
    (WidgetTester tester) async {
      final players = List<Player>.generate(
        20,
        (index) => player('p$index', name: 'Player $index', elo: 2000 - index),
      );
      String? selectedId;
      await pumpLeaderboard(
        tester,
        state: stateWithPlayers(players),
        onViewProfile: (player) => selectedId = player.id,
      );

      expect(find.byType(CustomScrollView), findsNothing);
      expect(find.text('LEADERBOARD'), findsOneWidget);
      await tester.tap(find.text('Player 0'));
      await tester.pump();
      expect(selectedId, 'p0');
    },
  );
}
