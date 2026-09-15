import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_colors.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_geometry.dart';
import 'package:sanctum/src/domain/services/palm_line_template.dart';
import 'package:sanctum/src/features/palm/view/palm_reveal_timeline.dart';
import 'package:sanctum/src/features/palm/view/widgets/palm_reveal_painter.dart';

import '../support/palm_fixtures.dart';

const _size = Size(360, 640);

late final SanctumColors _colors;
late final List<PalmCurve> _curves;

/// Paints the reveal at [seconds] and reads the result back.
///
/// A real rasterisation rather than a mock canvas: what these tests are
/// actually worried about is whether a line lands on the hand, and only
/// pixels can answer that.
Future<ui.Image> _render(double seconds) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Offset.zero & _size);

  PalmRevealPainter(
    frame: PalmRevealTimeline.at(
      Duration(microseconds: (seconds * 1000000).round()),
    ),
    curves: _curves,
    colors: _colors,
    labelStyle: const TextStyle(fontSize: 11, color: Color(0xFFFFFFFF)),
    verdictHeadline: 'A hand that decides late and means it',
    verdictStyle: const TextStyle(fontSize: 20, color: Color(0xFFFFFFFF)),
  ).paint(canvas, _size);

  return recorder.endRecording().toImage(
    _size.width.toInt(),
    _size.height.toInt(),
  );
}

/// How many pixels differ from the background ground.
Future<int> _litPixels(ui.Image image, {Rect? within}) async {
  final data = await image.toByteData();
  final bytes = data!.buffer.asUint8List();
  final ground = _colors.background;
  var lit = 0;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (within != null &&
          !within.contains(Offset(x.toDouble(), y.toDouble()))) {
        continue;
      }
      final i = (y * image.width + x) * 4;
      final delta =
          (bytes[i] - (ground.r * 255)).abs() +
          (bytes[i + 1] - (ground.g * 255)).abs() +
          (bytes[i + 2] - (ground.b * 255)).abs();
      if (delta > 24) lit++;
    }
  }
  return lit;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    _colors = SanctumColors.nocturne();
    final geometry = PalmGeometry.rectify(goodHand())!;
    _curves = [
      for (final curve in PalmLineTemplate.principal) geometry.place(curve),
    ];
  });

  test('paints every instant of the reveal without throwing', () async {
    for (var t = 0.0; t <= 10.5; t += 0.25) {
      final image = await _render(t);
      expect(image.width, 360);
      image.dispose();
    }
  });

  test('draws nothing on the palm before the draw beat', () async {
    final image = await _render(4);
    expect(await _litPixels(image), lessThan(600));
    image.dispose();
  });

  test('more of the palm is lit as the lines are drawn', () async {
    final early = await _render(4.3);
    final late_ = await _render(6.9);

    final earlyLit = await _litPixels(early);
    final lateLit = await _litPixels(late_);

    expect(earlyLit, greaterThan(0));
    expect(lateLit, greaterThan(earlyLit * 2));

    early.dispose();
    late_.dispose();
  });

  test('lands the lines on the hand, not somewhere near it', () async {
    // The coordinate mapping, pinned with pixels. `PalmSpace.image` is
    // normalised to the frame's *width* on both axes; scaling `y` by the
    // height instead produces lines that look almost right, which is the
    // hardest version of this bug to notice.
    final image = await _render(6.9);

    final expected = Rect.fromPoints(
      const Offset(150, 250),
      const Offset(340, 400),
    );
    final everywhere = await _litPixels(image);
    final inside = await _litPixels(image, within: expected.inflate(30));

    expect(inside / everywhere, greaterThan(0.75));
    image.dispose();
  });

  test('repaints when the instant changes and not otherwise', () {
    PalmRevealPainter painterAt(double seconds) => PalmRevealPainter(
      frame: PalmRevealTimeline.at(
        Duration(microseconds: (seconds * 1000000).round()),
      ),
      curves: _curves,
      colors: _colors,
      labelStyle: const TextStyle(fontSize: 11),
    );

    expect(painterAt(5).shouldRepaint(painterAt(6)), isTrue);
    expect(painterAt(5).shouldRepaint(painterAt(5)), isFalse);
  });
}
