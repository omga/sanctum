/// Whether the user has agreed that the advisor may send anything.
///
/// Three states rather than a boolean, because *declined* has to be a
/// thing the app remembers. A user who says no and is asked again on
/// the next launch has not been asked twice — they have been nagged,
/// and the answer they gave was not recorded. `advisor.md` §1: consent
/// is a screen, and declining it is a decision that persists and is
/// re-offerable.
///
/// Nothing outside the advisor reads this yet, and the difference
/// between [unasked] and [declined] is currently invisible on screen.
/// It is not decorative: the triggers in `advisor.md` §7 must never
/// nudge somebody who declined, and that is impossible to honour with a
/// boolean that cannot tell "no" from "not yet".
enum AdvisorConsent {
  /// The screen has not been shown, or was shown and dismissed without
  /// an answer.
  unasked,

  /// The user read the disclosure and agreed.
  granted,

  /// The user read the disclosure and said no.
  declined;

  /// Whether a request may leave the device.
  ///
  /// The only question any caller should be asking. Written as a getter
  /// rather than `== granted` at call sites so that adding a state —
  /// an expired consent, say — is one edit here rather than a search
  /// for every comparison.
  bool get allowsSending => this == AdvisorConsent.granted;
}

/// The disclosure the user agreed to, as a version.
///
/// Consent is to a *specific* set of facts: these numbers leave the
/// device, this vendor receives them, nothing is stored. Change any of
/// those and the agreement on file was to something else.
///
/// So a granted consent carries the version it was given against, and a
/// stored version lower than [current] reads back as
/// [AdvisorConsent.unasked] — the screen is shown again, stating what
/// is now true. A *declined* consent is not re-offered on a version
/// bump; somebody who said no does not want to be asked once per
/// release, and the entry points are still there when they change
/// their mind.
abstract final class AdvisorDisclosure {
  /// Bump this when what leaves the device, who receives it, or how
  /// long it is kept changes. Not for copy edits.
  ///
  /// 1 — computed positions and the question, to a Sanctum proxy and
  ///     then to DeepSeek, stored nowhere on the server.
  static const current = 1;
}
