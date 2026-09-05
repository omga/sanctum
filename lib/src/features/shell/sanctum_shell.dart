import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanctum/src/core/platform/app_task.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/services/audio/sanctum_audio_service.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_dialog.dart';
import 'package:sanctum/src/design_system/effects/aurora_background.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/effects/starfield.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/features/today/view_model/reminder_view_model.dart';
import 'package:sanctum/src/l10n/l10n.dart';

/// The persistent frame around the five main sections.
///
/// The aurora and starfield live *here*, not inside each screen. Two
/// reasons, and the second is the important one:
///
/// 1. One shader and one ticker for the whole app instead of four.
/// 2. Because the background is not rebuilt when the tab changes, it does
///    not restart — the sky keeps drifting through the transition. A
///    background that visibly resets on every tab tap is the single
///    fastest way to make an app feel cheap.
class SanctumShell extends ConsumerStatefulWidget {
  /// Creates the shell around [navigationShell].
  const SanctumShell({required this.navigationShell, super.key});

  /// go_router's stateful shell, holding one navigator per branch.
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<SanctumShell> createState() => _SanctumShellState();
}

class _SanctumShellState extends ConsumerState<SanctumShell> {
  SanctumAudioService? _audio;

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  bool _remindersRefreshed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio ??= ref.read(audioServiceProvider);

    // The scheduled notifications carry a week of pre-composed readings,
    // so the queue is a snapshot. Rewriting it once per launch keeps the
    // copy fresh and costs one cancel and seven schedules. It is a no-op
    // for anyone who never granted permission.
    if (!_remindersRefreshed) {
      _remindersRefreshed = true;
      unawaited(
        ref.read(reminderControllerProvider.notifier).refresh(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // canPop: false so back never leaves the app implicitly. What
      // happens instead is decided in _handleBack.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack(context);
      },
      child: _buildShell(context),
    );
  }

  /// Android back from the shell root.
  ///
  /// Two steps, in the order Android users expect:
  ///
  /// 1. From any tab other than the first, back returns to the first
  ///    tab. Exiting straight from Journal would lose their place for no
  ///    reason.
  /// 2. From the first tab, confirm before leaving. Sanctum is used for
  ///    sessions people are part-way through, and a stray back gesture
  ///    silently killing playback is a bad way to end a meditation.
  Future<void> _handleBack(BuildContext context) async {
    if (navigationShell.currentIndex != 0) {
      navigationShell.goBranch(0);
      return;
    }

    // The copy has to match reality. It used to promise "anything
    // playing will stop", which stopped being true the moment playback
    // moved into a background service — the session now continues, and
    // the notification is its control surface.
    final playing = _audio?.currentSession != null;

    final l10n = context.l10n;
    final leaving = await SanctumDialog.show(
      context,
      title: l10n.exitTitle,
      message: playing ? l10n.exitMessagePlaying : l10n.exitMessageIdle,
      confirmLabel: l10n.exitConfirm,
    );

    if (!leaving) return;

    // If a session is running, background the app rather than finishing
    // it. Finishing destroys the Flutter engine, which would stop the
    // very playback the dialog just promised would continue.
    if (playing) {
      await AppTask.moveToBackground();
    } else {
      await AppTask.exit();
    }
  }

  Widget _buildShell(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AuroraBackground(
        child: Starfield(
          child: navigationShell,
        ),
      ),
      bottomNavigationBar: SanctumNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          // Tapping the tab you are already on pops that branch back to
          // its root, which is what every native app does.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// The floating bar at the foot of every screen inside the shell.
///
/// Public only so `shell_nav_bar_test.dart` can measure it at 375pt in
/// each locale. `label_budget_test` counts characters, which is a proxy
/// for width and was not a tight enough one: the bar overflowed by 2.7
/// pixels on English "Journal" with every label inside its budget.
class SanctumNavBar extends StatelessWidget {
  /// Creates the bar.
  const SanctumNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  /// Which branch is showing.
  final int currentIndex;

  /// Called with the branch a tap selects.
  final ValueChanged<int> onTap;

  /// The four destinations, in order.
  ///
  /// No longer `const`: the labels are localised, so the list is built
  /// per frame against the context. Five records is nothing next to the
  /// shader already running behind this bar.
  static List<({IconData icon, String label})> _itemsFor(
    BuildContext context,
  ) {
    final l10n = context.l10n;
    return [
      (icon: Icons.wb_twilight, label: l10n.navToday),
      (icon: Icons.favorite_outline, label: l10n.navMatch),
      // A speech bubble with a spark, rather than the bare sparkle:
      // sparkles alone read as "magic" in an app that is already
      // full of them — the daily card and the disclosure line both
      // use one — and this tab is a conversation.
      (icon: Icons.assistant_outlined, label: l10n.navAsk),
      (icon: Icons.graphic_eq, label: l10n.navSound),
      (icon: Icons.auto_stories_outlined, label: l10n.navJournal),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsFor(context);

    return SafeArea(
      top: false,
      child: Padding(
        // `lg` rather than `xl`: at 24 a side the five pills plus the
        // selected label did not fit a 375pt phone, and the Row
        // overflowed. The bar is the widest thing on the screen, so it
        // gets the narrowest gutter.
        padding: const EdgeInsets.fromLTRB(
          SanctumSpacing.lg,
          0,
          SanctumSpacing.lg,
          SanctumSpacing.md,
        ),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: SanctumSpacing.sm,
            vertical: SanctumSpacing.sm,
          ),
          borderRadius: SanctumRadii.pillAll,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavItem(
                  icon: items[i].icon,
                  label: items[i].label,
                  selected: i == currentIndex,
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    onTap(i);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: SanctumMotion.quick,
          curve: SanctumMotion.ease,
          // `md` rather than `lg`, and the gutter outside is `lg` rather
          // than `xl`: five pills at the old numbers did not fit a
          // 375pt phone once a selected label was longer than
          // "Journal". Every Slavic label is. The pill is tighter by
          // four points a side and the bar now fits every locale —
          // `shell_nav_bar_test` measures all twenty combinations.
          padding: const EdgeInsets.symmetric(
            horizontal: SanctumSpacing.md,
            vertical: SanctumSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: SanctumRadii.pillAll,
            color: selected
                ? colors.accent.withValues(alpha: 0.18)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? colors.gold : colors.textTertiary,
              ),
              // The label only appears on the selected tab: four always-on
              // labels crowd a glass pill, and the icon plus the pill is
              // already an unambiguous selected state.
              AnimatedSize(
                duration: SanctumMotion.quick,
                curve: SanctumMotion.ease,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: SanctumSpacing.sm),
                        child: Text(
                          label,
                          style: context.type.label.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
