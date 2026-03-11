Updated START button sound to use custom user-provided MP3.

Changes:
- Copied C:/Users/paul/Desktop/start.mp3 to project asset path:
  - assets/audio/start.mp3
- Updated asset registration in pubspec.yaml:
  - flutter.assets now includes assets/audio/start.mp3 (replacing start_beep.mp3 entry)
- Updated playback source in lib/ui/screens/sprint_app_shell.dart:
  - _playStartBeep() now plays AssetSource('audio/start.mp3')

Validation:
- Ran flutter analyze on lib/ui/screens/sprint_app_shell.dart.
- Analyzer reported two existing info-level lints (catch without on clause, prefer expression function body), no new errors from this change.