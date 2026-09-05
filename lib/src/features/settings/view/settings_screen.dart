import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/design_system/effects/aurora_background.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/effects/starfield.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/features/advisor/view/advisor_consent_screen.dart';
import 'package:sanctum/src/features/settings/view_model/settings_view_model.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/l10n/sanctum_lexicon.dart';
import 'package:sanctum/src/l10n/sanctum_locales.dart';

/// Settings: the language the app is read in, and what the advisor
/// is allowed to send.
///
/// ## Why a language picker exists at all
///
/// Following the device is right for most people and is still the
/// default. It is wrong for the case this app actually has: somebody
/// whose phone is in English but who wants to be read to in Ukrainian,
/// which — given where the audience is — is common rather than exotic.
/// A reading is the product, and the language it is written in is not a
/// system preference so much as part of the reading.
class SettingsScreen extends ConsumerWidget {
  /// Creates the screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // Its own background, because this route sits outside the shell —
      // the shell is what paints the aurora and the starfield for every
      // screen inside it, and a screen pushed over the top of it gets a
      // bare black Scaffold otherwise. The paywall and the quiz do the
      // same thing for the same reason.
      body: AuroraBackground(
        child: Starfield(child: _body(context, ref)),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;
    final chosen = ref.watch(languagePreferenceProvider).value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textSecondary),
        title: Text(l10n.settingsTitle, style: type.title),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          SanctumSpacing.xl,
          0,
          SanctumSpacing.xl,
          context.navBarClearance,
        ),
        children: [
          Text(
            l10n.settingsLanguage,
            style: type.caption.copyWith(
              color: colors.textTertiary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: SanctumSpacing.md),
          _Choice(
            label: l10n.settingsLanguageSystem,
            selected: chosen == null,
            onTap: () => _choose(context, ref, null),
          ),
          for (final locale in SanctumLocales.supported) ...[
            const SizedBox(height: SanctumSpacing.sm),
            _Choice(
              // The language's own name for itself, not a translation of
              // it — see `SanctumLanguageName`.
              label: locale.endonym,
              selected: chosen == locale.languageCode,
              onTap: () => _choose(context, ref, locale.languageCode),
            ),
          ],
          const SizedBox(height: SanctumSpacing.lg),
          Text(l10n.settingsLanguageNote, style: type.caption),

          const SizedBox(height: SanctumSpacing.xxl),
          Text(
            l10n.settingsAdvisor,
            style: type.caption.copyWith(
              color: colors.textTertiary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: SanctumSpacing.md),
          const _AdvisorConsentRow(),
        ],
      ),
    );
  }

  void _choose(BuildContext context, WidgetRef ref, String? code) {
    // Nothing to do and nothing to reload if it is already the answer.
    if (ref.read(languagePreferenceProvider).value == code) return;
    unawaited(
      ref.read(languageControllerProvider.notifier).choose(code),
    );
  }
}

/// One selectable row.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return GlassCard.flat(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: SanctumSpacing.lg,
        vertical: SanctumSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: type.bodyLarge.copyWith(
                color: selected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ),
          if (selected) Icon(Icons.check, size: 20, color: colors.gold),
        ],
      ),
    );
  }
}

/// The one place consent can be read back and taken away.
///
/// It opens the same screen the user first answered rather than
/// paraphrasing it here. A settings page that summarises a disclosure
/// in its own words is a second disclosure to keep in step with the
/// first, and the two drift.
class _AdvisorConsentRow extends ConsumerWidget {
  const _AdvisorConsentRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;
    final consent = ref.watch(advisorConsentProvider).value;

    return GlassCard.flat(
      onTap: () => unawaited(AdvisorConsentScreen.open(context)),
      padding: const EdgeInsets.symmetric(
        horizontal: SanctumSpacing.lg,
        vertical: SanctumSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(l10n.settingsAdvisorRow, style: type.bodyLarge),
          ),
          Text(
            // Unresolved reads as off, because nothing may be sent
            // until it resolves to granted either.
            (consent?.allowsSending ?? false)
                ? l10n.settingsAdvisorOn
                : l10n.settingsAdvisorOff,
            style: type.bodyMedium.copyWith(color: colors.textTertiary),
          ),
          const SizedBox(width: SanctumSpacing.sm),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: colors.textTertiary,
          ),
        ],
      ),
    );
  }
}
