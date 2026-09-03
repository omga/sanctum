import 'dart:ui';

/// Which locales Sanctum ships, and how one is chosen.
///
/// ## Why this is not just `MaterialApp.supportedLocales`
///
/// Two independent things need to agree on the answer. Flutter resolves
/// a locale for the *widget* tree — that is what `AppLocalizations`
/// reads. The content catalogue resolves one for the *asset* bundle,
/// outside any widget, when a repository loads JSON. If those two ever
/// disagree the app shows English chrome around translated readings, or
/// the reverse, and nothing in the type system would notice.
///
/// So both go through this one list, and both use [resolve]. It is pure
/// and takes the preferred locales as an argument, which also makes the
/// interesting cases — regional variants, an unsupported language,
/// an empty list — ordinary unit tests.
abstract final class SanctumLocales {
  /// The locale everything falls back to.
  ///
  /// Also the language the content is authored in, so a missing
  /// translation degrades to a sentence that is at least well written.
  static const Locale fallback = Locale('en');

  /// Every locale the app ships.
  ///
  /// Adding one here is not enough on its own — a locale also needs its
  /// ARB file, its `assets/content/<code>/` directory, and the asset
  /// directory declared in `pubspec.yaml`. See `handoff.md`.
  ///
  /// Ukrainian and Russian shipped together 2026-08-31 as Wave 1 — see
  /// the roadmap for why that pairing and not, say, Spanish first.
  /// Spanish followed the same day as Wave 2.
  ///
  /// Spanish is registered as plain `es`, not `es-419` or `es-ES`.
  /// [resolve] matches on language before country, so one entry serves
  /// every Spanish-speaking market; the copy is written LatAm-neutral
  /// for that reason — `tú` rather than `vos`, `ustedes` rather than
  /// `vosotros`. A market that eventually needs its own wording gets
  /// its own entry here and resolves ahead of this one.
  static const List<Locale> supported = [
    fallback,
    Locale('uk'),
    Locale('ru'),
    Locale('es'),
  ];

  /// The best supported match for [preferred], in priority order.
  ///
  /// Matches on language first and ignores the country, which is what
  /// this app wants: `es-419` and `es-ES` should both read the Spanish
  /// copy rather than falling all the way back to English because the
  /// region did not match. When a locale needs genuinely different copy
  /// per region — Portuguese is the likely first case — it gets its own
  /// entry in [supported] and this still resolves it, because an exact
  /// match is tried before the language-only pass.
  static Locale resolve(List<Locale>? preferred) {
    if (preferred == null || preferred.isEmpty) return fallback;

    for (final want in preferred) {
      for (final have in supported) {
        if (have.languageCode == want.languageCode &&
            have.countryCode == want.countryCode) {
          return have;
        }
      }
    }

    for (final want in preferred) {
      for (final have in supported) {
        if (have.languageCode == want.languageCode) return have;
      }
    }

    return fallback;
  }

  /// The language code the content catalogue should load.
  static String contentCodeFor(Locale locale) => locale.languageCode;

  /// The content directory for [locale], e.g. `assets/content/en`.
  static String contentDirFor(Locale locale) =>
      'assets/content/${contentCodeFor(locale)}';
}
