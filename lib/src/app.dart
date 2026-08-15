import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/routing/app_router.dart';

part 'app.g.dart';

/// Whether the user still needs onboarding.
@Riverpod(keepAlive: true)
Future<bool> needsOnboarding(Ref ref) async {
  final result = await ref.watch(settingsRepositoryProvider).hasOnboarded();
  return switch (result) {
    Ok(:final value) => !value,
    // If the preference cannot be read, showing onboarding again is the
    // benign failure. Skipping it would drop a first-time user straight
    // into an empty app with no explanation.
    Err() => true,
  };
}

/// The router, built once the onboarding answer is known.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final needsOnboarding = ref.watch(needsOnboardingProvider).value ?? false;
  return buildRouter(startAtOnboarding: needsOnboarding);
}

/// The root widget.
///
/// Deliberately thin: it owns the theme and the router, and nothing else.
/// Screens are reached through the router, never constructed here.
class SanctumApp extends ConsumerWidget {
  /// Creates the root widget.
  const SanctumApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(needsOnboardingProvider);

    // Hold the first frame until the start destination is known. This is
    // a single preference read, so the wait is imperceptible — and it
    // avoids the alternative, which is showing /today and then yanking
    // the user to onboarding a frame later.
    if (onboarding.isLoading) {
      return MaterialApp(
        theme: SanctumTheme.nocturne(),
        debugShowCheckedModeBanner: false,
        home: const ColoredBox(color: Color(0xFF0B0616)),
      );
    }

    return MaterialApp.router(
      title: 'Sanctum',
      debugShowCheckedModeBanner: false,
      theme: SanctumTheme.nocturne(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
