import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_dialog.dart';
import 'package:sanctum/src/design_system/effects/aurora_background.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/effects/starfield.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/advisor_consent.dart';
import 'package:sanctum/src/features/advisor/view_model/advisor_consent_view_model.dart';
import 'package:sanctum/src/l10n/l10n.dart';

/// What the advisor sends, who receives it, and a choice about it.
///
/// ## Why this is a screen and not a checkbox
///
/// `advisor.md` §1. Everything else in Sanctum is computed on the
/// device; this one feature sends a chart to a third party, and a line
/// of small print under a text field is not how somebody learns that.
/// The screen states four things — what is sent, what is not, who
/// receives it, how long it is kept — and asks. It is shown before a
/// single byte moves, and `chatTransport` refuses to build a proxy
/// transport until it has been answered, so the disclosure is not the
/// only thing holding the line.
///
/// ## Why the same widget serves the offer and the review
///
/// A user who agreed and later wants to know what they agreed to should
/// read the *same words*, not a summary of them written elsewhere.
/// Settings opens this; the only difference is the first line and the
/// pair of buttons at the foot.
///
/// ## Leaving is not an answer
///
/// The back arrow records nothing and the state stays
/// [AdvisorConsent.unasked]. Only "Not now" writes
/// [AdvisorConsent.declined]. The distinction is the reason the stored
/// value is not a boolean: a decision has to be told apart from a
/// screen somebody swiped away from, or the triggers in `advisor.md` §7
/// end up nudging the one person who already said no.
class AdvisorConsentView extends ConsumerWidget {
  /// Creates the disclosure.
  const AdvisorConsentView({required this.onClose, super.key});

  /// Leaves the screen — after declining, or after reading.
  ///
  /// Granting does not call it: the provider flips, whatever is showing
  /// this rebuilds, and the user is where they were going.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;
    final consent =
        ref.watch(advisorConsentProvider).value ?? AdvisorConsent.unasked;
    final granted = consent.allowsSending;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        SanctumSpacing.lg,
        SanctumSpacing.md,
        SanctumSpacing.lg,
        // The floating nav bar draws over this list on both routes that
        // show it — the conversation screen and the one settings pushes
        // — so the last button has to clear it. Found by running it:
        // at a fixed 32 the "Not now" sits under the pill on a shorter
        // phone.
        context.navBarClearance,
      ),
      children: [
        Text(l10n.advisorConsentTitle, style: type.displaySmall),
        const SizedBox(height: SanctumSpacing.sm),
        Text(
          granted ? l10n.advisorConsentReviewIntro : l10n.advisorConsentIntro,
          style: type.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: SanctumSpacing.xl),

        _Section(
          label: l10n.advisorConsentSentTitle,
          lines: [
            l10n.advisorConsentSentPositions,
            l10n.advisorConsentSentQuestion,
            l10n.advisorConsentSentLanguage,
          ],
        ),
        const SizedBox(height: SanctumSpacing.md),
        _Section(
          label: l10n.advisorConsentHeldTitle,
          lines: [
            l10n.advisorConsentHeldNames,
            l10n.advisorConsentHeldBirth,
            l10n.advisorConsentHeldElse,
          ],
        ),
        const SizedBox(height: SanctumSpacing.md),
        _Section(
          label: l10n.advisorConsentWhoTitle,
          lines: [l10n.advisorConsentWhoBody],
        ),
        const SizedBox(height: SanctumSpacing.md),
        _Section(
          label: l10n.advisorConsentKeptTitle,
          lines: [l10n.advisorConsentKeptBody],
        ),

        const SizedBox(height: SanctumSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 14,
              color: colors.textTertiary,
            ),
            const SizedBox(width: SanctumSpacing.xs),
            Expanded(
              child: Text(
                l10n.advisorConsentAiNote,
                style: type.caption.copyWith(color: colors.textTertiary),
              ),
            ),
          ],
        ),
        const SizedBox(height: SanctumSpacing.xl),

        if (granted) ...[
          SanctumButton(
            label: l10n.advisorConsentWithdraw,
            variant: SanctumButtonVariant.ghost,
            expand: true,
            onPressed: () => unawaited(_withdraw(context, ref)),
          ),
          const SizedBox(height: SanctumSpacing.sm),
          SanctumButton(
            label: l10n.advisorConsentDone,
            variant: SanctumButtonVariant.quiet,
            expand: true,
            onPressed: onClose,
          ),
        ] else ...[
          SanctumButton(
            label: l10n.advisorConsentAccept,
            expand: true,
            onPressed: () => unawaited(
              ref.read(advisorConsentControllerProvider.notifier).grant(),
            ),
          ),
          const SizedBox(height: SanctumSpacing.sm),
          SanctumButton(
            label: l10n.advisorConsentDecline,
            variant: SanctumButtonVariant.quiet,
            expand: true,
            onPressed: () => unawaited(_decline(ref)),
          ),
        ],
      ],
    );
  }

  Future<void> _decline(WidgetRef ref) async {
    // Recorded before leaving, not after: the screen this sits on pops
    // on the same tap, and a write started from a disposed widget is
    // the crash `AdvisorConsentController` is keepAlive to avoid.
    await ref.read(advisorConsentControllerProvider.notifier).decline();
    onClose();
  }

  /// Withdrawing is a real revocation, so it asks first.
  ///
  /// And it says what withdrawing does *not* do: the transcripts stay,
  /// because they are on this phone and nothing about consent reaches
  /// them. People assume the opposite, and finding out later is worse
  /// than a sentence in a dialog.
  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await SanctumDialog.show(
      context,
      title: l10n.advisorConsentWithdrawTitle,
      message: l10n.advisorConsentWithdrawMessage,
      confirmLabel: l10n.advisorConsentWithdraw,
      cancelLabel: l10n.journalKeep,
    );
    if (!confirmed) return;
    await ref.read(advisorConsentControllerProvider.notifier).withdraw();
  }
}

/// One labelled group of statements.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.lines});

  final String label;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final colors = context.colors;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: type.caption.copyWith(
              color: colors.textTertiary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: SanctumSpacing.md),
          for (final line in lines) ...[
            if (line != lines.first) const SizedBox(height: SanctumSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  // Sits the dot on the first line's optical centre
                  // rather than its top edge.
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: colors.textTertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: SanctumSpacing.sm),
                Expanded(
                  child: Text(
                    line,
                    style: type.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// [AdvisorConsentView] as a route, for reading it again from settings.
class AdvisorConsentScreen extends StatelessWidget {
  /// Creates the screen.
  const AdvisorConsentScreen({super.key});

  /// Opens it.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AdvisorConsentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Its own background: this route sits over the shell, which is what
    // paints the aurora and the starfield for the screens inside it.
    // `SettingsScreen` — the only place this opens from — does the same.
    return AuroraBackground(
      child: Starfield(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: context.colors.textSecondary),
          ),
          body: SafeArea(
            top: false,
            child: AdvisorConsentView(
              onClose: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      ),
    );
  }
}
