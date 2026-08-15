import 'package:flutter/material.dart';
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
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/domain/models/energy_check_in.dart';
import 'package:sanctum/src/domain/models/oracle_card.dart';
import 'package:sanctum/src/domain/models/ritual.dart';
import 'package:sanctum/src/domain/models/sound_session.dart';
import 'package:sanctum/src/domain/models/streak_summary.dart';
import 'package:sanctum/src/features/today/view/today_screen.dart';

class _Oracle implements OracleRepository {
  OracleDrawState? current;
  int revealCalls = 0;

  @override
  Stream<OracleDrawState?> watchDraw(DateTime day) => Stream.value(current);

  @override
  Future<Result<void>> ensureAssigned({
    required DateTime day,
    required String cardId,
  }) async {
    current ??= OracleDrawState(cardId: cardId, revealed: false);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> reveal(DateTime day) async {
    revealCalls++;
    final c = current;
    if (c != null) {
      current = OracleDrawState(cardId: c.cardId, revealed: true);
    }
    return const Result.ok(null);
  }

  @override
  Stream<List<String>> watchRevealedHistory() => const Stream.empty();
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
  EnergyLevel? recorded;
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
  }) async {
    recorded = level;
    return const Result.ok(null);
  }
}

void main() {
  late _Oracle oracle;
  late _Energy energy;

  Future<void> pumpToday(WidgetTester tester) async {
    oracle = _Oracle();
    energy = _Energy();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(FixedClock(DateTime(2026, 8, 15))),
          contentCatalogProvider.overrideWith(
            (ref) async => ContentCatalog(
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
            ),
          ),
          installSaltProvider.overrideWith((ref) async => 'salt'),
          oracleRepositoryProvider.overrideWithValue(oracle),
          practiceRepositoryProvider.overrideWithValue(_Practice()),
          energyRepositoryProvider.overrideWithValue(energy),
        ],
        child: MaterialApp(
          theme: SanctumTheme.nocturne(),
          home: const Scaffold(body: TodayScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the day', (tester) async {
    await pumpToday(tester);

    expect(find.text('WAXING CRESCENT'), findsOneWidget);
    expect(find.text('YOUR CARD FOR TODAY'), findsOneWidget);
    expect(find.text('How is your energy?'), findsOneWidget);
  });

  testWidgets('tapping the face-down card reveals it', (tester) async {
    await pumpToday(tester);

    await tester.tap(find.text('Tap to turn it over'));
    await tester.pumpAndSettle();

    expect(
      oracle.revealCalls,
      1,
      reason:
          'the tap must reach the controller and the controller must '
          'survive long enough to complete its async write',
    );
  });

  testWidgets('tapping an energy level records it', (tester) async {
    await pumpToday(tester);

    await tester.tap(find.text('Radiant'));
    await tester.pumpAndSettle();

    expect(energy.recorded, EnergyLevel.radiant);
  });
}
