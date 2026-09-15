import 'dart:async';

import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/domain/models/advisor_context.dart';
import 'package:sanctum/src/domain/models/conversation.dart';
import 'package:sanctum/src/domain/services/chat_transport.dart';

/// A [ChatTransport] that answers from a script, with no network.
///
/// ## Why this ships, and keeps shipping
///
/// `advisor.md` §8 builds the entire conversation UI on this before a
/// proxy exists: the screen, the streaming render, the entry points and
/// the gating are all buildable, demoable and testable with no API key,
/// no deployment and no cost per run.
///
/// It is not scaffolding to be deleted afterwards. It stays, for two
/// reasons that do not go away:
///
/// * **Widget tests need a transport that is fast and deterministic.**
///   A test that hits a real model is slow, flaky, costs money per run
///   and asserts on prose that changes when somebody edits a system
///   prompt. This one answers in scripted sentences with a fake clock.
/// * **Development on a plane.** The daily loop of this app works
///   offline by design; the advisor screen should be openable while
///   building the rest.
///
/// ## What it deliberately does *not* do
///
/// No intelligence. It does not parse the question, and it must not
/// grow a rules engine that pretends to — the moment this file starts
/// answering plausibly, somebody will demo it as the product and the
/// real one will never get funded. It answers with a fixed rotation.
///
/// That rotation is written copy, used to make content for social posts,
/// so tests assert on its shape and never on its wording.
class ScriptedChatTransport implements ChatTransport {
  /// Creates a scripted transport.
  ///
  /// [delayPerChunk] is the pause between chunks. Zero in tests, so a
  /// widget test does not spend real seconds watching a fake model type;
  /// a realistic value in a debug build, because streaming that arrives
  /// instantly does not exercise the UI states that streaming exists to
  /// produce.
  const ScriptedChatTransport({
    this.delayPerChunk = const Duration(milliseconds: 40),
    this.failEveryNthTurn,
  });

  /// Pause between emitted chunks.
  final Duration delayPerChunk;

  /// When set, every nth send fails instead of answering.
  ///
  /// The failure path is the one nobody builds until a user finds it:
  /// a half-written answer on screen, a spent turn that must not be
  /// spent (see [ChatFailed]), and a re-send that has to work. Being
  /// able to produce it on demand is why this knob exists.
  final int? failEveryNthTurn;

  @override
  Stream<ChatChunk> send({
    required Conversation conversation,
    required List<ChatMessage> history,
    required AdvisorContext? context,
  }) async* {
    final turn = history.where((m) => m.author == MessageAuthor.you).length;

    final nth = failEveryNthTurn;
    if (nth != null && nth > 0 && turn % nth == 0) {
      yield const ChatFailed(
        AdvisorFailure(
          'The scripted transport was asked to fail.',
          kind: AdvisorFailureKind.scripted,
        ),
      );
      return;
    }

    // Deterministic: the same conversation at the same turn always gets
    // the same answer, so a widget test can assert on it.
    // final answer = _script[(turn - 1).clamp(0, _script.length - 1)];
    final answer = _script[turn.clamp(0, _script.length - 1)];
    for (final word in answer.split(' ')) {
      if (delayPerChunk > Duration.zero) {
        await Future<void>.delayed(delayPerChunk);
      }
      yield ChatDelta('$word ');
    }
    yield const ChatCompleted();
  }
  static const String _first = '''
Liam is a Gemini. That's the explanation. That's the whole reading.\n
You've asked me this four times this week. My answer hasn't changed. Neither has Liam.\n
I pulled his chart three times hoping for a different result.''';

  static const String _second =
      'Your Venus is in Pisces. You fall in love with potential. '
      'Liam has enormous potential. '
      'Liam is also 26 and lives with his mother.';

  static const String _third =
      'You won\'t. But "seen 9:42 pm" will outlive us all.';
  static const String _fourth =
      "Anywhere Liam isn't. I've run the numbers twice.";
  static const String _fifth =
      "Nothing. That's the reading. "
      "Nothing is going to happen, and you're going to be fine.";
  static const String _six =
      'You already asked me this. I told you the truth. '
      'Would you like a lie instead?';

  // Not in [_script] yet.
  // ignore: unused_field
  static const String _seven =
      'Mercury went direct on Tuesday and you mistook that for a '
      'personality change in Liam. '
      'Venus is retrograde. So is your judgment. These are related. '
      'Immortality is not in your chart. '
      'This situationship, however, appears to be eternal. '
      'Your 12th house. Liam is in your 8th. Different addresses. '
      'Please stop visiting. '
      'He will watch your story. He will not reply. '
      'Saturday, approximately 11 pm.';

  /// The rotation. Written copy, used to make content for social posts:
  /// a test may pin its shape, never its wording.
  static const List<String> _script = [
    _first,
    _second,
    _third,
    _fourth,
    _fifth,
    _six,
  ];
}
