// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $sanctumShellRoute,
  $paywallRoute,
  $payoffRoute,
  $quizRoute,
  $onboardingRoute,
];

RouteBase get $sanctumShellRoute => StatefulShellRouteData.$route(
  navigatorContainerBuilder: SanctumShellRoute.$navigatorContainerBuilder,
  factory: $SanctumShellRouteExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/today',
          hasOverriddenOnExit: false,
          factory: $TodayRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'ritual',
              hasOverriddenOnExit: false,
              factory: $RitualRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/match',
          hasOverriddenOnExit: false,
          factory: $MatchRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'new',
              hasOverriddenOnExit: false,
              factory: $MatchEntryRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'result',
              hasOverriddenOnExit: false,
              factory: $MatchResultRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/sessions',
          hasOverriddenOnExit: false,
          factory: $SessionsRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: ':sessionId',
              hasOverriddenOnExit: false,
              factory: $SessionPlayerRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/journal',
          hasOverriddenOnExit: false,
          factory: $JournalRoute._fromState,
        ),
      ],
    ),
  ],
);

extension $SanctumShellRouteExtension on SanctumShellRoute {
  static SanctumShellRoute _fromState(GoRouterState state) =>
      const SanctumShellRoute();
}

mixin $TodayRoute on GoRouteData {
  static TodayRoute _fromState(GoRouterState state) => const TodayRoute();

  @override
  String get location => GoRouteData.$location('/today');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $RitualRoute on GoRouteData {
  static RitualRoute _fromState(GoRouterState state) => const RitualRoute();

  @override
  String get location => GoRouteData.$location('/today/ritual');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MatchRoute on GoRouteData {
  static MatchRoute _fromState(GoRouterState state) => const MatchRoute();

  @override
  String get location => GoRouteData.$location('/match');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MatchEntryRoute on GoRouteData {
  static MatchEntryRoute _fromState(GoRouterState state) =>
      const MatchEntryRoute();

  @override
  String get location => GoRouteData.$location('/match/new');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MatchResultRoute on GoRouteData {
  static MatchResultRoute _fromState(GoRouterState state) => MatchResultRoute(
    name: state.uri.queryParameters['name']!,
    birth: state.uri.queryParameters['birth']!,
    celebrityId: state.uri.queryParameters['celebrity-id'],
  );

  MatchResultRoute get _self => this as MatchResultRoute;

  @override
  String get location => GoRouteData.$location(
    '/match/result',
    queryParams: {
      'name': _self.name,
      'birth': _self.birth,
      if (_self.celebrityId != null) 'celebrity-id': _self.celebrityId,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SessionsRoute on GoRouteData {
  static SessionsRoute _fromState(GoRouterState state) => const SessionsRoute();

  @override
  String get location => GoRouteData.$location('/sessions');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SessionPlayerRoute on GoRouteData {
  static SessionPlayerRoute _fromState(GoRouterState state) =>
      SessionPlayerRoute(sessionId: state.pathParameters['sessionId']!);

  SessionPlayerRoute get _self => this as SessionPlayerRoute;

  @override
  String get location => GoRouteData.$location(
    '/sessions/${Uri.encodeComponent(_self.sessionId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $JournalRoute on GoRouteData {
  static JournalRoute _fromState(GoRouterState state) => const JournalRoute();

  @override
  String get location => GoRouteData.$location('/journal');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $paywallRoute => GoRouteData.$route(
  path: '/paywall',
  hasOverriddenOnExit: false,
  factory: $PaywallRoute._fromState,
);

mixin $PaywallRoute on GoRouteData {
  static PaywallRoute _fromState(GoRouterState state) => PaywallRoute(
    moment:
        _$convertMapValue(
          'moment',
          state.uri.queryParameters,
          _$PaywallMomentEnumMap._$fromName,
        ) ??
        PaywallMoment.returningUser,
  );

  PaywallRoute get _self => this as PaywallRoute;

  @override
  String get location => GoRouteData.$location(
    '/paywall',
    queryParams: {
      if (_self.moment != PaywallMoment.returningUser)
        'moment': _$PaywallMomentEnumMap[_self.moment],
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

const _$PaywallMomentEnumMap = {
  PaywallMoment.lockedContent: 'locked-content',
  PaywallMoment.streakEarned: 'streak-earned',
  PaywallMoment.ritualCompleted: 'ritual-completed',
  PaywallMoment.sessionsSampled: 'sessions-sampled',
  PaywallMoment.returningUser: 'returning-user',
};

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T? Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}

extension<T extends Enum> on Map<T, String> {
  T? _$fromName(String? value) =>
      entries.where((element) => element.value == value).firstOrNull?.key;
}

RouteBase get $payoffRoute => GoRouteData.$route(
  path: '/payoff',
  hasOverriddenOnExit: false,
  factory: $PayoffRoute._fromState,
);

mixin $PayoffRoute on GoRouteData {
  static PayoffRoute _fromState(GoRouterState state) => const PayoffRoute();

  @override
  String get location => GoRouteData.$location('/payoff');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $quizRoute => GoRouteData.$route(
  path: '/quiz',
  hasOverriddenOnExit: false,
  factory: $QuizRoute._fromState,
);

mixin $QuizRoute on GoRouteData {
  static QuizRoute _fromState(GoRouterState state) => const QuizRoute();

  @override
  String get location => GoRouteData.$location('/quiz');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $onboardingRoute => GoRouteData.$route(
  path: '/onboarding',
  hasOverriddenOnExit: false,
  factory: $OnboardingRoute._fromState,
);

mixin $OnboardingRoute on GoRouteData {
  static OnboardingRoute _fromState(GoRouterState state) =>
      const OnboardingRoute();

  @override
  String get location => GoRouteData.$location('/onboarding');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
