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

### Built but NOT yet verified on a device

- **Payoff screen** (`features/payoff/`) — the reading, the shareable
  card, and `share_plus` capture at 3x. Compiled and analyzer-clean, but
  the last build/install cycle was cut short. **Test this first.**

### Stubbed or missing

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

1. **Verify the payoff screen on a device.** Build, run through the quiz,
   check the reading composes correctly and that "Share this" produces a
   real image in the share sheet.
2. **Personalise the paywall headline from quiz answers.** The data is
   persisted and `ReadingComposer` already selects copy from it; the
   paywall just doesn't read it yet. Someone who ticked "I keep repeating
   a pattern" should see that sentence back. This is the highest-value
   remaining conversion work.
3. **Wire the reminder time** to real local notifications, or remove the
   question. Shipping it as-is is a broken promise.
4. **Add the entertainment disclaimer** to first launch.
5. **Replace the placeholder icon** and set up build flavors if the
   two-app experiment is going ahead.
6. Then: RevenueCat, energy insights, golden tests, low-end Android
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
