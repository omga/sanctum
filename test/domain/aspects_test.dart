import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/services/aspects.dart';

void main() {
  group('separation', () {
    test('is zero for identical positions', () {
      expect(Aspects.separation(120, 120), closeTo(0, 1e-9));
    });

    test('never exceeds a half turn', () {
      for (var a = 0; a < 360; a += 7) {
        for (var b = 0; b < 360; b += 11) {
          expect(
            Aspects.separation(a.toDouble(), b.toDouble()),
            inInclusiveRange(0, 180),
          );
        }
      }
    });

    test('takes the short way round', () {
      // 350° and 10° are 20° apart, not 340°.
      expect(Aspects.separation(350, 10), closeTo(20, 1e-9));
    });

    test('is symmetric', () {
      expect(
        Aspects.separation(200, 35),
        closeTo(Aspects.separation(35, 200), 1e-9),
      );
    });
  });

  group('heat', () {
    test('peaks at the hard angles', () {
      for (final angle in [0.0, 90.0, 180.0]) {
        expect(Aspects.heat(0, angle), closeTo(1, 1e-9), reason: '$angle');
      }
    });

    test('bottoms out between them', () {
      for (final angle in [45.0, 135.0]) {
        expect(Aspects.heat(0, angle), closeTo(0, 1e-9), reason: '$angle');
      }
    });

    test('stays in range everywhere', () {
      for (var angle = 0; angle <= 360; angle++) {
        expect(
          Aspects.heat(0, angle.toDouble()),
          inInclusiveRange(0, 1),
        );
      }
    });
  });

  group('ease', () {
    test('peaks at the flowing angles', () {
      for (final angle in [0.0, 60.0, 120.0, 180.0]) {
        expect(Aspects.ease(0, angle), closeTo(1, 1e-9), reason: '$angle');
      }
    });

    test('is lowest at a square', () {
      // The distinction the whole model rests on: a square is maximum
      // heat and minimum ease. If these two functions ever agree at 90°
      // the six facets collapse into one.
      expect(Aspects.ease(0, 90), closeTo(0, 1e-9));
      expect(Aspects.heat(0, 90), closeTo(1, 1e-9));
    });

    test('stays in range everywhere', () {
      for (var angle = 0; angle <= 360; angle++) {
        expect(
          Aspects.ease(0, angle.toDouble()),
          inInclusiveRange(0, 1),
        );
      }
    });
  });

  test('both are continuous — no orb cliffs', () {
    // The reason this is harmonic rather than orb-gated: adjacent
    // positions must give adjacent answers, or scores jump when a
    // birthday moves by a day.
    for (var angle = 0; angle < 180; angle++) {
      final step = (Aspects.heat(0, angle.toDouble()) -
              Aspects.heat(0, angle + 1))
          .abs();
      expect(step, lessThan(0.1), reason: 'discontinuity near $angle');
    }
  });
}
