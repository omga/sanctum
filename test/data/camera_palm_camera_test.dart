import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/data/services/palm/camera_palm_camera.dart';

const _back = CameraDescription(
  name: 'back',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);

const _front = CameraDescription(
  name: 'front',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 270,
);

/// A controller that opens without a device behind it.
class _FakeController extends CameraController {
  _FakeController(CameraDescription description, {this.initialiseThrows})
    : super(description, ResolutionPreset.high, enableAudio: false);

  /// What `initialize` should fail with, if anything.
  final CameraException? initialiseThrows;

  bool streaming = false;
  bool disposed = false;

  @override
  Future<void> initialize() async {
    if (initialiseThrows case final error?) throw error;
  }

  @override
  Future<void> startImageStream(void Function(CameraImage) onAvailable) async =>
      streaming = true;

  @override
  Future<void> stopImageStream() async => streaming = false;

  @override
  Future<void> dispose() async => disposed = true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fails when the phone has no camera', () async {
    final camera = CameraPalmCamera(
      describe: () async => const <CameraDescription>[],
      build: _FakeController.new,
    );
    addTearDown(camera.dispose);

    final result = await camera.start();

    expect(result, isA<Err<void>>());
    expect(camera.controller, isNull);
  });

  test('points a refused permission at Settings', () async {
    // The only failure a user can do something about, so it must not
    // arrive as "Could not open the camera" — that is a dead end in
    // front of a switch they could flip in twenty seconds.
    final camera = CameraPalmCamera(
      describe: () async => const [_back],
      build: (description) => _FakeController(
        description,
        initialiseThrows: CameraException('CameraAccessDenied', 'nope'),
      ),
    );
    addTearDown(camera.dispose);

    final result = await camera.start();

    expect(
      switch (result) {
        Err(:final failure) => failure.message,
        Ok() => '',
      },
      contains('Settings'),
    );
  });

  test('says something useful when access is switched off entirely', () async {
    final camera = CameraPalmCamera(
      describe: () async => const [_back],
      build: (description) => _FakeController(
        description,
        initialiseThrows: CameraException('CameraAccessRestricted', 'nope'),
      ),
    );
    addTearDown(camera.dispose);

    final result = await camera.start();

    expect(
      switch (result) {
        Err(:final failure) => failure.message,
        Ok() => '',
      },
      contains('does not allow'),
    );
  });

  test('takes the back camera when there is a choice', () async {
    // Resolution and mirroring both decide this. A front sensor costs
    // the crease filter detail it never gets back, and a mirrored frame
    // flips handedness and chirality together, which is exactly the case
    // `HandLandmarks.isPalmFacing` cannot detect.
    late CameraDescription chosen;
    final camera = CameraPalmCamera(
      describe: () async => const [_front, _back],
      build: (description) {
        chosen = description;
        return _FakeController(description);
      },
    );
    addTearDown(camera.dispose);

    await camera.start();

    expect(chosen.lensDirection, CameraLensDirection.back);
  });

  test('falls back to whatever lens exists', () async {
    late CameraDescription chosen;
    final camera = CameraPalmCamera(
      describe: () async => const [_front],
      build: (description) {
        chosen = description;
        return _FakeController(description);
      },
    );
    addTearDown(camera.dispose);

    expect(await camera.start(), isA<Ok<void>>());
    expect(chosen.lensDirection, CameraLensDirection.front);
  });

  test('starts the stream once, however often it is asked', () async {
    var built = 0;
    final camera = CameraPalmCamera(
      describe: () async => const [_back],
      build: (description) {
        built++;
        return _FakeController(description);
      },
    );
    addTearDown(camera.dispose);

    await camera.start();
    await camera.start();

    expect(built, 1);
  });

  test('refuses to capture before it is open', () async {
    final camera = CameraPalmCamera(
      describe: () async => const [_back],
      build: _FakeController.new,
    );
    addTearDown(camera.dispose);

    expect(await camera.capture(), isA<Err<dynamic>>());
  });

  test('releases the device on stop', () async {
    late _FakeController controller;
    final camera = CameraPalmCamera(
      describe: () async => const [_back],
      build: (description) => controller = _FakeController(description),
    );

    await camera.start();
    expect(controller.streaming, isTrue);

    await camera.stop();

    expect(controller.streaming, isFalse);
    expect(controller.disposed, isTrue);
    expect(camera.controller, isNull);
  });

  test('tells the preview when a controller appears and goes', () async {
    // The preview has no Riverpod state change to rebuild on — the
    // provider hands out one adapter for the life of the scan — so the
    // notification is the only signal it gets.
    final camera = CameraPalmCamera(
      describe: () async => const [_back],
      build: _FakeController.new,
    );
    addTearDown(camera.dispose);

    var notifications = 0;
    camera.addListener(() => notifications++);

    await camera.start();
    expect(notifications, 1);

    await camera.stop();
    expect(notifications, 2);
  });
}
