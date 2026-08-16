import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/core/analytics/analytics_event.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/effects/aurora_background.dart';
import 'package:sanctum/src/design_system/effects/starfield.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/routing/app_router.dart';

/// First-run welcome.
class OnboardingScreen extends ConsumerWidget {
  /// Creates the screen.
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.type;

    return Scaffold(
      body: AuroraBackground(
        child: Starfield(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(SanctumSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text('Sanctum', style: type.displayLarge),
                  const SizedBox(height: SanctumSpacing.md),
                  Text(
                    'A quiet room that is only yours.\n\n'
                    'One card, one tone, one honest sentence a day. '
                    'No account, ever. Your name, your birth date and '
                    'your journal stay on this phone.',
                    style: type.bodyLarge,
                  ),
                  const Spacer(),
                  SanctumButton(
                    label: 'Enter',
                    icon: Icons.auto_awesome,
                    expand: true,
                    // Straight into the quiz. Onboarding is marked done
                    // at the *end* of it, so someone who bails half-way
                    // is offered it again rather than dropped into an
                    // app that knows nothing about them.
                    onPressed: () {
                      ref
                          .read(analyticsProvider)
                          .track(const AnalyticsEvent.quizStarted());
                      const QuizRoute().go(context);
                    },
                  ),
                  const SizedBox(height: SanctumSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
