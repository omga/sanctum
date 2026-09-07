import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:sanctum/src/domain/models/palm.dart';

/// A 2-D affine transform.
///
/// ```text
/// x' = a·x + b·y + tx
/// y' = c·x + d·y + ty
/// ```
///
/// ## Why affine and not a homography
///
/// A homography would correct perspective, and a palm held at an angle
/// really is a perspective projection — but it needs four
/// correspondences that are not close to collinear, and the four points
/// a hand actually offers are the wrist plus a knuckle arch. Solving
/// eight unknowns from that is ill-conditioned: small landmark jitter
/// produces large, *visible* swings in the warp, and the failure mode is
/// a line sliding across the palm between frames.
///
/// Six unknowns from five rigid points is over-determined and stable.
/// The cost is that a steeply tilted palm cannot be fully rectified —
/// which is why [PalmGeometry] refuses those frames outright
/// ([PalmReadiness.tooOblique]) instead of drawing on them badly.
@immutable
class Affine2 {
  /// Creates a transform from its six coefficients.
  const Affine2({
    required this.a,
    required this.b,
    required this.tx,
    required this.c,
    required this.d,
    required this.ty,
  });

  /// The transform that changes nothing.
  static const Affine2 identity = Affine2(
    a: 1,
    b: 0,
    tx: 0,
    c: 0,
    d: 1,
    ty: 0,
  );

  /// Row one: `x` coefficient.
  final double a;

  /// Row one: `y` coefficient.
  final double b;

  /// Row one: translation.
  final double tx;

  /// Row two: `x` coefficient.
  final double c;

  /// Row two: `y` coefficient.
  final double d;

  /// Row two: translation.
  final double ty;

  /// Fits the transform that best maps [from] onto [to], by least
  /// squares.
  ///
  /// Returns null when the fit is degenerate — fewer than three
  /// correspondences, mismatched lists, or points so nearly collinear
  /// that the normal equations are singular. A null here is a frame to
  /// drop, not an error to report: the next camera frame is 33 ms away.
  ///
  /// The two rows are independent least-squares problems sharing one
  /// normal matrix, so this builds that 3×3 once, inverts it once, and
  /// applies it twice.
  static Affine2? fit({
    required List<PalmPoint> from,
    required List<PalmPoint> to,
  }) {
    if (from.length != to.length || from.length < 3) return null;

    var sxx = 0.0;
    var sxy = 0.0;
    var syy = 0.0;
    var sx = 0.0;
    var sy = 0.0;
    var sxX = 0.0;
    var syX = 0.0;
    var sX = 0.0;
    var sxY = 0.0;
    var syY = 0.0;
    var sY = 0.0;

    for (var i = 0; i < from.length; i++) {
      final p = from[i];
      final q = to[i];
      sxx += p.x * p.x;
      sxy += p.x * p.y;
      syy += p.y * p.y;
      sx += p.x;
      sy += p.y;
      sxX += p.x * q.x;
      syX += p.y * q.x;
      sX += q.x;
      sxY += p.x * q.y;
      syY += p.y * q.y;
      sY += q.y;
    }

    final n = from.length.toDouble();
    final inverse = _invert3(
      [sxx, sxy, sx],
      [sxy, syy, sy],
      [sx, sy, n],
    );
    if (inverse == null) return null;

    final row1 = _apply3(inverse, [sxX, syX, sX]);
    final row2 = _apply3(inverse, [sxY, syY, sY]);

    return Affine2(
      a: row1[0],
      b: row1[1],
      tx: row1[2],
      c: row2[0],
      d: row2[1],
      ty: row2[2],
    );
  }

  /// Maps a point, translation included.
  PalmPoint apply(PalmPoint point) => PalmPoint(
    a * point.x + b * point.y + tx,
    c * point.x + d * point.y + ty,
  );

  /// Maps a direction, translation excluded.
  ///
  /// What a normal or a tangent needs: a displacement has no origin, so
  /// applying [tx] and [ty] to one would move it somewhere meaningless.
  PalmPoint applyVector(PalmPoint vector) => PalmPoint(
    a * vector.x + b * vector.y,
    c * vector.x + d * vector.y,
  );

