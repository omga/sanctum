import 'package:sanctum/src/domain/models/energy_check_in.dart';
import 'package:sanctum/src/domain/models/moon_phase.dart';
import 'package:sanctum/src/domain/services/moon_phase_calculator.dart';

/// What the user's own check-ins add up to.
class EnergyPattern {
  /// Creates a pattern.
  const EnergyPattern({
    required this.days,
    required this.averageByPhase,
    required this.total,
    this.finding,
  });

  /// The last stretch of days, oldest first. `null` where nothing was
  /// logged, so the strip shows gaps honestly rather than closing them.
  final List<EnergyLevel?> days;

  /// Mean energy per moon phase, where there is enough to mean anything.
  final Map<MoonPhase, double> averageByPhase;

  /// How many check-ins went into this.
  final int total;

  /// The one sentence worth showing, or `null` if there is not one.
  final String? finding;

  /// Whether there is enough history to say anything at all.
  bool get hasFinding => finding != null;
}

/// Reads a user's check-in history back to them.
///
/// ## Why this exists
///
/// The check-in was a deposit with no withdrawal: the app asked how you
/// felt every day, stored it, and never mentioned it again.
/// `EnergyRepository.watchRecent` was written and called from nowhere.
/// An app that collects feelings and never refers to them teaches people
/// to stop answering, which is worse than never having asked.
///
/// ## Why it is correlated with the moon rather than just charted
///
/// A line graph of your mood is a fitness app. The thing only Sanctum
/// can do — because it keeps history locally and computes real lunar
/// phase — is put the two together: *"you have logged Depleted on four
/// of the last five full moons."* That converts the user's own data into
/// evidence for the app's premise, which is a far better argument than
/// any copy could make, and it is the natural thing to put behind the
/// paywall.
///
/// ## Why it refuses to speak most of the time
///
/// A finding is only produced when both phases have at least
/// [minimumPerPhase] check-ins and the gap between them clears
/// [minimumGap]. Anything looser and the app starts announcing patterns
/// in four data points, which is how a product that claims to know you
/// gets caught not knowing you.
abstract final class EnergyPatternCalculator {
  /// Check-ins needed in a phase before it can appear in a finding.
  static const int minimumPerPhase = 3;

  /// How far apart two phase averages must be, on the 1–5 scale.
  static const double minimumGap = 0.7;

  /// How many days the strip shows.
  static const int windowDays = 30;

  /// Analyses [checkIns] as of [today].
  static EnergyPattern analyse({
    required List<EnergyCheckIn> checkIns,
    required DateTime today,
  }) {
    final byDay = <DateTime, EnergyLevel>{};
    for (final entry in checkIns) {
      byDay[_dayOf(entry.recordedAt)] = entry.level;
    }

    final start = _dayOf(today).subtract(
      const Duration(days: windowDays - 1),
    );
    final days = [
      for (var i = 0; i < windowDays; i++)
        byDay[start.add(Duration(days: i))],
    ];

    final buckets = <MoonPhase, List<int>>{};
    for (final entry in checkIns) {
      final phase = MoonPhaseCalculator.phaseFor(entry.recordedAt);
      (buckets[phase] ??= []).add(entry.level.value);
    }

    final averages = <MoonPhase, double>{
      for (final entry in buckets.entries)
        entry.key:
            entry.value.reduce((a, b) => a + b) / entry.value.length,
    };

    return EnergyPattern(
      days: days,
      averageByPhase: averages,
      total: checkIns.length,
      finding: _findingFrom(buckets, averages),
    );
  }

  static String? _findingFrom(
    Map<MoonPhase, List<int>> buckets,
    Map<MoonPhase, double> averages,
  ) {
    final eligible = [
      for (final entry in averages.entries)
        if ((buckets[entry.key]?.length ?? 0) >= minimumPerPhase) entry,
    ];
    if (eligible.length < 2) return null;

    eligible.sort((a, b) => a.value.compareTo(b.value));
    final lowest = eligible.first;
    final highest = eligible.last;
    if (highest.value - lowest.value < minimumGap) return null;

    final count = buckets[lowest.key]!.length;
    return 'Your energy runs lowest around the '
        '${lowest.key.displayName.toLowerCase()} — $count check-ins say '
        'so — and highest around the '
        '${highest.key.displayName.toLowerCase()}.';
  }

  static DateTime _dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
