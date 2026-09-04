import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/catalog/content_catalog.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/repositories/report_repository.dart';
import 'package:sanctum/src/data/repositories/subscription_repository.dart';
import 'package:sanctum/src/domain/models/birth_time.dart';
import 'package:sanctum/src/domain/models/celebrity.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/models/report_product.dart';
import 'package:sanctum/src/domain/models/ritual.dart';
import 'package:sanctum/src/domain/models/sound_session.dart';
import 'package:sanctum/src/domain/models/subscription_plan.dart';
import 'package:sanctum/src/domain/services/compatibility_composer.dart';
import 'package:sanctum/src/features/compatibility/view/report_screen.dart';

import '../support/copy.dart';
import '../support/harness.dart';

final CopyBook _copy = loadEnglishCopy();

/// Gemini and Sagittarius — an opposition, so the splits are lopsided.
CompatibilityMatch _match({int? yourMinute, int? theirMinute}) =>
    CompatibilityComposer.compose(
      you: MatchPerson(
        name: 'Andrew',
        birthDate: DateTime(1996, 6, 15),
        birthTime: BirthTime(minuteOfDay: yourMinute),
      ),
      them: MatchPerson(
        name: 'Alex',
        birthDate: DateTime(1994, 12, 2),
        birthTime: BirthTime(minuteOfDay: theirMinute),
      ),
      now: DateTime(2026, 9, 4),
      copy: _copy,
    );

/// A receipt store that owns whatever it is told to.
class _Reports implements ReportRepository {
  _Reports(this.owned);

  final Set<String> owned;

  @override
  Future<Result<Set<String>>> purchased() async => Result.ok(owned);

  @override
  Future<Result<void>> recordPurchase(String matchId) async =>
      const Result.ok(null);
}

/// A store with one product and no sheet.
class _Store implements SubscriptionRepository {
  _Store({this.product});

  final ReportProduct? product;

  @override
  Future<Result<List<SubscriptionPlan>>> plans() async => const Result.ok([]);

  @override
  Future<Result<bool>> purchase(String planId) async => const Result.ok(true);

  @override
  Future<Result<ReportProduct?>> reportProduct() async => Result.ok(product);

  @override
  Future<Result<bool>> purchaseReport() async => const Result.ok(true);

  @override
  Future<Result<bool>> restore() async => const Result.ok(false);
}

