Implemented visual-first parity pass for PWA->Flutter in sprint app.

Scope delivered:
- AppState expanded with isSettingsOpen, remoteSyncEnabled, useClientAudio, manualFullscreenEnabled.
- SprintRepository interface expanded with runtime sync toggles/streams + persisted useClientAudio/manualFullscreen + local/cloud reset and seed actions.
- SprintRepositoryImpl now supports runtime remote sync enable/disable, listener attach/detach, cloud write suppression when sync off, and persistence of new settings in DB+SharedPreferences.
- SprintController gained settings modal actions, remote sync/client audio/fullscreen toggles, local/cloud data actions, system back policy handler, and start-match client-audio control send gating.
- Local session transition parity: client connect forces leaderboard/local source and closes settings; client disconnect forces landing/db source and closes settings.
- Immersive mode logic combines connected-client fullscreen and manual fullscreen preference.
- Platform adapter extended with local control event stream + sendStartMatchBeepControl method.
- Android Nearby protocol extended to typed envelope payloads (snapshot + control:start_match_beep) with new decode model, host sendControl, client control event flow, and bridge method/event wiring.
- Sprint app shell refactored to modal-style settings UX with backdrop/close/floating settings FAB/footer settings opening modal, plus back handling policy order and client control-beep playback subscription.
- Leaderboard connected mode layout ported with dynamic fullWidthCount, connected full/half card heights, and FittedBox fallback scaling. Added connected full/half card keys for deterministic tests.
- AGENTS.md updated with requested context-mode performance section values.

Testing changes:
- Added/updated tests in sprint_app_shell_test.dart, leaderboard_screen_test.dart, sprint_controller_test.dart, sprint_repository_impl_test.dart, platform_channels_test.dart for new parity behavior.

Verification:
- Targeted suite pass:
  flutter test test/ui/sprint_app_shell_test.dart test/ui/leaderboard_screen_test.dart test/state/sprint_controller_test.dart test/data/sprint_repository_impl_test.dart test/platform/platform_channels_test.dart
- Full flutter test currently has unrelated pre-existing UI expectation failures in landing/match_runner tests (outside this parity scope).