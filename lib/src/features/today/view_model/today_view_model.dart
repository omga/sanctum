import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/analytics/analytics_event.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/core/time/clock.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/repositories/oracle_repository.dart';
import 'package:sanctum/src/domain/models/energy_check_in.dart';
import 'package:sanctum/src/domain/models/moon_phase.dart';
import 'package:sanctum/src/domain/models/oracle_card.dart';
import 'package:sanctum/src/domain/models/quiz.dart';
import 'package:sanctum/src/domain/models/streak_summary.dart';
import 'package:sanctum/src/domain/models/transit.dart';
import 'package:sanctum/src/domain/services/daily_attunement_selector.dart';
import 'package:sanctum/src/domain/services/energy_pattern.dart';
import 'package:sanctum/src/domain/services/moon_phase_calculator.dart';
import 'package:sanctum/src/domain/services/transit_composer.dart';

part 'today_view_model.g.dart';

/// Everything the Today screen renders.
///
/// One immutable object rather than six separately-watched providers, so
/// the screen cannot render a half-updated frame — for example yesterday's
/// card beside today's moon.
class TodayUiState {
  /// Creates the state.
  const TodayUiState({
    required this.date,
    required this.moon,
    required this.card,
    required this.cardRevealed,
    required this.affirmation,
    required this.streak,
    required this.energy,
    required this.pattern,
    required this.cardDrawCount,
    this.transit,
  });

  /// The local date this state describes.
  final DateTime date;

  /// Tonight's moon.
  final MoonReading moon;

  /// The card assigned to today.
  final OracleCard card;

  /// Whether the user has flipped it.
  final bool cardRevealed;

  /// Today's affirmation.
  final String affirmation;

  /// Current practice streak.
  final StreakSummary streak;

  /// Today's energy check-in, if recorded.
  final EnergyCheckIn? energy;

  /// What the sky is doing to this user today.
  ///
  /// `null` only when we have no birth date — everyone who finished
  /// onboarding has one, but the screen must not assume it.
  final DailyTransitReading? transit;

  /// What their own check-ins add up to.
  final EnergyPattern pattern;

  /// How many times today's card has come up before, this window.
  final int cardDrawCount;

  /// Whether today's check-in is still outstanding.
  bool get needsCheckIn => energy == null;

  /// Whether today's card is one they have drawn before.
  ///
  /// A repeat is the only thing that gives a daily draw any continuity —
  /// otherwise every day is independent and there is no thread to pull.
  bool get cardIsRepeat => cardDrawCount > 1;
}

/// The live draw state for [day].
@riverpod
Stream<OracleDrawState?> oracleDraw(Ref ref, DateTime day) =>
    ref.watch(oracleRepositoryProvider).watchDraw(day);

/// The live streak as of [day].
@riverpod
Stream<StreakSummary> streak(Ref ref, DateTime day) =>
    ref.watch(practiceRepositoryProvider).watchStreak(day);

/// The live energy check-in for [day].
@riverpod
Stream<EnergyCheckIn?> energyFor(Ref ref, DateTime day) =>
    ref.watch(energyRepositoryProvider).watchFor(day);

/// The user's recent check-ins.
@riverpod
Stream<List<EnergyCheckIn>> recentEnergy(Ref ref) =>
    ref.watch(energyRepositoryProvider).watchRecent();

/// Every card the user has ever turned over.
@riverpod
Stream<List<String>> revealedCards(Ref ref) =>
    ref.watch(oracleRepositoryProvider).watchRevealedHistory();

/// Composes the Today screen's state.
@riverpod
Future<TodayUiState> todayState(Ref ref) async {
  final today = ref.watch(clockProvider).today();

  final catalog = await ref.watch(contentCatalogProvider.future);
  final salt = await ref.watch(installSaltProvider.future);

  // Two different salts so the card and the affirmation are chosen
  // independently. Sharing one would lock them into lockstep — the same
  // pairing every cycle, which users notice faster than you would think.
  final card = DailyAttunementSelector.select(
    catalogue: catalog.oracleCards,
    date: today,
    salt: '$salt:oracle',
  );
  final affirmation = DailyAttunementSelector.select(
    catalogue: catalog.affirmations,
    date: today,
    salt: '$salt:affirmation',
  );

  // Persist the assignment so the card cannot change if the catalogue
  // ever grows: selection is a pure function of the catalogue *length*,
  // so shipping new cards would otherwise reshuffle today mid-day.
  await ref
      .watch(oracleRepositoryProvider)
      .ensureAssigned(day: today, cardId: card.id);

  final draw = await ref.watch(oracleDrawProvider(today).future);
  final streakSummary = await ref.watch(streakProvider(today).future);
  final energy = await ref.watch(energyForProvider(today).future);
  final history = await ref.watch(recentEnergyProvider.future);
  final drawn = await ref.watch(revealedCardsProvider.future);

  final storedCard = draw == null
      ? card
      : catalog.cardById(draw.cardId) ?? card;

  // The birth date onboarding already collected. Reading it here rather
  // than asking again is the difference between an app that remembers
  // and a form.
  final answers = (await ref.watch(quizRepositoryProvider).load())
      .getOrElse(const QuizAnswers());
  final birthDate = answers.dates['birth_date'];

  return TodayUiState(
    date: today,
    moon: MoonPhaseCalculator.readingFor(today),
    card: storedCard,
    cardRevealed: draw?.revealed ?? false,
    affirmation: affirmation,
    streak: streakSummary,
    energy: energy,
    transit: birthDate == null
        ? null
        : TransitComposer.compose(
            birthDate: birthDate,
            day: today,
            copy: catalog.copy,
          ),
    pattern: EnergyPatternCalculator.analyse(
      checkIns: history,
      today: today,
      copy: catalog.copy,
    ),
    cardDrawCount: drawn.where((id) => id == storedCard.id).length,
  );
}

/// Actions the Today screen can take.
///
/// The command pattern: each method moves this notifier through
/// loading → data/error, so the UI can disable a control while its write
/// is in flight and surface a failure without the screen itself ever
/// touching a repository or writing a `try`.
@riverpod
class TodayController extends _$TodayController {
  @override
  FutureOr<void> build() {}

  /// Flips today's card.
  Future<void> revealCard() async {
    ref.read(analyticsProvider).track(const AnalyticsEvent.cardRevealed());
    final today = ref.read(clockProvider).today();
    await _run(() => ref.read(oracleRepositoryProvider).reveal(today));
  }

  /// Records today's energy check-in.
  Future<void> recordEnergy(EnergyLevel level) async {
    ref
        .read(analyticsProvider)
        .track(AnalyticsEvent.energyCheckedIn(level: level.name));
    final today = ref.read(clockProvider).today();
    await _run(
      () => ref.read(energyRepositoryProvider).record(level: level, day: today),
    );
  }

  Future<void> _run(Future<Result<void>> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}
