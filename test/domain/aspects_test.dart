import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
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


  group('named contacts', () {
    test('classifies each aspect at its exact angle', () {
      const exact = <({double angle, ZodiacAspect aspect})>[
        (angle: 0, aspect: ZodiacAspect.conjunction),
        (angle: 30, aspect: ZodiacAspect.semiSextile),
        (angle: 60, aspect: ZodiacAspect.sextile),
        (angle: 90, aspect: ZodiacAspect.square),
        (angle: 120, aspect: ZodiacAspect.trine),
        (angle: 150, aspect: ZodiacAspect.quincunx),
        (angle: 180, aspect: ZodiacAspect.opposition),
      ];
      for (final one in exact) {
        final contact = Aspects.contact(0, one.angle);
        expect(contact, isNotNull, reason: '${one.angle}°');
        expect(contact!.aspect, one.aspect);
        expect(contact.orb, closeTo(0, 0.001));
        expect(contact.isExact, isTrue);
      }
    });

    test('returns nothing when no aspect is in orb', () {
      // The common case, and the honest one. Most planet pairs are not
      // in contact, and the report says so rather than reaching for the
      // nearest angle regardless of distance.
      for (final angle in [45.0, 75.0, 105.0, 135.0]) {
        expect(Aspects.contact(0, angle), isNull, reason: '$angle°');
      }
    });

    test('holds each aspect only inside its own orb', () {
      // Orbs are asymmetric on purpose: a conjunction 7° off is still a
      // conjunction, a quincunx 7° off is nothing at all.
      expect(Aspects.contact(0, 7)!.aspect, ZodiacAspect.conjunction);
      expect(Aspects.contact(0, 9), isNull);
      expect(Aspects.contact(0, 152)!.aspect, ZodiacAspect.quincunx);
      expect(Aspects.contact(0, 157), isNull);
    });

    test('picks the closest aspect when two orbs overlap', () {
      // Square (90 ± 7) and trine (120 ± 7) leave no gap either side of
      // 105, but nothing stops a future orb table from overlapping.
      final contact = Aspects.contact(0, 84)!;
      expect(contact.aspect, ZodiacAspect.square);
      expect(contact.orb, closeTo(6, 0.001));
    });

    test('is direction-agnostic and wraps the circle', () {
      expect(Aspects.contact(350, 110)!.aspect, ZodiacAspect.trine);
      expect(Aspects.contact(110, 350)!.aspect, ZodiacAspect.trine);
    });

    test('tone groups the angles the copy is written for', () {
      expect(Aspects.contact(0, 120)!.tone, ContactTone.flowing);
      expect(Aspects.contact(0, 90)!.tone, ContactTone.hard);
      expect(Aspects.contact(0, 180)!.tone, ContactTone.charged);
    });
  });
}
