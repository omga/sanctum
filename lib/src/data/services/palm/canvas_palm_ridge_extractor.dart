import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:sanctum/src/data/services/palm/palm_ridge_filter.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_crease_snapper.dart';
import 'package:sanctum/src/domain/services/palm_detector.dart';
import 'package:sanctum/src/domain/services/palm_geometry.dart';

/// Rectifies the captured still and measures its creases.
///
/// ## Rectify first, then filter
///
/// The palm is warped to a fixed square before anything looks at it, so
/// every number downstream means the same thing on every scan. A filter
/// run on the raw photograph would have to cope with a palm that is
/// rotated, half the frame, and further away than the last one — and the
/// probe widths in [PalmRidgeFilter] are pixel distances, so they would
/// be measuring a different fraction of a hand each time. After the warp
/// they are a fixed fraction of a palm.
///
/// It also means the field is in exactly the space `PalmCreaseSnapper`
/// searches, with no second transform between the two to get wrong.
///
/// ## Why the GPU draws the crop
///
/// The warp is an affine resample of a photograph that may be twelve
/// megapixels. Doing it in Dart means reading every source pixel; asking
/// the canvas to draw the image through a matrix costs one round trip
/// and hands back exactly the 256 × 256 that gets looked at. The filter
/// itself stays in Dart, where it can be tested.
class CanvasPalmRidgeExtractor implements PalmRidgeExtractor {
  /// Creates an extractor.
  const CanvasPalmRidgeExtractor({
    this.resolution = PalmRidgeFilter.resolution,
    this.margin = PalmRidgeFilter.margin,
  });

  /// The crop's edge length in pixels.
  final int resolution;

  /// How far beyond canonical `[0, 1]` the crop reaches.
  final double margin;

  @override
  Future<RidgeFieldSource?> extract({
    required PalmFrameImage image,
    required HandLandmarks landmarks,
  }) async {
    final frame = PalmGeometry.rectify(landmarks);
    if (frame == null) return null;

    ui.Image? decoded;
    ui.Image? crop;
    try {
      decoded = await _decode(image);
      crop = await _rectify(decoded, frame);

      final bytes = await crop.toByteData();
      if (bytes == null) return null;

      return _Source(
        PalmRidgeField(
          response: PalmRidgeFilter.responseFrom(
            bytes.buffer.asUint8List(),
            resolution,
          ),
          size: resolution,
          margin: margin,
        ),
      );
    } on Object {
      // A still that will not decode, or a canvas that will not hand
      // back its pixels, is a scan without crease detail — not a scan
      // that failed. `PalmComposer` draws the bare template from a null
      // field, which is a worse reading and a working one.
      return null;
    } finally {
      decoded?.dispose();
      crop?.dispose();
    }
  }

  Future<ui.Image> _decode(PalmFrameImage image) async {
    final codec = await ui.instantiateImageCodec(image.bytes);
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  /// Draws the palm into a canonical square.
  Future<ui.Image> _rectify(ui.Image source, PalmFrame frame) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Three transforms, right to left: source pixels to
    // `PalmSpace.image` (both axes over the width), image space to
    // canonical via the warp, then canonical to crop pixels with the
    // margin folded in.
    final span = 1 + margin * 2;
    final scale = resolution / span;
    final warp = frame.toCanonical;
    final perPixel = 1 / source.width;

    canvas
      ..translate(margin * scale, margin * scale)
      ..transform(
        Float64List.fromList([
          warp.a * scale * perPixel, warp.c * scale * perPixel, 0, 0, //
          warp.b * scale * perPixel, warp.d * scale * perPixel, 0, 0, //
          0, 0, 1, 0, //
          warp.tx * scale, warp.ty * scale, 0, 1, //
        ]),
      )
      ..drawImage(
        source,
        Offset.zero,
        Paint()..filterQuality = FilterQuality.medium,
      );

    final picture = recorder.endRecording();
    try {
      return await picture.toImage(resolution, resolution);
    } finally {
      picture.dispose();
    }
  }
}

class _Source implements RidgeFieldSource {
  const _Source(this.field);

  @override
  final RidgeField field;

  @override
  void dispose() {
    // The buffer is plain Dart memory and the images were released as
    // soon as they were read. Nothing outlives the extraction.
  }
}
