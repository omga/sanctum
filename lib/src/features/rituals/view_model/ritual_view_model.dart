import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/core/time/clock.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/domain/models/journal_entry.dart';
import 'package:sanctum/src/domain/models/moon_phase.dart';
import 'package:sanctum/src/domain/models/ritual.dart';
import 'package:sanctum/src/domain/services/moon_phase_calculator.dart';
import 'package:sanctum/src/domain/services/ritual_selector.dart';

part 'ritual_view_model.g.dart';

/// What the rituals surface knows about today.
class RitualUiState {
  /// Creates the state.
  const RitualUiState({
    required this.phase,
    required this.today,
    this.ritual,
    this.nextRitual,
    this.daysUntilNext,
  });

  /// Tonight's phase.
  final MoonPhase phase;

  /// The local date.
  final DateTime today;

  /// The ritual available now, if this phase has one.
  final Ritual? ritual;

  /// The next ritual to become available, when none is available today.
  final Ritual? nextRitual;

  /// Days until [nextRitual] opens.
  final int? daysUntilNext;

  /// Whether a ritual can be done right now.
  bool get isOpen => ritual != null;
}

/// Today's ritual, or the wait until the next one.
@riverpod
Future<RitualUiState> ritualState(Ref ref) async {
  final today = ref.watch(clockProvider).today();
  final catalog = await ref.watch(contentCatalogProvider.future);
  final phase = MoonPhaseCalculator.phaseFor(today);

  final available = RitualSelector.select(
    catalog.ritualsFor(phase),
    phase,
    today,
  );
  if (available != null) {
    return RitualUiState(phase: phase, today: today, ritual: available);
  }

  // Nothing today: find whichever ritual phase arrives first. Searching
  // the catalogue rather than hard-coding the four quarters means adding
  // a ritual for a new phase needs no code change here.
  //
  // The teaser names the ritual that phase will *actually* open with, so
  // it goes through the selector on the future date rather than showing
  // whichever entry happens to sit first in the JSON.
  Ritual? soonest;
  var soonestDays = 1 << 30;

  for (final candidate in MoonPhase.values) {
    if (!catalog.hasRitualFor(candidate)) continue;
    final date = MoonPhaseCalculator.nextOccurrence(candidate, today);
    final days = today.calendarDaysUntil(date);
    if (days >= 0 && days < soonestDays) {
      soonestDays = days;
      soonest = RitualSelector.select(
        catalog.ritualsFor(candidate),
        candidate,
        date,
      );
    }
  }

  return RitualUiState(
    phase: phase,
    today: today,
    nextRitual: soonest,
    daysUntilNext: soonest == null ? null : soonestDays,
  );
}

/// Completing a ritual.
@riverpod
class RitualController extends _$RitualController {
  @override
  FutureOr<void> build() {}

  /// Marks [ritual] complete by writing [reflection] into the journal.
  ///
  /// A ritual that leaves nothing behind is just a page of instructions.
  /// Writing it in as a [JournalKind.ritual] entry gives it an artefact
  /// the user can return to, and makes the moon cycle legible in their
  /// own words months later.
  Future<void> complete({
    required Ritual ritual,
    required String reflection,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(journalRepositoryProvider)
        .add(
          kind: JournalKind.ritual,
          body: reflection,
          createdAt: ref.read(clockProvider).now(),
          prompt: '${ritual.moon} · ${ritual.title}',
        );
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}
