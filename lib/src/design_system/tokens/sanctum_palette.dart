import 'dart:ui';

/// Raw colour primitives — the paint, not the meaning.
///
/// ## Primitive vs semantic tokens
///
/// These are *primitives*: named pigments with no opinion about where
/// they are used. Widgets must never reference them directly. They are
/// consumed once, by `SanctumColors`, which maps them onto semantic roles
/// like "background" or "textSecondary".
///
/// That indirection is what makes a redesign tractable: changing what
/// `orchid` means is a one-line edit here, and changing *which* pigment
/// plays the accent role is a one-line edit there — neither requires
/// touching a single widget.
abstract final class SanctumPalette {
  // ── Grounds: the night sky, darkest to lightest ──────────────────
  /// Deepest ground. Behind everything.
  static const Color voidBlack = Color(0xFF07040F);

  /// Primary app background.
  static const Color abyss = Color(0xFF0B0616);

  /// Background at the far end of the aurora gradient.
  static const Color midnight = Color(0xFF150B26);

  /// Elevated background — sheets, bottom bars.
  static const Color nebula = Color(0xFF1A0F2E);

  /// Raised surface — cards sitting above the nebula.
  static const Color veil = Color(0xFF241640);

  // ── Aurora: the signature glow ───────────────────────────────────
  /// Primary aurora hue.
  static const Color violet = Color(0xFF7C5CFF);

  /// Secondary aurora hue.
  static const Color orchid = Color(0xFFC77DFF);

  /// Warm edge of the aurora.
  static const Color rose = Color(0xFFFF9ECD);

  /// Cool counterpoint, used sparingly.
  static const Color azure = Color(0xFF5CC8FF);

  // ── Metal: restraint is what makes gold read as expensive ────────
  /// Accent metal for dividers, rules and small marks.
  static const Color gold = Color(0xFFE8C88A);

  /// Recessed gold, for borders that should not compete.
  static const Color goldDeep = Color(0xFFA8905F);

  // ── Ink ──────────────────────────────────────────────────────────
  /// Highest-contrast text.
  static const Color moonlight = Color(0xFFF4F1FA);

  /// Supporting text.
  static const Color mist = Color(0xFFC3B9D6);

  /// De-emphasised text, captions, disabled states.
  static const Color whisper = Color(0xFF8B819F);

  // ── Signal ───────────────────────────────────────────────────────
  /// Positive state.
  static const Color jade = Color(0xFF7FD8A4);

  /// Cautionary state.
  static const Color amber = Color(0xFFF0C46A);

  /// Destructive or failed state.
  static const Color ember = Color(0xFFFF8A8A);

  // ── Neutrals used for glass ──────────────────────────────────────
  /// Pure white, only ever used at low opacity for glass and glow.
  static const Color white = Color(0xFFFFFFFF);
}
