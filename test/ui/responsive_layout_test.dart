import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprint/models/app_models.dart';
import 'package:sprint/ui/screens/sprint_app.dart';
import 'package:sprint/ui/theme/app_theme.dart';

import '../test_helpers.dart';

void main() {
  const sizes = <Size>[Size(360, 780), Size(900, 1000)];

  testWidgets(
    'landing screen renders without overflow at compact and regular widths',
    (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final size in sizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildSprintTheme(Brightness.light),
            darkTheme: buildSprintTheme(Brightness.dark),
            home: Scaffold(
              body: LandingScreen(
                localSessionState: const LocalSessionState(
                  role: LocalSessionRole.client,
                  phase: LocalSessionPhase.awaitingApproval,
                  discoveredHosts: <DiscoveredHost>[
                    DiscoveredHost(
                      endpointId: 'host-1',
                      displayName: 'Mirror One',
                    ),
                  ],
                  authToken: '1234',
                ),
                isLocalSource: true,
                onOpenRandom: () {},
                onOpenElo: () {},
                onOpenDeathMatch: () {},
                onStartLocalDisplay: () {},
                onConnectLocalDisplay: () {},
                onStopLocalDisplay: () {},
                onUseLocalConnection: () {},
                onUseDatabase: () {},
                onConnectHost: (_) {},
                onDisconnectLocal: () {},
                onAcceptLocalConnection: () {},
                onRejectLocalConnection: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Landing overflow at $size',
        );
      }
    },
  );

  testWidgets(
    'player selection screen renders without overflow at compact and regular widths',
    (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final players = List<Player>.generate(
        12,
        (index) => player('p$index', name: 'Player $index', elo: 1200 + index),
      );

      for (final size in sizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildSprintTheme(Brightness.light),
            darkTheme: buildSprintTheme(Brightness.dark),
            home: Scaffold(
              body: PlayerSelectionScreen(
                title: 'Random Matches',
                isEloMode: true,
                players: players,
                onGenerate: (selectedIds, targetMatches) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'PlayerSelection overflow at $size',
        );
      }
    },
  );

  testWidgets(
    'match runner screen renders without overflow at compact and regular widths',
    (WidgetTester tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = AppState.initial().copyWith(
        screen: Screen.matchRunner,
        roundMatches: <UiRoundMatch>[
          UiRoundMatch(
            id: 'm1',
            player1: player('p1', name: 'Long Name Alpha', elo: 1298),
            player2: player('p2', name: 'Long Name Beta', elo: 1254),
            started: true,
          ),
        ],
      );

      for (final size in sizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildSprintTheme(Brightness.light),
            darkTheme: buildSprintTheme(Brightness.dark),
            home: Scaffold(
              body: MatchRunnerScreen(
                state: state,
                onBack: () {},
                onClose: () {},
                onNextRound: () {},
                onStart: (_) {},
                onResult: (_, result) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'MatchRunner overflow at $size',
        );
      }
    },
  );
}
