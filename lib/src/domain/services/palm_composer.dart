import 'dart:math' as math;

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
    required this.background,
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

  /// How crease-like the palm is where no line runs, `[0, 1]`.
  ///
  /// The yardstick [support] is read against. Support alone is a poor
  /// judge of a photograph: the ridge filter scales every response by
  /// the strongest things in the crop, and on most photographs those are
  /// the edges of the hand against whatever is behind it — so a real
  /// crease traced perfectly can score low in absolute terms, while a
  /// pen line scores high. What distinguishes a readable photograph from
  /// an unreadable one is whether the lines stand out from the palm
  /// around them, and this is the "around them".
  ///
  /// Zero when nothing was measured.
  final double background;

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

    assert(
      priors.last.line == PalmLine.fate,
      'fate must be traced after the lines it is kept off',
    );

    for (final template in priors) {
      // Fate is traced last, against a field with the lines already traced
      // taken out of it. The fate line runs up the middle of the palm, and
      // a life line bowed well toward the middle can pass within a few
      // hundredths of it — inside the tracer's band. Traced against the
      // whole field, the fate line on a hand that has none would follow the
      // life line's crease and score it as its own, and the reading would
      // describe a line the user cannot find. Taking those creases out
      // leaves only evidence that belongs to no other line.
      final own = switch (field) {
        null => null,
        final whole when template.line == PalmLine.fate => _Excluding(
          whole,
          canonical,
        ),
        final whole => whole,
      };
      final snapped = own == null
          ? template
          : PalmCreaseSnapper.snap(curve: template, field: own);
      support[template.line] = own == null
          ? 0
          : PalmCreaseSnapper.support(curve: snapped, field: own);
      canonical.add(snapped);
    }

    final background = field == null ? 0.0 : _backgroundOf(field, canonical);

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
      background: background,
      measured: field != null,
      support: support,
      claimed: claimed,
    );
  }

  /// The mean ridge response over the palm, away from every traced line.
  ///
  /// A grid across the palm's interior rather than the whole crop: the
  /// crop reaches past the hand, and its edges against the background
  /// are exactly the strong responses this is meant to see past.
  static double _backgroundOf(RidgeField field, List<PalmCurve> lines) {
    const steps = 16;
    const clearance = 0.035;
    final near = [for (final line in lines) ...line.sample()];

    var total = 0.0;
    var count = 0;
    for (var row = 0; row < steps; row++) {
      for (var column = 0; column < steps; column++) {
        final point = PalmPoint(
          0.15 + 0.70 * column / (steps - 1),
          0.20 + 0.70 * row / (steps - 1),
        );
        if (near.any((sample) => sample.distanceTo(point) < clearance)) {
          continue;
        }
        total += field.responseAt(point).clamp(0.0, 1.0);
        count++;
      }
    }
    return count == 0 ? 0 : total / count;
  }
}

/// [field] with the creases of lines already traced faded out.
///
/// A soft mask rather than a hard cut: a hard edge would put a step in
/// the response that the tracer could mistake for the side of a crease.
/// Within a couple of hundredths of a traced line the response is gone;
/// by four hundredths — where a real fate line beside the life line would
/// run — it is essentially untouched.
class _Excluding implements RidgeField {
  _Excluding(this.field, List<PalmCurve> lines)
    : _samples = [for (final line in lines) ...line.sample(perSegment: 6)];

  final RidgeField field;
  final List<PalmPoint> _samples;

  static const double _radius = 0.025;

  @override
  double responseAt(PalmPoint point) {
    var nearest = double.infinity;
    for (final sample in _samples) {
      final distance = sample.distanceTo(point);
      if (distance < nearest) nearest = distance;
    }
    final ratio = nearest / _radius;
    return field.responseAt(point) * (1 - math.exp(-ratio * ratio));
  }
}
