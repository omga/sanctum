import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _SanctumButtonState extends State<SanctumButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

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
        Text(
          widget.label,
          style: type.button.copyWith(color: _foreground(colors)),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SanctumSpacing.xl,
                  vertical: SanctumSpacing.md + 2,
                ),
                child: label,
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
      gradient: LinearGradient(
        colors: [colors.accentSecondary, colors.accent],
      ),
      boxShadow: [
        // The glow is what makes the primary button look lit rather
        // than merely coloured.
        BoxShadow(
          color: colors.accent.withValues(alpha: _pressed ? 0.20 : 0.38),
          blurRadius: _pressed ? 12 : 22,
          spreadRadius: -4,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    SanctumButtonVariant.ghost => BoxDecoration(
      borderRadius: SanctumRadii.pillAll,
      color: colors.glassFill,
      border: Border.all(color: colors.glassBorder),
    ),
    SanctumButtonVariant.quiet => const BoxDecoration(
      borderRadius: SanctumRadii.pillAll,
    ),
  };
}
