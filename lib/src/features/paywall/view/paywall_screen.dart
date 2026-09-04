import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/core/analytics/analytics_event.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/effects/aurora_background.dart';
import 'package:sanctum/src/design_system/effects/starfield.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/paywall.dart';
import 'package:sanctum/src/domain/models/subscription_plan.dart';
import 'package:sanctum/src/features/paywall/view_model/paywall_view_model.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/l10n/sanctum_lexicon.dart';

/// Sanctum Premium.
///
/// ## What sells it
///
/// The headline changes with [moment]. Someone who just held a three-day
/// streak sees their streak; someone who tapped a locked session sees
/// that session. Naming what the person actually did is the single
/// biggest difference between a paywall that converts and one that gets
/// dismissed — and unlike a fake countdown, it is simply true.
///
/// The close button is visible from the first frame, the price is stated
/// in full next to the trial, and "cancel anytime" sits under the CTA.
/// Those three are non-negotiable: hiding any of them is an App Store
/// 3.1.2 rejection, and the refund rate on high-pressure paywalls costs
/// more than the conversions.
class PaywallScreen extends ConsumerStatefulWidget {
  /// Creates the paywall, framed around [moment].
  const PaywallScreen({this.moment = PaywallMoment.returningUser, super.key});

  /// What earned the user this screen.
  final PaywallMoment moment;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String? _selectedPlanId;
  bool _purchased = false;

