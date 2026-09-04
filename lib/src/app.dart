import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/l10n/sanctum_locales.dart';
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

/// The locale the whole app is shown in.
///
/// The *same* provider the content catalogue resolves from, handed to
/// `MaterialApp` as an explicit `locale`. Letting Flutter resolve the
/// widget tree from the platform while the JSON resolved from a stored
/// preference is exactly the disagreement `SanctumLocales` was written
/// to make impossible — English chrome around Ukrainian readings, with
/// nothing in the type system to notice.
@Riverpod(keepAlive: true)
Locale appLocale(Ref ref) => ref.watch(contentLocaleProvider);

/// The root widget.
///
/// Deliberately thin: it owns the theme, the router, and the one listener
/// that has to outlive every screen. Screens are reached through the
/// router, never constructed here.
class SanctumApp extends ConsumerStatefulWidget {
  /// Creates the root widget.
  const SanctumApp({super.key});

  @override
  ConsumerState<SanctumApp> createState() => _SanctumAppState();
}

class _SanctumAppState extends ConsumerState<SanctumApp> {
  StreamSubscription<bool>? _notificationTaps;

  @override
  void initState() {
    super.initState();

    // Tapping the media notification should land on the session that is
    // playing, not on whatever screen the app happened to be left on.
    //
    // This is subscribed at the root on purpose. The notification is
    // tappable precisely when the app is backgrounded and no sound
    // screen is mounted, so a listener living on the player — the
    // obvious place for it — would be disposed exactly when it was
    // needed. `androidNotificationClickStartsActivity` (on by default)
    // brings the activity forward; this is what decides where it lands.
    //
    // `notificationClicked` is a BehaviorSubject seeded `false`, so the
    // filter below discards the seed, and a tap that arrives *during*
    // startup is replayed to this listener rather than lost — which is
    // the cold-start case, where the service outlived the UI.
    _notificationTaps = AudioService.notificationClicked
        .where((clicked) => clicked)
        .listen((_) => _openPlayingSession());
  }

  @override
  void dispose() {
    unawaited(_notificationTaps?.cancel());
    super.dispose();
  }

  /// Navigates to whatever is loaded in the audio handler.
  void _openPlayingSession() {
    // Deferred a frame: a tap can be replayed during `initState`, and
    // navigating while the first frame is still being built throws.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // The handler is the source of truth for what is playing. If it
      // holds nothing — the service was killed and rebuilt without a
      // session — there is no player worth opening, and dropping the
      // user on /today is the honest outcome.
      final session = ref.read(audioServiceProvider).currentSession;
      if (session == null) return;

      final router = ref.read(appRouterProvider);
      final destination = SessionPlayerRoute(sessionId: session.id).location;

      // `go` on the same location rebuilds the branch and resets the
      // screen, so a second tap on the notification while the player is
      // already open would visibly flicker.
      if (router.state.uri.toString() == destination) return;
      router.go(destination);
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(needsOnboardingProvider);
    // Held for the same reason as the onboarding answer: rendering in
    // the device's language and swapping to the chosen one a frame later
    // is worse than an imperceptible wait on one more preference read.
    final language = ref.watch(languagePreferenceProvider);

    // Hold the first frame until the start destination is known. This is
    // a single preference read, so the wait is imperceptible — and it
    // avoids the alternative, which is showing /today and then yanking
    // the user to onboarding a frame later.
    if (onboarding.isLoading || language.isLoading) {
      return MaterialApp(
        theme: SanctumTheme.nocturne(),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: SanctumLocales.supported,
        home: const ColoredBox(color: Color(0xFF0B0616)),
      );
    }

    return MaterialApp.router(
      // Not localised: the app is called Sanctum everywhere.
      title: 'Sanctum',
      debugShowCheckedModeBanner: false,
      theme: SanctumTheme.nocturne(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // The same list the content catalogue resolves against, so the
      // JSON and the ARB strings cannot end up in different languages.
      supportedLocales: SanctumLocales.supported,
      locale: ref.watch(appLocaleProvider),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
