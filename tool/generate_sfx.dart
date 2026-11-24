// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  final outputDir = Directory('assets/audio');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  // 1. Generate Door Whoosh (Pneumatic "wiss / pssshhh" air release)
  final doorWav = generateDoorPneumaticSfx();
  File('assets/audio/door_whoosh.wav').writeAsBytesSync(doorWav);
  print('Generated assets/audio/door_whoosh.wav (${doorWav.length} bytes)');

  // 2. Generate Car Horn (Automotive dual-tone "HONK HONK")
  final hornWav = generateCarHornSfx();
  File('assets/audio/car_horn.wav').writeAsBytesSync(hornWav);
  print('Generated assets/audio/car_horn.wav (${hornWav.length} bytes)');

  // 3. Generate Car Brake (Hydraulic brake pad friction & tire screech)
  final brakeWav = generateCarBrakeSfx();
  File('assets/audio/car_brake.wav').writeAsBytesSync(brakeWav);
  print('Generated assets/audio/car_brake.wav (${brakeWav.length} bytes)');
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

/// Generates a realistic pneumatic / hydraulic automatic sliding door "pssshhh / wiss" sound.
Uint8List generateDoorPneumaticSfx() {
  const sampleRate = 44100;
  const duration = 0.65; // 650 ms
  final totalSamples = (sampleRate * duration).toInt();
  final samples = List<double>.filled(totalSamples, 0.0);
  final rand = math.Random(12345);

  // Simple resonant IIR filter state
  double filterY1 = 0.0;
  double filterY2 = 0.0;

  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;

    // White noise source
    final noise = rand.nextDouble() * 2.0 - 1.0;

    // Resonant frequency sweeps down from 3400 Hz to 1300 Hz
    final progress = t / duration;
    final centerFreq = 3400.0 - 2100.0 * progress;
    final w0 = 2.0 * math.pi * centerFreq / sampleRate;
    final alpha = math.sin(w0) * 0.35;

    // Bandpass filtered noise
    final filtered = noise * alpha + filterY1 * (1.0 - alpha * 0.8) - filterY2 * 0.15;
    filterY2 = filterY1;
    filterY1 = filtered;

    // Pressure envelope: rapid attack (25ms), sustained air hiss, smooth exponential tail
    double envelope;
    if (t < 0.025) {
      envelope = t / 0.025;
    } else if (t < 0.28) {
      envelope = 1.0 - 0.2 * ((t - 0.025) / 0.255);
    } else {
      final tailT = (t - 0.28) / (duration - 0.28);
      envelope = 0.8 * math.exp(-tailT * 3.5);
    }

    // Subtle pneumatic hiss flutter (35 Hz air turbulence)
    final flutter = 1.0 + 0.15 * math.sin(2.0 * math.pi * 35.0 * t);

    samples[i] = filtered * envelope * flutter * 0.85;
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
      if (beep1T < 0.1) env = beep1T / 0.1;
      else if (beep1T > 0.85) env = (1.0 - beep1T) / 0.15;
      else env = 1.0;
    } else if (t >= 0.21 && t < 0.50) {
      final beep2T = (t - 0.21) / 0.29;
      if (beep2T < 0.08) env = beep2T / 0.08;
      else if (beep2T > 0.82) env = (1.0 - beep2T) / 0.18;
      else env = 1.0;
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
