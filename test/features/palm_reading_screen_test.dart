import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/catalog/content_catalog.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/repositories/palm_repository.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_composer.dart';
import 'package:sanctum/src/features/palm/view/palm_reading_screen.dart';
import 'package:sanctum/src/features/palm/view_model/palm_scan_view_model.dart';
import 'package:sanctum/src/l10n/generated/app_localizations.dart';

import '../support/copy.dart';
import '../support/harness.dart';
import '../support/palm_fixtures.dart';

class _FakePalmRepository implements PalmRepository {
  _FakePalmRepository({this.unlocked = const {}, this.shared = false});

  Set<String> unlocked;
  bool shared;

  @override
  Future<Result<Set<String>>> unlockedReadings() async => Ok(unlocked);

  @override
  Future<Result<void>> recordUnlock(String scanId) async {
    unlocked = {...unlocked, scanId};
    return const Ok(null);
  }

  @override
  Future<Result<bool>> hasSharedScan() async => Ok(shared);

  @override
  Future<Result<void>> recordShare() async {
    shared = true;
    return const Ok(null);
  }
}

late AppLocalizations _en;
late PalmReading _scan;

Future<void> _pumpReading(
  WidgetTester tester, {
  required _FakePalmRepository repository,
  bool isPremium = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        palmRepositoryProvider.overrideWithValue(repository),
        // The real English content file, not a fixture. These tests then
        // fail if a `palm.*` key the screen asks for is missing from the
        // shipped copy, which is the failure worth catching.
        contentCatalogProvider.overrideWith(
          (ref) async => ContentCatalog(
            oracleCards: const [],
            sessions: const [],
            affirmations: const [],
            rituals: const [],
            quizQuestions: const [],
            celebrities: const [],
            copy: loadEnglishCopy(),
          ),
        ),
        isPremiumProvider.overrideWithValue(isPremium),
        // The reading is read from the live scan, because nothing about
        // a palm is stored. Seeding it is what the camera would do.
        palmScanViewModelProvider.overrideWith(_SeededScan.new),
      ],
      child: testApp(PalmReadingScreen(scanId: _scan.id)),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// A view model that starts on a finished scan.
class _SeededScan extends PalmScanViewModel {
  @override
  PalmScanState build() =>
      PalmScanState(stage: PalmScanStage.revealed, reading: _scan);
}

void main() {
  setUpAll(() async {
    _en = await AppLocalizations.delegate.load(const Locale('en'));
    _scan = PalmComposer.compose(
      landmarks: goodHand(),
      at: DateTime.utc(2026, 9, 8, 10, 12),
    )!;
  });

  testWidgets('asks for a share before the first reading', (tester) async {
    await _pumpReading(tester, repository: _FakePalmRepository());

    expect(find.text(_en.palmLockedShareTitle), findsOneWidget);
    expect(find.text(_en.palmLineHeart), findsNothing);
  });

  testWidgets('names every destination, not just a public post', (
    tester,
  ) async {
    // The wording is the design. Requiring a *public* post is
    // unenforceable, is the shape of thing App Review rejects, and
    // taxes the only acquisition channel this feature has — so the copy
    // has to offer a friend and a group alongside a feed.
    await _pumpReading(tester, repository: _FakePalmRepository());

    final body = _en.palmLockedShareBody.toLowerCase();
    expect(body, contains('friend'));
    expect(body, contains('group'));
  });

  testWidgets('opens once something has been shared', (tester) async {
    await _pumpReading(
      tester,
      repository: _FakePalmRepository(shared: true),
    );

    expect(find.text(_en.palmLineHeart), findsOneWidget);
    expect(find.text(_en.palmLockedShareTitle), findsNothing);
  });

  testWidgets('writes the reading down so it stays open', (tester) async {
    // Without this, coming back a minute later spends the allowance
    // again and then asks for money for a screen already read.
    final repository = _FakePalmRepository(shared: true);
    await _pumpReading(tester, repository: repository);
    await tester.pump();

    expect(repository.unlocked, contains(_scan.id));
  });

  testWidgets('asks for money once the free reading is spent', (
    tester,
  ) async {
    await _pumpReading(
      tester,
      repository: _FakePalmRepository(
        unlocked: const {'palm:2026-01-01T00:00:00:left'},
        shared: true,
      ),
    );

    expect(find.text(_en.palmLockedPremiumTitle), findsOneWidget);
    expect(find.text(_en.palmLockedPremiumCta), findsOneWidget);
  });

  testWidgets('never asks a subscriber for either', (tester) async {
    await _pumpReading(
      tester,
      repository: _FakePalmRepository(
        unlocked: const {'palm:2026-01-01T00:00:00:left'},
      ),
      isPremium: true,
    );

    expect(find.text(_en.palmLineHeart), findsOneWidget);
    expect(find.text(_en.palmLockedShareTitle), findsNothing);
    expect(find.text(_en.palmLockedPremiumTitle), findsNothing);
  });

  testWidgets('carries the entertainment disclaimer', (tester) async {
    // Present on the reveal and here. Store review for divination
    // content generally expects it, and the roadmap already lists its
    // absence elsewhere as debt.
    await _pumpReading(
      tester,
      repository: _FakePalmRepository(shared: true),
    );

    expect(find.text(_en.palmDisclaimer), findsOneWidget);
  });
}
