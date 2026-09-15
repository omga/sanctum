import 'dart:math' as math;

import 'package:meta/meta.dart';

/// A point in two dimensions.
///
/// Deliberately not `dart:ui`'s `Offset`: `domain/` imports nothing but
/// pure Dart, and the whole palm pipeline — landmarks in, warped curves
/// out — has to stay testable in milliseconds without a widget binding.
/// The conversion to `Offset` happens once, in the painter.
@immutable
class PalmPoint {
  /// Creates a point at [x], [y].
  const PalmPoint(this.x, this.y);

  /// Horizontal position.
  ///
  /// Which space that is in depends on who produced it — see
  /// [PalmSpace]. Landmarks arrive normalised to the source image;
  /// template curves are authored in canonical palm space.
  final double x;

  /// Vertical position, increasing *downward* in both spaces.
  final double y;

  /// Componentwise difference.
  PalmPoint operator -(PalmPoint other) => PalmPoint(x - other.x, y - other.y);

  /// Componentwise sum.
  PalmPoint operator +(PalmPoint other) => PalmPoint(x + other.x, y + other.y);

  /// Uniform scale.
  PalmPoint operator *(double factor) => PalmPoint(x * factor, y * factor);

  /// Distance from the origin.
  double get magnitude => math.sqrt(x * x + y * y);

  /// Distance to [other].
  double distanceTo(PalmPoint other) => (this - other).magnitude;

  /// The z component of the 3-D cross product with [other].
  ///
  /// The sign is the only part used, and it is what tells a palm from
  /// the back of a hand — see [HandLandmarks.isPalmFacing].
  double cross(PalmPoint other) => x * other.y - y * other.x;

  /// This point rescaled to unit length, or the origin if it has none.
  PalmPoint get normalized {
    final length = magnitude;
    return length == 0
        ? const PalmPoint(0, 0)
        : PalmPoint(x / length, y / length);
  }

  /// The unit vector at a right angle to this one, rotated clockwise in
  /// screen coordinates.
  PalmPoint get normal => PalmPoint(-y, x).normalized;

  @override
  bool operator ==(Object other) =>
      other is PalmPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() =>
      'PalmPoint(${x.toStringAsFixed(4)}, ${y.toStringAsFixed(4)})';
}

/// Which coordinate system a [PalmPoint] is expressed in.
///
/// Only documentation — the type is the same either way — but the two
/// are extremely easy to confuse and a curve drawn in the wrong one
/// lands somewhere plausible rather than obviously wrong, which is the
/// worst kind of bug to find in a stranger's feed.
enum PalmSpace {
  /// The source frame, normalised **to its width on both axes**: `x`
  /// runs `0..1` and `y` runs `0..HandLandmarks.frameAspect`.
  ///
  /// Not the detector's own convention, which normalises each axis to
  /// its own dimension — convenient for drawing and wrong for measuring,
  /// because on a 16:9 frame it makes a vertical centimetre 1.78× longer
  /// than a horizontal one. Every distance, angle and warp below would
  /// silently inherit that. The camera boundary converts once, on the
  /// way in.
  image,

  /// The rectified palm. `x` runs from the thumb side (0) to the little
  /// finger side (1); `y` runs from the knuckles (0) to the wrist (1).
  ///
  /// Anatomical, not left/right — which is what makes the line template
  /// handedness-free. See `PalmGeometry`.
  canonical,
}

/// Which hand the detector believes it saw.
enum Handedness {
  /// The left hand.
  left,

  /// The right hand.
  right;

  /// The other one.
  Handedness get opposite =>
      this == Handedness.left ? Handedness.right : Handedness.left;
}

/// The 21 points MediaPipe's hand landmark model returns, in its order.
///
/// The indices are the model's, not ours, and must not be reordered:
/// [HandLandmarks.points] is indexed by them directly.
enum PalmLandmark {
  /// The base of the hand.
  wrist,

  /// Thumb, carpometacarpal — the joint at the base of the thumb.
  thumbCmc,

  /// Thumb, metacarpophalangeal.
  thumbMcp,

  /// Thumb, interphalangeal.
  thumbIp,

  /// Thumb, tip.
  thumbTip,

  /// Index finger, metacarpophalangeal — the knuckle.
  indexMcp,

