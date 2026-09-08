import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/effects/aurora_background.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_composer.dart';
import 'package:sanctum/src/domain/services/palm_gate.dart';
import 'package:sanctum/src/domain/services/palm_reading_composer.dart';
import 'package:sanctum/src/features/palm/view_model/palm_reading_view_model.dart';
import 'package:sanctum/src/features/palm/view_model/palm_scan_view_model.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/routing/app_router.dart';

/// What the scan says, once the gate lets it through.
///
/// ## Why a reading can expire
///
/// It reads the live scan rather than storage, because there is no
/// storage: no still, no landmarks, no curves. That is the answer to a
/// palm scan being biometric data, and this screen is where the cost of
/// it shows — come back after the process was killed and there is
/// nothing to render, so it offers another scan instead of a document.
///
/// The alternative is keeping a scan on disk to reopen, which is a
/// materially different privacy position for a feature nobody has asked
/// that of yet.
class PalmReadingScreen extends ConsumerWidget {
  /// Creates the reading screen for [scanId].
  const PalmReadingScreen({required this.scanId, super.key});

  /// Which scan this is about.
  final String scanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = ref.watch(
      palmScanViewModelProvider.select((state) => state.reading),
    );
    final access = ref.watch(palmReadingAccessProvider(scanId));
    final catalogue = ref.watch(contentCatalogProvider);
    final copy = catalogue.value?.copy;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(context.l10n.palmTitle),
      ),
      body: AuroraBackground(
        child: SafeArea(
          child: switch ((reading, access, copy)) {
            (null, _, _) ||
            (_, AsyncLoading(), _) ||
            (_, _, null) => const Center(child: CircularProgressIndicator()),
            (
              final PalmReading scan,
              AsyncData(value: final granted),
              final CopyBook book,
            ) =>
              _Gated(scan: scan, access: granted, copy: book),
            (_, AsyncError(:final error), _) => Center(child: Text('$error')),
          },
        ),
      ),
    );
  }
}

/// Shows the reading, or the ask that stands in front of it.
class _Gated extends ConsumerStatefulWidget {
  const _Gated({
    required this.scan,
    required this.access,
    required this.copy,
  });

  final PalmReading scan;
  final PalmReadingAccess access;
  final CopyBook copy;

  @override
  ConsumerState<_Gated> createState() => _GatedState();
}

class _GatedState extends ConsumerState<_Gated> {
  @override
  void initState() {
    super.initState();
    _keepOpen();
  }

  @override
  void didUpdateWidget(_Gated old) {
    super.didUpdateWidget(old);
    if (old.access != widget.access) _keepOpen();
  }

  /// Writes the reading down the first time it opens, so it stays open.
  ///
  /// Without it, coming back a minute later spends the allowance a
  /// second time and then asks for money for a screen already read.
  ///
  /// Fired from a life-cycle hook rather than from `build`, because a
  /// write and two invalidations during a build is how a screen ends up
  /// rebuilding itself in a circle.
  void _keepOpen() {
    if (widget.access != PalmReadingAccess.unlocked) return;
    unawaited(
      ref.read(palmUnlockControllerProvider.notifier).keepOpen(widget.scan.id),
    );
  }

  @override
  Widget build(BuildContext context) =>
      widget.access == PalmReadingAccess.unlocked
      ? _Reading(
          profile: PalmReadingComposer.compose(widget.scan),
          copy: widget.copy,
        )
      : _Locked(access: widget.access);
}

/// The reading itself.
class _Reading extends StatelessWidget {
  const _Reading({required this.profile, required this.copy});

  final PalmProfile profile;
  final CopyBook copy;

  @override
  Widget build(BuildContext context) {
    if (profile.isThin) return const _Thin();

    return ListView(
      padding: const EdgeInsets.all(SanctumSpacing.lg),
      children: [
        for (final note in profile.notes) ...[
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameOf(context, note.line),
                  style: context.type.label.copyWith(
                    color: context.colors.gold,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: SanctumSpacing.sm),
                Text(
                  copy.get(_copyKeyOf(note)),
                  style: context.type.bodyLarge.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SanctumSpacing.md),
        ],
        const SizedBox(height: SanctumSpacing.sm),
        Center(
          child: Text(
            context.l10n.palmDisclaimer,
            style: context.type.caption.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

/// A scan too faint to say much about.
///
/// Blames the photograph, which is where the fault actually is: clarity
/// falls in a dim room on a hand whose lines are perfectly deep.
class _Thin extends StatelessWidget {
  const _Thin();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(SanctumSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.palmThinTitle,
            textAlign: TextAlign.center,
            style: context.type.title.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: SanctumSpacing.md),
          Text(
            context.l10n.palmThinBody,
            textAlign: TextAlign.center,
            style: context.type.bodyMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: SanctumSpacing.lg),
          SanctumButton(
            label: context.l10n.palmRetake,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}

/// The ask standing in front of the reading.
///
/// Two shapes, and the difference matters. A share is asked for once and
/// any destination counts — a friend, a group, a post — because
/// requiring a *public* post is unenforceable, is the shape of thing App
/// Review rejects, and taxes the only acquisition channel this feature
/// has. Money is asked for afterwards. See `PalmGate`.
class _Locked extends StatelessWidget {
  const _Locked({required this.access});

  final PalmReadingAccess access;

  @override
  Widget build(BuildContext context) {
    final needsShare = access == PalmReadingAccess.needsShare;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SanctumSpacing.xl),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                needsShare
                    ? context.l10n.palmLockedShareTitle
                    : context.l10n.palmLockedPremiumTitle,
                textAlign: TextAlign.center,
                style: context.type.title.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: SanctumSpacing.md),
              Text(
                needsShare
                    ? context.l10n.palmLockedShareBody
                    : context.l10n.palmLockedPremiumBody,
                textAlign: TextAlign.center,
                style: context.type.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: SanctumSpacing.lg),
              SanctumButton(
                // The share itself lives on the reveal, where the thing
                // being shared is on screen. Sending them back to it is
                // honest; a share button here would share a lock card.
                label: needsShare
                    ? context.l10n.palmRetake
                    : context.l10n.palmLockedPremiumCta,
                onPressed: () => needsShare
                    ? Navigator.of(context).pop()
                    : const PaywallRoute().push<void>(context),
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _nameOf(BuildContext context, PalmLine line) => switch (line) {
  PalmLine.heart => context.l10n.palmLineHeart,
  PalmLine.head => context.l10n.palmLineHead,
  PalmLine.life => context.l10n.palmLineLife,
  PalmLine.fate => context.l10n.palmLineFate,
};

/// The content key for one line at one length.
///
/// The prose lives in `assets/content/<locale>/copy.json` rather than in
/// the ARB, because this repo splits the two on which half needs a human
/// translator — and a paragraph about somebody's hand is squarely the
/// half that does. The ARB keeps the chrome: buttons, hints, line names.
///
/// The key is composed from structure, so the composer decides what is
/// claimed and the translator only decides how it is said. Same rule the
/// relationship report follows.
String _copyKeyOf(PalmLineNote note) =>
    'palm.${note.line.name}.${note.length.name}';
