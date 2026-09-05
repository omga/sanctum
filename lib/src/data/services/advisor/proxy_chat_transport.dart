import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/domain/models/advisor_context.dart';
import 'package:sanctum/src/domain/models/conversation.dart';
import 'package:sanctum/src/domain/services/chat_transport.dart';

/// Talks to Sanctum's advisor proxy.
///
/// ## Why there is a proxy at all
///
/// The model API key cannot ship in the binary. That is the whole
/// reason — `advisor.md` §5 — and it is why this class is thin: the
/// prompt, the vendor and the rate limits all live on the far side,
/// where they can be corrected without a store release.
///
/// ## What travels
///
/// [AdvisorContext.facts], the language to answer in, and the
/// conversation so far. Nothing else, and the payload type is built so
/// that nothing else *can* — see that class. The proxy re-validates the
/// same rules, so a future bug on this side is rejected rather than
/// forwarded to a third party.
///
/// The install id in the header is not a login. Sanctum has no accounts
/// and `handoff.md` rejects adding one; this is the key the proxy's rate
/// limiter counts on, and it identifies an installation rather than a
/// person.
///
/// ## The wire format is ours, not the vendor's
///
/// The proxy translates whatever the model streams into one shape:
///
/// ```text
/// data: {"delta":"some text"}
/// data: {"done":true}
/// data: {"error":"rate_limited"}
/// ```
///
/// So switching models is a server change, and this parser never learns
/// a vendor's event names.
class ProxyChatTransport implements ChatTransport {
  /// Creates a transport pointed at [endpoint].
  const ProxyChatTransport({
    required this.endpoint,
    required this.installId,
    required this.client,
    required this.anonKey,
    this.timeout = const Duration(seconds: 45),
  });

  /// The proxy's URL.
  final Uri endpoint;

  /// Identifies the installation to the rate limiter. Not a person.
  final String installId;

  /// Supabase's anon key, when the function is deployed behind one.
  final String anonKey;

  /// How long to wait for the *first* byte.
  ///
  /// Not for the whole answer: a long answer streaming steadily is
  /// working, and cancelling it at an arbitrary total would look like a
  /// failure to somebody watching words appear.
  final Duration timeout;

  /// The HTTP client, injected so the transport is testable against a
  /// local server rather than the internet.
  final http.Client client;

  @override
  Stream<ChatChunk> send({
    required Conversation conversation,
    required List<ChatMessage> history,
    required AdvisorContext? context,
  }) async* {
    if (context == null) {
      // Every surface that can open a conversation builds one. A null
      // here is a programming error rather than a user-visible state,
      // and sending an unanchored question would produce exactly the
      // generic answer this feature exists to avoid.
      yield const ChatFailed(
        AdvisorFailure(
          'No chart context for this conversation.',
          kind: AdvisorFailureKind.refused,
        ),
      );
      return;
    }

    final request = http.Request('POST', endpoint)
      ..headers.addAll({
        'content-type': 'application/json',
        'accept': 'text/event-stream',
        'x-sanctum-install': installId,
        if (anonKey.isNotEmpty) 'authorization': 'Bearer $anonKey',
        if (anonKey.isNotEmpty) 'apikey': anonKey,
      })
      ..body = jsonEncode({
        'surface': context.surface,
        'languageCode': context.languageCode,
        'facts': context.facts,
        'messages': [
          for (final message in history)
            {'author': message.author.name, 'body': message.body},
        ],
      });

    http.StreamedResponse response;
    try {
      response = await client.send(request).timeout(timeout);
    } on TimeoutException {
      yield const ChatFailed(
        AdvisorFailure(
          'The advisor did not answer in time.',
          kind: AdvisorFailureKind.offline,
        ),
      );
      return;
    } on Exception catch (error) {
      // No connection, DNS, TLS. All the same thing to the user, and
      // all recoverable by trying again later.
      yield ChatFailed(
        AdvisorFailure(
          'Could not reach the advisor.',
          kind: AdvisorFailureKind.offline,
          cause: error,
        ),
      );
      return;
    }

    // A non-200 still carries an SSE error frame, so the body is read
    // either way and the status is only a fallback.
    var sawDelta = false;
    var finished = false;

    await for (final line in _lines(response.stream)) {
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty) continue;

      final Map<String, dynamic> event;
      try {
        event = jsonDecode(payload) as Map<String, dynamic>;
      } on FormatException {
        // A frame that is not JSON is the proxy or the network being
        // odd; skipping it beats failing an answer that is otherwise
        // arriving.
        continue;
      }

      if (event['delta'] case final String delta) {
        sawDelta = true;
        yield ChatDelta(delta);
      } else if (event['error'] case final String kind) {
        yield ChatFailed(
          AdvisorFailure('The advisor refused.', kind: _kindFor(kind)),
        );
        return;
      } else if (event['done'] == true) {
        finished = true;
        yield const ChatCompleted();
        return;
      }
    }

    // The stream ended without a `done` frame: a dropped connection
    // mid-answer, or a proxy that died. Deliberately *not* completed —
    // an answer that stopped halfway has not been delivered, and
    // completing here would spend the turn for it.
    if (!finished) {
      yield ChatFailed(
        AdvisorFailure(
          sawDelta
              ? 'The answer stopped part-way.'
              : 'The advisor sent nothing.',
          kind: response.statusCode == 429
              ? AdvisorFailureKind.rateLimited
              : AdvisorFailureKind.server,
        ),
      );
    }
  }

  /// Splits a byte stream into lines, tolerating chunk boundaries.
  ///
  /// An SSE frame is not guaranteed to arrive whole: the network splits
  /// wherever it likes, and a naive `utf8.decode` per chunk both breaks
  /// multi-byte characters — every non-English locale this app ships —
  /// and loses half-lines.
  static Stream<String> _lines(Stream<List<int>> bytes) =>
      bytes.transform(utf8.decoder).transform(const LineSplitter());

  static AdvisorFailureKind _kindFor(String kind) => switch (kind) {
    'rate_limited' => AdvisorFailureKind.rateLimited,
    'bad_request' => AdvisorFailureKind.refused,
    _ => AdvisorFailureKind.server,
  };
}
