Fixed remaining auto-connect parity gap where Flutter still showed Accept/Reject despite auto-connect.

Root cause:
- In `LocalLeaderboardConnectionManager.onConnectionInitiated`, state was always set to `AWAITING_APPROVAL`.
- Auto-accept was only triggered for host role, so client could still require manual accept.

Change made:
- File: `android/app/src/main/kotlin/elo/flutter/nearby/LocalLeaderboardConnectionManager.kt`
- Added `autoAcceptEnabled` in `onConnectionInitiated`.
- When auto-connect is enabled:
  - session phase now stays `CONNECTING` (no `AWAITING_APPROVAL` emission),
  - `acceptPendingConnection()` is called for both roles.
- This removes the visible accept step in Flutter under auto-connect mode.

Verification:
- `flutter test test/ui/sprint_app_shell_test.dart test/state/sprint_controller_test.dart test/platform/platform_channels_test.dart` passed.
- A wider run that included `landing_screen_test.dart` showed existing unrelated failures in that suite.