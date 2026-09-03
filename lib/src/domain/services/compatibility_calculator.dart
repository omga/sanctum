import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/domain/services/aspects.dart';

/// Scores a pairing from where the planets actually were.
///
/// ## What changed, and why it matters
///
/// The first version scored from the distance between two sun signs and
/// then nudged each result by `((a.index + b.index) % 5) - 2` so that
/// two different trines would not both return 94. That nudge was the one
/// part of this app that was genuinely arbitrary — decoration dressed as
/// a model — and it is gone. Every number below is now a continuous
/// function of four real planetary longitudes per person.
///
/// ## Each axis is owned by one planetary pair
///
/// No blending of everything into everything: each facet is driven by
/// the contact that traditionally governs it, so any score can be traced
/// back to a specific claim.
///
/// - **Spark** — Venus against Mars, both ways. Desire.
/// - **Vibe** — Sun and Venus, flowing. Whether ordinary days are nice.
/// - **Trust** — Sun against Venus. Being liked rather than wanted.
/// - **Drama** — Sun against Sun and Mars against Mars, hard angles.
/// - **Depth** — Saturn against Venus. The weight you cannot shake.
/// - **Future** — Saturn against Sun, flowing. Commitment that holds.
///
/// ## The Moon joins only when both people know their birth time
///
/// The Moon is the body synastry actually cares about — emotional
/// register, what someone needs rather than what they want — and it is
/// the one body a birth date cannot place. It moves 13° a day, so
/// without a time its sign is close to a coin toss.
///
/// So it is included when, and only when, *both* charts have a known
/// birth time. Every term below is otherwise exactly what it was, which
/// means a reading composed before this existed still computes to the
/// same numbers, and a match against a celebrity — whose catalogue entry
/// is a date from Wikidata with no time — is unaffected.
///
/// Half-knowing is the case worth being careful about. If one person
/// supplied a time and the other did not, the Moon is left out
/// altogether rather than guessed at noon for the missing side. A
/// lopsided model would put a real Moon against an invented one and
/// report the difference as a finding about the couple, which is the
/// same failure as inventing a score. It is the principle `_share`
/// already follows: the model should not be loudest where it knows
/// least.
///
/// ## Why the floor is 45
///
/// A 9% match is funny exactly once. The modal user is checking
/// themselves against somebody they actually like, and a product that
/// tells people their relationship is doomed gets deleted rather than
/// posted. The range is honest — both ends occur — it is simply not
/// cruel.
abstract final class CompatibilityCalculator {
  /// Lowest score the model will return.
  static const int floor = 45;

  /// Highest score the model will return.
  static const int ceiling = 98;

  /// Whether a reading between [you] and [them] can use the Moon.
  ///
  /// Surfaced so the UI can say what the reading is working from, and
  /// offer the missing birth time as something to add rather than
  /// quietly producing a thinner result.
  static bool usesMoon(MatchPerson you, MatchPerson them) =>
      you.moon != null && them.moon != null;

  /// The six facet scores for [you] and [them], in display order.
  static List<FacetScore> facets(MatchPerson you, MatchPerson them) => [
    for (final facet in CompatibilityFacet.values)
      FacetScore(facet: facet, score: score(facet, you, them)),
  ];

  /// The score for one [facet].
  static int score(
    CompatibilityFacet facet,
    MatchPerson you,
    MatchPerson them,
  ) => _toScale(_raw(facet, you, them));

  /// The headline number.
  ///
  /// Weighted rather than a flat mean: Drama is volatility, not virtue,
  /// so a couple who fight spectacularly should not out-score a couple
  /// who are happy. It contributes, because a reading with no charge in
  /// it is not compatibility either, just politeness.
  static int overall(MatchPerson you, MatchPerson them) {
    const weights = <CompatibilityFacet, double>{
      CompatibilityFacet.spark: 0.22,
      CompatibilityFacet.vibe: 0.22,
      CompatibilityFacet.trust: 0.20,
      CompatibilityFacet.drama: 0.06,
      CompatibilityFacet.depth: 0.12,
      CompatibilityFacet.future: 0.18,
    };

    var total = 0.0;
    for (final entry in weights.entries) {
      total += _raw(entry.key, you, them) * entry.value;
    }
    return _toScale(total);
  }

  /// Who wants it more, as the user's share of `100`.
  ///
  /// Their Mars reaching your Venus is them pursuing you; yours reaching
  /// theirs is the reverse. The two are genuinely different contacts,
  /// which is why this can be lopsided at all.
  static int pullShare(MatchPerson you, MatchPerson them) => _share(
    Aspects.heat(you.mars, them.venus),
    Aspects.heat(them.mars, you.venus),
  );

  /// Who sets the terms, as the user's share of `100`.
  ///
  /// Saturn is the one-way planet: the Saturn person is the one who
  /// defines what is acceptable, and the Sun person is the one who feels
  /// measured against it.
  static int powerShare(MatchPerson you, MatchPerson them) => _share(
    Aspects.heat(you.saturn, them.sun),
    Aspects.heat(them.saturn, you.sun),
  );

  /// A one-word read on a headline score.
  static String verdictFor(int overall) => switch (overall) {
    >= 90 => 'Rare',
    >= 80 => 'Strong',
    >= 70 => 'Charged',
    >= 60 => 'Workable',
    _ => 'Hard-won',
  };

