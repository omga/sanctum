import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/l10n/l10n.dart';

/// Sanctum's confirmation dialog.
///
/// Material's [AlertDialog] would work and would look like a different
/// app — square-ish, opaque, system-typeface buttons. A dialog is one of
/// the few places a user looks closely, so it is the last place to let
/// the design system lapse.
class SanctumDialog extends StatelessWidget {
  /// Creates a dialog.
  const SanctumDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel,
    super.key,
  });

  /// Headline.
  final String title;

  /// Supporting copy.
  final String message;

  /// Label for the affirmative action.
  final String confirmLabel;

  /// Label for the dismissive action.
  ///
  /// Nullable rather than defaulted, because the default is localised
  /// and a default parameter value has to be a compile-time constant.
  /// Resolved against the context in [build].
  final String? cancelLabel;

  /// Shows the dialog, resolving to `true` if confirmed.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String? cancelLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: context.colors.scrim,
      builder: (_) => SanctumDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(SanctumSpacing.xl),
      child: ClipRRect(
        borderRadius: SanctumRadii.xlAll,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: SanctumRadii.xlAll,
              color: colors.surface.withValues(alpha: 0.92),
              border: Border.all(color: colors.glassBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(SanctumSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: type.displaySmall),
                  const SizedBox(height: SanctumSpacing.sm),
                  Text(message, style: type.bodyMedium),
                  const SizedBox(height: SanctumSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SanctumButton(
                        label: cancelLabel ?? context.l10n.commonStay,
                        variant: SanctumButtonVariant.quiet,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      const SizedBox(width: SanctumSpacing.sm),
                      SanctumButton(
                        label: confirmLabel,
                        variant: SanctumButtonVariant.ghost,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: SanctumMotion.quick);
  }
}
