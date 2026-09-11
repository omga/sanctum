import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Renders the widget behind [key] to PNG bytes.
///
/// The widget must be a [RepaintBoundary] that has painted: an off-screen
/// page, or one still animating in, has no layer to read. The image is
/// released as soon as it is encoded — at four times a phone's width a
/// capture is tens of megabytes of pixels, and leaving it for the
/// collector on a screen that also holds a decoded twelve-megapixel still
/// is how a save turns into a memory warning.
Future<Uint8List> captureBoundaryPng(
  GlobalKey key, {
  double pixelRatio = 3,
}) async {
  final object = key.currentContext?.findRenderObject();
  if (object == null || object is! RenderRepaintBoundary) {
    throw StateError('capture target is not a RepaintBoundary');
  }

  final image = await object.toImage(pixelRatio: pixelRatio);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('could not encode the image');
    return bytes.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
