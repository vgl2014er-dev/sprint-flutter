import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprint/models/app_models.dart';
import 'package:sprint/ui/screens/sprint_app.dart';
import 'package:sprint/ui/theme/app_theme.dart';
import 'package:sprint/ui/theme/sprint_theme_tokens.dart';

Widget _buildLanding({
  required LocalSessionState localSessionState,
  required bool isLocalSource,
  VoidCallback? onConnectLocalDisplay,
}) => MaterialApp(
  theme: buildSprintTheme(Brightness.light),
  darkTheme: buildSprintTheme(Brightness.dark),
  home: Scaffold(
    body: LandingScreen(
      localSessionState: localSessionState,
      isLocalSource: isLocalSource,
      onOpenRandom: () {},
      onOpenElo: () {},
      onStartLocalDisplay: () {},
      onConnectLocalDisplay: onConnectLocalDisplay ?? () {},
      onStopLocalDisplay: () {},
      onUseLocalConnection: () {},
      onUseDatabase: () {},
      onConnectHost: (_) {},
      onDisconnectLocal: () {},
      onAcceptLocalConnection: () {},
      onRejectLocalConnection: () {},
    ),
  ),
);

void main() {
  testWidgets('random matches card uses neutral grey icon chip', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildLanding(
        localSessionState: const LocalSessionState(),
        isLocalSource: false,
      ),
    );

    final chip = tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
    expect(chip.backgroundColor, SprintThemeTokens.light.neutralChip);
  });

  testWidgets('landing action cards use theme card surface', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildLanding(
        localSessionState: const LocalSessionState(),
        isLocalSource: false,
      ),
    );

    final theme = buildSprintTheme(Brightness.light);
    final card = tester.widget<Card>(find.byType(Card).first);
    final cardMaterial = tester.widget<Material>(
      find
          .ancestor(
            of: find.text('Random Matches'),
            matching: find.byType(Material),
          )
          .first,
    );

    expect(card.color, isNull);
    expect(cardMaterial.color, theme.colorScheme.surface);
    expect(card.surfaceTintColor, Colors.transparent);
  });

  testWidgets('offline mirror host button uses outlined style', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildLanding(
        localSessionState: const LocalSessionState(),
        isLocalSource: false,
      ),
    );

    expect(find.widgetWithText(OutlinedButton, 'Host'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Host'), findsNothing);
  });

  testWidgets('shows inline approval actions without separate nearby cards', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildLanding(
        localSessionState: const LocalSessionState(
          role: LocalSessionRole.client,
          phase: LocalSessionPhase.awaitingApproval,
          pendingConnectionName: 'Sprint Device',
          authToken: 'FRJCP',
          discoveredHosts: <DiscoveredHost>[
            DiscoveredHost(endpointId: 'XC13', displayName: 'Sprint Device'),
          ],
        ),
        isLocalSource: true,
      ),
    );

    expect(find.text('Approve Nearby Connection'), findsNothing);
    expect(find.text('Nearby'), findsNothing);
    expect(find.textContaining('Compare code'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, 'Accept'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Reject'), findsOneWidget);
  });

  testWidgets('connect reveals available nearby devices in offline card', (
    WidgetTester tester,
  ) async {
    var localState = const LocalSessionState();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSprintTheme(Brightness.light),
        darkTheme: buildSprintTheme(Brightness.dark),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => LandingScreen(
              localSessionState: localState,
              isLocalSource: false,
              onOpenRandom: () {},
              onOpenElo: () {},
              onStartLocalDisplay: () {},
              onConnectLocalDisplay: () {
                setState(() {
                  localState = const LocalSessionState(
                    role: LocalSessionRole.client,
                    phase: LocalSessionPhase.discovering,
                    discoveredHosts: <DiscoveredHost>[
                      DiscoveredHost(
                        endpointId: 'XC13',
                        displayName: 'Sprint Device',
                      ),
                    ],
                  );
                });
              },
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
      ),
    );

    expect(find.text('Sprint Device'), findsNothing);
    expect(find.text('XC13'), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Connect'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sprint Device'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Connect'), findsOneWidget);
    expect(find.text('XC13'), findsOneWidget);
  });
}
