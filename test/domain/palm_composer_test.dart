import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_composer.dart';
import 'package:sanctum/src/domain/services/palm_crease_snapper.dart';
import 'package:sanctum/src/domain/services/palm_line_template.dart';

import '../support/palm_fixtures.dart';

final _at = DateTime.utc(2026, 9, 8, 10, 12);

/// Creases along whichever template lines are named.
class _Creases implements RidgeField {
  _Creases(Iterable<PalmLine> lines)
    : _samples = [
        for (final line in lines)
          ...PalmLineTemplate.of(line).sample(perSegment: 40),
      ];

  final List<PalmPoint> _samples;

  static const double _sigma = 0.014;

  @override
  double responseAt(PalmPoint point) {
    var nearest = double.infinity;
    for (final sample in _samples) {
      nearest = math.min(nearest, sample.distanceTo(point));
    }
    final ratio = nearest / _sigma;
    return math.exp(-ratio * ratio);
  }
}

void main() {
  group('compose', () {
    test('returns null when the pose cannot be rectified', () {
      final collapsed = {
        for (final entry in canonicalHand.entries)
          entry.key: const PalmPoint(0.5, 0.5),
      };
      expect(
        PalmComposer.compose(
          landmarks: handAt(pose(), canonical: collapsed),
          at: _at,
        ),
        isNull,
      );
    });

    test('names the scan by its instant, never by its hand', () {
      // The id is stored; the hand is not. It has to identify a session
      // and nothing else, so two scans of the same palm differ and no
      // two ids can be joined into a record of a person.
      final first = PalmComposer.compose(landmarks: goodHand(), at: _at)!;
      final second = PalmComposer.compose(
        landmarks: goodHand(),
        at: _at.add(const Duration(seconds: 30)),
      )!;

      expect(first.id, 'palm:2026-09-08T10:12:00:right');
      expect(first.id, isNot(second.id));
      expect(
        PalmComposer.compose(
          landmarks: handAt(pose(mirror: true), handedness: Handedness.left),
          at: _at,
        )!.id,
        endsWith(':left'),
      );
    });

    test('places the lines on the frame, ready to draw', () {
      final reading = PalmComposer.compose(landmarks: goodHand(), at: _at)!;
      for (final curve in reading.curves) {
        expect(curve.space, PalmSpace.image);
      }
      expect(reading.curveOf(PalmLine.heart), isNotNull);
    });
  });

  group('what a hand is allowed to be told', () {
    test('always claims the three lines every hand has', () {
      // Even on a field with nothing in it. A heart line the filter
      // cannot find is a statement about the lighting, not the hand, and
      // refusing to draw it makes the app look broken on a dim evening.
      final reading = PalmComposer.compose(
        landmarks: goodHand(),
        at: _at,
        field: _Creases(const []),
      )!;

      expect(reading.claimed, containsAll(PalmLine.principal));
      expect(
        reading.curves.map((curve) => curve.line),
        containsAll(PalmLine.principal),
      );
    });

    test('stays quiet about a fate line that is not there', () {
      final reading = PalmComposer.compose(
        landmarks: goodHand(),
        at: _at,
        field: _Creases(PalmLine.principal),
      )!;

      expect(reading.claimed, isNot(contains(PalmLine.fate)));
      expect(reading.curveOf(PalmLine.fate), isNull);
      expect(
        reading.support[PalmLine.fate],
        lessThan(PalmComposer.fateThreshold),
      );
    });

    test('claims a fate line the creases do support', () {
      final reading = PalmComposer.compose(
        landmarks: goodHand(),
        at: _at,
        field: _Creases([...PalmLine.principal, PalmLine.fate]),
      )!;

      expect(reading.claimed, contains(PalmLine.fate));
      expect(reading.curveOf(PalmLine.fate), isNotNull);
    });

    test('draws the bare template when there is no field at all', () {
      // The live viewfinder's case: a preview frame, no time to filter
      // it. Nothing is claimed beyond the three, and support is honest
      // about knowing nothing.
      final reading = PalmComposer.compose(landmarks: goodHand(), at: _at)!;

      expect(reading.claimed, PalmLine.principal.toSet());
      expect(reading.support.values, everyElement(0));
    });
  });

  group('snapping happens in canonical space', () {
    test('so the same hand at two distances gets the same lines', () {
      // The reason the order is rectify, snap, place. Snapping in frame
      // space would make the search radius mean a different fraction of
      // a palm on a hand held near the lens than on one held far away,
      // and the same numbers would be tight on one scan and sloppy on
      // the next.
      final field = _Creases([...PalmLine.principal, PalmLine.fate]);
      final near = PalmComposer.compose(
        landmarks: handAt(pose(scale: 0.62)),
        at: _at,
        field: field,
      )!;
      final far = PalmComposer.compose(
        landmarks: handAt(pose(scale: 0.38)),
        at: _at,
        field: field,
      )!;

      expect(near.claimed, far.claimed);
      for (final line in near.claimed) {
        expect(
          near.support[line],
          closeTo(far.support[line]!, 1e-9),
        );
      }
    });

    test('and a rotated hand gets them too', () {
      final field = _Creases(PalmLine.principal);
      final upright = PalmComposer.compose(
        landmarks: goodHand(),
        at: _at,
        field: field,
      )!;
      final tilted = PalmComposer.compose(
        landmarks: handAt(pose(rotation: 0.5)),
        at: _at,
        field: field,
      )!;

      for (final line in PalmLine.principal) {
        expect(
          upright.support[line],
          closeTo(tilted.support[line]!, 1e-9),
        );
      }
    });
  });
}
