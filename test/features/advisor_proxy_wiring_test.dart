import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sanctum/src/data/catalog/content_catalog.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/database/sanctum_database.dart';
import 'package:sanctum/src/data/repositories/subscription_repository.dart';
import 'package:sanctum/src/domain/models/advisor_topic.dart';
import 'package:sanctum/src/domain/models/birth_time.dart';
import 'package:sanctum/src/domain/models/celebrity.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/models/ritual.dart';
import 'package:sanctum/src/domain/models/sound_session.dart';
import 'package:sanctum/src/domain/services/compatibility_composer.dart';
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

/// A client that answers like the deployed Edge Function.
///
/// Not the scripted transport and not an overridden `chatTransport`:
/// the thing under test here is the wiring *between* them — the real
/// `chatTransportProvider`, building a real `ProxyChatTransport`,
/// reached the way `AdvisorController.ask` reaches it.
http.Client _answering(List<String> frames, {int status = 200}) {
  return MockClient.streaming((request, bodyStream) async {
    return http.StreamedResponse(
      Stream.fromIterable([
        for (final frame in frames) utf8.encode('data: $frame\n\n'),
      ]),
      status,
      headers: {'content-type': 'text/event-stream'},
    );
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required http.Client client,
  String endpoint = 'https://example.test/functions/v1/advisor',
}) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    'sanctum.advisor_consent': 'granted',
    'sanctum.advisor_consent_version': 1,
  });

  final db = SanctumDatabase.memory();
  addTearDown(db.close);

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
        // The two things a real build supplies, and nothing else. In
        // particular `chatTransportProvider` is NOT overridden.
        advisorEndpointProvider.overrideWithValue(endpoint),
        httpClientProvider.overrideWithValue(client),
      ],
      child: testApp(AdvisorScreen(topic: MatchTopic(_match))),
    ),
  );
  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
}

Future<void> _ask(WidgetTester tester, String question) async {
  await tester.enterText(find.byType(TextField), question);
  await tester.testTextInput.receiveAction(TextInputAction.send);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('an answer from the proxy reaches the screen', (tester) async {
    // The end-to-end path the app takes in a build with a URL compiled
    // in: consent granted, `chatTransportProvider` resolving to a real
    // `ProxyChatTransport`, and `AdvisorController.ask` awaiting it.
    // Every layer of this was tested except the seam between them, and
    // the seam is what an `ADVISOR_PROXY_URL` build first exercises.
    await _pump(
      tester,
      client: _answering([
        '{"delta":"Because "}',
        '{"delta":"of Saturn."}',
        '{"done":true}',
      ]),
    );

    await _ask(tester, 'Why is it like this?');

    expect(find.text('Because of Saturn.'), findsOneWidget);
  });

  testWidgets('a proxy that says nothing says so', (tester) async {
    // A 401 from the platform key check is the likeliest first failure
    // of a freshly pointed build, and it arrives as an empty body
    // rather than an SSE error frame. It must surface as the failure
    // bar and not as a question that sits there forever.
    await _pump(tester, client: _answering(const [], status: 401));

    await _ask(tester, 'Why is it like this?');

    expect(find.textContaining('did not get through'), findsOneWidget);
  });
}
