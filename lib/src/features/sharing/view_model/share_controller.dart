import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:share_plus/share_plus.dart';

part 'share_controller.g.dart';

/// Puts a captured card, or an invite, into the system share sheet.
///
/// Shared by the payoff screen and the compatibility flow. It lives
/// outside both because the *only* growth surface this product has is
/// people posting its output, and a share path that quietly differs
/// between two screens is a growth bug nobody will ever file.
@riverpod
class ShareController extends _$ShareController {
  @override
  FutureOr<void> build() {}

  /// Captures the widget behind [boundaryKey] and shares it.
  ///
  /// Rendered at 3x so it survives being viewed full-screen in a story.
  /// A 1x capture looks soft next to everything else in a feed, and soft
  /// reads as amateur — which defeats the point of the channel.
  Future<void> share(GlobalKey boundaryKey, {String? text}) async {
    state = const AsyncLoading();

    final result = await Result.guard(
      () async {
        final object = boundaryKey.currentContext?.findRenderObject();
        if (object == null || object is! RenderRepaintBoundary) {
          throw StateError('share target is not a RepaintBoundary');
        }

        final image = await object.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) throw StateError('could not encode the card');

        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/sanctum_reading.png');
        await file.writeAsBytes(bytes.buffer.asUint8List());

        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: text),
        );
      },
      onError: (error, stackTrace) => UnexpectedFailure(
        'Could not share your reading',
        cause: error,
        stackTrace: stackTrace,
      ),
    );

    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }

  /// Shares [text] with no attachment, and reports whether the user
  /// actually chose somewhere to send it.
  ///
  /// The boolean is the whole reason this is separate from [share]: the
  /// compatibility flow trades a reading for an invite, so it needs to
  /// know the sheet was completed rather than dismissed.
  ///
  /// It is worth being honest about what this can and cannot know. The
  /// platform tells us an app was picked; nothing tells us a message was
  /// really sent, and nothing ever will. Picking a target is the
  /// strongest signal available, and the failure mode — someone opens
  /// Messages, backs out, and keeps the reading — is a far better one
  /// than withholding it from a user who did share.
  Future<bool> shareInvite(String text) async {
    state = const AsyncLoading();

    final result = await Result.guard(
      () async {
        final outcome = await SharePlus.instance.share(
          ShareParams(text: text),
        );
        return outcome.status == ShareResultStatus.success;
      },
      onError: (error, stackTrace) => UnexpectedFailure(
        'Could not open the share sheet',
        cause: error,
        stackTrace: stackTrace,
      ),
    );

    return switch (result) {
      Ok(:final value) => () {
        state = const AsyncData(null);
        return value;
      }(),
      Err(:final failure) => () {
        state = AsyncError(failure, StackTrace.current);
        return false;
      }(),
    };
  }

  /// Captures several boundaries in order and shares them as one post.
  ///
  /// [beforeEach] is awaited before frame `index` is read. The slides
  /// live in a `PageView`, and only a page that is actually on screen
  /// has painted a layer for [RenderRepaintBoundary.toImage] to read —
  /// so the caller uses this hook to bring each page forward, while
  /// every touch of the file system and the share sheet stays here.
  ///
  /// Files are numbered because the receiving app is handed a list and
  /// orders a photo post by file name. An unnumbered set arrives as a
  /// carousel in whatever order the OS chose, and the cover is the one
  /// slide that cannot afford to be wrong.
  ///
  /// Each [ui.Image] is disposed as soon as it is encoded. Four frames
  /// at 1080x1920 are about 33 MB of image memory held at once, which is
  /// a real risk on the low-end Android this is aimed at.
  Future<void> shareAll(
    List<GlobalKey> keys, {
    required double pixelRatio,
    String? text,
    Future<void> Function(int index)? beforeEach,
  }) async {
    state = const AsyncLoading();

    final result = await Result.guard(
      () async {
        final directory = await getTemporaryDirectory();
        final files = <XFile>[];

        for (final (index, key) in keys.indexed) {
          await beforeEach?.call(index);

          final object = key.currentContext?.findRenderObject();
          if (object == null || object is! RenderRepaintBoundary) {
            throw StateError('slide $index is not a RepaintBoundary');
          }

          final image = await object.toImage(pixelRatio: pixelRatio);
          final ByteData? bytes;
          try {
            bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          } finally {
            image.dispose();
          }
          if (bytes == null) throw StateError('could not encode a slide');

          final file = File('${directory.path}/sanctum_slide_$index.png');
          await file.writeAsBytes(bytes.buffer.asUint8List());
          files.add(XFile(file.path));
        }

        await SharePlus.instance.share(
          ShareParams(files: files, text: text),
        );
      },
      onError: (error, stackTrace) => UnexpectedFailure(
        'Could not build your post',
        cause: error,
        stackTrace: stackTrace,
      ),
    );

    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}
