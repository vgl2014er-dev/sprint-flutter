import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprint/models/app_models.dart';
import 'package:sprint/ui/screens/sprint_app.dart';

import '../test_helpers.dart';

void main() {
  AppState buildState(
    List<UiRoundMatch> matches, {
    int currentIndex = 0,
    bool standardSession = false,
    List<String>? participantIds,
    int targetMatchesPerPlayer = 3,
    Map<String, int>? completedByPlayerId,
    Map<String, int>? scheduledByPlayerId,
    bool deathMatch = false,
  }) {
    return AppState.initial().copyWith(
      screen: Screen.matchRunner,
      roundMatches: matches,
      currentMatchIndex: currentIndex,
      deathMatchInProgress: deathMatch,
      standardSessionStrategy: standardSession ? PairingStrategy.random : null,
      clearStandardSessionStrategy: !standardSession,
      standardSessionParticipantIds: standardSession
          ? (participantIds ??
                matches
                    .expand(
                      (match) => <String>[match.player1.id, match.player2.id],
                    )
                    .toSet()
                    .toList(growable: false))
          : const <String>[],
      standardSessionTargetMatchesPerPlayer: standardSession
          ? targetMatchesPerPlayer
          : 3,
      standardSessionCompletedMatchesByPlayerId: standardSession
          ? (completedByPlayerId ?? const <String, int>{})
          : const <String, int>{},
      standardSessionScheduledMatchesByPlayerId: standardSession
          ? (scheduledByPlayerId ?? const <String, int>{})
          : const <String, int>{},
    );
  }

  Widget buildSubject(AppState state, {VoidCallback? onNextRound}) {
    return MaterialApp(
      home: Scaffold(
        body: MatchRunnerScreen(
          state: state,
          onBack: () {},
          onClose: () {},
          onNextRound: onNextRound ?? () {},
          onStart: (_) {},
          onResult: (_, _) {},
        ),
      ),
    );
  }

  testWidgets('shows only START before match begins', (
    WidgetTester tester,
  ) async {
    final match = UiRoundMatch(
      id: 'm1',
      player1: player('p1', name: 'Alice', elo: 1210),
      player2: player('p2', name: 'Bob', elo: 1190),
      started: false,
      played: false,
    );

    await tester.pumpWidget(buildSubject(buildState(<UiRoundMatch>[match])));

    expect(find.widgetWithText(ElevatedButton, 'START'), findsOneWidget);
    expect(find.text('ALICE WINS'), findsNothing);
    expect(find.text('BOB WINS'), findsNothing);
    expect(find.text('DRAW'), findsNothing);
  });

  testWidgets('shows result choices and hides START after match begins', (
    WidgetTester tester,
  ) async {
    final match = UiRoundMatch(
      id: 'm1',
      player1: player('p1', name: 'Alice', elo: 1210),
      player2: player('p2', name: 'Bob', elo: 1190),
      started: true,
      played: false,
    );

    await tester.pumpWidget(buildSubject(buildState(<UiRoundMatch>[match])));

    expect(find.widgetWithText(ElevatedButton, 'START'), findsNothing);
    expect(find.text('ALICE WINS'), findsOneWidget);
    expect(find.text('BOB WINS'), findsOneWidget);
    expect(find.text('DRAW'), findsOneWidget);
  });

  testWidgets('returns to START-only view for next unstarted match', (
    WidgetTester tester,
  ) async {
    final firstMatch = UiRoundMatch(
      id: 'm1',
      player1: player('p1', name: 'Alice'),
      player2: player('p2', name: 'Bob'),
      started: true,
      played: true,
      winnerId: 'p1',
    );
    final secondMatch = UiRoundMatch(
      id: 'm2',
      player1: player('p3', name: 'Chris'),
      player2: player('p4', name: 'Drew'),
      started: false,
      played: false,
    );

    await tester.pumpWidget(
      buildSubject(
        buildState(<UiRoundMatch>[firstMatch, secondMatch], currentIndex: 1),
      ),
    );

    expect(find.widgetWithText(ElevatedButton, 'START'), findsOneWidget);
    expect(find.text('CHRIS WINS'), findsNothing);
    expect(find.text('DREW WINS'), findsNothing);
    expect(find.text('DRAW'), findsNothing);
  });

  testWidgets('centers START button in match card before begin', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final match = UiRoundMatch(
      id: 'm1',
      player1: player('p1', name: 'Alice'),
      player2: player('p2', name: 'Bob'),
      started: false,
      played: false,
    );

    await tester.pumpWidget(buildSubject(buildState(<UiRoundMatch>[match])));

    final cardRect = tester.getRect(find.byType(Card).first);
    final startCenter = tester.getCenter(
      find.widgetWithText(ElevatedButton, 'START'),
    );

    expect((startCenter.dx - cardRect.center.dx).abs(), lessThan(48));
    expect((startCenter.dy - cardRect.center.dy).abs(), lessThan(64));
  });

  testWidgets('uses a much larger START button', (WidgetTester tester) async {
    final match = UiRoundMatch(
      id: 'm1',
      player1: player('p1', name: 'Alice'),
      player2: player('p2', name: 'Bob'),
      started: false,
      played: false,
    );

    await tester.pumpWidget(buildSubject(buildState(<UiRoundMatch>[match])));

    final size = tester.getSize(find.widgetWithText(ElevatedButton, 'START'));
    expect(size.height, greaterThanOrEqualTo(100));
  });

  testWidgets('uses much larger result buttons', (WidgetTester tester) async {
    final match = UiRoundMatch(
      id: 'm1',
      player1: player('p1', name: 'Alice', elo: 1210),
      player2: player('p2', name: 'Bob', elo: 1190),
      started: true,
      played: false,
    );

    await tester.pumpWidget(buildSubject(buildState(<UiRoundMatch>[match])));

    final size = tester.getSize(
      find.widgetWithText(FilledButton, 'ALICE WINS'),
    );
    expect(size.height, greaterThanOrEqualTo(110));
  });

  testWidgets('shows queue progress as Match X of Y', (
    WidgetTester tester,
  ) async {
    final matches = <UiRoundMatch>[
      UiRoundMatch(
        id: 'm1',
        player1: player('p1', name: 'Alice'),
        player2: player('p2', name: 'Bob'),
        started: true,
        played: true,
        winnerId: 'p1',
      ),
      UiRoundMatch(
        id: 'm2',
        player1: player('p3', name: 'Chris'),
        player2: player('p4', name: 'Drew'),
        started: false,
        played: false,
      ),
      UiRoundMatch(
        id: 'm3',
        player1: player('p5', name: 'Eve'),
        player2: player('p6', name: 'Finn'),
        started: false,
        played: false,
      ),
    ];

    await tester.pumpWidget(
      buildSubject(buildState(matches, currentIndex: 1, standardSession: true)),
    );

    expect(find.text('Match 2 of 3'), findsOneWidget);
  });

  testWidgets('shows current-pair contribution progress in standard session', (
    WidgetTester tester,
  ) async {
    final match = UiRoundMatch(
      id: 'm1',
      player1: player('p1', name: 'Alice', elo: 1210),
      player2: player('p2', name: 'Bob', elo: 1190),
      started: true,
      played: false,
    );

    await tester.pumpWidget(
      buildSubject(
        buildState(
          <UiRoundMatch>[match],
          standardSession: true,
          participantIds: const <String>['p1', 'p2'],
          targetMatchesPerPlayer: 3,
          completedByPlayerId: const <String, int>{'p1': 1, 'p2': 2},
          scheduledByPlayerId: const <String, int>{'p1': 3, 'p2': 3},
        ),
      ),
    );

    expect(find.textContaining('Elo: 1210'), findsOneWidget);
    expect(find.textContaining('1/3'), findsOneWidget);
    expect(find.textContaining('Elo: 1190'), findsOneWidget);
    expect(find.textContaining('2/3'), findsOneWidget);
  });

  testWidgets('shows standard session complete state without auto-next', (
    WidgetTester tester,
  ) async {
    var nextRoundCalls = 0;
    final match = UiRoundMatch(
      id: 'm1',
      player1: player('p1', name: 'Alice'),
      player2: player('p2', name: 'Bob'),
      started: true,
      played: true,
      winnerId: 'p1',
    );

    await tester.pumpWidget(
      buildSubject(
        buildState(
          <UiRoundMatch>[match],
          standardSession: true,
          participantIds: const <String>['p1', 'p2'],
          targetMatchesPerPlayer: 1,
          completedByPlayerId: const <String, int>{'p1': 1, 'p2': 1},
          scheduledByPlayerId: const <String, int>{'p1': 1, 'p2': 1},
        ),
        onNextRound: () => nextRoundCalls += 1,
      ),
    );
    await tester.pump();

    expect(find.text('Session complete'), findsOneWidget);
    expect(
      find.textContaining('All scheduled matches are finished'),
      findsOneWidget,
    );
    expect(nextRoundCalls, 0);
  });

  testWidgets('death match still auto-advances when all matches are played', (
    WidgetTester tester,
  ) async {
    var nextRoundCalls = 0;
    final match = UiRoundMatch(
      id: 'm1',
      player1: player('p1', name: 'Alice'),
      player2: player('p2', name: 'Bob'),
      started: true,
      played: true,
      winnerId: 'p1',
    );

    await tester.pumpWidget(
      buildSubject(
        buildState(<UiRoundMatch>[match], deathMatch: true),
        onNextRound: () => nextRoundCalls += 1,
      ),
    );
    await tester.pump();

    expect(nextRoundCalls, greaterThanOrEqualTo(1));
  });
}
