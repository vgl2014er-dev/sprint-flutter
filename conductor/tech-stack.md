# Technology Stack: Sprint Duels

## Core Framework & Language
- **Language:** [Dart](https://dart.dev/) (^3.10.4)
- **Framework:** [Flutter](https://flutter.dev/) (SDK)
- **State Management:** [Riverpod](https://riverpod.dev/) (flutter_riverpod ^2.6.1)

## Data Layer
- **Local Persistence:** [Drift](https://drift.simonbinder.eu/) (SQLite ORM, ^2.29.0)
- **Database Engine:** SQLite (sqlite3_flutter_libs ^0.5.39)
- **Cloud Database:** [Firebase Realtime Database](https://firebase.google.com/docs/database) (^12.0.3)
- **Shared Preferences:** [shared_preferences](https://pub.dev/packages/shared_preferences) (^2.5.3) for simple key-value storage.

## UI & Design
- **Design System:** [Material 3](https://m3.material.io/)
- **Icons:** [Lucide Icons](https://lucide.dev/), [Cupertino Icons](https://pub.dev/packages/cupertino_icons)
- **Typography:** [Google Fonts](https://pub.dev/packages/google_fonts) (^8.0.2)

## Utilities & Others
- **Audio:** [audioplayers](https://pub.dev/packages/audioplayers) (^6.1.0)
- **Functional Utilities:** [collection](https://pub.dev/packages/collection) (^1.19.1)
- **Serialization:** json_serializable / json_annotation (implied by drift/firebase patterns)
