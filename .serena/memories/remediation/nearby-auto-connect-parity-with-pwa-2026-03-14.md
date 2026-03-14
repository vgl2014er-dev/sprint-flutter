Added PWA-like auto-connect behavior to Android Nearby manager in Flutter.

Changed file:
- android/app/src/main/kotlin/elo/flutter/nearby/LocalLeaderboardConnectionManager.kt

Behavior updates:
- Added `requestedEndpointId` tracking to avoid parallel/duplicate request attempts.
- Added `AUTO_CONNECT_ENABLED = true` flag.
- Discovery auto-connect:
  - On endpoint found, if client mode has no connected/pending/requested endpoint, automatically calls `connectToHost(endpointId)`.
  - On endpoint lost, clears requested id and auto-attempts next discovered host when applicable.
- Host auto-accept:
  - On connection initiated while host role, automatically accepts pending connection when auto-connect is enabled.
- Lifecycle cleanup:
  - Clears `requestedEndpointId` on stopHosting/startDiscovery reset/disconnect/useDatabaseMode/resetSession and on connection result/disconnect/reject flows.
- `connectToHost` now guards against conflicting connect attempts and sets/clears `requestedEndpointId` around `requestConnection`.

Verification:
- Could not run Gradle Kotlin compile because local wrapper class was missing (`org.gradle.wrapper.GradleWrapperMain`).
- Ran Dart-side regression suites successfully:
  - `flutter test test/platform/platform_channels_test.dart test/state/sprint_controller_test.dart` => All tests passed.

Docs:
- Updated AGENTS.md follow-up context performance counters to latest ctx_stats report.