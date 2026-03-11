#!/usr/bin/env node
/**
 * Generates 5 sprint-start beep variations using ElevenLabs.
 * Uses textToSoundEffects for authentic beeps (falls back to TTS if needed).
 * Run: npm run audio:generate-beeps
 * Requires: ELEVENLABS_API_KEY env var
 *
 * Output: assets/audio/start_beep_1.mp3 ... start_beep_5.mp3
 */

import { ElevenLabsClient } from '@elevenlabs/elevenlabs-js';
import { Readable } from 'stream';
import { createWriteStream } from 'fs';
import { mkdir } from 'fs/promises';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUT_DIR = join(__dirname, '../../assets/audio');

const OUTPUT_FORMAT = 'mp3_44100_128';
const VOICE_ID = 'JBFqnCBsd6RMkjVDRZzb';
const MODEL_ID = 'eleven_multilingual_v2';

// Sound-effect prompts (textToSoundEffects) – loud, short sprint-start beeps
const BEEP_VARIANTS = [
  { text: 'A short, loud electronic beep', desc: 'Classic electronic' },
  { text: 'A sharp race starting beep', desc: 'Sharp starter' },
  { text: 'A punchy sprint start tone', desc: 'Punchy tone' },
  { text: 'A loud, brief starting horn', desc: 'Horn-style' },
  { text: 'A crisp beep for race start', desc: 'Crisp trigger' },
];

async function generateBeeps() {
  const apiKey = process.env.ELEVENLABS_API_KEY;
  if (!apiKey) {
    console.error('Error: Set ELEVENLABS_API_KEY environment variable.');
    process.exit(1);
  }

  const elevenlabs = new ElevenLabsClient({ apiKey });

  await mkdir(OUT_DIR, { recursive: true });

  const ttsTexts = ['Beep!', 'Bip!', 'Bop!', 'Go!', 'Now!'];
  let useSoundEffects = true;

  for (let i = 0; i < BEEP_VARIANTS.length; i++) {
    const { text, desc } = BEEP_VARIANTS[i];
    const outPath = join(OUT_DIR, `start_beep_${i + 1}.mp3`);

    console.log(`Generating ${i + 1}/5: "${text}" (${desc}) -> ${outPath}`);

    let audio;
    try {
      if (useSoundEffects) {
        audio = await elevenlabs.textToSoundEffects.convert({
          text,
          outputFormat: OUTPUT_FORMAT,
          durationSeconds: 0.5,
        });
      } else {
        throw new Error('Using TTS');
      }
    } catch {
      if (useSoundEffects) {
        useSoundEffects = false;
        console.log('  (textToSoundEffects unavailable, using TTS)\n');
      }
      audio = await elevenlabs.textToSpeech.convert(VOICE_ID, {
        text: ttsTexts[i],
        modelId: MODEL_ID,
        outputFormat: OUTPUT_FORMAT,
      });
    }

    // SDK returns Web ReadableStream<Uint8Array>; convert to Node Readable
    const readable = Readable.fromWeb(audio);
    const writer = createWriteStream(outPath);
    await new Promise((resolve, reject) => {
      readable.pipe(writer);
      writer.on('finish', resolve);
      writer.on('error', reject);
      readable.on('error', reject);
    });

    console.log(`  ✓ Saved`);
  }

  console.log('\nDone. Add to pubspec.yaml:');
  BEEP_VARIANTS.forEach((_, i) => {
    console.log(`  - assets/audio/start_beep_${i + 1}.mp3`);
  });
}

generateBeeps().catch((err) => {
  console.error(err);
  process.exit(1);
});
