import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_colors.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';

/// How a [SanctumButton] presents itself.
enum SanctumButtonVariant {
  /// Filled with the aurora gradient. One per screen, at most.
  primary,

  /// Glass outline. The default for anything secondary.
  ghost,

  /// Text only, for tertiary actions.
  quiet,
}

/// Sanctum's button.
///
/// Presses scale the button down slightly and fire a selection haptic.
/// Both matter more than they sound: a button that only changes colour
/// feels like a web page, and in an app whose entire proposition is
/// "this feels good to touch", that is a product bug rather than a
/// polish detail.
///
/// ## What makes it read as expensive
///
/// Three things, none of them colour:
///
/// * **A specular top edge.** A hairline of light along the top and a
///   fill that brightens toward it — the surface is lit from above, so
///   it has a direction and therefore a shape. This is the single
///   cheapest trick in the file and it does most of the work.
/// * **A gradient border rather than a flat one.** Real edges catch more
///   light at the top than the bottom. A uniform 1px outline is the
///   thing that makes a button look like a `<div>`.
/// * **A slow sheen** travelling across the primary variant, with a long
///   pause between passes. Long enough that it reads as light moving
///   over glass rather than as a loading shimmer — a sheen that cycles
///   quickly is a skeleton loader and makes the button look busy.
///
/// The sheen runs a ticker, so it is confined to the enabled primary
/// variant, of which there is at most one per screen. Ghost and quiet
/// buttons are static, which matters on a screen that already has a
/// starfield and a shader running behind it.
class SanctumButton extends StatefulWidget {
  /// Creates a button.
  const SanctumButton({
    required this.label,
    required this.onPressed,
    this.variant = SanctumButtonVariant.primary,
    this.icon,
    this.expand = false,
    super.key,
  });

  /// Button text.
  final String label;

  /// Tap handler. `null` renders the button disabled.
  final VoidCallback? onPressed;

  /// Visual treatment.
  final SanctumButtonVariant variant;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether to fill the available width.
  final bool expand;

  @override
  State<SanctumButton> createState() => _SanctumButtonState();
}

