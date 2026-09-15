import 'package:flutter_test/flutter_test.dart';
import 'package:hand_detection/hand_detection.dart' as hd;
import 'package:sanctum/src/data/services/palm/hand_detection_palm_detector.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_geometry.dart';

import '../support/palm_fixtures.dart';

/// This package's name for one of ours, so a fixture can be written in
/// our terms and handed over in theirs.
const Map<PalmLandmark, hd.HandLandmarkType> _types = {
  PalmLandmark.wrist: hd.HandLandmarkType.wrist,
  PalmLandmark.thumbCmc: hd.HandLandmarkType.thumbCMC,
  PalmLandmark.thumbMcp: hd.HandLandmarkType.thumbMCP,
  PalmLandmark.thumbIp: hd.HandLandmarkType.thumbIP,
  PalmLandmark.thumbTip: hd.HandLandmarkType.thumbTip,
  PalmLandmark.indexMcp: hd.HandLandmarkType.indexFingerMCP,
  PalmLandmark.indexPip: hd.HandLandmarkType.indexFingerPIP,
  PalmLandmark.indexDip: hd.HandLandmarkType.indexFingerDIP,
  PalmLandmark.indexTip: hd.HandLandmarkType.indexFingerTip,
  PalmLandmark.middleMcp: hd.HandLandmarkType.middleFingerMCP,
  PalmLandmark.middlePip: hd.HandLandmarkType.middleFingerPIP,
  PalmLandmark.middleDip: hd.HandLandmarkType.middleFingerDIP,
  PalmLandmark.middleTip: hd.HandLandmarkType.middleFingerTip,
  PalmLandmark.ringMcp: hd.HandLandmarkType.ringFingerMCP,
  PalmLandmark.ringPip: hd.HandLandmarkType.ringFingerPIP,
  PalmLandmark.ringDip: hd.HandLandmarkType.ringFingerDIP,
  PalmLandmark.ringTip: hd.HandLandmarkType.ringFingerTip,
  PalmLandmark.pinkyMcp: hd.HandLandmarkType.pinkyMCP,
  PalmLandmark.pinkyPip: hd.HandLandmarkType.pinkyPIP,
  PalmLandmark.pinkyDip: hd.HandLandmarkType.pinkyDIP,
  PalmLandmark.pinkyTip: hd.HandLandmarkType.pinkyTip,
};

const _width = 640;
const _height = 480;

/// A detection whose landmarks are [points], in pixels.
hd.Hand handOf(
  Map<PalmLandmark, PalmPoint> points, {
  hd.Handedness? handedness = hd.Handedness.left,
  double score = 0.9,
  int width = _width,
  int height = _height,
}) => hd.Hand(
  boundingBox: hd.BoundingBox.ltrb(0, 0, width.toDouble(), height.toDouble()),
  score: score,
  imageWidth: width,
  imageHeight: height,
  handedness: handedness,
  landmarks: [
    for (final entry in points.entries)
      hd.HandLandmark(
        type: _types[entry.key]!,
        x: entry.value.x,
        y: entry.value.y,
        z: 0,
        visibility: 1,
      ),
  ],
);

/// The canonical fixture hand, posed and scaled into pixel space.
Map<PalmLandmark, PalmPoint> pixelHand({
  double scale = 260,
  double dx = 180,
  double dy = 40,
}) => {
  for (final entry in canonicalHand.entries)
    entry.key: PalmPoint(
      dx + entry.value.x * scale,
      dy + entry.value.y * scale,
    ),
};

