import 'dart:math' as math;
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

Future<ui.Image> _render(PalmGuidePainter painter, {Size size = _size}) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder, Offset.zero & size), size);
  return recorder.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
}

/// The box occupied by pixels at least [minimumAlpha] opaque.
Future<Rect> _inkBounds(ui.Image image, {int minimumAlpha = 12}) async {
  final data = await image.toByteData();
  final bytes = data!.buffer.asUint8List();

  var left = image.width.toDouble();
  var top = image.height.toDouble();
  var right = 0.0;
  var bottom = 0.0;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (bytes[(y * image.width + x) * 4 + 3] > minimumAlpha) {
        left = math.min(left, x.toDouble());
        top = math.min(top, y.toDouble());
        right = math.max(right, x.toDouble());
        bottom = math.max(bottom, y.toDouble());
      }
    }
  }
  return Rect.fromLTRB(left, top, right, bottom);
}

/// How many separate runs of ink a horizontal line at [y] crosses.
Future<int> _inkRuns(ui.Image image, int y) async {
  final data = await image.toByteData();
  final bytes = data!.buffer.asUint8List();
  var runs = 0;
  var inside = false;
  for (var x = 0; x < image.width; x++) {
    final ink = bytes[(y * image.width + x) * 4 + 3] > 12;
    if (ink && !inside) runs++;
    inside = ink;
  }
  return runs;
}

HandLandmarks _asHand(List<PalmPoint> points, double aspect) => HandLandmarks(
  points: points,
  // The canonical hand is a right palm facing the lens.
  handedness: Handedness.right,
  confidence: 1,
  frameAspect: aspect,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => _colors = SanctumColors.nocturne());

  test('the target has fingers', () async {
    // What the first two outlines lacked in different ways: one was a
    // fingerless circle, the next a bundle of sausages. A line across the
    // upper hand has to cross each finger's outline twice.
    final image = await _render(PalmGuidePainter(colors: _colors, hold: 0));
    final ink = await _inkBounds(image);

    final runs = await _inkRuns(
      image,
      (ink.top + ink.height * 0.28).round(),
    );

    expect(runs, greaterThanOrEqualTo(6));
    image.dispose();
  });

  test('the target is taller than it is wide', () async {
    // Loosely: a splayed thumb makes a real hand wide, so this only rules
    // out the square blob. The finger test above does the real work.
    final image = await _render(PalmGuidePainter(colors: _colors, hold: 0));
    final ink = await _inkBounds(image);

    expect(ink.height, greaterThan(ink.width * 1.1));
    image.dispose();
  });

  test('the target fits on the screen with room around it', () async {
    final image = await _render(PalmGuidePainter(colors: _colors, hold: 0));
    final ink = await _inkBounds(image);

    expect(ink.left, greaterThan(8));
    expect(ink.top, greaterThan(8));
    expect(ink.right, lessThan(_size.width - 8));
    expect(ink.bottom, lessThan(_size.height - 8));
    expect(ink.width, greaterThan(_size.width * 0.5));
    image.dispose();
  });

  group('a hand matching the target', () {
    // The promise the target makes. The first version sized it at a
    // pleasing fraction of the screen, which through the preview's crop
    // came out under the size check — so a hand placed exactly on the
    // outline was told to come closer.
    const screens = {
      'test canvas, 3:4 frame': (Size(360, 640), 4 / 3),
      'Pixel 6, 2:3 preview': (Size(411, 914), 3 / 2),
      'tall phone, 9:16 frame': (Size(393, 873), 16 / 9),
    };

    for (final entry in screens.entries) {
      test('is accepted — ${entry.key}', () {
        final (size, aspect) = entry.value;
        final hand = _asHand(
          PalmGuidePainter.targetLandmarks(size, aspect),
          aspect,
        );

        expect(PalmGeometry.evaluate(hand).readiness, PalmReadiness.ready);
        // With room: jitter must not flicker it across the threshold.
        expect(
          hand.knuckleSpan,
          greaterThan(PalmGeometry.minKnuckleSpan * 1.1),
        );
      });
    }
  });

  test('the live outline contains the hand it is tracing', () async {
    // Drawn from the detected landmarks through the cover crop, so every
    // visible landmark must fall inside it.
    const aspect = 4 / 3;
    final landmarks = handAt(pose(scale: 0.5), frameAspect: aspect);

    final image = await _render(
      PalmGuidePainter(
        colors: _colors,
        hold: 0,
        landmarks: landmarks.points,
        frameAspect: aspect,
      ),
    );
    final ink = await _inkBounds(image, minimumAlpha: 120);

    final width = math.max(_size.width, _size.height / aspect);
    final rect = Rect.fromCenter(
      center: _size.center(Offset.zero),
      width: width,
      height: width * aspect,
    );

    var checked = 0;
    for (final landmark in PalmLandmark.values) {
      final point = landmarks[landmark];
      final onCanvas = rect.topLeft + Offset(point.x, point.y) * rect.width;
      if (!(Offset.zero & _size).deflate(3).contains(onCanvas)) continue;
      checked++;
      expect(
        ink.inflate(2).contains(onCanvas),
        isTrue,
        reason: '$landmark at $onCanvas is outside the outline $ink',
      );
    }
    expect(checked, greaterThan(15));

    image.dispose();
  });

  test('the live outline follows the hand, not the target', () async {
    // Only the bright live stroke counts here; the target stays faint in
    // the middle of the screen whatever the hand does.
    final image = await _render(
      PalmGuidePainter(
        colors: _colors,
        hold: 0,
        landmarks: handAt(
          pose(translation: const PalmPoint(0.05, 0.12)),
          frameAspect: 4 / 3,
        ).points,
      ),
    );
    final live = await _inkBounds(image, minimumAlpha: 120);

    expect(live.center.dx, lessThan(_size.width * 0.45));
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
