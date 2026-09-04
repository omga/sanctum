
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
import 'package:sanctum/src/domain/models/birth_time.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/paywall.dart';
import 'package:sanctum/src/domain/services/compatibility_gate.dart';
import 'package:sanctum/src/features/compatibility/view/match_carousel_screen.dart';
import 'package:sanctum/src/features/compatibility/view/report_screen.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/direction_bar.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/hexagon_chart.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/match_computing.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/match_share_card.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/score_dial.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/sign_avatar.dart';
import 'package:sanctum/src/features/compatibility/view_model/compatibility_view_model.dart';
import 'package:sanctum/src/features/compatibility/view_model/report_view_model.dart';
import 'package:sanctum/src/features/sharing/view_model/share_controller.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/l10n/sanctum_lexicon.dart';
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
    this.minuteOfBirth,
    this.celebrityId,
    this.first,
    super.key,
  });

  /// Opens a reading between two people, neither of whom is the user.
  ///
  /// Pushed with objects rather than routed. `MatchResultRoute` already
  /// carries one name and birth date in its query string — the standing
  /// hazard the handoff names — and a two-person route would put two
  /// people's details in a URL that reaches crash breadcrumbs and OS
  /// logs. Nothing about this screen needs deep-linking.
  static Future<void> openPair(
    BuildContext context,
    MatchPerson first,
    MatchPerson second,
  ) {
    final birth = second.birthDate;
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchResultScreen(
          name: second.name,
          birth:
              '${birth.year.toString().padLeft(4, '0')}-'
              '${birth.month.toString().padLeft(2, '0')}-'
              '${birth.day.toString().padLeft(2, '0')}',
          minuteOfBirth: second.birthTime.minuteOfDay,
          celebrityId: second.celebrityId,
          first: first,
        ),
      ),
    );
  }

  /// Their name.
  final String name;

  /// Their birth date, `yyyy-MM-dd`.
  final String birth;

  /// Their birth time in minutes since midnight, or null if unknown.
  final int? minuteOfBirth;

  /// Set when they came from the celebrity catalogue.
  final String? celebrityId;

  /// The first side of the reading. Null means the user themselves.
  final MatchPerson? first;

  @override
  ConsumerState<MatchResultScreen> createState() => _MatchResultState();
}

