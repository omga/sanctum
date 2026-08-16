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

### Local-first, no backend

No account, no server, no network in the core loop. The daily card is a
deterministic hash of `(installSalt, localDate)`; the moon phase is
computed. Both work offline and cost nothing to run.

**Rejected:** Supabase/Firebase for v1, and account-creation-before-paywall
(Nebula does this for retargeting; with no retargeting budget it is pure
funnel friction).

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

### The privacy promise, and what it now says

The app used to claim, in three places, that "nothing leaves your
phone". Analytics, RevenueCat and any AI feature all make that false.
The copy is now precise instead of absolute, which is still a strong
claim and has the advantage of being true:

> "No account, ever. Your name, your birth date and your journal stay on
> this phone."

That survives event analytics carrying no PII, and it survives
RevenueCat's anonymous app user IDs. **It does not survive AI chat** —
that would send a user's chart and their question to a third party, and
needs its own explicit consent gate, not a reworded sentence. Design
that in from the start if the advisor gets built.

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

**No celebrity photographs, ever.** A public figure's birth date is a
fact; their likeness is not, and a face beside a compatibility score
implies an endorsement that does not exist. The picker draws an
element-tinted disc with the sign glyph instead, which is also better
looking than a grid of scraped press photos.

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
  controls, notification with transport + seek
- Journal with persistence; 4 moon rituals gated by real moon phase
- Paywall: monthly/yearly, 7-day trial framing, gating, purchase unlocks
- Exit dialog; Android and iOS both build and run
- **Daily transit, retrograde banner, tomorrow tease, energy pattern
  strip and card repeat count** — all on Today, verified 2026-08-16 on
  the iOS 26.1 simulator.
- **Daily reading notifications** — permission prompt verified firing at
  the payoff screen on the simulator, and the schedule call completes
  cleanly. **Delivery itself has not been observed** — the first one is
  due at 08:00 the following day. Watch for it on a real device before
  trusting it.
- **Compatibility** (`features/compatibility/`) — fourth tab, verified
  2026-08-16 on the iOS 26.1 simulator end to end: manual entry and 46
  celebrities, the invite gate, unlock, persistence, the second-match
  paywall, and the shareable card.
- **Payoff screen** (`features/payoff/`) — verified 2026-08-16 on an
  Android device and on the iOS 26.1 simulator. The reading composes
  from the answers, addresses the user by name, and "Share this" puts a
  real 3x capture of the card into the share sheet. iOS labels it "Plain
  Text and 1 Document" because the payload is text *plus* a file; the
  image itself is recognised (Print and Assign to Contact are offered),
  and setting an explicit `image/png` mime type on the `XFile` was tried
  and changed nothing.

### Size, measured

A debug build reads as **~170 MB app + ~93 MB "user data"** on a Pixel 6
and neither number means anything: the debug APK carries an 85 MB
`kernel_blob.bin`, an unstripped 38.8 MB engine and 15 MB of Vulkan
validation layers, and `flutter run` leaves a *second* copy of the kernel
blob in `app_flutter/` for hot reload, which Android files under user
data. The app's real persisted state is **~40 KB**.

The release APK is **28.8 MB** for arm64, of which ~19 MB is the Flutter
engine plus our AOT code. It was 23.8 MB before
`flutter_local_notifications` (plus Android core-library desugaring),
`posthog_flutter`, and `sentry_flutter` — Sentry's native SDK is the
largest single addition at roughly 3.8 MB. Full breakdown and the commands to reproduce it
are in `device-testing.md`.

### Stubbed or missing

- **The 46 celebrity birth dates have not been verified against a
  source.** They are from memory, and the birth date is the single
  factual claim this feature makes about a real person — a wrong one
  shows the wrong sign beside their name. `celebrities.json` needs one
  pass against a reference before launch. Tests check the dates are
  plausible and the ids unique; nothing checks they are *right*.
- **Billing is a local stub.** `LocalSubscriptionRepository` writes a
  bool to preferences. Swapping in RevenueCat is one class implementing
  `SubscriptionRepository` + `EntitlementRepository` and one changed
  provider. Prices are placeholders — real ones must come from the store
  at runtime.
