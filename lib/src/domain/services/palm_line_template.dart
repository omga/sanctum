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
/// ## These numbers are a prior, not an answer
///
/// They come from palmar crease anatomy over adult hand proportions: the
/// heart line over the little and ring knuckles, the head line starting
/// with the life line at the thumb-side edge, the life line round the
/// thenar eminence. They are there to put the tracer in the right
/// neighbourhood, and the tracer decides the rest — including which way a
/// line bends, because the first time that was authored by eye it was
/// authored backwards.
abstract final class PalmLineTemplate {
  /// The heart line: from the little-finger edge, across, and curving up
  /// at the end into the gap between the index and middle fingers.
  ///
  /// It sags toward the wrist in the middle, which is the common shape —
  /// and deliberately only a prior. Heart lines genuinely bend either way,
  /// and the tracer is free to follow whichever this one does.
  static final PalmCurve heart = PalmCurve(
    line: PalmLine.heart,
    controlPoints: const [
      PalmPoint(1, 0.36),
      PalmPoint(0.88, 0.35),
      PalmPoint(0.74, 0.33),
      PalmPoint(0.62, 0.32),
      PalmPoint(0.5, 0.31),
      PalmPoint(0.38, 0.28),
      PalmPoint(0.3, 0.21),
    ],
  );

  /// The head line: across the middle of the palm, sloping away from the
  /// fingers as it crosses.
  static final PalmCurve head = PalmCurve(
    line: PalmLine.head,
    controlPoints: const [
      PalmPoint(0.12, 0.35),
      PalmPoint(0.26, 0.37),
      PalmPoint(0.4, 0.41),
      PalmPoint(0.52, 0.45),
      PalmPoint(0.64, 0.49),
      PalmPoint(0.74, 0.52),
      PalmPoint(0.82, 0.54),
    ],
  );

  /// The life line: around the ball of the thumb, from the index edge
  /// down to the wrist.
  ///
  /// It bows toward the **middle of the palm**, enclosing the thumb's
  /// mount on its thumb side. The first version bowed the other way —
  /// toward the thumb — which a Pixel 6 photograph made obvious and which
  /// no amount of snapping could rescue: at its middle it sat about 0.3
  /// of a palm from the real crease, several times further than the
  /// snapper was allowed to look.
  static final PalmCurve life = PalmCurve(
    line: PalmLine.life,
    controlPoints: const [
      PalmPoint(0.13, 0.36),
      PalmPoint(0.22, 0.42),
      PalmPoint(0.32, 0.52),
      PalmPoint(0.37, 0.65),
      PalmPoint(0.41, 0.76),
      PalmPoint(0.4, 0.88),
      PalmPoint(0.35, 0.97),
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
      PalmPoint(0.54, 0.96),
      PalmPoint(0.54, 0.8),
      PalmPoint(0.52, 0.64),
      PalmPoint(0.51, 0.52),
      PalmPoint(0.5, 0.42),
      PalmPoint(0.49, 0.34),
      PalmPoint(0.48, 0.26),
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
