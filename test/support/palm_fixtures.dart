import 'dart:math' as math;

import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_geometry.dart';

/// A whole hand in canonical palm space, fingers included.
///
/// Re-exported from `PalmGeometry` rather than copied. The viewfinder's
/// guide outline is drawn from the same map, and a fixture that drifted
/// from it would let a test pass against a hand the app never draws.
const Map<PalmLandmark, PalmPoint> canonicalHand = PalmGeometry.canonicalHand;

/// A similarity transform: uniform [scale], [rotation] in radians, then
/// [translation].
///
/// [translation] is where canonical `(0, 0)` lands, which is the thumb
/// side of the knuckle line rather than the middle of the hand.
///
/// [mirror] flips `x` first, which is what turns the canonical hand —
/// authored as a right palm — into a left one.
Affine2 pose({
  double scale = 0.5,
  double rotation = 0,
  PalmPoint translation = const PalmPoint(0.4, 0.7),
  bool mirror = false,
}) {
  final cos = math.cos(rotation);
  final sin = math.sin(rotation);
  final flip = mirror ? -1.0 : 1.0;
  return Affine2(
    a: scale * cos * flip,
    b: -scale * sin,
    tx: translation.x,
    c: scale * sin * flip,
    d: scale * cos,
    ty: translation.y,
  );
}

/// Builds landmarks by pushing [canonicalHand] through [transform].
///
/// The canonical hand is a *right* palm facing the lens, so a
/// [Handedness.left] hand needs a mirroring transform to stay palm-side
/// out — which is exactly the relationship `HandLandmarks.isPalmFacing`
/// tests, and why the two arguments are independent here rather than
/// derived from one another.
HandLandmarks handAt(
  Affine2 transform, {
  Handedness handedness = Handedness.right,
  double confidence = 0.95,
  double frameAspect = 16 / 9,
  Map<PalmLandmark, PalmPoint> canonical = canonicalHand,
}) => HandLandmarks(
  points: [
    for (final landmark in PalmLandmark.values)
      transform.apply(canonical[landmark]!),
  ],
  handedness: handedness,
  confidence: confidence,
  frameAspect: frameAspect,
);

/// The hand a good frame holds: a right palm, upright, filling a
/// comfortable share of the viewfinder.
///
/// Deliberately clear of the edges by more than `PalmGeometry.edgeMargin`
/// — the default pose used to land its little fingertip exactly on the
/// boundary, so any test that perturbed a landmark failed as
/// `offCentre` while appearing to be about something else.
HandLandmarks goodHand() => handAt(pose());

/// [canonicalHand] with the four fingers curled toward the palm by
/// [amount], where 0 leaves it open and 1 folds the tips onto the
/// knuckles.
Map<PalmLandmark, PalmPoint> curledHand(double amount) {
  const joints = {
    PalmLandmark.indexPip: PalmLandmark.indexMcp,
    PalmLandmark.indexDip: PalmLandmark.indexMcp,
    PalmLandmark.indexTip: PalmLandmark.indexMcp,
    PalmLandmark.middlePip: PalmLandmark.middleMcp,
    PalmLandmark.middleDip: PalmLandmark.middleMcp,
    PalmLandmark.middleTip: PalmLandmark.middleMcp,
    PalmLandmark.ringPip: PalmLandmark.ringMcp,
    PalmLandmark.ringDip: PalmLandmark.ringMcp,
    PalmLandmark.ringTip: PalmLandmark.ringMcp,
    PalmLandmark.pinkyPip: PalmLandmark.pinkyMcp,
    PalmLandmark.pinkyDip: PalmLandmark.pinkyMcp,
    PalmLandmark.pinkyTip: PalmLandmark.pinkyMcp,
  };
  return {
    for (final entry in canonicalHand.entries)
      entry.key: switch (joints[entry.key]) {
        final PalmLandmark knuckle => () {
          final base = canonicalHand[knuckle]!;
          return base + (entry.value - base) * (1 - amount);
        }(),
        null => entry.value,
      },
  };
}
