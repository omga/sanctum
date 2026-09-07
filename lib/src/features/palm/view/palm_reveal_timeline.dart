import 'package:flutter/foundation.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';
import 'package:sanctum/src/domain/models/palm.dart';

/// The stages of the reveal, and when each one runs.
///
/// Seconds rather than fractions because this is a beat sheet: the
/// numbers are the thing being designed, and a table of nine decimals
/// normalised against a total nobody can see is unreadable and
/// unadjustable.
enum PalmRevealBeat {
  /// The reticle finds the hand.
  align(0, 1.2),

  /// Shutter bloom; the still freezes and drains toward ink.
  capture(1.2, 2.2),

  /// A light bar crosses the palm, revealing the creases behind it.
  scan(2.2, 4),

  /// The principal lines draw, one after another and overlapping.
  draw(4, 7),

  /// Nodes at the intersections and mounts, joined by hairlines.
  constellate(7, 8.5),

  /// The headline claim and the mark.
  verdict(8.5, 10.5);

  const PalmRevealBeat(this.start, this.end);

  /// When the beat opens, in seconds from the start of the reveal.
  final double start;

  /// When it closes.
  final double end;

  /// How long it runs.
  double get duration => end - start;
}

/// Everything the painter needs to draw one instant of the reveal.
///
/// A value, not a controller. The same struct drives the live reveal and
/// the offscreen render that becomes the video — which is the point:
/// two code paths that drift produce a shared video that does not match
/// the app it advertises.
@immutable
class PalmRevealFrame {
  /// Creates a frame. Built by [PalmRevealTimeline.at].
  const PalmRevealFrame({
    required this.beat,
    required this.beatProgress,
    required this.captureFlash,
    required this.inkiness,
    required this.sweep,
    required this.lineProgress,
    required this.labelOpacity,
    required this.constellation,
    required this.verdict,
  });

  /// Which stage is running.
  final PalmRevealBeat beat;

  /// How far through that stage, eased, `[0, 1]`.
  final double beatProgress;

  /// The shutter bloom, `[0, 1]`, non-zero only during
  /// [PalmRevealBeat.capture].
  final double captureFlash;

  /// How far the still has drained from photograph toward ink, `[0, 1]`.
  ///
  /// Rises once and stays up. The drawn lines have to sit on a surface
  /// that is not competing with them, and a full-colour photograph of a
  /// hand is a very busy surface.
  final double inkiness;

  /// Where the scanning bar sits, `[0, 1]` down the palm, or null when
  /// it is not on screen.
  final double? sweep;

  /// How much of each line has been drawn, `[0, 1]`.
  final Map<PalmLine, double> lineProgress;

  /// How visible each line's name is, `[0, 1]`.
  final Map<PalmLine, double> labelOpacity;

  /// How much of the constellation overlay has appeared, `[0, 1]`.
  final double constellation;

  /// How far in the verdict card is, `[0, 1]`.
  final double verdict;

  /// How much of [line] is drawn, or zero for a line this hand does not
  /// claim.
  double progressOf(PalmLine line) => lineProgress[line] ?? 0;

  /// Value equality, so `CustomPainter.shouldRepaint` can be honest.
  ///
  /// Without it two frames describing the same instant compare unequal,
  /// the painter repaints on every tick regardless, and the one signal
  /// that could skip work is dead weight.
  @override
  bool operator ==(Object other) =>
      other is PalmRevealFrame &&
      other.beat == beat &&
      other.beatProgress == beatProgress &&
      other.captureFlash == captureFlash &&
      other.inkiness == inkiness &&
      other.sweep == sweep &&
      other.constellation == constellation &&
      other.verdict == verdict &&
      mapEquals(other.lineProgress, lineProgress) &&
      mapEquals(other.labelOpacity, labelOpacity);

  @override
  int get hashCode => Object.hash(
    beat,
    beatProgress,
    captureFlash,
    inkiness,
    sweep,
    constellation,
    verdict,
    Object.hashAllUnordered(lineProgress.entries.map((e) => (e.key, e.value))),
    Object.hashAllUnordered(labelOpacity.entries.map((e) => (e.key, e.value))),
  );
}

