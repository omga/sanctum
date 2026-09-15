import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_geometry.dart';
import 'package:sanctum/src/domain/services/palm_silhouette.dart';

import '../support/palm_fixtures.dart';

List<PalmPoint> _canonical() => [
  for (final landmark in PalmLandmark.values)
    PalmGeometry.canonicalHand[landmark]!,
];

double _span(List<PalmPoint> hand) => hand[PalmLandmark.indexMcp.index]
    .distanceTo(hand[PalmLandmark.pinkyMcp.index]);

/// Whether segments ab and cd cross, excluding shared endpoints.
bool _cross(PalmPoint a, PalmPoint b, PalmPoint c, PalmPoint d) {
  double orient(PalmPoint p, PalmPoint q, PalmPoint r) =>
      (q.x - p.x) * (r.y - p.y) - (q.y - p.y) * (r.x - p.x);
  final o1 = orient(a, b, c);
  final o2 = orient(a, b, d);
  final o3 = orient(c, d, a);
  final o4 = orient(c, d, b);
  return (o1 > 0) != (o2 > 0) && (o3 > 0) != (o4 > 0);
}

int _selfIntersections(List<PalmPoint> polyline) {
  var crossings = 0;
  for (var i = 0; i < polyline.length - 1; i++) {
    for (var j = i + 2; j < polyline.length - 1; j++) {
      if (_cross(polyline[i], polyline[i + 1], polyline[j], polyline[j + 1])) {
        crossings++;
      }
    }
  }
  return crossings;
}

void main() {
  group('the outline', () {
    test('is a well-formed cubic chain', () {
      final chain = PalmSilhouette.outline(_canonical());
      expect(chain.length % 3, 1);
      expect(chain.length, greaterThan(100));
      for (final point in chain) {
        expect(point.x.isFinite && point.y.isFinite, isTrue);
      }
    });

    test('never crosses itself', () {
      // The property that separates an outline from a scribble, and the
      // one the uniform Catmull-Rom spline fails at fingertips and webs,
      // where neighbouring points are unevenly spaced. Checked on both
      // hands and at an angle, because every side is chosen relative to
      // the hand rather than to the screen.
      final poses = {
        'canonical': _canonical(),
        'right hand, posed': handAt(pose()).points,
        'left hand': handAt(
          pose(mirror: true),
          handedness: Handedness.left,
        ).points,
        'rotated': handAt(pose(rotation: 0.6)).points,
      };

      for (final entry in poses.entries) {
        final samples = PalmSilhouette.sample(
          PalmSilhouette.outline(entry.value),
          perSegment: 6,
        );
        expect(_selfIntersections(samples), 0, reason: entry.key);
      }
    });

    test('reaches past every fingertip and the thumb', () {
      // The tip landmark sits inside the pad of the finger, so an outline
      // that stopped at it would draw every finger a little short.
      final hand = _canonical();
      final samples = PalmSilhouette.sample(PalmSilhouette.outline(hand));
      const chains = [
        (PalmLandmark.indexMcp, PalmLandmark.indexTip),
        (PalmLandmark.middleMcp, PalmLandmark.middleTip),
        (PalmLandmark.ringMcp, PalmLandmark.ringTip),
        (PalmLandmark.pinkyMcp, PalmLandmark.pinkyTip),
        (PalmLandmark.thumbCmc, PalmLandmark.thumbTip),
      ];

      for (final (base, tip) in chains) {
        final from = hand[base.index];
        final reach = hand[tip.index].distanceTo(from);
        final furthest = samples
            .map((point) => point.distanceTo(from))
            .reduce(math.max);
        expect(furthest, greaterThan(reach), reason: '$tip');
      }
    });

    test('draws the thumb where the thumb is', () {
      // The complaint that produced this class. The outline used to be the
      // canonical hand pushed through a warp fitted to the knuckles, so
      // its thumb stayed at the canonical angle whatever the user's thumb
      // was doing. Tucked or splayed, the outline has to go round the
      // actual tip.
      final splayed = _canonical();
      final tucked = [...splayed];
      tucked[PalmLandmark.thumbMcp.index] = const PalmPoint(0.10, 0.66);
      tucked[PalmLandmark.thumbIp.index] = const PalmPoint(0.06, 0.52);
      tucked[PalmLandmark.thumbTip.index] = const PalmPoint(0.04, 0.40);

      for (final hand in [splayed, tucked]) {
        final samples = PalmSilhouette.sample(PalmSilhouette.outline(hand));
        final tip = hand[PalmLandmark.thumbTip.index];
        final nearest = samples
            .map((point) => point.distanceTo(tip))
            .reduce(math.min);
        expect(nearest, lessThan(_span(hand) * 0.16));
      }
    });

    test('trails past the wrist rather than closing across it', () {
      // An outline shut straight across the wrist reads as a hand that has
      // been cut off; the arm continues, so the outline does too.
      final hand = _canonical();
      final chain = PalmSilhouette.outline(hand);
      final wrist = hand[PalmLandmark.wrist.index];

      expect(chain.first.y, greaterThan(wrist.y));
      expect(chain.last.y, greaterThan(wrist.y));
      expect(chain.first.distanceTo(chain.last), greaterThan(0.3));
    });
  });

  group('a hand that is not a hand', () {
    test('produces nothing', () {
      expect(
        PalmSilhouette.outline([
          for (var i = 0; i < PalmLandmark.count; i++)
            const PalmPoint(0.5, 0.5),
        ]),
        isEmpty,
      );
      expect(PalmSilhouette.outline(const [PalmPoint(0, 0)]), isEmpty);
    });
  });

  group('smooth', () {
    test('passes through every point it was given', () {
      const points = [
        PalmPoint(0, 0),
        PalmPoint(1, 0.2),
        PalmPoint(1.4, 1),
        PalmPoint(0.6, 1.8),
      ];
      final chain = PalmSilhouette.smooth(points);
      for (var i = 0; i < points.length; i++) {
        expect(chain[i * 3].distanceTo(points[i]), lessThan(1e-12));
      }
    });

    test('reduces to the uniform spline at equal spacing', () {
      const points = [
        PalmPoint(0, 0),
        PalmPoint(1, 0),
        PalmPoint(2, 0),
        PalmPoint(3, 0),
      ];
      final chain = PalmSilhouette.smooth(points);
      // p1 + (p2 - p0) / 6 for the middle segment.
      expect(
        chain[4].distanceTo(const PalmPoint(1 + 2 / 6, 0)),
        lessThan(1e-9),
      );
    });
  });
}
