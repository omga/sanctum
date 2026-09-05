import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/data/services/advisor/proxy_chat_transport.dart';
import 'package:sanctum/src/domain/models/advisor_context.dart';
import 'package:sanctum/src/domain/models/birth_time.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/conversation.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/services/chat_transport.dart';
import 'package:sanctum/src/domain/services/compatibility_composer.dart';

import '../support/copy.dart';

/// A real HTTP server rather than a mocked client.
///
/// What this transport actually does is parse a byte stream into
/// frames, and the failures worth catching — a frame split across two
/// packets, a multi-byte character split down the middle, a connection
/// that dies part-way — only exist at that level. A mock returning a
/// tidy list of strings would test none of them.
class _Proxy {
  _Proxy(this._handler);

  final Future<void> Function(HttpRequest request) _handler;
  late HttpServer _server;

  final requests = <Map<String, dynamic>>[];
  final headers = <String, String>{};

  Future<Uri> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(
      _server.forEach((request) async {
        headers.clear();
        request.headers.forEach((name, values) {
          headers[name] = values.join(',');
        });
        final body = await utf8.decoder.bind(request).join();
        if (body.isNotEmpty) {
          requests.add(jsonDecode(body) as Map<String, dynamic>);
        }
        await _handler(request);
      }),
    );
    return Uri.parse('http://127.0.0.1:${_server.port}/advisor');
  }

  Future<void> stop() => _server.close(force: true);
}

/// Writes SSE frames the way the Edge Function does.
Future<void> _stream(
  HttpRequest request,
  List<String> frames, {
  int status = 200,
  bool close = true,
}) async {
  request.response.statusCode = status;
  request.response.headers.contentType = ContentType('text', 'event-stream');
  for (final frame in frames) {
    request.response.write('data: $frame\n\n');
    await request.response.flush();
  }
  if (close) await request.response.close();
}

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
  now: DateTime(2026, 9, 5),
  copy: _copy,
);

final _conversation = Conversation(
  id: 'c1',
  kind: ConversationKind.advisor,
  subject: MatchSubject(_match.id),
  startedAt: DateTime(2026, 9, 5),
);

final _history = [
  ChatMessage(
    id: 'm1',
    conversationId: 'c1',
    author: MessageAuthor.you,
    body: 'Why is it like this?',
    at: DateTime(2026, 9, 5),
  ),
];

Future<List<ChatChunk>> _collect(
  Uri endpoint,
  http.Client client, {
  AdvisorContext? context,
}) => ProxyChatTransport(
  endpoint: endpoint,
  installId: 'install-abcdef',
  apiKey: 'sb_publishable_abc123',
  client: client,
).send(
  conversation: _conversation,
  history: _history,
  context:
      context ?? AdvisorContext.forMatch(_match, languageCode: 'en'),
).toList();

String _text(List<ChatChunk> chunks) =>
    chunks.whereType<ChatDelta>().map((d) => d.text).join();

