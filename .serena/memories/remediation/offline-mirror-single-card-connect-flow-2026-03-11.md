Implemented a landing-screen local-connect UI refactor to remove multi-card clutter and reduce layout shift.

What changed:
- Added `lib/ui/widgets/offline_mirror_setup_card.dart` as a new stateful widget that consolidates Offline Mirror setup and connection phases into one card.
- Replaced the previous split rendering in `lib/ui/screens/landing_screen.dart`:
  - removed standalone approval banner and separate nearby panel flow
  - now renders only `OfflineMirrorSetupCard` for host/connect/discovery/approval/manage states
- Removed obsolete `LocalPanel` and `_localPhaseText` from `lib/ui/screens/leaderboard_screen.dart` since landing no longer imports them.

Behavior updates:
- Connect flow expands inside the same Offline Mirror card.
- Available nearby devices render within that expanded card after connect/scanning state.
- Approval UI is inline (Accept/Reject only) with no compare-code sentence and no code text.
- `Use DB` remains available in expanded/manage state when local source is active.

Verification performed:
- `flutter test test/ui/landing_screen_test.dart` (pass)
- `flutter test test/ui/responsive_layout_test.dart` (pass)
- `flutter test test/ui/leaderboard_screen_test.dart` (pass)
- `flutter analyze lib/ui/screens/landing_screen.dart lib/ui/widgets/offline_mirror_setup_card.dart lib/ui/screens/leaderboard_screen.dart test/ui/landing_screen_test.dart` (no issues)

Test updates:
- Updated `test/ui/landing_screen_test.dart` expectations to assert no standalone approval/nearby sections and no compare-code copy.
- Added a connect-flow interaction test verifying device list reveal inside the Offline Mirror card.