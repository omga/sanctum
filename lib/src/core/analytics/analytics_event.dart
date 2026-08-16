/// Everything the app is allowed to report.
///
/// ## Why this is a closed set and not a `track(String, Map)`
///
/// Free-form analytics rots. Six months in, nobody remembers whether the
/// event is `quiz_done`, `quiz_complete` or `quizFinished`, half the
/// dashboards are measuring the wrong one, and somebody has passed a
/// user's name as a property because it was convenient at the time.
///
/// Every event here is a named constructor taking typed arguments, so
/// the call sites cannot invent a name, cannot misspell a property, and
/// — the part that matters — **cannot pass anything personal**, because
/// there is no constructor that accepts one. That is not a convention
/// somebody has to remember during review. It is the type system.
///
/// ## What deliberately never leaves the phone
///
/// No name, no birth date, no journal text, no free-text answer, no
/// partner's details. Not even the user's star sign: it is derived
/// directly from the birth date we promised stays local, and no decision
/// anybody makes would change based on how Geminis convert.
///
/// Question and option *ids* do travel. They come from bundled JSON, are
/// identical for every user, and are the whole point — they are what
/// answers "which question loses people".
class AnalyticsEvent {
  const AnalyticsEvent._(this.name, [this.properties = const {}]);

  /// The first-run screen was shown.
  const AnalyticsEvent.onboardingShown() : this._('onboarding_shown');

  /// They tapped through to the quiz.
  const AnalyticsEvent.quizStarted() : this._('quiz_started');

  /// A question appeared. Paired with [AnalyticsEvent.quizQuestionAnswered],
  /// this is the per-question drop-off funnel.
  AnalyticsEvent.quizQuestionShown({
    required String questionId,
    required int index,
  }) : this._('quiz_question_shown', {
         'question_id': questionId,
         'index': index,
       });

  /// A question was answered.
  AnalyticsEvent.quizQuestionAnswered({
    required String questionId,
    required int index,
  }) : this._('quiz_question_answered', {
         'question_id': questionId,
         'index': index,
       });

  /// Every visible question is answered.
  AnalyticsEvent.quizCompleted({required int answered})
    : this._('quiz_completed', {'answered': answered});

  /// The payoff reading was reached.
  const AnalyticsEvent.payoffShown() : this._('payoff_shown');

  /// They opened the share sheet from the payoff card.
  const AnalyticsEvent.payoffShared() : this._('payoff_shared');

  /// The OS notification prompt was raised.
  const AnalyticsEvent.reminderPermissionAsked()
    : this._('reminder_permission_asked');

  /// How they answered it.
  AnalyticsEvent.reminderPermissionResolved({required bool granted})
    : this._('reminder_permission_resolved', {'granted': granted});

  /// The paywall appeared, and what earned it.
  AnalyticsEvent.paywallShown({required String moment})
    : this._('paywall_shown', {'moment': moment});

  /// The paywall was dismissed without a purchase.
  AnalyticsEvent.paywallDismissed({required String moment})
    : this._('paywall_dismissed', {'moment': moment});

  /// A purchase was started.
  AnalyticsEvent.purchaseStarted({required String plan})
    : this._('purchase_started', {'plan': plan});

  /// A purchase completed.
  AnalyticsEvent.purchaseCompleted({required String plan})
    : this._('purchase_completed', {'plan': plan});

  /// A compatibility check was begun, from the picker or manual entry.
  AnalyticsEvent.matchStarted({required String source})
    : this._('match_started', {'source': source});

  /// The invite share sheet was completed.
  const AnalyticsEvent.matchInviteSent() : this._('match_invite_sent');

  /// A reading was unlocked, and by what route.
  AnalyticsEvent.matchRevealed({required String access})
    : this._('match_revealed', {'access': access});

  /// The match card went to the share sheet.
  const AnalyticsEvent.matchShared() : this._('match_shared');

  /// Today's card was turned over.
  const AnalyticsEvent.cardRevealed() : this._('card_revealed');

  /// An energy check-in was recorded. The level is one of five, and is
  /// what makes the retention question answerable at all.
  AnalyticsEvent.energyCheckedIn({required String level})
    : this._('energy_checked_in', {'level': level});

  /// A sound session was started.
  AnalyticsEvent.sessionStarted({required String sessionId})
    : this._('session_started', {'session_id': sessionId});

  /// A ritual was completed.
  AnalyticsEvent.ritualCompleted({required String phase})
    : this._('ritual_completed', {'phase': phase});

  /// A journal entry was saved. The body is never sent — only that one
  /// exists, and roughly how long it was.
  AnalyticsEvent.journalEntrySaved({required int lengthBucket})
    : this._('journal_entry_saved', {'length_bucket': lengthBucket});

  /// Snake-case event name.
  final String name;

  /// Properties. Only primitives, and never anything identifying.
  final Map<String, Object> properties;

  @override
  String toString() {
    if (properties.isEmpty) return name;
    final pairs = properties.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    return '$name $pairs';
  }
}
