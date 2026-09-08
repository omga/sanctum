import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/data/services/palm/palm_ridge_filter.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_crease_snapper.dart';
import 'package:sanctum/src/domain/services/palm_line_template.dart';

const _size = 128;
const _background = 200;
const _ink = 80;

/// Canonical point to a pixel in the crop.
Offset _pixelOf(PalmPoint point, {double margin = PalmRidgeFilter.margin}) {
  final span = 1 + margin * 2;
  return Offset(
    (point.x + margin) / span * (_size - 1),
    (point.y + margin) / span * (_size - 1),
  );
}

/// A flat grey image with [creases] stamped into it, dark and thin.
///
/// A palm built in the test rather than photographed. The filter's whole
/// job is "darker than its flanks, in some direction", and a synthetic
/// crease exercises exactly that with a position known to the pixel —
/// which no photograph of a hand can offer.
Uint8List _palmImage(
  List<PalmCurve> creases, {
  double thickness = 1.6,
  int background = _background,
}) {
  final bytes = Uint8List(_size * _size * 4);
  for (var i = 0; i < _size * _size; i++) {
    bytes[i * 4] = background;
    bytes[i * 4 + 1] = background;
    bytes[i * 4 + 2] = background;
    bytes[i * 4 + 3] = 255;
  }

  final reach = thickness.ceil();
  for (final curve in creases) {
    for (final point in curve.sample(perSegment: 60)) {
      final centre = _pixelOf(point);
      for (var dy = -reach; dy <= reach; dy++) {
        for (var dx = -reach; dx <= reach; dx++) {
          if (dx * dx + dy * dy > thickness * thickness) continue;
          final x = (centre.dx + dx).round();
          final y = (centre.dy + dy).round();
          if (x < 0 || y < 0 || x >= _size || y >= _size) continue;
          final at = (y * _size + x) * 4;
          bytes[at] = _ink;
          bytes[at + 1] = _ink;
          bytes[at + 2] = _ink;
        }
      }
    }
  }
  return bytes;
}

/// A straight crease from [a] to [b], in canonical units.
PalmCurve _line(PalmPoint a, PalmPoint b) => PalmCurve(
  line: PalmLine.head,
  controlPoints: [
    a,
    PalmPoint(a.x + (b.x - a.x) / 3, a.y + (b.y - a.y) / 3),
    PalmPoint(a.x + (b.x - a.x) * 2 / 3, a.y + (b.y - a.y) * 2 / 3),
    b,
  ],
);

PalmCurve _shifted(PalmCurve curve, PalmPoint by) => curve.withControlPoints([
  for (final point in curve.controlPoints) point + by,
]);

PalmRidgeField _fieldFor(
  List<PalmCurve> creases, {
  int background = _background,
}) => PalmRidgeField(
  response: PalmRidgeFilter.responseFrom(
    _palmImage(creases, background: background),
    _size,
  ),
  size: _size,
);

