import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:meta/meta.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/services/gallery/image_gallery.dart';

/// [ImageGallery] on top of the `gal` package.
///
/// Add-only. It asks to *add* to the photo library and never to read it,
/// which on iOS is a separate, far less alarming permission — the app has
/// no reason to see anybody's photos in order to put one there.
class GalImageGallery implements ImageGallery {
  /// Creates a gallery.
  const GalImageGallery();

  @override
  Future<Result<void>> save(Uint8List png, {required String name}) {
    return Result.guard(
      () async {
        // Asked at the moment of the tap, not up front. A permission
        // prompt the user can connect to what they just did gets a yes;
        // one at launch gets a no.
        if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
          throw const _Refused();
        }
        await Gal.putImageBytes(png, name: name);
      },
      onError: failureFor,
    );
  }

  /// What to tell the user when a save fails.
  ///
  /// A refused permission is named on its own because it is the one
  /// failure the user can fix, and "could not save" in front of a switch
  /// they could flip in Settings is a dead end.
  @visibleForTesting
  static AppFailure failureFor(Object error, StackTrace stackTrace) {
    const settings =
        'Sanctum needs permission to add to your photos. '
        'You can turn it on in Settings.';
    final message = switch (error) {
      _Refused() => settings,
      GalException(type: GalExceptionType.accessDenied) => settings,
      GalException(type: GalExceptionType.notEnoughSpace) =>
        'There is not enough space on this phone to save the image.',
      _ => 'Could not save the image',
    };
    return UnexpectedFailure(message, cause: error, stackTrace: stackTrace);
  }
}

/// The user declined the permission prompt.
class _Refused implements Exception {
  const _Refused();
}
