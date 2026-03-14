Addressed two connected-leaderboard parity issues raised by user: side gutters and missing PWA header.

Files changed:
- lib/ui/screens/leaderboard_screen.dart
- test/ui/leaderboard_screen_test.dart

What changed:
1) Added connected-mode PWA header block in Flutter (`_ConnectedLeaderboardHeader`):
   - LEADERBOARD title,
   - SEASON 04 • GLOBAL RANKINGS subtitle,
   - retained connected transport badge support.
2) Removed global connected-layout `FittedBox` width scaling, which caused visible side gutters in connected view.
3) Kept PWA-style dynamic full/half split and continuous connected card-height scaling.
4) Added border-height compensation when computing connected row heights.
5) Added per-row internal `FittedBox(scaleDown)` so very small connected row heights do not overflow while preserving full-width card layout.

Tests updated:
- Added connected header parity test.
- Updated larger-player connected scaling test to validate no global width shrink (left/right edges stay full width) and scaled-down height.

Verification:
- `flutter test test/ui/leaderboard_screen_test.dart` passed.
- `flutter test test/ui/sprint_app_shell_test.dart test/state/sprint_controller_test.dart test/platform/platform_channels_test.dart` passed.