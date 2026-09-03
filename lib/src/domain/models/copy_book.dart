/// The reading copy, in the reader's language.
///
/// ## Why the prose is not in ARB with everything else
///
/// `domain/` imports nothing but pure Dart — no Flutter — and
/// `AppLocalizations` is a Flutter class. The composers are pure domain
/// services, so they cannot reach it.
///
/// That is a constraint, but it points at the right split anyway. The
/// ARB holds UI chrome: buttons, labels, headings, the words around the
/// product. This holds the *content* — the forty-odd paragraphs that are
/// the thing people are actually paying for. They are edited by
/// different people, at different times, and reviewed differently: a
/// mistranslated button is a bug, and a mistranslated reading is a worse
/// product. Keeping them in separate files makes that visible.
///
/// It also means content ships on its own schedule. `copy.json` sits
/// beside the rest of the catalogue under `assets/content/<language>/`
/// and falls back to English per file, so a locale can ship its quiz and
/// its readings before its oracle deck is finished.
///
/// ## A flat dictionary, on purpose
///
/// Keys are dotted paths built from the enums that select them —
/// `compatibility.dynamic.trine`, `transit.pair.saturn.venus`. A
/// structured model per composer would type-check more of this, and
/// would also hand a translator a nested schema to break. A flat
/// key/value file is the shape every translation tool already speaks.
///
/// The typing that matters is kept: [get] throws rather than returning
/// an empty string, so a missing key surfaces as a loud failure with the
/// key in the message instead of a blank line in a published post.
class CopyBook {
  /// Creates a copy book over [entries].
  const CopyBook(this.entries);

  /// An empty book. Only useful as a placeholder in tests that do not
  /// compose anything.
  static const CopyBook empty = CopyBook({});

  /// Every line, by dotted key.
  final Map<String, String> entries;

  /// The line at [key].
  ///
  /// Throws when it is missing. Bundled content is a build-time
  /// artefact, so an absent key is a mistake in the repository rather
  /// than a condition a user can cause — and the loudest possible
  /// failure is the cheapest one to find.
  String get(String key) {
    final value = entries[key];
    if (value == null) {
      throw StateError('Missing copy for "$key"');
    }
    return value;
  }

  /// The line at [key], or null when it is absent.
  ///
  /// For the genuinely optional case — a transiting body that has no
  /// note written for it — where absence is a content decision rather
  /// than an omission.
  String? maybe(String key) => entries[key];

  /// Whether [key] has a line.
  bool has(String key) => entries.containsKey(key);

  /// The line at [key] with `{placeholder}` slots filled from [values].
  ///
  /// A deliberately tiny substitution — no plurals, no gender, no
  /// number formatting. Anything needing those belongs in the ARB,
  /// where ICU handles them properly and a translator's tooling
  /// understands them. What lives here is prose with a name or a count
  /// dropped into it, and the sentence is written per language anyway,
  /// so the placeholder can sit wherever that language needs it.
  String format(String key, Map<String, Object?> values) {
    var line = get(key);
    for (final entry in values.entries) {
      line = line.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return line;
  }
}
