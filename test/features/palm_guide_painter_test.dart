import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_colors.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_geometry.dart';
import 'package:sanctum/src/features/palm/view/widgets/palm_guide_painter.dart';

import '../support/palm_fixtures.dart';

const _size = Size(360, 640);
late final SanctumColors _colors;

Future<ui.Image> _render(PalmGuidePainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder, Offset.zero & _size), _size);
  return recorder.endRecording().toImage(
    _size.width.toInt(),
    _size.height.toInt(),
  );
}

/// The box the drawn pixels actually occupy.
Future<Rect> _inkBounds(ui.Image image) async {
  final data = await image.toByteData();
  final bytes = data!.buffer.asUint8List();

  var left = image.width.toDouble();
  var top = image.height.toDouble();
  var right = 0.0;
  var bottom = 0.0;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      // Alpha only: the painter draws onto a transparent canvas, so
      // anything with alpha is ink.
      if (bytes[(y * image.width + x) * 4 + 3] > 12) {
        left = left < x ? left : x.toDouble();
        top = top < y ? top : y.toDouble();
        right = right > x ? right : x.toDouble();
        bottom = bottom > y ? bottom : y.toDouble();
      }
    }
  }
  return Rect.fromLTRB(left, top, right, bottom);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => _colors = SanctumColors.nocturne());

  test('the target is hand-shaped, not a blob', () async {
    // The first version was eleven authored points and came out a
    // lopsided circle on a phone: roughly square, no fingers, nothing
    // about it saying "hand". A hand is much taller than it is wide,
    // and that is the cheapest property to hold it to.
    final image = await _render(
      PalmGuidePainter(colors: _colors, hold: 0),
    );
    final ink = await _inkBounds(image);

    expect(ink.height, greaterThan(ink.width * 1.25));
    image.dispose();
  });

  test('the target fits on the screen with room around it', () async {
    final image = await _render(
      PalmGuidePainter(colors: _colors, hold: 0),
    );
    final ink = await _inkBounds(image);

    expect(ink.left, greaterThan(8));
    expect(ink.top, greaterThan(8));
    expect(ink.right, lessThan(_size.width - 8));
    expect(ink.bottom, lessThan(_size.height - 8));
    expect(ink.width, greaterThan(_size.width * 0.35));
    image.dispose();
  });

  test('a detected hand is outlined where it actually is', () async {
    // The live outline goes through the warp, so it has to land on the
    // hand rather than in the middle of the screen where the target is.
    final frame = PalmGeometry.rectify(
      handAt(pose(translation: const PalmPoint(0.05, 0.12))),
    )!;

    final image = await _render(
      PalmGuidePainter(colors: _colors, hold: 0, frame: frame),
    );
    final ink = await _inkBounds(image);

    // Pulled well left of centre by the pose, which a target-only
    // render could not be.
    expect(ink.center.dx, lessThan(_size.width * 0.45));
    image.dispose();
  });

  test('repaints only when something it draws has changed', () {
    final still = PalmGuidePainter(colors: _colors, hold: 0);
    expect(
      still.shouldRepaint(PalmGuidePainter(colors: _colors, hold: 0.5)),
      isTrue,
    );
    expect(still.shouldRepaint(still), isFalse);
  });
}
