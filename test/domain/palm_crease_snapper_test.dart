import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_crease_snapper.dart';
import 'package:sanctum/src/domain/services/palm_line_template.dart';

/// A crease drawn along a reference curve, falling off with distance.
///
/// Stands in for the ridge filter. Writing the field by hand is the
/// whole reason [RidgeField] is an interface rather than a bitmap: the
/// snapper can be tested against a crease whose position is known
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
      final distance = sample.distanceTo(point);
      if (distance < nearest) nearest = distance;
    }
    final ratio = nearest / sigma;
    return math.exp(-ratio * ratio);
  }
}

/// The strongest response of several creases at a point.
class _Creases implements RidgeField {
  _Creases(this.fields);

  final List<RidgeField> fields;

  @override
  double responseAt(PalmPoint point) =>
      fields.map((field) => field.responseAt(point)).reduce(math.max);
}

/// Nothing anywhere.
class _Blank implements RidgeField {
  const _Blank();

  @override
  double responseAt(PalmPoint point) => 0;
}

/// The curve as the snapper will see it, after its own subdivision.
///
/// `snap` returns more control points than it was given, so any test
/// that compares point-for-point has to compare against this rather than
/// against the template — otherwise it is asserting that subdivision
/// did not happen.
PalmCurve _refine(PalmCurve curve) {
  var refined = curve;
  for (var i = 0; i < PalmCreaseSnapper.defaultSubdivisions; i++) {
    refined = refined.subdivided();
  }
  return refined;
}

PalmCurve _shifted(PalmCurve curve, PalmPoint by) => curve.withControlPoints([
  for (final point in curve.controlPoints) point + by,
]);

