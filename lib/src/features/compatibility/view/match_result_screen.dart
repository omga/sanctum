import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/paywall.dart';
import 'package:sanctum/src/domain/services/compatibility_gate.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/direction_bar.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/hexagon_chart.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/match_share_card.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/score_dial.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/sign_avatar.dart';
import 'package:sanctum/src/features/compatibility/view_model/compatibility_view_model.dart';
import 'package:sanctum/src/features/sharing/view_model/share_controller.dart';
import 'package:sanctum/src/routing/app_router.dart';

/// The reveal.
///
/// The person is carried in the route rather than in a provider so the
/// screen can be re-entered, deep-linked and restored without any
/// transient state surviving in memory between visits.
class MatchResultScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const MatchResultScreen({
    required this.name,
    required this.birth,
    this.celebrityId,
    super.key,
  });

  /// Their name.
  final String name;

  /// Their birth date, `yyyy-MM-dd`.
  final String birth;

  /// Set when they came from the celebrity catalogue.
  final String? celebrityId;

  @override
  ConsumerState<MatchResultScreen> createState() => _MatchResultState();
}

class _MatchResultState extends ConsumerState<MatchResultScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _persisting = false;

  MatchPerson get _them => MatchPerson(
    name: widget.name,
    birthDate: DateTime.parse(widget.birth),
    celebrityId: widget.celebrityId,
  );

  /// Writes a newly unlocked match to storage, exactly once.
  ///
  /// The guard matters: [CompatibilityController.reveal] invalidates the
  /// provider, so without it the rebuild that follows the write would
  /// start another one before the first had landed, and a free reveal
  /// could be recorded twice.
  void _persistIfNeeded(CompatibilityUiState state, CompatibilityMatch m) {
    if (_persisting || state.revealedIds.contains(m.id)) return;
    _persisting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(compatibilityControllerProvider.notifier).reveal(m);
      if (mounted) _persisting = false;
    });
  }

  Future<void> _sendInvite(CompatibilityMatch match) async {
    final sent = await ref
        .read(shareControllerProvider.notifier)
        .shareInvite(
          "What's your birth date? I'm running us through Sanctum and "
          'I want to see what it says.',
        );
    if (!sent) return;
    await ref.read(compatibilityControllerProvider.notifier)
        .recordInviteSent();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(compatibilityControllerProvider);

    ref
      ..watch(shareControllerProvider)
      ..listen(shareControllerProvider, (_, next) {
        if (next case AsyncError(:final error)) {
          ScaffoldMessenger.maybeOf(
            context,
          )?.showSnackBar(SnackBar(content: Text('$error')));
        }
      });

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textSecondary),
      ),
      body: state.when(
   skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (data) {
          final match = data.matchWith(_them);
          if (match == null) {
            return const Center(
              child: Text('Add your own birth date first.'),
            );
          }

          final access = data.accessFor(match.id);
          if (access == CompatibilityAccess.unlocked) {
            _persistIfNeeded(data, match);
          }

          return _Result(
            match: match,
            access: access,
            cardKey: _cardKey,
            onInvite: () => unawaited(_sendInvite(match)),
            onShare: () => unawaited(
              ref
                  .read(shareControllerProvider.notifier)
                  .share(_cardKey, text: 'Our match, from Sanctum'),
            ),
          );
        },
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.match,
    required this.access,
    required this.cardKey,
    required this.onInvite,
    required this.onShare,
  });

  final CompatibilityMatch match;
  final CompatibilityAccess access;
  final GlobalKey cardKey;
  final VoidCallback onInvite;
  final VoidCallback onShare;

  bool get _locked => access != CompatibilityAccess.unlocked;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    var beat = 0;
    Duration next() => Duration(milliseconds: 180 * beat++);

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(
            SanctumSpacing.xl,
            0,
            SanctumSpacing.xl,
            SanctumSpacing.huge + SanctumSpacing.xxl,
          ),
          children: [
            _Pair(match: match, dimmed: _locked),
            const SizedBox(height: SanctumSpacing.xl),

            // Everything below the pair is the paid part. Blurring it
            // rather than hiding it is deliberate: the user can see
            // there is a real reading with real numbers waiting, which
            // is the only reason anyone completes the next step.
            _Blurred(
              blurred: _locked,
              child: Column(
                children: [
                  Center(
                    child: ScoreDial(
                      score: match.overall,
                      verdict: match.verdict,
                      yours: match.you.sign.element,
                      theirs: match.them.sign.element,
                      animate: !_locked,
                    ),
                  ),
                  const SizedBox(height: SanctumSpacing.xl),
                  Text(
                    match.dynamicLine,
                    style: type.quote,
                  ).animate(delay: next()).fadeIn(duration: SanctumMotion.calm),
                  const SizedBox(height: SanctumSpacing.lg),
                  Text(match.elementLine, style: type.bodyLarge)
                      .animate(delay: next())
                      .fadeIn(duration: SanctumMotion.calm),
                  const SizedBox(height: SanctumSpacing.xxl),
                  Center(
                    child: HexagonChart(
                      facets: match.facets,
                      animate: !_locked,
                    ),
                  ),
                  const SizedBox(height: SanctumSpacing.xxl),

                  // The lopsided readings sit above the prose. They are
                  // the part people came for and the part they post.
                  for (final direction in match.directions) ...[
                    DirectionBar(
                      reading: direction,
                      yourName: match.you.name,
                      theirName: match.them.name,
                      animate: !_locked,
                    ),
                    const SizedBox(height: SanctumSpacing.xxl),
                  ],
                  _Note(
                    label: 'WHAT WORKS',
                    body: match.worksLine,
                    accent: true,
                  ),
                  const SizedBox(height: SanctumSpacing.md),
                  _Note(label: 'WHAT TO WATCH', body: match.watchLine),
                  const SizedBox(height: SanctumSpacing.xxl),
                  RepaintBoundary(
                    key: cardKey,
                    child: MatchShareCard(match: match),
                  ),
                  const SizedBox(height: SanctumSpacing.lg),
                  SanctumButton(
                    label: 'Share this',
                    icon: Icons.ios_share,
                    variant: SanctumButtonVariant.ghost,
                    expand: true,
                    onPressed: _locked ? null : onShare,
                  ),
                  const SizedBox(height: SanctumSpacing.lg),
                  Text(
                    'For entertainment purposes only.',
                    textAlign: TextAlign.center,
                    style: type.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_locked)
          Positioned(
            left: SanctumSpacing.xl,
            right: SanctumSpacing.xl,
            // Clear of the floating nav pill, which is itself inside a
            // SafeArea — a card that stops at `huge` puts its primary
            // button underneath the tab bar on every phone with a home
            // indicator.
            bottom: SanctumSpacing.huge + SanctumSpacing.xxl,
            child: _LockCard(access: access, onInvite: onInvite),
          ),
      ],
    );
  }
}

