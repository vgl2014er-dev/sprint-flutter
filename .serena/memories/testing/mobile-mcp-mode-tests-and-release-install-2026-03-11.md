Implemented mobile-mcp mode test coverage under scripts/mobile-mcp and verified dry-run + partial real execution.

Added files:
- scripts/mobile-mcp/mode-helpers.ps1
- scripts/mobile-mcp/test-theme-mode.ps1
- scripts/mobile-mcp/test-random-mode.ps1
- scripts/mobile-mcp/test-elo-mode.ps1
- scripts/mobile-mcp/test-death-match-mode.ps1
- scripts/mobile-mcp/test-local-mode.ps1
- scripts/mobile-mcp/run-mode-tests.ps1

Updated files:
- scripts/mobile-mcp/README.md (mode test usage and commands)
- package.json (mobile:test:* scripts)
- scripts/mobile-mcp/common.ps1: fixed Find-MobileElementsByLabel to return a flat array (removed nested-array return bug)

Important behavior notes:
- Theme toggle in mobile-mcp required coordinate tap fallback (header icon had no stable text label in element list on tested device), so test-theme-mode uses ThemeToggleX/ThemeToggleY params with defaults.
- random/elo mode tests changed to use 'Go Back' (controller navigates to leaderboard) instead of waiting for 'View Leaderboard' which only appears after full session completion.

Also created Maestro artifacts earlier in .maestro-tests for mode/local coverage and local orchestration.

Release install status:
- Ran scripts/rebuild-install-all-devices.ps1 -Release
- Build succeeded (app-release.apk)
- Installed and launched successfully on:
  - Pixel 7 [31071FDH2008FK]
  - 2410CRP4CG [4c637b9e]
- Android app id: sprint.app