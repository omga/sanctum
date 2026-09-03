import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/copy_book.dart';
import 'package:sanctum/src/domain/services/compatibility_composer.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/match_computing.dart';

import '../support/copy.dart';
import '../support/harness.dart';

final CopyBook _copy = loadEnglishCopy();

CompatibilityMatch _match() => CompatibilityComposer.compose(
  you: MatchPerson(name: 'Andrew', birthDate: DateTime(1996, 6, 15)),
  them: MatchPerson(name: 'Taylor Swift', birthDate: DateTime(1989, 12, 13)),
  now: DateTime(2026, 8, 16),
  copy: _copy,
);

void main() {
  testWidgets('walks every caption once, in order, then finishes', (
    tester,
  ) async {
    var done = 0;
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: MatchComputing(match: _match(), onDone: () => done++),
        ),
      ),
    );

    // Resolved through the pumped tree, since the captions are
    // localised and only exist against a context.
    final captions = MatchComputing.stepsFor(
      tester.element(find.byType(MatchComputing)),
    );

    for (final caption in captions) {
      expect(
        find.text(caption),
        findsOneWidget,
        reason: '$caption never appeared',
      );
      await tester.pump(MatchComputing.stepDuration);
      await tester.pump(const Duration(milliseconds: 400)); // cross-fade
    }

    expect(done, 1, reason: 'onDone must fire exactly once');

    // The orbit repeats forever; without disposing it the test binding
    // reports a pending timer.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('does not report done before the last caption', (tester) async {
    var done = 0;
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: MatchComputing(match: _match(), onDone: () => done++),
        ),
      ),
    );

    await tester.pump(MatchComputing.stepDuration * 2);
    expect(done, 0, reason: 'the reveal opened early');

    await tester.pump(MatchComputing.total);
    expect(done, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
