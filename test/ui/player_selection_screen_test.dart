import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprint/models/app_models.dart';
import 'package:sprint/ui/screens/sprint_app.dart';

import '../test_helpers.dart';

void main() {
  testWidgets(
    'shows target picker defaulting to 3 and passes target on generate',
    (WidgetTester tester) async {
      Set<String>? generatedIds;
      int? generatedTarget;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerSelectionScreen(
              title: 'Random Matches',
              isEloMode: false,
              players: <Player>[
                player('p1', name: 'Alpha'),
                player('p2', name: 'Beta'),
              ],
              onGenerate: (ids, target) {
                generatedIds = ids;
                generatedTarget = target;
              },
            ),
          ),
        ),
      );

      expect(find.text('Target per player'), findsOneWidget);
      expect(find.byKey(const Key('standard-target-value')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byKey(const Key('standard-target-increase')));
      await tester.pump();

      expect(find.text('4'), findsOneWidget);

      await tester.ensureVisible(find.text('Generate Matches'));
      await tester.tap(find.text('Generate Matches'));
      await tester.pump();

      expect(generatedIds, isNotNull);
      expect(generatedIds!.length, 2);
      expect(generatedTarget, 4);
    },
  );
}
