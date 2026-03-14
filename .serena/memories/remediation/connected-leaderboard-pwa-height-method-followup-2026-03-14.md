Follow-up parity update for connected leaderboard to align with PWA height-driven layout behavior.

What changed:
- Updated `lib/ui/screens/leaderboard_screen.dart` connected mode layout logic to use available-height-driven full/half split and continuous scale computation:
  - Added `_connectedFullWidthCountForAvailableHeight(playerCount, availableHeight)` using descending candidate search from N to min(3, N), with PWA-style `<= available + 15` acceptance.
  - Added `_connectedScaleForAvailableHeight(playerCount, fullWidthCount, availableHeight)` and base height helpers.
  - Added Flutter-specific row chrome compensation (`_connectedRowChromeHeight = 4`) so border height is included in fit calculations and avoids overflow drift vs raw PWA formula.
- Connected layout now builds full-width cards followed by half-width wrap cards based on the computed `fullWidthCount`.
- Added/kept scale fallback path (`FittedBox` at top-center) for dense layouts when scaled row heights drop under safety thresholds, to prevent runtime overflow in Flutter render tree.
- Row widget adjustments for connected narrow cards:
  - `buildPlayerRow` now receives `rowHeight`, `bottomMargin`, and `connectedHalf`.
  - Name/info block wrapped in `FittedBox(scaleDown)` for narrow cards to avoid text flex overflows.

Tests updated:
- `test/ui/leaderboard_screen_test.dart`
  - Replaced fixed 3/7 connected split assertion with viewport-sensitive assertions (compact vs tall heights).
  - Added continuous card-height scaling assertion by comparing row heights at two viewport heights.
  - Updated fallback assertion to target the connected root scale-down `FittedBox` (top-center) rather than counting all `FittedBox` instances.

Verification run:
- `flutter test test/ui/leaderboard_screen_test.dart` passed.
- `flutter test test/ui/leaderboard_screen_test.dart test/ui/sprint_app_shell_test.dart` passed.

Ops/docs:
- Updated `AGENTS.md` with a follow-up Context MCP performance block using latest `ctx_stats` output for this session.