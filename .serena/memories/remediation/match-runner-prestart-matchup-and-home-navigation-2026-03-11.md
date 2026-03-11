Implemented match-runner UX update to show matchup names above START and send back navigation to Home.

Code changes:
- lib/ui/screens/match_runner_screen.dart
  - Bottom CTA copy changed from Go Back/View Leaderboard to Go Home/View Home.
  - Standard session completion helper copy changed to: "All scheduled matches are finished. View Home to continue."
  - Added _PreStartMatchup widget and rendered it in showStartOnly branch above START button using uppercase player names and VS.
- lib/ui/screens/sprint_app_shell.dart
  - MatchRunnerScreen.onBack now uses controller.closeRoundToLanding (same as onClose).
- test/ui/match_runner_screen_test.dart
  - Updated pre-start tests to assert matchup names + VS + START.
  - Updated next-unstarted-match test similarly.
  - Updated layout test to assert matchup names are positioned above START.
  - Updated completion-state copy expectation and View Home button assertion.
- scripts/mobile-mcp/mode-helpers.ps1
  - Added Invoke-MobileTapByLabelWithFallback (PrimaryLabel -> FallbackLabel).
  - Added Assert-MobileLabelVisibleWithFallback (PrimaryLabel -> FallbackLabel).
- scripts/mobile-mcp/test-random-mode.ps1 and test-elo-mode.ps1
  - Replaced Go Back tap with Go Home primary and Go Back fallback helper.
- scripts/mobile-mcp/test-death-match-mode.ps1
  - Replaced Go Back label assertion with Go Home primary and Go Back fallback helper.

Verification run:
- flutter test test/ui/match_runner_screen_test.dart (pass)
- flutter analyze lib/ui/screens/match_runner_screen.dart lib/ui/screens/sprint_app_shell.dart test/ui/match_runner_screen_test.dart (info-level lints only; no errors)
- powershell -ExecutionPolicy Bypass -File scripts/mobile-mcp/test-random-mode.ps1 -DryRun (pass)
- powershell -ExecutionPolicy Bypass -File scripts/mobile-mcp/test-elo-mode.ps1 -DryRun (pass)
- powershell -ExecutionPolicy Bypass -File scripts/mobile-mcp/test-death-match-mode.ps1 -DryRun (pass)
