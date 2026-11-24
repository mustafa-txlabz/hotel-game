// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  final outputDir = Directory('assets/audio');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  // 1. Generate Door Open (Modern Electric Servo Glide + Velvet Air Whoosh)
  final doorOpenWav = generateDoorOpenSfx();
  File('assets/audio/door_open.wav').writeAsBytesSync(doorOpenWav);
  File('assets/audio/door_whoosh.wav').writeAsBytesSync(doorOpenWav);
  print('Generated assets/audio/door_open.wav (${doorOpenWav.length} bytes)');

  // 2. Generate Door Close (Descending Servo Glide + Air Whoosh + Soft Rubber Seal Bump)
  final doorCloseWav = generateDoorCloseSfx();
  File('assets/audio/door_close.wav').writeAsBytesSync(doorCloseWav);
  print('Generated assets/audio/door_close.wav (${doorCloseWav.length} bytes)');

  // 3. Generate Car Horn (Automotive dual-tone "HONK HONK")
  final hornWav = generateCarHornSfx();
  File('assets/audio/car_horn.wav').writeAsBytesSync(hornWav);
  print('Generated assets/audio/car_horn.wav (${hornWav.length} bytes)');

  // 4. Generate Car Brake (Hydraulic brake pad friction & tire screech)
  final brakeWav = generateCarBrakeSfx();
  File('assets/audio/car_brake.wav').writeAsBytesSync(brakeWav);
  print('Generated assets/audio/car_brake.wav (${brakeWav.length} bytes)');
}

class PinkNoise {
  double b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
  final math.Random rand;
  PinkNoise(int seed) : rand = math.Random(seed);

  double next() {
    final white = rand.nextDouble() * 2.0 - 1.0;
    b0 = 0.99886 * b0 + white * 0.0555179;
    b1 = 0.99332 * b1 + white * 0.0750759;
    b2 = 0.96900 * b2 + white * 0.1538520;
    b3 = 0.86650 * b3 + white * 0.3104856;
    b4 = 0.55000 * b4 + white * 0.5329522;
    b5 = -0.7616 * b5 - white * 0.0168980;
    final pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362;
    b6 = white * 0.115926;
    return pink * 0.11; // scale to roughly -1.0 to 1.0
  }
}

Uint8List buildWav({
  required List<double> samples,
  int sampleRate = 44100,
}) {
  final numSamples = samples.length;
  final subchunk2Size = numSamples * 2; // 16-bit mono = 2 bytes per sample
  final chunkSize = 36 + subchunk2Size;

  final byteData = ByteData(44 + subchunk2Size);

  // RIFF header
  byteData.setUint8(0, 0x52); // 'R'
  byteData.setUint8(1, 0x49); // 'I'
  byteData.setUint8(2, 0x46); // 'F'
  byteData.setUint8(3, 0x46); // 'F'
  byteData.setUint32(4, chunkSize, Endian.little);
  byteData.setUint8(8, 0x57); // 'W'
  byteData.setUint8(9, 0x41); // 'A'
  byteData.setUint8(10, 0x56); // 'V'
  byteData.setUint8(11, 0x45); // 'E'

  // fmt subchunk
  byteData.setUint8(12, 0x66); // 'f'
  byteData.setUint8(13, 0x6D); // 'm'
  byteData.setUint8(14, 0x74); // 't'
  byteData.setUint8(15, 0x20); // ' '
  byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
  byteData.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
  byteData.setUint16(22, 1, Endian.little); // NumChannels (1 = Mono)
  byteData.setUint32(24, sampleRate, Endian.little); // SampleRate
  byteData.setUint32(28, sampleRate * 2, Endian.little); // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
  byteData.setUint16(32, 2, Endian.little); // BlockAlign (NumChannels * BitsPerSample/8)
  byteData.setUint16(34, 16, Endian.little); // BitsPerSample (16 bits)

  // data subchunk
  byteData.setUint8(36, 0x64); // 'd'
  byteData.setUint8(37, 0x61); // 'a'
  byteData.setUint8(38, 0x74); // 't'
  byteData.setUint8(39, 0x61); // 'a'
  byteData.setUint32(40, subchunk2Size, Endian.little);

  // PCM samples
  int offset = 44;
  for (int i = 0; i < numSamples; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    final pcm16 = (clamped * 32767).toInt().clamp(-32768, 32767);
    byteData.setInt16(offset, pcm16, Endian.little);
    offset += 2;
  }

  return byteData.buffer.asUint8List();
}

