import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/catalog/content_catalog.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/database/sanctum_database.dart';
import 'package:sanctum/src/data/repositories/settings_repository.dart';
import 'package:sanctum/src/data/repositories/subscription_repository.dart';
import 'package:sanctum/src/data/services/advisor/proxy_chat_transport.dart';
import 'package:sanctum/src/data/services/advisor/scripted_chat_transport.dart';
import 'package:sanctum/src/domain/models/advisor_consent.dart';
import 'package:sanctum/src/domain/models/advisor_topic.dart';
import 'package:sanctum/src/domain/models/birth_time.dart';
import 'package:sanctum/src/domain/models/celebrity.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/models/ritual.dart';
import 'package:sanctum/src/domain/models/sound_session.dart';
import 'package:sanctum/src/domain/services/compatibility_composer.dart';
import 'package:sanctum/src/features/advisor/view/advisor_consent_screen.dart';
import 'package:sanctum/src/features/advisor/view/advisor_screen.dart';
import 'package:sanctum/src/features/advisor/view_model/advisor_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/copy.dart';
import '../support/harness.dart';

final CopyBook _copy = loadEnglishCopy();

final CompatibilityMatch _match = CompatibilityComposer.compose(
  you: MatchPerson(
    name: 'Andrew',
    birthDate: DateTime(1990, 1, 15),
    birthTime: const BirthTime(minuteOfDay: 500),
  ),
  them: MatchPerson(
    name: 'Alex',
    birthDate: DateTime(1990, 3, 2),
    birthTime: const BirthTime(minuteOfDay: 900),
  ),
  now: DateTime(2026, 9, 4),
  copy: _copy,
);

/// Pumps a screen over a real preferences store.
///
/// Unlike `advisor_screen_test`, this file does **not** override
/// `advisorConsentProvider` — the read, the write and the persistence
/// are the thing under test, so they run through
/// `PreferencesSettingsRepository` for real.
Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  Map<String, Object>? prefs,
  bool keepPreferences = false,
  SanctumDatabase? database,
}) async {
  tester.view.physicalSize = const Size(1200, 3400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  if (!keepPreferences) {
    SharedPreferences.setMockInitialValues(prefs ?? const {});
  }

  final db = database ?? SanctumDatabase.memory();
  if (database == null) addTearDown(db.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sanctumDatabaseProvider.overrideWithValue(db),
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
        isPremiumProvider.overrideWithValue(true),
        subscriptionRepositoryProvider.overrideWithValue(
          LocalSubscriptionRepository(),
        ),
        chatTransportProvider.overrideWith(
          (ref) async => const ScriptedChatTransport(
            delayPerChunk: Duration.zero,
          ),
        ),
      ],
      child: testApp(screen),
    ),
  );
  // Frames rather than `pumpAndSettle`: the consent screen's primary
  // button carries a sheen that repeats forever, so a settle never
  // returns. The same trade `advisor_screen_test` records.
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

/// Frames enough for a preference write, an invalidate and the
/// re-read behind it to land.
///
/// Not `pumpAndSettle`: whichever side of the gate the screen lands on
/// may carry a primary `SanctumButton`, whose sheen repeats forever.
Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// What the store holds, read the way the app reads it.
Future<AdvisorConsent> _stored() async {
  final result = await const PreferencesSettingsRepository().advisorConsent();
  return result.getOrElse(AdvisorConsent.unasked);
}

