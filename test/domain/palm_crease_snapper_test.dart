import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_crease_snapper.dart';
import 'package:sanctum/src/domain/services/palm_line_template.dart';

/// A crease drawn along a reference curve, falling off with distance.
///
/// Stands in for the ridge filter. Writing the field by hand is the
/// whole reason [RidgeField] is an interface rather than a bitmap: the
/// tracer can be tested against a crease whose position is known
/// exactly, which no photograph would give us.
class _Crease implements RidgeField {
  _Crease(PalmCurve reference, {this.sigma = 0.012})
    : _samples = reference.sample(perSegment: 40);

  final List<PalmPoint> _samples;
  final double sigma;

  @override
  double responseAt(PalmPoint point) {
    var nearest = double.infinity;
    for (final sample in _samples) {
      nearest = math.min(nearest, sample.distanceTo(point));
    }
    final ratio = nearest / sigma;
    return math.exp(-ratio * ratio);
  }
}

/// The strongest response of several fields at a point.
class _Creases implements RidgeField {
  _Creases(this.fields);

  final List<RidgeField> fields;

  @override
  double responseAt(PalmPoint point) =>
      fields.map((field) => field.responseAt(point)).reduce(math.max);
}

/// One dark speck and nothing else.
class _Speck implements RidgeField {
  const _Speck(this.centre);

  final PalmPoint centre;

  @override
  double responseAt(PalmPoint point) {
    final ratio = point.distanceTo(centre) / 0.008;
    return math.exp(-ratio * ratio);
  }
}

/// Nothing anywhere.
class _Blank implements RidgeField {
  const _Blank();

  @override
  double responseAt(PalmPoint point) => 0;
}

PalmCurve _shifted(PalmCurve curve, PalmPoint by) => curve.withControlPoints([
  for (final point in curve.controlPoints) point + by,
]);

/// [curve] bowed by [depth] in `y`, pinned at both ends.
PalmCurve _bowed(PalmCurve curve, double depth) {
  final count = curve.controlPoints.length;
  return curve.withControlPoints([
    for (var i = 0; i < count; i++)
      curve.controlPoints[i] +
          PalmPoint(0, depth * math.sin(math.pi * i / (count - 1))),
  ]);
}

/// Mean distance from [curve] to the nearest point of [crease].
double _meanDistance(PalmCurve curve, PalmCurve crease) {
  final targets = crease.sample(perSegment: 40);
  final points = curve.sample(perSegment: 4);
  var total = 0.0;
  for (final point in points) {
    var nearest = double.infinity;
    for (final target in targets) {
      nearest = math.min(nearest, target.distanceTo(point));
    }
    total += nearest;
  }
  return total / points.length;
}