void main() {
  late http.Client client;

  setUp(() => client = http.Client());
  tearDown(() => client.close());

  group('a good answer', () {
    test('streams deltas and completes', () async {
      final proxy = _Proxy(
        (request) => _stream(request, [
          '{"delta":"Because "}',
          '{"delta":"of Saturn."}',
          '{"done":true}',
        ]),
      );
      final endpoint = await proxy.start();
      addTearDown(proxy.stop);

      final chunks = await _collect(endpoint, client);
      expect(_text(chunks), 'Because of Saturn.');
      expect(chunks.last, isA<ChatCompleted>());
    });

    test('survives a frame split across packets', () async {
      // The failure a mocked client cannot produce: SSE frames are not
      // guaranteed to arrive whole.
      final proxy = _Proxy((request) async {
        request.response.statusCode = 200;
        request.response.headers.contentType =
            ContentType('text', 'event-stream');
        request.response.write('data: {"delta":"half ');
        await request.response.flush();
        request.response.write('a frame"}\n\ndata: {"done":true}\n\n');
        await request.response.close();
      });
      final endpoint = await proxy.start();
      addTearDown(proxy.stop);

      expect(_text(await _collect(endpoint, client)), 'half a frame');
    });

    test('survives a multi-byte character split down the middle', () async {
      // Three of the four shipped locales are not Latin. A naive
      // `utf8.decode` per chunk mangles them at packet boundaries.
      final bytes = utf8.encode('data: {"delta":"Привіт"}\n\n');
      final proxy = _Proxy((request) async {
        request.response.statusCode = 200;
        request.response.headers.contentType =
            ContentType('text', 'event-stream');
        request.response.add(bytes.sublist(0, 20));
        await request.response.flush();
        request.response.add(bytes.sublist(20));
        request.response.write('data: {"done":true}\n\n');
        await request.response.close();
      });
      final endpoint = await proxy.start();
      addTearDown(proxy.stop);

      expect(_text(await _collect(endpoint, client)), 'Привіт');
    });

    test('ignores a frame that is not JSON', () async {
      final proxy = _Proxy(
        (request) => _stream(request, [
          'not json at all',
          '{"delta":"still fine"}',
          '{"done":true}',
        ]),
      );
      final endpoint = await proxy.start();
      addTearDown(proxy.stop);

      final chunks = await _collect(endpoint, client);
      expect(_text(chunks), 'still fine');
      expect(chunks.last, isA<ChatCompleted>());
    });
  });

  group('what is sent', () {
    test('carries the computed facts and the question', () async {
      final proxy = _Proxy(
        (request) => _stream(request, ['{"done":true}']),
      );
      final endpoint = await proxy.start();
      addTearDown(proxy.stop);
      await _collect(endpoint, client);

      final sent = proxy.requests.single;
      expect(sent['surface'], 'match');
      expect(sent['languageCode'], 'en');
      expect((sent['facts']! as Map)['overall'], _match.overall);
      expect((sent['messages']! as List).single, {
        'author': 'you',
        'body': 'Why is it like this?',
      });
    });

    test('carries no name, at any depth', () async {
      // The assertion this whole feature rests on, made at the last
      // point before bytes leave the device.
      final proxy = _Proxy(
        (request) => _stream(request, ['{"done":true}']),
      );
      final endpoint = await proxy.start();
      addTearDown(proxy.stop);
      await _collect(endpoint, client);

      final body = jsonEncode(proxy.requests.single);
      expect(body, isNot(contains('Andrew')));
      expect(body, isNot(contains('Alex')));
      expect(body, isNot(contains('1990')));
    });

    test('identifies the installation, not a person', () async {
      final proxy = _Proxy(
        (request) => _stream(request, ['{"done":true}']),
      );
      final endpoint = await proxy.start();
      addTearDown(proxy.stop);
      await _collect(endpoint, client);

      expect(proxy.headers['x-sanctum-install'], 'install-abcdef');
      // A publishable key travels on `apikey`, never as a bearer token:
      // it is not a JWT, and anything verifying it as one fails.
      expect(proxy.headers['apikey'], 'sb_publishable_abc123');
      expect(proxy.headers.containsKey('authorization'), isFalse);
    });


  });

  group('a legacy anon key', () {
    test('still travels as a bearer token, because it is a JWT', () async {
      final proxy = _Proxy(
        (request) => _stream(request, ['{"done":true}']),
      );
      final endpoint = await proxy.start();
      addTearDown(proxy.stop);

      await ProxyChatTransport(
        endpoint: endpoint,
        installId: 'install-abcdef',
        apiKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.legacy',
        client: client,
      ).send(
        conversation: _conversation,
        history: _history,
        context: AdvisorContext.forMatch(_match, languageCode: 'en'),
      ).toList();

      expect(proxy.headers['apikey'], startsWith('eyJ'));
      expect(proxy.headers['authorization'], startsWith('Bearer eyJ'));
    });
  });

  group('failure', () {
    test('an error frame becomes the matching kind', () async {
      for (final (frame, expected) in [
        ('rate_limited', AdvisorFailureKind.rateLimited),
        ('bad_request', AdvisorFailureKind.refused),
        ('server', AdvisorFailureKind.server),
      ]) {
        final proxy = _Proxy(
          (request) => _stream(request, ['{"error":"$frame"}'], status: 429),
        );
        final endpoint = await proxy.start();
        final chunks = await _collect(endpoint, client);
        await proxy.stop();

        final failure = (chunks.single as ChatFailed).failure;
        expect((failure as AdvisorFailure).kind, expected, reason: frame);
      }
    });

    test('an unreachable proxy reads as offline', () async {
      // Port 1 on loopback, which nothing is listening on.
      final chunks = await _collect(
        Uri.parse('http://127.0.0.1:1/advisor'),
        client,
      );
      final failure = (chunks.single as ChatFailed).failure;
      expect((failure as AdvisorFailure).kind, AdvisorFailureKind.offline);
    });

    test('a stream that stops part-way does not complete', () async {
      // The money rule: an answer that arrived halfway has not been
      // delivered, so the turn must not be spent for it.
      final proxy = _Proxy((request) async {
        request.response.statusCode = 200;
        request.response.headers.contentType =
            ContentType('text', 'event-stream');
        request.response.write('data: {"delta":"half an ans');
        await request.response.flush();
        await request.response.close();
      });
      final endpoint = await proxy.start();
      addTearDown(proxy.stop);

      final chunks = await _collect(endpoint, client);
      expect(chunks.whereType<ChatCompleted>(), isEmpty);
      expect(chunks.last, isA<ChatFailed>());
    });

    test('a conversation with no context is refused before it is sent', () {
      // Nothing should reach the network at all, so there is no server
      // in this test on purpose.
      return ProxyChatTransport(
        endpoint: Uri.parse('http://127.0.0.1:1/advisor'),
        installId: 'install-abcdef',
        apiKey: '',
        client: client,
      )
          .send(
            conversation: _conversation,
            history: _history,
            context: null,
          )
          .toList()
          .then((chunks) {
            final failure = (chunks.single as ChatFailed).failure;
            expect(
              (failure as AdvisorFailure).kind,
              AdvisorFailureKind.refused,
            );
          });
    });
  });
}
