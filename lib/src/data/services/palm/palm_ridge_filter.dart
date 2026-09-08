import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_crease_snapper.dart';

/// Finds the dark, narrow, elongated things in a rectified palm.
///
/// ## What a crease looks like to a filter
///
/// Not an edge. An edge has bright on one side and dark on the other; a
/// crease is dark with bright on *both* sides, a few pixels across, and
/// running in an unknown direction. So the test is: is this pixel darker
/// than the two pixels flanking it, and does that hold in some
/// orientation?
///
/// Four orientations at two widths, taking the best answer. Four is
/// enough because the response falls off slowly with angle — a line at
/// 22° still reads strongly on the 0° and 45° probes — and two widths
/// because a life line and a fine head line are not the same thickness.
///
/// ## Why this is Dart and not a fragment shader
///
/// `.claude/palm.md` §4 called for a shader, on the assumption the
/// filter would run on every preview frame. It does not: it runs once,
/// on the captured still, while the reveal's first beat is playing. At
/// that budget a few hundred thousand integer operations in Dart is
/// free, and it buys a filter that can be tested against images built in
/// the test itself rather than against whatever the GPU did.
///
/// ## The floor matters more than the ceiling
///
/// Responses are scaled so the strongest creases reach 1, which on a
/// palm photographed in good light is right and on a blank wall would
/// stretch sensor noise to look identical. [minimumContrast] is what
/// stops that: below it the divisor stops shrinking, a featureless
/// image stays near zero, and `PalmProfile.isThin` keeps meaning
/// something.
abstract final class PalmRidgeFilter {
  /// The flank distances probed, in pixels at [resolution].
  static const List<int> widths = [2, 4];

  /// The intensity difference, out of 255, below which an image is
  /// treated as having no creases rather than faint ones.
  static const double minimumContrast = 7;

  /// The crop's edge length in pixels.
  static const int resolution = 256;

  /// How far beyond canonical `[0, 1]` the crop reaches.
  ///
  /// The snapper searches along the curve normal and the outermost
  /// template points sit close to the edge, so a crop that stopped at
  /// the palm's nominal bounds would return zero for exactly the
  /// offsets it is being asked about — and every line would be pulled
  /// inward by a filter that could not see outward.
  static const double margin = 0.15;

  /// The ridge response for an RGBA [crop] of `size` × `size` pixels.
  ///
  /// Values are `[0, 1]`, higher where the image is more crease-like.
  static Float32List responseFrom(Uint8List crop, int size) {
    assert(
      crop.length >= size * size * 4,
      'the crop is smaller than the size it claims',
    );

    final grey = _greyscale(crop, size);
    final smoothed = _blur(grey, size);
    final response = Float32List(size * size);

    var strongest = 0.0;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final best = _flankResponse(smoothed, size, x, y);
        response[y * size + x] = best;
        if (best > strongest) strongest = best;
      }
    }

    final divisor = math.max(strongest, minimumContrast);
    for (var i = 0; i < response.length; i++) {
      response[i] = (response[i] / divisor).clamp(0.0, 1.0);
    }
    return response;
  }

  static Float32List _greyscale(Uint8List rgba, int size) {
    final grey = Float32List(size * size);
    for (var i = 0; i < grey.length; i++) {
      final at = i * 4;
      grey[i] =
          rgba[at] * 0.2126 + rgba[at + 1] * 0.7152 + rgba[at + 2] * 0.0722;
    }
    return grey;
  }

  /// A 3×3 box blur, to stop sensor noise reading as a crease one pixel
  /// wide.
  static Float32List _blur(Float32List source, int size) {
    final out = Float32List(size * size);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        var total = 0.0;
        var count = 0;
        for (var dy = -1; dy <= 1; dy++) {
          final sy = y + dy;
          if (sy < 0 || sy >= size) continue;
          for (var dx = -1; dx <= 1; dx++) {
            final sx = x + dx;
            if (sx < 0 || sx >= size) continue;
            total += source[sy * size + sx];
            count++;
          }
        }
        out[y * size + x] = total / count;
      }
    }
    return out;
  }

  /// How much darker this pixel is than its flanks, at the best
  /// orientation and width.
  static double _flankResponse(
    Float32List grey,
    int size,
    int x,
    int y,
  ) {
    // The four probe directions, as integer steps. These are the
    // *normals* — a horizontal crease is found by probing vertically.
    const directions = [
      [1, 0],
      [1, 1],
      [0, 1],
      [-1, 1],
    ];

    final centre = grey[y * size + x];
    var best = 0.0;

    for (final width in widths) {
      for (final direction in directions) {
        final dx = direction[0] * width;
        final dy = direction[1] * width;

        final ax = x + dx;
        final ay = y + dy;
        final bx = x - dx;
        final by = y - dy;
        if (ax < 0 || ax >= size || ay < 0 || ay >= size) continue;
        if (bx < 0 || bx >= size || by < 0 || by >= size) continue;

        final flanks = (grey[ay * size + ax] + grey[by * size + bx]) / 2;
        final response = flanks - centre;
        if (response > best) best = response;
      }
    }
    return best;
  }
}

/// A [RidgeField] over a rectified palm, sampled from a response buffer.
@immutable
class PalmRidgeField implements RidgeField {
  /// Creates a field from [response], a `size` × `size` buffer covering
  /// canonical `[-margin, 1 + margin]` on both axes.
  const PalmRidgeField({
    required this.response,
    required this.size,
    this.margin = PalmRidgeFilter.margin,
  });

  /// The ridge response, row-major.
  final Float32List response;

  /// The buffer's edge length.
  final int size;

  /// How far beyond canonical `[0, 1]` the buffer reaches.
  final double margin;

  @override
  double responseAt(PalmPoint point) {
    // Canonical → buffer pixels, then bilinear. Nearest-neighbour here
    // would quantise the search to whole pixels, and the snapper moves
    // anchors by fractions of one — it would find the same offset for
    // several neighbouring candidates and pick whichever came first.
    final span = 1 + margin * 2;
    final fx = (point.x + margin) / span * (size - 1);
    final fy = (point.y + margin) / span * (size - 1);

    if (fx < 0 || fy < 0 || fx > size - 1 || fy > size - 1) return 0;

    final x0 = fx.floor();
    final y0 = fy.floor();
    final x1 = math.min(x0 + 1, size - 1);
    final y1 = math.min(y0 + 1, size - 1);
    final tx = fx - x0;
    final ty = fy - y0;

    final top =
        response[y0 * size + x0] * (1 - tx) + response[y0 * size + x1] * tx;
    final bottom =
        response[y1 * size + x0] * (1 - tx) + response[y1 * size + x1] * tx;
    return top * (1 - ty) + bottom * ty;
  }
}
