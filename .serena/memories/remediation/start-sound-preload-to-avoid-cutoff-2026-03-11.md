Adjusted START button audio playback to preload asset and reduce clipped start.

File changed:
- lib/ui/screens/sprint_app_shell.dart

Implementation:
- Added global preload future:
  - final Future<void> _startBeepPreload = _preloadStartBeep();
- Added _preloadStartBeep() to call:
  - _startBeepPlayer.setSource(AssetSource('audio/start.mp3'))
- Updated _playStartBeep() flow:
  - await _startBeepPreload
  - seek(Duration.zero)
  - resume()
  - fallback to play(AssetSource('audio/start.mp3'), mode: PlayerMode.lowLatency) on failure

Outcome:
- Avoids reloading the asset on first START press and replays from beginning with preloaded source.
- Keeps non-blocking behavior with guarded fallback path.

Validation:
- Ran flutter analyze on the file; only info-level lints remain (catch clause style + expression function body), no build-blocking errors.