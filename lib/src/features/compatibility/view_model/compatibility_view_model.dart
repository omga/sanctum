import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/analytics/analytics_event.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/domain/models/celebrity.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/quiz.dart';
import 'package:sanctum/src/domain/services/compatibility_composer.dart';
import 'package:sanctum/src/domain/services/compatibility_gate.dart';

part 'compatibility_view_model.g.dart';

/// Everything the compatibility tab needs to draw itself.
class CompatibilityUiState {
  /// Creates the state.
  const CompatibilityUiState({
    required this.you,
    required this.celebrities,
    required this.saved,
    required this.revealedIds,
    required this.hasSharedInvite,
    required this.isPremium,
    required this.now,
  });

  /// The user, or `null` if we do not have their birth date yet.
  final MatchPerson? you;

  /// The bundled celebrity catalogue.
  final List<Celebrity> celebrities;

  /// Matches already revealed, newest first.
  final List<CompatibilityMatch> saved;

  /// Ids of revealed matches.
  final Set<String> revealedIds;

  /// Whether an invite has ever been sent.
  final bool hasSharedInvite;

  /// Whether the user is a subscriber.
  final bool isPremium;

  /// Now, injected so composed matches are testable.
  final DateTime now;

  /// Whether we know enough to compute anything.
  bool get isReady => you != null;

  /// Free reveals left.
  int get revealsRemaining => CompatibilityGate.revealsRemaining(
    revealedIds: revealedIds,
    isPremium: isPremium,
  );

  /// What the user may do with the match against [id].
  CompatibilityAccess accessFor(String id) => CompatibilityGate.decide(
    matchId: id,
    revealedIds: revealedIds,
    hasSharedInvite: hasSharedInvite,
    isPremium: isPremium,
  );

  /// The reading for [them], composing it if it is new.
  ///
  /// A previously revealed match is returned as stored rather than
  /// recomposed, so its date — and anything else recorded at the time —
  /// stays what the user first saw.
  CompatibilityMatch? matchWith(MatchPerson them) {
    final me = you;
    if (me == null) return null;

    for (final match in saved) {
      if (match.id == them.key) return match;
    }

    return CompatibilityComposer.compose(you: me, them: them, now: now);
  }
}

/// Drives the compatibility tab.
@riverpod
class CompatibilityController extends _$CompatibilityController {
  @override
  Future<CompatibilityUiState> build() async {
    final catalog = await ref.watch(contentCatalogProvider.future);
    final answers = (await ref.watch(quizRepositoryProvider).load())
        .getOrElse(const QuizAnswers());
    final stored = (await ref.watch(compatibilityRepositoryProvider).load())
        .getOrElse(const CompatibilityState());

    return CompatibilityUiState(
      you: _personFrom(answers),
      celebrities: catalog.celebrities,
      saved: stored.matches,
      revealedIds: stored.revealed,
      hasSharedInvite: stored.hasSharedInvite,
      isPremium: ref.watch(isPremiumProvider),
      now: ref.watch(clockProvider).now(),
    );
  }

  /// The user as one half of a match, from what onboarding already asked.
  ///
  /// Reusing the quiz answers rather than asking again matters: a second
  /// "when were you born?" in an app that has already been told is the
  /// clearest possible signal that nothing is joined up.
  MatchPerson? _personFrom(QuizAnswers answers) {
    final birth = answers.dates['birth_date'];
    if (birth == null) return null;
    return MatchPerson(name: answers.name ?? 'You', birthDate: birth);
  }

  /// Records the user's own birth date, for anyone who reached this tab
  /// without it. Written back to the quiz answers so there stays exactly
  /// one place the app remembers when the user was born.
  Future<void> setYourBirthDate(DateTime date) async {
    final repository = ref.read(quizRepositoryProvider);
    final answers = (await repository.load()).getOrElse(const QuizAnswers());
    await repository.save(answers.withDate('birth_date', date));
    ref.invalidateSelf();
  }

  /// Records that an invite was sent, which buys the first reveal.
  Future<void> recordInviteSent() async {
    ref.read(analyticsProvider).track(const AnalyticsEvent.matchInviteSent());
    await ref.read(compatibilityRepositoryProvider).recordInviteSent();
    ref.invalidateSelf();
  }

  /// Persists [match] and marks it unlocked.
  Future<void> reveal(CompatibilityMatch match) async {
    ref
        .read(analyticsProvider)
        .track(
          AnalyticsEvent.matchRevealed(
            // Whether this one was bought with an invite or with money
            // is the whole question the gate exists to answer.
            access: match.them.celebrityId == null ? 'manual' : 'celebrity',
          ),
        );
    await ref.read(compatibilityRepositoryProvider).reveal(match);
    ref.invalidateSelf();
  }
}