class _MatchResultState extends ConsumerState<MatchResultScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _persisting = false;

  /// Whether the computing sequence has finished, or was never needed.
  ///
  /// Null until the first build has seen the persisted state, because
  /// that is the only moment we can tell a first reveal from a revisit:
  /// [_persistIfNeeded] writes the id immediately afterwards, so asking
  /// again later would always say "already seen".
  bool? _opened;

  MatchPerson get _them => MatchPerson(
    name: widget.name,
    birthDate: DateTime.parse(widget.birth),
    birthTime: BirthTime(minuteOfDay: widget.minuteOfBirth),
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
          context.l10n.matchInviteMessage,
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
          final match = switch (widget.first) {
            final first? => data.matchBetween(first, _them),
            null => data.matchWith(_them),
          };
          if (match == null) {
            return Center(
              child: Text(context.l10n.matchNeedBirthDate),
            );
          }

          final access = data.accessFor(match.id);
          final unlocked = access == CompatibilityAccess.unlocked;

          // Decided once, before the reveal is recorded: that write
          // happens immediately below, so this is the only moment a
          // first view can be told from a revisit.
          //
          // A locked reading runs the sequence too, and the order is the
          // point. Computing, *then* the ask, *then* the result puts the
          // invite at the moment curiosity peaks — after the app has
          // visibly done the work and before the user has had the thing
          // they came for. Showing the ask first, with nothing having
          // happened yet, is a toll booth.
          _opened ??= data.revealedIds.contains(match.id);

          if (unlocked) _persistIfNeeded(data, match);

          if (_opened == false) {
            return MatchComputing(
              match: match,
              onDone: () {
                if (mounted) setState(() => _opened = true);
              },
            );
          }

          return _Result(
            match: match,
            access: access,
            cardKey: _cardKey,
            onInvite: () => unawaited(_sendInvite(match)),
            onPost: () => unawaited(
              MatchCarouselScreen.open(context, match),
            ),
            onShare: () => unawaited(
              ref
                  .read(shareControllerProvider.notifier)
                  .share(_cardKey, text: context.l10n.matchShareText),
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
    required this.onPost,
  });

  final CompatibilityMatch match;
  final CompatibilityAccess access;
  final GlobalKey cardKey;
  final VoidCallback onInvite;
  final VoidCallback onShare;
  final VoidCallback onPost;

  bool get _locked => access != CompatibilityAccess.unlocked;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    var beat = 0;
    Duration next() => Duration(milliseconds: 180 * beat++);

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(
            SanctumSpacing.xl,
            0,
            SanctumSpacing.xl,
            context.navBarClearance,
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
                      verdict: verdictLabel(match.verdict, context.l10n),
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
                    label: context.l10n.matchWhatWorks,
                    body: match.worksLine,
                    accent: true,
                  ),
                  const SizedBox(height: SanctumSpacing.md),
                  _Note(
                    label: context.l10n.matchWhatToWatch,
                    body: match.watchLine,
                  ),
                  const SizedBox(height: SanctumSpacing.xxl),
                  RepaintBoundary(
                    key: cardKey,
                    child: MatchShareCard(match: match),
                  ),
                  const SizedBox(height: SanctumSpacing.lg),

                  // The carousel is the primary action and the card is
                  // the fallback, not the other way round. One still is
                  // a screenshot; four frames is a post, and posts are
                  // the only acquisition channel this product has.
                  SanctumButton(
                    label: context.l10n.matchShareTikTok,
                    icon: Icons.auto_awesome_motion,
                    expand: true,
                    onPressed: _locked ? null : onPost,
                  ),
                  const SizedBox(height: SanctumSpacing.sm),
                  SanctumButton(
                    label: context.l10n.matchShareCard,
                    icon: Icons.ios_share,
                    variant: SanctumButtonVariant.ghost,
                    expand: true,
                    onPressed: _locked ? null : onShare,
                  ),
                  const SizedBox(height: SanctumSpacing.xxl),

                  // The report offer sits *below* the share buttons and
                  // *above* the note about what the reading was computed
                  // from, and both of those are deliberate.
                  //
                  // Below the share, because posts are the only
                  // acquisition channel this product has and a paid CTA
                  // above them taxes the growth loop to make a sale.
                  //
                  // Above the note, because that note is stated as a
                  // limit rather than as an upsell — it says so in its
                  // own comment — and putting a Buy button directly
                  // under it would convert an honest disclosure into a
                  // sales hook. The offer sells depth on its own terms
                  // and leaves the note as the last word on the screen.
                  if (!_locked) ...[
                    _ReportOffer(match: match),
                    const SizedBox(height: SanctumSpacing.xxl),
                  ],

                  Text(
                    // Says what the reading was actually computed from.
                    // A user who gave a birth time should be able to see
                    // that it was used, and one who did not should learn
                    // what it would add — stated as a limit rather than
                    // as an upsell, because it is one.
                    match.usesMoon
                        ? context.l10n.matchReadWithMoon
                        : context.l10n.matchReadWithoutMoon,
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
            bottom: context.navBarClearance,
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
              label: match.you.sign.label(context.l10n),
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
              label: match.them.sign.label(context.l10n),
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
              match.aspect.label(context.l10n).toUpperCase(),
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

/// The offer for the deep report, on an already-revealed reading.
///
/// Never on a first reveal: that one is bought with an invite, and the
/// invite is the acquisition mechanic. Stacking a purchase ask onto the
/// same moment cannibalises it, so `_locked` gates this out and the
/// first reading a user ever opens is never asked for money.
class _ReportOffer extends ConsumerWidget {
  const _ReportOffer({required this.match});

  final CompatibilityMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final type = context.type;
    final colors = context.colors;

    // Owned or for sale changes the button, not the card. Someone who
    // has already bought this should find their way back in from the
    // same place they bought it, rather than being sold it twice.
    final state = ref.watch(reportControllerProvider(match)).value;
    final owned = state?.isOwned ?? false;
    final included = state?.isIncluded ?? false;
    final price = state?.product?.displayPrice;

    // Nothing owned, nothing included and no price means the store has
    // nothing to sell — a build with no products, or a region without
    // them. Show no offer at all rather than a button that cannot work.
    if (!owned && !included && price == null) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Names the person. The product is a document about one
            // named human being, and an offer that cannot say who it is
            // about is selling a category instead.
            l10n.reportOfferTitle(match.them.name),
            style: type.title,
          ),
          const SizedBox(height: SanctumSpacing.sm),
          Text(
            l10n.reportOfferBody,
            style: type.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: SanctumSpacing.lg),
          SanctumButton(
            label: owned || included
                ? l10n.reportOfferAction
                : l10n.reportOfferUnlock,
            icon: Icons.menu_book_outlined,
            expand: true,
            onPressed: () => unawaited(ReportScreen.open(context, match)),
          ),

          // The qualifier goes under the button, not inside it. This is
          // not a buy button — it opens the report screen, where the
          // price sits beside the control that actually reaches the
          // store — so nothing here has to carry a price to be
          // compliant, and a label with a price appended is the thing
          // that overflowed on a narrow phone.
          //
          // The price is still shown, because a card that hides it until
          // the next screen is the shape of a bait, and this product's
          // whole posture is the opposite.
          //
          // A subscriber who still has their included report never sees
          // a price here at all. That ask, on this screen, seconds after
          // they paid for the reading above it, is the entire reason the
          // included report exists.
          if (!owned) ...[
            const SizedBox(height: SanctumSpacing.sm),
            Center(
              child: Text(
                included
                    ? l10n.reportIncludedBadge
                    : l10n.reportOfferPrice(price!),
                style: type.caption.copyWith(
                  color: included ? colors.gold : colors.textSecondary,
                ),
              ),
            ),
          ],
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
                ? context.l10n.matchLockedTitle
                : context.l10n.matchLockedUsedTitle,
            style: type.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SanctumSpacing.sm),
          Text(
            needsInvite
                ? context.l10n.matchLockedInvite
                : context.l10n.matchLockedPremium,
            style: type.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SanctumSpacing.lg),
          SanctumButton(
            label: needsInvite
                ? context.l10n.matchSendInvite
                : context.l10n.matchSeePremium,
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
