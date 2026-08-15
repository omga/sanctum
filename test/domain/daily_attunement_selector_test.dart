import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/time/clock.dart';
import 'package:sanctum/src/domain/services/daily_attunement_selector.dart';

void main() {
  const salt = 'install-abc123';
  final catalogue = List<String>.generate(24, (i) => 'card-$i');

  /// The first date on or after [from] that begins a cycle.
  ///
  /// The per-cycle no-repeat guarantee is defined on aligned cycles, so a
  /// test asserting it must align — otherwise it is really asserting the
  /// sliding-window property, which is a different (stronger) claim and
  /// has its own test below.
  DateTime alignedCycleStart(DateTime from) {
    var date = from;
    while (DailyAttunementSelector.dayNumber(date) % catalogue.length != 0) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  String pick(DateTime date, {String withSalt = salt}) =>
      DailyAttunementSelector.select(
        catalogue: catalogue,
        date: date,
        salt: withSalt,
      );

  group('DailyAttunementSelector', () {
    test('returns the same card all day regardless of time', () {
      final morning = DateTime(2026, 8, 15, 6, 30);
      final night = DateTime(2026, 8, 15, 23, 59, 59);

      expect(pick(morning), pick(night));
    });

    test('changes at local midnight', () {
      expect(
        pick(DateTime(2026, 8, 15, 23, 59)),
        isNot(pick(DateTime(2026, 8, 16, 0, 1))),
      );
    });

    test('is stable across repeated calls (no hidden randomness)', () {
      final date = DateTime(2026, 8, 15);
      final picks = List.generate(50, (_) => pick(date));

      expect(picks.toSet(), hasLength(1));
    });

    test('two installs see different cards on the same day', () {
      final date = DateTime(2026, 8, 15);
      final a = pick(date, withSalt: 'install-a');
      final b = pick(date, withSalt: 'install-b');
      final c = pick(date, withSalt: 'install-c');

      // Not a strict guarantee for any single pair, but three identical
      // picks would mean the salt is not reaching the seed at all.
      expect({a, b, c}.length, greaterThan(1));
    });

    test('shows every card exactly once per aligned cycle', () {
      final start = alignedCycleStart(DateTime(2026, 1, 1));
      final seen = [
        for (var i = 0; i < catalogue.length; i++)
          pick(start.add(Duration(days: i))),
      ];

      expect(
        seen.toSet(),
        hasLength(catalogue.length),
        reason: 'every card should appear exactly once per cycle',
      );
    });

    test('reshuffles into a new order on the next cycle', () {
      final start = alignedCycleStart(DateTime(2026, 1, 1));
      final cycleOne = [
        for (var i = 0; i < catalogue.length; i++)
          pick(start.add(Duration(days: i))),
      ];
      final cycleTwo = [
        for (var i = 0; i < catalogue.length; i++)
          pick(start.add(Duration(days: catalogue.length + i))),
      ];

      expect(cycleTwo.toSet(), hasLength(catalogue.length));
      expect(cycleTwo, isNot(orderedEquals(cycleOne)));
    });

    test('no card repeats within the guard window, across seams', () {
      // The guarantee users actually experience is a *sliding* window,
      // not an aligned one. Cycle boundaries join the tail of one
      // shuffle to the head of the next, so this is the test that would
      // catch an unrepaired seam.
      final guard = DailyAttunementSelector.guardDays(catalogue.length);
      expect(guard, 7, reason: '24 cards should buy a full week');

      final window = <String>[];
      var date = DateTime(2025, 1, 1);
      final end = DateTime(2028, 1, 1);

      while (date.isBefore(end)) {
        final card = pick(date);
        expect(
          window,
          isNot(contains(card)),
          reason: '$card repeated within $guard days at $date',
        );
        window.add(card);
        if (window.length > guard) window.removeAt(0);
        date = date.add(const Duration(days: 1));
      }
    });

    test('guardDays never exceeds a third of a small catalogue', () {
      expect(DailyAttunementSelector.guardDays(3), 0);
      expect(DailyAttunementSelector.guardDays(7), 2);
      expect(DailyAttunementSelector.guardDays(24), 7);
      expect(DailyAttunementSelector.guardDays(100), 7);
    });

    test('small catalogues still produce valid indices', () {
      for (final size in [2, 3, 4, 5, 7]) {
        var date = DateTime(2026, 1, 1);
        for (var i = 0; i < 60; i++) {
          final index = DailyAttunementSelector.indexFor(
            catalogueLength: size,
            date: date,
            salt: salt,
          );
          expect(
            index,
            inInclusiveRange(0, size - 1),
            reason: 'size $size at $date',
          );
          date = date.add(const Duration(days: 1));
        }
      }
    });

    test('handles a single-entry catalogue', () {
      expect(
        DailyAttunementSelector.select(
          catalogue: ['only'],
          date: DateTime(2026, 8, 15),
          salt: salt,
        ),
        'only',
      );
    });

    test('handles dates before the epoch without crashing', () {
      final old = DateTime(2019, 6, 1);

      expect(DailyAttunementSelector.dayNumber(old), isNegative);
      expect(catalogue, contains(pick(old)));
    });

    test('every day of a long span produces a valid index', () {
      // Five years of days — guards the floor-division path around the
      // epoch and any accidental negative index.
      var date = DateTime(2018, 1, 1);
      final end = DateTime(2023, 1, 1);
      while (date.isBefore(end)) {
        final index = DailyAttunementSelector.indexFor(
          catalogueLength: catalogue.length,
          date: date,
          salt: salt,
        );
        expect(index, inInclusiveRange(0, catalogue.length - 1));
        date = date.add(const Duration(days: 1));
      }
    });

    test('is driven by the injected clock, not the wall clock', () {
      final clock = FixedClock(DateTime(2026, 8, 15, 10));
      final first = pick(clock.today());

      clock.advance(const Duration(days: 1));
      final second = pick(clock.today());

      expect(first, isNot(second));
    });
  });
}
