# Task Completion Checklist

Before considering a code task done:

1. **Formatting**: Run `dart format lib test` on all modified files.
2. **Analysis**: Run `flutter analyze` and resolve all reported issues (lints, errors, warnings).
3. **Tests**: Run `flutter test`. Ensure at least the relevant tests for changed areas are passing.
4. **Code Generation**: If Drift schema, queries, or JSON serializable models changed, regenerate with `dart run build_runner build --delete-conflicting-outputs`.
5. **Nearby Verification**: If the "Offline Mirror" or Nearby Connection feature was touched:
   - Run the E2E script: `scripts/mobile-mcp/run-end-to-end.ps1`.
   - Verify connection success on both devices.
6. **Platform Compatibility**: Confirm no accidental edits to native Android code (`android/`) unless intended.
7. **Performance**: Verify expensive operations (network, DB) are not in `build()` methods.
8. **UI Verification**: Ensure app boots on a target device or emulator when behavior changed (`flutter run`).