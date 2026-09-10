import 'dart:math' as math;

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

/// Traces the crease a line actually follows in the photograph.
///
/// ## Why this is the feature
///
/// The template puts the heart line where heart lines usually go, so two
/// people filming the scan get the same three curves in the same places —
/// and the first comment pointing that out ends the channel. This is the
/// step that makes a scan belong to the hand it was taken from.
///
/// ## Why a path, not a nudge per point
///
/// The first version looked for the best offset at each anchor on its
/// own, within a small radius, and smoothed the answers afterwards. On a
/// real palm that failed two ways at once. A radius small enough to stop
/// a line jumping onto its neighbour was too small to reach a crease the
/// template had placed badly — the life line, authored bowing the wrong
/// way, sat several radii from the real one and could not be moved. And
/// deciding each point independently let neighbouring points settle on
/// different wrinkles, which smoothing then averaged into a line lying on
/// no crease at all.
///
/// So the line is traced instead. It is cut into [defaultStations]
/// stations along its length; at each, every offset across a band either
/// side is scored by how crease-like the photograph is there; and dynamic
/// programming finds the single path through those scores that is most
/// crease-like overall while paying for two things:
///
/// - **Distance from the template** ([defaultPrior]), so a line prefers
///   the crease near its anatomical home to a deeper one further off.
/// - **Bending** ([defaultSmoothness]), charged on the change of offset
///   between neighbouring stations. This is what makes a line follow one
///   continuous crease rather than hopping between wrinkles — and what
///   stops a single dark speck pulling it into a detour, because a one-
///   station gain cannot pay for the trip out and back, while a genuine
///   crease repays the transition at every station it runs for.
///
/// The path is free to bow either way. The photograph decides a line's
/// curvature; the template only decides where to start looking.
abstract final class PalmCreaseSnapper {
  /// How far either side of the template a line may move, in canonical
  /// units — a tenth of a palm. Wide enough to find a crease the prior
  /// misplaced; still short of the gap to the next principal line, and
  /// [defaultPrior] keeps it honest near the edge of the band.
  static const double defaultBand = 0.10;

  /// How many stations a line is traced at.
  static const int defaultStations = 28;

  /// How many offsets are tried at each station. Odd, so that "stay on
  /// the template" is one of them exactly.
  static const int defaultOffsets = 25;

  /// The cost of sitting at the edge of the band, relative to a response
  /// of 1. Scales with the square of the offset.
  static const double defaultPrior = 0.35;

  /// The cost of bending, per unit of squared slope between stations.
  static const double defaultSmoothness = 0.25;

  /// The most offsets a line may step between neighbouring stations.
  static const int _maxStep = 3;

