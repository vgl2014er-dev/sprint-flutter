import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprint/models/app_models.dart';
import 'package:sprint/ui/screens/sprint_app.dart';
import 'package:sprint/ui/theme/app_theme.dart';
import 'package:sprint/ui/theme/sprint_theme_tokens.dart';

import '../test_helpers.dart';

void main() {
  AppState stateWithPlayers(
    List<Player> players, {
    bool readOnlyClient = false,
    List<MatchHistoryEntry> history = const <MatchHistoryEntry>[],
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
      history: history,
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

  testWidgets('renders table headers', (WidgetTester tester) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[player('p1', name: 'Alpha')]),
      onViewProfile: (_) {},
    );

    expect(find.text('RANK'), findsOneWidget);
    expect(find.text('PLAYER'), findsOneWidget);
    expect(find.text('ELO'), findsOneWidget);
    expect(find.text('WIN %'), findsOneWidget);
  });

  testWidgets('shows connected transport badge in leaderboard header', (
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

    expect(find.text('WiFi'), findsOneWidget);
  });

  testWidgets('hides transport badge when not connected', (
    WidgetTester tester,
  ) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(
        <Player>[player('p1', name: 'Alpha')],
        localSessionStateOverride: const LocalSessionState(
          role: LocalSessionRole.client,
          phase: LocalSessionPhase.disconnected,
          connectionMedium: LocalConnectionMedium.wifi,
        ),
      ),
      onViewProfile: (_) {},
    );

    expect(find.text('WiFi'), findsNothing);
  });

  testWidgets('uses token header background and theme row background', (
    WidgetTester tester,
  ) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[player('p1', name: 'Alpha')]),
      onViewProfile: (_) {},
    );

    final headerBox = tester.widget<ColoredBox>(
      find
          .ancestor(of: find.text('RANK'), matching: find.byType(ColoredBox))
          .first,
    );
    expect(headerBox.color, SprintThemeTokens.light.shellBackground);

    final rowMaterial = tester.widget<Material>(
      find
          .ancestor(of: find.text('Alpha'), matching: find.byType(Material))
          .first,
    );
    expect(
      rowMaterial.color,
      buildSprintTheme(Brightness.light).colorScheme.surface,
    );
  });

  testWidgets('does not render top spacer when local source is off', (
    WidgetTester tester,
  ) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[player('p1', name: 'Alpha')]),
      onViewProfile: (_) {},
    );

    final rankTop = tester.getTopLeft(find.text('RANK')).dy;
    expect(rankTop, lessThan(14));
  });

  testWidgets('uses zero list padding to avoid fullscreen top inset gaps', (
    WidgetTester tester,
  ) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[player('p1', name: 'Alpha')]),
      onViewProfile: (_) {},
    );

    final listView = tester.widget<ListView>(find.byType(ListView));
    expect(listView.padding, EdgeInsets.zero);
  });

  testWidgets('removes inherited top media padding from leaderboard rows', (
    WidgetTester tester,
  ) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[player('p1', name: 'Alpha')]),
      onViewProfile: (_) {},
      mediaPadding: const EdgeInsets.only(top: 96),
    );

    final headerTop = tester.getTopLeft(find.text('RANK')).dy;
    final firstRowTop = tester.getTopLeft(find.text('Alpha')).dy;

    expect(firstRowTop - headerTop, lessThan(120));
  });

  testWidgets('sorts rows by Elo descending', (WidgetTester tester) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[
        player('p1', name: 'Low'),
        player('p2', name: 'High', elo: 1300),
        player('p3', name: 'Mid', elo: 1250),
      ]),
      onViewProfile: (_) {},
    );

    final highY = tester.getTopLeft(find.text('High')).dy;
    final midY = tester.getTopLeft(find.text('Mid')).dy;
    final lowY = tester.getTopLeft(find.text('Low')).dy;

    expect(highY, lessThan(midY));
    expect(midY, lessThan(lowY));
  });

  testWidgets('shows medal icons for top three and numeric rank afterward', (
    WidgetTester tester,
  ) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[
        player('p1', name: 'One', elo: 1400),
        player('p2', name: 'Two', elo: 1300),
        player('p3', name: 'Three'),
        player('p4', name: 'Four', elo: 1100),
      ]),
      onViewProfile: (_) {},
    );

    expect(find.byIcon(Icons.workspace_premium_rounded), findsNWidgets(3));
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('shows computed win rate percentage', (
    WidgetTester tester,
  ) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[
        player('p1', name: 'Rate', elo: 1280, wins: 5, losses: 1),
      ]),
      onViewProfile: (_) {},
    );

    expect(find.text('83%'), findsOneWidget);
  });

  testWidgets('uses newest timestamp match for delta and highlights', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpLeaderboard(
        tester,
        state: stateWithPlayers(
          <Player>[
            player('p1', name: 'Alpha', elo: 1210),
            player('p2', name: 'Bravo', elo: 1250),
            player('p3', name: 'Charlie', elo: 1180),
          ],
          history: <MatchHistoryEntry>[
            historyEntry(
              id: 'm-old',
              p1Id: 'p1',
              p2Id: 'p2',
              p1Name: 'Alpha',
              p2Name: 'Bravo',
              p1EloBefore: 1200,
              p2EloBefore: 1260,
              p1EloAfter: 1210,
              p2EloAfter: 1250,
              result: MatchResult.p1,
              timestamp: 100,
            ),
            historyEntry(
              id: 'm-latest',
              p1Id: 'p2',
              p2Id: 'p3',
              p1Name: 'Bravo',
              p2Name: 'Charlie',
              p1EloBefore: 1245,
              p2EloBefore: 1185,
              p1EloAfter: 1250,
              p2EloAfter: 1180,
              result: MatchResult.p1,
              timestamp: 200,
            ),
            historyEntry(
              id: 'm-mid',
              p1Id: 'p1',
              p2Id: 'p3',
              p1Name: 'Alpha',
              p2Name: 'Charlie',
              p1EloBefore: 1200,
              p2EloBefore: 1190,
              p1EloAfter: 1210,
              p2EloAfter: 1180,
              result: MatchResult.p1,
              timestamp: 150,
            ),
          ],
        ),
        onViewProfile: (_) {},
      );

      expect(
        find.byKey(const Key('leaderboard-highlight-row-p2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('leaderboard-highlight-row-p3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('leaderboard-highlight-row-p1')),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel('leaderboard_highlight_row_p2'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('leaderboard_highlight_row_p3'),
        findsOneWidget,
      );

      final p2Delta = find.byKey(const Key('leaderboard-elo-delta-p2'));
      final p3Delta = find.byKey(const Key('leaderboard-elo-delta-p3'));
      expect(p2Delta, findsOneWidget);
      expect(p3Delta, findsOneWidget);
      expect(
        find.bySemanticsLabel('leaderboard_elo_delta_p2_positive_5'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('leaderboard_elo_delta_p3_negative_5'),
        findsOneWidget,
      );
      expect(
        find.descendant(of: p2Delta, matching: find.text('+5')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: p3Delta, matching: find.text('-5')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: p2Delta,
          matching: find.byIcon(Icons.arrow_upward_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: p3Delta,
          matching: find.byIcon(Icons.arrow_downward_rounded),
        ),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('shows neutral zero delta without direction arrow', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpLeaderboard(
        tester,
        state: stateWithPlayers(
          <Player>[
            player('p1', name: 'Zero One'),
            player('p2', name: 'Zero Two'),
          ],
          history: <MatchHistoryEntry>[
            historyEntry(
              id: 'm-zero',
              p1Id: 'p1',
              p2Id: 'p2',
              p1Name: 'Zero One',
              p2Name: 'Zero Two',
              p1EloBefore: 1200,
              p2EloBefore: 1200,
              p1EloAfter: 1200,
              p2EloAfter: 1200,
              result: MatchResult.draw,
              timestamp: 300,
            ),
          ],
        ),
        onViewProfile: (_) {},
      );

      final p1Delta = find.byKey(const Key('leaderboard-elo-delta-p1'));
      final p2Delta = find.byKey(const Key('leaderboard-elo-delta-p2'));
      expect(p1Delta, findsOneWidget);
      expect(p2Delta, findsOneWidget);
      expect(
        find.bySemanticsLabel('leaderboard_elo_delta_p1_neutral_0'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('leaderboard_elo_delta_p2_neutral_0'),
        findsOneWidget,
      );
      expect(
        find.descendant(of: p1Delta, matching: find.text('0')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: p2Delta, matching: find.text('0')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: p1Delta,
          matching: find.byIcon(Icons.arrow_upward_rounded),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: p1Delta,
          matching: find.byIcon(Icons.arrow_downward_rounded),
        ),
        findsNothing,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'forces connected-display layout to fit players without scrolling',
    (WidgetTester tester) async {
      const size = Size(360, 420);
      final manyPlayers = List<Player>.generate(
        24,
        (index) => player('p$index', name: 'P$index', elo: 2000 - index),
      );
      await pumpLeaderboard(
        tester,
        size: size,
        state: stateWithPlayers(manyPlayers, readOnlyClient: true),
        onViewProfile: (_) {},
      );

      expect(find.byType(ListView), findsNothing);
      expect(find.byType(FittedBox), findsOneWidget);
      final lastBottom = tester.getBottomLeft(find.text('P23')).dy;
      final viewportHeight = tester.getSize(find.byType(Scaffold)).height;
      expect(lastBottom, lessThanOrEqualTo(viewportHeight));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps default leaderboard mode scrollable', (
    WidgetTester tester,
  ) async {
    final players = List<Player>.generate(
      24,
      (index) => player('p$index', name: 'Player $index', elo: 2000 - index),
    );
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(players),
      onViewProfile: (_) {},
    );

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(FittedBox), findsNothing);
  });

  testWidgets('uses grey for rank elo win and black for player name', (
    WidgetTester tester,
  ) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[
        player('p1', name: 'P1', elo: 1400, wins: 10),
        player('p2', name: 'P2', elo: 1300, wins: 8, losses: 2),
        player('p3', name: 'P3', wins: 7, losses: 3),
        player('p4', name: 'Moritz', elo: 1111, wins: 3, losses: 2),
      ]),
      onViewProfile: (_) {},
    );

    const valueGrey = Color(0xFF64748B);
    const playerBlack = Color(0xFF111827);

    final rankText = tester.widgetList<Text>(find.text('4')).first;
    final nameText = tester.widget<Text>(find.text('Moritz'));
    final eloText = tester.widget<Text>(find.text('1111'));
    final winText = tester.widget<Text>(find.text('60%'));

    expect(rankText.style?.color, valueGrey);
    expect(nameText.style?.color, playerBlack);
    expect(eloText.style?.color, valueGrey);
    expect(winText.style?.color, valueGrey);
  });

  testWidgets('keeps medal and numeric ranks left-aligned in rank column', (
    WidgetTester tester,
  ) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[
        player('p1', name: 'One', elo: 1400),
        player('p2', name: 'Two', elo: 1300),
        player('p3', name: 'Three'),
        player('p4', name: 'Four', elo: 1100),
      ]),
      onViewProfile: (_) {},
    );

    final firstMedalLeftX = tester
        .getTopLeft(find.byIcon(Icons.workspace_premium_rounded).first)
        .dx;
    final rankFourLeftX = tester.getTopLeft(find.text('4')).dx;
    final rankHeaderLeftX = tester.getTopLeft(find.text('RANK')).dx;

    expect((firstMedalLeftX - rankHeaderLeftX).abs(), lessThanOrEqualTo(10));
    expect((rankFourLeftX - rankHeaderLeftX).abs(), lessThanOrEqualTo(10));
  });

  testWidgets('keeps player name size balanced with elo and win columns', (
    WidgetTester tester,
  ) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[
        player('p1', name: 'Lion', elo: 1286, wins: 10),
      ]),
      onViewProfile: (_) {},
    );

    final nameText = tester.widget<Text>(find.text('Lion'));
    final eloText = tester.widget<Text>(find.text('1286'));
    final winText = tester.widget<Text>(find.text('100%'));
    final nameSize = nameText.style?.fontSize;
    final eloSize = eloText.style?.fontSize;
    final winSize = winText.style?.fontSize;

    expect(nameSize, isNotNull);
    expect(eloSize, isNotNull);
    expect(winSize, isNotNull);
    expect(nameSize!, lessThanOrEqualTo(20));
    expect(nameSize, lessThanOrEqualTo(eloSize! + 2));
    expect(nameSize, lessThanOrEqualTo(winSize! + 2));
  });

  testWidgets('tapping row opens profile when interactive', (
    WidgetTester tester,
  ) async {
    String? selectedId;
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[
        player('p1', name: 'Tapper'),
      ]),
      onViewProfile: (player) => selectedId = player.id,
    );

    await tester.tap(find.text('Tapper'));
    await tester.pump();

    expect(selectedId, 'p1');
  });

  testWidgets('row tap is disabled in read-only client mode', (
    WidgetTester tester,
  ) async {
    String? selectedId;
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[
        player('p1', name: 'ReadOnly'),
      ], readOnlyClient: true),
      onViewProfile: (player) => selectedId = player.id,
    );

    await tester.tap(find.text('ReadOnly'));
    await tester.pump();

    expect(selectedId, isNull);
  });

  testWidgets('keeps long names from overflowing on narrow width', (
    WidgetTester tester,
  ) async {
    const longName = 'A very very very very long player name for leaderboard';
    await pumpLeaderboard(
      tester,
      size: const Size(280, 700),
      state: stateWithPlayers(<Player>[
        player('p1', name: longName),
      ]),
      onViewProfile: (_) {},
    );

    final text = tester.widget<Text>(find.text(longName));
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
