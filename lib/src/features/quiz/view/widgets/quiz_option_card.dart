import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/quiz.dart';

/// One selectable answer.
///
/// Selection animates the border to gold and lifts the fill rather than
/// stamping a checkbox on it. In a flow this long the difference between
/// "a form" and "a ritual" is almost entirely in how the taps feel.
class QuizOptionCard extends StatelessWidget {
  /// Creates an option card.
  const QuizOptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
    this.multi = false,
    super.key,
  });

  /// The option shown.
  final QuizOption option;

  /// Whether it is currently chosen.
  final bool selected;

  /// Tap handler.
  final VoidCallback onTap;

  /// Whether the parent question allows several answers.
  final bool multi;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return Semantics(
      selected: selected,
      button: true,
      label: option.label,
      child: GestureDetector(
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          onTap();
        },
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
              _Marker(selected: selected, multi: multi),
              const SizedBox(width: SanctumSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.label, style: type.bodyLarge),
                    if (option.detail case final detail?) ...[
                      const SizedBox(height: 2),
                      Text(detail, style: type.caption),
                    ],
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

class _Marker extends StatelessWidget {
  const _Marker({required this.selected, required this.multi});

  final bool selected;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedContainer(
      duration: SanctumMotion.quick,
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // Square for multi-select, round for single. The shape is the
        // only affordance telling the user whether picking a second
        // answer replaces the first.
        shape: multi ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: multi ? SanctumRadii.smAll : null,
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
