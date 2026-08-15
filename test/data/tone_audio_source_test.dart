import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/data/services/audio/tone_audio_source.dart';

ToneAudioSource source({double hz = 528}) => ToneAudioSource(frequencyHz: hz);

Future<Uint8List> collect(Stream<List<int>> stream) async {
  final out = <int>[];
  await stream.forEach(out.addAll);
  return Uint8List.fromList(out);
}

void main() {
  group('loop geometry', () {
    test('a loop contains a whole number of cycles', () {
      // The seamlessness requirement. A fractional cycle leaves a
      // discontinuity at the join, heard as a click once per loop —
      // forever, for the whole session.
      const rate = 22050;
      for (final hz in [174.0, 285.0, 396.0, 417.0, 528.0, 963.0, 136.1]) {
        final samples = ToneAudioSource.loopSampleCount(hz, rate);
        final cycles = samples * hz / rate;

        expect(
          (cycles - cycles.roundToDouble()).abs(),
          lessThan(1e-9),
          reason: '$hz Hz gives $cycles cycles, which is not whole',
        );
      }
    });

    test('every loop is at least a second long', () {
      const rate = 22050;
      for (final hz in [174.0, 528.0, 963.0]) {
        expect(
          ToneAudioSource.loopSampleCount(hz, rate),
          greaterThanOrEqualTo(rate),
          reason: '$hz Hz loop is shorter than a second',
        );
      }
    });

    test('the whole asset is small, whatever the session length', () async {
      // A session's duration is no longer a property of the audio at
      // all — the player loops this. Thirty minutes and thirty seconds
      // are the same 43 KB.
      final bytes = await collect((await source().request()).stream);
      expect(bytes.length, lessThan(100 * 1024));
    });
  });

  group('wav output', () {
    test('is a header a decoder can read', () async {
      final bytes = await collect((await source().request()).stream);

      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');

      final view = ByteData.view(bytes.buffer);
      expect(view.getUint16(20, Endian.little), 1, reason: 'PCM');
      expect(view.getUint16(22, Endian.little), 1, reason: 'mono');
      expect(view.getUint16(34, Endian.little), 16, reason: '16-bit');
      expect(view.getUint32(24, Endian.little), 22050);
      // Declared data size must match what actually follows.
      expect(view.getUint32(40, Endian.little), bytes.length - 44);
    });

    test('joins seamlessly end to start', () async {
      // The last sample and the first must be adjacent on the waveform.
      // If they are not, the loop clicks.
      final bytes = await collect((await source().request()).stream);
      final view = ByteData.view(bytes.buffer);

      final first = view.getInt16(44, Endian.little);
      final last = view.getInt16(bytes.length - 2, Endian.little);
      final secondToLast = view.getInt16(bytes.length - 4, Endian.little);

      // Continuing the final step must land near the first sample.
      final projected = last + (last - secondToLast);
      expect(
        (projected - first).abs(),
        lessThan(2000),
        reason: 'discontinuity at the loop join: $projected vs $first',
      );
    });

    test('serves byte ranges', () async {
      final whole = await collect((await source().request()).stream);
      final slice = await collect((await source().request(100, 200)).stream);

      expect(slice.length, 100);
      expect(slice, whole.sublist(100, 200));
    });
  });

  test('BENCH: open cost no longer scales with session length', () async {
    // The regression this design removes. Building a full-length
    // waveform cost 305/697/717 ms for 10/20/30 minutes, drained
    // eagerly by the proxy the moment the player opened. There is now
    // no such thing as a full-length waveform.
    final watch = Stopwatch()..start();
    for (final hz in [174.0, 528.0, 963.0, 136.1]) {
      await collect((await ToneAudioSource(frequencyHz: hz).request()).stream);
    }
    watch.stop();

    // Benchmark output is the point of this test.
    // ignore: avoid_print
    print('\nall four tones built in ${watch.elapsedMilliseconds} ms');
    expect(watch.elapsedMilliseconds, lessThan(200));
  });

  test('the built loop is cached, not rebuilt per request', () async {
    final src = source();
    expect(src.buildCount, 0, reason: 'nothing built until first read');

    for (var i = 0; i < 20; i++) {
      await collect((await src.request()).stream);
    }

    expect(
      src.buildCount,
      1,
      reason: 'twenty reads must not cost twenty builds',
    );
  });
}
