import 'package:sanctum/src/domain/models/celebrity.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
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
    required this.celebrities,
    this.copy = CopyBook.empty,
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

  /// Public figures the user can match themselves against.
  final List<Celebrity> celebrities;

  /// The reading copy, in the loaded locale.
  ///
  /// Defaulted so a test can build a catalogue without one; anything
  /// that actually composes a reading must pass it, and will throw on
  /// the first missing key if it does not.
  final CopyBook copy;

  /// The celebrities in [group], in catalogue order.
  List<Celebrity> celebritiesIn(CelebrityGroup group) =>
      [for (final one in celebrities) if (one.group == group) one];

  /// The celebrity with [id], or `null`.
  Celebrity? celebrityById(String id) {
    for (final one in celebrities) {
      if (one.id == id) return one;
    }
    return null;
  }

  /// Every ritual written for [phase], in catalogue order.
  ///
  /// Only the four quarter phases carry rituals; the crescents and
  /// gibbous months deliberately do not, so the prompt stays an event
  /// rather than a daily chore. Each of those four carries several, and
  /// `RitualSelector` decides which one a given moon opens with — see
  /// there for why the choice is per cycle rather than per day.
  List<Ritual> ritualsFor(MoonPhase phase) =>
      [for (final ritual in rituals) if (ritual.phase == phase) ritual];

  /// Whether [phase] has any ritual at all.
  ///
  /// For "is there something to do tonight?" questions. Which ritual it
  /// is depends on the date, so anything showing one to a user must go
  /// through `RitualSelector` rather than reaching for the first match.
  bool hasRitualFor(MoonPhase phase) {
    for (final ritual in rituals) {
      if (ritual.phase == phase) return true;
    }
    return false;
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