  /// The signed area scale. Negative means the transform reflects.
  double get determinant => a * d - b * c;

  /// The inverse, or null when [determinant] is too near zero to trust.
  Affine2? get inverse {
    final det = determinant;
    if (det.abs() < 1e-12) return null;
    final ia = d / det;
    final ib = -b / det;
    final ic = -c / det;
    final id = a / det;
    return Affine2(
      a: ia,
      b: ib,
      tx: -(ia * tx + ib * ty),
      c: ic,
      d: id,
      ty: -(ic * tx + id * ty),
    );
  }

  /// The rotation of the transformed `x` axis, in radians.
  double get rotation => math.atan2(c, a);

  /// The two singular values, larger first.
  ///
  /// Closed-form 2×2 SVD. Their ratio is [anisotropy]; their product is
  /// the absolute area scale.
  (double, double) get scales {
    final e = (a + d) / 2;
    final f = (a - d) / 2;
    final g = (c + b) / 2;
    final h = (c - b) / 2;
    final q = math.sqrt(e * e + h * h);
    final r = math.sqrt(f * f + g * g);
    return (q + r, (q - r).abs());
  }

  /// How far from a similarity this transform is: `1` is uniform scale
  /// and rotation, higher is squashed.
  ///
  /// The foreshortening measure. A palm facing the lens squarely warps
  /// to canonical space almost isotropically; one tilted away does not,
  /// and this is the number that catches it.
  double get anisotropy {
    final (major, minor) = scales;
    return minor < 1e-9 ? double.infinity : major / minor;
  }

  static List<double>? _invert3(
    List<double> r0,
    List<double> r1,
    List<double> r2,
  ) {
    final c00 = r1[1] * r2[2] - r1[2] * r2[1];
    final c01 = r1[2] * r2[0] - r1[0] * r2[2];
    final c02 = r1[0] * r2[1] - r1[1] * r2[0];
    final det = r0[0] * c00 + r0[1] * c01 + r0[2] * c02;
    if (det.abs() < 1e-15) return null;

    final c10 = r0[2] * r2[1] - r0[1] * r2[2];
    final c11 = r0[0] * r2[2] - r0[2] * r2[0];
    final c12 = r0[1] * r2[0] - r0[0] * r2[1];
    final c20 = r0[1] * r1[2] - r0[2] * r1[1];
    final c21 = r0[2] * r1[0] - r0[0] * r1[2];
    final c22 = r0[0] * r1[1] - r0[1] * r1[0];

    return [
      c00 / det, c10 / det, c20 / det, //
      c01 / det, c11 / det, c21 / det, //
      c02 / det, c12 / det, c22 / det, //
    ];
  }

  static List<double> _apply3(List<double> m, List<double> v) => [
    m[0] * v[0] + m[1] * v[1] + m[2] * v[2],
    m[3] * v[0] + m[4] * v[1] + m[5] * v[2],
    m[6] * v[0] + m[7] * v[1] + m[8] * v[2],
  ];
}

/// A rectified palm: the two transforms between the frame and canonical
/// palm space, plus how well they fit.
@immutable
class PalmFrame {
  /// Creates a frame. Built by [PalmGeometry.rectify], not by hand.
  const PalmFrame({
    required this.toCanonical,
    required this.toImage,
    required this.landmarks,
    required this.residual,
  });

  /// Frame → canonical palm space.
  final Affine2 toCanonical;

  /// Canonical palm space → frame. What the painter uses.
  final Affine2 toImage;

  /// The hand this was fitted to.
  final HandLandmarks landmarks;

  /// RMS anchor error in canonical units.
  ///
  /// The fit's own opinion of itself. A flat hand lands near 0.02; a
  /// cupped or tilted one climbs, and past
  /// [PalmGeometry.maxResidual] the warp is extrapolating rather than
  /// measuring.
  final double residual;

