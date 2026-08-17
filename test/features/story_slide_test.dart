import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/carousel/story_slide.dart';

/// Pumps [child] inside the app's theme at a viewport big enough that a
/// full slide is laid out without the test surface clipping it.
Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: SanctumTheme.nocturne(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a slide is exactly 9:16', (tester) async {
    await _pump(tester, const StorySlide(child: SizedBox()));

    final size = tester.getSize(find.byType(StorySlide));

    expect(size.width, StorySlide.width);
    expect(size.height, StorySlide.height);
    expect(size.width / size.height, closeTo(9 / 16, 0.001));
  });

  testWidgets('captures at 1440x2560 from a viewport too small for it', (
    tester,
  ) async {
    // This is the assertion that matters, and it has to be made in a
    // *cramped* parent. A `SizedBox` is clamped by its constraints, so
    // a slide previewed inside a 380pt-tall viewport lays out 380pt
    // tall — and the capture faithfully writes that to disk. The first
    // version of this screen shipped 1080x1689 files that looked
    // perfect on screen, because the display was scaled separately from
    // the layout. Giving this test room to breathe is what let it
    // through, so it is deliberately given none.
    final key = GlobalKey();
    await _pump(
      tester,
      SizedBox(
        height: 380,
        width: 300,
        child: FittedBox(
          child: RepaintBoundary(
            key: key,
            child: const StorySlide(child: SizedBox()),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(StorySlide)),
      const Size(StorySlide.width, StorySlide.height),
      reason: 'the slide was clamped by its parent',
    );

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(
      pixelRatio: StorySlide.captureScale,
    );
    addTearDown(image.dispose);

    expect(image.width, 1440);
    expect(image.height, 2560);
  });

  testWidgets('keeps content clear of every TikTok overlay', (tester) async {
    // These three fractions were measured off a real post on a Pixel 6,
    // not taken from a spec sheet, and the first version of this screen
    // was short on two of them. They are the reason the gutters are the
    // size they are, so they are asserted rather than trusted.
    const captionTop = 0.832; // "Miami" chip, username, sound row
    const railLeft = 0.850; // avatar, like, comment, bookmark
    const chromeTop = 0.021; // back arrow and search

    final key = GlobalKey();
    await _pump(
      tester,
      StorySlide(child: SizedBox(key: key, width: 10, height: 10)),
    );

    final slide = tester.getRect(find.byType(StorySlide));
    final content = tester.getRect(find.byKey(key));

    expect(
      (content.bottom - slide.top) / slide.height,
      lessThanOrEqualTo(captionTop),
      reason: 'content runs under the caption block',
    );
    expect(
      (content.right - slide.left) / slide.width,
      lessThanOrEqualTo(railLeft),
      reason: 'content runs under the action rail',
    );
    expect(
      (content.top - slide.top) / slide.height,
      greaterThanOrEqualTo(chromeTop),
      reason: 'content runs under the back arrow',
    );
  });

  testWidgets('side margins are symmetric', (tester) async {
    // Deliberate: only the right is covered on TikTok, but the same file
    // goes to Instagram Stories where the overlays sit elsewhere, and an
    // off-centre composition reads as a mistake.
    final key = GlobalKey();
    await _pump(
      tester,
      StorySlide(child: SizedBox(key: key, width: 10, height: 10)),
    );

    final slide = tester.getRect(find.byType(StorySlide));
    final content = tester.getRect(find.byKey(key));

    expect(
      content.center.dx - slide.center.dx,
      closeTo(0, 0.01),
      reason: 'the composition is off centre',
    );
  });
}
