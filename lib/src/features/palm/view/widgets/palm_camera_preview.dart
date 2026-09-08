import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:sanctum/src/data/services/palm/camera_palm_camera.dart';

/// The live viewfinder.
///
/// ## Why it fills rather than fits
///
/// The guide outline and the reveal are both laid out against the
/// frame's own coordinates, and `PalmGuidePainter` maps them across the
/// full width of the canvas. Letterboxing the preview would leave the
/// outline floating over black bars that the geometry knows nothing
/// about, so the preview is cropped to cover instead — the same
/// `BoxFit.cover` the reveal painter applies to the still, for the same
/// reason.
///
/// ## Why it listens rather than watches
///
/// [CameraPalmCamera] is a `ChangeNotifier` because a controller does
/// not exist until `start()` has finished, and there is no Riverpod
/// state change to hang a rebuild on — the provider hands out the same
/// adapter instance throughout.
class PalmCameraPreview extends StatelessWidget {
  /// Creates the preview for [camera].
  const PalmCameraPreview({required this.camera, super.key});

  /// The adapter holding the controller.
  final CameraPalmCamera camera;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: camera,
    builder: (context, _) {
      final controller = camera.controller;
      if (controller == null || !controller.value.isInitialized) {
        // Nothing, rather than a spinner. The scan screen is already
        // showing its own instruction over this, and a second thing
        // appearing and vanishing under it reads as a flicker.
        return const SizedBox.expand();
      }

      final size = controller.value.previewSize;
      if (size == null) return const SizedBox.expand();

      return ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            // Swapped. `previewSize` is reported in the sensor's own
            // orientation, which is landscape on effectively every
            // phone, so using it directly gives a preview rotated a
            // quarter turn inside a box of the wrong shape.
            width: size.height,
            height: size.width,
            child: CameraPreview(controller),
          ),
        ),
      );
    },
  );
}
