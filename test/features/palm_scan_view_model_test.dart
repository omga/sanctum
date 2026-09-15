import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_camera.dart';
import 'package:sanctum/src/domain/services/palm_detector.dart';
import 'package:sanctum/src/features/palm/view_model/palm_scan_view_model.dart';

import '../support/palm_fixtures.dart';

final _frame = PalmFrameImage(
  bytes: Uint8List(4),
  width: 720,
  height: 1280,
  format: PalmImageFormat.yuv420,
);

class _FakeCamera implements PalmCamera {
  _FakeCamera({this.startFails = false, this.captureFails = false});

  final bool startFails;
  final bool captureFails;
  // Broadcast, for two reasons. It matches the real thing — frames are
  // dropped, never queued — and `close()` on a single-subscription
  // controller that was never listened to never completes, which hangs
  // the teardown of every test where the camera fails to open.
  final _controller = StreamController<PalmFrameImage>.broadcast();
  bool stopped = false;

  @override
  Stream<PalmFrameImage> get frames => _controller.stream;

  @override
  Future<Result<void>> start() async =>
      startFails ? const Err(UnexpectedFailure('no camera')) : const Ok(null);

  @override
  Future<Result<PalmFrameImage>> capture() async => captureFails
      ? const Err(UnexpectedFailure('shutter failed'))
      : Ok(_frame);

  @override
  Future<void> stop() async => stopped = true;

  void emit() => _controller.add(_frame);

  Future<void> dispose() => _controller.close();
}

class _FakeDetector implements PalmDetector {
  _FakeDetector(this.answer, {this.takes = Duration.zero});

  /// Called once per frame; returns whatever the test wants next.
  HandLandmarks? Function(int call) answer;

  /// How long inference takes.
  ///
  /// Zero for most tests. It matters for exactly one: a detector that
  /// returns instantly never has frames to drop, because the microtask
  /// queue drains between stream deliveries. Dropping only happens when
  /// inference is slower than the frame rate — which on a real device
  /// it always is.
  final Duration takes;

  int calls = 0;

  @override
  Future<HandLandmarks?> detect(PalmFrameImage image) async {
    final result = answer(calls);
    calls++;
    if (takes > Duration.zero) await Future<void>.delayed(takes);
    return result;
  }

  @override
  Future<void> dispose() async {}
}

ProviderContainer _containerWith(
  _FakeCamera camera,
  _FakeDetector detector, {
  Duration interval = Duration.zero,
  void Function()? onDetectorBuilt,
}) {
  final container = ProviderContainer(
    overrides: [
      palmCameraProvider.overrideWithValue(camera),
      if (onDetectorBuilt == null)
        palmDetectorProvider.overrideWithValue(detector)
      else
        palmDetectorProvider.overrideWith((ref) {
          onDetectorBuilt();
          return detector;
        }),
      // The throttle is real behaviour with its own test; every other
      // test here would otherwise have to sleep through it.
      palmInferenceIntervalProvider.overrideWithValue(interval),
    ],
  );
  addTearDown(container.dispose);
  container.listen(palmScanViewModelProvider, (_, _) {});
  return container;
}

/// Emits [count] frames, letting the detector finish between each.
///
/// One at a time on purpose. The view model drops frames that arrive
/// while it is still working on the last, so a burst would exercise the
/// dropping rather than the counting — which is a different test.
Future<void> _feed(_FakeCamera camera, int count) async {
  for (var i = 0; i < count; i++) {
    camera.emit();
    await pumpEventQueue();
  }
}

