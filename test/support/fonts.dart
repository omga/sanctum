import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the app's real fonts into the test binding.
///
/// Without this, `flutter_test` draws every glyph as a square box of the
/// font size, so a line of text measures nothing like the shipped one —
/// far wider for Latin, and wrong in the other direction for the Cyrillic
/// locales. Any test that asserts something *fits* is then measuring the
/// test font and reporting on a layout the user will never see.
///
/// Only the sans is loaded. It is the family every label, button and
/// body line uses; the serif appears in headings, which are the things
/// that wrap rather than overflow. Add it here the day a test needs it.
///
/// `dart:io` rather than `rootBundle`, matching `copy.dart`: the file is
/// read from the repository, which is also what makes the test fail if
/// the shipped font ever changes metrics.
Future<void> loadSanctumFonts() async {
  final bytes = await File('assets/fonts/Inter-Variable.ttf').readAsBytes();
  await (FontLoader(
    'Inter',
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}
