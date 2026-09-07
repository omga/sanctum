# Sanctum — handoff

Written for someone with **zero context**. Read this before changing
anything structural.

---

## 1. What this is, commercially

A spiritual-wellness / divination app for iOS and Android, aimed at a
consumer audience. Two-person team.

The competitive reality shapes every decision below:

- The main competitor is **OBRIO/Nebula** — Kyiv, 300+ employees, ~$50M
  ARR. Genesis, Universe, Zenjoy and Headway run the same playbook from
  the same city.
- Their playbook is capital-intensive paid user acquisition on Meta. At
  roughly $48 CAC and ~1.3x ROAS with two-month payback, a small team
  cannot win that fight — they have more creative test volume, better
  LTV data so they can bid higher, and an ad account the algorithm
  already trusts.

**Therefore the chosen strategy is organic-first**, not paid UA. Share
and export surfaces are *features*, not polish — they are the acquisition
channel. The onboarding payoff card exists to be posted.

The owner also plans to **ship two apps** and compare conversion. The
intended mechanism is **build flavors on one codebase**, not a forked
repo: content is JSON-driven, the design system is token-driven, and
entitlements sit behind an interface, so a second product is a second
asset set plus a second bundle ID. The expensive part of "two apps" is
two store listings and two creative pipelines, not the engineering.

### Direction, decided 2026-08-16

Build **one** app, not two. The two-app plan was really a hedge against
positioning uncertainty, and positioning can be tested far more cheaply
with two TikTok accounts pointing at one binary than with two store
listings and two creative pipelines. The codebase stays flavour-*ready*;
nothing ships a second bundle ID until one app has a content loop that
reliably works. Splitting a two-person team's posting volume across two
accounts is the one cost the strategy cannot absorb.

Viral formats, ranked by how well they actually travel:

1. **The camera is on the person** — palm and face reading. The filming
   *is* the content. Strongest format, and the best paywall moment.
2. **The output is about a relationship** — compatibility, celebrity
   matches. Invites a second person, so it duets and stitches.
3. **The output is a card about you** — the payoff card. Good retention
   surface, weak acquisition one, because a screenshot is not watchable.

Compatibility was built first because it is days of work on top of the
zodiac engine, the birth-date wheel and `ReadingComposer` that already
existed, and it buys a dozen filmable formats immediately. Video export
and palm scan are the next two bets, in that order.

### Known strategic tension (unresolved)

The owner's own feature ranking put **meditation audio last** ("commodity,
near-zero conversion lift") and **onboarding quiz → personalised paywall
first**. Sanctum as built is a beautiful version of the low-ranked thing,
plus a good version of the high-ranked thing. The relationship/astrology
wedge — compatibility readings, AI advisor sold as credits — is where the
category's money actually is and is **not built**. The quiz and zodiac
work already lean that way, deliberately.

---

## 2. Architecture

See `README.md` for the layer diagram. The rule that matters:

> `features/` → `domain/` ← `data/`. `domain/` imports nothing but pure
> Dart.

Almost all interesting logic lives in `domain/` as pure functions, which
is why the test suite is fast and covers the things that actually break.

`device-testing.md` in this folder covers running and verifying on real
hardware: simulator coordinates, resetting onboarding, and where the
build sizes actually come from. Read it before you spend an afternoon
concluding that taps do not reach Flutter.

---

## 3. Decisions, and what was rejected

Each of these was chosen deliberately. Do not "fix" them without reading
the reason.

### dart_mappable, not freezed

Stable `freezed` (3.2.5) caps `analyzer` at `<11`, which is incompatible
with the analyzer-13 ecosystem that `build_runner` 2.16 and
`riverpod_generator` 4.x require. Only `freezed 4.0.0-dev.*` supports it.
`dart_mappable` 4.9 is stable on analyzer 13 and replaces freezed *and*
json_serializable *and* json_annotation in one package.

**Rejected:** freezed on a dev prerelease.

### riverpod_lint via Dart's native analyzer plugin, not custom_lint

Since riverpod_lint 3.x it uses `analysis_server_plugin` and is declared
in the top-level `plugins:` key of `analysis_options.yaml` — *not* as a
dev_dependency. `custom_lint` is not needed and actively conflicts
(`analyzer_plugin` 0.13 vs 0.14). Plain `dart analyze` picks up the
rules, so CI needs no separate lint runner.

It has already caught a real bug (`ref` used in `State.dispose`).

### sqlite3 3.x directly, not sqlite3_flutter_libs, not drift_flutter

`sqlite3_flutter_libs` is **end-of-life** (`0.6.0+eol`); `package:sqlite3`
v3 ships SQLite itself via Dart build hooks and its changelog explicitly
says to drop the dependency. `drift_flutter` 0.3.1 still pulls the EOL
shims in transitively, so the connection is wired by hand in
`sanctum_database.dart`.

Most Drift tutorials online are still wrong about this.

### Local-first, and one backend

No account, no server, no network **in the core loop**. The daily card
is a deterministic hash of `(installSalt, localDate)`; the moon phase is
computed. Both work offline and cost nothing to run.

**Rejected:** Supabase/Firebase for v1, and account-creation-before-paywall
(Nebula does this for retargeting; with no retargeting budget it is pure
funnel friction).

**The exception, added 2026-09:** the advisor has a Supabase Edge
Function, because a model API key cannot ship in a binary. It is
stateless — no database, no session, no user record — and the app calls
it only when `ADVISOR_PROXY_URL` is compiled in. The second half of the
rejection above still holds: the function takes an **install id**, not a
Supabase user, and Sanctum still has no accounts. See §3 "The advisor"
and `proxy/README.md`.

### Tones are a 43 KB seamless loop, not a rendered session

A sine wave is periodic. A 30-minute 528 Hz tone is 3,675 samples
repeated 10,800 times. The first implementation synthesised the whole
thing — **79 MB and 79 million `sin()` calls, synchronously, on the UI
thread**, which was a real ANR on a Pixel 6.

Now `ToneAudioSource` generates one cycle-aligned loop and the player
repeats it with `LoopMode.one`. Session length lives in the service as a
clock; the fade lives there as a volume ramp. Measured: 305/697/717 ms
per session → **10 ms for all tones combined**.

The loop must contain a whole number of cycles (`sr / gcd(f, sr)`) or it
clicks once per second forever. There are tests for this.

### Moon phase is an elongation model, not mean-synodic

The obvious implementation (constant 29.53-day month from a known new
moon) is off by up to 0.6 days. Phase bands are only ±1.85 days wide, so
that error is invisible mid-band and **wrong near the edges** — the app
confidently displayed "New Moon" 2.4 days after the new moon.

It now computes actual solar/lunar elongation. Worst error vs US Naval
Observatory data: **0.004 days**. Tests pin real USNO timestamps *and*
boundary dates, because the original passed every centre-of-band test.

### Paywall: earned moments with exponential backoff

`PaywallTrigger` is pure and exhaustively tested. Rules: never on install
day; explicit intent (tapping a lock) always wins and bypasses cooldown;
otherwise an "earned moment" is required (streak, ritual completed, both
free sessions used); each dismissal pushes the next prompt out 3 → 7 →
14 → 30 days; and after 4 dismissals it **never asks automatically
again**. A two-year simulation asserts exactly 4 prompts.

**Rejected explicitly:** fake countdown timers, hidden dismiss buttons,
obscured pricing. Those are App Store 3.1.2 rejections and refund
magnets. The paywall converts on timing and honest framing — the headline
names what the user just did.

Weekly pricing was also advised against (highest-refund configuration in
the category) though the stub still lists monthly + yearly only.

### Journal entries open, and can be deleted

`JournalEntry.preview` truncates at 80 characters, and that was the only
way an entry was ever rendered — so anything longer than a sentence was
written, stored, and permanently unreadable. Tapping a tile now opens a
reader sheet with the whole body, scrolling for long entries.

That sheet is also where two more already-built, unreachable things
finally surface: `prompt` was stored on every entry and never shown, so
an entry answering a ritual prompt never displayed what it was
answering; and `delete` existed in both the repository *and* the view
model with no UI calling either. A journal you cannot delete from is a
worse product than one that never offered it.

Both sheets pass `useRootNavigator: true`. Without it the shell's
floating nav bar draws on top of the sheet — a modal with a tab bar
sitting over its own buttons.

**Pattern worth noticing:** this is the fourth repository method found
written, tested at the data layer, and called from nowhere
(`watchRecent`, `watchRevealedHistory`, `delete`, plus the `rhythm`
answer). When adding a repository method here, add the call site in the
same change or it will sit dead for months.

### Tab switching cross-fades, and every branch stays mounted

`BranchSwitcher` replaces go_router's default `IndexedStack` via
`StatefulShellRouteData`'s `$navigatorContainerBuilder` hook, which the
generator picks up automatically.

It is a `Stack`, not an `AnimatedSwitcher`, and that is the whole point
of a stateful shell: Sound keeps playing, Journal keeps its scroll
offset, Today does not refetch. An `AnimatedSwitcher` would dispose the
outgoing branch and undo all of it.

Three things keep the cost down, which matters because a fragment shader
and a starfield ticker are already running behind every screen:

- A branch at opacity 0 is **not painted at all** — `AnimatedOpacity`
  short-circuits — so idle branches cost only layout, and unchanged
  subtrees are relayout boundaries.
- The outgoing branch leaves in 110 ms while the incoming takes 260 ms,
  so the window where two layers composite is about a third of the
  transition rather than all of it.
- Inactive branches have their tickers switched off. Without that, every
  `flutter_animate` entry and `TweenAnimationBuilder` on three hidden
  screens keeps driving frames for a user looking at the fourth.

The movement is transform-only — a small rise and a hair of scale —
because transforms are effectively free next to compositing. See the
gotcha above about where `TickerMode` has to sit.

### Crash reporting is Sentry, and it sees handled failures

Sentry over Crashlytics for one codebase-specific reason: this app
converts almost everything into an `AppFailure` and degrades rather than
crashing. A corrupt blob, a failed write, a share sheet that will not
open — none of those are crashes, and none would ever reach a crash-only
reporter. They are most of what actually goes wrong here.

So `Result.guard` — documented as *the only place the codebase turns
exceptions into results* — calls `ResultReporting.report`. That hook is a
static in `core/result` holding nothing but a nullable callback, so the
result layer stays vendor-free and tests leave it unset. Handled
failures arrive in Sentry at **warning** level so genuine crashes stay
distinguishable in the inbox.

**Wired by hand, not by `sentry-wizard`.** The wizard rewrites the entry
point to wrap `runApp` in `SentryFlutter.init(appRunner:)` and
reintroduces `runZonedGuarded` — which `bootstrap` deliberately does not
use, because `PlatformDispatcher.instance.onError` has caught async
errors since Flutter 3.3 and does not fight the test binding's zone. It
would also have installed 21 Homebrew formulae including a `node`
upgrade.

