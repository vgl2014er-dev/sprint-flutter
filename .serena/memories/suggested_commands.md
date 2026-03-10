# Suggested Commands (Windows)

## Setup
- `flutter pub get`
- `scripts/install-all-devices.ps1` (to install on all connected devices)

## Run
- `flutter run`
- `flutter run -d <deviceId>`

## Quality Checks
- `dart format lib test`
- `flutter analyze`
- `flutter test`

## Code Generation (Drift / build_runner)
- `dart run build_runner build --delete-conflicting-outputs`
- `dart run build_runner watch --delete-conflicting-outputs`

## Useful Utilities (PowerShell)
- `git status`
- `git diff`
- `Get-ChildItem`
- `Get-Content <file>`
- `Select-String -Path <file> -Pattern <text>`
