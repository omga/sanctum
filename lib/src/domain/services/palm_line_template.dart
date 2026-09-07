import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_geometry.dart';

/// The principal lines, authored once in canonical palm space.
///
/// ## Why a template at all
///
/// There is no shipping model that segments palm creases. It is an open
/// research problem — the published work is U-Net segmentation over
/// rectified crops — and every package that sounds like it detects palm
/// lines is detecting hand *landmarks*. So the lines start as an
/// anatomical prior and are then pulled onto the real creases by
/// `PalmCreaseSnapper`, which is the half that makes two people's scans
/// differ.
///
/// Drawing this template without that second step is honest only as far
/// as "the heart line runs there on most hands". It is the floor, not
/// the feature.
///
/// ## One set, both hands
///
/// Canonical space is anatomical — `x` from the thumb side to the little
/// finger side — so these curves serve a left hand and a right hand
/// alike. See [PalmGeometry] for why that works and what it costs.
///
/// ## These numbers are authored, and not yet measured
///
/// They come from standard palmistry placement over adult hand
/// proportions, not from a dataset. Spike S3 in `.claude/palm.md` §8 is
/// what replaces them with something fitted to real captures; until it
/// runs, treat every coordinate here as a starting point.
abstract final class PalmLineTemplate {
  /// The heart line: from the little-finger edge, rising toward the gap
  /// between the index and middle fingers.
  static final PalmCurve heart = PalmCurve(
    line: PalmLine.heart,
    controlPoints: const [
      PalmPoint(0.97, 0.34),
      PalmPoint(0.82, 0.29),
      PalmPoint(0.66, 0.26),
      PalmPoint(0.50, 0.25),
      PalmPoint(0.40, 0.24),
      PalmPoint(0.32, 0.22),
      PalmPoint(0.24, 0.19),
    ],
  );

  /// The head line: across the middle of the palm, sloping away from the
  /// fingers as it crosses.
  static final PalmCurve head = PalmCurve(
    line: PalmLine.head,
    controlPoints: const [
      PalmPoint(0.16, 0.36),
      PalmPoint(0.30, 0.38),
      PalmPoint(0.45, 0.42),
      PalmPoint(0.58, 0.46),
      PalmPoint(0.68, 0.49),
      PalmPoint(0.76, 0.52),
      PalmPoint(0.84, 0.55),
    ],
  );

  /// The life line: around the ball of the thumb, from the index edge
  /// down to the wrist.
  static final PalmCurve life = PalmCurve(
    line: PalmLine.life,
    controlPoints: const [
      PalmPoint(0.19, 0.30),
      PalmPoint(0.14, 0.42),
      PalmPoint(0.16, 0.55),
      PalmPoint(0.24, 0.68),
      PalmPoint(0.30, 0.78),
      PalmPoint(0.36, 0.86),
      PalmPoint(0.42, 0.95),
    ],
  );

  /// The fate line: rising from the wrist toward the middle finger.
  ///
  /// Offered separately from [principal] because plenty of hands do not
  /// have one, and drawing it regardless is a claim the user can
  /// disprove by looking down.
  static final PalmCurve fate = PalmCurve(
    line: PalmLine.fate,
    controlPoints: const [
      PalmPoint(0.48, 0.95),
      PalmPoint(0.48, 0.78),
      PalmPoint(0.47, 0.62),
      PalmPoint(0.46, 0.48),
      PalmPoint(0.45, 0.38),
      PalmPoint(0.45, 0.30),
      PalmPoint(0.45, 0.22),
    ],
  );

  /// The three lines every hand has, in the order the reveal draws them.
  ///
  /// Heart first because it is the uppermost and the one people look for;
  /// life last because it is the longest and ends at the wrist, which is
  /// where the composition wants to settle before the verdict card.
  static List<PalmCurve> get principal => [heart, head, life];

  /// Every line, fate included.
  static List<PalmCurve> get all => [heart, head, life, fate];

  /// The template for [line].
  static PalmCurve of(PalmLine line) => switch (line) {
    PalmLine.heart => heart,
    PalmLine.head => head,
    PalmLine.life => life,
    PalmLine.fate => fate,
  };
}