  /// Traces [curve] onto the creases in [field].
  ///
  /// [curve] must be in canonical space, because [field] is. The result
  /// is a new cubic chain passing through the traced stations; the input
  /// is not modified.
  static PalmCurve snap({
    required PalmCurve curve,
    required RidgeField field,
    double band = defaultBand,
    int stations = defaultStations,
    int offsets = defaultOffsets,
    double prior = defaultPrior,
    double smoothness = defaultSmoothness,
  }) {
    assert(
      curve.space == PalmSpace.canonical,
      'the ridge field is in canonical space, so the curve must be',
    );
    assert(stations >= 3, 'a line needs at least three stations');
    assert(offsets >= 3 && offsets.isOdd, 'offsets must include zero');

    final along = _stationsOf(curve, stations);
    if (along == null) return curve;
    final (points, tangents, normals, spacing) = along;

    final steps = [
      for (var k = 0; k < offsets; k++) -band + 2 * band * k / (offsets - 1),
    ];

    // How good each offset is at each station, before any bending.
    final unary = List<double>.filled(stations * offsets, 0);
    final reach = spacing * 0.35;
    for (var i = 0; i < stations; i++) {
      for (var k = 0; k < offsets; k++) {
        final at = points[i] + normals[i] * steps[k];
        // Averaged over a short run along the line, so a crease — which
        // is long — outscores a speck, which is not.
        final response =
            (field.responseAt(at) +
                field.responseAt(at + tangents[i] * reach) +
                field.responseAt(at - tangents[i] * reach)) /
            3;
        final fraction = steps[k] / band;
        unary[i * offsets + k] = -response + prior * fraction * fraction;
      }
    }

    // Cheapest path to every offset at every station.
    final cost = List<double>.filled(stations * offsets, 0);
    final back = List<int>.filled(stations * offsets, 0);
    for (var k = 0; k < offsets; k++) {
      cost[k] = unary[k];
    }
    for (var i = 1; i < stations; i++) {
      for (var k = 0; k < offsets; k++) {
        var best = double.infinity;
        var from = k;
        final low = math.max(0, k - _maxStep);
        final high = math.min(offsets - 1, k + _maxStep);
        for (var j = low; j <= high; j++) {
          final slope = (steps[k] - steps[j]) / spacing;
          final candidate =
              cost[(i - 1) * offsets + j] + smoothness * slope * slope;
          if (candidate < best) {
            best = candidate;
            from = j;
          }
        }
        cost[i * offsets + k] = best + unary[i * offsets + k];
        back[i * offsets + k] = from;
      }
    }

    var choice = offsets ~/ 2;
    var cheapest = double.infinity;
    for (var k = 0; k < offsets; k++) {
      final total = cost[(stations - 1) * offsets + k];
      if (total < cheapest) {
        cheapest = total;
        choice = k;
      }
    }

    final traced = List<PalmPoint>.filled(stations, const PalmPoint(0, 0));
    for (var i = stations - 1; i >= 0; i--) {
      traced[i] = points[i] + normals[i] * steps[choice];
      if (i > 0) choice = back[i * offsets + choice];
    }

    return curve.withControlPoints(_chainThrough(traced));
  }

  /// Traces every curve in [curves].
  static List<PalmCurve> snapAll({
    required List<PalmCurve> curves,
    required RidgeField field,
    double band = defaultBand,
  }) => [
    for (final curve in curves) snap(curve: curve, field: field, band: band),
  ];

  /// How well [curve] sits on the creases in [field], averaged along it
  /// and normalised to `[0, 1]`.
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

  /// Evenly spaced stations along [curve], by arc length, with their
  /// unit tangents and normals and the spacing between them.
  static (List<PalmPoint>, List<PalmPoint>, List<PalmPoint>, double)?
  _stationsOf(PalmCurve curve, int count) {
    final dense = curve.sample(perSegment: 32);
    final lengths = <double>[0];
    for (var i = 1; i < dense.length; i++) {
      lengths.add(lengths.last + dense[i].distanceTo(dense[i - 1]));
    }
    final total = lengths.last;
    if (total < 1e-9) return null;

    final points = <PalmPoint>[];
    var j = 1;
    for (var i = 0; i < count; i++) {
      final target = total * i / (count - 1);
      while (j < lengths.length - 1 && lengths[j] < target) {
        j++;
      }
      final segment = lengths[j] - lengths[j - 1];
      final t = segment < 1e-12
          ? 0.0
          : ((target - lengths[j - 1]) / segment).clamp(0.0, 1.0);
      points.add(dense[j - 1] + (dense[j] - dense[j - 1]) * t);
    }

    final tangents = [
      for (var i = 0; i < count; i++)
        (points[math.min(i + 1, count - 1)] - points[math.max(i - 1, 0)])
            .normalized,
    ];
    final normals = [for (final tangent in tangents) tangent.normal];

    return (points, tangents, normals, total / (count - 1));
  }

  /// A cubic chain through [points], by Catmull-Rom.
  ///
  /// Uniform rather than centripetal: the stations are evenly spaced by
  /// construction, which is the case uniform handles well, and the
  /// traced offsets change gently between neighbours.
  static List<PalmPoint> _chainThrough(List<PalmPoint> points) {
    final chain = <PalmPoint>[points.first];
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[math.max(i - 1, 0)];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[math.min(i + 2, points.length - 1)];
      chain
        ..add(p1 + (p2 - p0) * (1 / 6))
        ..add(p2 - (p3 - p1) * (1 / 6))
        ..add(p2);
    }
    return chain;
  }
}
