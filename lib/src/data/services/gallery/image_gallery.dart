import 'dart:typed_data';

import 'package:sanctum/src/core/result/result.dart';

/// The device's photo library, write-only.
///
/// An interface for the reason every other service here is one: the
/// save flow can then be tested with a gallery that records what it was
/// handed, which no photo library on a test runner will do.
abstract interface class ImageGallery {
  /// Saves [png] to the photo library as [name].
  ///
  /// Only ever called from a tap on Save. Nothing in the palm feature
  /// writes an image anywhere on its own — see `PalmRepository` for why
  /// that absence is the design — and a copy the user chose to keep is
  /// theirs, the same as a copy they chose to share.
  Future<Result<void>> save(Uint8List png, {required String name});
}
