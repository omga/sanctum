import 'package:meta/meta.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_crease_snapper.dart';
import 'package:sanctum/src/domain/services/palm_geometry.dart';
import 'package:sanctum/src/domain/services/palm_line_template.dart';

/// A finished scan: the warp, the lines as they will be drawn, and how
/// much of each one the photograph actually supports.
@immutable
class PalmReading {
  /// Creates a reading. Built by [PalmComposer.compose].
  const PalmReading({
    required this.id,
    required this.frame,
    required this.curves,
    required this.canonicalCurves,
    required this.priors,
    required this.support,
    required this.measured,
    required this.claimed,
  });

  /// What the gate and the analytics call this scan.
  ///
  /// A capture instant and a handedness, and nothing else. It identifies
  /// a *session*, never a person: two scans of the same palm get
  /// different ids on purpose, so nothing stored against one can be
  /// joined up into a record of a hand. See `PalmRepository`.
  final String id;

  /// The rectified palm.
  final PalmFrame frame;

  /// The lines, snapped and placed in [PalmSpace.image], ready to draw.
  final List<PalmCurve> curves;

  /// The same lines before placement, in canonical palm space.
  ///
  /// Kept because everything *measured* about a line has to be measured
  /// here. A length in frame widths says as much about how close the
  /// hand was held as about the hand, so a reading built on it would
  /// tell somebody their life line grew when they stepped forward.
  final List<PalmCurve> canonicalCurves;

  /// The prior each line was traced from, in canonical space.
  ///
  /// Not always the canonical template: the life line is fitted to the
  /// hand's own thumb first. Kept so that anything measured *relative* to
  /// what was expected — a line's length, above all — is measured against
  /// what was actually expected for this hand.
  final Map<PalmLine, PalmCurve> priors;

  /// How well each line sits on a real crease, `[0, 1]`.
  ///
  /// Meaningless unless [measured] is true.
  final Map<PalmLine, double> support;

  /// Whether a ridge field was available at all.
  ///
  /// The distinction [support] cannot carry on its own: zero means "we
  /// looked and found nothing" only when this is true, and "we did not
  /// look" when it is false. Collapsing the two makes every scan on a
  /// build with no crease filter report as too faint to read — which is
  /// a claim about the user's hand that nothing measured.
  final bool measured;

  /// The lines this hand is allowed to be told about.
  final Set<PalmLine> claimed;

  /// The curve for [line], or null if this hand does not claim it.
  PalmCurve? curveOf(PalmLine line) {
    for (final curve in curves) {
      if (curve.line == line) return curve;
    }
    return null;
  }
}

/// Turns one detected hand into the lines a reveal will draw.
///
/// ## The order matters
///
/// Rectify, then snap **in canonical space**, then place. Snapping in
/// frame space would work, but the search radius and the smoothing
/// weights would then mean different things on a hand held near the lens
/// than on one held far away — the same numbers would be tight on one
/// scan and sloppy on the next. In canonical space they are fractions of
/// a palm, which is what they are supposed to be.
///
/// ## Which lines a hand is allowed to be told about
///
/// The three principal lines are always claimed. Every hand has a heart,
/// head and life line; if the ridge filter cannot find one, that is a
/// statement about the lighting, not about the hand, and refusing to
/// draw it would make the app look broken on a dim evening.
///
/// **The fate line is different.** Plenty of hands genuinely have none,
/// so it is claimed only when the creases support it — and a reading
/// that stays quiet about it is telling the truth, where one that
/// describes it is making a claim the user disproves by looking down.
abstract final class PalmComposer {
  /// How much support the fate line needs before it is claimed.
  ///
  /// **Not calibrated.** The synthetic fields in the tests put a line
  /// sitting on its crease above 0.8 and a line sitting on nothing at 0,
  /// so anything in between separates them; where the boundary belongs
  /// against a real ridge filter is spike S3's question, not this
  /// file's.
  static const double fateThreshold = 0.35;

  /// The id for a scan taken at [at] of a [handedness] hand.
  ///
  /// Second resolution, because that is enough to separate two scans and
  /// not enough to be a fingerprint. UTC so the id does not change
  /// meaning when somebody flies.
  static String idFor({
    required DateTime at,
    required Handedness handedness,
  }) {
    final instant = at.toUtc().toIso8601String().split('.').first;
    return 'palm:$instant:${handedness.name}';
  }

  /// Composes the reading for [landmarks], or null when the pose cannot
  /// be rectified at all.
  ///
  /// [field] is the ridge response over canonical palm space. Pass
  /// `null` to skip snapping entirely and draw the bare template — which
  /// is what the live viewfinder does, because it has a preview frame
  /// rather than a still and no time to filter it.
  static PalmReading? compose({
    required HandLandmarks landmarks,
    required DateTime at,
    RidgeField? field,
    double fateThreshold = PalmComposer.fateThreshold,
  }) {
    final frame = PalmGeometry.rectify(landmarks);
    if (frame == null) return null;

    final support = <PalmLine, double>{};
    final canonical = <PalmCurve>[];

    // The life line's prior is fitted to where this hand's thumb actually
    // is, carried into canonical space by the same warp as everything
    // else. It is the only line that depends on the thumb, and the warp
    // alone cannot see the thumb — see `PalmLineTemplate.lifeAround`.
    final priors = PalmLineTemplate.forHand(
      thumbBase: frame.toCanonical.apply(landmarks[PalmLandmark.thumbCmc]),
    );

    for (final template in priors) {
      final snapped = field == null
          ? template
          : PalmCreaseSnapper.snap(curve: template, field: field);
      support[template.line] = field == null
          ? 0
          : PalmCreaseSnapper.support(curve: snapped, field: field);
      canonical.add(snapped);
    }

    final claimed = <PalmLine>{
      ...PalmLine.principal,
      if ((support[PalmLine.fate] ?? 0) >= fateThreshold) PalmLine.fate,
    };

    final kept = [
      for (final curve in canonical)
        if (claimed.contains(curve.line)) curve,
    ];

    return PalmReading(
      id: idFor(at: at, handedness: landmarks.handedness),
      frame: frame,
      curves: [for (final curve in kept) frame.place(curve)],
      canonicalCurves: kept,
      priors: {for (final prior in priors) prior.line: prior},
      measured: field != null,
      support: support,
      claimed: claimed,
    );
  }
}