void main() {
  group('before it is answered', () {
    testWidgets('the conversation is behind the disclosure', (tester) async {
      await _pump(tester, AdvisorScreen(topic: MatchTopic(_match)));

      expect(find.text('Before you ask'), findsOneWidget);
      // The two things a conversation screen has, and this one must not
      // until the question above has been answered.
      expect(find.byType(TextField), findsNothing);
      expect(find.text('SUGGESTED'), findsNothing);
    });

    testWidgets('the processor is named, not implied', (tester) async {
      // An unnamed "AI provider" is not a disclosure. If the vendor
      // changes, this test fails — which is the point: the copy and
      // AdvisorDisclosure.current both have to move with it.
      await _pump(tester, AdvisorScreen(topic: MatchTopic(_match)));
      expect(find.textContaining('DeepSeek'), findsOneWidget);
    });

    testWidgets('it says what is not sent, as well as what is', (
      tester,
    ) async {
      await _pump(tester, AdvisorScreen(topic: MatchTopic(_match)));
      expect(find.text('WHAT IS SENT'), findsOneWidget);
      expect(find.text('WHAT IS NOT'), findsOneWidget);
      expect(find.text('WHO RECEIVES IT'), findsOneWidget);
      expect(find.text('HOW LONG IT IS KEPT'), findsOneWidget);
    });

    testWidgets('an AI is disclosed before the first question, not after', (
      tester,
    ) async {
      // EU AI Act Article 50. The line at the head of a conversation
      // arrives too late for somebody deciding whether to have one.
      await _pump(tester, AdvisorScreen(topic: MatchTopic(_match)));
      expect(find.textContaining('written by an AI'), findsOneWidget);
    });
  });

  group('answering', () {
    testWidgets('agreeing opens the conversation', (tester) async {
      await _pump(tester, AdvisorScreen(topic: MatchTopic(_match)));
      await tester.tap(find.text('Agree and continue'));
      await _frames(tester);

      expect(find.text('SUGGESTED'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Before you ask'), findsNothing);
      expect(await _stored(), AdvisorConsent.granted);
    });

    testWidgets('and is not asked again next time', (tester) async {
      // The same database both times, or drift warns about two of them
      // over one executor — and the second screen would be reading a
      // different store than the first wrote to.
      final db = SanctumDatabase.memory();
      addTearDown(db.close);

      await _pump(
        tester,
        AdvisorScreen(topic: MatchTopic(_match)),
        database: db,
      );
      await tester.tap(find.text('Agree and continue'));
      await _frames(tester);

      // `keepPreferences`, or the re-pump replaces the store and proves
      // nothing about persistence.
      await _pump(
        tester,
        AdvisorScreen(topic: MatchTopic(_match)),
        database: db,
        keepPreferences: true,
      );
      expect(find.text('Before you ask'), findsNothing);
      expect(find.text('SUGGESTED'), findsOneWidget);
    });

    testWidgets('declining is recorded as a decision', (tester) async {
      await _pump(tester, AdvisorScreen(topic: MatchTopic(_match)));
      await tester.tap(find.text('Not now'));
      await _frames(tester);

      expect(await _stored(), AdvisorConsent.declined);
    });

    testWidgets('leaving without answering records nothing', (tester) async {
      // The distinction the stored value is a tri-state to keep: a
      // screen somebody backed out of is not a no, and the triggers in
      // `advisor.md` §7 have to be able to tell them apart.
      await _pump(tester, AdvisorScreen(topic: MatchTopic(_match)));
      expect(await _stored(), AdvisorConsent.unasked);
    });

    testWidgets('declining leaves the offer open', (tester) async {
      await _pump(
        tester,
        AdvisorScreen(topic: MatchTopic(_match)),
        prefs: const {'sanctum.advisor_consent': 'declined'},
      );
      // Re-offerable: the entry points still work and still lead here.
      // What must not happen is a conversation opening anyway.
      expect(find.text('Before you ask'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('on the narrowest phone', () {
    testWidgets('lays out without overflowing', (tester) async {
      // The suite renders tall so that every section and both buttons
      // are on screen at once. This is the shape that actually ships:
      // four cards of prose, a caption and two full-width buttons at
      // 375pt, in a locale that runs a quarter longer than English.
      await _pump(tester, AdvisorScreen(topic: MatchTopic(_match)));
      tester.view.physicalSize = const Size(1125, 2436);
      tester.view.devicePixelRatio = 3;
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Before you ask'), findsOneWidget);
    });
  });

  group('from settings', () {
    testWidgets('a granted consent can be read back and withdrawn', (
      tester,
    ) async {
      await _pump(
        tester,
        const AdvisorConsentScreen(),
        prefs: const {
          'sanctum.advisor_consent': 'granted',
          'sanctum.advisor_consent_version': 1,
        },
      );
      expect(find.textContaining('The advisor is on'), findsOneWidget);

      await tester.tap(find.text('Stop sending'));
      await _frames(tester);
      // The confirmation, then the same label inside it.
      await tester.tap(find.text('Stop sending').last);
      await _frames(tester);

      expect(await _stored(), AdvisorConsent.declined);
      expect(find.text('Agree and continue'), findsOneWidget);
    });
  });

  group('the second gate', () {
    /// A build that *does* have a proxy compiled in — which no build has
    /// today, and which is the only interesting case here.
    ProviderContainer containerWith(AdvisorConsent consent) {
      SharedPreferences.setMockInitialValues({
        if (consent != AdvisorConsent.unasked)
          'sanctum.advisor_consent': consent.name,
        'sanctum.advisor_consent_version': 1,
      });
      final container = ProviderContainer(
        overrides: [
          advisorEndpointProvider.overrideWithValue(
            'https://example.test/functions/v1/advisor',
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('an unanswered disclosure means no proxy transport', () async {
      final container = containerWith(AdvisorConsent.unasked);
      expect(
        await container.read(chatTransportProvider.future),
        isA<ScriptedChatTransport>(),
      );
    });

    test('a declined one means no proxy transport either', () async {
      final container = containerWith(AdvisorConsent.declined);
      expect(
        await container.read(chatTransportProvider.future),
        isA<ScriptedChatTransport>(),
      );
    });

    test('a granted one is what builds it', () async {
      final container = containerWith(AdvisorConsent.granted);
      expect(
        await container.read(chatTransportProvider.future),
        isA<ProxyChatTransport>(),
      );
    });
  });

  group('the disclosure it was given against', () {
    test('a yes to an older one is asked again', () async {
      // Consent is to a specific set of facts. Change who receives the
      // data and the agreement on file was to something else.
      SharedPreferences.setMockInitialValues({
        'sanctum.advisor_consent': 'granted',
        'sanctum.advisor_consent_version': AdvisorDisclosure.current - 1,
      });
      expect(await _stored(), AdvisorConsent.unasked);
    });

    test('a no to an older one stays a no', () async {
      // Somebody who declined does not want to be asked once per
      // release, and the entry points are still there if they change
      // their mind.
      SharedPreferences.setMockInitialValues({
        'sanctum.advisor_consent': 'declined',
        'sanctum.advisor_consent_version': AdvisorDisclosure.current - 1,
      });
      expect(await _stored(), AdvisorConsent.declined);
    });

    test('recording one stamps the current version', () async {
      SharedPreferences.setMockInitialValues(const {});
      await const PreferencesSettingsRepository().recordAdvisorConsent(
        granted: true,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt('sanctum.advisor_consent_version'),
        AdvisorDisclosure.current,
      );
    });
  });
}
