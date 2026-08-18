import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/domain/services/compatibility_calculator.dart';
import 'package:sanctum/src/domain/services/compatibility_composer.dart';

final _now = DateTime(2026, 8, 16);

MatchPerson _person(String name, DateTime birth) =>
    MatchPerson(name: name, birthDate: birth);

/// A date squarely inside each sign, for exhaustive pair coverage.
DateTime _dateIn(ZodiacSign sign) => switch (sign) {
  ZodiacSign.aries => DateTime(1996, 4, 5),
  ZodiacSign.taurus => DateTime(1996, 5, 5),
  ZodiacSign.gemini => DateTime(1996, 6, 5),
  ZodiacSign.cancer => DateTime(1996, 7, 5),
  ZodiacSign.leo => DateTime(1996, 8, 5),
  ZodiacSign.virgo => DateTime(1996, 9, 5),
  ZodiacSign.libra => DateTime(1996, 10, 5),
  ZodiacSign.scorpio => DateTime(1996, 11, 5),
  ZodiacSign.sagittarius => DateTime(1996, 12, 5),
  ZodiacSign.capricorn => DateTime(1996, 1, 5),
  ZodiacSign.aquarius => DateTime(1996, 2, 5),
  ZodiacSign.pisces => DateTime(1996, 3, 5),
};

CompatibilityMatch _compose(DateTime a, DateTime b) =>
    CompatibilityComposer.compose(
      you: _person('You', a),
      them: _person('Them', b),
      now: _now,
    );

