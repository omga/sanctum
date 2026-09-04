import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';

import '../support/harness.dart';

/// Pumps a button whose enabled state the test controls.
Future<void> _pump(WidgetTester tester, ValueNotifier<bool> enabled) async {
  await tester.pumpWidget(
    testApp(
      Scaffold(
        body: ValueListenableBuilder<bool>(
          valueListenable: enabled,
          builder: (context, value, _) => SanctumButton(
            label: 'Unlock',
            onPressed: value ? () {} : null,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('survives being disabled and enabled again', (tester) async {
    // The sheen controller is disposed when the button is disabled and
    // rebuilt when it is enabled, so the State legitimately creates more
    // than one ticker over its life. Under
    // `SingleTickerProviderStateMixin` the second one throws — which is
    // what the report's buy button hit the moment somebody cancelled a
    // purchase, the one path least likely to be tried by hand.
    final enabled = ValueNotifier<bool>(true);
    addTearDown(enabled.dispose);

    await _pump(tester, enabled);
    expect(tester.takeException(), isNull);

    enabled.value = false;
    await tester.pump();
    expect(tester.takeException(), isNull);

    enabled.value = true;
    await tester.pump();
    expect(tester.takeException(), isNull);

    // And again, because "works the second time" is not the claim.
    enabled
      ..value = false
      ..value = true;
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a disabled button does not fire', (tester) async {
    final enabled = ValueNotifier<bool>(false);
    addTearDown(enabled.dispose);

    await _pump(tester, enabled);
    await tester.tap(find.text('Unlock'), warnIfMissed: false);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
