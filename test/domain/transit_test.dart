import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/models/planet.dart';
import 'package:sanctum/src/domain/models/transit.dart';
import 'package:sanctum/src/domain/services/ephemeris.dart';
import 'package:sanctum/src/domain/services/transit_calculator.dart';
import 'package:sanctum/src/domain/services/transit_composer.dart';
import '../support/copy.dart';

final _birth = DateTime(1996, 6, 15);

final CopyBook _copy = loadEnglishCopy();

void main() {
  group('retrograde', () {
    test('the Sun never is', () {
      for (var day = 0; day < 400; day += 11) {
        final date = DateTime(2024).add(Duration(days: day));
        expect(Ephemeris.isRetrograde(Planet.sun, date), isFalse);
      }
    });

    test('Mercury is, about three times a year', () {
      // Mercury turns retrograde 3–4 times a year for roughly three
      // weeks. Far outside that band and the sign convention is wrong.
      var days = 0;
      for (var day = 0; day < 365; day++) {
        final date = DateTime(2024).add(Duration(days: day));
        if (Ephemeris.isRetrograde(Planet.mercury, date)) days++;
      }
      expect(days, inInclusiveRange(50, 80));
    });

    test('Saturn is, for about four and a half months a year', () {
      var days = 0;
      for (var day = 0; day < 365; day++) {
        final date = DateTime(2024).add(Duration(days: day));
        if (Ephemeris.isRetrograde(Planet.saturn, date)) days++;
      }
      expect(days, inInclusiveRange(120, 160));
    });

    test('catches the well-known August 2024 Mercury retrograde', () {
      // Mercury was retrograde from 5 August to 28 August 2024.
      expect(
        Ephemeris.isRetrograde(Planet.mercury, DateTime(2024, 8, 15)),
        isTrue,
      );
      expect(
        Ephemeris.isRetrograde(Planet.mercury, DateTime(2024, 9, 15)),
        isFalse,
      );
    });
  });

  group('transits', () {
    test('are ordered strongest first', () {
      final hits = TransitCalculator.forDay(
        birthDate: _birth,
        day: DateTime(2026, 8, 16),
      );
      for (var i = 1; i < hits.length; i++) {
        expect(
          hits[i - 1].significance,
          greaterThanOrEqualTo(hits[i].significance),
        );
      }
    });

    test('never report a body aspecting its own natal position', () {
      for (var day = 0; day < 200; day += 3) {
        final hits = TransitCalculator.forDay(
          birthDate: _birth,
          day: DateTime(2026).add(Duration(days: day)),
        );
        for (final hit in hits) {
          expect(hit.transiting, isNot(hit.natal));
        }
      }
    });

    test('stay inside the orb of the transiting body', () {
      for (var day = 0; day < 200; day += 3) {
        final hits = TransitCalculator.forDay(
          birthDate: _birth,
          day: DateTime(2026).add(Duration(days: day)),
        );
        for (final hit in hits) {
          expect(hit.orb, lessThanOrEqualTo(hit.transiting.orb));
          expect(hit.tightness, inInclusiveRange(0, 1));
        }
      }
    });

    test('only use natal points a birth date can actually pin', () {
      // The Moon moves 13° a day. If it ever appears here, somebody has
      // started guessing.
      for (var day = 0; day < 120; day += 7) {
        for (final hit in TransitCalculator.forDay(
          birthDate: _birth,
          day: DateTime(2026).add(Duration(days: day)),
        )) {
          expect(Planet.natal, contains(hit.natal));
        }
      }
    });

    test('the headline changes over a month', () {
      // The entire point. If the daily reading is the same all month,
      // there is no more reason to open the app than there was before.
      final seen = <String>{};
      for (var day = 0; day < 30; day++) {
        final hit = TransitCalculator.headline(
          birthDate: _birth,
          day: DateTime(2026, 3).add(Duration(days: day)),
        );
        if (hit != null) seen.add(hit.headlineIn(_copy));
      }
      expect(seen.length, greaterThan(3));
    });

    test('two people born a week apart get different days', () {
      final a = TransitCalculator.headline(
        birthDate: DateTime(1996, 6, 15),
        day: DateTime(2026, 5, 4),
      );
      final b = TransitCalculator.headline(
        birthDate: DateTime(1996, 6, 22),
        day: DateTime(2026, 5, 4),
      );
      expect(a?.headlineIn(_copy), isNot(b?.headlineIn(_copy)));
    });

    test('most days have something to say', () {
      var quiet = 0;
      for (var day = 0; day < 365; day++) {
        final hit = TransitCalculator.headline(
          birthDate: _birth,
          day: DateTime(2026).add(Duration(days: day)),
        );
        if (hit == null) quiet++;
      }
      // Some quiet days are honest; a majority of them means the orbs
      // are too tight for a daily product.
      expect(quiet, lessThan(120));
    });
  });

  group('composition', () {
    test('every transit a user can get has copy written for it', () {
      // The failure this catches: a pair with no line falls back to the
      // quiet-day text on a day that is not quiet.
      for (final transiting in Planet.values) {
        for (final natal in Planet.natal) {
          if (transiting == natal) continue;
          expect(
            _copy.maybe('transit.pair.${transiting.name}.${natal.name}'),
            isNotNull,
            reason: 'no copy for $transiting to natal $natal',
          );
        }
      }
    });

    test('every aspect has an opener and every body a retrograde note', () {
      for (final aspect in TransitAspect.values) {
        expect(_copy.has('transit.opener.${aspect.name}'), isTrue);
      }
      for (final planet in Planet.values) {
        if (!planet.canRetrograde) continue;
        expect(_copy.has('transit.retrograde.${planet.name}'), isTrue);
      }
    });

    test('never composes an empty reading across a whole year', () {
      for (var day = 0; day < 365; day += 2) {
        final reading = TransitComposer.compose(
          birthDate: _birth,
          day: DateTime(2026).add(Duration(days: day)),
          copy: _copy,
        );
        expect(reading.line, isNotEmpty);
        expect(reading.line.length, greaterThan(40));
      }
    });

    test('is deterministic', () {
      final day = DateTime(2026, 8, 16);
      expect(
        TransitComposer.compose(birthDate: _birth, day: day, copy: _copy).line,
        TransitComposer.compose(birthDate: _birth, day: day, copy: _copy).line,
      );
    });

    test('teases tomorrow only when tomorrow is different', () {
      var teased = 0;
      var same = 0;
      for (var day = 0; day < 90; day++) {
        final date = DateTime(2026, 4).add(Duration(days: day));
        final reading = TransitComposer.compose(
          birthDate: _birth,
          day: date,
          copy: _copy,
        );
        if (reading.tomorrow == null) {
          same++;
        } else {
          teased++;
        }
      }
      // Both cases must occur, or the tease is either constant noise or
      // never fires.
      expect(teased, greaterThan(0));
      expect(same, greaterThan(0));
    });

    test('marks a retrograde transit as a rerun', () {
      // Find a day whose headline body is retrograde, and check the copy
      // says so rather than presenting it as new.
      for (var day = 0; day < 365; day++) {
        final date = DateTime(2026).add(Duration(days: day));
        final reading = TransitComposer.compose(
          birthDate: _birth,
          day: date,
          copy: _copy,
        );
        if (reading.transit?.retrograde ?? false) {
          expect(reading.line, contains('rerun'));
          return;
        }
      }
      fail('no retrograde headline in a year');
    });
  });
}
