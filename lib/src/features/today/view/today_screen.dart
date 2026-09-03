import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/energy_check_in.dart';
import 'package:sanctum/src/domain/models/paywall.dart';
import 'package:sanctum/src/features/rituals/view_model/ritual_view_model.dart';
import 'package:sanctum/src/features/today/view/widgets/energy_pattern_strip.dart';
import 'package:sanctum/src/features/today/view/widgets/moon_disc.dart';
import 'package:sanctum/src/features/today/view/widgets/oracle_card_view.dart';
import 'package:sanctum/src/features/today/view/widgets/transit_panel.dart';
import 'package:sanctum/src/features/today/view_model/today_view_model.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/l10n/sanctum_lexicon.dart';
import 'package:sanctum/src/routing/app_router.dart';

/// The home screen: today's attunement.
class TodayScreen extends ConsumerWidget {
  /// Creates the screen.
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayStateProvider);

    return SafeArea(
      bottom: false,
      // skipLoadingOnReload: a write here makes a Drift stream emit,
      // which counts as a *dependency change* rather than a refresh — and
      // `when` renders the loading branch for those by default. That
      // swapped the whole list for a spinner on every tap, destroying the
      // Scrollable and rebuilding it at offset zero. A screen that already
      // has content should never flash a spinner because a stream ticked.
      child: state.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _TodayError(message: '$error'),
        data: (data) => _TodayContent(state: data),
      ),
    );
  }
}

class _TodayError extends StatelessWidget {
  const _TodayError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SanctumSpacing.xl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: context.type.bodyMedium,
        ),
      ),
    );
  }
}

class _TodayContent extends ConsumerWidget {
  const _TodayContent({required this.state});

  final TodayUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final type = context.type;
    // `watch`, not just `read(.notifier)`. Generated @riverpod providers
    // are auto-dispose: reading only the notifier creates it with nobody
    // listening, so Riverpod disposes it immediately and the very next
    // `ref.read` inside an action throws UnmountedRefException — the tap
    // silently does nothing. Watching keeps it alive for as long as this
    // widget is mounted, and gives us the action's status for free.
    ref.watch(todayControllerProvider);
    final controller = ref.read(todayControllerProvider.notifier);

    // Actions record failures into their own AsyncValue. Surface them,
    // otherwise a failed write is indistinguishable from a dead button.
    ref.listen(todayControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SanctumSpacing.screenGutter,
        SanctumSpacing.lg,
        SanctumSpacing.screenGutter,
        SanctumSpacing.huge + SanctumSpacing.xxl,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(context),
                    style: type.displayMedium,
                  ),
                  const SizedBox(height: SanctumSpacing.xxs),
                  Text(
                    state.moon.phase.label(context.l10n).toUpperCase(),
                    style: type.caption.copyWith(color: colors.gold),
                  ),
                ],
              ),
            ),
            MoonDisc(reading: state.moon, size: 52),
          ],
        ),
        const SizedBox(height: SanctumSpacing.xl),

        // The transit leads. It is the only thing on this screen that
        // is true of *this* user on *this* day — the affirmation is one
        // of twenty-two and the card is a hash — so it is what earns the
        // open.
        if (state.transit case final transit?) ...[
          TransitPanel(reading: transit),
          const SizedBox(height: SanctumSpacing.lg),
        ],

        GlassCard.flat(
          child: Text(state.affirmation, style: type.quote),
        ),
        const SizedBox(height: SanctumSpacing.lg),

        OracleCardView(
          card: state.card,
          revealed: state.cardRevealed,
          onReveal: controller.revealCard,
        ),
        if (state.cardIsRepeat) ...[
          const SizedBox(height: SanctumSpacing.sm),
          Text(
            context.l10n.todayCardRepeat(state.cardDrawCount),
            textAlign: TextAlign.center,
            style: type.caption.copyWith(color: colors.gold),
          ),
        ],
        const SizedBox(height: SanctumSpacing.lg),

        // Only rendered on the four phases that carry a ritual, so it
        // reads as an event rather than a permanent menu item.
        const _RitualPrompt(),

        if (state.needsCheckIn)
          _EnergyPrompt(onSelect: controller.recordEnergy)
        else
          _EnergyRecorded(level: state.energy!.level),

        const SizedBox(height: SanctumSpacing.lg),

        // Directly under the check-in on purpose: the question and the
        // answer to it belong next to each other, so giving the app your
        // state and getting something back is one motion rather than a
        // deposit that disappears.
        EnergyPatternStrip(pattern: state.pattern),
        const SizedBox(height: SanctumSpacing.lg),

        _StreakRow(
          current: state.streak.current,
          longest: state.streak.longest,
          atRisk: state.streak.isAtRisk,
        ),
      ],
    );
  }

  String _greeting(BuildContext context) {
    // Based on the *date's* hour would always be midnight, so use the
    // real hour of day here — this is presentation, not domain logic.
    final l10n = context.l10n;
    final hour = DateTime.now().hour;
    if (hour < 5) return l10n.greetingLateNight;
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 18) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }
}