**Ordering in `bootstrap` is load-bearing.** Sentry goes in *after* the
app's own `FlutterError.onError` and `PlatformDispatcher.onError`,
because its integrations capture whatever handler is already installed
and call it after reporting. Install it first and Sentry chains to
Flutter's defaults and the app's logging is silently lost.

Switched off on purpose: `attachScreenshot` and `attachViewHierarchy`
(both would capture the text on screen — journal entries, a name, two
birth dates), performance tracing (the free tier is 5k events/month),
and `SentryNavigatorObserver` — same route hazard as PostHog's observer,
with `_scrub` as a second line of defence on breadcrumb data.

Verified: on the iOS simulator a probe exception was delivered and the
envelope queue drained. On a real Pixel 6, `libsentry.so` and
`libsentry-android.so` load, `AUTO_INIT is disabled!` confirms the
PostHog flag works, PostHog received feature flags over the network, and
a forced JVM crash was captured. Android *delivery* was not directly
observed — a release build is not debuggable, so its envelope cache
cannot be inspected.

### Analytics is typed, closed, and has no vendor

`AnalyticsEvent` is a class with a private constructor and ~23 named
constructors. There is no `track(String, Map)`, on purpose: free-form
analytics rots, and within a year nobody remembers whether the event is
`quiz_done` or `quiz_complete`, half the dashboards measure the wrong
one, and somebody has passed a user's name as a property because it was
convenient.

More importantly, **call sites cannot leak personal data because no
constructor accepts any**. That is the type system rather than a
convention somebody has to catch in review. `analytics_test.dart` backs
it with a denylist of property names, a primitives-only check and a
length check that would catch prose. New events must be added to
`_everyEvent` in that test — the guarantees are only worth anything if
the list is exhaustive.

Not even the star sign is reported: it is derived straight from the
birth date we promise stays local, and no decision would change based on
how Geminis convert. Question and option *ids* do travel — they come
from bundled JSON, are identical for every user, and are exactly what
answers "which question loses people".

**PostHog is wired** (US cloud, project 561208).
`LoggingAnalyticsService` stays available for local debugging; the vendor
is one line in `core_providers.dart`.

Configured **from Dart**, not from the manifest. PostHog's guide has you
paste the token into `AndroidManifest.xml` *and* `Info.plist`; doing it
in `PostHogAnalyticsService.configure()` instead keeps the token in one
place and stops `debug: true` — which their snippet hardcodes — shipping
to production. Native auto-init is switched off on both platforms via
`com.posthog.posthog.AUTO_INIT`, or the plugin inits on attach, finds no
token, and logs an error every launch.

The `phc_` token is committed with a `POSTHOG_KEY` dart-define override.
It is write-only ingestion and extractable from any shipped binary, so
it is not a secret; the override exists so debug builds can point at a
separate project instead of polluting production funnels.

Two things are off on purpose:

- **Session replay.** Supported on Flutter and masked by default, but
  these screens carry journal entries, the user's name, their birth date
  and their partner's. "Masking would probably hold" is not the standard
  for the one claim the product is differentiated on.
- **`PosthogObserver`.** The navigator observer that auto-captures screen
  views is deliberately not installed, and this one is sharper than it
  looks: **`MatchResultRoute` carries `name` and `birth` as query
  parameters**, so autocapturing routes would post a partner's name and
  birth date to a third party. Screens are reported through the typed
  taxonomy or not at all.

That route shape is a standing hazard, not just an analytics one — deep
link URLs also surface in crash-reporter breadcrumbs and OS logs. If
Sentry or Crashlytics is added, check what it records about navigation
before enabling it.

Verified on the simulator: the SDK initialises under the project token,
`posthog.remoteConfig` holds a real server response (so the round trip
works), the replay buffer stays empty, and the event queue drains on
backgrounding.

**Caveat worth knowing before you trust the log implementation:**
`ConsoleLogger` uses `dart:developer`'s `log`, which goes to the VM
service — so events are visible in an IDE or `flutter run` console and
**not** in `flutter logs` or `simctl log stream` from a detached device.
It is a development aid, not a way to watch a real user's funnel. That
is an argument for wiring a real vendor sooner rather than later.

### The privacy promise, and why the copy no longer makes one

The app used to claim, in three places, that "nothing leaves your
phone". Analytics and RevenueCat already strained that; the advisor
broke it outright, because it sends a chart and a question to DeepSeek.

The claim was withdrawn from the product rather than reworded (commit
"The app stops promising what it can no longer promise"). The onboarding
body, the quiz's name and birth-time questions, `partnerBody` and half
the advisor disclosure no longer promise locality, in all four locales.

**What is still said, and is still true:** narrow statements about one
screen — a journal entry is only on this phone, which is *why* deleting
it cannot be undone; a report is computed on the device; locale content
is bundled rather than downloaded. The distinction worth keeping is
between a claim about the product's posture, which changed, and a fact
about one screen, which did not.

**What replaces it:** three enforced layers rather than a sentence —
`AdvisorContext` has no field a name could occupy, `MessageRedaction`
rewrites the names a user types, and the proxy rejects them a third
time. See §3 "The advisor" and `advisor.md` §1.

**And a screen that states the exception.** The advisor's consent screen
is now where "what leaves this phone" is answered, in full and before
anything does — which is why the general claim could be withdrawn from
onboarding without the product becoming vaguer about it. A narrow,
verifiable statement on the one screen it applies to beats a broad one
on the first screen of the app.

`reportLockedNote` is a cautionary tale here. It said "It stays on this
phone", the sweep read that as a privacy promise and cut it, and
`report_screen_test` failed: that line is small print warning that a
consumable **does not restore on another device**. Not every sentence
containing "this phone" is a marketing claim.

### The advisor, and the three places a name is stopped

Built 2026-09 across five commits. `advisor.md` is the design document
and the place to read first; this is what a person changing the code
needs to know before they touch it.

**The feature.** An AI astrologer answering from the pairing's computed
positions, reached from the reading, the report, and an Ask tab. Five
free messages a week for subscribers, shared across every conversation;
$2.99 buys five more; non-subscribers get none free and can still buy.

**A name never leaves the device, and it is enforced three times.**
Not by review, not by a promise in copy:

1. `AdvisorContext` has a private constructor and no field a name or a
   birth date could occupy — the `AnalyticsEvent` pattern applied to
   higher stakes. `advisor_context_test.dart` asserts a real match's
   payload contains no substring of either person's name.
2. `MessageRedaction` rewrites the names the app stored out of anything
   the user types, over the *whole* history — scrubbing only the newest
   message re-sends every earlier name on the next turn.
3. The Edge Function re-validates with the same denied-key list, walked
   to full depth. That is defence against our own future bug, not
   against a hostile client.

Suggested questions sidestep the problem: each has a `displayKey`
carrying `{name}` and a `promptKey` that never does. Two written strings
beat one string and a regex.

**The transport is an interface, and both implementations stay.**
`ScriptedChatTransport` is not scaffolding — it is what keeps the widget
tests fast, deterministic and free, and it is what the app falls back to
when no proxy URL is compiled in. `ProxyChatTransport` speaks a wire
format that is *ours*, not the vendor's, so changing model is a server
change and the client parser never learns a vendor's event names.

`MessageAuthor.counterpart`, never `.advisor`: person-to-person chat
later swaps the transport and the `ConversationKind`, and the models,
budget, storage and their tests do not move.

**Money is client-side, and that is the known hole.** `MessageBudget`
spends from a balance in preferences. The proxy has a rate limit keyed
on a header the client chooses and nothing else — it does not know
whether the caller has messages left. Anybody who reads the publishable
key out of the binary can spend the DeepSeek budget. Closing that means
a RevenueCat webhook into a Supabase table and a check in the function,
which is also the first infrastructure astrologer chat needs.

**Consent is a screen, and it gates the feature twice.** Built
2026-09-05. `AdvisorScreen` shows `AdvisorConsentView` instead of a
conversation until it is answered, and `chatTransport` will not build a
`ProxyChatTransport` without a granted consent — so a build that *does*
compile a URL still sends nothing until a user has read what leaves the
device and agreed. The screen names DeepSeek; an unnamed "AI provider"
is not disclosure, and a test fails if the name disappears.

The stored answer is a tri-state, not a boolean, and the reason is worth
keeping: the back arrow records nothing and only "Not now" writes
`declined`, so a decision can be told from a screen somebody walked away
from. It also carries `AdvisorDisclosure.current` — a yes to an older
disclosure reads back as unasked, because consent was to a specific set
of facts and changing the recipient changes them. A no survives a
version bump. `docs/` holds the privacy policy and store data-safety
drafts that have to be finished before a release build points at the
proxy.

**A conversation need not be about a pairing.** `AdvisorTopic` is a
sealed type — `MatchTopic` and `SelfTopic` — carrying the subject, the
payload, the suggestions and the names to redact. It is the controller's
family key, and equality is the subject key. The Ask tab leads with a
"You" row that does not wait for a saved reading. `advisor.md` §11 has
the reasoning, including why `SelfSubject` is not date-keyed the way
`DaySubject` is, and the fact that **a `self` surface needs the Edge
Function redeployed** — an older deployment answers `bad_request`.

**The first build ever pointed at the proxy found a real defect, and it
is worth knowing the shape of it.** `AdvisorController.ask` reaches the
transport with `ref.read(chatTransportProvider.future)`, and `ref.read`
registers no listener — so an auto-disposing provider is collected the
moment the read returns. With no URL compiled in, `chatTransport` built
synchronously and finished first; with a URL it awaits an install id,
resumes on a disposed `Ref`, throws `UnmountedRefException` inside a
future nobody is awaiting, and `ask` never returns. The symptom is a
question sitting under a spinner for ever with no error — indistinguish-
able, from the outside, from a dead proxy. `chatTransportProvider` is
`keepAlive` now, which is the same fix `LanguageController` records for
the same cause. `advisor_proxy_wiring_test.dart` is the regression, and
it is a *widget* test because every layer had tests already and the
defect was in the seam between them.

**Things that will catch you:**

* Widget tests need `SharedPreferences.setMockInitialValues` or every
  screen renders as though the user had no messages — a plausible
  failure with nothing to do with the code under test. Re-pumping
  *resets* that store, so a test proving the balance is shared has to
  pass `keepPreferences: true` or it proves nothing.
* A widget test of the *conversation* also has to grant consent, or the
  screen renders the disclosure and every assertion about a composer
  fails. `advisor_screen_test` overrides `advisorConsentProvider` rather
  than writing preference keys, so that file does not have to know how
  consent is stored; `advisor_consent_test` deliberately does not
  override it, because the storage is what it is testing.
* `pumpAndSettle` never returns on any screen showing a primary
  `SanctumButton`; its sheen repeats forever. The out-of-messages state
  has one. Pump frames instead — `report_screen_test` records the same
  trade.
* The advisor screen is pushed with an object, never routed.
  `CompatibilityMatch.id` contains both names and birth dates, and
  routing by it would write exactly that into breadcrumbs and OS logs.
