import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gal/gal.dart';
import 'package:sanctum/src/data/services/gallery/gal_image_gallery.dart';

GalException _failure(GalExceptionType type) => GalException(
  type: type,
  platformException: PlatformException(code: type.name),
  stackTrace: StackTrace.empty,
);

void main() {
  test('points a refused permission at Settings', () {
    // The one failure the user can fix, so it must not arrive as "could
    // not save" in front of a switch they could flip in twenty seconds.
    expect(
      GalImageGallery.failureFor(
        _failure(GalExceptionType.accessDenied),
        StackTrace.empty,
      ).message,
      contains('Settings'),
    );
  });

  test('says when the phone is full', () {
    expect(
      GalImageGallery.failureFor(
        _failure(GalExceptionType.notEnoughSpace),
        StackTrace.empty,
      ).message,
      contains('space'),
    );
  });

  test('falls back to a plain message for anything else', () {
    for (final error in [
      _failure(GalExceptionType.unexpected),
      _failure(GalExceptionType.notSupportedFormat),
      StateError('boom'),
    ]) {
      expect(
        GalImageGallery.failureFor(error, StackTrace.empty).message,
        'Could not save the image',
      );
    }
  });
}
