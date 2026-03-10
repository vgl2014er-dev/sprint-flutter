Implemented full Material 3 theming and UI modularization in worktree branch codex/theme-full-sweep at C:/Users/paul/projects/flutter/sprint-theme-full-sweep.

Key changes:
- Added AppThemePreference enum and AppState.themePreference with initial light default and copyWith/equality/hash integration.
- Extended SprintRepository API and SprintRepositoryImpl with themePreference stream + setThemePreference, persisted to DB setting `theme_mode` and SharedPreferences key `theme_mode_v1`, load order DB -> prefs -> light.
- SprintController now subscribes to repository themePreference stream and exposes toggleThemePreference().
- Added theme modules: lib/ui/theme/app_theme.dart, lib/ui/theme/sprint_theme_tokens.dart, lib/ui/theme/breakpoints.dart.
- ThemeData now uses Material 3, ColorScheme.fromSeed with blue seed and amber accent tuning, Google Fonts (Oswald heading / Merriweather body), and centralized appBar/card/button/chip/input themes with WidgetStateProperty.resolveWith.
- Modularized UI into lib/ui/screens/* and lib/ui/widgets/*; kept lib/ui/screens/sprint_app.dart as compatibility re-export barrel.
- AppHeader supports multiple trailing actions; SprintApp shell now shows quick theme toggle and leaderboard reset together when applicable.
- Fixed context bug by constructing screen callbacks/dialog actions with an inner Builder context under MaterialApp; reset dialog now resolves MaterialLocalizations correctly.
- Added compact-width overflow safeguards in player selection and death-match setup rows/headers.
- Removed double-dispose wiring from sprintControllerProvider (StateNotifierProvider already disposes notifier).

Test updates:
- Added repository tests for theme preference default/persistence/fallback.
- Added controller tests for theme stream propagation and toggle behavior.
- Updated UI tests to assert theme/token-derived values rather than old hardcoded card colors.
- Added new UI tests: test/ui/sprint_app_shell_test.dart and test/ui/responsive_layout_test.dart.

Validation:
- flutter pub get, dart format lib test, flutter analyze, flutter test, and flutter test test/ui test/state test/data all pass.
- Drift warning about multiple in-memory DB instances appears in repository tests but is non-fatal.