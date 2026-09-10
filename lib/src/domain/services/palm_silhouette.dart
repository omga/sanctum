import 'dart:math' as math;

import 'package:sanctum/src/domain/models/palm.dart';

/// The outline of a hand, traced from its 21 landmarks.
///
/// ## Why it is traced and not assembled
///
/// The first two outlines were built from parts. One was eleven points
/// authored by eye, which came out a lopsided circle; the next was a
/// capsule down every bone, unioned — which looked like sausages, made
/// a V of the palm where five capsules met at the wrist, and stuck a
/// thumb on at whatever angle the canonical hand held it rather than
/// where the user's thumb was. Both were recognisably not a hand.
///
/// A hand's outline is one line. So this walks it: up the little
/// finger's outer edge, round its tip, down into the web, up the ring
/// finger, and so on across to the index, into the web of the thumb,
/// out along the thumb and back, round the ball of the thumb to the
/// wrist. Every point comes from the landmarks, so the thumb is drawn
/// where the thumb is.
///
/// ## Why centripetal
///
/// The points are joined with a Catmull-Rom spline, and the uniform
/// variant overshoots wherever neighbouring points are unevenly spaced
/// — a fingertip cap, a web — and draws small loops there. The
/// centripetal parameterisation is the one proven not to form cusps or
/// self-intersections within a segment, which is the property an
/// outline cannot do without.
///
/// ## Handedness
///
/// Every side is chosen relative to the hand itself — toward the little
/// finger for the fingers, toward the index for the thumb — never left
/// or right, so a left hand and a right hand trace the same way round.
abstract final class PalmSilhouette {
  /// Finger half-widths at the knuckle, middle joint, end joint and
  /// tip, as fractions of the knuckle span. A finger tapers.
  static const List<double> _index = [0.118, 0.106, 0.094, 0.084];
  static const List<double> _middle = [0.122, 0.110, 0.098, 0.088];
  static const List<double> _ring = [0.114, 0.102, 0.092, 0.082];
  static const List<double> _pinky = [0.100, 0.090, 0.080, 0.072];

  /// The thumb's, from its base joint to its tip. Broad at the base,
  /// because that base is the ball of the thumb.
  static const List<double> _thumb = [0.180, 0.140, 0.122, 0.108];

  /// How far a web sits above the knuckle line, as a fraction of span.
  static const double _webLift = 0.14;

  /// How far the outline trails past the wrist. The arm continues, and
  /// an outline closed straight across the wrist reads as a hand that
  /// has been cut off.
  static const double _wristTail = 0.22;

  /// The smoothed outline for [landmarks], as a cubic chain in the same
  /// space the landmarks are in, or empty if the hand is degenerate.
  static List<PalmPoint> outline(List<PalmPoint> landmarks) =>
      smooth(contour(landmarks));

  /// The points the outline passes through, in order, before smoothing.
  static List<PalmPoint> contour(List<PalmPoint> landmarks) {
    if (landmarks.length != PalmLandmark.count) return const [];
    PalmPoint at(PalmLandmark landmark) => landmarks[landmark.index];

    final indexMcp = at(PalmLandmark.indexMcp);
    final pinkyMcp = at(PalmLandmark.pinkyMcp);
    final wrist = at(PalmLandmark.wrist);

    final across = pinkyMcp - indexMcp;
    final span = across.magnitude;
    if (span < 1e-9) return const [];
    final u = across * (1 / span);

    final knuckles =
        (indexMcp +
            at(PalmLandmark.middleMcp) +
            at(PalmLandmark.ringMcp) +
            pinkyMcp) *
        0.25;
    final towardWrist = wrist - knuckles;
    if (towardWrist.magnitude < 1e-9) return const [];
    final v = towardWrist.normalized;

    bool towardPinky(PalmPoint _, PalmPoint normal) => _dot(normal, u) > 0;

    _Digit finger(List<PalmLandmark> joints, List<double> widths) => _Digit(
      [for (final joint in joints) at(joint)],
      [for (final width in widths) width * span],
      towardPinky,
    );

    final pinky = finger(const [
      PalmLandmark.pinkyMcp,
      PalmLandmark.pinkyPip,
      PalmLandmark.pinkyDip,
      PalmLandmark.pinkyTip,
    ], _pinky);
    final ring = finger(const [
      PalmLandmark.ringMcp,
      PalmLandmark.ringPip,
      PalmLandmark.ringDip,
      PalmLandmark.ringTip,
    ], _ring);
    final middle = finger(const [
      PalmLandmark.middleMcp,
      PalmLandmark.middlePip,
      PalmLandmark.middleDip,
      PalmLandmark.middleTip,
    ], _middle);
    final index = finger(const [
      PalmLandmark.indexMcp,
      PalmLandmark.indexPip,
      PalmLandmark.indexDip,
      PalmLandmark.indexTip,
    ], _index);
    // The thumb's inner side is the one facing the index knuckle. Its
    // direction relative to the palm changes completely between a
    // tucked thumb and a splayed one, so "toward the little finger" —
    // right for the fingers — is ambiguous for it.
    final thumb = _Digit(
      [
        at(PalmLandmark.thumbCmc),
        at(PalmLandmark.thumbMcp),
        at(PalmLandmark.thumbIp),
        at(PalmLandmark.thumbTip),
      ],
      [for (final width in _thumb) width * span],
      (joint, normal) => _dot(normal, indexMcp - joint) > 0,
    );

    PalmPoint web(_Digit a, _Digit b) =>
        (a.joints.first + b.joints.first) * 0.5 - v * (span * _webLift);

    final wristUlnar = wrist + u * (span * 0.42);
    final wristRadial = wrist - u * (span * 0.36);
    final hypothenar = (pinky.outer(0) + wristUlnar) * 0.5 + u * (span * 0.05);
    final thenar = (thumb.inner(0) + wristRadial) * 0.5 - u * (span * 0.07);
    final thumbWeb =
        (index.inner(0) + thumb.outer(1)) * 0.5 + v * (span * 0.04);

    return [
      wristUlnar + v * (span * _wristTail),
      wristUlnar,
      hypothenar,
      pinky.outer(0),
      pinky.outer(1),
      pinky.outer(2),
      ...pinky.cap,
      pinky.inner(2),
      pinky.inner(1),
      web(pinky, ring),
      ring.outer(1),
      ring.outer(2),
      ...ring.cap,
      ring.inner(2),
      ring.inner(1),
      web(ring, middle),
      middle.outer(1),
      middle.outer(2),
      ...middle.cap,
      middle.inner(2),
      middle.inner(1),
      web(middle, index),
      index.outer(1),
      index.outer(2),
      ...index.cap,
      index.inner(2),
      index.inner(1),
      index.inner(0),
      thumbWeb,
      thumb.outer(1),
      thumb.outer(2),
      ...thumb.cap,
      thumb.inner(2),
      thumb.inner(1),
      thumb.inner(0),
      thenar,
      wristRadial,
      wristRadial + v * (span * _wristTail),
    ];
  }

