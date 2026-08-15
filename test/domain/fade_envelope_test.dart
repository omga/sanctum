import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/services/fade_envelope.dart';

double volume(int seconds, {int totalMinutes = 20, int fadeSeconds = 4}) =>
    FadeEnvelope.volumeAt(
      position: Duration(seconds: seconds),
      total: Duration(minutes: totalMinutes),
      fade: Duration(seconds: fadeSeconds),
    );

void main() {
  group('FadeEnvelope', () {
    test('starts and ends at silence', () {
      // The whole point. A tone that begins or ends at full amplitude
      // is a step discontinuity, which is audible as a tick.
      expect(volume(0), 0);
      expect(volume(20 * 60), 0);
    });

    test('ramps up linearly over the fade', () {
      expect(volume(1), closeTo(0.25, 0.001));
      expect(volume(2), closeTo(0.5, 0.001));
      expect(volume(3), closeTo(0.75, 0.001));
      expect(volume(4), 1);
    });

    test('holds full volume through the middle', () {
      expect(volume(60), 1);
      expect(volume(600), 1);
      expect(volume(20 * 60 - 5), 1);
    });

    test('ramps down over the final fade', () {
      expect(volume(20 * 60 - 4), 1);
      expect(volume(20 * 60 - 3), closeTo(0.75, 0.001));
      expect(volume(20 * 60 - 1), closeTo(0.25, 0.001));
    });

    test('never leaves [0, 1], across an entire session', () {
      for (var s = -10; s <= 20 * 60 + 10; s += 1) {
        final v = volume(s);
        expect(v, inInclusiveRange(0, 1), reason: 'at ${s}s');
      }
    });

    test('a session shorter than two fades peaks lower, never clips', () {
      // 6-second session with a 4-second fade: the ramps overlap. It
      // must peak below 1 rather than exceed it or jump.
      double v(int seconds) => FadeEnvelope.volumeAt(
        position: Duration(seconds: seconds),
        total: const Duration(seconds: 6),
        fade: const Duration(seconds: 4),
      );

      expect(v(0), 0);
      expect(v(3), closeTo(0.75, 0.001));
      expect(v(6), 0);
      for (var s = 0; s <= 6; s++) {
        expect(v(s), inInclusiveRange(0, 1));
      }
    });

    test('is monotonic up then down, with no jumps', () {
      // A jump anywhere in the envelope is itself a click.
      var previous = volume(0);
      for (var s = 1; s <= 20 * 60; s++) {
        final current = volume(s);
        expect(
          (current - previous).abs(),
          lessThanOrEqualTo(0.26),
          reason: 'volume jumped at ${s}s: $previous -> $current',
        );
        previous = current;
      }
    });

    test('degenerate inputs are silent or full, never NaN', () {
      expect(
        FadeEnvelope.volumeAt(
          position: Duration.zero,
          total: Duration.zero,
          fade: const Duration(seconds: 4),
        ),
        0,
      );
      expect(
        FadeEnvelope.volumeAt(
          position: const Duration(seconds: 5),
          total: const Duration(minutes: 10),
          fade: Duration.zero,
        ),
        1,
      );
    });
  });
}
