Implemented always-connected leaderboard presentation and removed visible settings icons.

Behavior changes:
- Leaderboard now always uses connected header/card layout regardless of connection state.
- App shell treats `Screen.leaderboard` as fullscreen unconditionally (header/footer hidden while on leaderboard).
- Removed visible settings icon entry points from shell UI:
  - removed floating settings FAB
  - removed Settings tab from footer
- Kept settings modal logic and back handling intact so a programmatically opened modal still closes via system back.

Code touchpoints:
- `lib/features/leaderboard/leaderboard_screen.dart`
- `lib/features/app_shell/sprint_app_shell.dart`
- `lib/ui/widgets/app_footer.dart`
- Tests updated: `test/ui/leaderboard_screen_test.dart`, `test/ui/sprint_app_shell_test.dart`

Verification:
- Full `flutter test` suite passed.