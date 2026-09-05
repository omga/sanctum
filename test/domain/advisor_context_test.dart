import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/advisor_context.dart';
import 'package:sanctum/src/domain/models/birth_time.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/planet.dart';
import 'package:sanctum/src/domain/models/transit.dart';
import 'package:sanctum/src/domain/services/compatibility_composer.dart';
import 'package:sanctum/src/domain/services/report_composer.dart';

import '../support/copy.dart';

/// The privacy guarantee, asserted rather than promised.
///
/// `handoff.md` §3 is explicit that the promise — "your name, your birth
/// date and your journal stay on this phone" — does not survive AI chat
/// unless the payload is built to make it survive. [AdvisorContext] is
/// that construction; this file is the proof.
///
/// Modelled on `analytics_test.dart`, which does the same job for the
/// same reason. **New constructors must be added to `_everyContext`** —
/// the guarantees below are only worth what the exhaustiveness of that
/// list is worth.
void main() {
  final copy = loadEnglishCopy();

  // Deliberately distinctive names. A generic "You"/"Them" would pass a
  // substring check by accident.
  const yourName = 'Ksenia';
  const theirName = 'Alexander';

  final you = MatchPerson(
    name: yourName,
    birthDate: DateTime(1996, 6, 15),
    birthTime: const BirthTime(minuteOfDay: 500),
  );
  final them = MatchPerson(
    name: theirName,
    birthDate: DateTime(1994, 11, 2),
    birthTime: const BirthTime(minuteOfDay: 900),
  );

  final match = CompatibilityComposer.compose(
    you: you,
    them: them,
    now: DateTime(2026, 9, 5),
    copy: copy,
  );
  final report = ReportComposer.compose(match: match, copy: copy);

  const reading = DailyTransitReading(
    transit: Transit(
      transiting: Planet.saturn,
      natal: Planet.venus,
      aspect: TransitAspect.square,
      orb: 1.4,
      retrograde: true,
    ),
    line: 'ignored — prose never travels',
    headline: 'ignored',
    retrogrades: [Planet.mercury],
  );

  /// Every way an [AdvisorContext] can be built.
  final everyContext = <String, AdvisorContext>{
    'forMatch': AdvisorContext.forMatch(match, languageCode: 'en'),
    'forReport': AdvisorContext.forReport(report, languageCode: 'uk'),
    'forToday': AdvisorContext.forToday(reading, languageCode: 'es'),
    'forSelf': AdvisorContext.forSelf(
      you: you,
      today: reading,
      languageCode: 'en',
    ),
  };

  /// Every string and number anywhere in a payload, flattened.
  List<Object> flatten(Object? value) => switch (value) {
    final Map<Object?, Object?> map => [
      for (final entry in map.entries) ...[
        entry.key!,
        ...flatten(entry.value),
      ],
    ],
    final List<Object?> list => [for (final item in list) ...flatten(item)],
    final Object object => [object],
    null => const [],
  };

  group('the payload carries no identity', () {
    test('no name appears anywhere, in any form', () {
      // The check the whole feature rests on. A chart is not personal
      // data until it is attached to a person.
      for (final entry in everyContext.entries) {
        final flat = flatten(entry.value.facts).join(' ').toLowerCase();
        expect(
          flat.contains(yourName.toLowerCase()),
          isFalse,
          reason: '${entry.key} leaked the user name',
        );
        expect(
          flat.contains(theirName.toLowerCase()),
          isFalse,
          reason: '${entry.key} leaked the other name',
        );
      }
    });

    test('no birth date appears, in any of the obvious spellings', () {
      // Longitudes are derived from the date; the date is not
      // recoverable from them, and it is not sent.
      //
      // Years and ISO spellings only. A bare day-of-month is not a
      // useful check — "15" is a substring of half the longitudes in
      // any payload — and the guarantee it would be testing is already
      // made structurally: the type has no date field to put one in.
      const spellings = ['1996', '1994', '06-15', '11-02', '1996-06-15'];
      for (final entry in everyContext.entries) {
        final flat = flatten(entry.value.facts).join(' ');
        for (final spelling in spellings) {
          expect(
            flat.contains(spelling),
            isFalse,
            reason: '${entry.key} may contain a birth date ($spelling)',
          );
        }
      }
    });

    test('no key is one a person could be identified from', () {
      // A denylist rather than an allowlist, because the failure being
      // guarded against is somebody *adding* a field, and an allowlist
      // that has to be updated to add a legitimate field gets updated
      // reflexively.
      const denied = {
        'name',
        'first_name',
        'display_name',
        'birth',
        'birth_date',
        'birthdate',
        'birth_time',
        'dob',
        'email',
        'journal',
        'entry',
        'note',
        'device_id',
        'user_id',
        'install_id',
      };
      for (final entry in everyContext.entries) {
        for (final key in flatten(entry.value.facts).whereType<String>()) {
          expect(
            denied.contains(key),
            isFalse,
            reason: '${entry.key} carries a denied key: $key',
          );
        }
      }
    });
  });

  group('the payload carries only computed facts', () {
    test('every value is a primitive', () {
      for (final entry in everyContext.entries) {
        for (final value in flatten(entry.value.facts)) {
          expect(
            value is num || value is bool || value is String,
            isTrue,
            reason: '${entry.key} carries a ${value.runtimeType}',
          );
        }
      }
    });

    test('no value is long enough to be prose', () {
      // The composed readings are full paragraphs and none of them
      // belongs here: the model is given the numbers and writes its own
      // sentences. A long string in this payload means somebody passed
      // `match.dynamicLine` or a journal entry.
      for (final entry in everyContext.entries) {
        for (final value in flatten(entry.value.facts).whereType<String>()) {
          expect(
            value.length,
            lessThan(24),
            reason: '${entry.key} carries prose: "$value"',
          );
        }
      }
    });

    test('positions are rounded to a tenth of a degree', () {
      // Fifteen significant figures of an ephemeris calculation is both
      // meaningless to a model and, across enough fields, a fingerprint.
      final facts = everyContext['forMatch']!.facts;
      final yours = facts['you']! as Map<String, Object>;
      for (final value in yours.values.whereType<double>()) {
        expect(
          (value * 10) % 1,
          moreOrLessEquals(0, epsilon: 1e-9),
          reason: '$value is finer than a tenth of a degree',
        );
      }
    });
  });

  group('a conversation about yourself', () {
    test('sends one set of positions and no second person', () {
      // The whole difference between this surface and every other one.
      // A stray `them` here would be a pairing the user never asked
      // about, assembled out of whatever was lying around.
      final facts = everyContext['forSelf']!.facts;
      expect(facts.keys, contains('you'));
      expect(facts.keys, isNot(contains('them')));
      expect(facts.keys, isNot(contains('facets')));
    });

    test('carries the day it was asked on', () {
      // Without it the model has a birth chart and no present tense,
      // which is the horoscope-filler answer the prompt forbids.
      final facts = everyContext['forSelf']!.facts;
      expect(facts['quiet'], isFalse);
      expect(facts['transit'], isA<Map<String, Object>>());
    });

    test('works with no birth date to read a transit against', () {
      // Reachable: the transit needs a birth date, the app can be used
      // without one, and the natal questions still stand.
      final chartOnly = AdvisorContext.forSelf(you: you, languageCode: 'en');
      expect(chartOnly.facts.keys, contains('you'));
      expect(chartOnly.facts.keys, isNot(contains('transit')));
      expect(chartOnly.facts.keys, isNot(contains('quiet')));
    });

    test('describes the same sky as the today surface', () {
      // Two constructors, one day. If they ever diverge, the advisor
      // contradicts the panel the question was asked next to.
      final self = everyContext['forSelf']!.facts;
      final today = everyContext['forToday']!.facts;
      expect(self['transit'], today['transit']);
      expect(self['retrogrades'], today['retrogrades']);
      expect(self['quiet'], today['quiet']);
    });
  });

  group('the payload carries what the advisor actually needs', () {
    test('a match sends the scores the user is looking at', () {
      final facts = everyContext['forMatch']!.facts;
      expect(facts['overall'], match.overall);
      expect(facts['aspect'], match.aspect.name);
      expect(facts['facets'], hasLength(match.facets.length));
    });

    test('a report sends the bands and contacts a match does not', () {
      final facets = everyContext['forReport']!.facts['facets']! as List;
      final first = facets.first as Map<String, Object>;
      expect(first.containsKey('band'), isTrue);
      expect(first.containsKey('contacts'), isTrue);
    });

    test('a moon is sent only when both birth times are known', () {
      final withMoon =
          everyContext['forMatch']!.facts['you']! as Map<String, Object>;
      expect(withMoon.containsKey('moon'), isTrue);

      final noTime = CompatibilityComposer.compose(
        you: MatchPerson(name: yourName, birthDate: DateTime(1996, 6, 15)),
        them: MatchPerson(name: theirName, birthDate: DateTime(1994, 11, 2)),
        now: DateTime(2026, 9, 5),
        copy: copy,
      );
      final without =
          AdvisorContext.forMatch(noTime, languageCode: 'en').facts['you']!
              as Map<String, Object>;
      // Absent rather than guessed — the same rule `MatchPerson.moon`
      // enforces, so the advisor cannot describe a Moon the app itself
      // refuses to place.
      expect(without.containsKey('moon'), isFalse);
    });

    test('a quiet sky is stated rather than hidden', () {
      final quiet = AdvisorContext.forToday(
        const DailyTransitReading(
          line: 'x',
          headline: 'y',
          retrogrades: [],
        ),
        languageCode: 'en',
      );
      expect(quiet.facts['quiet'], isTrue);
      expect(quiet.facts.containsKey('transit'), isFalse);
    });

    test('the answer language travels', () {
      expect(everyContext['forReport']!.languageCode, 'uk');
    });

    test('the surface travels, so the prompt can differ by screen', () {
      expect(everyContext['forMatch']!.surface, 'match');
      expect(everyContext['forReport']!.surface, 'report');
      expect(everyContext['forToday']!.surface, 'today');
      expect(everyContext['forSelf']!.surface, 'self');
    });
  });
}