  /// Places a canonical curve onto the frame.
  ///
  /// The only sanctioned way for a template to reach the screen — which
  /// is why it asserts the space rather than trusting the caller. A
  /// canonical curve drawn without this lands in the frame's top-left
  /// corner at 1 % scale, which looks like a rendering bug rather than
  /// the coordinate mistake it is.
  PalmCurve place(PalmCurve curve) {
    assert(
      curve.space == PalmSpace.canonical,
      'place() maps canonical curves onto the frame',
    );
    return PalmCurve(
      line: curve.line,
      controlPoints: [
        for (final point in curve.controlPoints) toImage.apply(point),
      ],
      space: PalmSpace.image,
    );
  }

  /// The distance across the knuckles, in frame widths.
  double get palmWidth => landmarks.knuckleSpan;

  /// How far the palm is rotated from upright, in radians.
  double get rotation => toImage.rotation;

  /// The foreshortening measure — see [Affine2.anisotropy].
  double get anisotropy => toImage.anisotropy;

  /// Whether the warp reflects, which is true for exactly one hand.
  ///
  /// Not a fault. Canonical space is anatomical — thumb side to little
  /// finger side — so a left hand and a right hand map to the *same*
  /// canonical palm through transforms of opposite chirality, and the
  /// template needs no left/right variant. This getter exists because
  /// text does: a label mapped through [toImage] on one hand comes out
  /// mirrored, so labels are positioned by the transform and drawn
  /// upright.
  bool get isMirrored => toImage.determinant < 0;
}

/// A frame's verdict: whether to capture, and the warp if there is one.
@immutable
class PalmScan {
  /// Creates a verdict.
  const PalmScan({required this.readiness, this.frame});

  /// Why the shutter may or may not fire.
  final PalmReadiness readiness;

  /// The warp, when one could be fitted. Present even for some
  /// not-ready verdicts — a hand that is merely too small still has a
  /// usable pose, and the viewfinder draws its outline while it asks the
  /// user to come closer.
  final PalmFrame? frame;

  /// Whether to capture.
  bool get isReady => readiness.isReady;
}

/// Turning 21 points into a palm you can draw on.
///
/// ## Canonical palm space
///
/// `x` runs from the thumb side (0) to the little-finger side (1); `y`
/// from the knuckles (0) to the wrist (1). **Anatomical, not left and
/// right** — and that one choice is why there is no mirrored copy of the
/// line template. A left hand and a right hand both map onto the same
/// canonical palm; the transforms differ in chirality, and
/// [PalmFrame.isMirrored] reports it for the one consumer that cares.
///
/// ## Why these five anchors
///
/// The wrist and the four knuckles are rigid with respect to each other.
/// The thumb's CMC joint is not: it travels several percent of the frame
/// as the thumb abducts, and including it makes the warp breathe as
/// somebody relaxes their hand — which reads on video as the lines
/// crawling. It is excluded from the fit deliberately, and the template
/// still covers the thenar mount because [PalmCurve] control points do
/// not have to sit on an anchor.
abstract final class PalmGeometry {
  /// Where each anchor sits in canonical palm space.
  ///
  /// Authored from adult hand proportions — palm breadth is about 0.80
  /// of palm length, and the knuckle line arches with the middle finger
  /// furthest from the wrist and the little finger nearest. Those two
  /// facts are what make [Affine2.anisotropy] near 1 for a hand held
  /// flat to the lens, which is what makes [maxAnisotropy] mean
  /// something.
  ///
  /// **Tunable, and expected to be tuned** against real landmark
  /// captures — see `.claude/palm.md` §8, spike S3.
  static const Map<PalmLandmark, PalmPoint> canonicalAnchors = {
    PalmLandmark.wrist: PalmPoint(0.50, 1),
    PalmLandmark.indexMcp: PalmPoint(0.19, 0.19),
    PalmLandmark.middleMcp: PalmPoint(0.44, 0.12),
    PalmLandmark.ringMcp: PalmPoint(0.68, 0.15),
    PalmLandmark.pinkyMcp: PalmPoint(0.89, 0.25),
  };

  /// Below this detector confidence, the pose is not worth fitting.
  static const double minConfidence = 0.6;

  /// The knuckle span, in frame widths, under which creases do not
  /// survive the lens.
  static const double minKnuckleSpan = 0.28;

