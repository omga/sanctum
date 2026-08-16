import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/core/analytics/analytics_event.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/effects/aurora_background.dart';
import 'package:sanctum/src/design_system/effects/starfield.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/reading.dart';
import 'package:sanctum/src/features/payoff/view/widgets/shareable_card.dart';
import 'package:sanctum/src/features/payoff/view_model/payoff_view_model.dart';
import 'package:sanctum/src/features/sharing/view_model/share_controller.dart';
import 'package:sanctum/src/features/today/view_model/reminder_view_model.dart';

/// The end of onboarding: what we heard, said back.
///
/// This is the emotional peak of the whole funnel and, with an
/// organic-first channel, also the acquisition surface — so the card is a
/// first-class thing on it rather than a share icon in a corner.
///
/// Deliberately *not* the paywall. Asking for money on the same screen
/// as the payoff makes the payoff read as bait; the paywall arrives
/// later, on its own terms, when the trigger says it has been earned.
class PayoffScreen extends ConsumerStatefulWidget {
  /// Creates the payoff screen.
  const PayoffScreen({required this.onContinue, super.key});

  /// Called when the user moves on into the app.
  final VoidCallback onContinue;

  @override
  ConsumerState<PayoffScreen> createState() => _PayoffScreenState();
}

class _PayoffScreenState extends ConsumerState<PayoffScreen> {
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // The end of the funnel onboarding is measured against.
    ref.read(analyticsProvider).track(const AnalyticsEvent.payoffShown());
  }

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(readingProvider);

    ref
      ..watch(shareControllerProvider)
      ..listen(shareControllerProvider, (_, next) {
        if (next case AsyncError(:final error)) {
          ScaffoldMessenger.maybeOf(context)
              ?.showSnackBar(SnackBar(content: Text('$error')));
        }
      });

    return Scaffold(
      body: AuroraBackground(
        intensity: 1.2,
        child: Starfield(
          child: SafeArea(
            child: reading.when(
   skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (data) => _Body(
                reading: data,
                cardKey: _cardKey,
                onShare: () {
                  ref
                      .read(analyticsProvider)
                      .track(const AnalyticsEvent.payoffShared());
                  unawaited(
                    ref
                        .read(shareControllerProvider.notifier)
                        .share(
                          _cardKey,
                          text: 'My reading from Sanctum',
                        ),
                  );
                },
                // The permission prompt belongs here and nowhere
                // else. The user has just read a reading that ended by
                // quoting their own answer about showing up daily, so
                // the ask is the natural next sentence. Asked on first
                // launch instead, it gets declined once and can never be
                // asked again.
                onContinue: () {
                  unawaited(
                    ref
                        .read(reminderControllerProvider.notifier)
                        .enable(),
                  );
                  widget.onContinue();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.reading,
    required this.cardKey,
    required this.onShare,
    required this.onContinue,
  });

  final Reading reading;
  final GlobalKey cardKey;
  final VoidCallback onShare;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    var beat = 0;
    Duration next() => Duration(milliseconds: 220 * beat++);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SanctumSpacing.xl,
        SanctumSpacing.xxl,
        SanctumSpacing.xl,
        SanctumSpacing.xxl,
      ),
      children: [
        // Lines arrive one at a time rather than all at once. The pacing
        // is the difference between reading a result and being told
        // something.
        Text(reading.headline, style: type.displayMedium)
            .animate(delay: next())
            .fadeIn(duration: SanctumMotion.calm)
            .slideY(begin: 0.12, end: 0),

        const SizedBox(height: SanctumSpacing.lg),
        Text(
          reading.opening,
          style: type.bodyLarge,
        ).animate(delay: next()).fadeIn(duration: SanctumMotion.calm),

        if (reading.recognition case final line?) ...[
          const SizedBox(height: SanctumSpacing.lg),
          Text(
            line,
            style: type.quote,
          ).animate(delay: next()).fadeIn(duration: SanctumMotion.ritual),
        ],

        if (reading.intention case final line?) ...[
          const SizedBox(height: SanctumSpacing.lg),
          Text(
            line,
            style: type.bodyLarge,
          ).animate(delay: next()).fadeIn(duration: SanctumMotion.calm),
        ],

        if (reading.closing case final line?) ...[
          const SizedBox(height: SanctumSpacing.md),
          Text(
            line,
            style: type.bodySmall,
          ).animate(delay: next()).fadeIn(duration: SanctumMotion.calm),
        ],

        const SizedBox(height: SanctumSpacing.xxl),

        // RepaintBoundary is what makes the capture possible at all, so
        // the key lives on it rather than on any wrapper.
        RepaintBoundary(
              key: cardKey,
              child: ShareableCard(reading: reading),
            )
            .animate(delay: next())
            .fadeIn(duration: SanctumMotion.ritual)
            .scaleXY(begin: 0.96, end: 1),

        const SizedBox(height: SanctumSpacing.xl),
        SanctumButton(
          label: 'Share this',
          icon: Icons.ios_share,
          variant: SanctumButtonVariant.ghost,
          expand: true,
          onPressed: onShare,
        ).animate(delay: next()).fadeIn(),

        const SizedBox(height: SanctumSpacing.md),
        SanctumButton(
          label: 'Enter Sanctum',
          icon: Icons.auto_awesome,
          expand: true,
          onPressed: onContinue,
        ).animate(delay: next()).fadeIn(),

        const SizedBox(height: SanctumSpacing.xl),
        Text(
          // Required for store review of divination content, and it is
          // simply true.
          'For entertainment purposes only.',
          textAlign: TextAlign.center,
          style: type.caption,
        ).animate(delay: next()).fadeIn(),
      ],
    );
  }
}
