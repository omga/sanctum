import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_composer.dart';
import 'package:sanctum/src/domain/services/palm_crease_snapper.dart';
import 'package:sanctum/src/domain/services/palm_line_template.dart';
import 'package:sanctum/src/domain/services/palm_reading_composer.dart';

import '../support/palm_fixtures.dart';

final _at = DateTime.utc(2026, 9, 8, 10, 12);

/// Creases along whichever curves are handed in.
class _Creases implements RidgeField {
  _Creases(Iterable<PalmCurve> curves)
    : _samples = [
        for (final curve in curves) ...curve.sample(perSegment: 40),
      ];

  final List<PalmPoint> _samples;

  static const double _sigma = 0.014;

  @override
  double responseAt(PalmPoint point) {
    var nearest = double.infinity;
    for (final sample in _samples) {
      nearest = math.min(nearest, sample.distanceTo(point));
    }
    final ratio = nearest / _sigma;
    return math.exp(-ratio * ratio);
  }
}

PalmProfile _profileFrom(RidgeField? field) => PalmReadingComposer.compose(
  PalmComposer.compose(landmarks: goodHand(), at: _at, field: field)!,
);

void main() {
  group('compose', () {
    test('notes every line the hand claimed, in the drawn order', () {
      final profile = _profileFrom(null);
      expect(
        profile.notes.map((note) => note.line),
        PalmLine.principal,
      );
      expect(profile.id, startsWith('palm:'));
    });

    test('reads a line that matches the template as typical', () {
      final profile = _profileFrom(
        _Creases(PalmLineTemplate.principal),
      );
      for (final note in profile.notes) {
        expect(note.length, PalmLineLength.typical);
      }
    });

    test('carries clarity through from what the photograph showed', () {
      final clear = _profileFrom(_Creases(PalmLineTemplate.principal));
      expect(clear.clarity, greaterThan(0.5));
      expect(clear.measured, isTrue);
      expect(clear.isThin, isFalse);
    });

    test('offers a retake when it looked and found almost nothing', () {
      // A field with creases nowhere near the lines: measured, and
      // measured badly.
      final elsewhere = _profileFrom(
        _Creases([
          PalmCurve(
            line: PalmLine.fate,
            controlPoints: const [
              PalmPoint(0.02, 0.02),
              PalmPoint(0.03, 0.03),
              PalmPoint(0.04, 0.04),
              PalmPoint(0.05, 0.05),
            ],
          ),
        ]),
      );

      expect(elsewhere.measured, isTrue);
      expect(elsewhere.isThin, isTrue);
    });

    test('does not call an unmeasured scan faint', () {
      // "We did not look" is not evidence that a hand read faintly.
      // Conflating the two sends everybody on a build with no crease
      // filter back to the camera for no reason.
      final unmeasured = _profileFrom(null);

      expect(unmeasured.measured, isFalse);
      expect(unmeasured.clarity, 0);
      expect(unmeasured.isThin, isFalse);
    });

    test(
      'measures in canonical space, so distance to the lens is not a claim',
      () {
        // The bug this guards against would tell somebody their life line
        // grew because they stepped towards the camera.
        final field = _Creases(PalmLineTemplate.principal);
        PalmProfile at(double scale) => PalmReadingComposer.compose(
          PalmComposer.compose(
            landmarks: handAt(pose(scale: scale)),
            at: _at,
            field: field,
          )!,
        );

        final near = at(0.62);
        final far = at(0.38);
        for (final line in PalmLine.principal) {
          expect(near.noteOf(line)!.length, far.noteOf(line)!.length);
          expect(
            near.noteOf(line)!.clarity,
            closeTo(far.noteOf(line)!.clarity, 1e-9),
          );
        }
      },
    );

    test('has no note for a line the hand did not claim', () {
      expect(_profileFrom(null).noteOf(PalmLine.fate), isNull);
    });
  });
}
