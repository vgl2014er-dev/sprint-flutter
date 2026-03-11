# Sprint Start Beep Generator

Generates 5 variations of loud, short sprint-start beep sounds using ElevenLabs.

## Setup

1. Install dependencies: `npm install`
2. Set your API key: `$env:ELEVENLABS_API_KEY = "your_key"` (PowerShell) or `export ELEVENLABS_API_KEY=your_key` (Bash)

## Run

```bash
npm run audio:generate-beeps
```

Output: `assets/audio/start_beep_1.mp3` … `start_beep_5.mp3`

## API Used

- **textToSoundEffects** (preferred): Generates actual sound effects from text prompts (e.g. "A short, loud electronic beep"). Requires ElevenLabs subscription with sound effects access.
- **textToSpeech** (fallback): If sound effects aren't available, uses TTS with short words: "Beep!", "Bip!", etc.

## Add to Flutter

After generating, add to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/audio/start.mp3
    - assets/audio/start_beep_1.mp3
    - assets/audio/start_beep_2.mp3
    - assets/audio/start_beep_3.mp3
    - assets/audio/start_beep_4.mp3
    - assets/audio/start_beep_5.mp3
```
