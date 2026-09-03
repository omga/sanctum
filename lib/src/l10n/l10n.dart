import 'package:flutter/widgets.dart';
import 'package:sanctum/src/l10n/generated/app_localizations.dart';

export 'package:sanctum/src/l10n/generated/app_localizations.dart';

/// `context.l10n` — the strings for the current locale.
///
/// A getter rather than `AppLocalizations.of(context)` at four hundred
/// call sites, for the same reason `context.colors` and `context.type`
/// exist in this design system: the short form is the one people
/// actually use, and a convention nobody minds typing is a convention
/// that survives.
extension L10nX on BuildContext {
  /// Localised UI strings.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
