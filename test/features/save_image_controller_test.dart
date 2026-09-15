import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/data/services/gallery/image_gallery.dart';
import 'package:sanctum/src/features/sharing/view_model/save_image_controller.dart';

class _FakeGallery implements ImageGallery {
  Uint8List? saved;
  String? name;
  Result<void> answer = const Ok(null);

  @override
  Future<Result<void>> save(Uint8List png, {required String name}) async {
    saved = png;
    this.name = name;
    return answer;
  }
}

/// Pumps a small painted boundary and hands back a ref to drive the
/// controller with.
Future<WidgetRef> _pump(
  WidgetTester tester, {
  required _FakeGallery gallery,
  required GlobalKey boundary,
  bool attach = true,
}) async {
  late WidgetRef captured;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [imageGalleryProvider.overrideWithValue(gallery)],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) {
            captured = ref;
            // Watched, as the reveal watches it: auto-disposed otherwise.
            ref.watch(saveImageControllerProvider);
            return Center(
              child: RepaintBoundary(
                key: attach ? boundary : null,
                child: const ColoredBox(
                  color: Color(0xFF336699),
                  child: SizedBox(width: 40, height: 30),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  return captured;
}

void main() {
  testWidgets('saves what is on screen, as a PNG, under the name asked', (
    tester,
  ) async {
    final gallery = _FakeGallery();
    final boundary = GlobalKey();
    final ref = await _pump(tester, gallery: gallery, boundary: boundary);

    final result = await tester.runAsync(
      () => ref
          .read(saveImageControllerProvider.notifier)
          .save(boundary, name: 'sanctum-palm-test'),
    );

    expect(result, isA<Ok<void>>());
    expect(gallery.name, 'sanctum-palm-test');
    // The PNG signature: the gallery is handed an encoded image, not raw
    // pixels it would have to guess the shape of.
    expect(gallery.saved!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });

  testWidgets('passes a gallery refusal back rather than swallowing it', (
    tester,
  ) async {
    // A refused photos permission is the one failure a user can fix, so
    // its message has to reach the screen.
    final gallery = _FakeGallery()
      ..answer = const Err(UnexpectedFailure('Photos access is off'));
    final boundary = GlobalKey();
    final ref = await _pump(tester, gallery: gallery, boundary: boundary);

    final result = await tester.runAsync(
      () => ref
          .read(saveImageControllerProvider.notifier)
          .save(boundary, name: 'sanctum-palm-test'),
    );

    expect(
      switch (result) {
        Err(:final failure) => failure.message,
        _ => '',
      },
      'Photos access is off',
    );
  });

  testWidgets('fails cleanly when there is nothing painted to capture', (
    tester,
  ) async {
    final gallery = _FakeGallery();
    final boundary = GlobalKey();
    final ref = await _pump(
      tester,
      gallery: gallery,
      boundary: boundary,
      attach: false,
    );

    final result = await tester.runAsync(
      () => ref
          .read(saveImageControllerProvider.notifier)
          .save(boundary, name: 'sanctum-palm-test'),
    );

    expect(result, isA<Err<void>>());
    expect(gallery.saved, isNull);
  });
}
