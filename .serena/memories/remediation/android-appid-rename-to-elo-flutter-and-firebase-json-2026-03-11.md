Renamed Android app/package identity from sprint.app to elo.flutter and swapped Firebase config to the user-provided google-services file.

Changes made:
- android/app/build.gradle.kts
  - namespace: elo.flutter
  - applicationId: elo.flutter
- Kotlin package declarations/imports migrated from sprint.app.* to elo.flutter.*
- Kotlin source files moved to matching package paths:
  - android/app/src/main/kotlin/elo/flutter/**
  - android/app/src/androidTest/kotlin/elo/flutter/**
  (old sprint/app paths removed from source tree)
- Firebase config replaced in app module:
  - android/app/google-services.json now sourced from user download file and contains package_name elo.flutter
- Download file rename request handled:
  - C:/Users/paul/Downloads/google-services (3).json -> C:/Users/paul/Downloads/google-services.json (old (3) file removed)
- Updated app id defaults in runtime/test utilities:
  - lib/core/app_logger.dart default logger name -> elo.flutter
  - scripts/mobile-mcp/* test helper defaults -> elo.flutter

Validation:
- Release build succeeded (flutter build apk --release via rebuild-install script)
- Installed and launched successfully with app id elo.flutter on both connected Android devices:
  - 31071FDH2008FK
  - 4c637b9e
- Removed old sprint.app from both devices and verified only package:elo.flutter remains.