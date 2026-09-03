import 'dart:convert';
import 'dart:io';

import 'package:sanctum/src/domain/models/copy_book.dart';

/// The English reading copy, read straight off disk.
///
/// `dart:io` rather than an asset bundle on purpose. Most of the tests
/// that need this are pure domain tests — they compose a reading and
/// assert a number — and requiring `TestWidgetsFlutterBinding` just to
/// reach `rootBundle` would drag the Flutter test harness into the fast,
/// dependency-free half of the suite for no benefit.
///
/// Reading the real shipped file rather than a fixture is also the
/// point: these tests then fail if a key the composers ask for is
/// missing from the content, which is the failure worth catching.
CopyBook loadEnglishCopy() {
  final raw = File('assets/content/en/copy.json').readAsStringSync();
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return CopyBook({
    for (final entry in decoded.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value! as String,
  });
}
