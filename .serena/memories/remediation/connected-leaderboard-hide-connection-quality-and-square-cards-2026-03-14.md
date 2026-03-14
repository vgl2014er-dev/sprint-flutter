Implemented connected-view visual tweaks requested by user.

Files changed:
- lib/ui/screens/leaderboard_screen.dart
- test/ui/leaderboard_screen_test.dart

Behavior changes:
1) Removed connection quality badge (e.g. WiFi/BLE) from the connected leaderboard header only.
   - Non-connected leaderboard header behavior remains unchanged.
2) Connected leaderboard cards now have square outer corners (radius 0).
   - Applied to connected card container border radius, top-rank scan ClipRRect radius, and InkWell splash radius.
   - Non-connected leaderboard cards keep the existing rounded corners.

Tests:
- Updated connected header test to assert WiFi label is not shown in connected mode.
- Added test: connected cards are square while default cards stay rounded.

Verification:
- flutter test test/ui/leaderboard_screen_test.dart
- flutter test test/ui/sprint_app_shell_test.dart test/state/sprint_controller_test.dart test/platform/platform_channels_test.dart
All passed.