void main() {
  group('coordinates', () {
    test('normalise both axes by the width, never per axis', () {
      // The conversion `PalmSpace.image` exists for. Dividing y by the
      // height instead makes a vertical millimetre 1.33x a horizontal
      // one on this frame, and every distance the geometry measures
      // inherits it.
      final hand = handOf({
        for (final landmark in PalmLandmark.values)
          landmark: const PalmPoint(320, 240),
      });

      final landmarks = HandDetectionPalmDetector.landmarksFrom(hand)!;

      expect(landmarks[PalmLandmark.wrist].x, closeTo(0.5, 1e-9));
      expect(landmarks[PalmLandmark.wrist].y, closeTo(0.375, 1e-9));
      expect(landmarks.frameAspect, closeTo(_height / _width, 1e-9));
    });

    test('map every point to the landmark it belongs to', () {
      // Both sides carry MediaPipe's 21 points in the same order today.
      // This asserts the mapping rather than the coincidence.
      final points = {
        for (final (index, landmark) in PalmLandmark.values.indexed)
          landmark: PalmPoint(index.toDouble(), index * 2),
      };

      final landmarks = HandDetectionPalmDetector.landmarksFrom(
        handOf(points),
      )!;

      for (final (index, landmark) in PalmLandmark.values.indexed) {
        expect(landmarks[landmark].x, closeTo(index / _width, 1e-9));
        expect(landmarks[landmark].y, closeTo(index * 2 / _width, 1e-9));
      }
    });
  });

  group('handedness', () {
    test('is flipped, because the model assumes a mirrored image', () {
      expect(HandDetectionPalmDetector.assumesMirroredInput, isTrue);

      expect(
        HandDetectionPalmDetector.landmarksFrom(
          handOf(pixelHand(), handedness: hd.Handedness.left),
        )!.handedness,
        Handedness.right,
      );
      expect(
        HandDetectionPalmDetector.landmarksFrom(
          handOf(pixelHand(), handedness: hd.Handedness.right),
        )!.handedness,
        Handedness.left,
      );
    });

    test('the flip is what lets a real palm read as a palm', () {
      // The property the whole feature rests on, and the reason the flip
      // is not cosmetic. `canonicalHand` is a right palm facing the
      // lens; MediaPipe, assuming a mirrored input it did not get,
      // labels it "left". Flipped, the chirality and the handedness
      // agree and the frame is ready. Unflipped, they disagree, every
      // palm reports as a back of a hand, and the shutter never fires.
      final landmarks = HandDetectionPalmDetector.landmarksFrom(
        handOf(pixelHand(), handedness: hd.Handedness.left),
      )!;

      expect(landmarks.isPalmFacing, isTrue);
      expect(
        PalmGeometry.evaluate(landmarks).readiness,
        isNot(PalmReadiness.backOfHand),
      );
    });

    test('a hand with no handedness is dropped', () {
      // Without it the back-of-hand check cannot run, and that check is
      // the difference between reading a palm and reading knuckles.
      expect(
        HandDetectionPalmDetector.landmarksFrom(
          handOf(pixelHand(), handedness: null),
        ),
        isNull,
      );
    });
  });

  group('a hand that is not all there', () {
    test('is dropped rather than guessed at', () {
      final partial = pixelHand()..remove(PalmLandmark.pinkyTip);

      expect(
        HandDetectionPalmDetector.landmarksFrom(handOf(partial)),
        isNull,
      );
    });

    test('and so is one with no landmarks at all', () {
      expect(
        HandDetectionPalmDetector.landmarksFrom(handOf(const {})),
        isNull,
      );
    });

    test('and so is a frame of no size', () {
      expect(
        HandDetectionPalmDetector.landmarksFrom(
          handOf(pixelHand(), width: 0, height: 0),
        ),
        isNull,
      );
    });
  });

  test('carries the detector score through as confidence', () {
    final landmarks = HandDetectionPalmDetector.landmarksFrom(
      handOf(pixelHand(), score: 0.42),
    )!;
    expect(landmarks.confidence, closeTo(0.42, 1e-9));
  });

  test('produces a hand the geometry can rectify', () {
    // End to end over the seam: a detection in this package's terms
    // becomes a warp in ours, with no step in between.
    final landmarks = HandDetectionPalmDetector.landmarksFrom(
      handOf(pixelHand(), handedness: hd.Handedness.left),
    )!;

    final frame = PalmGeometry.rectify(landmarks);

    expect(frame, isNotNull);
    expect(frame!.residual, lessThan(PalmGeometry.maxResidual));
  });
}
