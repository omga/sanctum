import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/services/compatibility_composer.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/carousel/match_carousel_slides.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/carousel/story_slide.dart';

/// Gemini and Sagittarius — an opposition, so the split is lopsided and
/// the bar has two visibly different ends.
CompatibilityMatch _match() => CompatibilityComposer.compose(
  you: MatchPerson(name: 'Andrew', birthDate: DateTime(1996, 6, 15)),
  them: MatchPerson(name: 'Taylor Swift', birthDate: DateTime(1989, 12, 13)),
  now: DateTime(2026, 8, 16),
);

Future<void> _pumpSlide(WidgetTester tester, int index) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: SanctumTheme.nocturne(),
      home: Scaffold(
        body: Center(child: MatchCarousel.slidesFor(_match())[index]),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every slide lays out without overflowing 9:16', (
    tester,
  ) async {
    for (var index = 0; index < MatchCarousel.slideCount; index++) {
      await _pumpSlide(tester, index);

      expect(
        tester.takeException(),
        isNull,
        reason: 'slide $index overflowed',
      );
      expect(tester.getSize(find.byType(StorySlide)).height,
          StorySlide.height);
    }
  });

  testWidgets('the split bar actually paints', (tester) async {
    // It once did not. A Row centres its children by default, which
    // leaves them a loose height, and a childless ColoredBox then takes
    // `constraints.smallest` — so the bar reserved its 10pt of layout
    // and drew nothing at all. The tree was correct and the pixels were
    // empty, so only a size assertion catches it.
    await _pumpSlide(tester, 2);

    final ends = find.descendant(
      of: find.byType(StorySlide),
      matching: find.byType(ColoredBox),
    );

    expect(ends, findsNWidgets(2));
    for (final end in tester.widgetList<ColoredBox>(ends)) {
      final size = tester.getSize(find.byWidget(end));
      expect(size.height, greaterThan(0), reason: 'the bar is invisible');
      expect(size.width, greaterThan(0));
    }
  });

  testWidgets('the cover shows both names in full', (tester) async {
    // An ellipsized name is a blemish on the result screen and a
    // permanent one in a stranger's feed.
    await _pumpSlide(tester, 0);

    expect(find.text('Andrew'), findsOneWidget);
    expect(find.text('Taylor Swift'), findsOneWidget);
  });
}
