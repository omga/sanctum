// just_audio marks StreamAudioSource @experimental. It is used here with
// that risk accepted and contained: this file is the only place that
// touches the API, and it sits behind SanctumAudioService, so if the
// signature changes the blast radius is one class.
// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:meta/meta.dart';

/// One seamless period of a pure tone, for the player to loop forever.
///
/// ## Why this is tiny, and why it used to be enormous
///
/// A sine wave is *periodic*. A thirty-minute 528 Hz tone is 3,675
/// samples repeated 10,800 times — the same fraction of a second, over
/// and over. The first version of this class computed every one of those
/// repetitions: 79 MB and 79 million `sin()` calls for a single session.
///
/// That is the audio equivalent of re-rendering every frame of a film
/// that never changes. A video player opens a 20 GB file instantly
/// because the bytes already exist and it reads only the next second of
/// them. Our bytes do not exist — we compute them — so the equivalent
/// trick is not to stream harder, it is to notice that all but the first
/// 43 KB are duplicates.
///
/// So this generates exactly one whole number of cycles, and
/// `SanctumAudioService` plays it with `LoopMode.one`. Session length and
/// the fade in and out are handled there, by clock and volume, because
/// neither belongs in the waveform.
///
/// ## Seamlessness
///
/// The loop must contain an *integer* number of cycles, or the join
/// produces a discontinuity — an audible click once a second, forever.
/// For a sample rate `sr` and frequency `f`, the shortest such run is
/// `sr / gcd(f, sr)` samples; see [loopSampleCount].
class ToneAudioSource extends StreamAudioSource {
  /// Creates a looping source for [frequencyHz].
  ToneAudioSource({
    required this.frequencyHz,
    this.sampleRate = 22050,
    this.amplitude = 0.28,
  });

  /// Tone frequency in hertz.
  final double frequencyHz;

  /// Samples per second.
  ///
  /// 22.05 kHz, not 44.1. The highest tone in the catalogue is 963 Hz, so
  /// the Nyquist limit of 11 kHz is over ten times what a pure sine
  /// needs. The output is indistinguishable and every buffer is half the
  /// size.
  final int sampleRate;

  /// Peak amplitude, 0–1.
  ///
  /// Well below full scale. A full-scale sine is startlingly loud, and
  /// this is an app people fall asleep to.
  final double amplitude;

  static const int _headerBytes = 44;
  static const int _bytesPerSample = 2;

  /// Frequencies are treated to this precision when finding a period.
  ///
  /// One decimal place, so 136.1 Hz is exact rather than approximated.
  static const int _hzPrecision = 10;

  Uint8List? _cached;
  int _buildCount = 0;

  /// How many times the waveform has actually been generated.
  ///
  /// Exposed so the cache can be asserted directly rather than inferred
  /// from a stopwatch — a timing-based test of a cache is flaky by
  /// construction, and this one duly flaked under parallel load.
  @visibleForTesting
  int get buildCount => _buildCount;

  /// Samples in one seamless loop of [frequencyHz] at [sampleRate].
  ///
  /// Returns the shortest run containing a whole number of cycles,
  /// extended by whole periods until it is at least one second — a
  /// hundred-millisecond file makes some decoders work harder than the
  /// audio is worth.
  static int loopSampleCount(double frequencyHz, int sampleRate) {
    final numerator = (frequencyHz * _hzPrecision).round();
    final scaledRate = sampleRate * _hzPrecision;
    final period = scaledRate ~/ _gcd(numerator, scaledRate);

    final repeats = math.max(1, (sampleRate / period).ceil());
    return period * repeats;
  }

  static int _gcd(int a, int b) {
    var x = a;
    var y = b;
    while (y != 0) {
      final t = y;
      y = x % y;
      x = t;
    }
    return x;
  }

  /// The whole loop, header included. Built once, then reused.
  Uint8List get _bytes => _cached ??= _build();

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final data = _bytes;
    final from = start ?? 0;
    final to = end ?? data.length;

    return StreamAudioResponse(
      sourceLength: data.length,
      contentLength: to - from,
      offset: from,
      contentType: 'audio/wav',
      // No chunking, no laziness, no generator racing the player: the
      // whole asset is 43 KB and already in memory.
      stream: Stream.value(data.sublist(from, to)),
    );
  }

  Uint8List _build() {
    _buildCount++;
    final samples = loopSampleCount(frequencyHz, sampleRate);
    final dataBytes = samples * _bytesPerSample;
    final out = Uint8List(_headerBytes + dataBytes);
    final view = ByteData.view(out.buffer);

    _writeHeader(view, out, dataBytes);

    final step = 2 * math.pi * frequencyHz / sampleRate;
    for (var n = 0; n < samples; n++) {
      final value = math.sin(step * n) * amplitude;
      view.setInt16(
        _headerBytes + n * _bytesPerSample,
        (value * 32767).round(),
        Endian.little,
      );
    }

    return out;
  }

  void _writeHeader(ByteData view, Uint8List out, int dataBytes) {
    void ascii(int offset, String tag) {
      for (var i = 0; i < tag.length; i++) {
        out[offset + i] = tag.codeUnitAt(i);
      }
    }

    ascii(0, 'RIFF');
    view.setUint32(4, 36 + dataBytes, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    view
      ..setUint32(16, 16, Endian.little) // PCM chunk size
      ..setUint16(20, 1, Endian.little) // format = PCM
      ..setUint16(22, 1, Endian.little) // mono
      ..setUint32(24, sampleRate, Endian.little)
      ..setUint32(28, sampleRate * _bytesPerSample, Endian.little)
      ..setUint16(32, _bytesPerSample, Endian.little)
      ..setUint16(34, 16, Endian.little); // bits per sample
    ascii(36, 'data');
    view.setUint32(40, dataBytes, Endian.little);
  }
}
