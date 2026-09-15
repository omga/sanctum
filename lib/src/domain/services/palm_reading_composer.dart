import 'package:meta/meta.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_composer.dart';
import 'package:sanctum/src/domain/services/palm_line_template.dart';

/// How a line compares with the one the template expected.
enum PalmLineLength {
  /// Noticeably shorter than typical.
  short,

  /// About what the template expected.
  typical,

  /// Noticeably longer.
  long,
}

/// One line, as the reading will talk about it.
@immutable
class PalmLineNote {
  /// Creates a note.
  const PalmLineNote({
    required this.line,
    required this.length,
    required this.clarity,
  });

  /// Which line.
  final PalmLine line;

  /// How it compares with the template.
  final PalmLineLength length;

  /// How clearly the photograph showed it, `[0, 1]`.
  ///
  /// Not a claim about the hand — a dim room lowers this on a hand whose
  /// lines are perfectly deep. It is here so the copy can be more
  /// tentative when the evidence is thin, and so a retake can be offered
  /// when it is thin across the board.
  final double clarity;
}

/// What a scan is allowed to say.
@immutable
class PalmProfile {
  /// Creates a profile.
  const PalmProfile({
    required this.id,
    required this.notes,
    required this.measured,
    this.background = 0,
  });

  /// The scan this describes.
  final String id;

  /// One note per claimed line, in the order the reveal drew them.
  final List<PalmLineNote> notes;

  /// Whether the creases were looked for at all — see
  /// [PalmReading.measured].
  final bool measured;

  /// The mean clarity across the lines.
  double get clarity => notes.isEmpty
      ? 0
      : notes.map((note) => note.clarity).reduce((a, b) => a + b) /
            notes.length;

  /// How crease-like the palm is away from the lines — see
  /// `PalmReading.background`.
  final double background;

  /// How far the traced lines stand out from the palm around them.
  double get lift => clarity - background;

  /// Whether the photograph was too poor to say much.
  ///
  /// Decided by [lift], not by [clarity]. The first version asked for a
  /// mean clarity of 0.2, and on a Pixel 6 a bare palm whose lines were
  /// traced perfectly failed it while the same palm with the lines gone
  /// over in pen passed: the filter scales against the strongest edges
  /// in the crop, so a real crease reads low in absolute terms and a pen
  /// line reads high. Neither number says whether the photograph was
  /// readable. Whether the lines stand out from the rest of the palm
  /// does — a blurred or unlit photograph has lines no different from
  /// their surroundings, and a readable one does not, pen or no pen.
  ///
  /// False when nothing was measured. "We did not look" is not evidence
  /// that a hand read faintly.
  bool get isThin => measured && lift < PalmReadingComposer.minLift;

  /// The note for [line], if the hand claimed it.
  PalmLineNote? noteOf(PalmLine line) {
    for (final note in notes) {
      if (note.line == line) return note;
    }
    return null;
  }
}

/// Turns a scan into the handful of facts a reading may be built on.
///
/// ## Measured against the template, not against a population
///
/// "A long life line" needs a comparison, and the only one available on
/// device is the authored template — so that is what it says, and this
/// document should not pretend otherwise. The template is a prior taken
/// from standard palmistry proportions, not a mean over a dataset, and
/// until spike S3 fits it to real captures a "long" line means longer
/// than the prior expected rather than longer than other people's.
///
/// That is a weaker claim than the genre usually makes and it is the
/// only one the arithmetic supports.
///
/// ## Why the reading composes from structure rather than prose
///
/// Same rule the relationship report follows: the scores are computed
/// once and the words are looked up, never the other way round. Here the
/// structure is `(line, length band, clarity)` and the sentences live in
/// the content JSON, so a translator changes words and can never change
/// what the app claims about somebody's hand.
abstract final class PalmReadingComposer {
  /// How much longer than the template counts as long.
  ///
  /// Ten percent. Tighter than that and landmark noise decides the band;
  /// looser and almost every hand reads as typical, which is true but
  /// makes for a reading nobody would pay for. Not calibrated.
  static const double longRatio = 1.1;

  /// And how much shorter counts as short.
  static const double shortRatio = 0.9;

  /// How much more crease-like than the rest of the palm the lines must
  /// be before a reading is shown.
  ///
  /// Low on purpose. Refusing a reading over lines the user can see were
  /// drawn correctly is a broken screen at the point of sale; showing one
  /// on a mediocre photograph costs almost nothing, because a line the
  /// tracer could not move stays on its prior and reads as typical. Not
  /// calibrated — the debug readout on the reading screen prints the
  /// three numbers this is decided from, for exactly that.
  static const double minLift = 0.03;

  /// The profile for [reading].
  static PalmProfile compose(PalmReading reading) {
    final notes = <PalmLineNote>[];

    for (final curve in reading.canonicalCurves) {
      // Against the prior this line was traced from, not the canonical
      // template: a life line fitted to a thumb set further out is a
      // slightly different length before any crease moves it, and
      // measuring that difference would call a hand's line short or long
      // for where its thumb is.
      final prior =
          reading.priors[curve.line] ?? PalmLineTemplate.of(curve.line);
      final expected = prior.length;
      final ratio = expected == 0 ? 1.0 : curve.length / expected;

      notes.add(
        PalmLineNote(
          line: curve.line,
          length: switch (ratio) {
            >= longRatio => PalmLineLength.long,
            <= shortRatio => PalmLineLength.short,
            _ => PalmLineLength.typical,
          },
          clarity: (reading.support[curve.line] ?? 0).clamp(0.0, 1.0),
        ),
      );
    }

    return PalmProfile(
      id: reading.id,
      notes: notes,
      measured: reading.measured,
      background: reading.background,
    );
  }
}
