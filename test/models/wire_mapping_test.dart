import 'package:flutter_test/flutter_test.dart';
import 'package:sprint/models/app_models.dart';

void main() {
  test('screen wire values round-trip', () {
    for (final screen in Screen.values) {
      expect(Screen.fromWire(screen.toWire()), screen);
    }
  });

  test('pairing strategy wire values round-trip', () {
    for (final strategy in PairingStrategy.values) {
      expect(PairingStrategy.fromWire(strategy.toWire()), strategy);
    }
  });

  test('leaderboard source wire values round-trip', () {
    for (final source in LeaderboardSource.values) {
      expect(LeaderboardSource.fromWire(source.toWire()), source);
    }
  });

  test('local connection medium wire values round-trip', () {
    for (final medium in LocalConnectionMedium.values) {
      expect(LocalConnectionMedium.fromWire(medium.toWire()), medium);
    }
  });
}