  /// Index finger, proximal interphalangeal.
  indexPip,

  /// Index finger, distal interphalangeal.
  indexDip,

  /// Index finger, tip.
  indexTip,

  /// Middle finger, knuckle.
  middleMcp,

  /// Middle finger, proximal interphalangeal.
  middlePip,

  /// Middle finger, distal interphalangeal.
  middleDip,

  /// Middle finger, tip.
  middleTip,

  /// Ring finger, knuckle.
  ringMcp,

  /// Ring finger, proximal interphalangeal.
  ringPip,

  /// Ring finger, distal interphalangeal.
  ringDip,

  /// Ring finger, tip.
  ringTip,

  /// Little finger, knuckle.
  pinkyMcp,

  /// Little finger, proximal interphalangeal.
  pinkyPip,

  /// Little finger, distal interphalangeal.
  pinkyDip,

  /// Little finger, tip.
  pinkyTip;

  /// How many points a hand has. The model's contract, asserted on the
  /// way in so a short list fails at the boundary rather than as a range
  /// error three layers deeper.
  static const int count = 21;
}

/// One detected hand.
///
/// **Nothing here is ever persisted or transmitted.** A palm scan is
/// hand geometry, which US biometric-privacy statutes name explicitly,
/// and the only defensible answer is that the measurement does not
/// outlive the screen that made it. There is no mapper on this class on
/// purpose: it has no JSON codec because it must never acquire one.
@immutable
class HandLandmarks {
  /// Creates a hand from exactly [PalmLandmark.count] points, in the
  /// model's order, normalised to the source image.
  const HandLandmarks({
    required this.points,
    required this.handedness,
    required this.confidence,
    required this.frameAspect,
  }) : assert(
         points.length == PalmLandmark.count,
         'a hand is exactly 21 points',
       ),
       assert(frameAspect > 0, 'a frame has a height');

  /// The landmarks, indexed by [PalmLandmark].
  final List<PalmPoint> points;

  /// Which hand the detector reported.
  ///
  /// The detector decides this from appearance, so a mirrored preview
  /// inverts it. Un-mirror at the camera boundary, not here — see
  /// [isPalmFacing], which depends on the two agreeing.
  final Handedness handedness;

  /// The detector's confidence, `[0, 1]`.
  final double confidence;

  /// The source frame's height divided by its width.
  ///
  /// Carried rather than assumed because [PalmSpace.image] is isotropic:
  /// `y` runs to this value, not to 1, and the framing check needs to
  /// know where the bottom edge is.
  final double frameAspect;

  /// The landmark at [landmark].
  PalmPoint operator [](PalmLandmark landmark) => points[landmark.index];

  /// Whether we are looking at the palm rather than the back of the hand.
  ///
  /// Chirality, not a model output. Walking wrist → index knuckle →
  /// little-finger knuckle turns one way on a palm and the other on a
  /// back, so the sign of the cross product answers it — and comparing
  /// that against the reported [handedness] is the whole check.
  ///
  /// This is why mirroring has to be resolved before the landmarks get
  /// here. A selfie-mirrored frame flips the cross product *and* the
  /// reported handedness, so the two stay consistent and the check
  /// silently passes on a back of a hand. See `handoff` note in
  /// `.claude/palm.md` §7.
  bool get isPalmFacing {
    final toIndex = this[PalmLandmark.indexMcp] - this[PalmLandmark.wrist];
    final toPinky = this[PalmLandmark.pinkyMcp] - this[PalmLandmark.wrist];
    final clockwise = toIndex.cross(toPinky) > 0;
    return clockwise == (handedness == Handedness.right);
  }

  /// The span across the knuckles, in image widths.
  ///
  /// The scale check: a palm that is a fifth of the frame carries no
  /// crease detail worth filming, whatever the camera's resolution.
  double get knuckleSpan =>
      this[PalmLandmark.indexMcp].distanceTo(this[PalmLandmark.pinkyMcp]);

