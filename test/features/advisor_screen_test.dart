import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/data/catalog/content_catalog.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/database/sanctum_database.dart';
import 'package:sanctum/src/data/services/advisor/scripted_chat_transport.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/domain/models/advisor_context.dart';
import 'package:sanctum/src/domain/models/birth_time.dart';
import 'package:sanctum/src/domain/models/celebrity.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/conversation.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/models/ritual.dart';
import 'package:sanctum/src/domain/models/sound_session.dart';
import 'package:sanctum/src/domain/services/chat_transport.dart';
import 'package:sanctum/src/domain/services/compatibility_composer.dart';
import 'package:sanctum/src/domain/services/conversation_budget.dart';
import 'package:sanctum/src/domain/services/conversation_starters.dart';
import 'package:sanctum/src/features/advisor/view/advisor_screen.dart';
import 'package:sanctum/src/features/advisor/view_model/advisor_view_model.dart';

import '../support/copy.dart';
import '../support/harness.dart';

final CopyBook _copy = loadEnglishCopy();

/// A pairing chosen because it is lopsided *and* has a weak facet, so
/// every branch of `ConversationStarters` has something to offer and the
/// suggestion row is exercised rather than merely present.
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

/// Records what a transport was handed, so a test can assert on what
/// would have left the device.
class _Recording implements ChatTransport {
  final sent = <List<ChatMessage>>[];

  @override
  Stream<ChatChunk> send({
    required Conversation conversation,
    required List<ChatMessage> history,
    required AdvisorContext? context,
  }) async* {
    sent.add(history);
    yield const ChatDelta('An answer.');
    yield const ChatCompleted();
  }
}

/// Fails once, then answers — the retry path.
class _FailsOnce implements ChatTransport {
  int calls = 0;

  @override
  Stream<ChatChunk> send({
    required Conversation conversation,
    required List<ChatMessage> history,
    required AdvisorContext? context,
  }) async* {
    calls++;
    if (calls == 1) {
      yield const ChatFailed(
        AdvisorFailure('nope', kind: AdvisorFailureKind.offline),
      );
      return;
    }
    yield const ChatDelta('Second time lucky.');
    yield const ChatCompleted();
  }
}