class _Blurred extends StatelessWidget {
  const _Blurred({required this.blurred, required this.child});

  final bool blurred;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!blurred) return child;
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Opacity(opacity: 0.6, child: child),
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.match, required this.dimmed});

  final CompatibilityMatch match;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Side(
              name: match.you.name,
              label: match.you.sign.displayName,
              child: SignAvatar(sign: match.you.sign, size: 76),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SanctumSpacing.lg,
              ),
              child: Text(
                '+',
                style: type.displaySmall.copyWith(color: colors.gold),
              ),
            ),
            _Side(
              name: match.them.name,
              label: match.them.sign.displayName,
              child: SignAvatar(
                sign: match.them.sign,
                size: 76,
                dimmed: dimmed,
              ),
            ),
          ],
        ),
        const SizedBox(height: SanctumSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: SanctumRadii.pillAll,
            color: colors.glassFill,
            border: Border.all(color: colors.glassBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SanctumSpacing.lg,
              vertical: SanctumSpacing.xs + 2,
            ),
            child: Text(
              match.aspect.displayName.toUpperCase(),
              style: type.caption.copyWith(
                color: colors.gold,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.name,
    required this.label,
    required this.child,
  });

  final String name;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final type = context.type;

    return SizedBox(
      width: 104,
      child: Column(
        children: [
          child,
          const SizedBox(height: SanctumSpacing.sm),
          Text(
            name,
            style: type.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(label, style: type.caption),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({
    required this.label,
    required this.body,
    this.accent = false,
  });

  final String label;
  final String body;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: type.caption.copyWith(
              color: accent ? colors.gold : colors.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: SanctumSpacing.sm),
          Text(body, style: type.bodyMedium),
        ],
      ),
    );
  }
}

class _LockCard extends StatelessWidget {
  const _LockCard({required this.access, required this.onInvite});

  final CompatibilityAccess access;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final needsInvite = access == CompatibilityAccess.needsInvite;

    return GlassCard(
      padding: const EdgeInsets.all(SanctumSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, color: colors.gold, size: 26),
          const SizedBox(height: SanctumSpacing.md),
          Text(
            needsInvite
                ? 'Your reading is ready'
                : "That's your free reading used",
            style: type.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SanctumSpacing.sm),
          Text(
            needsInvite
                ? 'Invite one person and it opens. They do not have to '
                      'reply — asking is the point.'
                : 'Sanctum Premium reads you against anyone, as often as '
                      'you like.',
            style: type.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SanctumSpacing.lg),
          SanctumButton(
            label: needsInvite ? 'Send an invite' : 'See Premium',
            icon: needsInvite ? Icons.ios_share : Icons.auto_awesome,
            expand: true,
            onPressed: needsInvite
                ? onInvite
                : () => const PaywallRoute(
                    moment: PaywallMoment.lockedContent,
                  ).push<void>(context),
          ),
        ],
      ),
    );
  }
}
