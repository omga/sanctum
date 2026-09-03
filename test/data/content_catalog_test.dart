import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/catalog/content_catalog.dart';
import 'package:sanctum/src/data/catalog/content_catalog_source.dart';
import 'package:sanctum/src/domain/models/celebrity.dart';
import 'package:sanctum/src/domain/models/moon_phase.dart';
import 'package:sanctum/src/domain/models/quiz.dart';

void main() {
  // Loads the *real* bundled JSON, so a typo in a content file fails CI
  // rather than shipping. Content is code here.
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentCatalog catalog;

  setUpAll(() async {
    const source = AssetContentCatalogSource();
    final result = await source.load();
    catalog = switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw StateError('load failed: $failure'),
    };
  });

  group('bundled content', () {
    test('parses every catalogue', () {
      expect(catalog.oracleCards, isNotEmpty);
      expect(catalog.sessions, isNotEmpty);
      expect(catalog.affirmations, isNotEmpty);
      expect(catalog.rituals, isNotEmpty);
      expect(catalog.celebrities, isNotEmpty);
    });

    test('celebrity ids are unique', () {
      final ids = catalog.celebrities.map((c) => c.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('every celebrity has a usable birth date', () {
      // The birth date is the one factual claim this feature makes about
      // a real person, and it is the only input the reading uses. A date
      // in the future or a placeholder year is a wrong sign shown next to
      // someone's name.
      final now = DateTime.now();
      for (final one in catalog.celebrities) {
        expect(
          one.birthDate.isBefore(now),
          isTrue,
          reason: '${one.name} is not born yet',
        );
        expect(
          one.birthDate.year,
          greaterThan(1900),
          reason: '${one.name} has a placeholder year',
        );
        expect(one.name.trim(), isNotEmpty);
        expect(one.knownFor.trim(), isNotEmpty);
        // Nobody in the catalogue may be a minor. This is a romantic
        // compatibility feature — "who wants it more" is rendered beside
        // the name and posted publicly — and a child in that list is a
        // different kind of mistake from a wrong date. The catalogue is
        // built from a script that already enforces this; the test is
        // what stops a hand-added entry slipping past it.
        final age = now.difference(one.birthDate).inDays ~/ 365;
        expect(
          age,
          greaterThanOrEqualTo(18),
          reason: '${one.name} is under 18',
        );
      }
    });

    test('every group has someone in it', () {
      // An empty section renders as a heading with nothing under it.
      for (final group in CelebrityGroup.values) {
        expect(
          catalog.celebritiesIn(group),
          isNotEmpty,
          reason: 'nobody in ${group.displayName}',
        );
      }
    });

    test('the picker covers a decent spread of signs', () {
      // Not all twelve — that would be a content constraint nobody can
      // meet with real people — but a list that is all Leos makes the
      // match scores look broken.
      final signs = catalog.celebrities.map((c) => c.sign).toSet();
      expect(signs.length, greaterThanOrEqualTo(10));
    });

    test('the deck is large enough for a week-long no-repeat guarantee', () {
      // DailyAttunementSelector only reaches a 7-day guard at 22+ cards.
      expect(catalog.oracleCards.length, greaterThanOrEqualTo(22));
    });

    test('card ids are unique', () {
      final ids = catalog.oracleCards.map((c) => c.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('session ids are unique and durations are sane', () {
      final ids = catalog.sessions.map((s) => s.id).toList();
      expect(ids.toSet(), hasLength(ids.length));

      for (final session in catalog.sessions) {
        expect(session.durationSeconds, greaterThan(0));
        expect(session.frequencyHz, greaterThan(20));
        expect(session.frequencyHz, lessThan(20000));
      }
    });

    test('no card has empty copy', () {
      for (final card in catalog.oracleCards) {
        expect(card.name, isNotEmpty, reason: card.id);
        expect(card.message, isNotEmpty, reason: card.id);
        expect(card.guidance, isNotEmpty, reason: card.id);
      }
    });

    test('both ritual moons have a ritual', () {
      expect(catalog.hasRitualFor(MoonPhase.newMoon), isTrue);
      expect(catalog.hasRitualFor(MoonPhase.fullMoon), isTrue);
    });

    test('every ritual phase carries more than one, so they rotate', () {
      // A phase with a single ritual serves the same words every cycle,
      // which is what this catalogue was before. Guarding it here is
      // cheaper than noticing six months later that nothing changed.
      for (final phase in MoonPhase.values) {
        if (!catalog.hasRitualFor(phase)) continue;
        expect(
          catalog.ritualsFor(phase).length,
          greaterThan(1),
          reason: phase.name,
        );
      }
    });

    test('the quiz asks for a birth time, and it parses as one', () {
      // The kind is a string in JSON, so a typo would decode to a
      // different question type and the screen would silently render
      // the wrong control.
      final question = catalog.quizQuestions
          .where((q) => q.id == 'birth_time')
          .single;

      expect(question.kind, QuizQuestionKind.time);
      expect(question.options, isEmpty);
    });

    test('the birth time is asked after the birth date', () {
      // Order matters for the flow, not just for taste: the time is a
      // follow-up to the date and reads as a non-sequitur before it.
      final ids = catalog.quizQuestions.map((q) => q.id).toList();
      expect(ids.indexOf('birth_time'), ids.indexOf('birth_date') + 1);
    });

    test('ritual ids are unique', () {
      final ids = catalog.rituals.map((r) => r.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every ritual has ordered steps', () {
      for (final ritual in catalog.rituals) {
        expect(ritual.steps, isNotEmpty, reason: ritual.id);
      }
    });

    test('lookup by id works', () {
      final first = catalog.oracleCards.first;
      expect(catalog.cardById(first.id)?.name, first.name);
      expect(catalog.cardById('nope'), isNull);
    });
  });
}