Future<void> _pump(
  WidgetTester tester, {
  ChatTransport? transport,
  Size size = const Size(1200, 2600),
  double pixelRatio = 1,
  SanctumDatabase? database,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);

  // A real database, in memory: the view model reads and writes through
  // the repository, so a fake would test the fake. A test that needs the
  // screen re-opened passes the same one twice.
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
        chatTransportProvider.overrideWith(
          (ref) async =>
              transport ??
              const ScriptedChatTransport(delayPerChunk: Duration.zero),
        ),
      ],
      child: testApp(AdvisorScreen(match: _match)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('opening a conversation', () {
    testWidgets('says an AI is answering', (tester) async {
      // EU AI Act Article 50. The line used to carry a second promise —
      // that the name and birth date stay on the phone — and that came
      // out with the rest of the absolute privacy copy: the claim now
      // belongs on the consent screen, where it can say precisely what
      // is sent rather than gesture at it in a caption.
      await _pump(tester);
      expect(find.textContaining('written by an AI'), findsOneWidget);
    });

    testWidgets('offers questions rather than a blank box', (tester) async {
      await _pump(tester);
      expect(find.text('SUGGESTED'), findsOneWidget);

      // Every question the domain selected is on screen, rendered with
      // its slots filled. Asserting the count alone would pass on three
      // chips reading "{facet}"; asserting a hard-coded sentence would
      // pin the test to one fixture's weakest facet.
      final starters = ConversationStarters.forMatch(_match);
      expect(starters, hasLength(3));
      for (final starter in starters) {
        final rendered = _copy.format(starter.displayKey, {
          'name': _match.them.name,
          if (starter.facet case final facet?) ...{
            'facet': facet.displayName,
            'score': _match.facets
                .firstWhere((scored) => scored.facet == facet)
                .score,
          },
        });
        expect(find.text(rendered), findsOneWidget, reason: rendered);
      }
    });

    testWidgets('names the other person in the suggestions', (tester) async {
      // The name is rendered locally and never sent — the entire point
      // of the display/prompt split. Asserted on a suggestion rather
      // than anywhere on screen, so the app bar title cannot satisfy it.
      await _pump(tester);
      expect(
        find.textContaining('further into this than I am'),
        findsOneWidget,
      );
    });
  });

  group('asking', () {
    testWidgets('shows the question, then the answer', (tester) async {
      await _pump(tester);
      await tester.enterText(find.byType(TextField), 'Why is it like this?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      expect(find.text('Why is it like this?'), findsOneWidget);
      expect(find.textContaining('scripted advisor'), findsOneWidget);
    });

    testWidgets('a tapped suggestion asks it', (tester) async {
      await _pump(tester);
      // Tap the card, not the label inside it: the label is not the
      // hit target, and tapping it only worked by falling through.
      final chip = find.ancestor(
        of: find.textContaining('Alex further into this'),
        matching: find.byType(GlassCard),
      );
      expect(chip, findsOneWidget);
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(find.textContaining('scripted advisor'), findsOneWidget);
    });

    testWidgets('sends no name to the transport, ever', (tester) async {
      // The assertion the feature rests on, made where a real send
      // happens rather than only in the domain test.
      final recording = _Recording();
      await _pump(tester, transport: recording);
      await tester.enterText(
        find.byType(TextField),
        'Why does Alex ignore Andrew?',
      );
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      final bodies = recording.sent.single.map((m) => m.body).join(' ');
      expect(bodies, isNot(contains('Alex')));
      expect(bodies, isNot(contains('Andrew')));
      expect(bodies, contains('them'));
      expect(bodies, contains('me'));

      // …while the screen still shows what the user actually wrote.
      expect(find.text('Why does Alex ignore Andrew?'), findsOneWidget);
    });

    testWidgets('redacts the whole history, not just the newest message', (
      tester,
    ) async {
      final recording = _Recording();
      await _pump(tester, transport: recording);
      for (final question in ['About Alex', 'And Alex again']) {
        await tester.enterText(find.byType(TextField), question);
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pumpAndSettle();
      }
      final second = recording.sent.last.map((m) => m.body).join(' ');
      expect(second, isNot(contains('Alex')));
    });
  });

  group('the budget', () {
    testWidgets('spends one turn per answered question', (tester) async {
      await _pump(tester);
      await tester.enterText(find.byType(TextField), 'One');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(AdvisorScreen));
      final container = ProviderScope.containerOf(element);
      expect(
        container
            .read(advisorControllerProvider(_match))
            .requireValue
            .conversation
            .turnsUsed,
        1,
      );
    });

    testWidgets('a failed send spends nothing', (tester) async {
      // A user who paid for ten answers and got nine plus an error has
      // been short-changed by one.
      await _pump(tester, transport: _FailsOnce());
      await tester.enterText(find.byType(TextField), 'One');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AdvisorScreen)),
      );
      expect(
        container
            .read(advisorControllerProvider(_match))
            .requireValue
            .conversation
            .turnsUsed,
        0,
      );
    });

    testWidgets('closes the composer once every question is spent', (
      tester,
    ) async {
      await _pump(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AdvisorScreen)),
      );
      for (var i = 0; i < ConversationBudget.turnsPerConversation; i++) {
        await tester.enterText(find.byType(TextField), 'Question $i');
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pumpAndSettle();
      }
      expect(
        container.read(advisorControllerProvider(_match)).requireValue.isSpent,
        isTrue,
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text('That was the last question'), findsOneWidget);
      // The transcript is not taken away with the composer.
      expect(find.text('Question 0'), findsOneWidget);
    });
  });

  group('on the narrowest phone', () {
    // The suite renders at 1200x2600, where nothing overflows and
    // nothing wraps. `label_budget_test.dart` exists because a layout
    // assertion that cannot fail is worse than none; this one can, and
    // the composer row plus a long disclosure is exactly the shape that
    // breaks at 375pt.
    testWidgets('lays out without overflowing', (tester) async {
      await _pump(tester, size: const Size(1125, 2436), pixelRatio: 3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('still lays out with a transcript and a spent budget', (
      tester,
    ) async {
      await _pump(tester, size: const Size(1125, 2436), pixelRatio: 3);
      for (var i = 0; i < ConversationBudget.turnsPerConversation; i++) {
        await tester.enterText(
          find.byType(TextField),
          'A question long enough to wrap onto a second line, number $i',
        );
        await tester.testTextInput.receiveAction(TextInputAction.send);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      expect(find.text('That was the last question'), findsOneWidget);
    });
  });

  group('storage', () {
    testWidgets('a transcript survives leaving and coming back', (
      tester,
    ) async {
      // The gap step 2 shipped with, closed. Every conversation used to
      // start empty because the notifier was the only place it lived.
      final db = SanctumDatabase.memory();
      addTearDown(db.close);

      await _pump(tester, database: db);
      await tester.enterText(find.byType(TextField), 'Does this persist?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // Tear the screen down entirely, then build it again over the
      // same database — which is what leaving the screen does.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await _pump(tester, database: db);

      expect(find.text('Does this persist?'), findsOneWidget);
      expect(find.textContaining('scripted advisor'), findsOneWidget);
    });

    testWidgets('so do the turns already spent', (tester) async {
      // Without this, a conversation would silently refill itself on
      // every visit and the cap would mean nothing.
      final db = SanctumDatabase.memory();
      addTearDown(db.close);

      await _pump(tester, database: db);
      await tester.enterText(find.byType(TextField), 'One');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await _pump(tester, database: db);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AdvisorScreen)),
      );
      expect(
        container
            .read(advisorControllerProvider(_match))
            .requireValue
            .conversation
            .turnsUsed,
        1,
      );
    });

    testWidgets('a screen opened and left writes nothing', (tester) async {
      // Otherwise the Ask tab fills up with conversations nobody had.
      final db = SanctumDatabase.memory();
      addTearDown(db.close);

      await _pump(tester, database: db);
      expect(await db.select(db.conversations).get(), isEmpty);
    });

    testWidgets('deleting clears the transcript and offers to start over', (
      tester,
    ) async {
      final db = SanctumDatabase.memory();
      addTearDown(db.close);

      await _pump(tester, database: db);
      await tester.enterText(find.byType(TextField), 'Forget this');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Forget this'), findsNothing);
      // Back to the suggestion row, not a blank screen.
      expect(find.text('SUGGESTED'), findsOneWidget);
      expect(await db.select(db.chatMessages).get(), isEmpty);
    });

    testWidgets('there is nothing to delete before anything is said', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });
  });

  group('failure', () {
    testWidgets('says what happened and keeps the question', (tester) async {
      await _pump(tester, transport: _FailsOnce());
      await tester.enterText(find.byType(TextField), 'Will this fail?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      expect(find.textContaining('No connection'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('retrying answers without retyping', (tester) async {
      final transport = _FailsOnce();
      await _pump(tester, transport: transport);
      await tester.enterText(find.byType(TextField), 'Will this fail?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Second time lucky.'), findsOneWidget);
      expect(transport.calls, 2);
      // One question in the transcript, not two.
      expect(find.text('Will this fail?'), findsOneWidget);
    });
  });
}
