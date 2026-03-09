# Task Completion Checklist

Before considering a code task done:

1. Run formatting on touched Dart files (`dart format lib test` or target files).
2. Run analyzer (`flutter analyze`) and resolve introduced issues.
3. Run tests (`flutter test`), at least relevant tests for changed areas.
4. If Drift schema/queries changed, regenerate files with build_runner.
5. Verify app boots on a target device/emulator when behavior changed (`flutter run`).
6. Confirm no accidental edits to generated files unless regeneration was intended.