void main() {
  group('match identity', () {
    test('is the pair, not just the second person', () {
      // The id was `them.key` while the user was always the first side.
      // Once any two people can be compared that collides: "Taylor and
      // Doja" and "you and Doja" would be the same saved reading, and
      // unlocking one would unlock the other.
      final youAndB = _compose(
        _dateIn(ZodiacSign.aries),
        _dateIn(ZodiacSign.leo),
      );
      final aAndB = CompatibilityComposer.compose(
        you: _person('Someone Else', _dateIn(ZodiacSign.virgo)),
        them: _person('Them', _dateIn(ZodiacSign.leo)),
        now: _now,
      );

      expect(youAndB.id, isNot(aAndB.id));
      expect(youAndB.id, contains(youAndB.you.key));
      expect(youAndB.id, contains(youAndB.them.key));
    });

    test('is directional, because the reading is', () {
      // Who wants it more is not a symmetric question, so A-then-B and
      // B-then-A are different readings and must not share storage.
      final a = _person('A', _dateIn(ZodiacSign.aries));
      final b = _person('B', _dateIn(ZodiacSign.libra));

      final forward =
          CompatibilityComposer.compose(you: a, them: b, now: _now);
      final backward =
          CompatibilityComposer.compose(you: b, them: a, now: _now);

      expect(forward.id, isNot(backward.id));
    });
  });

  group('coverage', () {
    test('every aspect has a dynamic line and a share line', () {
      for (final aspect in ZodiacAspect.values) {
        expect(
          CompatibilityComposer.dynamics[aspect],
          isNotNull,
          reason: 'no copy for $aspect',
        );
        expect(CompatibilityComposer.shareLines[aspect], isNotNull);
      }
    });

    test('every facet has works, watch and punchline copy', () {
      for (final facet in CompatibilityFacet.values) {
        expect(CompatibilityComposer.works[facet], isNotNull, reason: '$facet');
        expect(
          CompatibilityComposer.watches[facet],
          isNotNull,
          reason: '$facet',
        );
        expect(
          CompatibilityComposer.punchlines[facet],
          isNotNull,
          reason: '$facet',
        );
      }
    });

    test('both directional readings have copy for all three leans', () {
      for (final lines in [
        CompatibilityComposer.pullLines,
        CompatibilityComposer.powerLines,
      ]) {
        expect(lines, hasLength(3));
        for (final line in lines.values) {
          expect(line, isNotEmpty);
        }
      }
    });

    test('every pair of signs composes a complete reading', () {
      // Every one of the 144 orderings, composed for real from dates
      // that actually land in each sign. This is the test that catches a
      // new element key, a reordered enum or a copy map with a hole in
      // it — none of which are visible until some specific user picks
      // some specific date.
      for (final a in ZodiacSign.values) {
        for (final b in ZodiacSign.values) {
          final match = CompatibilityComposer.compose(
            you: _person('A', _dateIn(a)),
            them: _person('B', _dateIn(b)),
            now: _now,
          );

          expect(match.you.sign, a, reason: 'sample date drifted');
          expect(match.them.sign, b, reason: 'sample date drifted');
          expect(match.dynamicLine, isNotEmpty, reason: '$a + $b');
          expect(match.elementLine, isNotEmpty, reason: '$a + $b');
          expect(match.worksLine, isNotEmpty, reason: '$a + $b');
          expect(match.watchLine, isNotEmpty, reason: '$a + $b');
          expect(match.shareLine, isNotEmpty, reason: '$a + $b');
          expect(match.verdict, isNotEmpty, reason: '$a + $b');
          expect(match.facets, hasLength(6), reason: '$a + $b');
          expect(match.pull.line, isNotEmpty, reason: '$a + $b');
          expect(match.power.line, isNotEmpty, reason: '$a + $b');
          expect(
            match.pull.yourShare + match.pull.theirShare,
            100,
            reason: '$a + $b',
          );
        }
      }
    });

    test('element keys are unordered', () {
      expect(
        CompatibilityComposer.elementKey(ZodiacSign.aries, ZodiacSign.cancer),
        CompatibilityComposer.elementKey(ZodiacSign.cancer, ZodiacSign.aries),
      );
    });

    test('there is copy for all ten element pairs and no more', () {
      final keys = <String>{};
      for (final a in ZodiacSign.values) {
        for (final b in ZodiacSign.values) {
          keys.add(CompatibilityComposer.elementKey(a, b));
        }
      }
      expect(keys, hasLength(10));
      expect(CompatibilityComposer.elements.keys.toSet(), keys);
    });
  });

  group('composition', () {
    test('the same two dates always compose the same reading', () {
      final a = _compose(DateTime(1996, 6, 15), DateTime(1990, 11, 2));
      final b = _compose(DateTime(1996, 6, 15), DateTime(1990, 11, 2));

      expect(a.overall, b.overall);
      expect(a.dynamicLine, b.dynamicLine);
      expect(a.elementLine, b.elementLine);
      expect(a.shareLine, b.shareLine);
    });

    test('the closing lines are keyed to this pair, not to the aspect', () {
      final match = _compose(DateTime(1996, 6, 15), DateTime(1990, 11, 2));

      expect(
        match.worksLine,
        CompatibilityComposer.works[match.strongest.facet],
      );
      expect(
        match.watchLine,
        CompatibilityComposer.watches[match.weakest.facet],
      );
    });

    test('the verdict matches the score band', () {
      final match = _compose(DateTime(1996, 6, 15), DateTime(1990, 11, 2));
      expect(
        match.verdict,
        CompatibilityCalculator.verdictFor(match.overall),
      );
    });

    test('the pair reads the same from either side', () {
      final a = _compose(DateTime(1996, 6, 15), DateTime(1990, 11, 2));
      final b = _compose(DateTime(1990, 11, 2), DateTime(1996, 6, 15));

      expect(a.overall, b.overall);
      expect(a.aspect, b.aspect);
      expect(a.elementLine, b.elementLine);
    });

    test('but the lopsided readings swap over', () {
      final a = _compose(DateTime(1996, 6, 15), DateTime(1990, 11, 2));
      final b = _compose(DateTime(1990, 11, 2), DateTime(1996, 6, 15));

      expect(a.pull.yourShare, b.pull.theirShare);
      expect(a.power.yourShare, b.power.theirShare);
    });

    test('the card line is drawn from the strongest thing on the page', () {
      // Every share line must come from one of the three sources, never
      // be improvised, and never be blank.
      final permitted = {
        CompatibilityComposer.lopsidedShareLine,
        ...CompatibilityComposer.punchlines.values,
        ...CompatibilityComposer.shareLines.values,
      };

      for (final a in ZodiacSign.values) {
        for (final b in ZodiacSign.values) {
          final match = CompatibilityComposer.compose(
            you: _person('A', _dateIn(a)),
            them: _person('B', _dateIn(b)),
            now: _now,
          );
          expect(permitted, contains(match.shareLine));
        }
      }
    });

    test('a lopsided pull takes over the card', () {
      // The most postable claim wins the artifact that travels.
      var seen = false;
      for (var year = 1970; year <= 2005; year++) {
        final match = _compose(
          DateTime(1996, 6, 15),
          DateTime(year, 4, 9),
        );
        if ((match.pull.yourShare - 50).abs() >= 18) {
          expect(match.shareLine, CompatibilityComposer.lopsidedShareLine);
          seen = true;
        }
      }
      expect(seen, isTrue, reason: 'no lopsided pair in the sample');
    });
  });

  group('identity', () {
    test('a celebrity match keys on the celebrity', () {
      final person = MatchPerson(
        name: 'Zendaya',
        birthDate: DateTime(1996, 9, 1),
        celebrityId: 'zendaya',
      );
      expect(person.key, 'celeb:zendaya');
    });

    test('a manual match keys on name and date, case-insensitively', () {
      final a = _person('Sam', DateTime(1994, 3, 2));
      final b = _person('  sam  ', DateTime(1994, 3, 2));
      expect(a.key, b.key);
    });

    test('a different date is a different match', () {
      final a = _person('Sam', DateTime(1994, 3, 2));
      final b = _person('Sam', DateTime(1994, 3, 3));
      expect(a.key, isNot(b.key));
    });
  });
}
