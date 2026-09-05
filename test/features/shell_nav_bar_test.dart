import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/features/shell/sanctum_shell.dart';
import 'package:sanctum/src/l10n/sanctum_locales.dart';

import '../support/fonts.dart';
import '../support/harness.dart';

/// The narrowest phone the app supports, in physical pixels.
const _narrowest = Size(1125, 2436);

void main() {
  // The real Inter, or this measures the test font's square boxes and
  // reports on a layout nobody will ever see.
  setUpAll(loadSanctumFonts);

  group('the nav bar fits', () {
    // It did not. On a 375pt phone the five pills plus the selected
    // label overflowed the Row by 2.7 pixels, and `label_budget_test`
    // passed throughout — it counts characters, and what overflows is
    // width. This measures.
    for (final locale in SanctumLocales.supported) {
      for (var index = 0; index < 5; index++) {
        testWidgets('${locale.languageCode}, tab $index', (tester) async {
          tester.view.physicalSize = _narrowest;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            testApp(
              Scaffold(
                // Where the shell puts it, so the width it is given is
                // the width it actually gets.
                bottomNavigationBar: SanctumNavBar(
                  currentIndex: index,
                  onTap: (_) {},
                ),
              ),
              locale: locale,
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