  /// How open the hand is, as the mean tip-to-wrist distance over the
  /// mean knuckle-to-wrist distance across the four fingers.
  ///
  /// A flat open hand computes to about 1.70 — the fingers are roughly
  /// three quarters of the palm's length again — and a fist falls under
  /// 1.15. Those are proportions, not measurements: confirm them
  /// against real captures before trusting the threshold. Curled
  /// fingers foreshorten the palm and hide the top of every line, so
  /// this gates the capture rather than merely warning about it.
  double get openness {
    const tips = [
      PalmLandmark.indexTip,
      PalmLandmark.middleTip,
      PalmLandmark.ringTip,
      PalmLandmark.pinkyTip,
    ];
    const knuckles = [
      PalmLandmark.indexMcp,
      PalmLandmark.middleMcp,
      PalmLandmark.ringMcp,
      PalmLandmark.pinkyMcp,
    ];

    final wrist = this[PalmLandmark.wrist];
    var tipSum = 0.0;
    var knuckleSum = 0.0;
    for (var i = 0; i < tips.length; i++) {
      tipSum += this[tips[i]].distanceTo(wrist);
      knuckleSum += this[knuckles[i]].distanceTo(wrist);
    }
    return knuckleSum == 0 ? 0 : tipSum / knuckleSum;
  }

  /// The centre of the palm, as the mean of the wrist and the four
  /// knuckles. Used for the framing check, not for the warp.
  PalmPoint get centre {
    const anchors = [
      PalmLandmark.wrist,
      PalmLandmark.indexMcp,
      PalmLandmark.middleMcp,
      PalmLandmark.ringMcp,
      PalmLandmark.pinkyMcp,
    ];
    var sum = const PalmPoint(0, 0);
    for (final anchor in anchors) {
      sum += this[anchor];
    }
    return sum * (1 / anchors.length);
  }
}

/// The principal lines a reading is allowed to name.
///
/// Four, and no more. Palmistry catalogues dozens of minor lines, and
/// every one of them is a curve we would be drawing from a template with
/// nothing under it — these four are the ones deep enough to survive
/// `PalmCreaseSnapper` finding them in an actual photograph.
enum PalmLine {
  /// The uppermost major line, running below the fingers.
  heart('Heart'),

  /// Across the middle of the palm.
  head('Head'),

  /// Arcing around the ball of the thumb.
  life('Life'),

  /// Rising from the wrist toward the middle finger. Genuinely absent on
  /// many hands, which the reading says rather than inventing one.
  fate('Fate');

  const PalmLine(this.displayName);

  /// English name. Localised copy lives in the content JSON, like every
  /// other reading string — this is for logs and debug overlays.
  final String displayName;

  /// The three every hand has. [PalmLine.fate] is offered separately
  /// because claiming it unconditionally would be a lie the user can
  /// check by looking at their own hand.
  static const List<PalmLine> principal = [
    PalmLine.heart,
    PalmLine.head,
    PalmLine.life,
  ];
}

/// One line, as a chain of cubic Bézier segments.
///
/// The control points are `3n + 1` long: an on-curve point, then two
/// off-curve controls and an on-curve end per segment. That is the form
/// `Path.cubicTo` wants, so the painter does no conversion, and it is
/// also the form `PalmCreaseSnapper` perturbs — it moves the on-curve
/// points and drags their neighbouring handles, which keeps the curve
/// smooth while it snaps.
@immutable
class PalmCurve {
  /// Creates a curve for [line] from [controlPoints], in [space].
  ///
  /// Not `const`, and that is the assert's doing: `List.length` is not
  /// available to the constant evaluator, so keeping the invariant means
  /// giving up compile-time construction. Worth it — a chain that is not
  /// `3n + 1` long draws a curve that silently omits its last segment,
  /// and the template is built once per process either way.
  // ignore: prefer_const_constructors_in_immutables
  PalmCurve({
    required this.line,
    required this.controlPoints,
    this.space = PalmSpace.canonical,
  }) : assert(
         controlPoints.length >= 4 && controlPoints.length % 3 == 1,
         'a cubic chain is 3n + 1 points',
       );

  /// Which line this is.
  final PalmLine line;

  /// The cubic chain.
  final List<PalmPoint> controlPoints;

  /// Which coordinate system [controlPoints] are in.
  final PalmSpace space;

  /// How many cubic segments the chain holds.
  int get segmentCount => (controlPoints.length - 1) ~/ 3;

