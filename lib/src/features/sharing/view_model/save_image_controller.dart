import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/features/sharing/view_model/boundary_capture.dart';

part 'save_image_controller.g.dart';

/// Saves a captured widget to the photo library.
///
/// Beside `ShareController`, and for the same reason it lives outside the
/// screens that use it: the reveal is what people keep, and a save path
/// that differed between two screens would be a bug nobody files.
///
/// Callers must watch this provider for as long as a save can be in
/// flight. It is auto-disposed, and reading it only when a button is
/// tapped creates it, starts the capture, and lets it be torn down before
/// the capture returns.
@riverpod
class SaveImageController extends _$SaveImageController {
  /// Four times the screen's density, not three. A shared image is looked
  /// at once in a feed; a saved one is zoomed into later, and the lines
  /// are drawn a few pixels wide.
  static const double pixelRatio = 4;

  @override
  FutureOr<void> build() {}

  /// Captures [boundaryKey] and saves it as [name].
  Future<Result<void>> save(
    GlobalKey boundaryKey, {
    required String name,
  }) async {
    // Read before the first await, while the provider is certainly alive.
    final gallery = ref.read(imageGalleryProvider);
    state = const AsyncLoading();

    final captured = await Result.guard(
      () => captureBoundaryPng(boundaryKey, pixelRatio: pixelRatio),
      onError: (error, stackTrace) => UnexpectedFailure(
        'Could not capture the image',
        cause: error,
        stackTrace: stackTrace,
      ),
    );

    final result = switch (captured) {
      Ok(value: final png) => await gallery.save(png, name: name),
      Err(:final failure) => Err<void>(failure),
    };

    if (ref.mounted) {
      state = switch (result) {
        Ok() => const AsyncData(null),
        Err(:final failure) => AsyncError(failure, StackTrace.current),
      };
    }
    return result;
  }
}
