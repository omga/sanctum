import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/l10n/sanctum_locales.dart';

/// A `MaterialApp` configured the way the real one is.
///
/// Widget tests that pump a bare `MaterialApp` get no `Localizations`
/// for this app, and `AppLocalizations.of(context)` is non-nullable — so
/// the first widget that reads a string throws rather than rendering in
/// English. That failure looks like a bug in the widget under test,
/// which is a bad hour to spend.
///
/// Locale is pinned to English rather than left to the host, so a
/// developer with a non-English machine gets the same assertions as CI.
Widget testApp(Widget home) => MaterialApp(
  theme: SanctumTheme.nocturne(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: SanctumLocales.supported,
  locale: SanctumLocales.fallback,
  home: home,
);
