# Sanctum — analytics

Every event the app can emit, what it answers, and where it fires.

The source of truth is [`lib/src/core/analytics/analytics_event.dart`](../lib/src/core/analytics/analytics_event.dart);
this file is the human-readable index of it. If the two disagree, the
code is right and this file is stale — fix it in the same commit.

---

## 1. The contract

**The taxonomy is a closed set.** `AnalyticsEvent` has a private
constructor and 22 named constructors. There is no `track(String, Map)`,
on purpose: free-form analytics rots, and within a year nobody remembers
whether the event is `quiz_done` or `quiz_complete`.

**Call sites cannot leak personal data, because no constructor accepts
any.** That is the type system, not a review convention. No name, no
birth date, no journal text, no free-text answer, no partner's details —
and not even the star sign, which is derived straight from the birth
date the onboarding copy promises stays local.

Question ids, option ids and enum names *do* travel. They come from
bundled JSON, are identical for every user, and are exactly what answers
"which question loses people".

`test/core/analytics_test.dart` enforces this with a `_everyEvent` list,
a forbidden-property-name denylist, a primitives-only check and a
40-character length check that would catch prose. **A new event must be
added to `_everyEvent`** or it gets none of those protections.

## 2. Where events go

PostHog, US cloud, project 561208. Wired in
[`core_providers.dart`](../lib/src/core/core_providers.dart) — swapping
the vendor is one line. `LoggingAnalyticsService` stays available for
local debugging, though note that it writes via `dart:developer`, so its
output appears in an IDE or `flutter run` console and **not** in
`flutter logs` or `simctl log stream`.

Deliberately off, and documented at length in `handoff.md`:

- **Session replay** — these screens carry journal entries, a name, and
  two birth dates.
- **`PosthogObserver`** — `MatchResultRoute` carries `name` and `birth`
  as query parameters, so autocapturing routes would post a partner's
  name and birth date to a third party.
- **Person profiles** (`identifiedOnly`, and nothing calls `identify`),
  so events stay anonymous.

## 3. The events

### Onboarding

| Event | Properties | Fires |
|---|---|---|
| `onboarding_shown` | — | **Nowhere.** See §5. |
| `quiz_started` | — | [`onboarding_screen.dart:48`](../lib/src/features/onboarding/view/onboarding_screen.dart:48) — the Enter button. |
| `quiz_question_shown` | `question_id`, `index` | [`quiz_view_model.dart:86`](../lib/src/features/quiz/view_model/quiz_view_model.dart:86) |
| `quiz_question_answered` | `question_id`, `index` | [`quiz_view_model.dart:101`](../lib/src/features/quiz/view_model/quiz_view_model.dart:101) |
| `quiz_completed` | `answered` (int) | [`quiz_view_model.dart:257`](../lib/src/features/quiz/view_model/quiz_view_model.dart:257) — `finish()`. |
| `payoff_shown` | — | [`payoff_screen.dart:48`](../lib/src/features/payoff/view/payoff_screen.dart:48) |
| `payoff_shared` | — | [`payoff_screen.dart:79`](../lib/src/features/payoff/view/payoff_screen.dart:79) — share sheet opened. |

`question_id` is one of `name`, `goals`, `echo`, `love_status`, `weight`,
`birth_date`, `birth_time`, `rhythm`, `commitment` — from
`assets/content/<lang>/onboarding_quiz.json`.

`shown`/`answered` together are the **per-question drop-off funnel**, the
main reason this instrumentation exists. Two details make the numbers
mean what you think:

- **`shown` is reported from the view model, not the widget**, and
  deduped on `_reportedId`. A widget rebuilds for a toggle, a keyboard or
  a theme change, and each of those would inflate the denominator.
- **`index` is the position in the *currently visible* set**, which
  shifts as branches open and close (`love_status` only appears if
  `goals` includes `love`). Group by `question_id`, not by `index`.

`answered` on `quiz_completed` is the count of visible questions, so it
varies by branch — 8 or 9 today. It is not a completion percentage.

