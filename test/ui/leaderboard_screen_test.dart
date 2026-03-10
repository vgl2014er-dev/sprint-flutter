import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprint/models/app_models.dart';
import 'package:sprint/ui/screens/sprint_app.dart';

import '../test_helpers.dart';

void main() {
  AppState stateWithPlayers(
    List<Player> players, {
    bool readOnlyClient = false,
  }) {
    final localSessionState = readOnlyClient
        ? const LocalSessionState(
            role: LocalSessionRole.client,
            phase: LocalSessionPhase.connected,
          )
        : const LocalSessionState();
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
      state: stateWithPlayers(<Player>[player('p1', name: 'Alpha', elo: 1200)]),
      onViewProfile: (_) {},
    );

    expect(find.text('RANK'), findsOneWidget);
    expect(find.text('PLAYER'), findsOneWidget);
    expect(find.text('ELO'), findsOneWidget);
    expect(find.text('WIN %'), findsOneWidget);
  });

  testWidgets('uses grey header background and white row background', (
    WidgetTester tester,
  ) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[player('p1', name: 'Alpha', elo: 1200)]),
      onViewProfile: (_) {},
    );

    final headerBox = tester.widget<ColoredBox>(
      find
          .ancestor(of: find.text('RANK'), matching: find.byType(ColoredBox))
          .first,
    );
    expect(headerBox.color, const Color(0xFFF1F5F9));

    final rowMaterial = tester.widget<Material>(
      find
          .ancestor(of: find.text('Alpha'), matching: find.byType(Material))
          .first,
    );
    expect(rowMaterial.color, Colors.white);
  });

  testWidgets('does not render top spacer when local source is off', (
    WidgetTester tester,
  ) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[player('p1', name: 'Alpha', elo: 1200)]),
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
      state: stateWithPlayers(<Player>[player('p1', name: 'Alpha', elo: 1200)]),
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
      state: stateWithPlayers(<Player>[player('p1', name: 'Alpha', elo: 1200)]),
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
        player('p1', name: 'Low', elo: 1200),
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
        player('p3', name: 'Three', elo: 1200),
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
        player('p1', name: 'Rate', elo: 1280, wins: 5, losses: 1, draws: 0),
      ]),
      onViewProfile: (_) {},
    );

    expect(find.text('83%'), findsOneWidget);
  });

  testWidgets('uses grey for rank elo win and black for player name', (
    WidgetTester tester,
  ) async {
    await pumpLeaderboard(
      tester,
      state: stateWithPlayers(<Player>[
        player('p1', name: 'P1', elo: 1400, wins: 10, losses: 0, draws: 0),
        player('p2', name: 'P2', elo: 1300, wins: 8, losses: 2, draws: 0),
        player('p3', name: 'P3', elo: 1200, wins: 7, losses: 3, draws: 0),
        player('p4', name: 'Moritz', elo: 1111, wins: 3, losses: 2, draws: 0),
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
        player('p3', name: 'Three', elo: 1200),
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
        player('p1', name: 'Lion', elo: 1286, wins: 10, losses: 0, draws: 0),
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
        player('p1', name: 'Tapper', elo: 1200),
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
        player('p1', name: 'ReadOnly', elo: 1200),
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
        player('p1', name: longName, elo: 1200),
      ]),
      onViewProfile: (_) {},
    );

    final text = tester.widget<Text>(find.text(longName));
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });
}
