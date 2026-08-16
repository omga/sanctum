import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';

/// A split neither person controls, drawn as one bar with two ends.
///
/// This is the most postable object in the app. "We are 86% compatible"
/// is a fact about a couple and nobody screenshots it; "he is 71% of
/// this and you are 29%" is a fact about a person, and it goes straight
/// into a group chat.
class DirectionBar extends StatelessWidget {
  /// Creates a bar.
  const DirectionBar({
    required this.reading,
    required this.yourName,
    required this.theirName,
    this.animate = true,
    super.key,
  });

  /// What is being split.
  final DirectionalReading reading;

  /// Label for the left end.
  final String yourName;

  /// Label for the right end.
  final String theirName;

  /// Whether to slide the split into place.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reading.kind.displayName.toUpperCase(),
          style: type.caption.copyWith(
            color: colors.textSecondary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: SanctumSpacing.md),
        Row(
          children: [
            Expanded(
              child: _End(
                name: yourName,
                share: reading.yourShare,
                leading: true,
                emphasised: reading.leansYou && !reading.isBalanced,
              ),
            ),
            const SizedBox(width: SanctumSpacing.md),
            Expanded(
              child: _End(
                name: theirName,
                share: reading.theirShare,
                leading: false,
                emphasised: !reading.leansYou && !reading.isBalanced,
              ),
            ),
          ],
        ),
        const SizedBox(height: SanctumSpacing.sm),
        ClipRRect(
          borderRadius: SanctumRadii.pillAll,
          child: TweenAnimationBuilder<double>(
            tween: Tween(
              begin: animate ? 0.5 : reading.yourShare / 100,
              end: reading.yourShare / 100,
            ),
            duration: animate
                ? const Duration(milliseconds: 900)
                : Duration.zero,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (value * 1000).round(),
                    child: ColoredBox(color: colors.accent),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: ((1 - value) * 1000).round(),
                    child: ColoredBox(color: colors.gold),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: SanctumSpacing.md),
        Text(reading.line, style: type.bodyMedium),
      ],
    );
  }
}

class _End extends StatelessWidget {
  const _End({
    required this.name,
    required this.share,
    required this.leading,
    required this.emphasised,
  });

  final String name;
  final int share;
  final bool leading;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return Column(
      crossAxisAlignment: leading
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          '$share%',
          style: type.title.copyWith(
            color: emphasised
                ? (leading ? colors.accent : colors.gold)
                : colors.textSecondary,
          ),
        ),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: type.caption,
        ),
      ],
    );
  }
}
