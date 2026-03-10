import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprint/models/app_models.dart';
import 'package:sprint/ui/screens/sprint_app.dart';

void main() {
  testWidgets('random matches card uses neutral grey icon chip', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LandingScreen(
            localSessionState: const LocalSessionState(),
            isLocalSource: false,
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

    final chip = tester.widget<CircleAvatar>(find.byType(CircleAvatar).first);
    expect(chip.backgroundColor, const Color(0xFFE5E7EB));
  });

  testWidgets('landing action cards have white background', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LandingScreen(
            localSessionState: const LocalSessionState(),
            isLocalSource: false,
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

    final card = tester.widget<Card>(find.byType(Card).first);
    expect(card.color, Colors.white);
    expect(card.surfaceTintColor, Colors.transparent);
  });

  testWidgets('offline mirror host button uses outlined style', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LandingScreen(
            localSessionState: const LocalSessionState(),
            isLocalSource: false,
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

    expect(find.widgetWithText(OutlinedButton, 'Host'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Host'), findsNothing);
  });

  testWidgets('shows nearby connect setup and approval on landing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LandingScreen(
            localSessionState: const LocalSessionState(
              role: LocalSessionRole.client,
              phase: LocalSessionPhase.awaitingApproval,
              pendingConnectionName: 'Sprint Device',
              authToken: 'FRJCP',
              discoveredHosts: <DiscoveredHost>[
                DiscoveredHost(
                  endpointId: 'XC13',
                  displayName: 'Sprint Device',
                ),
              ],
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

    expect(find.text('Approve Nearby Connection'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Nearby'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Connect'), findsOneWidget);
    expect(find.text('XC13'), findsOneWidget);
  });
}
