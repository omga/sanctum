import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/domain/services/compatibility_calculator.dart';

MatchPerson person(int year, int month, int day) =>
    MatchPerson(name: 'X', birthDate: DateTime(year, month, day));

/// A spread of real birth dates, so the properties below are checked
/// against actual planetary geometry rather than a handful of samples.
final _people = <MatchPerson>[
  for (var year = 1962; year <= 2006; year += 4)
    for (final month in [2, 5, 8, 11]) person(year, month, 14),
];

void main() {
  group('sign aspects', () {
    // Still used to name the reading, even though it no longer scores it.
    test('the enum is declared in distance order', () {
      expect(ZodiacAspect.values, hasLength(7));
      expect(ZodiacAspect.values[0], ZodiacAspect.conjunction);
      expect(ZodiacAspect.values[3], ZodiacAspect.square);
      expect(ZodiacAspect.values[4], ZodiacAspect.trine);
      expect(ZodiacAspect.values[6], ZodiacAspect.opposition);
    });

    test('wraps around the end of the wheel', () {
      expect(
        CompatibilityCalculator.stepsBetween(
          ZodiacSign.pisces,
          ZodiacSign.aries,
        ),
        1,
      );
    });

    test('four apart is a trine and shares an element', () {
      expect(
        CompatibilityCalculator.aspectBetween(
          ZodiacSign.aries,
          ZodiacSign.leo,
        ),
        ZodiacAspect.trine,
      );
      expect(ZodiacSign.aries.element, ZodiacSign.leo.element);
    });
  });

  group('facet scores', () {
    test('are symmetric', () {
      for (final a in _people.take(20)) {
        for (final b in _people.take(20)) {
          expect(
            CompatibilityCalculator.overall(a, b),
            CompatibilityCalculator.overall(b, a),
            reason: 'a pairing must read the same from either side',
          );
        }
      }
    });

    test('stay inside the published range', () {
      for (final a in _people) {
        for (final b in _people.take(12)) {
          expect(
            CompatibilityCalculator.overall(a, b),
            inInclusiveRange(
              CompatibilityCalculator.floor,
              CompatibilityCalculator.ceiling,
            ),
          );
          for (final facet in CompatibilityCalculator.facets(a, b)) {
            expect(
              facet.score,
              inInclusiveRange(
                CompatibilityCalculator.floor,
                CompatibilityCalculator.ceiling,
              ),
              reason: '${facet.facet}',
            );
          }
        }
      }
    });

    test('produce all six facets, in declaration order', () {
      final facets = CompatibilityCalculator.facets(
        person(1996, 6, 15),
        person(1990, 11, 2),
      );
      expect(facets.map((f) => f.facet), CompatibilityFacet.values);
    });

    test('are deterministic', () {
      final a = person(1996, 6, 15);
      final b = person(1990, 11, 2);
      expect(
        CompatibilityCalculator.overall(a, b),
        CompatibilityCalculator.overall(a, b),
      );
    });

    test('actually use the whole scale', () {
      // The failure this guards against is a model that technically
      // ranges 45–98 but in practice returns 68–74 for everybody, which
      // is what a naive average of harmonic functions does.
      final scores = <int>{};
      for (final a in _people) {
        for (final b in _people) {
          scores.add(CompatibilityCalculator.overall(a, b));
        }
      }
      expect(scores.reduce((a, b) => a < b ? a : b), lessThan(60));
      expect(scores.reduce((a, b) => a > b ? a : b), greaterThan(88));
      expect(scores.length, greaterThan(30));
    });

    test('two people born days apart do not score identically', () {
      // The old model keyed everything to the sun sign, so a whole month
      // of birthdays collapsed onto one result. Real planets move.
      final anchor = person(1996, 6, 15);
      final first = CompatibilityCalculator.overall(
        anchor,
        person(1990, 11, 2),
      );
      final second = CompatibilityCalculator.overall(
        anchor,
        person(1990, 11, 20),
      );
      expect(first, isNot(second));
    });

    test('the same two dates score the same regardless of name', () {
      const date = 15;
      expect(
        CompatibilityCalculator.overall(
          MatchPerson(name: 'Sam', birthDate: DateTime(1996, 6, date)),
          MatchPerson(name: 'Alex', birthDate: DateTime(1990, 11, 2)),
        ),
        CompatibilityCalculator.overall(
          MatchPerson(name: 'Jo', birthDate: DateTime(1996, 6, date)),
          MatchPerson(name: 'Pat', birthDate: DateTime(1990, 11, 2)),
        ),
      );
    });
  });

  group('directional readings', () {
    test('the two shares always sum to one hundred', () {
      for (final a in _people.take(15)) {
        for (final b in _people.take(15)) {
          final pull = CompatibilityCalculator.pullShare(a, b);
          expect(pull, inInclusiveRange(5, 95));
          expect(100 - pull, inInclusiveRange(5, 95));
        }
      }
    });

    test('reverse when the two people swap places', () {
      // The whole point of a directional reading. If this were symmetric
      // it would be saying nothing.
      for (final a in _people.take(15)) {
        for (final b in _people.take(15)) {
          expect(
            CompatibilityCalculator.pullShare(a, b),
            100 - CompatibilityCalculator.pullShare(b, a),
            reason: 'pull must mirror',
          );
          expect(
            CompatibilityCalculator.powerShare(a, b),
            100 - CompatibilityCalculator.powerShare(b, a),
            reason: 'power must mirror',
          );
        }
      }
    });

    test('a person is evenly matched with themselves', () {
      final self = person(1996, 6, 15);
      expect(CompatibilityCalculator.pullShare(self, self), 50);
      expect(CompatibilityCalculator.powerShare(self, self), 50);
    });

    test('do get lopsided for real pairs', () {
      // Damped toward even when there is nothing to say — but if it were
      // damped so hard that nothing ever leaned, the feature would not
      // exist.
      var lopsided = 0;
      for (final a in _people) {
        for (final b in _people) {
          if ((CompatibilityCalculator.pullShare(a, b) - 50).abs() >= 18) {
            lopsided++;
          }
        }
      }
      expect(lopsided, greaterThan(0));
    });
  });

  group('verdicts', () {
    test('band the score', () {
      expect(CompatibilityCalculator.verdictFor(95), 'Rare');
      expect(CompatibilityCalculator.verdictFor(84), 'Strong');
      expect(CompatibilityCalculator.verdictFor(71), 'Charged');
      expect(CompatibilityCalculator.verdictFor(62), 'Workable');
      expect(CompatibilityCalculator.verdictFor(47), 'Hard-won');
    });

    test('every reachable score has a verdict', () {
      for (
        var score = CompatibilityCalculator.floor;
        score <= CompatibilityCalculator.ceiling;
        score++
      ) {
        expect(CompatibilityCalculator.verdictFor(score), isNotEmpty);
      }
    });
  });
}
