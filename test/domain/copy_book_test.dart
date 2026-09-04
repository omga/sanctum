import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';

void main() {
  group('a book with no fallback', () {
    const book = CopyBook({'a.one': 'first'});

    test('returns what it has', () {
      expect(book.get('a.one'), 'first');
      expect(book.maybe('a.one'), 'first');
      expect(book.has('a.one'), isTrue);
    });

    test('throws with the key in the message when it does not', () {
      // Bundled content is a build artefact, so an absent key is a
      // mistake in the repository rather than something a user can
      // cause — and the loudest failure is the cheapest to find.
      expect(
        () => book.get('a.missing'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('a.missing'),
          ),
        ),
      );
      expect(book.maybe('a.missing'), isNull);
      expect(book.has('a.missing'), isFalse);
    });
  });

  group('a translated book backed by English', () {
    const book = CopyBook(
      {'a.one': 'первый'},
      fallback: {'a.one': 'first', 'a.two': 'second'},
    );

    test('prefers the locale over the fallback', () {
      expect(book.get('a.one'), 'первый');
    });

    test('falls back per key rather than failing', () {
      // The case this exists for: new copy lands in English first, and
      // until a translator reaches it every other locale has a file
      // that exists and is missing keys. Without this that is not a
      // missing translation, it is a StateError thrown at a real user.
      expect(book.get('a.two'), 'second');
      expect(book.has('a.two'), isTrue);
    });

    test('still throws when neither has the key', () {
      // Copy that was never authored at all must stay loud.
      expect(() => book.get('a.three'), throwsStateError);
      expect(book.has('a.three'), isFalse);
    });

    test('formats a fallback line too', () {
      const named = CopyBook({}, fallback: {'greet': 'Hello, {name}.'});
      expect(named.format('greet', {'name': 'Alex'}), 'Hello, Alex.');
    });
  });
}
