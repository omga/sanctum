import 'package:sanctum/src/domain/models/moon_phase.dart';
import 'package:sanctum/src/domain/models/ritual.dart';
import 'package:sanctum/src/domain/services/moon_phase_calculator.dart';

/// Picks which ritual a given moon opens with.
///
/// ## The problem this exists to solve
///
/// The catalogue used to hold exactly one ritual per phase, and
/// `ritualFor` returned the first match. A user six months in had done
/// the same New Moon ritual six times, word for word. Rituals are the
/// app's strongest retention surface precisely because they are rare —
/// and identical repetition is what turns rare into stale.
///
/// Simply adding more entries would not have fixed it: a second ritual
/// with the same phase was unreachable, sitting in the JSON forever
/// while the first one kept being served.
///
/// ## Why the cycle, and not the day
///
/// The obvious index is the date, and it is wrong. A phase band is
/// several days wide, so a day-keyed pick would hand the user a
/// *different* ritual each morning of the same full moon — including
/// halfway through one they had started. The unit of a ritual is the
/// occurrence, not the day.
///
/// So the key is the lunation containing the current run of the phase.
/// It is constant for every day of one window and increments by exactly
/// one between windows, which makes this a true round-robin: every
/// ritual for a phase is seen once before any is seen twice.
///
/// ## Why this is not personalised
///
/// `DailyAttunementSelector` salts its pick per install, deliberately,
/// so the daily card does not feel like a broadcast. This does the
/// opposite, also deliberately. A daily card is a *reading* — it should
/// be about you. A moon ritual is a *practice* attached to a real event
/// in the sky that everybody is under at the same time, and two friends
/// comparing notes on the same full moon should find they were asked to
/// do the same thing. It also keeps this pure and synchronous, with no
/// install salt to thread through a provider.
abstract final class RitualSelector {
  /// The ritual for [phase] on [date], or null if that phase has none.
  ///
  /// [rituals] should already be filtered to [phase]; anything else is
  /// ignored, so a caller cannot accidentally serve a full moon ritual
  /// on a new moon.
  static Ritual? select(
    List<Ritual> rituals,
    MoonPhase phase,
    DateTime date,
  ) {
    final candidates = [
      for (final ritual in rituals)
        if (ritual.phase == phase) ritual,
    ];
    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;

    final start = MoonPhaseCalculator.occurrenceStart(phase, date);
    final cycle = MoonPhaseCalculator.lunationNumber(start);

    // Dart's % is non-negative for a positive divisor, so dates before
    // the year 2000 reference wrap correctly rather than throwing.
    return candidates[cycle % candidates.length];
  }
}
