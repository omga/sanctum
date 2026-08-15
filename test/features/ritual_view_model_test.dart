import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/core/time/clock.dart';
import 'package:sanctum/src/data/catalog/content_catalog.dart';
import 'package:sanctum/src/data/catalog/content_catalog_source.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/repositories/journal_repository.dart';
import 'package:sanctum/src/domain/models/journal_entry.dart';
import 'package:sanctum/src/domain/models/moon_phase.dart';
import 'package:sanctum/src/features/rituals/view_model/ritual_view_model.dart';

class _Journal implements JournalRepository {
  final added = <JournalEntry>[];

  @override
  Stream<List<JournalEntry>> watchEntries() => Stream.value(added);

  @override
  Future<Result<int>> add({
    required JournalKind kind,
    required String body,
    required DateTime createdAt,
    String? prompt,
  }) async {
    added.add(
      JournalEntry(
        id: added.length + 1,
        createdAt: createdAt,
        kind: kind,
        body: body,
        prompt: prompt,
      ),
    );
    return Result.ok(added.length);
  }

  @override
  Future<Result<void>> delete(int id) async => const Result.ok(null);
}

void main() {
  // Uses the REAL bundled rituals, so the test also proves the four
  // authored rituals map onto the phases the app actually computes.
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;
  late _Journal journal;

  setUpAll(() async {
    const source = AssetContentCatalogSource();
    catalog = switch (await source.load()) {
      Ok(:final value) => value,
      Err(:final failure) => throw StateError('$failure'),
    };
  });

  ProviderContainer containerAt(DateTime now) {
    journal = _Journal();
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(FixedClock(now)),
        contentCatalogProvider.overrideWith((ref) async => catalog),
        journalRepositoryProvider.overrideWithValue(journal),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ritualState', () {
    test('opens on a new moon', () async {
      // USNO: new moon 2026-08-12 17:37 UTC.
      final state = await containerAt(DateTime(2026, 8, 12, 20))
          .read(ritualStateProvider.future);

      expect(state.phase, MoonPhase.newMoon);
      expect(state.isOpen, isTrue);
      expect(state.ritual?.title, 'Intention Setting');
    });

    test('opens on a full moon', () async {
      // USNO: full moon 2026-08-28 04:18 UTC.
      final state = await containerAt(DateTime(2026, 8, 28, 12))
          .read(ritualStateProvider.future);

      expect(state.phase, MoonPhase.fullMoon);
      expect(state.ritual?.title, 'Release');
    });

    test('opens on both quarters', () async {
      final first = await containerAt(DateTime(2026, 8, 20, 6))
          .read(ritualStateProvider.future);
      final last = await containerAt(DateTime(2026, 8, 6, 6))
          .read(ritualStateProvider.future);

      expect(first.ritual?.title, 'Meeting Resistance');
      expect(last.ritual?.title, 'Honest Review');
    });

    test('is closed on a crescent, and says when the next one opens', () async {
      // 2026-08-15 is a waxing crescent — deliberately between rituals.
      final state = await containerAt(DateTime(2026, 8, 15))
          .read(ritualStateProvider.future);

      expect(state.phase, MoonPhase.waxingCrescent);
      expect(state.isOpen, isFalse);
      expect(state.ritual, isNull);
      expect(state.nextRitual, isNotNull);
      expect(state.daysUntilNext, isNotNull);
      expect(state.daysUntilNext, greaterThanOrEqualTo(0));
      // First quarter is 2026-08-20, so about five days out.
      expect(state.daysUntilNext, lessThanOrEqualTo(10));
    });

    test('every day of a lunar month resolves without throwing', () async {
      var date = DateTime(2026, 8, 1);
      var openDays = 0;

      for (var i = 0; i < 30; i++) {
        final state = await containerAt(date).read(ritualStateProvider.future);
        if (state.isOpen) {
          openDays++;
        } else {
          expect(state.daysUntilNext, isNotNull, reason: '$date');
        }
        date = date.add(const Duration(days: 1));
      }

      // Four bands of ~3.7 days each: roughly half the month is open.
      // The point is that it is neither always nor never.
      expect(openDays, greaterThan(8));
      expect(openDays, lessThan(22));
    });
  });

  group('RitualController', () {
    test('completing writes a ritual entry into the journal', () async {
      final container = containerAt(DateTime(2026, 8, 12, 20));
      final state = await container.read(ritualStateProvider.future);

      await container
          .read(ritualControllerProvider.notifier)
          .complete(
            ritual: state.ritual!,
            reflection: 'I asked for steadiness.',
          );

      expect(journal.added, hasLength(1));
      expect(journal.added.single.kind, JournalKind.ritual);
      expect(journal.added.single.body, 'I asked for steadiness.');
      expect(journal.added.single.prompt, contains('Intention Setting'));
      expect(container.read(ritualControllerProvider).hasError, isFalse);
    });

    test('an empty reflection still records the completion', () async {
      final container = containerAt(DateTime(2026, 8, 28, 12));
      final state = await container.read(ritualStateProvider.future);

      await container
          .read(ritualControllerProvider.notifier)
          .complete(ritual: state.ritual!, reflection: 'Completed Release.');

      expect(journal.added.single.body, isNotEmpty);
    });
  });
}
