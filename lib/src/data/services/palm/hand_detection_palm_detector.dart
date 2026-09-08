import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:hand_detection/hand_detection.dart' as hd;
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_detector.dart';

/// [PalmDetector] on top of the `hand_detection` package.
///
/// ## What this adapter is actually for
///
/// Three conversions, each of which is a bug if it is wrong and none of
/// which is obvious:
///
/// 1. **Pixels to width-normalised space.** The package returns
///    landmarks in the pixel space of the frame it ran on, and reports
///    that frame's size alongside them. `PalmSpace.image` divides *both*
///    axes by the width — see the note there on why per-axis
///    normalisation quietly distorts every distance the geometry
///    measures.
/// 2. **Landmark order.** Both sides carry MediaPipe's 21 points, and
///    both list them in the same order, but "both happen to agree today"
///    is not something to build a warp on. Each point is fetched by
///    name.
/// 3. **Handedness.** See below. It is the one that decides whether the
///    feature works at all.
///
/// ## The handedness flip
///
/// MediaPipe's hand landmark model emits handedness **on the assumption
/// that its input is mirrored** — the selfie convention. `hand_detection`
/// passes that output through untouched, and our frames come from the
/// rear camera and are not mirrored. So the label arrives inverted, and
/// [assumesMirroredInput] flips it back.
///
/// This is not cosmetic. `HandLandmarks.isPalmFacing` compares the
/// reported handedness against the pose's chirality; get the flip wrong
/// and *every palm reads as the back of a hand*, the readiness check
/// never passes, and the shutter never fires — on a scan that looks
/// perfectly aligned.
///
/// **Unverified on a device.** It follows from MediaPipe's documented
/// convention and from reading this package's source, which is as far as
/// reasoning goes. Spike S2 settles it, and the symptom names itself: if
/// a real palm held flat to the lens reports
/// [PalmReadiness.backOfHand], this constant is the wrong way round.
class HandDetectionPalmDetector implements PalmDetector {
  /// Creates a detector. The model loads on first use, not here.
  HandDetectionPalmDetector({this.maxDimension = 640});

  /// Whether the model's handedness output assumes a mirrored image.
  ///
  /// True for MediaPipe. Flipping the label is the correction; see the
  /// class doc for what happens if this is wrong.
  static const bool assumesMirroredInput = true;

  /// The longest edge the detector downscales a frame to.
  ///
  /// The landmark model's own input is far smaller than this, and the
  /// palm detector's is smaller still — feeding a full preview frame in
  /// buys nothing and costs the resize.
  final int maxDimension;

  hd.HandDetector? _detector;
  Future<hd.HandDetector>? _loading;

  /// Loads the model once, even if several frames race for it.
  ///
  /// Without the shared future the first two frames each build a
  /// detector, and the loser leaks an interpreter and its models.
  Future<hd.HandDetector> _ready() async {
    final existing = _detector;
    if (existing != null) return existing;

    return _detector = await (_loading ??= hd.HandDetector.create(
      // Landmarks are the whole point; boxes alone would not place a
      // line. Gestures are off — that is a second model, loaded and
      // shipped, for a question nobody here asks. Stated rather than
      // left to the default, because the default going the other way
      // would add it back silently.
      // ignore: avoid_redundant_argument_values
      enableGestures: false,
      // Tracking reuses the previous frame's region instead of running
      // the palm detector again, which is most of the per-frame cost.
      // It also steadies the warp between frames, and a warp that
      // breathes reads on video as the lines crawling.
      enableTracking: true,
    ));
  }

  @override
  Future<HandLandmarks?> detect(PalmFrameImage image) async {
    final detector = await _ready();

    final hands = switch (image.platformFrame) {
      // The live path. The package takes the platform frame as `Object`,
      // so handing it over costs no copy and no re-encode.
      final Object frame => await detector.detectFromCameraImage(
        frame,
        rotation: hd.rotationForFrame(
          width: image.width,
          height: image.height,
          sensorOrientation: image.rotationDegrees,
          isFrontCamera: image.isFrontFacing,
          // The scan is portrait. `PalmGeometry` refuses an oblique
          // palm anyway, so a landscape scan was never going to be
          // captured — and pretending to support one would mean
          // threading a live orientation through the domain layer for a
          // frame that gets rejected.
          deviceOrientation: DeviceOrientation.portraitUp,
        ),
        maxDim: maxDimension,
      ),
      // The still. Encoded bytes, which is what `detect` wants.
      null => await detector.detect(image.bytes),
    };

    if (hands.isEmpty) return null;

    // The largest hand, not the first. Two hands in frame is a common
    // way to hold a phone, and the one being read is the near one.
    final hand = hands.reduce(
      (a, b) =>
          a.boundingBox.width * a.boundingBox.height >=
              b.boundingBox.width * b.boundingBox.height
          ? a
          : b,
    );

    return landmarksFrom(hand);
  }

