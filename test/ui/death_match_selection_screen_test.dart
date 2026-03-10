import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprint/models/app_models.dart';
import 'package:sprint/ui/screens/sprint_app.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('death match selection uses unified player selection look', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeathMatchSelectionScreen(
            players: <Player>[
              player('p1', name: 'Alpha'),
              player('p2', name: 'Beta'),
            ],
            deathMatchInProgress: false,
            deathMatchLives: 2,
            deathMatchChampionId: null,
            deathMatchParticipantIds: const <String>[],
            deathMatchPairingStrategy: PairingStrategy.random,
            deathMatchLossesByPlayerId: const <String, int>{},
            onStart: (_, _, _) {},
            onReset: () {},
            onResume: () {},
          ),
        ),
      ),
    );

    expect(find.text('2 / 2 selected'), findsOneWidget);
    expect(find.text('Select All'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    final alphaCard = tester.widget<Card>(
      find.ancestor(of: find.text('Alpha'), matching: find.byType(Card)).first,
    );
    expect(alphaCard.color, const Color(0xFFE2E8F0));
  });
}