* **Missing Android manifest entries fail silently, and nothing in Dart
  can see it.** Three components have been missing at different times —
  `audio_service`'s service, its media-button receiver, and both
  notification receivers — and every time the platform swallowed it and
  the feature simply did nothing. Check the *merged* manifest rather
  than the source one:
  `build/app/intermediates/merged_manifest/*/process*MainManifest/AndroidManifest.xml`.
  A plugin that used to declare something can stop doing so, and a
  version upgrade is when that happens.
* `flutter_test` draws every glyph as a square box unless the real font
  is loaded, so any test asserting that something *fits* is measuring a
  font the user will never see. `test/support/fonts.dart` loads Inter;
  `shell_nav_bar_test` is the one that needs it. The nav bar overflowed
  on English "Journal" for months with `label_budget_test` passing
  throughout — it counts characters, and what overflows is width.
* Weeks are ISO-8601. A naive week number hands out a second free
  allowance in late December every year; there is a test pinning
  2026-W53 across the new year.
* The database is at `schemaVersion` 2. The migration is additive and
  `conversation_migration_test.dart` builds a version 1 database by hand
  to prove a journal survives it. A migration that *changes* something
  wants `drift_dev`'s schema snapshots instead of that fixture.

### The daily reading is a transit, not a random draw

The home screen used to show an affirmation drawn from a bag of 22 and
an oracle card picked by hashing the date. Both are stable, and neither
is *connected* to yesterday or tomorrow — so there was never a reason to
open the app on any particular day.

`TransitCalculator` now compares today's planets against the user's
natal positions. It changes because the sky moved, it differs between
two people born a week apart, and — the part that matters — it is
knowable in advance, which is the only honest open loop the app has. The
"Tomorrow" line on the transit panel is a real promise, not a tease.

Three things are load-bearing:

- **Only slow bodies are used as natal points** (Sun, Venus, Mars,
  Saturn). A birth date with no time pins a body only as tightly as that
  body is slow. Adding the Moon means adding a birth-time question.
- **A body never aspects its own natal position.** The Sun meeting your
  Sun is a birthday; the slow ones are the background of a life rather
  than news about a Tuesday.
- **Quiet days are admitted.** When nothing is in orb the app says so.
  A product that claims every Tuesday is significant has already spent
  its credibility.

Retrograde detection is free — apparent longitude decreasing — and
Mercury retrograde is the most culturally legible thing in astrology, so
it gets a banner. Pinned to the real August 2024 window in tests.

### Reminders: the promise onboarding was already making

`rhythm` — "when do you want your reading?" — was collected during
onboarding and **read by no code in the app**, while
`flutter_local_notifications` had been removed. The app asked people to
commit to a time and then had no way to reach them. That is now wired.

Three decisions worth keeping:

- **Inexact scheduling.** Exact alarms need `SCHEDULE_EXACT_ALARM`,
  which needs a Play Console policy declaration Google rejects without
  alarm-clock-grade justification. A reading at 08:07 instead of 08:00
  is indistinguishable, so `inexactAllowWhileIdle` is used and the
  permission never comes up. The manifest comment says so; do not "fix"
  it by adding the permission.
- **The notification carries the whole reading.** Nothing of ours runs
  when one fires, so each day's transit line is composed in advance and
  travels with it. That makes the queue a snapshot, which is why it is
  rewritten on every launch — one cancel, seven schedules.
- **Permission is requested at the payoff screen**, immediately after
  the reading has quoted the user's own answer about showing up daily.
  Asked on first launch it gets declined once and can never be asked
  again.

Scheduled instants are converted to absolute UTC rather than a named
zone, avoiding a timezone-name dependency. The trade: someone who
crosses a DST boundary without opening the app drifts by an hour until
the next launch rewrites the queue.

**None of it worked on Android until 2026-09-06.**
`flutter_local_notifications` stopped declaring its own receivers at
version 16 — its manifest now carries `POST_NOTIFICATIONS` and `VIBRATE`
and nothing else — so the app must declare
`ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver`
itself. It did not. `zonedSchedule` therefore set an alarm whose
PendingIntent targeted a component that did not exist: the call
succeeded, no `Result` failed, nothing was logged, the alarm fired, the
broadcast resolved to nothing, and no notification was ever posted.

The symptom on a device is silence, which is indistinguishable from a
denied permission or an OEM battery policy — and it is invisible to
every test in the Dart layer, which is how the feature shipped with unit
tests and never once worked. `android_manifest_test.dart` now asserts
the strings are present. It is a crude test and it is the only detector
that exists.

### Rituals rotate per lunation, and the catalogue is twelve

The catalogue held one ritual per phase and `ritualFor` returned the
first match, so a user six months in had done the same New Moon ritual
six times, word for word. It is now three per phase, twelve in all.

Adding entries alone would have fixed nothing — a second ritual for a
phase was simply unreachable behind the first. `RitualSelector` picks by
**lunation**, not by date: a phase band is several days wide, and a
day-keyed pick would swap the ritual out from under someone halfway
through it. `MoonPhaseCalculator.occurrenceStart` walks back to the first
day of the current run of the phase so every day inside one window agrees
on which occurrence it belongs to.

Unlike `DailyAttunementSelector` this is **not salted per install**, and
that is deliberate rather than lazy. A daily card is a reading and should
be about you; a moon ritual is a practice attached to an event everyone
is under at once, and two friends comparing notes on the same full moon
should find they were asked to do the same thing.

`content_catalog_test.dart` now asserts every ritual phase carries more
than one, and `ritual_view_model_test.dart` walks a full year to prove
every authored ritual is actually reachable — the check that would have
caught the original shape.

### The check-in loop is closed

`EnergyRepository.watchRecent` was implemented and called from nowhere:
the app asked how you felt every day, stored it, and never mentioned it
again. `EnergyPatternCalculator` reads it back — a 30-day strip that
shows gaps as gaps, plus a finding correlating energy against real lunar
phase.

It **refuses to speak most of the time**: a finding needs three
check-ins in each of two phases and a gap of 0.7 on the 1–5 scale.
Anything looser and the app starts announcing patterns in four data
points, which is how something claiming to know you gets caught not
knowing you. This is also the natural premium surface — the user's own
data arguing for the app's premise is a better sales pitch than copy.

### Compatibility runs on real planetary positions

`Ephemeris` computes Sun, Venus, Mars and Saturn from Keplerian elements
with linear rates — the standard JPL approximation. Validated against
three documented events: Saturn at the 2020 great conjunction lands
**0.03° from 0°29' Aquarius**, Venus' 2020 greatest elongation is 0.1°
out, and the December solstice falls exactly on 0° Capricorn. A separate
test agrees with the hand-written sun-sign date table on every non-cusp
day across seven decades, which validates the whole chain — Kepler
solve, heliocentric-to-geocentric transform, and the precession
correction that turns J2000 longitudes into tropical ones.

**Do not swap this for a library.** The obvious choice, `sweph`, is
**AGPL-3.0** unless you buy a professional Swiss Ephemeris licence from
Astrodienst — AGPL in a closed-source app means publishing the app's
source. It also ships ~20 MB of data files. We need half a degree of
precision, not arcseconds, so none of that is worth taking on.

Only slow bodies are used, and that is a correctness constraint rather
than laziness: a birth date with no time pins a body only as tightly as
that body is slow. Venus and Mars move under 1.25°/day and Saturn takes
two and a half years to cross a sign. **The Moon moves 13°/day and its
sign genuinely cannot be known without a birth time**, so it is not used
and not faked. Adding it means adding that question.

### Localisation: two stores of words, and why

Wave 0 landed 2026-08-31. The app is now *structurally* multilingual and
ships one locale, English. Adding a language is content and a content
pipeline, not engineering.

Words live in exactly two places, and the split is forced by the
architecture rather than chosen for taste:

| | `lib/src/l10n/app_en.arb` | `assets/content/<lang>/` |
|---|---|---|
| Holds | UI chrome: buttons, headings, labels, errors | The product: readings, quiz, oracle, rituals, copy.json |
| Reached by | `context.l10n.someKey` | `CopyBook`, injected into domain services |
| Why there | needs ICU plurals and a context | `domain/` is pure Dart and **cannot import `AppLocalizations`** |

**That second cell is the whole design.** `features/ → domain/ ← data/`
means a composer cannot see a Flutter-generated class, so the prose it
assembles has to arrive as data. It does, as a flat dotted dictionary —
`compatibility.dynamic.trine`, `transit.pair.saturn.venus` — built from
the enums that select it, so adding an aspect or a facet fails on a
missing key rather than composing a blank line.

`copy.json` was **generated from the `static const` maps it replaced**,
not retyped, so the English content is provably the same text that
shipped before. The guard going forward is in the tests:
`reading_composer_test` and `compatibility_composer_test` read the real
shipped file and assert every key the composers ask for exists.

Four rules worth keeping:

- **No widget calls `.displayName`.** Enum names are rendered through
  `sanctum_lexicon.dart`, which switches exhaustively — so adding an
  enum value breaks compilation there, which is the cheapest possible
  reminder that it needs an ARB entry too. `displayName` survives on the
  enums as the authoring source the ARB was written from, and as a debug
  label. A widget that reaches for it ships English inside a translated
  screen, silently.
- **`SanctumLocales.resolve` is the only locale decision.** `MaterialApp`
  and the content catalogue both go through it. Two resolvers would
  eventually disagree and put English chrome around translated readings.
- **Content falls back per *file*, not per catalogue.** A locale missing
  `oracle_cards.json` gets the English deck and keeps its own quiz. That
  is what lets a language ship before its long tail is translated.
- **`CopyBook.format` is deliberately feeble** — `{name}` substitution
  and nothing else. Anything needing a plural or a number belongs in the
  ARB, where ICU does it properly.

Adding a locale: an ARB file, an `assets/content/<code>/` directory, the
directory declared in `pubspec.yaml`, and the locale added to
`SanctumLocales.supported`. `lib/src/l10n/untranslated.json` lists what
each locale still lacks.

**Known English still in the code**, all deliberate and all listed so
nobody has to rediscover them:

- `AppFailure` messages ("Could not read your matches"). They surface in
  snackbars but are produced in repositories and controllers with no
  context, so localising them is its own small project — probably by
  giving `AppFailure` a key instead of a message.
- `design_system/gallery/` — a developer surface, referenced from
  nowhere in the app.
- The SANCTUM wordmark on exported frames, which is a brand mark.
- Sign *glyphs* (♈♉♊), which are Unicode and language-independent.

### Ukrainian and Russian: the voice, and what Slavic broke

Wave 1 landed 2026-08-31. Three locales ship: `en`, `uk`, `ru`.

**The voice, decided by the owner and applied everywhere:**

- **Informal singular** — «ти» / «ты», never «Ви» / «Вы». The one
  exception is the compatibility readings, where the English "you" means
  *the couple*; there the plural is correct and is written as «ви двоє /
  вас двох» so it can never be misread as formal address. A sweep script
  in the scratchpad checks that plural-you appears nowhere outside
  `compatibility.*`.
