Implemented balanced feature-first architecture shift while preserving behavior via compatibility exports.

Key structural changes:
- Added AGENTS.md section 'Agentic Feature Locality Rule' with:
  - lib/features/<feature> structure,
  - screen+controller default,
  - shared models/repos in lib/core,
  - no domain/usecases for new work,
  - <=1200 feature-folder budget (manual review),
  - explicit app_shell exception policy and PR checklist line-budget requirement.
- Added Follow-up ctx_stats entry to AGENTS.md for this session.

Canonical runtime paths moved to feature/core:
- main.dart now imports lib/features/app_shell/sprint_app.dart.
- Sprint controller moved to lib/features/app_shell/app_shell_controller.dart.
- App shell moved to lib/features/app_shell/sprint_app_shell.dart.
- Screens moved to feature folders:
  - landing, leaderboard, match_runner, player_selection, player_profile, player_list, settings.
- Shared models moved to lib/core/models/app_models.dart.
- Repository interface/impl moved to lib/core/repositories/.
- Domain logic files moved to lib/core/logic/.

Compatibility layer:
- Old paths in lib/state, lib/ui/screens, lib/models, lib/data/repository, lib/domain now re-export new canonical files, so existing imports/tests continue to work during transition.

Feature controller files added:
- Added per-feature controller placeholders:
  - landing_controller.dart, leaderboard_controller.dart, match_runner_controller.dart,
    player_selection_controller.dart, player_profile_controller.dart,
    player_list_controller.dart, settings_controller.dart.

Verification:
- flutter analyze: no errors (infos/warnings only).
- Targeted parity suites pass:
  - test/ui/sprint_app_shell_test.dart
  - test/ui/leaderboard_screen_test.dart
  - test/state/sprint_controller_test.dart
  - test/data/sprint_repository_impl_test.dart
  - test/platform/platform_channels_test.dart
- Full flutter test still has known unrelated UI failures in landing/match_runner tests (same failing set seen before this architecture move).

Manual architecture acceptance (feature-folder line totals):
- app_shell: 1970 (OVER, documented exception)
- landing: 198 OK
- leaderboard: 1028 OK
- match_runner: 590 OK
- player_selection: 635 OK
- player_profile: 324 OK
- player_list: 40 OK
- settings: 79 OK