void main() {
  group('the template', () {
    test('is a well-formed cubic chain inside the palm', () {
      for (final curve in PalmLineTemplate.all) {
        expect(curve.space, PalmSpace.canonical);
        expect(curve.controlPoints.length % 3, 1);
        expect(curve.controlPoints.length, greaterThanOrEqualTo(4));
        for (final point in curve.controlPoints) {
          expect(point.x, inInclusiveRange(0, 1));
          expect(point.y, inInclusiveRange(0, 1));
        }
      }
    });

    test('claims only the three lines every hand has', () {
      expect(PalmLineTemplate.principal.map((curve) => curve.line), [
        PalmLine.heart,
        PalmLine.head,
        PalmLine.life,
      ]);
      expect(PalmLineTemplate.all.length, 4);
      expect(PalmLineTemplate.of(PalmLine.fate).line, PalmLine.fate);
    });

    test('keeps the heart line above the head line across the palm', () {
      final heart = PalmLineTemplate.heart.sample();
      final head = PalmLineTemplate.head.sample();
      for (final point in heart) {
        for (final other in head.where((o) => (o.x - point.x).abs() < 0.05)) {
          expect(point.y, lessThan(other.y));
        }
      }
    });

    test('bows the life line toward the palm, round the thumb', () {
      // Authored backwards once. The life line encloses the ball of the
      // thumb, so its middle sits further from the thumb side (larger x)
      // than the straight line between its ends.
      final life = PalmLineTemplate.life;
      final start = life.controlPoints.first;
      final end = life.controlPoints.last;
      final middle = life.sample(perSegment: 20)[20];
      final t = (middle.y - start.y) / (end.y - start.y);
      final chordX = start.x + (end.x - start.x) * t;

      expect(middle.x, greaterThan(chordX + 0.05));
    });
  });

  group('trace', () {
    test('leaves a line that already sits on its crease', () {
      final template = PalmLineTemplate.head;
      final traced = PalmCreaseSnapper.snap(
        curve: template,
        field: _Crease(template),
      );
      expect(_meanDistance(traced, template), lessThan(0.004));
    });

    test('pulls a line onto a crease offset from the template', () {
      final template = PalmLineTemplate.head;
      final crease = _shifted(template, const PalmPoint(0, 0.035));

      final before = _meanDistance(template, crease);
      final traced = PalmCreaseSnapper.snap(
        curve: template,
        field: _Crease(crease),
      );

      expect(before, greaterThan(0.03));
      expect(_meanDistance(traced, crease), lessThan(before / 3));
    });

    test('follows a crease that bends the other way', () {
      // The life-line lesson, as a test. A template's curvature is a
      // guess; the photograph's is not. The old per-point snapper could
      // only nudge each anchor a little, so a crease bowing the opposite
      // way stayed out of reach at its middle — exactly where the
      // difference is largest.
      final template = PalmLineTemplate.heart;
      final crease = _bowed(template, 0.07);

      final before = _meanDistance(template, crease);
      final traced = PalmCreaseSnapper.snap(
        curve: template,
        field: _Crease(crease),
      );

      expect(_meanDistance(traced, crease), lessThan(before / 2));
    });

    test('prefers the crease under it to an equal one further away', () {
      final template = PalmLineTemplate.head;
      final traced = PalmCreaseSnapper.snap(
        curve: template,
        field: _Creases([
          _Crease(template),
          _Crease(_shifted(template, const PalmPoint(0, 0.04))),
        ]),
      );

      expect(_meanDistance(traced, template), lessThan(0.006));
    });

    test('is not pulled into a detour by a single speck', () {
      // A mole, a crumb, the edge of a ring: strong, dark and short. A
      // one-station gain cannot pay for bending out and back, so the line
      // stays put where a real crease would have drawn it across.
      final template = PalmLineTemplate.heart;
      final middle = template.controlPoints[3];
      final traced = PalmCreaseSnapper.snap(
        curve: template,
        field: _Speck(middle + const PalmPoint(0, 0.06)),
      );

      final nearest = traced
          .sample(perSegment: 8)
          .map((point) => point.distanceTo(middle))
          .reduce(math.min);
      expect(nearest, lessThan(0.015));
    });

    test('never moves further than the band', () {
      final template = PalmLineTemplate.life;
      final traced = PalmCreaseSnapper.snap(
        curve: template,
        field: _Crease(_shifted(template, const PalmPoint(0.2, 0))),
        band: 0.03,
      );

      final allowed = template.sample(perSegment: 40);
      for (final point in traced.sample(perSegment: 4)) {
        final nearest = allowed
            .map((other) => other.distanceTo(point))
            .reduce(math.min);
        expect(nearest, lessThanOrEqualTo(0.03 + 0.002));
      }
    });

    test('comes out smooth, with no kinks', () {
      final traced = PalmCreaseSnapper.snap(
        curve: PalmLineTemplate.heart,
        field: _Crease(_bowed(PalmLineTemplate.heart, 0.07)),
      );

      final points = traced.sample(perSegment: 4);
      for (var i = 1; i < points.length - 1; i++) {
        final a = (points[i] - points[i - 1]).normalized;
        final b = (points[i + 1] - points[i]).normalized;
        final turn = math.acos((a.x * b.x + a.y * b.y).clamp(-1.0, 1.0));
        expect(turn, lessThan(math.pi / 9), reason: 'at sample $i');
      }
    });

    test('stays on the template on a blank palm', () {
      final template = PalmLineTemplate.life;
      final traced = PalmCreaseSnapper.snap(
        curve: template,
        field: const _Blank(),
      );
      expect(_meanDistance(traced, template), lessThan(0.004));
    });

    test('refuses a line that is not in canonical space', () {
      final placed = PalmCurve(
        line: PalmLine.head,
        controlPoints: PalmLineTemplate.head.controlPoints,
        space: PalmSpace.image,
      );
      expect(
        () => PalmCreaseSnapper.snap(curve: placed, field: const _Blank()),
        throwsA(isA<AssertionError>()),
      );
    });

    test('subdivision traces the same curve exactly', () {
      for (final template in PalmLineTemplate.all) {
        final once = template.subdivided();
        expect(once.segmentCount, template.segmentCount * 2);
        final before = template.sample(perSegment: 16);
        final after = once.sample(perSegment: 8);
        expect(after.length, before.length);
        for (var i = 0; i < before.length; i++) {
          expect(after[i].distanceTo(before[i]), lessThan(1e-12));
        }
      }
    });
  });

  group('support', () {
    test('is high on a crease and nil on a blank palm', () {
      final template = PalmLineTemplate.fate;
      expect(
        PalmCreaseSnapper.support(curve: template, field: _Crease(template)),
        greaterThan(0.8),
      );
      expect(
        PalmCreaseSnapper.support(curve: template, field: const _Blank()),
        0,
      );
    });

    test('separates a hand with a fate line from one without', () {
      final fate = PalmLineTemplate.fate;
      expect(
        PalmCreaseSnapper.support(curve: fate, field: _Crease(fate)),
        greaterThan(
          PalmCreaseSnapper.support(
                curve: fate,
                field: _Crease(PalmLineTemplate.life),
              ) +
              0.5,
        ),
      );
    });
  });
}
