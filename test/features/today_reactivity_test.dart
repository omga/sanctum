import 'dart:async';

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
import 'package:sanctum/src/domain/models/oracle_card.dart';
import 'package:sanctum/src/domain/models/ritual.dart';
import 'package:sanctum/src/domain/models/sound_session.dart';
import 'package:sanctum/src/domain/models/streak_summary.dart';
import 'package:sanctum/src/features/today/view_model/today_view_model.dart';

/// A fake that behaves like Drift does: one long-lived stream that emits
/// again whenever the underlying data changes.
///
/// The earlier fake returned `Stream.value(...)` — a brand new, already
/// complete stream on every watch. That makes any re-read look correct
/// and cannot express "the value changed while someone was listening",
/// which is exactly the behaviour the UI depends on.
class StreamingOracleRepository implements OracleRepository {
  final _controller = StreamController<OracleDrawState?>.broadcast();
  OracleDrawState? _current;

  @override
  Stream<OracleDrawState?> watchDraw(DateTime day) async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<Result<void>> ensureAssigned({
    required DateTime day,
    required String cardId,
  }) async {
    _current ??= OracleDrawState(cardId: cardId, revealed: false);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> reveal(DateTime day) async {
    final current = _current;
    if (current != null) {
      _current = OracleDrawState(cardId: current.cardId, revealed: true);
      _controller.add(_current);
    }
    return const Result.ok(null);
  }

  @override
  Stream<List<String>> watchRevealedHistory() => const Stream.empty();

  void dispose() => _controller.close();
}

class _Practice implements PracticeRepository {
  @override
  Stream<StreakSummary> watchStreak(DateTime today) =>
      Stream.value(StreakSummary.empty);
  @override
  Future<Result<void>> recordCompletion({
    required String sessionId,
    required DateTime completedAt,
    required Duration listened,
  }) async => const Result.ok(null);
  @override
  Future<Result<int>> totalSessions() async => const Result.ok(0);
}

class _Energy implements EnergyRepository {
  @override
  Stream<EnergyCheckIn?> watchFor(DateTime day) => Stream.value(null);
  @override
  Stream<List<EnergyCheckIn>> watchRecent({int days = 30}) =>
      Stream.value(const []);
  @override
  Future<Result<void>> record({
    required EnergyLevel level,
    required DateTime day,
    String? note,
  }) async => const Result.ok(null);
}

void main() {
  test('todayState reflects a reveal that arrives on the stream', () async {
    final oracle = StreamingOracleRepository();
    addTearDown(oracle.dispose);

    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(FixedClock(DateTime(2026, 8, 15))),
        contentCatalogProvider.overrideWith(
          (ref) async => ContentCatalog(
            oracleCards: [
              for (var i = 0; i < 22; i++)
                OracleCard(
                  id: 'card-$i',
                  name: 'Card $i',
                  message: 'm',
                  guidance: 'g',
                ),
            ],
            sessions: const <SoundSession>[],
            affirmations: [for (var i = 0; i < 22; i++) 'a$i'],
            rituals: const <Ritual>[],
            quizQuestions: const [],
          ),
        ),
        installSaltProvider.overrideWith((ref) async => 'salt'),
        oracleRepositoryProvider.overrideWithValue(oracle),
        practiceRepositoryProvider.overrideWithValue(_Practice()),
        energyRepositoryProvider.overrideWithValue(_Energy()),
      ],
    );
    addTearDown(container.dispose);

    // Keep the provider alive the way a mounted widget would.
    final sub = container.listen(todayStateProvider, (_, _) {});
    addTearDown(sub.close);

    final initial = await container.read(todayStateProvider.future);
    expect(initial.cardRevealed, isFalse);

    await container.read(todayControllerProvider.notifier).revealCard();
    // Let the stream event propagate.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final after = await container.read(todayStateProvider.future);
    expect(
      after.cardRevealed,
      isTrue,
      reason:
          'the UI never sees the reveal if todayState does not rebuild '
          'when the draw stream emits',
    );
  });
}
