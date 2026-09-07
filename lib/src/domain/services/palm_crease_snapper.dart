import 'package:sanctum/src/domain/models/palm.dart';

/// How strongly the image looks like a crease at a given point.
///
/// The seam between the geometry and the photograph. The domain layer
/// never sees pixels: something in `data/` runs a ridge filter over the
/// rectified palm and exposes the result through this one method, so
/// every test below can hand the snapper a field it wrote by hand.
abstract interface class RidgeField {
  /// The ridge response at [point] in canonical palm space, where higher
  /// means darker and more line-like. Outside the palm, return zero.
  double responseAt(PalmPoint point);
}

/// Pulls an authored line onto the crease that is actually there.
///
/// ## Why this is the feature
///
/// The template alone puts the heart line where a heart line usually
/// goes, which means two people filming this get the same three curves
/// in the same places. The format does not survive that: the first
/// comment pointing it out ends the channel. This is the step that makes
/// a scan belong to the hand it was taken from.
///
/// ## How it moves
///
/// Only the on-curve anchors move, and only along the curve's normal.
/// Sliding a point *along* the line would change nothing visible while
/// wrecking the parameterisation, and letting it move freely would let a
/// strong nearby crease drag the heart line onto the head line.
///
/// Three things keep it honest:
///
/// - **A falloff penalty.** A better response further away has to be
///   *much* better to win, so the curve prefers the crease under it to a
///   deeper one two lines over.
/// - **Laplacian smoothing over the offsets**, not the points. Each
///   anchor has its own normal, so smoothing positions would fight the
///   curvature; smoothing the scalar offsets and re-projecting keeps the
///   line smooth without flattening it.
/// - **Both control handles travel with their anchor**, which preserves
///   each tangent's direction and length. Moving anchors alone produces
///   a curve that kinks at every third point.
abstract final class PalmCreaseSnapper {
  /// How far, in canonical units, an anchor may move. About 4 % of the
  /// palm's width — enough to find the crease under a template line,
  /// too little to reach the next one.
  static const double defaultSearchRadius = 0.045;

  /// How much a full-radius move is penalised, relative to response.
  static const double defaultFalloff = 0.35;

  /// How many times a curve is split before its anchors are searched.
  ///
  /// An authored line has two segments, so three anchors, so three
  /// places it can be pulled — not enough freedom to follow a crease
  /// that wanders. Two subdivisions give nine anchors, roughly one every
  /// 9 % of the line's length, which is finer than [defaultSearchRadius]
  /// can move any single one of them.
  ///
  /// Subdivision is exact, so this costs shape nothing — see
  /// [PalmCurve.subdivided].
  static const int defaultSubdivisions = 2;

  /// Snaps [curve] onto the creases in [field].
  ///
  /// [curve] must be in canonical space, because [field] is. The input
  /// is not modified, and the result carries **more control points than
  /// it did** — see [defaultSubdivisions]. Draw what comes back.
  static PalmCurve snap({
    required PalmCurve curve,
    required RidgeField field,
    double searchRadius = defaultSearchRadius,
    double falloff = defaultFalloff,
    int samples = 9,
    int smoothingPasses = 2,
    int subdivisions = defaultSubdivisions,
  }) {
    assert(
      curve.space == PalmSpace.canonical,
      'the ridge field is in canonical space, so the curve must be',
    );
    assert(samples >= 1, 'a search needs at least one step either way');
    assert(
      subdivisions >= 0,
      'a curve cannot be split a negative number of times',
    );

    var refined = curve;
    for (var i = 0; i < subdivisions; i++) {
      refined = refined.subdivided();
    }

    final anchors = refined.anchors;
    final normals = _normalsOf(refined);

    final offsets = <double>[
      for (var i = 0; i < anchors.length; i++)
        _bestOffset(
          anchor: anchors[i],
          normal: normals[i],
          field: field,
          searchRadius: searchRadius,
          falloff: falloff,
          samples: samples,
        ),
    ];

    final smoothed = _smooth(offsets, passes: smoothingPasses);

    final moved = [...refined.controlPoints];
    for (var i = 0; i < anchors.length; i++) {
      final shift = normals[i] * smoothed[i];
      final anchorIndex = i * 3;
      for (final index in [anchorIndex - 1, anchorIndex, anchorIndex + 1]) {
        if (index >= 0 && index < moved.length) {
          moved[index] = moved[index] + shift;
        }
      }
    }

    return refined.withControlPoints(moved);
  }

  /// Snaps every curve in [curves].
  static List<PalmCurve> snapAll({
    required List<PalmCurve> curves,
    required RidgeField field,
    double searchRadius = defaultSearchRadius,
    double falloff = defaultFalloff,
    int subdivisions = defaultSubdivisions,
  }) => [
    for (final curve in curves)
      snap(
        curve: curve,
        field: field,
        searchRadius: searchRadius,
        falloff: falloff,
        subdivisions: subdivisions,
      ),
  ];

  /// How well [curve] sits on the creases in [field], averaged over its
  /// anchors and normalised to `[0, 1]`.
  ///
  /// What decides whether a line is *claimed*. A hand with no fate line
  /// leaves the fate template sitting on nothing, and this is the number
  /// that says so — so the reading can decline to mention it rather than
  /// describing a curve the user cannot find.
  static double support({
    required PalmCurve curve,
    required RidgeField field,
    int perSegment = 8,
  }) {
    final points = curve.sample(perSegment: perSegment);
    if (points.isEmpty) return 0;
    var total = 0.0;
    for (final point in points) {
      total += field.responseAt(point).clamp(0.0, 1.0);
    }
    return total / points.length;
  }

  static List<PalmPoint> _normalsOf(PalmCurve curve) {
    final points = curve.controlPoints;
    final count = curve.segmentCount + 1;
    return [
      for (var i = 0; i < count; i++)
        () {
          final index = i * 3;
          final incoming = index > 0
              ? points[index] - points[index - 1]
              : const PalmPoint(0, 0);
          final outgoing = index + 1 < points.length
              ? points[index + 1] - points[index]
              : const PalmPoint(0, 0);
          final tangent = (incoming + outgoing).normalized;
          return tangent.normal;
        }(),
    ];
  }

  static double _bestOffset({
    required PalmPoint anchor,
    required PalmPoint normal,
    required RidgeField field,
    required double searchRadius,
    required double falloff,
    required int samples,
  }) {
    var bestOffset = 0.0;
    var bestScore = field.responseAt(anchor);

    for (var step = -samples; step <= samples; step++) {
      if (step == 0) continue;
      final fraction = step / samples;
      final offset = fraction * searchRadius;
      final response = field.responseAt(anchor + normal * offset);
      final score = response - falloff * fraction * fraction;
      if (score > bestScore) {
        bestScore = score;
        bestOffset = offset;
      }
    }

    return bestOffset;
  }

  static List<double> _smooth(List<double> offsets, {required int passes}) {
    if (offsets.length < 3 || passes <= 0) return offsets;
    var current = offsets;
    for (var pass = 0; pass < passes; pass++) {
      final next = [...current];
      for (var i = 1; i < current.length - 1; i++) {
        next[i] = current[i] * 0.5 + (current[i - 1] + current[i + 1]) * 0.25;
      }
      current = next;
    }
    return current;
  }
}
