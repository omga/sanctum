import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanctum/src/domain/models/paywall.dart';
import 'package:sanctum/src/features/compatibility/view/compatibility_screen.dart';
import 'package:sanctum/src/features/compatibility/view/match_result_screen.dart';
import 'package:sanctum/src/features/compatibility/view/partner_entry_screen.dart';
import 'package:sanctum/src/features/journal/view/journal_screen.dart';
import 'package:sanctum/src/features/onboarding/view/onboarding_screen.dart';
import 'package:sanctum/src/features/payoff/view/payoff_screen.dart';
import 'package:sanctum/src/features/paywall/view/paywall_presenter.dart';
import 'package:sanctum/src/features/paywall/view/paywall_screen.dart';
import 'package:sanctum/src/features/quiz/view/quiz_screen.dart';
import 'package:sanctum/src/features/rituals/view/ritual_screen.dart';
import 'package:sanctum/src/features/sessions/view/session_player_screen.dart';
import 'package:sanctum/src/features/sessions/view/sessions_screen.dart';
import 'package:sanctum/src/features/settings/view/settings_screen.dart';
import 'package:sanctum/src/features/shell/branch_switcher.dart';
import 'package:sanctum/src/features/shell/sanctum_shell.dart';
import 'package:sanctum/src/features/today/view/today_screen.dart';

part 'app_router.g.dart';

