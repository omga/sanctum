import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/energy_check_in.dart';
import 'package:sanctum/src/domain/services/energy_pattern.dart';
import 'package:sanctum/src/l10n/l10n.dart';

/// The last thirty check-ins, and what they add up to.
///
/// This is the withdrawal for a deposit the app has been taking since
/// day one. Until now the check-in wrote to a table nothing ever read —
/// the user gave their state to the app every day and the app never
/// mentioned it again.
class EnergyPatternStrip extends StatelessWidget {
  /// Creates the strip.
  const EnergyPatternStrip({required this.pattern, super.key});

  /// The analysed history.
  final EnergyPattern pattern;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Both halves are flexible. A letter-spaced uppercase heading
          // and a counted noun beside it are each a good deal longer
          // once translated, and this row is fixed to the card width —
          // so unconstrained Texts here are an overflow waiting for the
          // first language that needs the room.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  context.l10n.energyStripWindow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.caption.copyWith(
                    color: colors.textSecondary,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              const SizedBox(width: SanctumSpacing.sm),
              Flexible(
                child: Text(
                  context.l10n.energyCheckInCount(pattern.total),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: type.caption.copyWith(color: colors.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: SanctumSpacing.md),
          Row(
            children: [
              for (final day in pattern.days)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: _Bar(level: day),
                  ),
                ),
            ],
          ),
          if (pattern.finding case final finding?) ...[
            const SizedBox(height: SanctumSpacing.lg),
            Text(
              finding,
              style: type.bodyMedium.copyWith(color: colors.textPrimary),
            ),
          ] else ...[
            const SizedBox(height: SanctumSpacing.md),
            Text(
              context.l10n.energyStripEmpty,
              style: type.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.level});

  final EnergyLevel? level;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = level?.value ?? 0;

    return SizedBox(
      height: 34,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // A missing day is drawn as a stub rather than skipped, so the
          // gaps stay visible. Closing them would quietly claim the user
          // checked in when they did not.
          Container(
            height: level == null ? 3 : 6 + value * 5.5,
            decoration: BoxDecoration(
              borderRadius: SanctumRadii.smAll,
              color: level == null
                  ? colors.glassBorder
                  : Color.lerp(
                      colors.accentCool,
                      colors.gold,
                      (value - 1) / 4,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
