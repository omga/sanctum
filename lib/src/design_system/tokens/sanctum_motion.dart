import 'package:flutter/animation.dart';

/// Durations and curves.
///
/// ## The rule Sanctum animates by
///
/// Nothing snaps. In a meditation app, motion *is* tone of voice: a 120ms
/// linear slide feels like a banking app, and no amount of gradient work
/// recovers from it. Sanctum's motion is slow, eased, and slightly
/// overlapping.
///
/// Durations are deliberately few. If a value here does not fit, the
/// interaction is usually wrong — not the scale.
abstract final class SanctumMotion {
  /// 120ms — pressed states and colour shifts only.
  static const Duration instant = Duration(milliseconds: 120);

  /// 240ms — small element enter/exit.
  static const Duration quick = Duration(milliseconds: 240);

  /// 420ms — the default. Page content, cards, sheets.
  static const Duration calm = Duration(milliseconds: 420);

  /// 700ms — deliberate, ceremonial reveals (the oracle flip).
  static const Duration ritual = Duration(milliseconds: 700);

  /// 1200ms — breathing and pulse cycles.
  static const Duration breath = Duration(milliseconds: 1200);

  /// 32s — one full drift of the aurora. Slow enough to feel alive
  /// without ever pulling the eye away from content.
  static const Duration auroraDrift = Duration(seconds: 32);

  /// Default easing: gentle out, no overshoot.
  static const Curve ease = Curves.easeOutCubic;

  /// Entering elements. A touch of deceleration reads as "arriving".
  static const Curve enter = Curves.easeOutQuart;

  /// Leaving elements — faster, so exits never feel sluggish.
  static const Curve exit = Curves.easeInQuad;

  /// Symmetric easing for looping animations (breath, glow, drift).
  static const Curve loop = Curves.easeInOutSine;

  /// The one place a little bounce is allowed: confirmations.
  static const Curve celebrate = Curves.easeOutBack;
}