double _meanDistanceToCrease(PalmCurve curve, PalmCurve crease) {
  final samples = crease.sample(perSegment: 40);
  final anchors = curve.anchors;
  var total = 0.0;
  for (final anchor in anchors) {
    var nearest = double.infinity;
    for (final sample in samples) {
      nearest = math.min(nearest, sample.distanceTo(anchor));
    }
    total += nearest;
  }
  return total / anchors.length;
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
      // Fate is drawn when the creases support it and named only then —
      // plenty of hands have none, and a line the user cannot find is a
      // claim they can disprove by looking down.
      expect(PalmLineTemplate.principal.map((curve) => curve.line), [
        PalmLine.heart,
        PalmLine.head,
        PalmLine.life,
      ]);
      expect(PalmLineTemplate.all.length, 4);
      expect(PalmLineTemplate.of(PalmLine.fate).line, PalmLine.fate);
    });

    test('keeps the heart line above the head line across the palm', () {
      // The one ordering palmistry will not forgive, and the easiest to
      // break while nudging coordinates.
      final heart = PalmLineTemplate.heart.sample();
      final head = PalmLineTemplate.head.sample();
      for (final point in heart) {
        final below = head.where((other) => (other.x - point.x).abs() < 0.05);
        for (final other in below) {
          expect(point.y, lessThan(other.y));
        }
      }
    });
  });

  group('snap', () {
    test('leaves a curve that already sits on its crease', () {
      final template = PalmLineTemplate.head;
      final refined = _refine(template);
      final snapped = PalmCreaseSnapper.snap(
        curve: template,
        field: _Crease(template),
      );

      for (var i = 0; i < refined.anchors.length; i++) {
        expect(
          snapped.anchors[i].distanceTo(refined.anchors[i]),
          lessThan(0.004),
        );
      }
    });

    test('pulls a curve onto a crease offset from the template', () {
      final template = PalmLineTemplate.head;
      final crease = _shifted(template, const PalmPoint(0, 0.02));

      final before = _meanDistanceToCrease(template, crease);
      final snapped = PalmCreaseSnapper.snap(
        curve: template,
        field: _Crease(crease),
      );
      final after = _meanDistanceToCrease(snapped, crease);

      expect(before, greaterThan(0.015));
      expect(after, lessThan(before / 3));
    });

    test('prefers the crease under it to an equal one further away', () {
      // What the falloff penalty buys. Without it the heart line walks
      // onto whichever neighbouring crease happens to read darker.
      final template = PalmLineTemplate.head;
      final near = _Crease(template);
      final far = _Crease(_shifted(template, const PalmPoint(0, 0.04)));

      final snapped = PalmCreaseSnapper.snap(
        curve: template,
        field: _Creases([near, far]),
      );

      expect(
        _meanDistanceToCrease(snapped, template),
        lessThan(0.006),
      );
    });

    test('never moves an anchor further than the search radius', () {
      final template = PalmLineTemplate.life;
      final refined = _refine(template);
      final crease = _shifted(template, const PalmPoint(0.2, 0));
      final snapped = PalmCreaseSnapper.snap(
        curve: template,
        field: _Crease(crease),
        searchRadius: 0.03,
      );

      for (var i = 0; i < refined.anchors.length; i++) {
        expect(
          snapped.anchors[i].distanceTo(refined.anchors[i]),
          lessThanOrEqualTo(0.03 + 1e-9),
        );
      }
    });

    test('preserves every tangent, so the curve does not kink', () {
      final template = PalmLineTemplate.heart;
      final refined = _refine(template);
      final snapped = PalmCreaseSnapper.snap(
        curve: template,
        field: _Crease(_shifted(template, const PalmPoint(0, 0.015))),
      );

      for (var i = 0; i < refined.segmentCount; i++) {
        final beforeOut = refined.controlPoints[i * 3].distanceTo(
          refined.controlPoints[i * 3 + 1],
        );
        final afterOut = snapped.controlPoints[i * 3].distanceTo(
          snapped.controlPoints[i * 3 + 1],
        );
        expect(afterOut, closeTo(beforeOut, 1e-9));
      }
    });

    test('spreads a single-anchor find across its neighbours', () {
      // Smoothing. One dark speck under one anchor must not produce a
      // curve with a spike in it — the neighbours come partway, so the
      // line bends instead of kinking.
      final template = PalmLineTemplate.head;
      final refined = _refine(template);
      final anchors = refined.anchors;
      const peak = 4;
      final speck = _Crease(
        PalmCurve(
          line: PalmLine.head,
          controlPoints: [
            anchors[peak] + const PalmPoint(-0.004, 0.028),
            anchors[peak] + const PalmPoint(-0.001, 0.028),
            anchors[peak] + const PalmPoint(0.001, 0.028),
            anchors[peak] + const PalmPoint(0.004, 0.028),
          ],
        ),
        sigma: 0.006,
      );

      final snapped = PalmCreaseSnapper.snap(curve: template, field: speck);
      final moved = [
        for (var i = 0; i < anchors.length; i++)
          snapped.anchors[i].distanceTo(anchors[i]),
      ];

      expect(moved[peak], greaterThan(0.002));
      expect(moved[peak - 1], greaterThan(0));
      expect(moved[peak + 1], greaterThan(0));
      expect(moved[peak - 1], lessThan(moved[peak]));
      expect(moved.first, lessThan(moved[peak]));
    });

    test('does nothing on a blank field', () {
      final template = PalmLineTemplate.life;
      final snapped = PalmCreaseSnapper.snap(
        curve: template,
        field: const _Blank(),
      );

      // Not the same control points — snapping subdivides first — but
      // the same curve, which is the claim that matters.
      expect(
        snapped.controlPoints.length,
        greaterThan(
          template.controlPoints.length,
        ),
      );
      final before = template.sample(perSegment: 16);
      final after = snapped.sample(perSegment: 4);
      expect(after.length, before.length);
      for (var i = 0; i < before.length; i++) {
        expect(after[i].distanceTo(before[i]), lessThan(1e-12));
      }
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

    test('refuses a curve that is not in canonical space', () {
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
      // The number the reading consults before it names the fate line.
      final fate = PalmLineTemplate.fate;
      final elsewhere = _Crease(PalmLineTemplate.life);

      expect(
        PalmCreaseSnapper.support(curve: fate, field: _Crease(fate)),
        greaterThan(
          PalmCreaseSnapper.support(curve: fate, field: elsewhere) + 0.5,
        ),
      );
    });
  });
}
