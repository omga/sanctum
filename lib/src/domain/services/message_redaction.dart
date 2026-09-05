/// Strips names out of anything on its way to the advisor.
///
/// ## Why the type system is not enough on its own
///
/// `AdvisorContext` guarantees the *computed* half of a request carries
/// no name, because no constructor accepts one. It cannot make the same
/// guarantee about the other half, which is a text box the user types
/// into — and the first thing somebody asks about a pairing is "why does
/// Alex keep doing this".
///
/// So the promise in `handoff.md` §3 needs one more thing: outbound text
/// is rewritten to remove the names the app already knows before it
/// leaves the device. The user still asks their question and still reads
/// "Alex" on screen; the model is told "them".
///
/// ## What this is not
///
/// Not PII detection, and it does not pretend to be. It removes the
/// specific strings this app stored — the user's own name from
/// onboarding, and both names on the pairing being discussed — because
/// those are the ones the app is responsible for, and they are the ones
/// that would turn a computed chart into an identified person.
///
/// A user determined to type a surname, an address and a phone number
/// into a chat box can do so, and no client-side pass fixes that. The
/// consent screen says what leaves the device (`advisor.md` §1) so that
/// this is an informed choice rather than a surprise.
abstract final class MessageRedaction {
  /// What a redacted name is replaced with.
  ///
  /// A pronoun-free word on purpose. The app never learns anyone's
  /// gender and must not invent one on the way out — an answer written
  /// about "him" because the redactor guessed is worse than one written
  /// about "them".
  static const String placeholder = 'them';

  /// What the user's own name is replaced with.
  static const String selfPlaceholder = 'me';

  /// Rewrites [text] with every name in [names] replaced.
  ///
  /// [names] is `(name, replacement)` pairs so the user's own name can
  /// become "me" while the other person becomes "them" — a question that
  /// reads "why does them ignore me" is worse than one that reads "why
  /// do they ignore me", and the difference is which side was matched.
  ///
  /// Matching is case-insensitive and bounded to whole words, so a
  /// person called Al does not turn "always" into "themways".
  static String redact(String text, {required Map<String, String> names}) {
    var result = text;
    // Longest first: a person stored as "Alex Smith" must be replaced
    // whole rather than leaving "Smith" behind after "Alex" matched.
    final ordered = names.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final name in ordered) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      final pattern = RegExp(
        r'(?<![\p{L}\p{N}])' + RegExp.escape(trimmed) + r'(?![\p{L}\p{N}])',
        caseSensitive: false,
        unicode: true,
      );
      result = result.replaceAll(pattern, names[name]!);
    }
    return result;
  }

  /// Whether [text] still contains any of [names].
  ///
  /// The assertion a test makes, and the assertion the send path makes
  /// before handing anything to a transport. Cheap enough to run on
  /// every message, and the one check that would catch a redactor bug
  /// before a user's name reached a third party.
  static bool containsAny(String text, Iterable<String> names) {
    for (final name in names) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      final pattern = RegExp(
        r'(?<![\p{L}\p{N}])' + RegExp.escape(trimmed) + r'(?![\p{L}\p{N}])',
        caseSensitive: false,
        unicode: true,
      );
      if (pattern.hasMatch(text)) return true;
    }
    return false;
  }
}
