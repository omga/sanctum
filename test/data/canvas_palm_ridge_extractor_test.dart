import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/data/services/palm/canvas_palm_ridge_extractor.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_detector.dart';
import 'package:sanctum/src/domain/services/palm_geometry.dart';
import 'package:sanctum/src/domain/services/palm_line_template.dart';

import '../support/palm_fixtures.dart';

const _width = 480;
const _height = 640;
const _frame = Rect.fromLTWH(0, 0, 480, 640);
const double _aspect = _height / _width;

/// A photograph of a palm whose creases sit exactly on [creases].
///
/// Drawn through the same warp the extractor will invert, so the test
/// knows where every crease is in canonical space to the pixel — which
/// is the only way to tell a correct rectification from one that is
/// merely plausible.
Future<Uint8List> _photograph(
  PalmFrame frame,
  List<PalmCurve> creases,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(
      _frame,
      Paint()..color = const Color(0xFFC8C8C8),
    );

  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFF505050);

  for (final curve in creases) {
    final placed = frame.place(curve);
    Offset at(PalmPoint point) => Offset(point.x, point.y) * _width.toDouble();

    final path = Path()
      ..moveTo(
        at(placed.controlPoints.first).dx,
        at(placed.controlPoints.first).dy,
      );
    for (var s = 0; s < placed.segmentCount; s++) {
      final c1 = at(placed.controlPoints[s * 3 + 1]);
      final c2 = at(placed.controlPoints[s * 3 + 2]);
      final end = at(placed.controlPoints[s * 3 + 3]);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
    }
    canvas.drawPath(path, paint);
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(_width, _height);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  return png!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HandLandmarks landmarks;
  late PalmFrame frame;

  setUpAll(() {
    landmarks = handAt(pose(scale: 0.5), frameAspect: _aspect);
    frame = PalmGeometry.rectify(landmarks)!;
  });

  Future<RidgeFieldSource?> extract(List<PalmCurve> creases) async {
    final bytes = await _photograph(frame, creases);
    return const CanvasPalmRidgeExtractor().extract(
      image: PalmFrameImage(
        bytes: bytes,
        width: _width,
        height: _height,
        format: PalmImageFormat.jpeg,
      ),
      landmarks: landmarks,
    );
  }

  test(
    'rectifies the palm, so creases land where the template looks',
    () async {
      // The matrix in `_rectify` is three transforms composed, and a wrong
      // one produces a crop that looks like a hand and answers every
      // question in the wrong place. Drawing the creases *through* the
      // warp and reading them back *through* its inverse is what pins it.
      final source = (await extract(PalmLineTemplate.principal))!;
      addTearDown(source.dispose);

      for (final curve in PalmLineTemplate.principal) {
        final anchors = curve.anchors;
        final middle = anchors[anchors.length ~/ 2];
        expect(
          source.field.responseAt(middle),
          greaterThan(0.35),
          reason: '${curve.line} was not found where it was drawn',
        );
      }
    },
  );

  test('answers quietly where no crease was drawn', () async {
    final source = (await extract([PalmLineTemplate.heart]))!;
    addTearDown(source.dispose);

    // The life line's lower reach, on a palm that only has a heart line.
    expect(
      source.field.responseAt(const PalmPoint(0.40, 0.90)),
      lessThan(0.2),
    );
  });

  test('a palm with nothing on it supports nothing', () async {
    final source = (await extract(const []))!;
    addTearDown(source.dispose);

    for (final curve in PalmLineTemplate.principal) {
      expect(
        source.field.responseAt(curve.anchors.first),
        lessThan(0.1),
      );
    }
  });

  test('refuses a pose it cannot rectify', () async {
    final collapsed = handAt(
      pose(),
      canonical: {
        for (final entry in canonicalHand.entries)
          entry.key: const PalmPoint(0.5, 0.5),
      },
    );

    expect(
      await const CanvasPalmRidgeExtractor().extract(
        image: PalmFrameImage(
          bytes: Uint8List(0),
          width: _width,
          height: _height,
          format: PalmImageFormat.jpeg,
        ),
        landmarks: collapsed,
      ),
      isNull,
    );
  });

  test(
    'returns nothing rather than throwing on bytes it cannot read',
    () async {
      // A still that will not decode is a scan without crease detail, not
      // a scan that failed: `PalmComposer` draws the bare template from a
      // null field.
      expect(
        await const CanvasPalmRidgeExtractor().extract(
          image: PalmFrameImage(
            bytes: Uint8List.fromList([1, 2, 3, 4]),
            width: _width,
            height: _height,
            format: PalmImageFormat.jpeg,
          ),
          landmarks: landmarks,
        ),
        isNull,
      );
    },
  );
}
