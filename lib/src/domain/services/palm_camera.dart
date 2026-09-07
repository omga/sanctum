import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/domain/services/palm_detector.dart';

/// The viewfinder, behind an interface.
///
/// Declared here so the scan's state machine can be tested against a
/// fake that emits whatever sequence of frames a test wants — a hand
/// that arrives and leaves, a hand that steadies for exactly long
/// enough, a capture that fails. None of that is reachable through a
/// real camera in a test, and all of it is where the bugs are.
abstract interface class PalmCamera {
  /// Opens the camera and begins streaming.
  Future<Result<void>> start();

  /// Preview frames, at whatever rate the platform delivers.
  ///
  /// Deliberately not every frame the sensor produces: the detector
  /// cannot keep up with 60 fps and does not need to. Implementations
  /// drop rather than queue, because a backed-up queue turns the
  /// viewfinder into a recording of the recent past.
  Stream<PalmFrameImage> get frames;

  /// Takes the still the whole reveal is built from.
  ///
  /// A real capture, not the newest preview frame. The preview is
  /// downscaled for the detector's sake and carries nowhere near enough
  /// detail for a crease filter — which is the entire reason the reveal
  /// is rendered from a photograph rather than recorded live.
  Future<Result<PalmFrameImage>> capture();

  /// Stops the stream and releases the device.
  Future<void> stop();
}
