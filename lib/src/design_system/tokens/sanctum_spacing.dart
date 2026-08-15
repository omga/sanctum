/// The spacing scale.
///
/// Every gap, pad and inset in the app comes from this list. A fixed
/// scale is what makes unrelated screens feel like one product — ad-hoc
/// values (13, 18, 22) are the single most common reason an app looks
/// "almost right" without anyone being able to say why.
///
/// Based on a 4pt grid, growing roughly geometrically so adjacent steps
/// are visibly different.
abstract final class SanctumSpacing {
  /// 2pt — hairline nudges only.
  static const double xxs = 2;

  /// 4pt — icon-to-label.
  static const double xs = 4;

  /// 8pt — tight internal padding.
  static const double sm = 8;

  /// 12pt — default internal padding.
  static const double md = 12;

  /// 16pt — standard screen gutter.
  static const double lg = 16;

  /// 24pt — separation between groups.
  static const double xl = 24;

  /// 32pt — section breaks.
  static const double xxl = 32;

  /// 48pt — major vertical rhythm.
  static const double xxxl = 48;

  /// 64pt — hero breathing room.
  static const double huge = 64;

  /// The horizontal inset used by essentially every screen.
  static const double screenGutter = lg;
}
