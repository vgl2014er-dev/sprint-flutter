# Sprint Project Overview

## Purpose
Sprint is a Flutter app ("Sprint Duels") for managing player matchups and Elo-based ranking updates. It supports random/Elo pairing, death-match rounds, leaderboard tracking, and profile/history views. A key feature is the "Offline Mirror," which allows nearby devices to mirror the leaderboard in real-time without an internet connection.

## Tech Stack
- **Flutter / Dart** (SDK constraint `^3.10.4`)
- **State Management**: `flutter_riverpod` (using `ConsumerWidget` and `StateNotifier`)
- **Local Persistence**: `drift` (SQLite) for structured data and `shared_preferences` for simple flags.
- **Cloud/Sync**: `firebase_core`, `firebase_database` for online leaderboard sync.
- **Connectivity**: Android Nearby Connections API (native integration) for the Offline Mirror.
- **Audio**: `audioplayers` for in-app sound effects (e.g., match start beeps).
- **Navigation**: Custom state-based navigation (handled via `SprintController` and `Screen` enum).

## Core Features
- **Matchmaking**: 
  - *Random*: Equal distribution of matchups.
  - *Elo*: Pairs players with similar ratings.
  - *Death Match*: Tournament mode with limited lives; last player standing wins.
- **Leaderboard**: Real-time ranking with Elo updates, win rates, and match counts.
- **Offline Mirror (Nearby)**:
  - *Host*: Advertises the local database state to nearby devices.
  - *Client*: Discovers and connects to a host to receive live updates.
  - *Authentication*: Uses a 4-digit code (Nearby PIN) for connection approval.
- **Player Profiles**: Detailed history, head-to-head stats, and match deletion/rollback.

## High-Level Architecture
- `lib/main.dart`: App bootstrap, Firebase init, Riverpod `ProviderScope`.
- `lib/state/`: State orchestration via `SprintController` and `AppState`.
- `lib/domain/`: Pure logic (Elo calculation, pairing algorithms, history policies).
- `lib/data/`:
  - `local/`: Drift database schema and DAOs.
  - `repository/`: Repository implementations bridging local DB, Firebase, and Nearby state.
- `lib/platform/`: Platform channel interfaces for native Android Nearby integration.
- `android/app/src/main/kotlin/sprint/app/nearby/`: Native Android implementation for Nearby Connections.

## Notes
- The app prefers immutable-style state updates using `copyWith`.
- Repository and platform adapters are wired via Riverpod providers.
- Local nearby connectivity is currently Android-only (native code).