/// `TickerProviderStateMixin`, not `SingleTickerProviderStateMixin`.
///
/// The single variant permits exactly one ticker for the whole life of
/// the State, disposed or not. [_syncSheen] disposes the controller when
/// the button becomes disabled and builds a new one when it is enabled
/// again — so a button that goes enabled → disabled → enabled asks for a
/// second ticker and trips the assertion.
///
/// Nothing did that until the report's buy button, which disables itself
/// while the store sheet is open and re-enables when the user backs out.
/// The crash was on *cancel*, which is the path least likely to be tried
/// by hand.
class _SanctumButtonState extends State<SanctumButton>
    with TickerProviderStateMixin {
  /// One pass plus its pause. The sweep itself takes [_sheenSweep] of it.
  static const Duration _sheenPeriod = Duration(milliseconds: 4200);
  static const double _sheenSweep = 0.34;

  AnimationController? _sheen;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  bool get _wantsSheen =>
      widget.variant == SanctumButtonVariant.primary && _enabled;

  @override
  void initState() {
    super.initState();
    _syncSheen();
  }

  @override
  void didUpdateWidget(SanctumButton old) {
    super.didUpdateWidget(old);
    _syncSheen();
  }

  /// Creates the ticker only for the variant that uses it, and stops it
  /// the moment the button is disabled — a highlight sliding across a
  /// greyed-out control looks like the app is stuck.
  void _syncSheen() {
    if (_wantsSheen && _sheen == null) {
      _sheen = AnimationController(vsync: this, duration: _sheenPeriod)
        ..repeat();
    } else if (!_wantsSheen && _sheen != null) {
      _sheen!.dispose();
      _sheen = null;
    }
  }

  @override
  void dispose() {
    _sheen?.dispose();
    super.dispose();
  }

  void _setPressed({required bool value}) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (!_enabled) return;
    unawaited(HapticFeedback.selectionClick());
    widget.onPressed!.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    final label = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon case final icon?) ...[
          Icon(icon, size: 18, color: _foreground(colors)),
          const SizedBox(width: SanctumSpacing.sm),
        ],
        // Flexible, because the label is translated and nothing else
        // bounds it: a Row child sized to its own text simply overflows
        // the button, and Russian and Ukrainian run 20–30% longer than
        // the English these widths were eyeballed against. Ellipsis is
        // an ugly last resort rather than the plan — the plan is short
        // labels — but it fails as a truncated word instead of as
        // yellow-and-black stripes across a paywall.
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: type.button.copyWith(color: _foreground(colors)),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        onTap: _handleTap,
        onTapDown: (_) => _setPressed(value: true),
        onTapUp: (_) => _setPressed(value: false),
        onTapCancel: () => _setPressed(value: false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: SanctumMotion.instant,
          curve: SanctumMotion.ease,
          child: AnimatedOpacity(
            opacity: _enabled ? 1 : 0.4,
            duration: SanctumMotion.instant,
            child: DecoratedBox(
              decoration: _decoration(colors),
              child: ClipRRect(
                borderRadius: SanctumRadii.pillAll,
                child: Stack(
                  children: [
                    if (widget.variant != SanctumButtonVariant.quiet)
                      Positioned.fill(child: _Specular(pressed: _pressed)),
                    if (_sheen case final sheen?)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: sheen,
                          builder: (context, _) =>
                              _Sheen(progress: sheen.value),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SanctumSpacing.xl,
                        vertical: SanctumSpacing.md + 2,
                      ),
                      child: label,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _foreground(SanctumColors colors) => switch (widget.variant) {
    SanctumButtonVariant.primary => colors.textOnAccent,
    SanctumButtonVariant.ghost => colors.textPrimary,
    SanctumButtonVariant.quiet => colors.gold,
  };

  BoxDecoration _decoration(SanctumColors colors) => switch (widget.variant) {
    SanctumButtonVariant.primary => BoxDecoration(
      borderRadius: SanctumRadii.pillAll,
      // Diagonal rather than horizontal, so the fill agrees with the
      // light source the specular layer implies.
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colors.accentSecondary, colors.accent],
      ),
      border: GradientBoxBorder(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.45),
            Colors.white.withValues(alpha: 0.06),
          ],
        ),
      ),
      boxShadow: [
        // Two shadows, not one. The tight dark one seats the button on
        // the background; the wide coloured one is the bloom that makes
        // it look lit rather than merely coloured. A single shadow can
        // do one or the other.
        BoxShadow(
          color: colors.scrim.withValues(alpha: _pressed ? 0.18 : 0.30),
          blurRadius: _pressed ? 6 : 10,
          offset: Offset(0, _pressed ? 2 : 4),
        ),
        BoxShadow(
          color: colors.accent.withValues(alpha: _pressed ? 0.22 : 0.42),
          blurRadius: _pressed ? 14 : 26,
          spreadRadius: -4,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    SanctumButtonVariant.ghost => BoxDecoration(
      borderRadius: SanctumRadii.pillAll,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.03),
        ],
      ),
      border: GradientBoxBorder(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0.07),
          ],
        ),
      ),
    ),
    SanctumButtonVariant.quiet => const BoxDecoration(
      borderRadius: SanctumRadii.pillAll,
    ),
  };
}

/// The lit top edge. Light comes from above, so the surface brightens
/// toward it and the highlight tightens when the button is pressed —
/// a pressed surface is closer to its background and catches less.
class _Specular extends StatelessWidget {
  const _Specular({required this.pressed});

  final bool pressed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedContainer(
        duration: SanctumMotion.instant,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: pressed ? 0.10 : 0.20),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0, 0.52],
          ),
        ),
      ),
    );
  }
}

/// A band of light crossing the button, then a long wait.
///
/// The gradient's alignment is animated rather than the widget's
/// position: no transform, no second clip, and nothing to lay out.
class _Sheen extends StatelessWidget {
  const _Sheen({required this.progress});

  /// Position within the full period, 0–1.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final swept = (progress / _SanctumButtonState._sheenSweep).clamp(0.0, 1.0);
    if (swept >= 1) return const SizedBox.shrink();

    final x = -2.2 + Curves.easeInOutSine.transform(swept) * 4.4;

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(x, -1),
            end: Alignment(x + 0.9, 1),
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.22),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
      ),
    );
  }
}
