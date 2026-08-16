import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/transit.dart';

/// Today's transit, the retrograde note, and what lands tomorrow.
///
/// The tomorrow line is the only honest open loop the app has. A daily
/// card cannot promise anything about tomorrow, because it is a hash of
/// the date — but the sky is on rails, so this one can, and a reason to
/// come back is worth more than anything else on the screen.
class TransitPanel extends StatelessWidget {
  /// Creates the panel.
  const TransitPanel({required this.reading, super.key});

  /// What today holds.
  final DailyTransitReading reading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final transit = reading.transit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reading.retrogradeNote case final note?) ...[
          _Banner(text: note),
          const SizedBox(height: SanctumSpacing.md),
        ],
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 15,
                    color: colors.gold,
                  ),
                  const SizedBox(width: SanctumSpacing.sm),
                  Expanded(
                    child: Text(
                      (transit?.headline ?? 'A quiet sky').toUpperCase(),
                      style: type.caption.copyWith(
                        color: colors.gold,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                  if (transit?.isExact ?? false)
                    Text(
                      'EXACT',
                      style: type.caption.copyWith(
                        color: colors.accentSecondary,
                        letterSpacing: 1.6,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: SanctumSpacing.md),
              Text(reading.line, style: type.bodyLarge),
              if (reading.tomorrow case final tomorrow?) ...[
                const SizedBox(height: SanctumSpacing.lg),
                Divider(color: colors.divider, height: 1),
                const SizedBox(height: SanctumSpacing.md),
                Row(
                  children: [
                    Text(
                      'TOMORROW',
                      style: type.caption.copyWith(
                        color: colors.textTertiary,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(width: SanctumSpacing.md),
                    Expanded(
                      child: Text(
                        tomorrow,
                        style: type.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: SanctumRadii.mdAll,
        color: colors.warning.withValues(alpha: 0.12),
        border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SanctumSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.replay, size: 15, color: colors.warning),
            const SizedBox(width: SanctumSpacing.sm),
            Expanded(
              child: Text(text, style: context.type.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