Future<void> _pump(
  WidgetTester tester,
  CompatibilityMatch match, {
  bool owned = true,
  ReportProduct? product = const ReportProduct(
    id: 'sanctum.report.relationship',
    displayPrice: '£4.99',
  ),
  Size size = const Size(1200, 2600),
  double pixelRatio = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        contentCatalogProvider.overrideWith(
          (ref) async => ContentCatalog(
            oracleCards: const [],
            sessions: const <SoundSession>[],
            affirmations: const [],
            rituals: const <Ritual>[],
            quizQuestions: const [],
            celebrities: const <Celebrity>[],
            copy: _copy,
          ),
        ),
        reportRepositoryProvider.overrideWithValue(
          _Reports(owned ? {match.id} : const {}),
        ),
        subscriptionRepositoryProvider.overrideWithValue(
          _Store(product: product),
        ),
        isPremiumProvider.overrideWithValue(false),
      ],
      child: testApp(ReportScreen(match: match)),
    ),
  );
  // `pump` rather than `pumpAndSettle`: the primary button carries a
  // sheen that repeats forever, so a settle never returns on any screen
  // showing one. Two frames is enough for the providers to resolve.
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('names the person in the title', (tester) async {
    // The product is a document about one named human being. A report
    // that cannot say who it is about is selling a category.
    await _pump(tester, _match());
    expect(find.text('You & Alex'), findsOneWidget);
  });

  testWidgets('every facet gets a section with its score', (tester) async {
    final match = _match();
    await _pump(tester, match);

    for (final scored in match.facets) {
      await tester.scrollUntilVisible(
        find.text(scored.facet.displayName.toUpperCase()),
        300,
      );
      expect(
        find.text(scored.facet.displayName.toUpperCase()),
        findsOneWidget,
      );
    }
  });

  testWidgets('shows the angle for contacts that are not in orb', (
    tester,
  ) async {
    // About two facet sections in five have nothing in orb. Rendering
    // those as bare "no contact" lines would put an empty table under a
    // paragraph that promises to show its working.
    await _pump(tester, _match());
    expect(find.textContaining('no aspect'), findsWidgets);
  });

  testWidgets('names the aspect for contacts that are in orb', (
    tester,
  ) async {
    await _pump(tester, _match());
    expect(find.textContaining('off exact'), findsWidgets);
  });

  testWidgets('the angle table uses geometric names, not chip names', (
    tester,
  ) async {
    // "Magnetic · 4.4° off exact" reads as a mood in a column of
    // measurements, and "Charged" is already the verdict two lines up
    // in the header meaning something else entirely.
    await _pump(tester, _match());
    expect(find.textContaining('Opposition'), findsWidgets);
    expect(find.textContaining('Magnetic'), findsNothing);
  });

  testWidgets('says why the Moon is missing, without a birth time', (
    tester,
  ) async {
    await _pump(tester, _match());
    await tester.scrollUntilVisible(find.text('No birth time'), 300);
    expect(find.text('No birth time'), findsOneWidget);
  });

  testWidgets('names both Moon signs when both times are known', (
    tester,
  ) async {
    final match = _match(yourMinute: 520, theirMinute: 1335);
    await _pump(tester, match);

    final moon = ReportMoonNames(match);
    await tester.scrollUntilVisible(find.text(moon.label), 300);
    expect(find.text(moon.label), findsOneWidget);
  });

  testWidgets('keeps the disclaimer wording', (tester) async {
    // "For entertainment purposes only" is a store-review requirement
    // and is not decorative.
    await _pump(tester, _match());
    await tester.scrollUntilVisible(
      find.textContaining('entertainment purposes only'),
      300,
    );
    expect(
      find.textContaining('entertainment purposes only'),
      findsOneWidget,
    );
  });

  testWidgets('lays out without overflowing on a small phone', (
    tester,
  ) async {
    await _pump(
      tester,
      _match(),
      size: const Size(750, 1334),
      pixelRatio: 2,
    );
    expect(tester.takeException(), isNull);
  });

  group('before it is bought', () {
    testWidgets('shows the offer and none of the document', (tester) async {
      // A blurred wall of body text reads as a wall of text, and blurred
      // specificity is indistinguishable from blurred filler — so the
      // offer states what is inside and shows none of it.
      await _pump(tester, _match(), owned: false);

      expect(find.textContaining('You & Alex, in full'), findsOneWidget);
      expect(find.text('Unlock · £4.99'), findsOneWidget);
      expect(find.text('SPARK'), findsNothing);
      expect(find.textContaining('WHAT THIS NUMBER IS MADE OF'), findsNothing);
    });

    testWidgets('shows no price when the store has no product', (
      tester,
    ) async {
      await _pump(tester, _match(), owned: false, product: null);

      expect(find.textContaining('not available'), findsOneWidget);
      expect(find.textContaining('Unlock ·'), findsNothing);
    });

    testWidgets('says the purchase does not leave the phone', (tester) async {
      // Consumables do not restore, and the small print has to say so
      // before the money changes hands rather than after.
      await _pump(tester, _match(), owned: false);
      expect(find.textContaining('stays on this phone'), findsOneWidget);
    });
  });
}

/// The Moon-signs subheading the screen should be rendering.
class ReportMoonNames {
  /// Reads both Moon signs off [match].
  ReportMoonNames(this.match);

  /// The reading under test.
  final CompatibilityMatch match;

  /// "Gemini and Sagittarius".
  String get label =>
      '${match.you.moonSign!.displayName} and '
      '${match.them.moonSign!.displayName}';
}
