import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/domain/services/palm_camera.dart';
import 'package:sanctum/src/domain/services/palm_detector.dart';

/// [PalmCamera] on top of the `camera` plugin.
///
/// ## The back camera, deliberately
///
/// A palm scan seems like a front-camera gesture and is not. Two reasons
/// decide it:
///
/// - **Resolution.** The entire product is whether the crease filter can
///   see this person's lines rather than a template. Front sensors on
///   most phones are a fraction of the rear one, and every pixel lost is
///   detail the ridge filter never gets.
/// - **Mirroring.** A front preview is mirrored for the viewer, the raw
///   stream is not, and which of the two a detector sees differs by
///   platform. `HandLandmarks.isPalmFacing` compares reported handedness
///   against the pose's chirality, and a mirror flips both — so the
///   back-of-hand check passes on a back of a hand. The rear camera has
///   no such ambiguity.
///
/// Holding the phone in one hand and the palm of the other in front of
/// it is the natural posture anyway, and it is the one that films well.
///
/// ## The still is a real capture, not the newest preview frame
///
/// The stream runs at a resolution chosen so a detector can keep up with
/// it. That is nowhere near enough for creases. So [capture] stops the
/// stream and takes an actual photograph, which is the whole reason the
/// reveal is rendered from a still rather than recorded live.
class CameraPalmCamera extends ChangeNotifier implements PalmCamera {
  /// Creates an adapter.
  ///
  /// [describe] and [build] exist so the failure paths — no camera on
  /// the device, permission refused — can be tested without one.
  CameraPalmCamera({
    Future<List<CameraDescription>> Function()? describe,
    CameraController Function(CameraDescription)? build,
  }) : _describe = describe ?? availableCameras,
       _build = build ?? _defaultController;

  final Future<List<CameraDescription>> Function() _describe;
  final CameraController Function(CameraDescription) _build;

  final StreamController<PalmFrameImage> _frames =
      StreamController<PalmFrameImage>.broadcast();

  CameraController? _controller;
  CameraDescription? _description;
  var _streaming = false;

  /// The live controller, for the preview surface. Null until [start]
  /// has finished.
  CameraController? get controller => _controller;

  @override
  Stream<PalmFrameImage> get frames => _frames.stream;

  static CameraController _defaultController(
    CameraDescription description,
  ) => CameraController(
    description,
    // Matched to the detector's own downscale, which is 640 on the long
    // edge. `high` is 720p: every frame of it is 1.4 MB that gets
    // resized away before inference, allocated thirty times a second,
    // and the garbage collector notices long before the model does.
    // `medium` is 720x480 and loses nothing the detector would have
    // kept.
    //
    // The still is unaffected — `takePicture` shoots at the sensor's own
    // resolution, which is the whole reason the reveal is rendered from
    // a photograph rather than from a preview frame.
    ResolutionPreset.medium,
    // Nothing here records audio. This is what keeps the microphone out
    // of the store listing — see the removal in AndroidManifest.xml and
    // the absent purpose string in Info.plist.
    enableAudio: false,
    imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
        ? ImageFormatGroup.bgra8888
        : ImageFormatGroup.nv21,
  );

  @override
  Future<Result<void>> start() async {
    if (_controller != null) return const Ok(null);

    return Result.guard(
      () async {
        final cameras = await _describe();
        if (cameras.isEmpty) {
          throw StateError('this device has no camera');
        }

        final description = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        final controller = _build(description);
        await controller.initialize();

        _controller = controller;
        _description = description;
        notifyListeners();

        await controller.startImageStream(_onImage);
        _streaming = true;
      },
      onError: _failureFor,
    );
  }

  @override
  Future<Result<PalmFrameImage>> capture() async {
    final controller = _controller;
    if (controller == null) {
      return const Err(
        UnexpectedFailure('The camera is not open'),
      );
    }

    return Result.guard(
      () async {
        // Stopped first. A capture taken while the stream is running is
        // supported unevenly across the two platform implementations,
        // and the stream has no further use once the shutter has fired.
        if (_streaming) {
          _streaming = false;
          await controller.stopImageStream();
        }

        final file = await controller.takePicture();
        final bytes = await file.readAsBytes();

        // The JPEG's own dimensions, not the preview's. Read from the
        // header rather than by decoding: `PalmFrameImage.aspect` feeds
        // every distance the geometry measures, and the preview's aspect
        // is not the still's on most phones.
        final descriptor = await ui.ImageDescriptor.encoded(
          await ui.ImmutableBuffer.fromUint8List(bytes),
        );
        final width = descriptor.width;
        final height = descriptor.height;
        descriptor.dispose();

        return PalmFrameImage(
          bytes: bytes,
          width: width,
          height: height,
          format: PalmImageFormat.jpeg,
          isFrontFacing:
              _description?.lensDirection == CameraLensDirection.front,
          // Left at the default zero. A still arrives upright: the
          // plugin bakes the sensor's rotation into the file's own
          // orientation, which the stream frames never get.
        );
      },
      onError: _failureFor,
    );
  }