  @override
  Future<void> dispose() async {
    final detector = _detector;
    _detector = null;
    _loading = null;
    await detector?.dispose();
  }

  /// Converts one detection, or null if it is not a whole hand.
  ///
  /// Public because it is the whole adapter. Everything else here is
  /// plumbing around a model that cannot run in a test; the three
  /// conversions this performs are where the bugs live, and they are
  /// testable from a hand-built [hd.Hand] without a model, a camera or
  /// a device.
  static HandLandmarks? landmarksFrom(hd.Hand hand) {
    if (!hand.hasLandmarks) return null;

    final width = hand.imageWidth.toDouble();
    final height = hand.imageHeight.toDouble();
    if (width <= 0 || height <= 0) return null;

    final points = <PalmPoint>[];
    for (final landmark in PalmLandmark.values) {
      final found = hand.getLandmark(_typeOf(landmark));
      // A partial hand is not a hand. Returning 20 points and a guess
      // would put a warp on the screen that nothing measured.
      if (found == null) return null;
      points.add(PalmPoint(found.x / width, found.y / width));
    }

    final handedness = switch (hand.handedness) {
      hd.Handedness.left => Handedness.left,
      hd.Handedness.right => Handedness.right,
      // No handedness means the back-of-hand check cannot run, and that
      // check is the difference between reading a palm and reading a
      // set of knuckles. Drop the frame; the next one is 60 ms away.
      null => null,
    };
    if (handedness == null) return null;

    return HandLandmarks(
      points: points,
      handedness: assumesMirroredInput ? handedness.opposite : handedness,
      confidence: hand.score,
      frameAspect: height / width,
    );
  }

  /// This package's name for one of ours.
  ///
  /// Exhaustive, so a landmark added to [PalmLandmark] cannot silently
  /// map to nothing.
  static hd.HandLandmarkType _typeOf(PalmLandmark landmark) =>
      switch (landmark) {
        PalmLandmark.wrist => hd.HandLandmarkType.wrist,
        PalmLandmark.thumbCmc => hd.HandLandmarkType.thumbCMC,
        PalmLandmark.thumbMcp => hd.HandLandmarkType.thumbMCP,
        PalmLandmark.thumbIp => hd.HandLandmarkType.thumbIP,
        PalmLandmark.thumbTip => hd.HandLandmarkType.thumbTip,
        PalmLandmark.indexMcp => hd.HandLandmarkType.indexFingerMCP,
        PalmLandmark.indexPip => hd.HandLandmarkType.indexFingerPIP,
        PalmLandmark.indexDip => hd.HandLandmarkType.indexFingerDIP,
        PalmLandmark.indexTip => hd.HandLandmarkType.indexFingerTip,
        PalmLandmark.middleMcp => hd.HandLandmarkType.middleFingerMCP,
        PalmLandmark.middlePip => hd.HandLandmarkType.middleFingerPIP,
        PalmLandmark.middleDip => hd.HandLandmarkType.middleFingerDIP,
        PalmLandmark.middleTip => hd.HandLandmarkType.middleFingerTip,
        PalmLandmark.ringMcp => hd.HandLandmarkType.ringFingerMCP,
        PalmLandmark.ringPip => hd.HandLandmarkType.ringFingerPIP,
        PalmLandmark.ringDip => hd.HandLandmarkType.ringFingerDIP,
        PalmLandmark.ringTip => hd.HandLandmarkType.ringFingerTip,
        PalmLandmark.pinkyMcp => hd.HandLandmarkType.pinkyMCP,
        PalmLandmark.pinkyPip => hd.HandLandmarkType.pinkyPIP,
        PalmLandmark.pinkyDip => hd.HandLandmarkType.pinkyDIP,
        PalmLandmark.pinkyTip => hd.HandLandmarkType.pinkyTip,
      };
}
