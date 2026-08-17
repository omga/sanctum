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

  Future<void> _purchase(SubscriptionPlan plan) async {
    final analytics = ref.read(analyticsProvider)
      ..track(AnalyticsEvent.purchaseStarted(plan: plan.id));

    await ref.read(paywallControllerProvider.notifier).purchase(plan);
    if (!mounted) return;
    if (ref.read(paywallControllerProvider).hasError) return;

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
                  return const Center(
                    child: Text('Plans are unavailable right now.'),
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
                            'SANCTUM PREMIUM',
                            style: type.caption.copyWith(color: colors.gold),
                          ),
                          const SizedBox(height: SanctumSpacing.md),
                          Text(
                            _headline(widget.moment),
                            style: type.displayLarge,
                          ),
                          const SizedBox(height: SanctumSpacing.md),
                          Text(
                            _subhead(widget.moment),
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

  String _headline(PaywallMoment moment) => switch (moment) {
    PaywallMoment.streakEarned => 'You kept it up.',
    PaywallMoment.ritualCompleted => 'That was the work.',
    PaywallMoment.sessionsSampled => 'There are seven more.',
    PaywallMoment.lockedContent => 'Open the whole sanctum.',
    PaywallMoment.returningUser => 'You keep coming back.',
  };

  String _subhead(PaywallMoment moment) => switch (moment) {
    PaywallMoment.streakEarned =>
      'Three days is where a practice starts to hold. Premium opens '
          'every session and every ritual, so it has somewhere to go.',
    PaywallMoment.ritualCompleted =>
      'Every moon has a ritual, and every one of them is written to '
          'be done rather than read. Premium opens the rest.',
    PaywallMoment.sessionsSampled =>
      'You have heard both free tones. The full library runs from '
          '174 through 963 Hz, plus a low one for the end of the day.',
    PaywallMoment.lockedContent =>
      'Every sound session, every moon ritual, and the record of '
          'every card you have drawn.',
    PaywallMoment.returningUser =>
      'The daily card stays free forever. Premium is for when you '
          'want more than a minute a day.',
  };
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  static const List<({IconData icon, String text})> _items = [
    (icon: Icons.graphic_eq, text: 'All nine sound sessions'),
    (icon: Icons.brightness_2_outlined, text: 'Every moon ritual'),
    (icon: Icons.auto_awesome, text: 'Your full oracle history'),
    (icon: Icons.show_chart, text: 'Energy and streak insights'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        for (final item in _items)
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
                          isYearly ? 'Yearly' : 'Monthly',
                          style: type.title,
                        ),
                        if (plan.savingsPercent case final saving?) ...[
                          const SizedBox(width: SanctumSpacing.sm),
                          _Banner(text: 'SAVE $saving%'),
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
                        (true, final perMonth?) =>
                          '$perMonth / month · billed '
                              '${plan.displayPrice} yearly',
                        (true, _) => '${plan.displayPrice} / year',
                        _ =>
                          '${plan.displayPrice} / ${plan.period.unitLabel}',
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
  });

  final List<SubscriptionPlan> plans;
  final String selectedId;
  final SubscriptionPlan plan;
  final ValueChanged<String> onSelect;
  final VoidCallback onPurchase;

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
                ? 'Start ${plan.trialDays} days free'
                : 'Subscribe',
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
                ? '${plan.trialDays} days free, then ${plan.displayPrice} '
                      'per ${plan.period.unitLabel}. Cancel anytime.'
                : '${plan.displayPrice} per ${plan.period.unitLabel}. '
                      'Cancel anytime.',
            textAlign: TextAlign.center,
            style: type.caption,
          ),
          const SizedBox(height: SanctumSpacing.sm),
          TextButton(
            onPressed: () =>
                ref.read(paywallControllerProvider.notifier).restore(),
            child: Text('Restore purchases', style: type.caption),
          ),
        ],
      ),
    );
  }
}