### Reminders

| Event | Properties | Fires |
|---|---|---|
| `reminder_permission_asked` | — | [`reminder_view_model.dart:53`](../lib/src/features/today/view_model/reminder_view_model.dart:53) |
| `reminder_permission_resolved` | `granted` (bool) | [`reminder_view_model.dart:61`](../lib/src/features/today/view_model/reminder_view_model.dart:61) |

Raised at the payoff screen, immediately after the reading has quoted the
user's own answer about showing up daily — never on a cold first launch,
where it gets declined once and can never be asked again. The pair is the
opt-in rate for the only retention channel the app has.

### Paywall and purchase

| Event | Properties | Fires |
|---|---|---|
| `paywall_shown` | `moment` | [`paywall_screen.dart:59`](../lib/src/features/paywall/view/paywall_screen.dart:59) |
| `paywall_dismissed` | `moment` | [`paywall_screen.dart:69`](../lib/src/features/paywall/view/paywall_screen.dart:69) |
| `purchase_started` | `plan` | [`paywall_screen.dart:104`](../lib/src/features/paywall/view/paywall_screen.dart:104) |
| `purchase_completed` | `plan` | [`paywall_screen.dart:110`](../lib/src/features/paywall/view/paywall_screen.dart:110) — **over-counts, see §5.** |

`moment` is a `PaywallMoment` name: `lockedContent`, `streakEarned`,
`ritualCompleted`, `sessionsSampled`, `returningUser`. It is what
`PaywallTrigger` decided *earned* the prompt, and it changes the
headline — so conversion should always be read per moment. `PaywallTrigger`
also guarantees each user sees at most four automatic prompts in their
lifetime, which caps how much data this can ever produce.

`plan` is the store product identifier — RevenueCat's
`product.identifier` in production, `sanctum.premium.monthly` /
`sanctum.premium.yearly` from the stub repository, and
`sanctum.report.relationship` for the one-off report. The consumable
needed no taxonomy change; split conversion by `plan`.

**`purchase_completed` means a completed sale on both paths.** Each
returns whether the user actually bought — a cancellation is neither an
error nor a sale — so the event fires only on a real purchase. This was
not true of the subscription path before 2026-09-04: every cancellation
counted as a completed purchase, so **`purchase_completed` on a
subscription plan is inflated for any data collected before that date.**
Report figures were never affected.

### Compatibility

| Event | Properties | Fires |
|---|---|---|
| `match_started` | `source` | **Nowhere.** See §5. |
| `match_invite_sent` | — | [`compatibility_view_model.dart:162`](../lib/src/features/compatibility/view_model/compatibility_view_model.dart:162) |
| `match_revealed` | `access` | [`compatibility_view_model.dart:172`](../lib/src/features/compatibility/view_model/compatibility_view_model.dart:172) — **misreports, see §5.** |
| `match_shared` | — | **Nowhere.** See §5. |
| `report_unlocked` | `access` | [`report_view_model.dart`](../lib/src/features/compatibility/view_model/report_view_model.dart) — a report opened for the first time. |

`report_unlocked`'s `access` is `purchase` or `included`. The two are not
interchangeable: a report claimed with a subscriber's one included slot
is owned but was never bought, so it must never reach
`purchase_completed` — that would count a giveaway as a sale on the
number the whole SKU is judged by. Report *unlocks* are this event;
report *revenue* is `purchase_completed` filtered to
`sanctum.report.relationship`.

`match_invite_sent` reports that the user **picked a target app in the
share sheet**, not that a message was sent. Nothing on either platform
can tell us the latter, and the number should be read as an upper bound.

### Daily loop

| Event | Properties | Fires |
|---|---|---|
| `card_revealed` | — | [`today_view_model.dart:194`](../lib/src/features/today/view_model/today_view_model.dart:194) — the oracle card was turned over. |
| `energy_checked_in` | `level` | [`today_view_model.dart:203`](../lib/src/features/today/view_model/today_view_model.dart:203) |
| `session_started` | `session_id` | **Nowhere.** See §5. |
| `ritual_completed` | `phase` | **Nowhere.** See §5. |
| `journal_entry_saved` | `length_bucket` | **Nowhere.** See §5. |