  /// Tip-to-wrist over knuckle-to-wrist, under which the fingers are
  /// curled far enough to hide the top of every line.
  ///
  /// A flat hand lands near 1.70 and a fist near 1.10, so this sits
  /// between them rather than close to either — the number wants to
  /// reject a half-closed hand without punishing short fingers.
  static const double minOpenness = 1.55;

  /// The foreshortening past which an affine warp stops being honest.
  static const double maxAnisotropy = 1.45;

  /// The anchor fit error, in canonical units, past which the warp is
  /// extrapolating.
  ///
  /// Least squares spreads one bad anchor across all five, so this is
  /// less sensitive than it looks: a knuckle displaced by 14 % of the
  /// palm's length — a firmly cupped hand — lands at 0.046. Landmark
  /// jitter on a flat hand is an order of magnitude below that, which is
  /// the gap this threshold sits in. Both ends are asserted in
  /// `palm_geometry_test.dart`; neither has been measured against a real
  /// detector yet.
  static const double maxResidual = 0.035;

  /// How close to an edge a landmark may sit, in frame widths.
  static const double edgeMargin = 0.02;

  /// Fits the warp for [landmarks], or null if it is degenerate.
  static PalmFrame? rectify(HandLandmarks landmarks) {
    final anchors = canonicalAnchors.keys.toList();
    final from = [for (final anchor in anchors) landmarks[anchor]];
    final to = [for (final anchor in anchors) canonicalAnchors[anchor]!];

    final toCanonical = Affine2.fit(from: from, to: to);
    final toImage = toCanonical?.inverse;
    if (toCanonical == null || toImage == null) return null;

    var squared = 0.0;
    for (var i = 0; i < from.length; i++) {
      final error = toCanonical.apply(from[i]) - to[i];
      squared += error.x * error.x + error.y * error.y;
    }

    return PalmFrame(
      toCanonical: toCanonical,
      toImage: toImage,
      landmarks: landmarks,
      residual: math.sqrt(squared / from.length),
    );
  }

  /// The full verdict on one frame.
  ///
  /// ## The order of complaints is the design
  ///
  /// The viewfinder shows one instruction at a time, so something has to
  /// decide which. The rule is *most fundamental first*: never ask
  /// somebody to move closer when they are showing the back of their
  /// hand, because doing what they were told will not help and the app
  /// will look broken. Framing complaints come last because they are the
  /// only ones the user can fix without being told twice.
  static PalmScan evaluate(HandLandmarks? landmarks) {
    if (landmarks == null) {
      return const PalmScan(readiness: PalmReadiness.noHand);
    }
    if (landmarks.confidence < minConfidence) {
      return const PalmScan(readiness: PalmReadiness.lowConfidence);
    }
    if (!landmarks.isPalmFacing) {
      return const PalmScan(readiness: PalmReadiness.backOfHand);
    }
    if (landmarks.openness < minOpenness) {
      return const PalmScan(readiness: PalmReadiness.fingersClosed);
    }

    final frame = rectify(landmarks);
    if (frame == null) {
      return const PalmScan(readiness: PalmReadiness.lowConfidence);
    }

    if (landmarks.knuckleSpan < minKnuckleSpan) {
      return PalmScan(readiness: PalmReadiness.tooSmall, frame: frame);
    }
    if (!_isFullyInFrame(landmarks)) {
      return PalmScan(readiness: PalmReadiness.offCentre, frame: frame);
    }
    if (frame.anisotropy > maxAnisotropy || frame.residual > maxResidual) {
      return PalmScan(readiness: PalmReadiness.tooOblique, frame: frame);
    }

    return PalmScan(readiness: PalmReadiness.ready, frame: frame);
  }

  static bool _isFullyInFrame(HandLandmarks landmarks) {
    final bottom = landmarks.frameAspect - edgeMargin;
    for (final point in landmarks.points) {
      if (point.x < edgeMargin ||
          point.x > 1 - edgeMargin ||
          point.y < edgeMargin ||
          point.y > bottom) {
        return false;
      }
    }
    return true;
  }
}