/// Generates a sleek, modern automatic sliding door opening sound.
/// Layered electric servo glide (260Hz -> 480Hz) + warm velvety air displacement whoosh.
Uint8List generateDoorOpenSfx() {
  const sampleRate = 44100;
  const duration = 0.42; // 420 ms
  final totalSamples = (sampleRate * duration).toInt();
  final samples = List<double>.filled(totalSamples, 0.0);
  final pink = PinkNoise(42);

  double filterState = 0.0;
  double phase1 = 0.0;
  double phase2 = 0.0;

  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    final progress = t / duration;

    // 1. Sleek ascending servo motor glide (260 Hz -> 480 Hz)
    final freq = 260.0 + 220.0 * progress;
    phase1 += 2.0 * math.pi * freq / sampleRate;
    phase2 += 2.0 * math.pi * (freq * 1.5) / sampleRate;
    final motor = (math.sin(phase1) * 0.6 + math.sin(phase2) * 0.25);

    // 2. Velvet air displacement whoosh (pink noise through dynamic resonant filter)
    final pNoise = pink.next();
    final cutoff = 700.0 + 800.0 * math.sin(progress * math.pi);
    final rc = 1.0 / (2.0 * math.pi * cutoff);
    final dt = 1.0 / sampleRate;
    final alpha = dt / (rc + dt);
    filterState += alpha * (pNoise - filterState);
    final airWhoosh = filterState * 1.8;

    // 3. Envelope: quick smooth attack (30ms), sustained body, smooth glide decay
    double env;
    if (t < 0.03) {
      env = t / 0.03;
    } else if (t < 0.28) {
      env = 1.0;
    } else {
      final decayT = (t - 0.28) / (duration - 0.28);
      env = 1.0 - decayT * decayT;
    }

    samples[i] = (motor * 0.35 + airWhoosh * 0.65) * env * 0.85;
  }

  return buildWav(samples: samples, sampleRate: sampleRate);
}

/// Generates a sleek, modern automatic sliding door closing sound.
/// Layered descending servo glide + air whoosh + gentle magnetic rubber seal bump.
Uint8List generateDoorCloseSfx() {
  const sampleRate = 44100;
  const duration = 0.45; // 450 ms
  final totalSamples = (sampleRate * duration).toInt();
  final samples = List<double>.filled(totalSamples, 0.0);
  final pink = PinkNoise(99);

  double filterState = 0.0;
  double phase1 = 0.0;
  double phase2 = 0.0;
  double sealPhase = 0.0;

  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    final progress = t / duration;

    // 1. Sleek descending servo motor glide (480 Hz -> 240 Hz)
    final freq = 480.0 - 240.0 * progress;
    phase1 += 2.0 * math.pi * freq / sampleRate;
    phase2 += 2.0 * math.pi * (freq * 1.5) / sampleRate;
    final motor = (math.sin(phase1) * 0.6 + math.sin(phase2) * 0.25);

    // 2. Air displacement
    final pNoise = pink.next();
    final cutoff = 1300.0 - 600.0 * progress;
    final rc = 1.0 / (2.0 * math.pi * cutoff);
    final dt = 1.0 / sampleRate;
    final alpha = dt / (rc + dt);
    filterState += alpha * (pNoise - filterState);
    final airWhoosh = filterState * 1.7;

    // 3. Sliding envelope
    double env;
    if (t < 0.03) {
      env = t / 0.03;
    } else if (t < 0.34) {
      env = 1.0;
    } else {
      final decayT = (t - 0.34) / (duration - 0.34);
      env = (1.0 - decayT).clamp(0.0, 1.0);
    }

    // 4. Soft magnetic/rubber seal bumper contact at end (t: 0.34s to 0.44s)
    double sealBump = 0.0;
    if (t >= 0.34 && t < 0.44) {
      final sealT = (t - 0.34) / 0.10;
      sealPhase += 2.0 * math.pi * 95.0 / sampleRate;
      final bumpEnv = math.sin(sealT * math.pi);
      sealBump = math.sin(sealPhase) * bumpEnv * 0.45;
    }

    samples[i] = ((motor * 0.30 + airWhoosh * 0.70) * env + sealBump) * 0.85;
  }

  return buildWav(samples: samples, sampleRate: sampleRate);
}

