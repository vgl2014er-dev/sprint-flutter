Implemented leaderboard enhancements in lib/ui/screens/leaderboard_screen.dart:
- Derive latest match from AppState.history using max timestamp.
- Compute per-player elo deltas for latest match participants.
- Highlight latest-match participant rows with border-only container.
- Add stable keys/content descriptions:
  - row key: leaderboard-highlight-row-<playerId>
  - row semantics label: leaderboard_highlight_row_<playerId>
  - delta key: leaderboard-elo-delta-<playerId>
  - delta semantics label: leaderboard_elo_delta_<playerId>_<positive|negative|neutral>_<abs>
- Render delta in ELO column:
  - positive => up arrow + +N in success color
  - negative => down arrow + -N in danger color
  - zero => neutral 0 with no arrow
- Add connected-display force-fit mode (read-only local client connected): non-scroll layout uses FittedBox(scaleDown) over a static column of rows so all players remain visible on screen.
- Preserve default scrollable ListView behavior outside connected-display mode.

Updated test/ui/leaderboard_screen_test.dart:
- Added history param support to stateWithPlayers helper.
- Added widget tests for:
  - newest timestamp selection for latest-match delta/highlight
  - positive/negative delta direction/color/icon semantics contracts
  - zero delta with no direction arrow
  - connected-display non-scroll force-fit behavior + viewport visibility of last row
  - default mode remains scrollable list

Validation:
- dart format on modified files
- flutter test test/ui/leaderboard_screen_test.dart (all tests passed)
