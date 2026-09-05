import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/services/message_redaction.dart';

const Map<String, String> _names = {
  'Alex': MessageRedaction.placeholder,
  'Ksenia': MessageRedaction.selfPlaceholder,
};

String _redact(String text) =>
    MessageRedaction.redact(text, names: _names);

void main() {
  group('what the user types', () {
    test("loses the other person's name", () {
      expect(
        _redact('Why does Alex keep doing this?'),
        'Why does them keep doing this?',
      );
    });

    test('loses their own name too, as "me"', () {
      // Two placeholders rather than one: "why does them ignore them" is
      // a worse question than the one that was asked.
      expect(
        _redact('Alex never texts Ksenia first'),
        'them never texts me first',
      );
    });

    test('is matched regardless of case', () {
      expect(_redact('alex and ALEX'), 'them and them');
    });

    test('keeps everything that is not a name', () {
      const question = 'Why is our Trust only 43 when the rest is high?';
      expect(_redact(question), question);
    });
  });

  group('word boundaries', () {
    test('a short name does not eat the middle of a word', () {
      // The bug this exists to prevent: a person called Al turning
      // "always" into "themways".
      expect(
        MessageRedaction.redact(
          'Al always talks about Al',
          names: {'Al': MessageRedaction.placeholder},
        ),
        'them always talks about them',
      );
    });

    test('punctuation still ends a name', () {
      expect(_redact('Alex, why?'), 'them, why?');
      expect(_redact('(Alex)'), '(them)');
    });

    test('a longer name is replaced whole', () {
      // Replacing "Alex" first would leave "Smith" behind.
      expect(
        MessageRedaction.redact(
          'Alex Smith never replies',
          names: {
            'Alex Smith': MessageRedaction.placeholder,
            'Alex': MessageRedaction.placeholder,
          },
        ),
        'them never replies',
      );
    });

    test('works on non-Latin names', () {
      // Three of the four shipped locales are not written in Latin
      // script, and a redactor that only guards English is not a
      // redactor.
      expect(
        MessageRedaction.redact(
          'Чому Олена мовчить?',
          names: {'Олена': MessageRedaction.placeholder},
        ),
        'Чому them мовчить?',
      );
    });
  });

  group('the check that runs before every send', () {
    test('catches a name that survived', () {
      expect(
        MessageRedaction.containsAny('Why does Alex do that', ['Alex']),
        isTrue,
      );
    });

    test('passes text that has been redacted', () {
      expect(
        MessageRedaction.containsAny(_redact('Why does Alex do that'), [
          'Alex',
          'Ksenia',
        ]),
        isFalse,
      );
    });

    test('ignores an empty stored name', () {
      // A user who skipped the name question has an empty string stored.
      // Treating that as a name to match would redact every character.
      expect(MessageRedaction.containsAny('anything at all', ['', '  ']),
          isFalse);
      expect(
        MessageRedaction.redact('anything at all', names: {'': 'them'}),
        'anything at all',
      );
    });
  });
}