  /// Distance between two signs on the wheel, `0–6`.
  ///
  /// Still here because the *sun-sign* aspect names the reading — the
  /// chip that says "Magnetic" — even though it no longer scores it.
  static int stepsBetween(ZodiacSign a, ZodiacSign b) {
    final raw = (a.index - b.index).abs();
    return raw > 6 ? 12 - raw : raw;
  }

  /// The classical aspect between two signs.
  ///
  /// [ZodiacAspect] is declared in distance order, so the step count is
  /// the index. The ordering is load-bearing and pinned by a test.
  static ZodiacAspect aspectBetween(ZodiacSign a, ZodiacSign b) =>
      ZodiacAspect.values[stepsBetween(a, b)];

  /// The unscaled `0–1` strength of a facet.
  ///
  /// Two parallel sets of weights rather than one set with zeroed terms,
  /// because every facet must still sum to 1.0 whichever branch runs —
  /// otherwise adding a birth time would not sharpen a score, it would
  /// simply inflate it, and every reading with a time would out-score
  /// every reading without one for no reason anybody could defend.
  static double _raw(
    CompatibilityFacet facet,
    MatchPerson a,
    MatchPerson b,
  ) {
    final aMoon = a.moon;
    final bMoon = b.moon;
    if (aMoon == null || bMoon == null) {
      return _rawWithoutMoon(facet, a, b);
    }

    return switch (facet) {
      // Desire is Venus and Mars. The Moon is not about wanting, so it
      // is left out here on purpose rather than for want of a weight.
      CompatibilityFacet.spark => _rawWithoutMoon(facet, a, b),
      CompatibilityFacet.vibe =>
        0.40 * Aspects.ease(a.sun, b.sun) +
            0.30 * Aspects.ease(a.venus, b.venus) +
            0.30 * Aspects.ease(aMoon, bMoon),
      CompatibilityFacet.trust =>
        0.35 * Aspects.ease(a.sun, b.venus) +
            0.35 * Aspects.ease(b.sun, a.venus) +
            0.15 * Aspects.ease(aMoon, b.venus) +
            0.15 * Aspects.ease(bMoon, a.venus),
      CompatibilityFacet.drama =>
        0.40 * Aspects.heat(a.sun, b.sun) +
            0.30 * Aspects.heat(a.mars, b.mars) +
            0.15 * Aspects.heat(aMoon, b.mars) +
            0.15 * Aspects.heat(bMoon, a.mars),
      CompatibilityFacet.depth =>
        0.35 * Aspects.heat(a.saturn, b.venus) +
            0.35 * Aspects.heat(b.saturn, a.venus) +
            0.15 * Aspects.heat(a.saturn, bMoon) +
            0.15 * Aspects.heat(b.saturn, aMoon),
      // Saturn to Sun is the commitment contact and stands alone.
      CompatibilityFacet.future => _rawWithoutMoon(facet, a, b),
    };
  }

  /// The original four-body model, unchanged.
  static double _rawWithoutMoon(
    CompatibilityFacet facet,
    MatchPerson a,
    MatchPerson b,
  ) => switch (facet) {
    CompatibilityFacet.spark =>
      0.40 * Aspects.heat(a.venus, b.mars) +
          0.40 * Aspects.heat(b.venus, a.mars) +
          0.20 * Aspects.heat(a.mars, b.mars),
    CompatibilityFacet.vibe =>
      0.55 * Aspects.ease(a.sun, b.sun) +
          0.45 * Aspects.ease(a.venus, b.venus),
    CompatibilityFacet.trust =>
      0.50 * Aspects.ease(a.sun, b.venus) +
          0.50 * Aspects.ease(b.sun, a.venus),
    CompatibilityFacet.drama =>
      0.55 * Aspects.heat(a.sun, b.sun) +
          0.45 * Aspects.heat(a.mars, b.mars),
    CompatibilityFacet.depth =>
      0.50 * Aspects.heat(a.saturn, b.venus) +
          0.50 * Aspects.heat(b.saturn, a.venus),
    CompatibilityFacet.future =>
      0.50 * Aspects.ease(a.saturn, b.sun) +
          0.50 * Aspects.ease(b.saturn, a.sun),
  };

  /// Maps a `0–1` strength onto the published range.
  ///
  /// The harmonic functions average 0.5, so untouched they would bunch
  /// every result around the middle of the scale. The expansion below
  /// widens it so that a 96 is reachable and means something.
  ///
  /// This is presentation, not modelling, and the distinction is the
  /// whole point: it is one monotonic curve applied identically to every
  /// pair, so it never changes which of two couples scores higher. The
  /// term it replaced was a per-pair nudge, which did.
  static int _toScale(double raw) {
    const expansion = 1.45;
    final widened = 0.5 + (raw.clamp(0.0, 1.0) - 0.5) * expansion;
    final clamped = widened.clamp(0.0, 1.0);
    return (floor + (ceiling - floor) * clamped).round();
  }

  /// Splits two raw strengths into shares of 100.
  ///
  /// The constant pulls weak pairs toward even. Without it, two people
  /// with no strong contacts either way would land on some dramatic
  /// 80/20 split decided by rounding noise — the model would be loudest
  /// exactly where it knows least.
  static int _share(double yours, double theirs) {
    const damping = 0.18;
    final share =
        (yours + damping) / (yours + theirs + 2 * damping);
    return (share * 100).round().clamp(5, 95);
  }
}