`level` is an `EnergyLevel` name: `depleted`, `low`, `steady`, `open`,
`radiant`. It is the only self-reported signal in the app and the only
thing that makes "is this working for people?" answerable at all.

`journal_entry_saved` sends a length *bucket*, never the body — the point
is that an entry exists and roughly how long it was.

## 4. Events the SDK sends by itself

`captureApplicationLifecycleEvents` is on, so PostHog emits
`Application Installed`, `Application Opened` and
`Application Backgrounded` without any code here. They carry no personal
data and they are the **denominator for every funnel below** — install
and open counts come from these, not from the typed taxonomy.

## 5. Known gaps — read before trusting a dashboard

**The advisor emits nothing at all.** Not one event, for a feature with
a screen, a purchase and a per-message cost. Nothing here can answer how
many people open it, how many ask a second question, what fraction run
out, or what a pack converts at. Adding them is on `handoff.md` §5 —
**with their call sites in the same commit**, which is the rule the rest
of this section exists to explain.

**Six of the 22 events have no call site in `lib/`.** They are declared,
they are listed in `_everyEvent`, and nothing fires them:

- `onboarding_shown` — the denominator for onboarding completion.
- `match_started` — the nearest thing to "a compatibility check began".
- `match_shared` — carousel exports, the entire acquisition channel.
- `session_started`, `ritual_completed`, `journal_entry_saved` — the
  whole retention loop outside the Today card.

This is the same pattern `handoff.md` flags for repository methods
written and called from nowhere. **Add the call site in the same change
as the event, or it sits dead for months.**

**Historic: `purchase_completed` used to fire on cancellation.**
`RevenueCatSubscriptionRepository.purchase` maps `purchaseCancelledError`
to a success `Result` so that backing out of the store sheet does not
show an error or land in Sentry — and it returned `Result<void>`, so
`paywall_screen.dart` read "no error" as a sale. It now returns
`Result<bool>`, and the screen reports, celebrates and closes only when
that bool is true.

Three things were wrong, not one: the event inflated the only conversion
number the business has; the screen flashed its purchased state and
closed on somebody who had just declined; and `_purchased` suppressed the
dismissal, so `PaywallTrigger`'s 3 → 7 → 14 → 30 day backoff never
advanced and the same user was prompted again on the shortest cooldown —
which also means **`paywall_dismissed` under-counts for data collected
before 2026-09-04.**

`paywall_purchase_test.dart` and `report_purchase_test.dart` pin all
three.

**`match_revealed`'s `access` does not carry access.** The doc comment
and the property name both say "by what route was this unlocked" —
invite, premium or already-revealed, which is the question
`CompatibilityGate` exists to answer. What is actually passed is
`'manual'` or `'celebrity'`, which is the *source*. So the invite-versus-
paywall split is currently unmeasurable, and the value duplicates what
`match_started(source:)` was meant to carry.

**Two events do not exist and are needed for the funnel:**

- **Second-person entry.** `match_started(source:)` marks intent; nothing
  reports that a name and date were actually submitted.
- **Language changes.** The in-app picker writes a preference nothing
  reports, so there is no way to see which locale people actually choose
  versus which one their device gave them — which is the number that
  says where the next translation wave should go.
- **The invite-gate impression.** `match_invite_sent` exists, but nothing
  reports that the gate was *shown*, so there is a numerator with no
  denominator — invite counts, not an invite rate.

## 6. Adding an event

1. Add a named constructor to `AnalyticsEvent` with typed arguments.
   Properties must be `String`, `int` or `bool`, snake_case, and must not
   be able to carry anything a user typed.
2. Add one instance to `_everyEvent` in `test/core/analytics_test.dart`.
   The guarantees are only worth something if that list is exhaustive.
3. **Add the call site in the same commit.** See §5 for what happens
   otherwise.
4. Add the row to this file.