/// Generates an authentic dual-tone automotive car horn ("HONK HONK!").
Uint8List generateCarHornSfx() {
  const sampleRate = 44100;
  const duration = 0.52; // 520 ms
  final totalSamples = (sampleRate * duration).toInt();
  final samples = List<double>.filled(totalSamples, 0.0);

  // Two horn frequencies (A4 = 440 Hz, C#5 = 554 Hz) forming a harmonic major third
  const f1 = 440.0;
  const f2 = 554.0;

  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;

    // Pattern: Beep 1 (0.0 to 0.16s), gap (0.16 to 0.21s), Beep 2 (0.21 to 0.50s)
    double env = 0.0;
    if (t >= 0.0 && t < 0.16) {
      final beep1T = t / 0.16;
      if (beep1T < 0.1) {
        env = beep1T / 0.1;
      } else if (beep1T > 0.85) {
        env = (1.0 - beep1T) / 0.15;
      } else {
        env = 1.0;
      }
    } else if (t >= 0.21 && t < 0.50) {
      final beep2T = (t - 0.21) / 0.29;
      if (beep2T < 0.08) {
        env = beep2T / 0.08;
      } else if (beep2T > 0.82) {
        env = (1.0 - beep2T) / 0.18;
      } else {
        env = 1.0;
      }
    }

    if (env > 0.0) {
      // Brassy metallic horn timbre: fundamental + 3rd harmonic + 5th harmonic
      final tone1 = math.sin(2.0 * math.pi * f1 * t) +
          0.35 * math.sin(2.0 * math.pi * f1 * 3.0 * t) +
          0.15 * math.sin(2.0 * math.pi * f1 * 5.0 * t);

      final tone2 = math.sin(2.0 * math.pi * f2 * t) +
          0.35 * math.sin(2.0 * math.pi * f2 * 3.0 * t) +
          0.15 * math.sin(2.0 * math.pi * f2 * 5.0 * t);

      // Mix & saturate slightly for automotive diaphragm rattle
      final mixed = (tone1 * 0.5 + tone2 * 0.5);
      final satIn = mixed * 1.3;
      final saturated = satIn / (1.0 + satIn.abs());

      samples[i] = saturated * env * 0.80;
    }
  }

  return buildWav(samples: samples, sampleRate: sampleRate);
}

/// Generates hydraulic brake pad friction and quick tire chirp.
Uint8List generateCarBrakeSfx() {
  const sampleRate = 44100;
  const duration = 0.42; // 420 ms
  final totalSamples = (sampleRate * duration).toInt();
  final samples = List<double>.filled(totalSamples, 0.0);
  final rand = math.Random(54321);

  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;

    // Pitch sweep downwards from 920 Hz to 480 Hz
    final freq = 920.0 - 440.0 * (t / duration);
    final tone = math.sin(2.0 * math.pi * freq * t);

    // Friction noise layer
    final noise = rand.nextDouble() * 2.0 - 1.0;

    // Envelope
    final attack = (t / 0.03).clamp(0.0, 1.0);
    final decay = math.exp(-t * 7.5);
    final env = attack * decay;

    samples[i] = (tone * 0.65 + noise * 0.35) * env * 0.70;
  }

  return buildWav(samples: samples, sampleRate: sampleRate);
}