void main() {
  test('a camera that will not open fails the scan', () async {
    final camera = _FakeCamera(startFails: true);
    final container = _containerWith(camera, _FakeDetector((_) => null));
    addTearDown(camera.dispose);

    await container.read(palmScanViewModelProvider.notifier).start();

    final state = container.read(palmScanViewModelProvider);
    expect(state.stage, PalmScanStage.failed);
    expect(state.failure, isNotNull);
  });

  test('an empty frame says so and fires nothing', () async {
    final camera = _FakeCamera();
    final container = _containerWith(camera, _FakeDetector((_) => null));
    addTearDown(camera.dispose);

    await container.read(palmScanViewModelProvider.notifier).start();
    await _feed(camera, 5);

    final state = container.read(palmScanViewModelProvider);
    expect(state.stage, PalmScanStage.aligning);
    expect(state.readiness, PalmReadiness.noHand);
    expect(state.steadyFrames, 0);
    expect(state.holdProgress, 0);
  });

  test('a hand held still fires the shutter by itself', () async {
    final camera = _FakeCamera();
    final container = _containerWith(
      camera,
      _FakeDetector((_) => goodHand()),
    );
    addTearDown(camera.dispose);

    await container.read(palmScanViewModelProvider.notifier).start();
    await _feed(camera, PalmScanViewModel.steadyFramesRequired);

    final state = container.read(palmScanViewModelProvider);
    expect(state.stage, PalmScanStage.revealed);
    expect(state.reading, isNotNull);
    expect(state.reading!.claimed, containsAll(PalmLine.principal));
    expect(camera.stopped, isTrue);
  });

  test('holding is a run of frames, not an average over them', () async {
    // One bad frame resets the count. Decaying instead would let a hand
    // that wobbles through the whole attempt eventually trip the
    // shutter, and the still would be the blurred one.
    final camera = _FakeCamera();
    final container = _containerWith(
      camera,
      // Every third frame loses the hand.
      _FakeDetector((call) => call % 3 == 2 ? null : goodHand()),
    );
    addTearDown(camera.dispose);

    await container.read(palmScanViewModelProvider.notifier).start();
    await _feed(camera, 12);

    final state = container.read(palmScanViewModelProvider);
    expect(state.stage, PalmScanStage.aligning);
    expect(
      state.steadyFrames,
      lessThan(PalmScanViewModel.steadyFramesRequired),
    );
  });

  test('reports what is wrong while it waits', () async {
    final camera = _FakeCamera();
    final container = _containerWith(
      camera,
      _FakeDetector((_) => handAt(pose(mirror: true))),
    );
    addTearDown(camera.dispose);

    await container.read(palmScanViewModelProvider.notifier).start();
    await _feed(camera, 3);

    final state = container.read(palmScanViewModelProvider);
    expect(state.readiness, PalmReadiness.backOfHand);
    expect(state.stage, PalmScanStage.aligning);
  });

  test('outlines a hand it is not ready to capture', () async {
    // A hand that is merely too far away still has a pose, and the
    // viewfinder draws it while the copy asks for more.
    final camera = _FakeCamera();
    final container = _containerWith(
      camera,
      _FakeDetector((_) => handAt(pose(scale: 0.3))),
    );
    addTearDown(camera.dispose);

    await container.read(palmScanViewModelProvider.notifier).start();
    await _feed(camera, 2);

    final state = container.read(palmScanViewModelProvider);
    expect(state.readiness, PalmReadiness.tooSmall);
    expect(state.preview, isNotNull);
  });

  test('a shutter that fails says so rather than half-revealing', () async {
    final camera = _FakeCamera(captureFails: true);
    final container = _containerWith(
      camera,
      _FakeDetector((_) => goodHand()),
    );
    addTearDown(camera.dispose);

    await container.read(palmScanViewModelProvider.notifier).start();
    await _feed(camera, PalmScanViewModel.steadyFramesRequired);

    final state = container.read(palmScanViewModelProvider);
    expect(state.stage, PalmScanStage.failed);
    expect(state.reading, isNull);
  });

  test('a hand that leaves between the hold and the still fails', () async {
    // The still is detected a second time, and it can disagree with the
    // preview. Better to ask for a retake than to draw lines from
    // landmarks that describe a different moment.
    final camera = _FakeCamera();
    const required = PalmScanViewModel.steadyFramesRequired;
    final container = _containerWith(
      camera,
      _FakeDetector((call) => call < required ? goodHand() : null),
    );
    addTearDown(camera.dispose);

    await container.read(palmScanViewModelProvider.notifier).start();
    await _feed(camera, required);

    final state = container.read(palmScanViewModelProvider);
    expect(state.stage, PalmScanStage.failed);
    expect(state.failure, isNotNull);
  });

  test('drops frames that arrive while it is still reading the last', () async {
    // The real condition: inference is slower than the camera. Queueing
    // instead of dropping would turn the viewfinder into a recording of
    // the recent past, and the hold counter would be counting frames the
    // user had already moved on from.
    final camera = _FakeCamera();
    final detector = _FakeDetector(
      (_) => null,
      takes: const Duration(milliseconds: 40),
    );
    final container = _containerWith(camera, detector);
    addTearDown(camera.dispose);

    await container.read(palmScanViewModelProvider.notifier).start();
    for (var i = 0; i < 20; i++) {
      camera.emit();
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    await pumpEventQueue();

    expect(detector.calls, lessThan(6));
    expect(detector.calls, greaterThan(0));
  });

  test('builds the detector once, not once a frame', () async {
    // The bug that killed a Pixel 6 in under a minute.
    //
    // `palmDetectorProvider` is auto-disposed. Reading it per frame
    // created it, returned it and disposed it again — so every frame
    // built a fresh detector, which loaded both TFLite models and
    // re-applied the XNNPack delegate. Hundreds of megabytes through the
    // large-object space and an out-of-memory kill.
    //
    // Nothing about the app's behaviour changed when it was fixed, which
    // is why the assertion is on the construction count rather than on
    // anything visible.
    var built = 0;
    final camera = _FakeCamera();
    final detector = _FakeDetector((_) => goodHand());
    addTearDown(camera.dispose);

    final container = _containerWith(
      camera,
      detector,
      onDetectorBuilt: () => built++,
    );

    await container.read(palmScanViewModelProvider.notifier).start();
    await _feed(camera, 5);

    expect(built, 1);
  });

  test('leaves a gap between inferences', () async {
    // Without it the detector runs as fast as the phone will let it,
    // pegging a core to track a hand that is barely moving.
    final camera = _FakeCamera();
    final detector = _FakeDetector((_) => null);
    addTearDown(camera.dispose);

    final container = _containerWith(
      camera,
      detector,
      interval: const Duration(seconds: 30),
    );

    await container.read(palmScanViewModelProvider.notifier).start();
    await _feed(camera, 6);

    expect(detector.calls, 1);
  });

  test('a retake throws the reading away and looks again', () async {
    final camera = _FakeCamera();
    final container = _containerWith(
      camera,
      _FakeDetector((_) => goodHand()),
    );
    addTearDown(camera.dispose);

    final model = container.read(palmScanViewModelProvider.notifier);
    await model.start();
    await _feed(camera, PalmScanViewModel.steadyFramesRequired);
    expect(container.read(palmScanViewModelProvider).reading, isNotNull);

    await model.retake();

    final state = container.read(palmScanViewModelProvider);
    expect(state.stage, PalmScanStage.aligning);
    expect(state.reading, isNull);
    expect(state.steadyFrames, 0);
  });

  test('stopping releases the camera', () async {
    final camera = _FakeCamera();
    final container = _containerWith(camera, _FakeDetector((_) => null));
    addTearDown(camera.dispose);

    final model = container.read(palmScanViewModelProvider.notifier);
    await model.start();
    await model.stop();

    expect(camera.stopped, isTrue);
    expect(container.read(palmScanViewModelProvider).stage, PalmScanStage.idle);
  });
}