  /// Joins [points] with a centripetal Catmull-Rom spline, as an open
  /// cubic chain: `3n + 1` points, which is what `Path.cubicTo` wants.
  static List<PalmPoint> smooth(List<PalmPoint> points) {
    if (points.length < 2) return const [];
    final chain = <PalmPoint>[points.first];
    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      // Reflected at the ends, so the first and last segments have a
      // neighbour to take a tangent from without inventing a direction.
      final p0 = i == 0 ? p1 + (p1 - p2) : points[i - 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2 + (p2 - p1);
      final (b1, b2) = _handles(p0, p1, p2, p3);
      chain
        ..add(b1)
        ..add(b2)
        ..add(p2);
    }
    return chain;
  }

  /// Samples a cubic chain, for measuring and testing an outline.
  static List<PalmPoint> sample(List<PalmPoint> chain, {int perSegment = 8}) {
    if (chain.length < 4) return const [];
    final out = <PalmPoint>[chain.first];
    for (var s = 0; s + 3 < chain.length; s += 3) {
      for (var i = 1; i <= perSegment; i++) {
        final t = i / perSegment;
        final w = 1 - t;
        out.add(
          chain[s] * (w * w * w) +
              chain[s + 1] * (3 * w * w * t) +
              chain[s + 2] * (3 * w * t * t) +
              chain[s + 3] * (t * t * t),
        );
      }
    }
    return out;
  }

  /// Bézier handles for the segment [p1] → [p2] of a centripetal
  /// Catmull-Rom spline. `d` is distance to the power ½, which is the
  /// centripetal choice; at equal spacing this reduces to the familiar
  /// uniform `p1 + (p2 - p0) / 6`.
  static (PalmPoint, PalmPoint) _handles(
    PalmPoint p0,
    PalmPoint p1,
    PalmPoint p2,
    PalmPoint p3,
  ) {
    const floor = 1e-6;
    final d1 = math.max(math.sqrt(p1.distanceTo(p0)), floor);
    final d2 = math.max(math.sqrt(p2.distanceTo(p1)), floor);
    final d3 = math.max(math.sqrt(p3.distanceTo(p2)), floor);

    final b1 =
        (p2 * (d1 * d1) -
            p0 * (d2 * d2) +
            p1 * (2 * d1 * d1 + 3 * d1 * d2 + d2 * d2)) *
        (1 / (3 * d1 * (d1 + d2)));
    final b2 =
        (p1 * (d3 * d3) -
            p3 * (d2 * d2) +
            p2 * (2 * d3 * d3 + 3 * d3 * d2 + d2 * d2)) *
        (1 / (3 * d3 * (d3 + d2)));
    return (b1, b2);
  }

  static double _dot(PalmPoint a, PalmPoint b) => a.x * b.x + a.y * b.y;
}

/// A finger or the thumb: four joints, a width at each, and which side
/// is which.
final class _Digit {
  _Digit(
    this.joints,
    this.halfWidths,
    bool Function(PalmPoint joint, PalmPoint normal) isOuter,
  ) : normals = [
        for (var i = 0; i < 4; i++)
          () {
            final tangent =
                joints[math.min(i + 1, 3)] - joints[math.max(i - 1, 0)];
            final normal = tangent.normal;
            return isOuter(joints[i], normal) ? normal : normal * -1;
          }(),
      ];

  final List<PalmPoint> joints;
  final List<double> halfWidths;

  /// Unit normals, each turned to face the outer side.
  final List<PalmPoint> normals;

  /// The outer edge at joint [i]: toward the little finger for a finger,
  /// toward the index for the thumb.
  PalmPoint outer(int i) => joints[i] + normals[i] * halfWidths[i];

  /// The inner edge at joint [i].
  PalmPoint inner(int i) => joints[i] - normals[i] * halfWidths[i];

  /// Round the tip, from the outer edge to the inner one.
  ///
  /// The apex sits beyond the tip landmark, because MediaPipe places
  /// that landmark inside the pad of the finger rather than at its end.
  List<PalmPoint> get cap {
    final tip = joints[3];
    final along = (joints[3] - joints[2]).normalized;
    final normal = normals[3];
    final width = halfWidths[3];
    return [
      outer(3),
      tip + along * (width * 0.75) + normal * (width * 0.72),
      tip + along * (width * 1.05),
      tip + along * (width * 0.75) - normal * (width * 0.72),
      inner(3),
    ];
  }
}