  @override
  Future<void> stop() async {
    final release = _detach();
    notifyListeners();
    await release;
  }

  @override
  void dispose() {
    // Releases without notifying. `stop()` tells the preview a
    // controller has gone, and a `ChangeNotifier` that notifies after
    // its own disposal throws — which would land on every exit from the
    // scan screen, the one moment the camera most needs releasing.
    unawaited(_detach());
    unawaited(_frames.close());
    super.dispose();
  }

  /// Drops the controller and hands back the work of closing it.
  ///
  /// Synchronous up to the point the fields are cleared, so a second
  /// call — a `stop()` racing the provider's disposal — finds nothing
  /// left to release rather than disposing the same controller twice.
  Future<void> _detach() async {
    final controller = _controller;
    final streaming = _streaming;
    _controller = null;
    _description = null;
    _streaming = false;

    if (controller == null) return;
    if (streaming) await controller.stopImageStream();
    await controller.dispose();
  }

  void _onImage(CameraImage image) {
    // Dropped rather than queued, and the controller is broadcast so it
    // never buffers: a backed-up queue turns the viewfinder into a
    // recording of the recent past, and the steadiness counter would be
    // counting frames the user had already moved on from.
    if (_frames.isClosed || !_frames.hasListener) return;

    _frames.add(
      PalmFrameImage(
        bytes: _packPlanes(image),
        width: image.width,
        height: image.height,
        format: image.format.group == ImageFormatGroup.bgra8888
            ? PalmImageFormat.bgra8888
            : PalmImageFormat.nv21,
        // Passed through rather than applied. Rotating a frame here
        // would cost a copy per frame for a consumer that has to know
        // the angle anyway to place its landmarks.
        rotationDegrees: _description?.sensorOrientation ?? 0,
        isFrontFacing: _description?.lensDirection == CameraLensDirection.front,
        // The detector wants this, not the packed bytes: it crops and
        // rotates the YUV planes itself, and re-encoding a frame to
        // avoid handing it over would cost more than the inference.
        platformFrame: image,
      ),
    );
  }

  /// Flattens a frame's planes into one buffer.
  ///
  /// `ImageFormatGroup.nv21` and `bgra8888` both normally arrive as a
  /// single plane, and that path copies nothing. The concatenation is
  /// the fallback for an implementation that splits them, which is
  /// cheaper to write than to debug on a device that does.
  static Uint8List _packPlanes(CameraImage image) {
    if (image.planes.length == 1) return image.planes.first.bytes;

    final total = image.planes.fold<int>(
      0,
      (sum, plane) => sum + plane.bytes.length,
    );
    final packed = Uint8List(total);
    var offset = 0;
    for (final plane in image.planes) {
      packed.setAll(offset, plane.bytes);
      offset += plane.bytes.length;
    }
    return packed;
  }

  /// Turns a plugin exception into something a screen can show.
  ///
  /// The permission codes are named individually because they are the
  /// only failures a user can do anything about, and "Could not open the
  /// camera" in front of a refused permission is a dead end.
  static AppFailure _failureFor(Object error, StackTrace stackTrace) {
    if (error is CameraException) {
      final message = switch (error.code) {
        'CameraAccessDenied' || 'AudioAccessDenied' =>
          'Sanctum needs the camera to read a palm. '
              'You can turn it on in Settings.',
        'CameraAccessDeniedWithoutPrompt' || 'AudioAccessDeniedWithoutPrompt' =>
          'Camera access is off for Sanctum. Turn it on in Settings to '
              'scan a palm.',
        'CameraAccessRestricted' ||
        'AudioAccessRestricted' => 'This phone does not allow camera access.',
        _ => 'Could not open the camera',
      };
      return UnexpectedFailure(
        message,
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return UnexpectedFailure(
      'Could not open the camera',
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