/// Appears only when the current moon phase has a ritual.
class _RitualPrompt extends ConsumerWidget {
  const _RitualPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ritualStateProvider).value;
    final ritual = state?.ritual;
    if (ritual == null) return const SizedBox.shrink();

    final colors = context.colors;
    final type = context.type;

    return Padding(
      padding: const EdgeInsets.only(bottom: SanctumSpacing.lg),
      child: GlassCard.flat(
        onTap: () {
          if (ref.read(isPremiumProvider)) {
            const RitualRoute().go(context);
          } else {
            unawaited(
              const PaywallRoute(moment: PaywallMoment.lockedContent)
                  .push<void>(context),
            );
          }
        },
        child: Row(
          children: [
            Icon(Icons.brightness_2_outlined, color: colors.gold),
            const SizedBox(width: SanctumSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ritual.title, style: type.title),
                  Text(
                    context.l10n.todayRitualOpen(ritual.moon),
                    style: type.bodySmall,
                  ),
                ],
              ),
            ),
            if (ref.watch(isPremiumProvider))
              Icon(Icons.chevron_right, color: colors.textTertiary)
            else
              Icon(Icons.lock_outline, size: 18, color: colors.gold),
          ],
        ),
      ),
    );
  }
}

class _EnergyPrompt extends StatelessWidget {
  const _EnergyPrompt({required this.onSelect});

  final void Function(EnergyLevel) onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GlassCard.flat(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.todayEnergyQuestion, style: context.type.title),
          const SizedBox(height: SanctumSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final level in EnergyLevel.values)
                Expanded(
                  child: Semantics(
                    button: true,
                    label: level.label(context.l10n),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(level),
                      child: Column(
                        children: [
                          Container(
                            height: 34,
                            margin: const EdgeInsets.symmetric(
                              horizontal: SanctumSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: SanctumRadii.smAll,
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  colors.accent.withValues(
                                    alpha: 0.15 + level.value * 0.13,
                                  ),
                                  colors.accentTertiary.withValues(
                                    alpha: 0.08 + level.value * 0.08,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: SanctumSpacing.xs),
                          Text(
                            level.label(context.l10n),
                            textAlign: TextAlign.center,
                            style: context.type.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnergyRecorded extends StatelessWidget {
  const _EnergyRecorded({required this.level});

  final EnergyLevel level;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GlassCard.flat(
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: colors.success, size: 20),
          const SizedBox(width: SanctumSpacing.md),
          Expanded(
            child: Text(
              context.l10n.todayEnergyRecorded(
                level.label(context.l10n).toLowerCase(),
              ),
              style: context.type.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  const _StreakRow({
    required this.current,
    required this.longest,
    required this.atRisk,
  });

  final int current;
  final int longest;
  final bool atRisk;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return GlassCard.flat(
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department_outlined,
            color: current > 0 ? colors.gold : colors.textTertiary,
          ),
          const SizedBox(width: SanctumSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current == 0
                      ? context.l10n.streakNone
                      : context.l10n.streakDays(current),
                  style: type.title,
                ),
                Text(
                  switch ((current, atRisk)) {
                    (0, _) => context.l10n.streakBeginToday,
                    (_, true) => context.l10n.streakAtRisk,
                    _ => context.l10n.streakLongest(longest),
                  },
                  style: type.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