/// Sanctum's routes, declared as types rather than strings.
///
/// ## Why typed routes
///
/// `context.go('/sessions/$id')` compiles even when the path is wrong,
/// the parameter is misspelled, or the id is missing — you find out at
/// runtime, on a device, usually not your own.
/// `SessionPlayerRoute(sessionId: id).go(context)` will not compile if
/// any of those are wrong. For the cost of one generated file, an entire
/// category of bug stops existing.
@TypedStatefulShellRoute<SanctumShellRoute>(
  branches: [
    TypedStatefulShellBranch<TodayBranch>(
      routes: [
        TypedGoRoute<TodayRoute>(
          path: '/today',
          routes: [TypedGoRoute<RitualRoute>(path: 'ritual')],
        ),
      ],
    ),
    TypedStatefulShellBranch<MatchBranch>(
      routes: [
        TypedGoRoute<MatchRoute>(
          path: '/match',
          routes: [
            TypedGoRoute<MatchEntryRoute>(path: 'new'),
            TypedGoRoute<MatchResultRoute>(path: 'result'),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<SessionsBranch>(
      routes: [
        TypedGoRoute<SessionsRoute>(
          path: '/sessions',
          routes: [TypedGoRoute<SessionPlayerRoute>(path: ':sessionId')],
        ),
      ],
    ),
    TypedStatefulShellBranch<JournalBranch>(
      routes: [TypedGoRoute<JournalRoute>(path: '/journal')],
    ),
  ],
)
class SanctumShellRoute extends StatefulShellRouteData {
  /// Creates the shell route.
  const SanctumShellRoute();

  /// Replaces go_router's default `IndexedStack` with a cross-fade.
  ///
  /// Picked up by the generator, which passes it to
  /// `StatefulShellRouteData.$route`. The default container swaps
  /// branches with a hard cut; this one keeps every branch mounted — so
  /// playback, scroll offsets and loaded state all survive — and fades
  /// between them.
  static const ShellNavigationContainerBuilder
  $navigatorContainerBuilder = _buildBranchContainer;

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) => SanctumShell(navigationShell: navigationShell);
}

Widget _buildBranchContainer(
  BuildContext context,
  StatefulNavigationShell navigationShell,
  List<Widget> children,
) => BranchSwitcher(
  currentIndex: navigationShell.currentIndex,
  children: children,
);

/// The Today tab.
class TodayBranch extends StatefulShellBranchData {
  /// Creates the branch.
  const TodayBranch();
}

/// The Compatibility tab.
class MatchBranch extends StatefulShellBranchData {
  /// Creates the branch.
  const MatchBranch();
}

/// The Sound tab.
class SessionsBranch extends StatefulShellBranchData {
  /// Creates the branch.
  const SessionsBranch();
}

/// The Journal tab.
class JournalBranch extends StatefulShellBranchData {
  /// Creates the branch.
  const JournalBranch();
}

/// Home: the daily attunement.
class TodayRoute extends GoRouteData with $TodayRoute {
  /// Creates the route.
  const TodayRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PaywallPresenter(child: TodayScreen());
}

/// The moon ritual for the current phase.
///
/// A child of `/today` rather than its own tab: rituals are only open on
/// four phases, and a tab that sits empty most of the month teaches
/// people to stop tapping it.
class RitualRoute extends GoRouteData with $RitualRoute {
  /// Creates the route.
  const RitualRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RitualScreen();
}

/// Compatibility: pick someone to be read against.
class MatchRoute extends GoRouteData with $MatchRoute {
  /// Creates the route.
  const MatchRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CompatibilityScreen();
}

/// Manual entry of the other person.
class MatchEntryRoute extends GoRouteData with $MatchEntryRoute {
  /// Creates the route.
  const MatchEntryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PartnerEntryScreen();
}

/// The reveal.
///
/// The pair travels in query parameters rather than in a provider, so a
/// result can be reopened from history, restored after the process is
/// killed, and eventually linked to from outside the app — all of which
/// a transient in-memory selection would quietly break.
class MatchResultRoute extends GoRouteData with $MatchResultRoute {
  /// Creates the route.
  const MatchResultRoute({
    required this.name,
    required this.birth,
    this.minuteOfBirth,
    this.celebrityId,
  });

  /// Their name.
  final String name;

  /// Their birth date, `yyyy-MM-dd`.
  final String birth;

  /// Their birth time as minutes since midnight, when they know it.
  ///
  /// Absent means unknown, which is also what every link written before
  /// this parameter existed means — so old deep links keep working and
  /// resolve to the same reading they always did.
  final int? minuteOfBirth;

  /// Set when they came from the celebrity catalogue.
  final String? celebrityId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      MatchResultScreen(
        name: name,
        birth: birth,
        minuteOfBirth: minuteOfBirth,
        celebrityId: celebrityId,
      );
}

/// The sound-bath library.
class SessionsRoute extends GoRouteData with $SessionsRoute {
  /// Creates the route.
  const SessionsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SessionsScreen();
}

/// A single session's player.
class SessionPlayerRoute extends GoRouteData with $SessionPlayerRoute {
  /// Creates the route for [sessionId].
  const SessionPlayerRoute({required this.sessionId});

  /// Catalogue id of the session to play.
  final String sessionId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      SessionPlayerScreen(sessionId: sessionId);
}

/// The journal.
class JournalRoute extends GoRouteData with $JournalRoute {
  /// Creates the route.
  const JournalRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const JournalScreen();
}

/// Sanctum Premium, outside the shell so it is full-bleed.
///
/// [moment] is a query parameter rather than a path segment: it changes
/// the copy, not the resource, and a URL like `/paywall?moment=...` keeps
/// the route itself meaningful.
@TypedGoRoute<PaywallRoute>(path: '/paywall')
class PaywallRoute extends GoRouteData with $PaywallRoute {
  /// Creates the route.
  const PaywallRoute({this.moment = PaywallMoment.returningUser});

  /// What earned the user this screen.
  final PaywallMoment moment;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      PaywallScreen(moment: moment);
}

/// The end of onboarding: the reading, and the card people post.
@TypedGoRoute<PayoffRoute>(path: '/payoff')
class PayoffRoute extends GoRouteData with $PayoffRoute {
  /// Creates the route.
  const PayoffRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => PayoffScreen(
    onContinue: () => const TodayRoute().go(context),
  );
}

/// The onboarding quiz, outside the shell so it is full-bleed.
@TypedGoRoute<QuizRoute>(path: '/quiz')
class QuizRoute extends GoRouteData with $QuizRoute {
  /// Creates the route.
  const QuizRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => QuizScreen(
    onFinished: () => const PayoffRoute().go(context),
  );
}

/// Settings, reached from the moon on the Today screen.
@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData with $SettingsRoute {
  /// Creates the route.
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsScreen();
}

/// First-run onboarding, outside the shell so it has no nav bar.
@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
class OnboardingRoute extends GoRouteData with $OnboardingRoute {
  /// Creates the route.
  const OnboardingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const OnboardingScreen();
}

/// Builds the router.
///
/// [startAtOnboarding] is resolved once at startup rather than through a
/// `redirect`: a redirect would have to read async state on every single
/// navigation, and the answer only ever changes once per install.
GoRouter buildRouter({required bool startAtOnboarding}) {
  return GoRouter(
    initialLocation: startAtOnboarding ? '/onboarding' : '/today',
    routes: $appRoutes,
  );
}