  @override
  void initState() {
    super.initState();
    // Record the impression once, on display — this is what feeds the
    // cooldown, so it must not fire on every rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(analyticsProvider)
          .track(AnalyticsEvent.paywallShown(moment: widget.moment.name));
      unawaited(ref.read(paywallControllerProvider.notifier).recordShown());
    });
  }

  Future<void> _dismiss() async {
    if (!_purchased) {
      ref
          .read(analyticsProvider)
          .track(
            AnalyticsEvent.paywallDismissed(moment: widget.moment.name),
          );
      await ref.read(paywallControllerProvider.notifier).recordDismissed();
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  /// Restores, and says so either way.
  ///
  /// Store review requires a restore path, and a silent one fails the
  /// spirit of it: the common case is a reinstall that finds nothing,
  /// and a button that does nothing visible reads as broken. Errors are
  /// already surfaced by the listener in `build`, so this only has to
  /// speak when the call succeeded.
  Future<void> _restore() async {
    final restored = await ref
        .read(paywallControllerProvider.notifier)
        .restore();

    if (!mounted) return;
    if (ref.read(paywallControllerProvider).hasError) return;

    if (restored) {
      Navigator.of(context).maybePop();
      return;
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(context.l10n.paywallNoPurchase),
      ),
    );
  }

  /// Buys [plan], and only celebrates if it was actually bought.
  ///
  /// The three things below all used to run on a cancellation, because
  /// `purchase` returned `Result<void>` and "no error" was read as
  /// success. Each was its own bug: `purchase_completed` inflated the
  /// only conversion number the business has, the screen flashed its
  /// purchased state and closed on somebody who had just declined, and
  /// `_purchased` suppressed the dismissal — so `PaywallTrigger`'s
  /// backoff never advanced and the same user got prompted again on the
  /// shortest cooldown.
  ///
  /// A cancellation now leaves them on the paywall, which is where
  /// backing out of a store sheet should land: the plan is still
  /// selected, and closing it records a dismissal like any other.
  Future<void> _purchase(SubscriptionPlan plan) async {
    final analytics = ref.read(analyticsProvider)
      ..track(AnalyticsEvent.purchaseStarted(plan: plan.id));

    final bought = await ref
        .read(paywallControllerProvider.notifier)
        .purchase(plan);

    if (!mounted) return;
    if (ref.read(paywallControllerProvider).hasError) return;
    if (!bought) return;

    analytics.track(AnalyticsEvent.purchaseCompleted(plan: plan.id));

    unawaited(HapticFeedback.mediumImpact());
    setState(() => _purchased = true);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final plans = ref.watch(subscriptionPlansProvider);

    ref.watch(paywallControllerProvider);
    ref.listen(paywallControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text('$error')));
      }
    });

    return Scaffold(
      body: AuroraBackground(
        intensity: 1.3,
        child: Starfield(
          child: SafeArea(
            child: plans.when(
   skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (unordered) {
                // Yearly leads: it is the default selection and the
                // one the CTA describes. Lifetime is filtered out rather
                // than ordered last — the store offering may contain it,
                // but a one-off price next to two subscriptions changes
                // what this screen is asking for. It belongs on its own
                // surface, reached by its own trigger.
                final sellable = unordered.where(
                  (p) => p.period != BillingPeriod.lifetime,
                );
                final data = [
                  ...sellable.where((p) => p.period == BillingPeriod.yearly),
                  ...sellable.where((p) => p.period != BillingPeriod.yearly),
                ];
                if (data.isEmpty) {
                  return Center(
                    child: Text(context.l10n.paywallUnavailable),
                  );
                }
                final selected = _selectedPlanId ?? data.first.id;
                final plan = data.firstWhere((p) => p.id == selected);

                return Column(
                  children: [
                    // Always visible, always first. Never a delayed or
                    // hidden dismiss.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        color: colors.textSecondary,
                        onPressed: _dismiss,
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SanctumSpacing.xl,
                        ),
                        children: [
                          const SizedBox(height: SanctumSpacing.lg),
                          Text(
                            context.l10n.paywallBrand,
                            style: type.caption.copyWith(color: colors.gold),
                          ),
                          const SizedBox(height: SanctumSpacing.md),
                          Text(
                            _headline(context, widget.moment),
                            style: type.displayLarge,
                          ),
                          const SizedBox(height: SanctumSpacing.md),
                          Text(
                            _subhead(context, widget.moment),
                            style: type.bodyLarge,
                          ),
                          const SizedBox(height: SanctumSpacing.xl),
                          const _Benefits(),
                          const SizedBox(height: SanctumSpacing.lg),
                        ],
                      ),
                    ),
                    // Prices and CTA are pinned, never scrolled. On a
                    // shorter phone the selected plan would otherwise sit
                    // below the fold while the button advertised its
                    // trial — the user reads "7 days free, then £39.99 a
                    // year" with no visible yearly option. Pinning them
                    // together makes that impossible by construction.
                    _Footer(
                      plans: data,
                      selectedId: selected,
                      plan: plan,
                      onSelect: (id) {
                        unawaited(HapticFeedback.selectionClick());
                        setState(() => _selectedPlanId = id);
                      },
                      onPurchase: () => _purchase(plan),
                      onRestore: () => unawaited(_restore()),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _headline(BuildContext context, PaywallMoment moment) {
    final l10n = context.l10n;
    return switch (moment) {
      PaywallMoment.streakEarned => l10n.paywallHeadlineStreak,
      PaywallMoment.ritualCompleted => l10n.paywallHeadlineRitual,
      PaywallMoment.sessionsSampled => l10n.paywallHeadlineSessions,
      PaywallMoment.lockedContent => l10n.paywallHeadlineLocked,
      PaywallMoment.returningUser => l10n.paywallHeadlineReturning,
    };
  }

  String _subhead(BuildContext context, PaywallMoment moment) {
    final l10n = context.l10n;
    return switch (moment) {
      PaywallMoment.streakEarned => l10n.paywallSubheadStreak,
      PaywallMoment.ritualCompleted => l10n.paywallSubheadRitual,
      PaywallMoment.sessionsSampled => l10n.paywallSubheadSessions,
      PaywallMoment.lockedContent => l10n.paywallSubheadLocked,
      PaywallMoment.returningUser => l10n.paywallSubheadReturning,
    };
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  static List<({IconData icon, String text})> _itemsFor(
    BuildContext context,
  ) {
    final l10n = context.l10n;
    return [
      // First, because the compatibility lock card is what sells most
      // of these subscriptions — and until now the screen it sent people
      // to did not mention compatibility at all.
      (icon: Icons.favorite_outline, text: l10n.paywallBenefitMatches),
      (icon: Icons.graphic_eq, text: l10n.paywallBenefitSessions),
      (icon: Icons.brightness_2_outlined, text: l10n.paywallBenefitRituals),
      (icon: Icons.auto_awesome, text: l10n.paywallBenefitOracle),
      (icon: Icons.show_chart, text: l10n.paywallBenefitInsights),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        for (final item in _itemsFor(context))
          Padding(
            padding: const EdgeInsets.only(bottom: SanctumSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accent.withValues(alpha: 0.18),
                  ),
                  child: Icon(item.icon, size: 20, color: colors.gold),
                ),
                const SizedBox(width: SanctumSpacing.lg),
                Expanded(
                  child: Text(item.text, style: context.type.bodyLarge),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final isYearly = plan.period == BillingPeriod.yearly;

    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: SanctumMotion.quick,
          curve: SanctumMotion.ease,
          padding: const EdgeInsets.all(SanctumSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: SanctumRadii.lgAll,
            color: selected
                ? colors.accent.withValues(alpha: 0.16)
                : colors.glassFill,
            border: Border.all(
              color: selected ? colors.gold : colors.glassBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _RadioDot(selected: selected),
              const SizedBox(width: SanctumSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isYearly
                              ? context.l10n.paywallYearly
                              : context.l10n.paywallMonthly,
                          style: type.title,
                        ),
                        if (plan.savingsPercent case final saving?) ...[
                          const SizedBox(width: SanctumSpacing.sm),
                          _Banner(text: context.l10n.paywallSaveBadge(saving)),
                        ],
                      ],
                    ),
                    const SizedBox(height: SanctumSpacing.xxs),
                    Text(
                      // Both numbers, always: the headline per-month
                      // figure and the actual amount that gets charged.
                      // The store does not always break a yearly price
                      // down per month, and inventing the number here
                      // would mean formatting currency ourselves.
                      switch ((isYearly, plan.displayPricePerMonth)) {
                        (true, final perMonth?) => context.l10n
                            .paywallPriceYearlyPerMonth(
                              perMonth,
                              plan.displayPrice,
                            ),
                        (true, _) => context.l10n.paywallPriceYearly(
                          plan.displayPrice,
                        ),
                        _ => context.l10n.paywallPricePerPeriod(
                          plan.displayPrice,
                          plan.period.unitLabelIn(context.l10n),
                        ),
                      },
                      style: type.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: SanctumMotion.quick,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.gold : Colors.transparent,
        border: Border.all(
          color: selected ? colors.gold : colors.glassBorder,
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: 15, color: colors.textOnAccent)
          : null,
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SanctumSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        borderRadius: SanctumRadii.pillAll,
        gradient: LinearGradient(
          colors: [colors.gold, colors.goldMuted],
        ),
      ),
      child: Text(
        text,
        style: context.type.caption.copyWith(color: colors.textOnAccent),
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({
    required this.plans,
    required this.selectedId,
    required this.plan,
    required this.onSelect,
    required this.onPurchase,
    required this.onRestore,
  });

  final List<SubscriptionPlan> plans;
  final String selectedId;
  final SubscriptionPlan plan;
  final ValueChanged<String> onSelect;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.type;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SanctumSpacing.xl,
        SanctumSpacing.md,
        SanctumSpacing.xl,
        SanctumSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in plans) ...[
            _PlanTile(
              plan: option,
              selected: option.id == selectedId,
              onTap: () => onSelect(option.id),
            ),
            const SizedBox(height: SanctumSpacing.sm),
          ],
          const SizedBox(height: SanctumSpacing.sm),
          SanctumButton(
            label: plan.hasTrial
                ? context.l10n.paywallStartTrial(plan.trialDays)
                : context.l10n.paywallSubscribe,
            icon: Icons.auto_awesome,
            expand: true,
            onPressed: onPurchase,
          ),
          const SizedBox(height: SanctumSpacing.sm),
          Text(
            // Stating exactly what happens and when. A trial that does
            // not say what it renews at is the classic complaint, and
            // the classic refund.
            plan.hasTrial
                ? context.l10n.paywallTrialTerms(
                    plan.trialDays,
                    plan.displayPrice,
                    plan.period.unitLabelIn(context.l10n),
                  )
                : context.l10n.paywallTerms(
                    plan.displayPrice,
                    plan.period.unitLabelIn(context.l10n),
                  ),
            textAlign: TextAlign.center,
            style: type.caption,
          ),
          const SizedBox(height: SanctumSpacing.sm),
          TextButton(
            onPressed: onRestore,
            child: Text(context.l10n.paywallRestore, style: type.caption),
          ),
        ],
      ),
    );
  }
}
