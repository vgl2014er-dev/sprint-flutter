Adjusted connected leaderboard layout to ensure all cards fit screen while aligning closer to PWA card layout behavior.

Files changed:
- lib/ui/screens/leaderboard_screen.dart
- AGENTS.md (ctx stats update)

Connected layout changes:
- Kept PWA-style fullWidthCount calculation and scale computation (based on available viewport height, base card heights 84/72, +15 acceptance threshold for candidate k).
- Updated shrink strategy for Flutter:
  - When computed scale > 1 (few players), rows are expanded using scaled card heights.
  - When computed scale <= 1 (many players), rows are built at base heights (84/72) and the connected layout is always wrapped in `FittedBox(scaleDown, topCenter)` so the whole content scales down uniformly.
  - This preserves fit-to-screen while avoiding Flutter internal RenderFlex overflows that happened when row heights were directly shrunk too far.
- Connected mode now always uses root `FittedBox(scaleDown)` wrapper for final fit safety.

Card layout/padding alignment:
- Added explicit `connectedLayout` flag for connected mode rows.
- Updated connected card horizontal padding to PWA-like responsive inner spacing:
  - >=768px: 32
  - >=640px: 24
  - else: 16
- Non-connected rows keep existing 12 horizontal padding.
- Connected full and half cards both use this connected padding path (as requested).

Verification:
- `flutter test test/ui/leaderboard_screen_test.dart` passed.
- `flutter test test/ui/sprint_app_shell_test.dart test/state/sprint_controller_test.dart test/platform/platform_channels_test.dart` passed.

Notes:
- This approach intentionally uses final uniform scale-down in connected mode to guarantee all cards remain visible on-screen in Flutter while preserving PWA-like split/height logic.