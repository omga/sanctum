import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/core/time/clock.dart';
import 'package:sanctum/src/data/catalog/content_catalog.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/repositories/energy_repository.dart';
import 'package:sanctum/src/data/repositories/oracle_repository.dart';
import 'package:sanctum/src/data/repositories/practice_repository.dart';
import 'package:sanctum/src/domain/models/energy_check_in.dart';
import 'package:sanctum/src/domain/models/moon_phase.dart';
import 'package:sanctum/src/domain/models/oracle_card.dart';
import 'package:sanctum/src/domain/models/ritual.dart';
import 'package:sanctum/src/domain/models/sound_session.dart';
import 'package:sanctum/src/domain/models/streak_summary.dart';
import 'package:sanctum/src/features/today/view_model/today_view_model.dart';

/// Fakes, not mocks.
///
/// A mock asserts on calls; these just behave. For repositories with
/// four methods, a fake is shorter to write, reads like the real thing,
/// and does not break every time an unrelated call is added.
class FakeOracleRepository implements OracleRepository {
  OracleDrawState? draw;
  final assigned = <String>[];

  @override
  Stream<OracleDrawState?> watchDraw(DateTime day) => Stream.value(draw);

  @override
  Future<Result<void>> ensureAssigned({
    required DateTime day,
    required String cardId,
  }) async {
    assigned.add(cardId);
    draw ??= OracleDrawState(cardId: cardId, revealed: false);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> reveal(DateTime day) async {
    final current = draw;
    if (current != null) {
      draw = OracleDrawState(cardId: current.cardId, revealed: true);
    }
    return const Result.ok(null);
  }

  @override
  Stream<List<String>> watchRevealedHistory() => Stream.value(const []);
}

class FakePracticeRepository implements PracticeRepository {
  StreakSummary summary = StreakSummary.empty;

  @override
  Stream<StreakSummary> watchStreak(DateTime today) => Stream.value(summary);

  @override
  Future<Result<void>> recordCompletion({
    required String sessionId,
    required DateTime completedAt,
    required Duration listened,
  }) async => const Result.ok(null);

  @override
  Future<Result<int>> totalSessions() async => const Result.ok(0);
}

class FakeEnergyRepository implements EnergyRepository {
  EnergyCheckIn? today;

  @override
  Stream<EnergyCheckIn?> watchFor(DateTime day) => Stream.value(today);

  @override
  Stream<List<EnergyCheckIn>> watchRecent({int days = 30}) =>
      Stream.value(const []);

  @override
  Future<Result<void>> record({
    required EnergyLevel level,
    required DateTime day,
    String? note,
  }) async {
    today = EnergyCheckIn(id: 1, recordedAt: day, level: level);
    return const Result.ok(null);
  }
}

ContentCatalog _catalog() => ContentCatalog(
  oracleCards: [
    for (var i = 0; i < 22; i++)
      OracleCard(
        id: 'card-$i',
        name: 'Card $i',
        message: 'Message $i',
        guidance: 'Guidance $i',
      ),
  ],
  sessions: const <SoundSession>[],
  affirmations: [for (var i = 0; i < 22; i++) 'Affirmation $i'],
  rituals: const <Ritual>[],
  quizQuestions: const [],
);

void main() {
  late FakeOracleRepository oracle;
  late FakePracticeRepository practice;
  late FakeEnergyRepository energy;

  ProviderContainer makeContainer(DateTime now) {
    oracle = FakeOracleRepository();
    practice = FakePracticeRepository();
    energy = FakeEnergyRepository();

    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(FixedClock(now)),
        contentCatalogProvider.overrideWith((ref) async => _catalog()),
        installSaltProvider.overrideWith((ref) async => 'test-salt'),
        oracleRepositoryProvider.overrideWithValue(oracle),
        practiceRepositoryProvider.overrideWithValue(practice),
        energyRepositoryProvider.overrideWithValue(energy),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('todayState', () {
    test('composes moon, card, affirmation and streak', () async {
      final container = makeContainer(DateTime(2026, 1, 3, 10, 3));
      final state = await container.read(todayStateProvider.future);

      // 2026-01-03 is a full moon per USNO.
      expect(state.moon.phase, MoonPhase.fullMoon);
      expect(state.card.id, startsWith('card-'));
      expect(state.affirmation, startsWith('Affirmation'));
      expect(state.streak.current, 0);
      expect(state.cardRevealed, isFalse);
      expect(state.needsCheckIn, isTrue);
    });

    test('assigns the card exactly once', () async {
      final container = makeContainer(DateTime(2026, 8, 15));
      await container.read(todayStateProvider.future);

      expect(oracle.assigned, hasLength(1));
    });

    test('card and affirmation are chosen independently', () async {
      // Same day, same salt: if both used one salt they would pick the
      // same index and stay locked together forever.
      final container = makeContainer(DateTime(2026, 8, 15));
      final state = await container.read(todayStateProvider.future);

      final cardIndex = int.parse(state.card.id.split('-').last);
      final affirmationIndex = int.parse(state.affirmation.split(' ').last);

      expect(cardIndex, isNot(affirmationIndex));
    });

    test('the same date always yields the same card', () async {
      final a = await makeContainer(DateTime(2026, 8, 15, 6))
          .read(todayStateProvider.future);
      final b = await makeContainer(DateTime(2026, 8, 15, 23))
          .read(todayStateProvider.future);

      expect(a.card.id, b.card.id);
    });

    test('a different date yields a different card', () async {
      final a = await makeContainer(DateTime(2026, 8, 15))
          .read(todayStateProvider.future);
      final b = await makeContainer(DateTime(2026, 8, 16))
          .read(todayStateProvider.future);

      expect(a.card.id, isNot(b.card.id));
    });

    test('reflects an existing revealed draw', () async {
      final container = makeContainer(DateTime(2026, 8, 15));
      oracle.draw = const OracleDrawState(cardId: 'card-3', revealed: true);

      final state = await container.read(todayStateProvider.future);

      expect(state.cardRevealed, isTrue);
      expect(state.card.id, 'card-3');
    });

    test('surfaces a recorded check-in', () async {
      final container = makeContainer(DateTime(2026, 8, 15));
      energy.today = EnergyCheckIn(
        id: 1,
        recordedAt: DateTime(2026, 8, 15),
        level: EnergyLevel.radiant,
      );

      final state = await container.read(todayStateProvider.future);

      expect(state.needsCheckIn, isFalse);
      expect(state.energy?.level, EnergyLevel.radiant);
    });

    test('surfaces an at-risk streak', () async {
      final container = makeContainer(DateTime(2026, 8, 15));
      practice.summary = const StreakSummary(
        current: 4,
        longest: 9,
        completedToday: false,
      );

      final state = await container.read(todayStateProvider.future);

      expect(state.streak.current, 4);
      expect(state.streak.isAtRisk, isTrue);
    });
  });

  group('TodayController', () {
    test('revealCard flips the stored draw', () async {
      final container = makeContainer(DateTime(2026, 8, 15));
      await container.read(todayStateProvider.future);

      await container.read(todayControllerProvider.notifier).revealCard();

      expect(oracle.draw?.revealed, isTrue);
      expect(container.read(todayControllerProvider).hasError, isFalse);
    });

    test('recordEnergy stores the level', () async {
      final container = makeContainer(DateTime(2026, 8, 15));
      await container.read(todayStateProvider.future);

      await container
          .read(todayControllerProvider.notifier)
          .recordEnergy(EnergyLevel.open);

      expect(energy.today?.level, EnergyLevel.open);
    });
  });
}
