import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_crease_snapper.dart';

/// How a frame's bytes are laid out.
enum PalmImageFormat {
  /// Android's camera stream format: three planes, Y then U then V.
  ///
  /// Not `nv21`, which the plugin also offers and which arrives as a
  /// single tightly packed plane. That shape is the one a detector
  /// cannot take apart — see the note in `CameraPalmCamera`.
  yuv420,

  /// iOS's camera stream format.
  bgra8888,

  /// A compressed still, as `takePicture` returns.
  jpeg,
}

/// One frame handed to a detector.
///
/// A plain byte buffer rather than anything from `dart:ui`, so the
/// interface stays in `domain/` beside the geometry it feeds — the same
/// arrangement `ChatTransport` already uses, declared here and
/// implemented in `data/`.
@immutable
class PalmFrameImage {
  /// Creates a frame.
  const PalmFrameImage({
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
    this.rotationDegrees = 0,
    this.isFrontFacing = false,
    this.platformFrame,
  });

  /// The pixels.
  final Uint8List bytes;

  /// Width in pixels, before [rotationDegrees] is applied.
  final int width;

  /// Height in pixels, before [rotationDegrees] is applied.
  final int height;

  /// How [bytes] are laid out.
  final PalmImageFormat format;

  /// How far the sensor is rotated from the display, clockwise.
  final int rotationDegrees;

  /// Whether this came from a lens pointing at the user.
  ///
  /// Not decoration: it decides how a frame has to be rotated, and it is
  /// the first thing to look at when a scan insists every palm is the
  /// back of a hand.
  final bool isFrontFacing;

  /// The camera's own frame object, when the camera and the detector in
  /// use are a matched pair.
  ///
  /// Deliberately `Object?`. A landmark model wants the platform's
  /// native frame — a YUV buffer it can crop and rotate itself — and
  /// re-encoding every preview frame to hand it [bytes] instead would
  /// cost more than the inference does. But naming that type here would
  /// drag a camera plugin into `domain/`, which is the one thing this
  /// layer is not allowed to do.
  ///
  /// So it is opaque: `domain/` never reads it, a fake camera leaves it
  /// null, and the two real adapters agree on what it is between
  /// themselves. A detector that finds it null falls back to [bytes],
  /// which is what happens for the captured still.
  final Object? platformFrame;

  /// The frame's height over its width, after rotation.
  ///
  /// What `HandLandmarks.frameAspect` wants. A quarter turn swaps the
  /// two, and getting it wrong distorts every distance the geometry
  /// measures without making anything look obviously broken.
  double get aspect {
    final turned = rotationDegrees % 180 != 0;
    return turned ? width / height : height / width;
  }
}

/// Finds a hand in a frame.
///
/// ## What implementations owe this interface
///
/// Landmarks in [PalmSpace.image] — normalised to the frame's **width**
/// on both axes, not per-axis as every detector returns them — and a
/// [Handedness] that has already been un-mirrored if the preview was.
///
/// That second one is not a detail. `HandLandmarks.isPalmFacing` works
/// by comparing the reported handedness against the pose's chirality; a
/// mirrored frame flips *both*, they stay consistent, and the check
/// silently passes on the back of a hand. The conversion belongs at this
/// boundary because this is the only place that knows which camera the
/// frame came from.
abstract interface class PalmDetector {
  /// The hand in [image], or null if there is not one.
  Future<HandLandmarks?> detect(PalmFrameImage image);

  /// Releases the model.
  Future<void> dispose();
}

/// Extracts crease response from a captured still.
///
/// Separate from [PalmDetector] because it runs once, on the high
/// resolution still, long after the stream has stopped — and because the
/// two have entirely different cost profiles. The detector must keep up
/// with a viewfinder; this may take a second.
abstract interface class PalmRidgeExtractor {
  /// Builds the ridge field over canonical palm space for [image], given
  /// the [landmarks] that rectify it.
  ///
  /// Returns null when the still cannot be filtered usefully — too dark,
  /// too blurred — which the caller shows as a retake rather than
  /// drawing a template nothing supports.
  Future<RidgeFieldSource?> extract({
    required PalmFrameImage image,
    required HandLandmarks landmarks,
  });
}

/// A ridge field plus the resources behind it.
///
/// `RidgeField` itself is a bare sampling function so the snapper can be
/// tested against fields written by hand. A real one holds a bitmap that
/// has to be released, which is what this adds.
abstract interface class RidgeFieldSource {
  /// The field, for `PalmCreaseSnapper`.
  RidgeField get field;

  /// Releases the underlying buffer.
  void dispose();
}