/// The reveal's choreography, as a pure function of elapsed time.
///
/// ## Why this is not an `AnimationController`
///
/// Because it has to run twice. On screen it is driven by a ticker and
/// may drop a frame; in the exporter it is driven by a fixed `1/30`
/// step and may not. A controller couples the choreography to one of
/// those. A function of elapsed time serves both, and makes the export
/// deterministic — the same scan yields the same video on a flagship
/// and on a four-year-old midrange.
///
/// ## Why the lines overlap
///
/// Each line starts before the one before it has finished, by about half
/// a second. Strictly sequential draws read as a progress bar; this
/// reads as handwriting. It is the same instinct as
/// [SanctumMotion] — "slow, eased, and slightly overlapping".
abstract final class PalmRevealTimeline {
  /// The whole reveal.
  ///
  /// Ten and a half seconds: long enough that the draw does not feel
  /// rushed, short enough to loop on a feed before anybody scrolls.
  static const Duration total = Duration(milliseconds: 10500);

  /// When each line draws, in seconds.
  ///
  /// Heart first because it is uppermost and the one people look for;
  /// life last because it ends at the wrist, which is where the
  /// composition wants to settle before the verdict card. Fate, when a
  /// hand has one, draws under the constellation rather than alongside
  /// the three — it is the exception, and it should read as one.
  static const Map<PalmLine, (double, double)> drawWindows = {
    PalmLine.heart: (4, 5.4),
    PalmLine.head: (4.7, 6.1),
    PalmLine.life: (5.4, 7),
    PalmLine.fate: (7, 8.2),
  };

  /// How long a line's name takes to fade in once the line is finished.
  static const double labelFade = 0.45;

  /// The frame at [elapsed], for a hand that claims [lines].
  ///
  /// [lines] is what the creases actually supported — see
  /// `PalmCreaseSnapper.support`. A line left out of it is never drawn
  /// and never named, which is how a hand with no fate line gets an
  /// honest reveal rather than an invented one.
  static PalmRevealFrame at(
    Duration elapsed, {
    Set<PalmLine> lines = const {
      PalmLine.heart,
      PalmLine.head,
      PalmLine.life,
    },
  }) {
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final beat = _beatAt(seconds);

    return PalmRevealFrame(
      beat: beat,
      beatProgress: SanctumMotion.ease.transform(
        _fraction(seconds, beat.start, beat.end),
      ),
      captureFlash: _flashAt(seconds),
      inkiness: SanctumMotion.ease.transform(
        _fraction(
          seconds,
          PalmRevealBeat.capture.start + 0.35,
          PalmRevealBeat.scan.start + 0.4,
        ),
      ),
      sweep: beat == PalmRevealBeat.scan
          ? SanctumMotion.loop.transform(
              _fraction(
                seconds,
                PalmRevealBeat.scan.start,
                PalmRevealBeat.scan.end,
              ),
            )
          : null,
      lineProgress: {
        for (final line in lines)
          line: SanctumMotion.ease.transform(
            _fraction(seconds, drawWindows[line]!.$1, drawWindows[line]!.$2),
          ),
      },
      labelOpacity: {
        for (final line in lines)
          line: _fraction(
            seconds,
            drawWindows[line]!.$2,
            drawWindows[line]!.$2 + labelFade,
          ),
      },
      constellation: SanctumMotion.enter.transform(
        _fraction(
          seconds,
          PalmRevealBeat.constellate.start,
          PalmRevealBeat.constellate.end,
        ),
      ),
      verdict: SanctumMotion.enter.transform(
        _fraction(
          seconds,
          PalmRevealBeat.verdict.start,
          PalmRevealBeat.verdict.start + 1.1,
        ),
      ),
    );
  }

  /// Every frame of the reveal at [fps], for the offscreen render.
  ///
  /// Generated from the same [at] the live reveal uses, stepped by a
  /// fixed interval so the export never inherits a dropped frame.
  static Iterable<PalmRevealFrame> frames({
    int fps = 30,
    Set<PalmLine> lines = const {
      PalmLine.heart,
      PalmLine.head,
      PalmLine.life,
    },
  }) sync* {
    assert(fps > 0, 'a video has frames');
    final count = (total.inMilliseconds * fps / 1000).round();
    for (var i = 0; i < count; i++) {
      yield at(
        Duration(microseconds: (i * 1000000 / fps).round()),
        lines: lines,
      );
    }
  }

  static PalmRevealBeat _beatAt(double seconds) {
    for (final beat in PalmRevealBeat.values) {
      if (seconds < beat.end) return beat;
    }
    return PalmRevealBeat.verdict;
  }

  /// A short bloom at the shutter, up fast and down slow.
  static double _flashAt(double seconds) {
    const peak = 0.14;
    final since = seconds - PalmRevealBeat.capture.start;
    if (since < 0) return 0;
    if (since < peak) return since / peak;
    return 1 - _fraction(since, peak, peak + 0.5);
  }

  static double _fraction(double value, double start, double end) =>
      ((value - start) / (end - start)).clamp(0.0, 1.0);
}
