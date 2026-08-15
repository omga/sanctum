import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/catalog/content_catalog.dart';
import 'package:sanctum/src/data/catalog/content_catalog_source.dart';
import 'package:sanctum/src/domain/models/moon_phase.dart';

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
      expect(catalog.ritualFor(MoonPhase.newMoon), isNotNull);
      expect(catalog.ritualFor(MoonPhase.fullMoon), isNotNull);
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
