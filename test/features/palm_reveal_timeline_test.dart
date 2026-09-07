import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/features/palm/view/palm_reveal_timeline.dart';

PalmRevealFrame _at(double seconds, {Set<PalmLine>? lines}) =>
    PalmRevealTimeline.at(
      Duration(microseconds: (seconds * 1000000).round()),
      lines: lines ?? const {PalmLine.heart, PalmLine.head, PalmLine.life},
    );

void main() {
  group('the beat sheet', () {
    test('runs end to end with no gap and no overlap', () {
      const beats = PalmRevealBeat.values;
      expect(beats.first.start, 0);
      for (var i = 1; i < beats.length; i++) {
        expect(beats[i].start, beats[i - 1].end);
      }
      expect(
        beats.last.end * 1000,
        PalmRevealTimeline.total.inMilliseconds,
      );
    });

    test('names the beat at every instant, including the last', () {
      for (var t = 0.0; t <= 10.5; t += 0.05) {
        final frame = _at(t);
        expect(frame.beatProgress, inInclusiveRange(0, 1));
      }
      expect(_at(10.5).beat, PalmRevealBeat.verdict);
      expect(_at(99).beat, PalmRevealBeat.verdict);
    });
  });

  group('the draw', () {
    test('draws the lines in the order the composition wants', () {
      const windows = PalmRevealTimeline.drawWindows;
      expect(windows[PalmLine.heart]!.$1, lessThan(windows[PalmLine.head]!.$1));
      expect(windows[PalmLine.head]!.$1, lessThan(windows[PalmLine.life]!.$1));
    });

    test('overlaps them, so it reads as handwriting not a progress bar', () {
      const windows = PalmRevealTimeline.drawWindows;
      expect(
        windows[PalmLine.head]!.$1,
        lessThan(windows[PalmLine.heart]!.$2),
      );
      expect(
        windows[PalmLine.life]!.$1,
        lessThan(windows[PalmLine.head]!.$2),
      );
    });

    test('every line is finished before the constellation starts', () {
      // A line still drawing under the node overlay reads as a bug, and
      // it is the kind of thing a nudged window breaks silently.
      final frame = _at(PalmRevealBeat.constellate.start);
      for (final line in PalmLine.principal) {
        expect(frame.progressOf(line), 1);
      }
    });

    test('runs from nothing to whole across its own window', () {
      expect(_at(3.9).progressOf(PalmLine.heart), 0);
      expect(_at(4.7).progressOf(PalmLine.heart), inExclusiveRange(0, 1));
      expect(_at(5.4).progressOf(PalmLine.heart), 1);
      expect(_at(10).progressOf(PalmLine.heart), 1);
    });

    test('never moves backwards', () {
      var previous = 0.0;
      for (var t = 0.0; t <= 10.5; t += 0.02) {
        final now = _at(t).progressOf(PalmLine.life);
        expect(now, greaterThanOrEqualTo(previous - 1e-9));
        previous = now;
      }
    });
  });

  group('a line the hand does not have', () {
    test('is never drawn and never named', () {
      // The whole reason `lines` is a parameter. Plenty of hands have no
      // fate line, and drawing one is a claim the user disproves by
      // looking down.
      const claimed = {PalmLine.heart, PalmLine.head, PalmLine.life};
      for (var t = 0.0; t <= 10.5; t += 0.1) {
        final frame = _at(t, lines: claimed);
        expect(frame.progressOf(PalmLine.fate), 0);
        expect(frame.labelOpacity[PalmLine.fate], isNull);
      }
    });

    test('draws when the creases did support it', () {
      final frame = _at(8.2, lines: {...PalmLine.principal, PalmLine.fate});
      expect(frame.progressOf(PalmLine.fate), 1);
    });
  });

  group('labels', () {
    test('appear only after their line is complete', () {
      final finished = PalmRevealTimeline.drawWindows[PalmLine.heart]!.$2;
      expect(_at(finished - 0.01).labelOpacity[PalmLine.heart], 0);
      expect(
        _at(finished + PalmRevealTimeline.labelFade / 2)
            .labelOpacity[PalmLine.heart],
        inExclusiveRange(0, 1),
      );
      expect(
        _at(finished + PalmRevealTimeline.labelFade)
            .labelOpacity[PalmLine.heart],
        closeTo(1, 1e-9),
      );
    });
  });

  group('the sweep', () {
    test('is on screen only while scanning', () {
      expect(_at(2.1).sweep, isNull);
      expect(_at(3).sweep, isNotNull);
      expect(_at(4.1).sweep, isNull);
    });

    test('crosses the palm exactly once', () {
      expect(_at(PalmRevealBeat.scan.start).sweep, closeTo(0, 1e-9));
      expect(_at(PalmRevealBeat.scan.end - 0.001).sweep, closeTo(1, 0.01));
    });
  });

  group('the still', () {
    test('flashes at the shutter and settles', () {
      expect(_at(1.1).captureFlash, 0);
      expect(_at(1.34).captureFlash, closeTo(1, 0.02));
      expect(_at(2).captureFlash, lessThan(0.2));
    });

    test('drains toward ink once, and stays there', () {
      expect(_at(1.4).inkiness, 0);
      expect(_at(2.2).inkiness, inExclusiveRange(0, 1));
      expect(_at(2.7).inkiness, 1);
      expect(_at(10).inkiness, 1);
    });
  });

  group('frames', () {
    test('yields a fixed number, independent of anything', () {
      expect(PalmRevealTimeline.frames().length, 315);
      expect(PalmRevealTimeline.frames(fps: 60).length, 630);
    });

    test('is the same choreography the live reveal runs', () {
      // The one property that matters: the exported video cannot drift
      // from the app it advertises, because there is no second copy of
      // the timing to drift.
      final generated = PalmRevealTimeline.frames().toList();
      for (final index in [0, 40, 120, 200, 314]) {
        final direct = _at(index / 30);
        expect(generated[index].beat, direct.beat);
        expect(
          generated[index].progressOf(PalmLine.head),
          closeTo(direct.progressOf(PalmLine.head), 1e-9),
        );
      }
    });
  });
}
