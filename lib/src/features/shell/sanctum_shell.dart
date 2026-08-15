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

/// The persistent frame around the three main sections.
///
/// The aurora and starfield live *here*, not inside each screen. Two
/// reasons, and the second is the important one:
///
/// 1. One shader and one ticker for the whole app instead of three.
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audio ??= ref.read(audioServiceProvider);
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

    final leaving = await SanctumDialog.show(
      context,
      title: 'Leave Sanctum?',
      message: playing
          ? 'Your session keeps playing. Use the notification to pause '
                'or stop it.'
          : 'Your streak and your journal are already saved.',
      confirmLabel: 'Leave',
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
      bottomNavigationBar: _SanctumNavBar(
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

class _SanctumNavBar extends StatelessWidget {
  const _SanctumNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<({IconData icon, String label})> _items = [
    (icon: Icons.wb_twilight, label: 'Today'),
    (icon: Icons.graphic_eq, label: 'Sound'),
    (icon: Icons.auto_stories_outlined, label: 'Journal'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SanctumSpacing.xl,
          0,
          SanctumSpacing.xl,
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
              for (var i = 0; i < _items.length; i++)
                _NavItem(
                  icon: _items[i].icon,
                  label: _items[i].label,
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
          padding: const EdgeInsets.symmetric(
            horizontal: SanctumSpacing.lg,
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
              // The label only appears on the selected tab: three always-on
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
