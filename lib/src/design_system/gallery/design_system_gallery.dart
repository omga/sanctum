import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/effects/aurora_background.dart';
import 'package:sanctum/src/design_system/effects/glass_card.dart';
import 'package:sanctum/src/design_system/effects/starfield.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';

/// A living reference for Sanctum's design language.
///
/// Not shipped to users — it is the page you open to see every token and
/// component in one place, and the surface Phase 9's golden tests point
/// at. A design system without a gallery drifts, because nobody can see
/// the whole of it at once.
class DesignSystemGallery extends StatelessWidget {
  /// Creates the gallery.
  const DesignSystemGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return Scaffold(
      body: AuroraBackground(
        child: Starfield(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: SanctumSpacing.screenGutter,
                vertical: SanctumSpacing.xl,
              ),
              children: [
                Text('Sanctum', style: type.displayLarge),
                const SizedBox(height: SanctumSpacing.xs),
                Text(
                  'THE DESIGN LANGUAGE',
                  style: type.caption.copyWith(color: colors.gold),
                ),
                const SizedBox(height: SanctumSpacing.xxl),

                const _Section(label: 'Type scale'),
                Text('Display large', style: type.displayLarge),
                Text('Display medium', style: type.displayMedium),
                Text('Display small', style: type.displaySmall),
                Text('Title', style: type.title),
                const SizedBox(height: SanctumSpacing.md),
                Text(
                  'You are not late. You are exactly where the '
                  'work wants you.',
                  style: type.quote,
                ),
                const SizedBox(height: SanctumSpacing.md),
                Text('Body large — lead paragraph.', style: type.bodyLarge),
                Text('Body medium — default copy.', style: type.bodyMedium),
                Text('Body small — dense secondary.', style: type.bodySmall),
                Text('LABEL', style: type.label),
                Text('CAPTION / OVERLINE', style: type.caption),

                const SizedBox(height: SanctumSpacing.xxl),
                const _Section(label: 'Palette'),
                const _Swatches(),

                const SizedBox(height: SanctumSpacing.xxl),
                const _Section(label: 'Glass'),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Blurred panel', style: type.title),
                      const SizedBox(height: SanctumSpacing.sm),
                      Text(
                        'BackdropFilter + gradient hairline. Expensive — '
                        'never put one inside a scrolling list.',
                        style: type.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: SanctumSpacing.md),
                GlassCard.flat(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Flat panel', style: type.title),
                      const SizedBox(height: SanctumSpacing.sm),
                      Text(
                        'No blur, no save-layer. Use this one in lists — '
                        'over a dark ground the difference is invisible.',
                        style: type.bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: SanctumSpacing.xxl),
                const _Section(label: 'Buttons'),
                Row(
                  children: [
                    SanctumButton(
                      label: 'Begin',
                      icon: Icons.auto_awesome,
                      onPressed: () {},
                    ),
                    const SizedBox(width: SanctumSpacing.md),
                    SanctumButton(
                      label: 'Later',
                      variant: SanctumButtonVariant.ghost,
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: SanctumSpacing.md),
                Row(
                  children: [
                    SanctumButton(
                      label: 'Skip for now',
                      variant: SanctumButtonVariant.quiet,
                      onPressed: () {},
                    ),
                    const SizedBox(width: SanctumSpacing.md),
                    const SanctumButton(
                      label: 'Disabled',
                      onPressed: null,
                    ),
                  ],
                ),
                const SizedBox(height: SanctumSpacing.huge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: SanctumSpacing.md),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: context.type.caption.copyWith(color: colors.goldMuted),
          ),
          const SizedBox(width: SanctumSpacing.md),
          Expanded(child: Divider(color: colors.divider)),
        ],
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final entries = <String, Color>{
      'accent': colors.accent,
      'secondary': colors.accentSecondary,
      'tertiary': colors.accentTertiary,
      'cool': colors.accentCool,
      'gold': colors.gold,
      'surface': colors.surface,
      'raised': colors.surfaceRaised,
      'success': colors.success,
      'warning': colors.warning,
      'danger': colors.danger,
    };

    return Wrap(
      spacing: SanctumSpacing.md,
      runSpacing: SanctumSpacing.md,
      children: [
        for (final entry in entries.entries)
          Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: entry.value,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.glassBorder),
                ),
              ),
              const SizedBox(height: SanctumSpacing.xs),
              Text(entry.key, style: context.type.caption),
            ],
          ),
      ],
    );
  }
}
