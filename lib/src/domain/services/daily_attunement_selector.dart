import 'package:sanctum/src/core/time/clock.dart';
import 'package:sanctum/src/domain/services/deterministic_shuffle.dart';

/// Picks the one piece of content a user sees for a given day.
///
/// ## The requirement
///
/// The daily card must be:
///
/// * **Stable within a day** — reopening the app must not reroll it.
/// * **Different tomorrow** — it turns over at the user's local midnight.
/// * **Personal** — two people on the same day should not get the same
///   card, or the feature feels like a broadcast rather than a reading.
/// * **Free of backend** — no request, no account, works offline.
/// * **Non-repeating** — seeing the same card twice in one week reads as
///   broken, however random it technically is.
///
/// ## How
///
/// Days are numbered from an epoch. The catalogue is deterministically
/// shuffled once per *cycle*, where a cycle is `catalogue.length` days,
/// seeded by the user's salt plus the cycle number. The day's card is
/// then simply the entry at that day's index within the cycle.
///
/// That last step is what a naive `hash(salt, date) % length` gets wrong:
/// modulo picks independently each day, so it happily repeats a card two
/// days running. A shuffled cycle guarantees every card is seen once
/// before any is seen twice, and reshuffles into a new order each cycle.
///
/// ## The seam
///
/// Shuffling each cycle independently is not quite enough. A cycle
/// boundary joins the *tail* of one permutation to the *head* of the
/// next, and those two were shuffled with no knowledge of each other —
/// so a card at the end of one cycle can reappear two days later at the
/// start of the next. Within an aligned cycle the no-repeat property
/// holds, but the user does not experience aligned cycles; they
/// experience a sliding window of recent days.
///
/// `_permutationFor` therefore repairs the head of each permutation
/// against the tail of the previous one. The repair only ever swaps
/// entries within the head and middle, never the tail — which is what
/// keeps it from recursing, since the next cycle's repair reads only the
/// tail.
///
/// **Guaranteed:** every card appears exactly once per aligned cycle,
/// and no card repeats within `guardDays` days of itself. With a
/// catalogue of 21 or more that is a full week.
abstract final class DailyAttunementSelector {
  /// Day zero. Arbitrary but fixed — changing it reshuffles everyone.
  static final DateTime epoch = DateTime.utc(2020);

  /// Whole days from [epoch] to [date].
  static int dayNumber(DateTime date) => epoch.calendarDaysUntil(date.dateOnly);

  /// The index into [catalogueLength] for [date] and [salt].
  ///
  /// Exposed separately from [select] so it can be tested without a
  /// catalogue, and reused for parallel catalogues (an affirmation and a
  /// card drawn for the same day).
  static int indexFor({
    required int catalogueLength,
    required DateTime date,
    required String salt,
  }) {
    assert(catalogueLength > 0, 'catalogue must not be empty');
    if (catalogueLength == 1) return 0;

    final day = dayNumber(date);
    // Floor division, so dates before the epoch still land in a sane
    // cycle instead of mirroring around zero.
    final cycle = (day / catalogueLength).floor();
    final indexInCycle = day - cycle * catalogueLength;

    return _permutationFor(catalogueLength, salt, cycle)[indexInCycle];
  }

  /// The maximum enforced gap between two showings of the same card.
  ///
  /// Capped at a week — beyond that the constraint starts to fight the
  /// shuffle on small catalogues without the user ever noticing.
  static const int maxGuardDays = 7;

  /// The gap actually enforced for a catalogue of [length].
  ///
  /// The repair needs somewhere to move offending entries to, so the
  /// guard can never exceed roughly a third of the catalogue.
  static int guardDays(int length) {
    final third = (length - 1) ~/ 3;
    return third < maxGuardDays ? third : maxGuardDays;
  }

  /// The repaired order of card indices for one cycle.
  static List<int> _permutationFor(int length, String salt, int cycle) {
    List<int> shuffleFor(int c) => DeterministicShuffle.shuffled(
      List<int>.generate(length, (i) => i),
      DeterministicShuffle.hash('$salt:$c'),
    );

    final order = shuffleFor(cycle);
    final guard = guardDays(length);
    if (guard < 1) return order;

    // Only the previous permutation's TAIL matters, and a repair never
    // touches a tail — so reading the unrepaired previous shuffle here is
    // correct, and there is no recursion.
    final recent = shuffleFor(cycle - 1).sublist(length - guard).toSet();

    for (var i = 0; i < guard; i++) {
      if (!recent.contains(order[i])) continue;
      // Swap the offender into the middle region, which is neither head
      // nor tail, taking the first slot that is itself safe.
      for (var j = guard; j < length - guard; j++) {
        if (recent.contains(order[j])) continue;
        final temp = order[i];
        order[i] = order[j];
        order[j] = temp;
        break;
      }
    }

    return order;
  }

  /// The entry from [catalogue] for [date].
  ///
  /// [salt] should be a per-install identifier so that two users on the
  /// same day see different content.
  static T select<T>({
    required List<T> catalogue,
    required DateTime date,
    required String salt,
  }) {
    return catalogue[indexFor(
      catalogueLength: catalogue.length,
      date: date,
      salt: salt,
    )];
  }
}