  /// The on-curve points, which are the ones snapping is allowed to move.
  List<PalmPoint> get anchors => [
    for (var i = 0; i < controlPoints.length; i += 3) controlPoints[i],
  ];

  /// Samples the curve at [perSegment] points per cubic segment.
  ///
  /// Used for hit-testing, for the ridge search, and for measuring
  /// length. The painter does not use it — it hands the control points
  /// straight to `Path`, so what is drawn is the curve and not a
  /// polyline approximation of it.
  List<PalmPoint> sample({int perSegment = 12}) {
    assert(perSegment >= 1, 'a segment needs at least one sample');
    final out = <PalmPoint>[controlPoints.first];
    for (var s = 0; s < segmentCount; s++) {
      final p0 = controlPoints[s * 3];
      final p1 = controlPoints[s * 3 + 1];
      final p2 = controlPoints[s * 3 + 2];
      final p3 = controlPoints[s * 3 + 3];
      for (var i = 1; i <= perSegment; i++) {
        out.add(_cubicAt(p0, p1, p2, p3, i / perSegment));
      }
    }
    return out;
  }

  /// Approximate arc length, from a dense sampling.
  double get length {
    final points = sample(perSegment: 24);
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += points[i].distanceTo(points[i - 1]);
    }
    return total;
  }

  /// A copy with [controlPoints] replaced, keeping [line] and [space].
  PalmCurve withControlPoints(List<PalmPoint> points) =>
      PalmCurve(line: line, controlPoints: points, space: space);

  /// The same curve, described by twice as many segments.
  ///
  /// De Casteljau at `t = 0.5`, which splits a cubic into two cubics
  /// that trace it **exactly** — this changes the description, never the
  /// shape, and `palm_crease_snapper_test.dart` pins that.
  ///
  /// It exists because snapping can only move anchors: an authored line
  /// has two segments and therefore three places it can be pulled, which
  /// is not enough freedom to follow a real crease. Subdividing buys
  /// that freedom without anybody hand-authoring more control points and
  /// without changing what the template means.
  PalmCurve subdivided() {
    final out = <PalmPoint>[controlPoints.first];
    for (var s = 0; s < segmentCount; s++) {
      final p0 = controlPoints[s * 3];
      final p1 = controlPoints[s * 3 + 1];
      final p2 = controlPoints[s * 3 + 2];
      final p3 = controlPoints[s * 3 + 3];

      final a = (p0 + p1) * 0.5;
      final b = (p1 + p2) * 0.5;
      final c = (p2 + p3) * 0.5;
      final d = (a + b) * 0.5;
      final e = (b + c) * 0.5;
      final midpoint = (d + e) * 0.5;

      out.addAll([a, d, midpoint, e, c, p3]);
    }
    return withControlPoints(out);
  }

  static PalmPoint _cubicAt(
    PalmPoint p0,
    PalmPoint p1,
    PalmPoint p2,
    PalmPoint p3,
    double t,
  ) {
    final u = 1 - t;
    final a = u * u * u;
    final b = 3 * u * u * t;
    final c = 3 * u * t * t;
    final d = t * t * t;
    return PalmPoint(
      a * p0.x + b * p1.x + c * p2.x + d * p3.x,
      a * p0.y + b * p1.y + c * p2.y + d * p3.y,
    );
  }
}

/// Whether a frame is worth capturing, and if not, what to say.
///
/// One enum rather than a bag of booleans because the viewfinder can
/// only show one instruction at a time, and deciding *which* complaint
/// wins is exactly the kind of ordering that belongs in a tested pure
/// function rather than in a widget. See `PalmGeometry.assess`.
enum PalmReadiness {
  /// Capture.
  ready,

  /// The detector found nothing.
  noHand,

  /// A hand, but not confidently enough to build a warp on.
  lowConfidence,

  /// Too far away for the creases to survive the lens.
  tooSmall,

  /// Drifting out of frame, where the warp extrapolates.
  offCentre,

  /// The back of the hand. Says so, rather than reading the knuckles.
  backOfHand,

  /// Curled fingers, which hide the top of every line.
  fingersClosed,

  /// Held at too steep an angle for an affine warp to be honest about.
  tooOblique;

  /// Whether the shutter may fire.
  bool get isReady => this == PalmReadiness.ready;
}
