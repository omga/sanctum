import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_geometry.dart';

import '../support/palm_fixtures.dart';

Matcher _closeToPoint(PalmPoint expected, {double within = 1e-9}) =>
    predicate<PalmPoint>(
      (actual) => actual.distanceTo(expected) < within,
      'within $within of $expected',
    );

void _expectSameTransform(Affine2 actual, Affine2 expected) {
  expect(actual.a, closeTo(expected.a, 1e-9));
  expect(actual.b, closeTo(expected.b, 1e-9));
  expect(actual.tx, closeTo(expected.tx, 1e-9));
  expect(actual.c, closeTo(expected.c, 1e-9));
  expect(actual.d, closeTo(expected.d, 1e-9));
  expect(actual.ty, closeTo(expected.ty, 1e-9));
}

void main() {
  group('Affine2.fit', () {
    test('recovers a transform exactly from exact correspondences', () {
      final expected = pose(
        scale: 0.42,
        rotation: 0.3,
        translation: const PalmPoint(0.2, 0.15),
      );
      final from = PalmGeometry.canonicalAnchors.values.toList();
      final to = [for (final point in from) expected.apply(point)];

      _expectSameTransform(Affine2.fit(from: from, to: to)!, expected);
    });

    test('is least squares, not interpolation', () {
      // Five correspondences over-determine six coefficients split
      // across two independent three-unknown problems. One displaced
      // anchor must move the answer a little, not carry it — a fit that
      // honours every point exactly is a fit that will chase jitter.
      final from = PalmGeometry.canonicalAnchors.values.toList();
      final to = [for (final point in from) point];
      to[2] = to[2] + const PalmPoint(0.1, 0);

      final fitted = Affine2.fit(from: from, to: to)!;
      final moved = fitted.apply(from[2]);

      expect(moved.distanceTo(to[2]), greaterThan(0.01));
      expect(moved.distanceTo(from[2]), greaterThan(0.01));
    });

    test('refuses collinear points', () {
      const line = [
        PalmPoint(0, 0),
        PalmPoint(0.5, 0.5),
        PalmPoint(1, 1),
      ];
      expect(Affine2.fit(from: line, to: line), isNull);
    });

    test('refuses fewer than three points, and mismatched lists', () {
      const two = [PalmPoint(0, 0), PalmPoint(1, 1)];
      expect(Affine2.fit(from: two, to: two), isNull);
      expect(
        Affine2.fit(from: two, to: const [PalmPoint(0, 0)]),
        isNull,
      );
    });
  });

  group('Affine2', () {
    test('inverts', () {
      final transform = pose(scale: 0.4, rotation: -0.5);
      const point = PalmPoint(0.3, 0.7);
      expect(
        transform.inverse!.apply(transform.apply(point)),
        _closeToPoint(point),
      );
    });

    test('reports rotation and refuses to invert a collapsed transform', () {
      expect(pose(rotation: math.pi / 6).rotation, closeTo(math.pi / 6, 1e-9));
      const collapsed = Affine2(a: 1, b: 2, tx: 0, c: 2, d: 4, ty: 0);
      expect(collapsed.inverse, isNull);
    });

    test('measures foreshortening as the ratio of the singular values', () {
      expect(pose(scale: 0.5, rotation: 0.9).anisotropy, closeTo(1, 1e-9));
      const squashed = Affine2(a: 0.5, b: 0, tx: 0, c: 0, d: 0.25, ty: 0);
      expect(squashed.anisotropy, closeTo(2, 1e-9));
    });

    test('applyVector drops the translation', () {
      final transform = pose(translation: const PalmPoint(9, 9));
      expect(
        transform.applyVector(const PalmPoint(1, 0)),
        _closeToPoint(const PalmPoint(0.5, 0)),
      );
    });
  });

  group('rectify', () {
    test('recovers the pose the hand was placed with', () {
      final placed = pose(
        scale: 0.55,
        rotation: 0.2,
        translation: const PalmPoint(0.18, 0.24),
      );
      final frame = PalmGeometry.rectify(handAt(placed))!;

      _expectSameTransform(frame.toImage, placed);
      expect(frame.residual, closeTo(0, 1e-9));
      expect(frame.anisotropy, closeTo(1, 1e-9));
      expect(frame.rotation, closeTo(0.2, 1e-9));
    });

    test('round-trips a point through both transforms', () {
      final frame = PalmGeometry.rectify(goodHand())!;
      const canonical = PalmPoint(0.35, 0.6);
      expect(
        frame.toCanonical.apply(frame.toImage.apply(canonical)),
        _closeToPoint(canonical),
      );
    });

    test('puts a left hand and a right hand in the same canonical space', () {
      // The claim the whole template rests on: canonical space is
      // anatomical, so one authored line set serves both hands and there
      // is no mirrored copy to keep in step with it.
      final right = PalmGeometry.rectify(handAt(pose()))!;
      final left = PalmGeometry.rectify(
        handAt(pose(mirror: true), handedness: Handedness.left),
      )!;

      for (final landmark in PalmGeometry.canonicalAnchors.keys) {
        final expected = PalmGeometry.canonicalAnchors[landmark]!;
        expect(
          right.toCanonical.apply(right.landmarks[landmark]),
          _closeToPoint(expected, within: 1e-6),
        );
        expect(
          left.toCanonical.apply(left.landmarks[landmark]),
          _closeToPoint(expected, within: 1e-6),
        );
      }

      expect(right.isMirrored, isFalse);
      expect(left.isMirrored, isTrue);
    });

    test('residual rises when the hand stops being flat', () {
      // A cupped palm cannot be described by an affine, and the fit says
      // so rather than quietly producing a warp nobody checked.
      final cupped = {
        for (final entry in canonicalHand.entries)
          entry.key: entry.key == PalmLandmark.middleMcp
              ? entry.value + const PalmPoint(0, 0.12)
              : entry.value,
      };
      final frame = PalmGeometry.rectify(
        handAt(pose(), canonical: cupped),
      )!;

      expect(frame.residual, greaterThan(PalmGeometry.maxResidual));
    });

    test('leaves room above landmark jitter', () {
      // The other end of the same threshold. A flat hand read by a
      // detector that wobbles by a percent of its size must not be
      // rejected as cupped, or the viewfinder never fires.
      final noise = math.Random(7);
      PalmPoint jitter() =>
          PalmPoint(noise.nextDouble() - 0.5, noise.nextDouble() - 0.5) * 0.02;

      final wobbly = {
        for (final entry in canonicalHand.entries)
          entry.key: entry.value + jitter(),
      };
      final frame = PalmGeometry.rectify(
        handAt(pose(), canonical: wobbly),
      )!;

      expect(frame.residual, lessThan(PalmGeometry.maxResidual / 3));
      expect(
        PalmGeometry.evaluate(handAt(pose(), canonical: wobbly)).readiness,
        PalmReadiness.ready,
      );
    });
  });

  group('isPalmFacing', () {
    test('is true for either palm and false for either back', () {
      expect(handAt(pose()).isPalmFacing, isTrue);
      expect(
        handAt(pose(mirror: true), handedness: Handedness.left).isPalmFacing,
        isTrue,
      );
      expect(handAt(pose(mirror: true)).isPalmFacing, isFalse);
      expect(
        handAt(pose(), handedness: Handedness.left).isPalmFacing,
        isFalse,
      );
    });

    test('survives rotation, which is the point of using chirality', () {
      for (final angle in [0.0, 1.2, math.pi, -2.4]) {
        expect(handAt(pose(rotation: angle)).isPalmFacing, isTrue);
      }
    });
  });

  group('evaluate', () {
    test('captures a good frame', () {
      final scan = PalmGeometry.evaluate(goodHand());
      expect(scan.readiness, PalmReadiness.ready);
      expect(scan.isReady, isTrue);
      expect(scan.frame, isNotNull);
    });

    test('reports no hand, with no frame', () {
      final scan = PalmGeometry.evaluate(null);
      expect(scan.readiness, PalmReadiness.noHand);
      expect(scan.frame, isNull);
    });

    test('refuses a low-confidence detection', () {
      expect(
        PalmGeometry.evaluate(handAt(pose(), confidence: 0.4)).readiness,
        PalmReadiness.lowConfidence,
      );
    });

    test('names the back of a hand instead of the reading', () {
      expect(
        PalmGeometry.evaluate(handAt(pose(mirror: true))).readiness,
        PalmReadiness.backOfHand,
      );
    });

    test('refuses a half-closed hand', () {
      expect(
        PalmGeometry.evaluate(
          handAt(pose(), canonical: curledHand(0.7)),
        ).readiness,
        PalmReadiness.fingersClosed,
      );
      expect(
        PalmGeometry.evaluate(
          handAt(pose(), canonical: curledHand(0)),
        ).readiness,
        PalmReadiness.ready,
      );
    });

    test('asks a distant hand to come closer', () {
      final scan = PalmGeometry.evaluate(handAt(pose(scale: 0.3)));
      expect(scan.readiness, PalmReadiness.tooSmall);
      // The viewfinder still draws the outline while it asks.
      expect(scan.frame, isNotNull);
    });

    test('catches a hand leaving the frame', () {
      expect(
        PalmGeometry.evaluate(
          handAt(pose(translation: const PalmPoint(0.9, 0.8))),
        ).readiness,
        PalmReadiness.offCentre,
      );
    });

    test('refuses a palm tilted away from the lens', () {
      const oblique = Affine2(a: 0.5, b: 0, tx: 0.35, c: 0, d: 0.3, ty: 0.55);
      final scan = PalmGeometry.evaluate(handAt(oblique));
      expect(scan.frame!.anisotropy, greaterThan(PalmGeometry.maxAnisotropy));
      expect(scan.readiness, PalmReadiness.tooOblique);
    });

    test('complains about the back of a hand before its size', () {
      // Ordering, not coverage. Telling somebody to move closer when the
      // real problem is which way their hand faces makes the app look
      // broken: they do as they are told and nothing improves.
      expect(
        PalmGeometry.evaluate(
          handAt(pose(scale: 0.2, mirror: true)),
        ).readiness,
        PalmReadiness.backOfHand,
      );
    });
  });

  group('place', () {
    test('maps a canonical curve onto the frame', () {
      final frame = PalmGeometry.rectify(goodHand())!;
      final curve = PalmCurve(
        line: PalmLine.heart,
        controlPoints: const [
          PalmPoint(0.9, 0.3),
          PalmPoint(0.7, 0.25),
          PalmPoint(0.4, 0.22),
          PalmPoint(0.2, 0.2),
        ],
      );

      final placed = frame.place(curve);

      expect(placed.space, PalmSpace.image);
      expect(placed.line, PalmLine.heart);
      expect(
        placed.controlPoints.first,
        _closeToPoint(frame.toImage.apply(curve.controlPoints.first)),
      );
    });

    test('refuses a curve that is already in frame space', () {
      final frame = PalmGeometry.rectify(goodHand())!;
      final alreadyPlaced = PalmCurve(
        line: PalmLine.head,
        controlPoints: const [
          PalmPoint(0.1, 0.1),
          PalmPoint(0.2, 0.2),
          PalmPoint(0.3, 0.3),
          PalmPoint(0.4, 0.4),
        ],
        space: PalmSpace.image,
      );

      expect(() => frame.place(alreadyPlaced), throwsA(isA<AssertionError>()));
    });
  });
}