- **The reader is a woman.** Feminine agreement throughout — «ти
  народилася», «ти не здалася», «Завершила». This is not decoration: it
  removed every «(-ла)» bracket form from the first draft, which was the
  single most machine-made thing in it.
- **The app speaks in first person singular about its own work** —
  «Розставляю планети», «Читаю Венеру і Марс», «Збираю твій допис». Not
  "we". There is one voice in this app and it is not a team.

**What Slavic broke that English hid:**

- **`transit.headline` could not be a template.** It was
  `{transiting} {verb} your {natal}`, and the first Ukrainian build read
  **«САТУРН ТИСНЕ НА ТВІЙ ВЕНЕРА»** — the possessive must agree with the
  planet's gender *and* the verb governs a case, so "your Venus" is four
  different phrases depending on where it lands. Fixed by giving the
  natal body its own key, `transit.natal.*`, carrying possessive, gender
  and case together — and by choosing verbs that **all govern the
  accusative in every language**, so six forms suffice instead of one per
  verb-and-planet pair. English output is unchanged.
- **Plurals.** Four hand-rolled `n == 1 ? '' : 's'` patterns became ICU
  plurals in Wave 0 precisely for this: uk and ru need `one/few/many`,
  and the English two-branch form is unfixable by a translator.
- **Enum labels needed shortening, not just translating.** See the label
  budget below.

**Celebrity roles are gendered per person.** `assets/content/<loc>/
celebrities.json` carries `knownFor` in the right gender for each of the
141 entries (58 women). Ukrainian takes feminitives throughout
(акторка, співачка, блогерка); Russian takes them only where they are
the standard word rather than slang. Names stay in Latin — **so celebrity
search does not match Cyrillic input**, which is a real gap and the
obvious next thing to fix in the picker.

### Spanish: one locale code, LatAm-neutral copy

Wave 2 landed 2026-08-31. Four locales ship: `en`, `uk`, `ru`, `es`.

**Registered as plain `es`, deliberately.** `SanctumLocales.resolve`
matches language before country, so one entry serves Mexico, Colombia,
Argentina, Spain and every other market. The copy is written to survive
that: **`tú`** (the one informal singular understood everywhere — not
`vos`, which is Rioplatense/Central American), **`ustedes`** for the
couple readings (plural everywhere; `vosotros` would mark it Spain-only),
and no market-specific vocabulary. A market that eventually needs its
own wording gets its own entry, which resolves ahead of this one.

Same voice rules as Wave 1: informal, feminine agreement for the reader,
first person singular for the app's own work.

**The register is a positioning decision, not a translation choice.**
Spanish-language astrology content is saturated with *el universo
conspira a tu favor* — cosmic flattery, exclamation marks, zero
specificity. Sanctum's whole claim is the opposite, so the Spanish is
deliberately dry and concrete: *Sospechosamente fácil.* / *La química
nunca fue el problema.* / *De aquí no sale nadie limpio.* If this ever
gets softened toward the category norm, the differentiation goes with
it.

Two mechanical notes:

- **Spanish runs ~25% longer than English**, so the tight labels were
  chosen for length as much as meaning — `Fondo` for Depth (5 chars,
  matching English's `Depth`) rather than the clearer-but-double-length
  `Profundidad`. `label_budget_test.dart` covers `es` and enforces it.
- **`transit.headline` needed no special work here**, unlike the Slavic
  locales: Spanish `tu` is invariant for gender. The verbs were still
  chosen to all take a following `tu X` directly, so the same six
  `transit.natal.*` keys serve every aspect.

### Three defects that only composition revealed

Worth recording as a method, because none of these are visible when you
read the strings one at a time — only when you look at what the app
actually assembles and puts on screen.

1. **`Hoy … Hoy …`** Four of five transit openers start with the time
   word, and I had begun ten of twenty bodies the same way — so 40 of
   100 daily readings said it twice in two sentences. The English source
   does this in 2 of 100. Found by composing every permutation in a
   script rather than by reading the file. Fixed in `es`, and the same
   audit found I had done it in `uk` and `ru` too.
2. **The birth-time screen said the same sentence twice** — the question
   subtitle and the hint beneath it both read "most people don't know",
   word for word, in all three translations. Only visible on the screen,
   because the two strings live in different files.
3. **`Ritual de Cuarto creciente abierto`** — a capital mid-sentence,
   which in Spanish reads as machine output. The moon name is
   capitalised at source and is shown standalone elsewhere, so the
   *sentence* moved instead of the noun: `{moon}: ritual abierto`.

The general lesson: **read the composed screen, not the string table.**
A key-by-key review passes all three of these.

### The energy row, and a test that had to be thrown away

Five energy labels share one row, each getting about sixty points. In
Ukrainian «Виснажена» did not fit, wrapped to two lines, made its column
taller than the other four, and left the five bars stepping up and down.
Fixed by top-aligning the row and giving each label a fixed
one-line slot with `FittedBox(scaleDown)`; the labels were shortened too
(Виснажена, Низька, Рівна, Відкрита, Сяюча).

**The widget test written to guard it was deleted, on purpose.** It
passed identically with the bug present and with it fixed: `flutter_test`
draws in a fallback font whose metrics have nothing to do with Inter, so
nothing wrapped at any width, and loading the real face did not reproduce
it either. A layout assertion that cannot fail is worse than no test,
because it reads like cover.

The guard now sits where the constraint actually lives —
`test/l10n/label_budget_test.dart` caps the length of the labels that
live in fixed-width furniture (energy levels, nav, hexagon facets, the
aspect pill) in every shipped locale. It is deterministic, it fails on
the exact input that caused the bug, and it is the same rule the ARB
descriptions already state in prose. **Layout regressions in a
translation still need a device or a golden**, and there is no
substitute in this repo yet.

### A `CopyBook.empty` fallback was hiding a crash

Wave 0 gave two widgets `ref.watch(contentCopyProvider).value ??
CopyBook.empty`. `CopyBook.get` throws on a missing key by design — so on
the first frame, before the provider resolved, the empty book turned
"still loading" into a `StateError` and the Today screen threw. It only
surfaced under `uk` because that was the first cold start after the
change.

Fixed at the root rather than the symptom: **the composers now produce
every string, including the headline.** `DailyTransitReading.headline`
and `Reading.headline` are composed fields like every other line, the two
widgets went back to being plain `StatelessWidget`s, and
`contentCopyProvider` is gone. No widget reaches for content
asynchronously any more, which is the property that made this possible.

### Birth time is optional, and buys exactly one thing

Added 2026-08-31. Onboarding and both compatibility entry points now ask
for a birth time, with **"I do not know" as a first-class answer** rather
than a skip — most people genuinely do not know, and a question that
records nothing is a question the flow asks forever. `BirthTime` carries
three states (never asked / known / asked-and-unknown) precisely because
a nullable int carries two.

**What it buys is the Moon, and nothing else.** The four existing bodies
are slow by design, so a time moves them by fractions of a degree —
`ephemeris_test.dart` pins Saturn moving under 0.15° across a whole day,
because the tempting overclaim here is that a birth time sharpens the
whole reading. It does not. The Moon crosses a sign every 2.3 days and is
the one body a date cannot place, which is why it was excluded until now.

Three constraints hold it together:

- **The Moon enters the model only when *both* people have a time.** A
  real Moon measured against a noon guess would report the difference as
  a finding about the couple — the same lie as inventing a score. So
  `_raw` has two parallel weight sets, each summing to 1.0, and readings
  with no time compute *exactly* the numbers they did before. Spark and
  Future deliberately take no Moon term, and a test pins that.
- **Celebrities never get one.** The catalogue is Wikidata `P569`, which
  records a date. A fabricated Moon sign beside a real person's name, on
  a card built to be posted, is a different category of mistake.
- **`Ephemeris.moonLongitude` needs no precession correction.** Its
  series is already referred to the equinox of date, unlike the planetary
  elements. The proof is a cross-check rather than an assertion: at four
  documented new and full moons spanning 1990–2026, the Meeus lunar
  series and the Keplerian solar path agree to **0.03°**, through
  completely separate code.

The zone caveat is real and written down in `BirthTime`: this is
wall-clock time at a birth place the app never asks for. It is the same
assumption the birth *date* already makes, one level finer, and it is
never worse than the noon guess it replaces. Closing it properly needs a
birth *place* — a geocoder, a historical timezone database and a screen.

**`Ephemeris.julianDay` takes the time as an explicit argument, and that
is load-bearing.** It reads only the calendar fields of its `DateTime`.
Transits are computed from `Clock.today()`, but nothing stops a caller
passing a full `DateTime.now()` — and if that silently moved the sky, the
daily reading would drift through the afternoon. A test pins it.

### Birth dates are calendar dates, and used to lose a day

`dart_mappable` encodes every `DateTime` as UTC, which is right for an
instant and wrong for a birth date. The app builds birth dates as
`DateTime(y, m, d)` — local midnight — so east of Greenwich they were
stored as the *previous* day and read back shifted:

```text
saved     1996-06-15 00:00 local  (UTC+3)
stored    "1996-06-14T21:00:00.000Z"
restored  1996-06-14
```

Every birth date in the app moved back a day the first time it was read
from storage, for every user in Europe — including both of ours. Cusp
birthdays reported the wrong sun sign from the second launch onwards,
and `MatchPerson.key` stopped matching the id its own saved reading was
stored under.

`CalendarDateHook` fixes it by writing **UTC midnight of the local
calendar date**, so the stored string names the right day wherever the
phone is. Blobs written by the old behaviour do not have midnight in
them, which is exactly what distinguishes the two formats; those are
converted back through local time, recovering the original date on the
device that wrote it. `birth_time_persistence_test.dart` pins both paths
from hand-written legacy JSON.

**The general rule:** a hook's return value is cast straight to the
field's declared type, so a map-valued hook must rebuild a typed map. A
`Map<dynamic, dynamic>` fails that cast at runtime and takes the whole
field with it.

### Every field feeding `MatchPerson.key` must travel with the route

`MatchResultRoute` rebuilds the second person from loose query
parameters. Miss one and the rebuilt person keys differently from the
stored id, `CompatibilityGate` cannot find the reveal, and **a reading
the user has already unlocked asks to be unlocked again.**

This happened immediately: the saved-match list carried the date but not
the newly added time, and a revealed match came back showing "that's your
free reading used". `birth_time_test.dart` now pins the route round-trip
in both directions — that a known time survives, and that dropping it
changes the key.

### Aspects are harmonic, not orb-gated

Traditional astrology counts an aspect only inside an orb. Modelled
literally that gives a product where most planet pairs contribute
nothing, every score sits on its baseline, and the occasional pair
spikes — flat with spikes, which is the worst possible distribution for
something people compare with friends.

So `Aspects` uses the harmonic form: `cos(4θ)` peaks at the hard angles
(0°, 90°, 180°) and `cos(6θ)` at the flowing ones (0°, 60°, 120°, 180°).
Continuous, always defined, and a square is simultaneously maximum heat
and minimum ease — which is what lets Spark and Trust disagree about the
same couple.

### Six facets, and two that are deliberately lopsided

Spark, Vibe, Trust, Drama, Depth, Future — each owned by one planetary
contact, so any score traces to a specific claim. The earlier set
(Spark, Communication, Trust, Staying power) read like a performance
review; nobody describes a relationship in those words.

The names are all one short word **because of localisation**. These are
hexagon axis labels, and "Communication" becomes "Общение",
"Staying power" becomes "Долговечность". Short in English is the only
way to stay short in Russian.

`pullShare` and `powerShare` are **directional** and this is the most
important product decision in the feature. Everything was symmetric
before, and symmetry is exactly what nobody posts: "we are 86%
compatible" is a fact about a couple, "they are 62% of this and you are
38%" is a fact about a person. It is also the correct astrology — your
Mars on their Venus is a different contact from theirs on yours, and
Saturn is famously one-way.

Both are damped toward even (`_share`), so two people with no strong
contacts get 50/50 rather than a dramatic split decided by rounding
noise. The model should not be loudest where it knows least.

### What is presentation and what is modelling

`_toScale` widens the distribution so a 96 is reachable. That is a
single monotonic curve applied identically to every pair, so it never
changes which of two couples scores higher.

The term it replaced — `((a.index + b.index) % 5) - 2`, a per-pair nudge
that existed so two different trines would not both return 94 — *did*
change orderings, and was the one genuinely arbitrary number in the app.
Keep that distinction if you touch this: uniform presentation curves are
fine, per-pair fudges are not.

### The sun-sign aspect still names the reading

The distance between the two sun signs no longer scores anything, but it
still *names* the reading — the "Magnetic" chip — and still selects the
opening paragraph. `ZodiacAspect` is declared in distance order because
`aspectBetween` indexes `values` by the step count; reordering the enum
silently reassigns every reading in the app, and a test pins it.

Scores are clamped to **45–98**. A 9% match is funny exactly once; the
modal user is checking themselves against someone they like, and a
product that tells people their relationship is doomed gets deleted
rather than posted. The range is honest, just not cruel.

Copy comes from two independent axes — aspect for the dynamic, element
pair for the texture — plus two lines keyed to whichever facet actually
scored highest and lowest. Keying everything to the aspect alone would
make every Aries-and-Leo reading word-for-word identical to every
Taurus-and-Virgo one, and users compare results with their friends. That
is the whole distribution plan, so identical copy is not cosmetic.

### The first reading costs an invite, the second costs money

`CompatibilityGate` is pure and exhaustively tested. Rules: anything
already revealed stays revealed forever; premium opens everything; with
nothing revealed yet, an invite unlocks exactly one reading; after that
it is the paywall.

The ordering is the point. The invite is the only acquisition channel
this product has, and asking for it *before* the reveal — while
curiosity is at its peak and the user has not yet had the thing they
came for — is the only moment it converts. A second invite instead of
money was rejected: it teaches people the paywall can always be shared
away.

`revealedIds` is a set, not a count, so reopening the free reading a week
later does not consume the free slot again and then demand payment for a
screen the user has already seen.

What the app can know is limited and worth being honest about:
`ShareController.shareInvite` reports that the user *picked a target
app*, not that a message was sent. Nothing can tell us the latter.

### The catalogue is verified against Wikidata, not memory

141 people, and every birth date comes from Wikidata's `P569` rather
than from anybody's recollection. The original 46 were written from
memory and one of them was wrong — Barry Keoghan was 17 October, and is
18 October. One in 46 is about the rate you should expect from memory,
which is why `tool/verify_celebrities.py` exists and why it exits
non-zero: run it before a release.

Three things it does that a naive check would not:

- **Resolves through the English Wikipedia article, not Wikidata search.**
  Search is fuzzy and confidently wrong on mononyms: "Rihanna" matched
  a *given name* entity and "Dua Lipa" matched the album. Names that
  need help are pinned in `tool/celebrity_titles.json`, by Q-id where
  the article title is contested — "Lisa (Thai rapper)" resolved one
  day and 404'd the next when the page moved.
- **Rejects imprecise dates.** Wikidata stores year- and month-precision
  values, and a year-precision date renders as 1 January — which passes
  a naive string check and shows the wrong sign. Only `precision == 11`
  is accepted. Note the converse: Noah Kahan, Ice Spice, Tate McRae and
  Charli D'Amelio genuinely are 1 Jan / 1 Jul / 1 May, confirmed against
  article prose, so a "looks like a placeholder" heuristic would be
  wrong to reject them.
- **Excludes minors**, and `content_catalog_test.dart` asserts it. This
  is a romantic compatibility feature whose output — "who wants it
  more", beside a name — is designed to be posted publicly. A child in
  that list is a different category of mistake from a wrong date.

The `influencer` group ("Creators") was added alongside: someone hunting
a streamer will not scroll a list of film actors to find one. Enum
declaration order is section order in the picker.

**No celebrity photographs, ever.** A public figure's birth date is a
fact; their likeness is not, and a face beside a compatibility score
implies an endorsement that does not exist. The picker draws an
element-tinted disc with the sign glyph instead, which is also better
looking than a grid of scraped press photos.

That rule holds even when the *user* supplies the photograph. The
Photoshop analogy — "nobody bans the tool" — breaks on two points here:
this app ships a celebrity picker, a score, a template and a watermark,
so it structures the output rather than providing a blank canvas; and
the export is an acquisition asset for a paid product, which is the
commercial use that right-of-publicity claims are actually about. The
intended answer is that the creator adds the face in TikTok, where the
tool really is neutral — which also performs better, because content
that looks made in TikTok beats content that looks exported from an app.
The 9:16 template leaves the celebrity side as a glyph disc for exactly
this reason.

### The reveal makes you wait, on purpose

`MatchComputing` holds the compatibility screen for ~2.9 s before the
reading opens. The reading is already computed — the ephemeris runs in
well under a millisecond — so this is theatre and worth saying so. It
earns its place twice: a number that appears instantly reads as a
lookup, and this is the screen the acquisition plan asks people to film.

Two constraints on it. **The captions name work that actually happens** —
placing the planets, reading Venus and Mars, measuring the angles,
weighing six facets — because inventing steps here would be the same
lie as inventing a score, just prettier. And **it runs once per match**:
`_opened` is decided from `revealedIds` on the first build, before
`_persistIfNeeded` writes the id, since that is the only moment a first
reveal can be told from a revisit. Re-reading your own result is not a
reveal and should not cost three seconds.

### The reveal exports as a four-frame carousel

`features/compatibility/.../carousel/` renders the match as four 9:16
frames and hands all four to the share sheet at once. Cover, then the
hexagon, then the directional split, then the verdict — and the order is
the argument. The cover has to be legible as a thumbnail an inch tall,
and the split is on frame three because it is the only claim in this app
that is about a *person*, which is what gets defended in a comment.

**The share is deliberately not gated.** An earlier design traded the
reveal for a social post. Three reasons it is not built that way: the
platform only reports that an app was picked, never that anything was
posted (see `ShareController.shareInvite`), so the gate is unenforceable;
requiring a public post to unlock functionality is the shape of thing
App Review rejects; and the export *is* the acquisition channel, so
charging friction for it taxes the only growth this product has. The
gate stays where it already works — the second reading.

Four things about the implementation are load-bearing:

- **The canvas is 360x640 logical, captured at 4x → 1440x2560.** Laying
  it out at full pixel size would mean a parallel "but four times
  bigger" value for every token in the design system, and the first one
  anybody forgot would be invisible until it was in a stranger's feed.
  3x was the first choice and came back visibly soft next to the single
  card: TikTok draws the image wider than the screen to fill a 20:9
  phone, so a 1080-wide file is upscaled ~8% *before* its own
  recompression, and fine serif type on a dark gradient is the worst
  case for that. Frames are ~1.5 MB each and deleted after the share.
- **The preview must not constrain the slide.** A `SizedBox` is clamped
  by its constraints, so a slide previewed inside a viewport shorter
  than 640 lays out at the *viewport's* height and the capture writes
  that to disk. This shipped once as 1080x1689 files that looked perfect
  on screen. `FittedBox` lays its child out unbounded; `Transform.scale`
  does not. `story_slide_test.dart` pins it from a deliberately cramped
  parent — the first version of that test gave the slide room and
  therefore passed against the bug.
- **The gutters are measured, not guessed.** Posted to TikTok on a Pixel
  6 and read off the result: the caption/username/sound block covers the
  bottom **16.8%**, the action rail the right **15%**, and on a 20:9
  screen TikTok *crops 3.6% off each side* to fill. The first version
  reserved 14.4% and 8.9% and both were short — the facet pills landed
  under "Add 1st" and the closing quote ran beneath the like button.
  `railGutter` is applied to both sides so the composition stays centred,
  because the same file goes to Instagram Stories where the overlays sit
  somewhere else. `story_slide_test.dart` asserts the three fractions.
- **Rows inside a slide must not carry fixed widths.** The safe-zone fix
  narrowed the content column from 296 to 252 and every hard-coded
  `SizedBox(width:)` in the slides overflowed at once. They are
  `Expanded` now, and the hexagon takes `StorySlide.contentWidth`.
- **Content scales rather than overflows.** Copy length is not fixed —
  a longer directional line, or any translation — and on this canvas an
  overflow is not a debug stripe, it is a clipped sentence in a
  published post.

`CarouselCaption` composes the caption in `domain/`, leading with the
split rather than the score for the reason above, and falling back to
the share line when `isBalanced` says the model has nothing worth
claiming. A "Copy caption" button sits beside the share because Android
receivers routinely ignore `EXTRA_TEXT`.

### Background audio via audio_service, and `moveTaskToBack`

Playback runs in an Android foreground service / iOS audio background
mode, with lock-screen controls. `MainActivity` extends
`AudioServiceActivity` — with a plain `FlutterActivity` the service
spawns a second headless engine and the UI talks to a different handler
than the one holding the player.

"Leave" in the exit dialog calls a small `moveTaskToBack` platform
channel rather than `SystemNavigator.pop()`, because `pop()` calls
`finish()`, which destroys the activity and its Flutter engine — taking
the audio handler and player with it, i.e. silently killing the session
the dialog just promised would continue.

**Unresolved:** `androidNotificationOngoing: true` was set to make the
notification non-swipeable while playing. The owner reports it is still
swipeable on Android 16. Android 14 made ongoing notifications
user-dismissible, so that flag likely cannot deliver this any more. This
was **not verified against the audio_service source** — treat it as an
open question, not a fact. The safety net is in place regardless:
`onNotificationDeleted()` routes to `stopSession()`, which fades out.

### RevenueCat, without its paywall

`RevenueCatSubscriptionRepository` implements `BillingRepository` — the
marker interface that is both halves of billing — and one provider picks
it. That is the whole migration, exactly as the seam promised.

**`purchases_ui_flutter` was rejected, and not on taste.** RevenueCat
Paywalls and Customer Center require `MainActivity` to subclass
`FlutterFragmentActivity`; ours subclasses `AudioServiceActivity`, which
extends `FlutterActivity`. Changing it is the thing that gives audio a
second headless engine. The escape hatch is real if it is ever needed —
`AudioServiceActivity` is fourteen lines whose only job is one
`provideFlutterEngine` override, and `AudioServicePlugin.getFlutterEngine`
is `public static`, so a `FlutterFragmentActivity` subclass could do the
same thing — but it means maintaining a copy of a third-party class.

The product reason is stronger than the technical one: a remote paywall
template cannot read a local quiz answer, and personalising the headline
from the quiz is the highest-value conversion work left. `PaywallTrigger`
stays ours either way; RevenueCat has no equivalent of earned moments
with exponential backoff.

**The user is never identified.** `configure` passes no `appUserID`, so
RevenueCat generates an anonymous one, and that is the only reason the
privacy sentence survives having a payment vendor. `Purchases.logIn` with
anything derived from the quiz would break the one claim this product is
differentiated on.

**Prices are never computed here.** `priceString` and
`pricePerMonthString` come from the store already localised;
`displayPricePerMonth` is nullable because not every product has one, and
the paywall omits the line rather than dividing and formatting a
currency itself. Only `savingsPercent` is calculated, because a ratio of
two prices in one currency is not a currency.

**Lifetime is modelled but not sold.** `BillingPeriod.lifetime` exists so
the repository does not silently drop a configured product, and the
paywall filters it out. A one-off offer is now a screen to write, not a
data migration. `PackageType.weekly` is deliberately unmapped — highest
refund rate in the category — so adding one in the dashboard will not
make it appear in the app.

**Cancelling is not a failure.** `purchaseCancelledError` returns `Ok`.
Left to `Result.guard` it would reach Sentry as a handled failure and
show the user an error for a decision they made on purpose.

### The three RevenueCat layers, and which one empties a paywall

Products, entitlements and offerings are separate, and only one of them
feeds the paywall. This cost an evening:

* **Products** are what the store sells (`sanctum_premium:monthly`).
* **Entitlements** decide what is unlocked *after* a purchase. Ours is
  `Sanctum Pro` — a space and two capitals, verbatim, because the SDK
  matches on the identifier and a mismatch leaves `entitlements.active`
  simply empty, with nothing thrown and nothing logged.
* **Offerings** are what `plans()` reads. A package holds one product
  *per store*, so `$rc_monthly` can carry the Test Store product and the
  Play product at once and the SDK serves whichever matches the API key.

The failure that looks like a bug: products created, entitlement
attached, and the offering still holding only Test Store products. A
Play-keyed build then finds nothing and the paywall is empty, while the
dashboard looks complete. The SDK does say so —
`ConfigurationError: ...no Play Store products registered ... for your
offerings` — so read logcat for `[Purchases]` before touching code.

`plans()` now surfaces its own `StateError` text rather than collapsing
everything into one message, so the screen names which of the two
mistakes it is.

### The relationship report deepens a reading, it never recomputes one

`ReportComposer` takes an already-composed `CompatibilityMatch` and
copies every score out of it. Recomputing from the two birth dates would
be a line shorter and would let the paid document disagree with the free
reveal the user is looking at — a 77 on the dial and a 78 in the thing
they bought — which is the fastest available way to make every number in
the app look invented. A test asserts the equality across all 144
pairings.

What it sells is depth, not horizon. `roadmap.md` §1 rejects the
category's ten-year-forecast shape, and this composer has nowhere to put
one: `watchFor` names the fault line and the conditions it shows up
under, never a date.

`Aspects.contact` is the descriptive layer beside the harmonic scoring,
not a replacement. `heat`/`ease` stay continuous because that is right
for a number and wrong for a sentence — nobody wants to read "your Venus
is 0.41 heat to their Mars", they want to read that it is square, and by
how much. Orbs here reintroduce none of the flat-with-spikes
distribution the scoring model avoids, because nothing here feeds a
number.

Two thresholds were measured across 47,961 pairings rather than guessed:
facet bands land 42/28/30 high/mid/low, near-uniform across all six
axes, and direction leans come out symmetric. The same sweep found that
**39.7% of facet sections have no contact in orb at all** — which is why
every contact carries its real separation whether or not it forms a named
aspect. Rendering those as bare "no contact" lines would put an empty
table under a paragraph promising to show its working.

`aspectName*` is a second set of ARB keys for the same enum. `aspect*`
names how a pairing *feels* — "Magnetic", "Charged" — which is right on
a chip under two sun signs and wrong in a column of measured angles. They
also collided: "Charged" was both the square's chip and a score band's
verdict, two lines apart, meaning different things.

### A subscriber's first report is included, and that is not generosity

The compatibility lock card promises Premium "reads you against anyone,
as often as you like". A user who buys on that promise lands on the
reading they just paid for and finds a second price at the foot of it,
seconds later, on the same screen — and the locked report's own copy
said "Yours to keep — no subscription", which to somebody who subscribed
ninety seconds ago reads as a taunt. That is a bait and switch whatever
the SKU's merits, and freshly-converted subscribers are both the most
alert to it and the most likely to refund.

One included report removes that moment and keeps the revenue line: the
*second* report a subscriber wants is still sold, and by then the ask
reads as "you have had one" rather than "you just paid".

**Once ever, not once per period.** A renewing allowance is a credit
ledger — balances, expiry, refunds, second devices — which `roadmap.md`
§1 rejects explicitly. The storage is a single nullable id rather than a
count precisely because there is exactly one, and the copy says "your
first report is included" rather than naming a rate, so becoming more
generous later never means taking something away.

The experiment survives it: the offer appears on any *revealed* reading,
including the one a non-subscriber unlocks with an invite, so the
price-elasticity question is still answered where nearly all the traffic
is.

Three smaller decisions inside it. The claim is **explicit**, not granted
on open — it is the only one they get, and spending it silently on a
pairing tapped out of curiosity is a worse surprise than one extra tap.
A claimed report **survives a lapsed subscription**, because rule one of
the gate is that owned stays owned and clawing back a document somebody
has read is what produces refunds. And it is recorded as the *pairing's
id*, not a boolean, so "what do they own" stays one question and a
claimed report can be told from a bought one in the data —
`report_unlocked` carries `access: purchase | included` for exactly that
reason, and a claim must never reach `purchase_completed`.

### Receipts do not share a store with match history

`PreferencesCompatibilityRepository` catches a decode failure and returns
an *empty* state, on the stated reasoning that losing old matches on an
upgrade is a small cost. That is right for match history and wrong for
receipts: a match is four taps to recompute, a document somebody paid for
is a refund and a support email. So purchases live under their own
preferences key as a flat list of ids that no model change can
invalidate, and — unlike the match blob — a *read* failure there is
surfaced rather than swallowed, because reading "owns nothing" would
offer to re-sell something already bought.

**Consumables do not restore.** A reinstall loses every purchased report,
and the locked screen says so before the money changes hands. That is the
honest minimum, not a solution: the alternatives are a backend mapping
customers to pairings, or granting on request.

### `purchase` returns whether it purchased

`RevenueCatSubscriptionRepository` maps a cancelled store sheet to a
*success* result, so that backing out is not an error and does not reach
Sentry. That is correct. It also returned `Result<void>`, so the paywall
read "no error" as a sale — three bugs in one line:

- `purchase_completed` fired on every cancellation, inflating the only
  conversion number the business has;
- the screen flashed its purchased state and closed on somebody who had
  just declined;
- `_purchased` suppresses the dismissal, so a cancellation recorded
  none — `PaywallTrigger`'s 3 → 7 → 14 → 30 day backoff never advanced,
  and `paywall_dismissed` under-counted.

Both purchase paths now return `Result<bool>` where the bool is whether
they bought. A cancellation leaves the user on the paywall with their
plan still selected, which is where backing out of a store sheet should
land. Data collected before 2026-09-04 is wrong in both directions — see
`analytics.md` §5.

### Providers that outlive the screen that started them

`ref.read(someProvider.notifier).method()` registers **no listener**, so
an auto-disposing provider is collected at the end of the frame while an
async method is still awaiting. It then resumes on a dead `Ref` and
throws *Cannot use the Ref of … after it has been disposed*. This shipped
in the language picker and crashed on Android; iOS was winning the same
race by luck.

Two different fixes, and the difference matters:

- **`LanguageController` is `keepAlive`.** Guarding it with `ref.mounted`
  would stop the crash and silently skip the invalidate, leaving the
  preference saved and the app still in the old language — the failure
  mode hardest to report. The work has to outlive the screen, so the
  provider does.
- **The purchase controllers read every dependency before the first
  await.** A store sheet can outlive the screen that opened it, and
  `ref.read` on the far side would throw exactly where the money has
  already moved, losing the grant for a report the user was charged for.
  `state` and `invalidateSelf` are guarded with `ref.mounted` on the
  reverse principle: skipping a UI update for a screen that is gone is
  correct, skipping a receipt never is.

### The language picker, and the one seam it uses

`contentLocaleProvider`'s doc comment already called itself "the seam an
in-app language picker would use if one is ever added", and that is
exactly what happened. A stored language *code* — not a `Locale`, so the
repository stays free of `dart:ui` — feeds that one provider, and both
trees resolve from it. `MaterialApp` now gets an explicit `locale` from
the same source, because letting Flutter resolve the widget tree from the
platform while the JSON resolved from a preference is precisely the
disagreement `SanctumLocales` exists to prevent.

Null is a real answer and the default: following the device is what most
people want, and a stored value silently stops tracking a phone whose
language changed. `app.dart` holds the first frame until the preference
lands, alongside the onboarding answer, so nothing renders in one
language and swaps a frame later.

Changing it invalidates the preference, and the catalogue chain re-runs
from the asset read — the content catalogue is a *cached future* over an
asset bundle and would otherwise keep serving the old language's JSON
under new ARB chrome.

**Saved readings are recomposed, not replayed.** The prose is derived
data: the same two birth dates and the same copy book always compose the
same reading. It is persisted so the tab can list matches without
recomputing them, but the stored *words* are not the source of truth —
the two people are. `createdAt` is passed back in as `now` so the date
stays what the user first saw, and every score is a pure function of the
two charts, so nothing else can move. Without this a Ukrainian reader
changed language and found their own history still in English.

`verdictFor` returns bare English strings from `domain/`, which cannot
reach `AppLocalizations` — so "Charged" and "Hard-won" rendered inside
Russian sentences on the dial, the share card, the carousel and the
report subtitle. `verdictLabel` maps them, keyed off `verdictFor`'s own
output rather than a second switch on the same thresholds.

### A button label had no bound

`SanctumButton` put its `Text` straight into a `Row`, so any label wider
than the button overflowed — latent for *every* button in the app, and
Russian and Ukrainian run 20–30% longer than the English these widths
were eyeballed against. It is `Flexible` with a one-line ellipsis now:
an ugly last resort rather than the plan, but it fails as a truncated
word instead of yellow-and-black stripes across a paywall. The plan is
short labels, which is why the report offer's price moved out of its
button and onto its own line. That button is not a purchase control —
it opens the report screen, where the price sits beside the thing that
reaches the store — so nothing about the move is a compliance question.

### Fonts are bundled, never fetched

`google_fonts` fetches at runtime — font flash, jank, wrong text offline.
Cormorant Garamond and Inter are bundled as variable fonts (one file per
family, weights via `FontVariation`).

A third font, **Noto Sans Symbols**, is bundled purely for the zodiac
glyphs (U+2648–2653). Without it, iOS and Android both render those
through their *emoji* font as coloured tiles. A U+FE0E variation selector
does **not** reliably override this — it was tried and failed. Verify
codepoint coverage before swapping the font: "Noto Sans Symbols **2**",
the obvious-sounding choice, contains zero of the twelve.

---

## 4. Current state

### Works, verified on device

- Onboarding → **quiz** → payoff → app
- Today: daily card (deterministic), live moon phase with drawn
  terminator, affirmation, energy check-in, streak
- Oracle card 3-D flip
- Sound: 9 sessions, synthesised tones, background playback, lock-screen
  controls, notification with transport + seek. Verified on a real Pixel
  6 (Android 16) 2026-08-17 after three stacked bugs — see the gotchas
  for `await player.play()` and the resource shrinker. The check that
  actually settles it is
  `dumpsys activity services com.soulheals.sanctum | grep isForeground`.
- Journal with persistence; 4 moon rituals gated by real moon phase
- Paywall: monthly/yearly, 7-day trial framing, gating, purchase unlocks
- Exit dialog; Android and iOS both build and run
- **Daily transit, retrograde banner, tomorrow tease, energy pattern
  strip and card repeat count** — all on Today, verified 2026-08-16 on
  the iOS 26.1 simulator.
- **Daily reading notifications** — verified 2026-08-19 on a real Pixel
  6: `dumpsys alarm | grep -c "Alarm{.*sanctum"` returns **7**, one
  `RTC_WAKEUP` per day of the horizon at the hour the `rhythm` answer
  chose, each with a `window=+1h` from inexact scheduling. Note that
  **installing or updating the app clears its pending alarms** — they
  are only re-queued the next time it is opened, so a silent morning
  after an update is expected rather than a bug.
- **Compatibility** (`features/compatibility/`) — fourth tab, verified
  2026-08-16 on the iOS 26.1 simulator end to end: manual entry and 46
  celebrities, the invite gate, unlock, persistence, the second-match
  paywall, and the shareable card.
- **Carousel export** (`features/compatibility/.../carousel/`) —
  verified 2026-08-17 on the iOS 26.1 simulator end to end: all four
  frames render, the share sheet reports "Plain Text and 4 Documents",
  and the files on disk are 1440x2560 each. **Verified on TikTok** on a
  real Pixel 6, 2026-08-17: it accepts all four as one photo carousel,
  and it **drops the caption** — `EXTRA_TEXT` does not survive, which is
  what the "Copy caption" button is for. Do not remove it.
  **Instagram is untested.**
- **Payoff screen** (`features/payoff/`) — verified 2026-08-16 on an
  Android device and on the iOS 26.1 simulator. The reading composes
  from the answers, addresses the user by name, and "Share this" puts a
  real 3x capture of the card into the share sheet. iOS labels it "Plain
  Text and 1 Document" because the payload is text *plus* a file; the
  image itself is recognised (Print and Assign to Contact are offered),
  and setting an explicit `image/png` mime type on the `XFile` was tried
  and changed nothing.

- **The advisor** (`features/advisor/`) — verified 2026-09-05 on the
  iPhone 17 Pro simulator end to end against the *scripted* transport:
  the entry cards on a reading and on the report, the Ask tab, the
  suggestion row, streaming, the software keyboard, delete, and a
  transcript surviving a cold app restart.
- **The proxy is deployed and answering.** Verified 2026-09-05 by
  `curl` against the Supabase Edge Function: DeepSeek streams real
  deltas back in our own frame format. **The app has not yet been
  pointed at it** — `ADVISOR_PROXY_URL` is empty in every build, and it
  must stay that way until the consent screen exists (`advisor.md` §8
  step 5).

- **RevenueCat — a real subscription has been bought.** Verified
  2026-08-19 through Play internal testing on a Pixel 6, end to end:
  offering loads with live localised prices, purchase completes,
  entitlement unlocks, restore works. Entitlement identifier is
  **`Sanctum Pro`** — with the space and the capitals, verbatim from the
  dashboard, and pinned by a test because a mismatch fails *silently*.
  **iOS billing has never been run.**
- **Compare two other people** (`PairEntryScreen`) — any two people, not
  just the user and someone. The engine always supported it; it only
  ever received two birth dates.
- **The relationship report** (`roadmap.md` §1) — composed, screened,
  gated and sold. Verified 2026-09-04 on the iOS 26.1 simulator against
  the RevenueCat Test Store: `$3.99` fetched live for
  `sanctum.report.relationship`, all three sheet outcomes correct on
  both purchase paths, the grant surviving a relaunch, and **the same
  product id bought twice in a row** — it must be a consumable, or a
  user could buy exactly one report and then be told they already own
  the item. **Play has not had the same check on a device.**
- **A subscriber's first report is included**, claimed explicitly and
  once, with the second onwards sold. Verified on the simulator end to
  end, including the sequence the feature exists for: second
  compatibility → subscribe → reading → offer, which now shows
  "Included" rather than a price.
- **In-app language picker** (`features/settings/`) — reached from the
  moon on Today. Verified 2026-09-04 on the simulator: choosing Русский
  switched the chrome *and* the readings in the same frame, with no
  restart, and saved readings recomposed rather than staying in the
  language they were revealed in.
- **All four locales are complete.** Zero untranslated ARB strings and
  identical `copy.json` key sets, pinned by
  `test/l10n/content_parity_test.dart`. The report prose in `uk`, `ru`
  and `es` was machine-translated in voice and **has not had a native
  speaker's pass** — worth one before leaning on it commercially, since
  the copy is the product.

### Size, measured

A debug build reads as **~170 MB app + ~93 MB "user data"** on a Pixel 6
and neither number means anything: the debug APK carries an 85 MB
`kernel_blob.bin`, an unstripped 38.8 MB engine and 15 MB of Vulkan
validation layers, and `flutter run` leaves a *second* copy of the kernel
blob in `app_flutter/` for hot reload, which Android files under user
data. The app's real persisted state is **~40 KB**.

The release APK is **30.3 MB** for arm64 (28.8 MB before
RevenueCat), of which ~19 MB is the Flutter
engine plus our AOT code. It was 23.8 MB before
`flutter_local_notifications` (plus Android core-library desugaring),
`posthog_flutter`, and `sentry_flutter` — Sentry's native SDK is the
largest single addition at roughly 3.8 MB. Full breakdown and the commands to reproduce it
are in `device-testing.md`.

### Stubbed or missing

- **iOS billing is entirely untested against the real App Store.**
  Android is verified end to end and iOS has now been exercised against
  the RevenueCat **Test Store**, which simulates purchases and
  transacts against nothing. The App Store side still has no `appl_`
  key and no products of its own.
- **The report product is unverified on Play.** It resolves and sells on
  the Test Store; nobody has confirmed on an Android device that
  `sanctum.report.relationship` can be bought *twice*, which is the one
  thing a repeatable one-off has to do.
- **No golden tests** (`alchemist` is installed, none written).
- **No launcher icon of your own** — the current crescent mark is a
  placeholder generated in-repo.
- **Four locales ship: English, Ukrainian, Russian, Spanish.** Waves 0-2
  landed 2026-08-31 — see §3; the report and settings copy followed
  2026-09-04. 292 ARB keys and 237 content keys per locale. Both bundled
  fonts already cover Cyrillic and the Spanish diacritics, so there was
  no font work. All three translations were verified on device.
- **The report prose has had no native review in any locale.** The 58
  `report.*` paragraphs were translated in voice but not by a speaker,
  and unlike a button label a mistranslated reading is a worse product
  rather than a bug. `es` has had no native review at all — see below.
- **`es` has had no native review.** uk and ru are being checked by the
  owner, who speaks both. Nobody on the team reads Spanish, so that
  locale rests on the checks in §3 and on device screenshots — which
  catch grammar, layout and duplication, but not whether a line is
  *funny* or lands the way the English does. Worth one native pass
  before it fronts any paid acquisition.
- **Celebrity search does not match Cyrillic.** Names are stored in
  Latin, so a Ukrainian user typing «Тейлор» finds nothing. Either
  transliterate the 141 names per locale or match on a folded
  alias list.
- **No "For entertainment purposes only" disclaimer** outside the payoff
  screen. Nebula shows it at first launch; store review for divination
  content generally expects it.

---

## 5. What to do next

**Product and revenue priorities now live in `.claude/roadmap.md`**,
ordered by expected revenue per week of work. The short version: the
advisor sold as credits is the only item that changes the shape of the
revenue curve; paywall personalisation and a price test are the cheap
conversion work to do first; and posting twenty videos remains the
riskiest untested assumption and costs nothing.

**The advisor is mid-build.** `.claude/advisor.md` §8 is the running
order and says exactly what is done. Steps 1–6 are built; the proxy is
deployed and answering; the consent screen exists and gates the feature
twice. What is left, in the order it should happen:

1. **Finish the paperwork the consent screen ships with.**
   `docs/privacy-policy.md` and `docs/store-data-safety.md` are written
   from what the code does and are three things short of publishable:
   counsel on the DeepSeek transfer — the vendor processes in China, so
   an EU user's request is an international transfer needing a
   mechanism — the publisher's placeholders, and a hosted URL. **No
   release build may compile `ADVISOR_PROXY_URL` until they are done.**
   The screen makes the feature honest; the policy makes it lawful, and
   they are not the same job.
2. **Entitlement on the proxy.** A message is spent client-side today;
   the function's only gate is a rate limit keyed on a header the client
   chooses. A RevenueCat webhook into a Supabase table plus a balance
   check closes it, and is the first infrastructure astrologer chat
   needs anyway.
3. **Advisor analytics.** There are currently *zero* events for the
   feature, and the consent screen has just added the two most worth
   having: it was offered, and it was answered which way. Add them with
   their call sites in the same commit — `analytics.md` records six
   declared events that fire from nowhere, and this is how that
   happens.
4. **Triggers and notifications** (§8 step 7) — the "You + Alex → why
   does he not care?" nudge. `ReminderService` and `PaywallTrigger`'s
   backoff discipline are both there to copy. Note that a trigger must
   read `advisorConsentProvider` before it fires: nudging somebody who
   declined toward the feature they declined is the worst version of
   this mechanic.

What stays here is the engineering debt that is cheaper to fix now than
later, none of which is on the revenue path:

0. **Reopening a saved *pair* reading loses the first person.**
   `_SavedMatchTile` pushes `MatchResultRoute` with `match.them` only, so
   a stored "Taylor and Doja" reading reopens as "you and Doja". Found
   2026-08-31, pre-existing, not fixed. It is the same root cause as the
   item below: the route cannot express a reading the user is not in.
1. **Replace `MatchResultRoute`'s query parameters with an opaque id.**
   It carries `name` and `birth`. Both PostHog's and Sentry's navigation
   observers are disabled specifically because of it, and `_scrub`
   patches breadcrumbs after the fact — the real fix is to stop putting
   a partner's name and birth date in a URL at all. Until then, any new
   observability tool has to be audited for it.
2. **Add the entertainment disclaimer to first launch.** It is on the
   payoff screen and the carousel's closing frame, nowhere else.
3. **Replace the placeholder launcher icon.**
4. **Run the billing integration on iOS against the real App Store.**
   The Test Store now covers the code path, but it simulates purchases
   and transacts against nothing; there is still no `appl_` key and no
   App Store products.
5. **Confirm the report sells twice on Play.** It is a consumable, and a
   non-consumable there would let a user buy exactly one report and then
   be told they already own the item. Verified on the Test Store, never
   on an Android device.
6. **Golden tests.** `alchemist` is installed and unused. The carousel
   frames are the obvious first subject, since they are the one surface
   whose output is published and cannot be corrected after the fact.

---

## 6. Open questions

- Does `androidNotificationOngoing` still do anything on Android 14+? If
  not, what is the intended behaviour when a user dismisses the media
  notification mid-session?
- Two apps: which second vertical, and does it share this question
  catalogue or get its own?
- Real guided-meditation audio: the catalogue is designed to absorb it,
  but none exists. Synthesised tones are the current content.
- Pricing: £6.99/mo and £39.99/yr shipped to Play as-is and have never
  been tested against anything. RevenueCat Experiments can serve
  alternatives with no app update — see the roadmap.
- Instagram: does a four-image share reach Stories as four cards, or does
  Instagram take only the first? 9:16 *is* the Story format so the
  frames need no change there — but IG **feed** carousels cap at 4:5
  (1080x1350), so feed reach would need a second aspect on `StorySlide`.
  Worth building only once TikTok has shown the format moves.

---

## 7. Gotchas that will waste your time

- **The resource shrinker strips anything only Dart refers to, and only
  in release.** R8 walks Java, Kotlin and XML to decide what is
  reachable; it cannot read a Dart string. Two casualties, both in the
  audio feature, both invisible in debug:

  * `ic_notification`, from `androidNotificationIcon:` in bootstrap.
  * **`audio_service_play_arrow` / `_pause` / `_stop`** — the plugin's
    *own* transport icons, named by `MediaControl.play`/`pause`/`stop`.
    These are easiest to miss because they are not this app's files.

  The second set is the damaging one, and it fails in a way that looks
  like nothing: `AudioService.setState` throws
  `IllegalArgumentException: You must specify an icon resource id to
  build a CustomAction` **before** reaching
  `if (!wasPlaying && playing) enterPlayingState()`, so the foreground
  service is never started. Audio plays, the UI updates correctly, and
  there is simply no notification — the exception goes to `System.err`
  only, once per state broadcast (every 250 ms here, which is what makes
  it findable in logcat).

  `android/app/src/main/res/raw/keep.xml` pins both, with a wildcard on
  `audio_service_*` so adding a skip or rewind control later cannot
  reintroduce it. **Any future resource named only from Dart goes
  there.** Verify a build before shipping:

  ```bash
  for n in ic_notification audio_service_play_arrow audio_service_pause; do
    echo "$n: $($ANDROID_HOME/build-tools/<ver>/aapt2 dump resources \
      build/app/outputs/flutter-apk/app-release.apk | grep -c drawable/$n)"
  done
  ```

  Confirmed fixed on a Pixel 6, Android 16: `isForeground=true`,
  `types=0x2` (mediaPlayback), notification on channel
  `com.soulheals.sanctum.audio`, and tapping it lands on the player.

  Worth remembering *how* this went: there were three independent bugs
  behind one symptom — the `await player.play()` deadlock below, then
  `ic_notification`, then the transport icons. Each fix was necessary
  and none was sufficient, and after each one it was tempting to declare
  victory. "I found *a* cause" is not "I found *the* cause"; the only
  reliable check was `dumpsys activity services | grep isForeground`.
- **The media notification's destination is decided at the app root.**
  `AudioService.notificationClicked` is listened to in `SanctumApp`, not
  on the player screen — the notification is tappable exactly when the
  app is backgrounded and no sound screen is mounted, so a listener
  living on the player would be disposed precisely when it was needed.
  Navigation is deferred a frame because the stream is a seeded
  `BehaviorSubject` and can replay a tap during `initState`.
- **`await player.play()` never returns on a looping source.** just_audio
  documents it: the future "completes when the playback completes or is
  paused or stopped". `ToneAudioSource` loops with `LoopMode.one`, so
  awaiting it in `SanctumAudioHandler.start` blocked forever and the two
  lines after it never ran. One missing `unawaited` produced four
  symptoms at once — no media notification, dead transport buttons, no
  position updates, and `start()` itself never completing — while audio
  played out of the speakers the whole time, which made it look like a
  UI bug. `play()` publishes `playing: true` synchronously before its
  first internal await, so not awaiting it is safe and `_broadcast()`
  immediately after still reports the right state. This was in the
  first commit; it is not a regression from anything recent.
- **audio_service enters the foreground off `playbackState.playing`.**
  If that flag never goes true there is no notification and no
  lock-screen control, and `dumpsys activity services` shows the service
  *started but not foreground* — which is the fastest way to tell this
  apart from a permissions problem. `POST_NOTIFICATIONS` being granted
  does not help if nothing ever asks to be foregrounded.
- **`dart run build_runner build` now takes ~100 s.** It is not hung.
- **Riverpod 3 removed `AsyncValue.valueOrNull`.** Use `.value` (it is
  nullable). This bit twice.
- **Generated `@riverpod` providers are auto-dispose.** Calling
  `ref.read(provider.notifier)` without also watching it creates the
  notifier with no listeners, so Riverpod disposes it immediately and the
  next `ref.read` inside an async action throws `UnmountedRefException` —
  the button looks alive and does nothing. `ref.watch(provider)` in
  `build` keeps it alive.

  **This has now shipped four times.** The fourth was
  `paywallDecisionProvider`, found 2026-08-31 by reading a debug console:
  `PaywallPresenter` reaches it once on launch through
  `ref.read(...future)` and never watches it, so the chain was collected
  before `streakProvider` — a Drift stream — delivered its first row.
  The await then completed with `Bad state: the provider
  streakProvider(...) was disposed during loading state`, and the
  automatic paywall never appeared. Fixed at the call site with
  `ref.listenManual`, held across the await, rather than with keepAlive:
  `streakProvider` is a per-date family and pinning it for the app's
  lifetime is wrong, which `riverpod_lint`'s
  `only_use_keep_alive_inside_keep_alive` says out loud if you try.

  The third was `ReminderController`: both callers are fire-and-forget —
  the shell on launch, the payoff screen for permission — so neither ever
  watched it, and daily reading notifications were silently never
  scheduled.
  `dumpsys alarm | grep -ci sanctum` returned 0 on a device that was
  onboarded, had a birth date and had granted POST_NOTIFICATIONS, with
  no error anywhere — because the `UnmountedRefException` goes to
  `ConsoleLogger`, which writes to the VM service and *not* to logcat.
  It is now `@Riverpod(keepAlive: true)`.

  The rule worth internalising: **a provider whose methods are only ever
  reached through `ref.read(...notifier)` must be keepAlive.** If no
  widget watches it, auto-dispose kills it before its own async body
  finishes. Checking a scheduling feature is one command:
  `adb shell dumpsys alarm | grep -ci sanctum`.
- **`QuizFlow.next` counts a multi-select question as answered the
  moment the first option lands**, because `QuizAnswers.has` is just
  "is there a non-empty selection". Ticking one box therefore used to
  auto-advance both multi-select steps. The controller's cursor is what
  holds the screen: `QuizController.toggle` pins it to the question and
  only `advance()` releases it. Anything that writes a multi-select
  answer must go through `toggle`, not `choose`.
- **`AsyncValue.when` shows a spinner when a *dependency* changes.**
  `skipLoadingOnRefresh` defaults to `true`, so an explicit refresh
  keeps rendering the old data — but `skipLoadingOnReload` defaults to
  **`false`**, and a Drift stream emitting after a write is a *reload*.
  The effect: tapping the daily card or logging energy swapped the whole
  `ListView` for a `CircularProgressIndicator` for a frame, which
  destroyed the `Scrollable` and rebuilt it at offset zero — the list
  jumped to the top on every tap. Every `when` in `features/` now passes
  `skipLoadingOnReload: true`. A screen that already has content should
  never flash a spinner because a stream ticked.
- **In `BranchSwitcher`, `TickerMode` must sit *inside* the animated
  widgets.** With it outside, switching tabs disables the ticker on the
  very frame the outgoing branch starts leaving, which freezes the
  `AnimatedOpacity` driving its own fade-out. The branch stops at
  whatever opacity it reached and stays there, permanently painted over
  the incoming one. This does not fail a widget test; it looks like a
  stuck screen on a device, and it is how it was found.
- **A RevenueCat Test Store key crashes a release build, on purpose.**
  The SDK launches its own `SimulatedStoreErrorDialogActivity` and throws
  from `onPause`: *"Test Store API key used in release build."* Their
  reasoning is sound — an app submitted with a test key is rejected in
  review — but this repo builds release APKs to test on real hardware,
  so `configure` skips the SDK entirely when it holds a `test_` key in
  release mode. The app then runs with billing dead rather than not
  running at all, and every path fails closed to `free`. **Purchases can
  only be exercised in a debug build** until real platform keys exist.
- **`flutter pub add sentry_flutter` resolves 8.14.2, which does not
  compile.** Its Swift plugin calls `SentryBinaryImageCache.image`,
  which the native SDK that Swift Package Manager resolves no longer
  has, and the iOS build fails. Ask for `^9.27.0` explicitly. Sentry 9
  also deprecates `SentryEvent.copyWith` in favour of mutating the
  instance, which is what `_scrub` does.
- **A Gradle failure with a full disk looks like an AGP problem.** A
  build that ran out of space reported "Starting AGP 9+, only the new
  DSL interface will be read" — a Flutter Fix box pattern-matched onto
  unrelated output. `android.newDsl=false` was already set and AGP was
  never the cause. Check free space before believing that message.
- **A `part` file only sees its owning library's imports.** Drift's
  generated code needed `JournalKind` imported into
  `sanctum_database.dart` even though `tables.dart` already had it.
- **Drift row classes are renamed with a `Row` suffix**
  (`@DataClassName`), because `JournalEntries` would otherwise generate
  `JournalEntry` and collide with the domain model. Rows must never
  escape the data layer.
- **`test/analysis_options.yaml` relaxes one rule** —
  `avoid_redundant_argument_values` — so dates can be written
  `DateTime(2026, 1, 1)` instead of `DateTime(2026)`.
- The repo holds `dart analyze --fatal-infos` clean. Keep it there.
