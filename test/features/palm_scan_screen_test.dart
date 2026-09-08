import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/core/result/app_failure.dart';
import 'package:sanctum/src/core/result/result.dart';
import 'package:sanctum/src/domain/models/palm.dart';
import 'package:sanctum/src/domain/services/palm_camera.dart';
import 'package:sanctum/src/domain/services/palm_detector.dart';
import 'package:sanctum/src/features/palm/view/palm_scan_screen.dart';
import 'package:sanctum/src/features/palm/view_model/palm_scan_view_model.dart';
import 'package:sanctum/src/l10n/generated/app_localizations.dart';

import '../support/harness.dart';
import '../support/palm_fixtures.dart';

final _frame = PalmFrameImage(
  bytes: Uint8List(4),
  width: 720,
  height: 1280,
  format: PalmImageFormat.nv21,
);

class _FakeCamera implements PalmCamera {
  _FakeCamera({this.startFails = false});

  final bool startFails;
  final _controller = StreamController<PalmFrameImage>.broadcast();

  @override
  Stream<PalmFrameImage> get frames => _controller.stream;

  @override
  Future<Result<void>> start() async =>
      startFails ? const Err(UnexpectedFailure('no camera')) : const Ok(null);

  @override
  Future<Result<PalmFrameImage>> capture() async =>
      const Err(UnexpectedFailure('shutter failed'));

  @override
  Future<void> stop() async {}

  void emit() => _controller.add(_frame);

  Future<void> dispose() => _controller.close();
}

class _FakeDetector implements PalmDetector {
  _FakeDetector(this.answer);

  final HandLandmarks? Function() answer;

  @override
  Future<HandLandmarks?> detect(PalmFrameImage image) async => answer();

  @override
  Future<void> dispose() async {}
}

late AppLocalizations _en;

Future<void> _pumpScan(
  WidgetTester tester, {
  required _FakeCamera camera,
  required _FakeDetector detector,
  WidgetBuilder? preview,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        palmCameraProvider.overrideWithValue(camera),
        palmDetectorProvider.overrideWithValue(detector),
        palmPreviewBuilderProvider.overrideWithValue(preview),
      ],
      child: testApp(const PalmScanScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    _en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('says the camera is missing rather than faking one', (
    tester,
  ) async {
    // A viewfinder that looks like it is working and is not is the
    // single most confusing thing this screen could do, so the hole is
    // labelled.
    final camera = _FakeCamera();
    addTearDown(camera.dispose);

    await _pumpScan(
      tester,
      camera: camera,
      detector: _FakeDetector(() => null),
    );

    expect(find.text(_en.palmCameraUnavailable), findsOneWidget);
  });

  testWidgets('shows the preview when there is one', (tester) async {
    final camera = _FakeCamera();
    addTearDown(camera.dispose);

    await _pumpScan(
      tester,
      camera: camera,
      detector: _FakeDetector(() => null),
      preview: (_) => const ColoredBox(
        key: Key('preview'),
        color: Color(0xFF101010),
      ),
    );

    expect(find.byKey(const Key('preview')), findsOneWidget);
    expect(find.text(_en.palmCameraUnavailable), findsNothing);
  });

  testWidgets('asks for a hand before it has one', (tester) async {
    final camera = _FakeCamera();
    addTearDown(camera.dispose);

    await _pumpScan(
      tester,
      camera: camera,
      detector: _FakeDetector(() => null),
    );

    expect(find.text(_en.palmHintNoHand), findsOneWidget);
  });

  testWidgets('names what is wrong, and never the wrong thing', (
    tester,
  ) async {
    // Ordering, on screen this time. Telling somebody to move closer
    // when the real problem is which way their hand faces makes the app
    // look broken: they do as they are told and nothing improves.
    final camera = _FakeCamera();
    addTearDown(camera.dispose);

    await _pumpScan(
      tester,
      camera: camera,
      detector: _FakeDetector(
        () => handAt(pose(scale: 0.2, mirror: true)),
      ),
    );

    camera.emit();
    await tester.pumpAndSettle();

    expect(find.text(_en.palmHintBackOfHand), findsOneWidget);
    expect(find.text(_en.palmHintTooSmall), findsNothing);
  });

  testWidgets('says hold still once the frame is good', (tester) async {
    final camera = _FakeCamera();
    addTearDown(camera.dispose);

    await _pumpScan(
      tester,
      camera: camera,
      detector: _FakeDetector(goodHand),
    );

    camera.emit();
    await tester.pumpAndSettle();

    expect(find.text(_en.palmHintReady), findsOneWidget);
  });

  testWidgets('offers a retake when the camera will not open', (
    tester,
  ) async {
    // The failure branch, reached the shallow way. Driving it through
    // the shutter instead means driving a capture chain several real
    // awaits deep, which `pumpAndSettle` cannot settle and `runAsync`
    // delivers into the wrong zone — and the view model's own test
    // already covers every way a capture can fail.
    final camera = _FakeCamera(startFails: true);
    addTearDown(camera.dispose);

    await _pumpScan(
      tester,
      camera: camera,
      detector: _FakeDetector(goodHand),
    );
    // Pumped, never settled: the failure branch sits on
    // `AuroraBackground`, whose ticker drifts for 32 seconds and starts
    // again. `pumpAndSettle` waits for an idle frame that never comes.
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.palmRetake), findsOneWidget);
    expect(find.text(_en.palmHintNoHand), findsNothing);
  });
}
