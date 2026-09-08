import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/core_providers.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/services/palm/camera_palm_camera.dart';
import 'package:sanctum/src/data/services/palm/hand_detection_palm_detector.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_camera.dart';
import 'package:sanctum/src/domain/services/palm_composer.dart';
import 'package:sanctum/src/domain/services/palm_detector.dart';
import 'package:sanctum/src/domain/services/palm_geometry.dart';
import 'package:sanctum/src/features/palm/view/widgets/palm_camera_preview.dart';

part 'palm_scan_view_model.g.dart';

/// Where the scan has got to.
enum PalmScanStage {
  /// Nothing running. The camera has not been opened.
  idle,

  /// Streaming, looking for a hand worth capturing.
  aligning,

  /// The shutter has fired; the still is being taken and filtered.
  capturing,

  /// A reading exists and the reveal may play.
  revealed,

  /// Something went wrong and the screen has to say what.
  failed,
}

/// Everything the scan screen needs to draw itself.
@immutable
class PalmScanState {
  /// Creates the state.
  const PalmScanState({
    this.stage = PalmScanStage.idle,
    this.readiness = PalmReadiness.noHand,
    this.preview,
    this.still,
    this.reading,
    this.failure,
    this.steadyFrames = 0,
  });

  /// Which stage is running.
  final PalmScanStage stage;

  /// What the viewfinder should be saying right now.
  final PalmReadiness readiness;

  /// The live warp, for drawing the outline over the preview. Present
  /// even when [readiness] is unhappy — a hand that is merely too small
  /// still has a pose worth outlining while the copy asks for more.
  final PalmFrame? preview;

  /// The captured still, held in memory for the reveal to draw.
  ///
  /// **Never written anywhere.** It lives as long as this state does and
  /// goes when the screen does. A reveal has to draw the photograph — a
  /// hand with lines over it is the whole artefact — but nothing about
  /// the palm feature may outlive the session that made it, so this is
  /// the furthest the image travels.
  final PalmFrameImage? still;

  /// The finished scan.
  final PalmReading? reading;

  /// Why the scan stopped.
  final AppFailure? failure;

  /// How many consecutive good frames have arrived.
  final int steadyFrames;

  /// How close the shutter is to firing, `[0, 1]`.
  double get holdProgress =>
      (steadyFrames / PalmScanViewModel.steadyFramesRequired).clamp(0.0, 1.0);

  /// Whether the preview should be on screen.
  bool get isStreaming =>
      stage == PalmScanStage.aligning || stage == PalmScanStage.capturing;

  /// A copy with the named fields replaced.
  PalmScanState copyWith({
    PalmScanStage? stage,
    PalmReadiness? readiness,
    PalmFrame? preview,
    PalmFrameImage? still,
    PalmReading? reading,
    AppFailure? failure,
    int? steadyFrames,
    bool clearPreview = false,
  }) => PalmScanState(
    stage: stage ?? this.stage,
    readiness: readiness ?? this.readiness,
    preview: clearPreview ? null : preview ?? this.preview,
    still: still ?? this.still,
    reading: reading ?? this.reading,
    failure: failure ?? this.failure,
    steadyFrames: steadyFrames ?? this.steadyFrames,
  );
}

/// The widget that shows the live camera, or null when there is none.
///
/// A builder rather than a `Widget` on [PalmCamera], which would put
/// Flutter into a `domain/` interface. The adapter supplies both halves
/// — the frame stream through [PalmCamera] and the preview surface
/// through this.
///
/// Null for any camera that is not the real one, which is what makes a
/// test's fake camera render the labelled hole rather than reaching for
/// a controller that does not exist.
@riverpod
WidgetBuilder? palmPreviewBuilder(Ref ref) {
  final camera = ref.watch(palmCameraProvider);
  if (camera is! CameraPalmCamera) return null;
  return (context) => PalmCameraPreview(camera: camera);
}

/// The camera.
///
/// Auto-disposed on purpose: the scan screen is the only thing that
/// reads it, and a phone with a camera held open by a provider nobody is
/// looking through shows a recording light and drains a battery. The
/// disposal releases the device.
@riverpod
PalmCamera palmCamera(Ref ref) {
  final camera = CameraPalmCamera();
  ref.onDispose(camera.dispose);
  return camera;
}

/// The landmark model.
///
/// Auto-disposed with the scan, like the camera. The models are a few
/// megabytes of interpreter state; holding them open for a user who has
/// left the screen is the kind of thing that gets an app killed in the
/// background.
@riverpod
PalmDetector palmDetector(Ref ref) {
  final detector = HandDetectionPalmDetector();
  ref.onDispose(() => unawaited(detector.dispose()));
  return detector;
}

/// The crease filter. Overridden once a real one exists.
///
/// Optional in a way the other two are not: with no extractor the scan
/// still completes and draws the bare template. That is a worse product
/// — see `PalmCreaseSnapper` on why — but it is a working one, and it is
/// what the first build on a device will do while spike S3 is still
/// open.
@riverpod
PalmRidgeExtractor? palmRidgeExtractor(Ref ref) => null;

