import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/birth_time.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/models/relationship_report.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/domain/services/compatibility_calculator.dart';
import 'package:sanctum/src/domain/services/compatibility_composer.dart';
import 'package:sanctum/src/domain/services/report_composer.dart';

import '../support/copy.dart';

final CopyBook _copy = loadEnglishCopy();

final _now = DateTime(2026, 9, 4);

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

MatchPerson _person(String name, DateTime birth, {int? minute}) =>
    MatchPerson(
      name: name,
      birthDate: birth,
      birthTime: minute == null
          ? BirthTime.unknown
          : BirthTime(minuteOfDay: minute),
    );

CompatibilityMatch _match(
  DateTime a,
  DateTime b, {
  int? yourMinute,
  int? theirMinute,
}) => CompatibilityComposer.compose(
  you: _person('You', a, minute: yourMinute),
  them: _person('Them', b, minute: theirMinute),
  now: _now,
  copy: _copy,
);

RelationshipReport _report(
  DateTime a,
  DateTime b, {
  int? yourMinute,
  int? theirMinute,
}) => ReportComposer.compose(
  match: _match(a, b, yourMinute: yourMinute, theirMinute: theirMinute),
  copy: _copy,
);

/// Every sign against every sign, without birth times.
Iterable<RelationshipReport> _everyPairing() sync* {
  for (final a in ZodiacSign.values) {
    for (final b in ZodiacSign.values) {
      yield _report(_dateIn(a), _dateIn(b));
    }
  }
}

