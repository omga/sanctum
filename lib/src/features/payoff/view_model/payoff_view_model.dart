import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/data_providers.dart';
import 'package:sanctum/src/domain/models/quiz.dart';
import 'package:sanctum/src/domain/models/reading.dart';
import 'package:sanctum/src/domain/services/reading_composer.dart';
import 'package:share_plus/share_plus.dart';

part 'payoff_view_model.g.dart';

/// The reading built from the quiz answers.
@riverpod
Future<Reading> reading(Ref ref) async {
  final loaded = await ref.watch(quizRepositoryProvider).load();
  return ReadingComposer.compose(loaded.getOrElse(const QuizAnswers()));
}

/// Turns the card into an image and hands it to the share sheet.
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
}
