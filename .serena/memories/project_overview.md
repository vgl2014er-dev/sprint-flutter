# Sprint Project Overview

## Purpose
Sprint is a Flutter app ("Sprint Duels") for managing player matchups and Elo-based ranking updates. It supports random/Elo pairing, death-match rounds, leaderboard tracking, and profile/history views.

## Tech Stack
- Flutter / Dart (SDK constraint `^3.10.4`)
- State management: `flutter_riverpod`
- Local persistence: `drift` + `sqlite3_flutter_libs`
- Cloud/sync-related dependencies: `firebase_core`, `firebase_database`
- Device/platform integration: platform channel adapter in `lib/platform/`

## High-Level Architecture
- `lib/main.dart`: app bootstrap, Firebase init, Riverpod provider scope
- `lib/state/`: app orchestration/state notifier (`SprintController`)
- `lib/domain/`: pure domain logic (pairing, Elo, history/rollback rules)
- `lib/data/local/`: Drift database + generated schema file
- `lib/data/repository/`: repository interfaces + implementation
- `lib/models/`: app state/models/enums/value objects
- `lib/ui/screens/`: main UI screens/widgets composition
- `test/`: widget-level and harness tests

## Notes
- Repository and platform adapters are wired via Riverpod providers.
- App uses immutable-style state updates through `copyWith` and typed model objects.