- **Reminder time is collected and never used.** The quiz asks when the
  user wants their reading and nothing schedules it. This is a promise
  the app does not keep. Needs notifications wiring, which means
  re-adding `flutter_local_notifications` *and* Android core-library
  desugaring (it was removed precisely because it was unused and forced
  that).
- **No energy-over-time chart**, though the paywall advertises "insights".
- **No golden tests** (`alchemist` is installed, none written).
- **No launcher icon of your own** — the current crescent mark is a
  placeholder generated in-repo.
- **No localisation** (`flutter-setup-localization` skill is available and
  unused). Needed if non-English markets are pursued.
- **No "For entertainment purposes only" disclaimer** outside the payoff
  screen. Nebula shows it at first launch; store review for divination
  content generally expects it.

---

## 5. Exact next steps

1. **Verify the celebrity birth dates**, then post twenty videos of the
   compatibility flow before building anything else. The riskiest
   assumption is not the feature, it is whether this team can make
   content that moves — and that costs nothing to test.
2. **Replace `MatchResultRoute`'s query parameters with an opaque id.**
   It currently carries `name` and `birth`. Both PostHog's and Sentry's
   navigation observers are disabled specifically because of it, and
   `_scrub` patches breadcrumbs after the fact — but the real fix is to
   stop putting a partner's name and birth date in a URL at all. Until
   then, any new observability tool has to be audited for it.
3. **RevenueCat.** `LocalSubscriptionRepository` is a bool in prefs
   behind `EntitlementRepository`, so it is genuinely a drop-in. Free
   under $2.5k monthly tracked revenue, and its own dashboard covers a
   chunk of subscription analytics.
4. **Localise: Spanish, Russian, French.** Nothing is wired yet — no
   `flutter_localizations`, no ARB files, every string is inline. The
   engineering is routine; the real cost is that this app's value *is*
   its copy. There are roughly forty paragraphs of deliberately literary
   prose across the quiz, readings, compatibility and paywall, and
   machine translation will strip exactly the quality people are being
   asked to pay for. Budget for a human translator per language, and
   treat the reading copy as the expensive part.

   Already designed for: facet names are one short word each, hexagon
   labels sit in fixed-width boxes that wrap to two lines, and no text
   sits in a fixed-width container. Re-check the paywall and the nav bar
   — German-length strings in a four-item glass pill are the next thing
   to break.
9. **Personalise the paywall headline from quiz answers.** The data is
   persisted and `ReadingComposer` already selects copy from it; the
   paywall just doesn't read it yet. Someone who ticked "I keep repeating
   a pattern" should see that sentence back. This is the highest-value
   remaining conversion work.
4. **Wire the reminder time** to real local notifications, or remove the
   question. Shipping it as-is is a broken promise.
5. **Add the entertainment disclaimer** to first launch. It is already on
   the payoff screen and nowhere else.
6. **Replace the placeholder icon** and set up build flavors if the
   two-app experiment is going ahead.
7. Then: 9:16 video export of the reveal, palm scan, RevenueCat, energy insights, golden tests, low-end Android
   profiling.

---

## 6. Open questions

- Does `androidNotificationOngoing` still do anything on Android 14+? If
  not, what is the intended behaviour when a user dismisses the media
  notification mid-session?
- Two apps: which second vertical, and does it share this question
  catalogue or get its own?
- Real guided-meditation audio: the catalogue is designed to absorb it,
  but none exists. Synthesised tones are the current content.
- Pricing: the stub lists £6.99/mo and £39.99/yr as placeholders. Real
  products need creating in App Store Connect / Play Console.

---

## 7. Gotchas that will waste your time

- **`dart run build_runner build` now takes ~100 s.** It is not hung.
- **Riverpod 3 removed `AsyncValue.valueOrNull`.** Use `.value` (it is
  nullable). This bit twice.
- **Generated `@riverpod` providers are auto-dispose.** Calling
  `ref.read(provider.notifier)` without also watching it creates the
  notifier with no listeners, so Riverpod disposes it immediately and the
  next `ref.read` inside an async action throws `UnmountedRefException` —
  the button looks alive and does nothing. `ref.watch(provider)` in
  `build` keeps it alive. This shipped twice before being caught.
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