/// Drives one scan, from opening the camera to a finished reading.
///
/// ## Why the shutter fires itself
///
/// There is no capture button. The scan waits for
/// [steadyFramesRequired] consecutive frames that
/// [PalmGeometry.evaluate] is happy with, and then fires.
///
/// A button would be easier and worse. Pressing one moves the hand, and
/// the hand is the subject; the user would be fighting the thing they
/// are trying to photograph. It also makes for a far better video —
/// nobody's thumb travels across frame at the moment of capture.
///
/// The counter resets on any unhappy frame rather than decaying, because
/// "held still" is a claim about a run of frames, not an average over
/// them.
@riverpod
class PalmScanViewModel extends _$PalmScanViewModel {
  /// How many consecutive good frames fire the shutter.
  ///
  /// At the ~15 fps the detector is expected to sustain, eight frames is
  /// a little over half a second — long enough to mean the hand settled,
  /// short enough that nobody thinks the app has hung. Neither end of
  /// that has been measured on a device.
  static const int steadyFramesRequired = 8;

  StreamSubscription<PalmFrameImage>? _frames;
  var _busy = false;

  @override
  PalmScanState build() {
    // Captured here rather than read inside the callback: Riverpod
    // forbids touching another provider from a life-cycle hook, and the
    // throw lands on every exit from the scan screen — the one moment
    // the camera most needs releasing.
    final camera = ref.read(palmCameraProvider);
    ref.onDispose(() {
      unawaited(_frames?.cancel());
      unawaited(camera.stop());
    });
    return const PalmScanState();
  }

  /// Opens the camera and starts looking.
  Future<void> start() async {
    if (state.isStreaming) return;

    final camera = ref.read(palmCameraProvider);
    final started = await camera.start();
    if (!ref.mounted) return;
    if (started case Err(:final failure)) {
      state = state.copyWith(stage: PalmScanStage.failed, failure: failure);
      return;
    }

    state = const PalmScanState(stage: PalmScanStage.aligning);
    _frames = camera.frames.listen(_onFrame);
  }

  /// Throws the scan away and looks again.
  Future<void> retake() async {
    await _frames?.cancel();
    _frames = null;
    state = const PalmScanState();
    await start();
  }

  /// Stops everything.
  Future<void> stop() async {
    await _frames?.cancel();
    _frames = null;
    await ref.read(palmCameraProvider).stop();
    state = state.copyWith(stage: PalmScanStage.idle, clearPreview: true);
  }

  Future<void> _onFrame(PalmFrameImage image) async {
    // Frames arrive faster than the detector runs. Dropping the ones
    // that overlap keeps the viewfinder live; queueing them would make
    // it a recording of the recent past, and the steadiness counter
    // would be counting frames the user had already moved on from.
    if (_busy || state.stage != PalmScanStage.aligning) return;
    _busy = true;

    try {
      final landmarks = await ref.read(palmDetectorProvider).detect(image);
      // The screen can close while inference is in flight — leaving the
      // scan is the single most likely thing a user does during the
      // second it takes. Touching `ref` or `state` after that throws.
      if (!ref.mounted || state.stage != PalmScanStage.aligning) return;

      final scan = PalmGeometry.evaluate(landmarks);
      final steady = scan.isReady ? state.steadyFrames + 1 : 0;

      state = state.copyWith(
        readiness: scan.readiness,
        preview: scan.frame,
        clearPreview: scan.frame == null,
        steadyFrames: steady,
      );

      if (steady >= steadyFramesRequired) {
        await _capture();
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _capture() async {
    state = state.copyWith(stage: PalmScanStage.capturing);
    await _frames?.cancel();
    _frames = null;

    final camera = ref.read(palmCameraProvider);
    final still = await camera.capture();
    await camera.stop();
    if (!ref.mounted) return;

    switch (still) {
      case Err(:final failure):
        state = state.copyWith(
          stage: PalmScanStage.failed,
          failure: failure,
        );
      case Ok(value: final image):
        state = state.copyWith(still: image);
        await _compose(image);
    }
  }

  Future<void> _compose(PalmFrameImage image) async {
    final result = await Result.guard(
      () async {
        // Detected a second time, on the still rather than a preview
        // frame. The still is sharper and differently cropped, so the
        // landmarks from the stream would be subtly wrong on it — and
        // "subtly wrong" here means every line sits a few millimetres
        // off the crease it is supposed to be describing.
        final detector = ref.read(palmDetectorProvider);
        final extractor = ref.read(palmRidgeExtractorProvider);

        final landmarks = await detector.detect(image);
        if (landmarks == null) throw StateError('the hand left the frame');

        final source = await extractor?.extract(
          image: image,
          landmarks: landmarks,
        );

        try {
          final reading = PalmComposer.compose(
            landmarks: landmarks,
            at: ref.read(clockProvider).now(),
            field: source?.field,
          );
          if (reading == null) throw StateError('the palm could not be read');
          return reading;
        } finally {
          source?.dispose();
        }
      },
      onError: (error, stackTrace) => UnexpectedFailure(
        'Could not read that one — try again',
        cause: error,
        stackTrace: stackTrace,
      ),
    );

    if (!ref.mounted) return;

    state = switch (result) {
      Ok(value: final reading) => state.copyWith(
        stage: PalmScanStage.revealed,
        reading: reading,
      ),
      Err(:final failure) => state.copyWith(
        stage: PalmScanStage.failed,
        failure: failure,
      ),
    };
  }
}