void main() {
  group('the filter', () {
    test('finds a crease and ignores the space beside it', () {
      final crease = _line(
        const PalmPoint(0.1, 0.5),
        const PalmPoint(0.9, 0.5),
      );
      final field = _fieldFor([crease]);

      expect(field.responseAt(const PalmPoint(0.5, 0.5)), greaterThan(0.6));
      expect(field.responseAt(const PalmPoint(0.5, 0.75)), lessThan(0.15));
    });

    test('finds it whichever way it runs', () {
      // Four orientations, because a crease has no preferred direction
      // and an edge detector that only sees horizontals would place
      // every line on this palm at the same angle.
      final lines = {
        'horizontal': _line(
          const PalmPoint(0.1, 0.5),
          const PalmPoint(0.9, 0.5),
        ),
        'vertical': _line(
          const PalmPoint(0.5, 0.1),
          const PalmPoint(0.5, 0.9),
        ),
        'diagonal': _line(
          const PalmPoint(0.15, 0.15),
          const PalmPoint(0.85, 0.85),
        ),
        'anti-diagonal': _line(
          const PalmPoint(0.85, 0.15),
          const PalmPoint(0.15, 0.85),
        ),
      };

      for (final entry in lines.entries) {
        expect(
          _fieldFor([entry.value]).responseAt(const PalmPoint(0.5, 0.5)),
          greaterThan(0.6),
          reason: entry.key,
        );
      }
    });

    test('stays quiet on a blank palm', () {
      // Without the contrast floor the strongest thing in the image sets
      // the scale, so a featureless wall would normalise its own noise
      // up to 1 and every line would report as beautifully supported.
      final blank = _fieldFor(const []);
      for (final at in const [
        PalmPoint(0.3, 0.3),
        PalmPoint(0.5, 0.5),
        PalmPoint(0.7, 0.6),
      ]) {
        expect(blank.responseAt(at), lessThan(0.05));
      }
    });

    test('stays quiet on a flat dark palm too', () {
      expect(
        _fieldFor(const [], background: 40).responseAt(
          const PalmPoint(0.5, 0.5),
        ),
        lessThan(0.05),
      );
    });
  });

  group('the field', () {
    test('reads zero outside the crop it was given', () {
      final field = _fieldFor([
        _line(const PalmPoint(0.1, 0.5), const PalmPoint(0.9, 0.5)),
      ]);

      expect(field.responseAt(const PalmPoint(-0.5, 0.5)), 0);
      expect(field.responseAt(const PalmPoint(0.5, 1.9)), 0);
    });

    test('reaches past the palm, because the snapper searches there', () {
      // The template's outermost points sit near the edge, and the
      // snapper looks along their normals. A crop stopping at the
      // nominal bounds would answer zero for exactly those offsets and
      // pull every line inward.
      final field = _fieldFor([
        _line(const PalmPoint(-0.1, 0.5), const PalmPoint(0.4, 0.5)),
      ]);

      expect(field.responseAt(const PalmPoint(-0.08, 0.5)), greaterThan(0.3));
    });

    test('samples between pixels rather than snapping to them', () {
      // The snapper moves anchors by fractions of a pixel; nearest
      // neighbour would give several candidate offsets the same answer
      // and it would pick whichever it tried first.
      final field = _fieldFor([
        _line(const PalmPoint(0.1, 0.5), const PalmPoint(0.9, 0.5)),
      ]);

      final samples = [
        for (var i = 0; i <= 8; i++)
          field.responseAt(PalmPoint(0.5, 0.5 + i * 0.002)),
      ];
      expect(samples.toSet().length, greaterThan(4));
    });
  });

  group('end to end, on pixels', () {
    test('pulls the template onto creases that are really there', () {
      // The whole point of tier two. The template is the anatomical
      // prior; these are the creases in the photograph; the snapped
      // curve has to end up on the second, not the first.
      const offset = PalmPoint(0, 0.035);
      final template = PalmLineTemplate.head;
      final crease = _shifted(template, offset);
      final field = _fieldFor([crease]);

      final snapped = PalmCreaseSnapper.snap(curve: template, field: field);

      final creaseSamples = crease.sample(perSegment: 40);
      double distance(PalmCurve curve) {
        var total = 0.0;
        for (final anchor in curve.anchors) {
          var nearest = double.infinity;
          for (final sample in creaseSamples) {
            nearest = math.min(nearest, sample.distanceTo(anchor));
          }
          total += nearest;
        }
        return total / curve.anchors.length;
      }

      final before = distance(template);
      final after = distance(snapped);

      expect(before, greaterThan(0.03));
      expect(after, lessThan(before / 2));
    });

    test('reports support that tells a real crease from a bare palm', () {
      final template = PalmLineTemplate.head;

      final onCrease = PalmCreaseSnapper.support(
        curve: template,
        field: _fieldFor([template]),
      );
      final onNothing = PalmCreaseSnapper.support(
        curve: template,
        field: _fieldFor(const []),
      );

      expect(onCrease, greaterThan(0.4));
      expect(onNothing, lessThan(0.05));
      expect(onCrease - onNothing, greaterThan(0.35));
    });
  });
}
