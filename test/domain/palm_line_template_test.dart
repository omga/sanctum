import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_geometry.dart';
import 'package:sanctum/src/domain/services/palm_line_template.dart';

final PalmPoint _canonicalThumb =
    PalmGeometry.canonicalHand[PalmLandmark.thumbCmc]!;

void main() {
  group('lifeAround', () {
    test(
      'is the plain template for a thumb where the canonical hand has it',
      () {
        final fitted = PalmLineTemplate.lifeAround(_canonicalThumb);
        final plain = PalmLineTemplate.life;
        for (var i = 0; i < plain.controlPoints.length; i++) {
          expect(
            fitted.controlPoints[i].distanceTo(plain.controlPoints[i]),
            lessThan(1e-12),
          );
        }
      },
    );

    test('follows a thumb set further out, from the middle down', () {
      // The Pixel 6 case: a thumb base further toward the thumb side than
      // the canonical hand's. The lower life line has to move with it.
      const shift = PalmPoint(-0.08, 0);
      final fitted = PalmLineTemplate.lifeAround(_canonicalThumb + shift);
      final plain = PalmLineTemplate.life;

      expect(
        fitted.controlPoints.last.x,
        closeTo(plain.controlPoints.last.x - 0.08, 1e-9),
      );
      expect(fitted.anchors[1].x, lessThan(plain.anchors[1].x - 0.05));
    });

    test('leaves its start where the head line starts', () {
      // That end is tied to the index web, not the thumb.
      final fitted = PalmLineTemplate.lifeAround(
        _canonicalThumb + const PalmPoint(-0.1, 0.05),
      );
      expect(
        fitted.controlPoints.first.distanceTo(
          PalmLineTemplate.life.controlPoints.first,
        ),
        lessThan(1e-12),
      );
    });

    test('never moves further than the guard allows', () {
      // A misdetected or folded thumb must not drag the prior across the
      // palm; the tracer only searches a tenth of a palm from wherever it
      // is put.
      final fitted = PalmLineTemplate.lifeAround(
        _canonicalThumb + const PalmPoint(-0.9, 0.4),
      );
      final plain = PalmLineTemplate.life;
      for (var i = 0; i < plain.controlPoints.length; i++) {
        expect(
          fitted.controlPoints[i].distanceTo(plain.controlPoints[i]),
          lessThanOrEqualTo(PalmLineTemplate.maxThumbShift + 1e-9),
        );
      }
    });

    test('stays inside the palm', () {
      final fitted = PalmLineTemplate.lifeAround(
        _canonicalThumb + const PalmPoint(0.3, 0.3),
      );
      for (final point in fitted.controlPoints) {
        expect(point.x, inInclusiveRange(0, 1));
        expect(point.y, inInclusiveRange(0, 1));
      }
    });
  });

  group('forHand', () {
    test('fits only the life line', () {
      // Heart and head landed on their creases on a real palm; they do
      // not depend on the thumb and must not move with it.
      final fitted = PalmLineTemplate.forHand(
        thumbBase: _canonicalThumb + const PalmPoint(-0.08, 0),
      );
      expect(fitted.map((curve) => curve.line), [
        PalmLine.heart,
        PalmLine.head,
        PalmLine.life,
        PalmLine.fate,
      ]);
      expect(identical(fitted[0], PalmLineTemplate.heart), isTrue);
      expect(identical(fitted[1], PalmLineTemplate.head), isTrue);
      expect(identical(fitted[3], PalmLineTemplate.fate), isTrue);
      expect(identical(fitted[2], PalmLineTemplate.life), isFalse);
    });

    test('is the plain set when no thumb is known', () {
      expect(PalmLineTemplate.forHand(), PalmLineTemplate.all);
    });
  });
}