void main() {
  group('the copy is complete', () {
    test('every sign pairing composes without a missing key', () {
      // `CopyBook.get` throws on an absent key, so composing all 144
      // pairings against the real shipped file is the exhaustive check
      // that every branch of every selector has prose behind it. This is
      // the test that fails when somebody adds a facet or an aspect and
      // forgets the content.
      for (final report in _everyPairing()) {
        expect(report.opening, isNotEmpty);
        expect(report.closing, isNotEmpty);
        expect(report.watchFor, isNotEmpty);
        expect(report.facets, hasLength(CompatibilityFacet.values.length));
        for (final facet in report.facets) {
          expect(facet.mechanism, isNotEmpty);
          expect(facet.reading, isNotEmpty);
        }
      }
    });

    test('composes with both birth times known', () {
      // The Moon branch is a whole second set of keys and a whole second
      // set of contacts, and nothing above reaches it.
      for (final a in ZodiacSign.values) {
        for (final b in ZodiacSign.values) {
          final report = _report(
            _dateIn(a),
            _dateIn(b),
            yourMinute: 7 * 60 + 20,
            theirMinute: 21 * 60 + 5,
          );
          expect(report.moon, isNotNull);
          expect(report.moon!.reading, isNotEmpty);
        }
      }
    });

    test('every closing band a real score can produce has copy', () {
      // The closing key is derived from `verdictFor`'s own output rather
      // than from a second switch on the same thresholds, so this walks
      // the whole range instead of the five words we happen to expect.
      for (var score = 0; score <= 100; score++) {
        final key = ReportComposer.verdictKey(
          CompatibilityCalculator.verdictFor(score),
        );
        expect(
          _copy.has('report.closing.$key'),
          isTrue,
          reason: 'no closing copy for score $score (key "$key")',
        );
      }
    });

    test('every facet band is reachable', () {
      // A band with no pairing that produces it is copy nobody will ever
      // read, and — worse — a threshold that is quietly wrong.
      final seen = <FacetBand>{};
      for (final report in _everyPairing()) {
        for (final facet in report.facets) {
          seen.add(facet.band);
        }
      }
      expect(seen, containsAll(FacetBand.values));
    });

    test('every direction lean is reachable', () {
      final seen = <DirectionLean>{};
      for (final report in _everyPairing()) {
        for (final direction in report.directions) {
          seen.add(direction.lean);
        }
      }
      expect(seen, containsAll(DirectionLean.values));
    });
  });

  group('the report deepens the reading rather than restating it', () {
    test('every score is copied from the match, not recomputed', () {
      // The whole reason this takes a composed match: a 77 on the dial
      // and a 78 in the document the user paid for would make every
      // number in the app look invented.
      for (final report in _everyPairing()) {
        for (var i = 0; i < report.facets.length; i++) {
          expect(report.facets[i].facet, report.match.facets[i].facet);
          expect(report.facets[i].score, report.match.facets[i].score);
        }
        expect(report.pull.yourShare, report.match.pull.yourShare);
        expect(report.power.yourShare, report.match.power.yourShare);
        expect(report.id, report.match.id);
      }
    });

    test('is deterministic', () {
      final a = _report(_dateIn(ZodiacSign.gemini), _dateIn(ZodiacSign.leo));
      final b = _report(_dateIn(ZodiacSign.gemini), _dateIn(ZodiacSign.leo));
      expect(a.opening, b.opening);
      expect(a.closing, b.closing);
      expect(a.watchFor, b.watchFor);
      expect(
        [for (final f in a.facets) f.reading],
        [for (final f in b.facets) f.reading],
      );
    });

    test('watchFor keys off the weakest facet', () {
      for (final report in _everyPairing()) {
        final weakest = report.match.weakest;
        if (ReportComposer.bandFor(weakest.score) == FacetBand.high) continue;
        expect(
          report.watchFor,
          _copy.get('report.watch.${weakest.facet.name}'),
        );
      }
    });

    test('never warns about an axis it just called a strength', () {
      // About one pairing in a hundred and six scores every facet in the
      // top band. Keying the fault line to the weakest facet regardless
      // would have those reports call an axis a strength on one page and
      // warn about it on the next — rare, and not acceptable in a
      // document somebody paid for.
      var allHigh = 0;
      for (final report in _everyPairing()) {
        final highs = report.facets
            .where((f) => f.band == FacetBand.high)
            .length;
        if (highs != report.facets.length) continue;
        allHigh++;
        expect(report.watchFor, _copy.get('report.watch.none'));
      }
      expect(allHigh, greaterThan(0), reason: 'no all-high pairing covered');
    });
  });

  group('the Moon', () {
    final noTime = _report(
      _dateIn(ZodiacSign.aries),
      _dateIn(ZodiacSign.libra),
    );
    final oneTime = _report(
      _dateIn(ZodiacSign.aries),
      _dateIn(ZodiacSign.libra),
      yourMinute: 480,
    );
    final bothTimes = _report(
      _dateIn(ZodiacSign.aries),
      _dateIn(ZodiacSign.libra),
      yourMinute: 480,
      theirMinute: 1020,
    );

    test('is absent unless both birth times are known', () {
      // Half-knowing is the case worth being careful about: one real
      // Moon against an invented one would report the difference as a
      // finding about the couple.
      expect(noTime.moon, isNull);
      expect(oneTime.moon, isNull);
      expect(bothTimes.moon, isNotNull);
    });

    test('says why it is missing, exactly when it is missing', () {
      for (final report in [noTime, oneTime]) {
        expect(report.moonAbsence, isNotNull);
        expect(report.moonAbsence, isNotEmpty);
      }
      expect(bothTimes.moonAbsence, isNull);
    });

    test('contributes contacts only when it is in the score', () {
      // The calculator adds Moon terms to Vibe only when both times are
      // known. Listing a Moon contact the score did not use would be
      // claiming the number came from somewhere it did not.
      List<ReportContact> vibeOf(RelationshipReport report) => report.facets
          .firstWhere((f) => f.facet == CompatibilityFacet.vibe)
          .contacts;

      expect(
        vibeOf(noTime).any((c) => c.yourPoint == ChartPoint.moon),
        isFalse,
      );
      expect(
        vibeOf(bothTimes).any((c) => c.yourPoint == ChartPoint.moon),
        isTrue,
      );
      expect(vibeOf(bothTimes), hasLength(vibeOf(noTime).length + 1));
    });
  });

  group('the contacts are the ones the score was made of', () {
    test('spark is Venus against Mars, both ways, plus Mars to Mars', () {
      // Traceability is the product here: a reader has to be able to
      // follow any number back to two placements. That only holds if
      // these mirror `CompatibilityCalculator._raw` exactly.
      final report = _report(
        _dateIn(ZodiacSign.taurus),
        _dateIn(ZodiacSign.scorpio),
      );
      final spark = report.facets
          .firstWhere((f) => f.facet == CompatibilityFacet.spark)
          .contacts;

      expect(
        [for (final c in spark) '${c.yourPoint.name}/${c.theirPoint.name}'],
        ['venus/mars', 'mars/venus', 'mars/mars'],
      );
    });

    test('pull is Mars reaching Venus, power is Saturn reaching Sun', () {
      final report = _report(
        _dateIn(ZodiacSign.taurus),
        _dateIn(ZodiacSign.scorpio),
      );
      expect(
        [
          for (final c in report.pull.contacts)
            '${c.yourPoint.name}/${c.theirPoint.name}',
        ],
        ['mars/venus', 'venus/mars'],
      );
      expect(
        [
          for (final c in report.power.contacts)
            '${c.yourPoint.name}/${c.theirPoint.name}',
        ],
        ['saturn/sun', 'sun/saturn'],
      );
    });

    test('an out-of-orb pair is reported as no contact, not as zero', () {
      // Most planet pairs in most charts are not in contact. A report
      // that found something to say about all of them would be
      // inventing, which is the one thing this SKU cannot afford.
      final anyAbsent = _everyPairing().any(
        (report) => report.contacts.any((c) => !c.isInContact),
      );
      expect(anyAbsent, isTrue);

      final report = _report(
        _dateIn(ZodiacSign.gemini),
        _dateIn(ZodiacSign.leo),
      );
      expect(report.liveContacts.length, lessThan(report.contacts.length));
    });
  });
}
