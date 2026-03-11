## Task
Add a subtle connection-type indicator in the leaderboard header when a local Nearby session is connected.

## What changed
- Added a new cross-platform session field for transport hint:
  - Dart: `LocalConnectionMedium` enum (`unknown`, `ble`, `bt`, `wifi`) with wire mapping in `lib/models/app_models.dart`.
  - Dart `LocalSessionState` now carries `connectionMedium` (default `unknown`) and includes it in `copyWith`, `toJson`, `fromJson`, equality/hash.
  - Android: added `LocalConnectionMedium` enum and `connectionMedium` field to `LocalSessionState` in `android/app/src/main/kotlin/elo/flutter/nearby/LocalLeaderboardModels.kt`.
  - Android bridge: wired `connectionMedium` into platform event payloads in `SprintPlatformBridge.kt`.

- Added Nearby quality -> transport hint mapping in Android connection manager:
  - Overrode `onBandwidthChanged(endpointId, bandwidthInfo)`.
  - Mapped `BandwidthInfo.Quality` to hint:
    - `LOW -> BLE`
    - `MEDIUM -> BT`
    - `HIGH -> WIFI`
    - otherwise `UNKNOWN`
  - Reset hint to `UNKNOWN` across non-connected states (disconnect/error/pending/restart).
  - Note in code: Nearby public API does not expose exact radio medium directly; this is a quality-based UI hint.

- Leaderboard UI:
  - `_LeaderboardHeaderRow` now accepts a computed `connectionBadgeLabel`.
  - Added subtle badge widget `_ConnectionMediumBadge` in PLAYER header area.
  - Badge shown only when phase is `connected` and medium is known.
  - Display labels: `BLE`, `BT`, `WiFi`.

## Tests (TDD)
- Added failing tests first, then implemented:
  - `test/models/wire_mapping_test.dart`: round-trip for `LocalConnectionMedium`.
  - `test/platform/platform_channels_test.dart`: parses `connectionMedium` from `local_session_state` event.
  - `test/ui/leaderboard_screen_test.dart`:
    - shows `WiFi` badge when connected.
    - hides badge when disconnected.

## Verification run
- `flutter test test/models/wire_mapping_test.dart test/platform/platform_channels_test.dart test/ui/leaderboard_screen_test.dart` -> pass.
- `cd android && .\gradlew.bat :app:compileDebugKotlin` -> BUILD SUCCESSFUL.
- `flutter analyze lib/models/app_models.dart lib/ui/screens/leaderboard_screen.dart` -> existing info-level lints in `app_models.dart` (no new errors).