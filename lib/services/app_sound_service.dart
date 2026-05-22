import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum AppSound { vote, coin, boost, badgeUnlock }

class AppSoundService {
  const AppSoundService._();

  static final Map<AppSound, Uint8List> _sounds = {
    AppSound.vote: _wave([
      const _Tone(523.25, 55),
      const _Tone(659.25, 85),
    ]),
    AppSound.coin: _wave([
      const _Tone(1046.5, 38),
      const _Tone(1318.51, 48),
      const _Tone(1567.98, 82),
    ]),
    AppSound.boost: _wave([
      const _Tone(392, 42),
      const _Tone(523.25, 52),
      const _Tone(783.99, 115),
    ]),
    AppSound.badgeUnlock: _wave([
      const _Tone(659.25, 60),
      const _Tone(830.61, 60),
      const _Tone(987.77, 72),
      const _Tone(1318.51, 150),
    ]),
  };

  static Future<void> play(AppSound sound) async {
    try {
      final player = AudioPlayer();
      player.onPlayerComplete.listen((_) => player.dispose());
      await player.setVolume(0.72);
      await player.play(
        BytesSource(_sounds[sound]!, mimeType: 'audio/wav'),
      );
    } catch (error) {
      debugPrint('AppSoundService play error: $error');
      // Sound is polish. It must not block the product action.
    }
  }

  static Uint8List _wave(List<_Tone> tones) {
    const sampleRate = 22050;
    const sampleBytes = 2;
    const channels = 1;
    const amplitude = 11200;
    const silenceMs = 12;
    final samples = <int>[];

    for (final tone in tones) {
      final toneSamples = sampleRate * tone.durationMs ~/ 1000;
      for (var i = 0; i < toneSamples; i++) {
        final progress = i / math.max(toneSamples - 1, 1);
        final envelope = math.sin(math.pi * progress);
        final sample = math.sin(2 * math.pi * tone.hz * i / sampleRate);
        samples.add((sample * envelope * amplitude).round());
      }
      samples.addAll(List.filled(sampleRate * silenceMs ~/ 1000, 0));
    }

    final dataSize = samples.length * sampleBytes;
    final bytes = ByteData(44 + dataSize);
    _ascii(bytes, 0, 'RIFF');
    bytes.setUint32(4, 36 + dataSize, Endian.little);
    _ascii(bytes, 8, 'WAVE');
    _ascii(bytes, 12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, channels, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * sampleBytes * channels, Endian.little);
    bytes.setUint16(32, sampleBytes * channels, Endian.little);
    bytes.setUint16(34, sampleBytes * 8, Endian.little);
    _ascii(bytes, 36, 'data');
    bytes.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < samples.length; i++) {
      bytes.setInt16(44 + (i * sampleBytes), samples[i], Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  static void _ascii(ByteData bytes, int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes.setUint8(offset + i, value.codeUnitAt(i));
    }
  }
}

class _Tone {
  final double hz;
  final int durationMs;

  const _Tone(this.hz, this.durationMs);
}
