import 'package:sanctum/src/domain/models/moon_phase.dart';
import 'package:sanctum/src/domain/models/oracle_card.dart';
import 'package:sanctum/src/domain/models/quiz.dart';
import 'package:sanctum/src/domain/models/ritual.dart';
import 'package:sanctum/src/domain/models/sound_session.dart';

/// All bundled content, loaded once.
class ContentCatalog {
  /// Creates a catalogue.
  const ContentCatalog({
    required this.oracleCards,
    required this.sessions,
    required this.affirmations,
    required this.rituals,
    required this.quizQuestions,
  });

  /// The oracle deck.
  final List<OracleCard> oracleCards;

  /// Sound-bath sessions.
  final List<SoundSession> sessions;

  /// Daily affirmations.
  final List<String> affirmations;

  /// Moon rituals.
  final List<Ritual> rituals;

  /// The onboarding quiz, in order.
  final List<QuizQuestion> quizQuestions;

  /// The ritual for [phase], or `null` if that phase has none.
  ///
  /// Only the four quarter phases carry rituals; the crescents and
  /// gibbous months deliberately do not, so the prompt stays an event
  /// rather than a daily chore.
  Ritual? ritualFor(MoonPhase phase) {
    for (final ritual in rituals) {
      if (ritual.phase == phase) return ritual;
    }
    return null;
  }

  /// The card with [id], or `null`.
  OracleCard? cardById(String id) {
    for (final card in oracleCards) {
      if (card.id == id) return card;
    }
    return null;
  }

  /// The session with [id], or `null`.
  SoundSession? sessionById(String id) {
    for (final session in sessions) {
      if (session.id == id) return session;
    }
    return null;
  }
}
