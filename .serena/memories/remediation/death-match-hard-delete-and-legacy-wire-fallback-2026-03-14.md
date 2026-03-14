Removed Death Match mode completely from sprint app.

Changes:
- Removed `Screen.deathMatchSelection` and all Death Match AppState fields from `lib/core/models/app_models.dart`.
- Kept backward compatibility by mapping `Screen.fromWire('select-death')` to `Screen.landing`.
- Removed Death Match controller APIs and internals from `lib/features/app_shell/app_shell_controller.dart` (`startDeathMatch`, `resetDeathMatch`, death round generation, bye/lives tracking).
- Simplified match runner and shell routing to standard Random/Elo session flow only.
- Removed Death Match UI entry points and selection surface from landing and app shell.
- Removed `DeathMatchSelectionScreen` from `lib/features/player_selection/player_selection_screen.dart`.
- Deleted `test/ui/death_match_selection_screen_test.dart`.
- Updated impacted tests (`landing_screen_test`, `match_runner_screen_test`, `sprint_controller_test`) and added legacy wire fallback assertion in `test/models/wire_mapping_test.dart`.

Verification:
- Ran full `flutter test` suite successfully (all tests passed).