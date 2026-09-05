import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Length budgets for the labels that sit in fixed-width furniture.
///
/// ## Why this is a content test and not a layout test
///
/// The bug that prompted it was visual: five energy labels share one
/// row, each gets about sixty points, and "Виснажена" does not fit — so
/// it wrapped, made its column taller than the other four, and left the
/// bars stepping up and down like a staircase.
///
/// The obvious guard is a widget test that measures the row. That was
/// written, and it passed identically with the bug present and with it
/// fixed: `flutter_test` renders in a fallback font whose metrics have
/// nothing to do with Inter, so nothing wrapped at any width. Loading
/// the real face did not reproduce it either. A layout assertion that
/// cannot fail is worse than none, because it reads like cover.
///
/// So the guard sits where the constraint actually lives — in how long
/// a translator is allowed to make these particular strings. That *is*
/// deterministic, it fails on the exact input that caused the bug, and
/// it is the same rule the ARB descriptions already state in prose.
///
/// Budgets are in characters and deliberately generous: they exist to
/// catch a phrase where a word belongs, not to police good writing.
void main() {
  const locales = ['en', 'uk', 'ru', 'es'];

  /// The tightest slots in the app, and what fits in them.
  const budgets = <String, int>{
    // Five across one row on the narrowest phone.
    'energyDepleted': 12,
    'energyLow': 12,
    'energySteady': 12,
    'energyOpen': 12,
    'energyRadiant': 12,
    // Five in a glass pill now, only one of them labelled at a time.
    // The advisor tab made the row tighter for everybody, which is the
    // cost of the tab and worth stating where the numbers are.
    'navToday': 12,
    'navMatch': 12,
    'navSound': 12,
    'navJournal': 12,
    'navAsk': 12,
    // Axis labels on the hexagon, which has no room to grow.
    'facetSpark': 12,
    'facetVibe': 12,
    'facetTrust': 12,
    'facetDrama': 12,
    'facetDepth': 12,
    'facetFuture': 12,
    // The pill on the exported card.
    'aspectConjunction': 20,
    'aspectSemiSextile': 20,
    'aspectSextile': 20,
    'aspectSquare': 20,
    'aspectTrine': 20,
    'aspectQuincunx': 20,
    'aspectOpposition': 20,
  };

  for (final locale in locales) {
    test('$locale keeps its tight labels inside their budget', () {
      final raw = File('lib/src/l10n/app_$locale.arb').readAsStringSync();
      final arb = jsonDecode(raw) as Map<String, dynamic>;

      final over = <String>[];
      budgets.forEach((key, limit) {
        final value = arb[key] as String?;
        expect(value, isNotNull, reason: '$locale is missing $key');
        if (value!.length > limit) {
          over.add('$key = "$value" (${value.length} > $limit)');
        }
      });

      expect(
        over,
        isEmpty,
        reason: 'too long for their slot:\n${over.join('\n')}',
      );
    });
  }
}
