import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every locale ships every line, and with the same placeholders.
///
/// ## Why this is not covered by the fallback
///
/// `CopyBook` falls back to English per key, so a missing translation
/// degrades to a well-written English sentence rather than crashing. That
/// is the right runtime behaviour and it is also why a gap is invisible:
/// nothing fails, nobody notices, and a paying reader in Kyiv quietly
/// gets half a document in a language they did not choose.
///
/// So the gap is made visible here instead. If a locale is deliberately
/// mid-translation, this test is the place to say so — out loud, with a
/// list — rather than discovering it from a review.
void main() {
  const locales = ['uk', 'ru', 'es'];

  Map<String, String> copyFor(String code) {
    final raw = File('assets/content/$code/copy.json').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final entry in decoded.entries)
        if (!entry.key.startsWith('@')) entry.key: entry.value! as String,
    };
  }

  /// `{name}`-style slots, which must survive translation exactly.
  Set<String> slotsIn(String line) => RegExp(r'\{(\w+)\}')
      .allMatches(line)
      .map((m) => m.group(1)!)
      .toSet();

  final english = copyFor('en');

  test('English is the complete set', () {
    // Everything else is measured against it, so an empty read here
    // would make every assertion below vacuously pass.
    expect(english, isNotEmpty);
    expect(english.keys.where((k) => k.startsWith('report.')), hasLength(58));
  });

  for (final code in locales) {
    group(code, () {
      final copy = copyFor(code);

      test('has every line English has', () {
        final missing = english.keys.where((k) => !copy.containsKey(k))
            .toList()
          ..sort();
        expect(
          missing,
          isEmpty,
          reason:
              '$code is missing ${missing.length} lines. They will fall '
              'back to English at runtime rather than fail, which is why '
              'this test exists: ${missing.take(10).join(', ')}',
        );
      });

      test('has no line English does not', () {
        // A key nobody reads is either a typo or a leftover from copy
        // that was removed — both are dead weight a translator is still
        // being asked to maintain.
        final extra = copy.keys.where((k) => !english.containsKey(k))
            .toList()
          ..sort();
        expect(extra, isEmpty, reason: extra.join(', '));
      });

      test('keeps every placeholder', () {
        // The substitution is a plain `replaceAll`, so a translated
        // `{nombre}` is not a broken build — it is a literal `{name}`
        // printed to a user inside a sentence they paid for.
        for (final entry in english.entries) {
          final translated = copy[entry.key];
          if (translated == null) continue;
          expect(
            slotsIn(translated),
            slotsIn(entry.value),
            reason: '${entry.key} in $code',
          );
        }
      });
    });
  }

  test('no ARB string is left untranslated', () {
    // `flutter gen-l10n` writes this file on every build. Empty is the
    // whole assertion; the ARB half of the app has the same failure mode
    // as the content half and gets the same guard.
    final file = File('lib/src/l10n/untranslated.json');
    if (!file.existsSync()) return;

    final raw = file.readAsStringSync().trim();
    if (raw.isEmpty) return;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    for (final entry in decoded.entries) {
      expect(
        entry.value as List<dynamic>,
        isEmpty,
        reason: '${entry.key} has untranslated strings',
      );
    }
  });
}
