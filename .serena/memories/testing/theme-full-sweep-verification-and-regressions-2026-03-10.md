Theme full sweep verification results (2026-03-10):

Commands executed successfully in worktree:
- flutter pub get
- dart format lib test
- flutter analyze
- flutter test
- flutter test test/ui test/state test/data

Added regression tests:
- test/ui/sprint_app_shell_test.dart
  - validates header theme toggle render + interaction
  - validates coexistence of theme toggle and leaderboard reset action
- test/ui/responsive_layout_test.dart
  - validates compact + regular layout rendering without overflow for landing, player selection, match runner

Updated UI assertions:
- landing and leaderboard tests now assert theme/token-derived surfaces instead of previous hardcoded white assumptions.

Known non-fatal warning:
- Drift emits debug warning about multiple AppDatabase instances in repository tests; test suite remains passing.