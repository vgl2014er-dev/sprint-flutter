Applied high+moderate optimization items from connected-only performance report.

Code changes:
- lib/data/local/app_database.dart
  - Added deletePlayersExceptIds(List<String>) and deleteHistoryExceptIds(List<String>) for targeted pruning.
- lib/data/repository/sprint_repository_impl.dart
  - submitRoundResults now upserts changed players + inserted history only, caps history, then prunes by retained IDs.
  - deleteMatch now upserts reverted players and deletes one history entry without clearing/reinserting all players.
  - Firebase ingest listeners now upsert + deleteExceptIds instead of clear-and-reinsert.
- lib/ui/screens/match_runner_screen.dart
  - Added _HeadToHeadWinRateCache to memoize H2H pair win rates per history snapshot.
- lib/ui/screens/leaderboard_screen.dart
  - Added _LeaderboardDerivedCache to cache sorted players/latest-match highlight+delta derivation per players/history snapshot.
- lib/state/sprint_controller.dart
  - Added connected-session remote-sync policy:
    - auto-suspend remote sync when entering connected session if currently enabled,
    - restore on disconnect only when auto-suspended,
    - user override while connected disables auto-restore.
- lib/ui/screens/sprint_app_shell.dart
  - Narrowed rebuild scope by introducing shell-level selector projection (_ShellState) and settings-modal projection (_SettingsModalState).
  - Screen bodies now use Consumer subtrees/selectors so top-level shell no longer depends on full AppState updates.

Tests:
- Added controller tests:
  - auto-suspends remote sync while connected and restores on disconnect
  - does not auto-restore after explicit override while connected

Verification:
- Targeted suites passed:
  - test/ui/sprint_app_shell_test.dart
  - test/ui/leaderboard_screen_test.dart
  - test/state/sprint_controller_test.dart
  - test/data/sprint_repository_impl_test.dart
  - test/platform/platform_channels_test.dart
- Full flutter test run still has existing UI test failures outside this patch surface:
  - test/ui/landing_screen_test.dart (multiple expectations)
  - test/ui/match_runner_screen_test.dart (FilledButton expectation)

AGENTS.md update:
- Added Follow-up Session entry with ctx_stats:
  - savings 1.2x (16%), total calls 31, breakdown ctx_batch_execute=1/ctx_execute=9/ctx_execute_file=17/ctx_search=0/ctx_stats=4, totals 196.5KB processed / 32.1KB sandboxed / 164.4KB entered context.