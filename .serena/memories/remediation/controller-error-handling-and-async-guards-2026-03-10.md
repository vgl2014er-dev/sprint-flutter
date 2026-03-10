Implemented P1 remediation in SprintController and tests.

Code changes:
- lib/state/sprint_controller.dart
  - Added AppLogger integration.
  - Replaced ignored platform error subscription with _onPlatformError handler.
  - _onPlatformError now sets localSessionState.phase=LocalSessionPhase.error and stores errorMessage for UI visibility.
  - Replaced fire-and-forget unawaited writes/commands with guarded wrappers:
    - _runRepositoryWrite
    - _runPlatformCommand
    - _runGuardedAsync
  - Guard wrappers catch both async and sync failures, log with AppLogger.error, and prevent uncaught async exceptions.
  - Applied wrappers to repository writes, local platform commands, publishLocalHostedSnapshot, and setImmersiveMode.

Tests:
- test/state/sprint_controller_test.dart
  - Added test: surfaces platform errors in local session state.
  - Added test: handles repository write failures without uncaught async errors.
  - Added test: handles platform command failures without uncaught async errors.
  - Extended fake repository/platform with error injection and invocation counters.

Minor cleanup:
- lib/data/local/app_database.dart: switched forTesting constructor to super-parameter style.
- test/data/sprint_repository_impl_test.dart: removed unnecessary dart:async import.

Validation:
- flutter test (full suite): PASS
- flutter analyze: PASS
- dart format run on modified files.