# Sanctum

A spiritual-wellness app for iOS and Android. A daily reading computed
from the user's own birth chart, compatibility readings between the user
and anyone — or between any two other people, including a catalogue of
141 public figures — that export as a four-frame 9:16 carousel for
TikTok and Reels, a deep "You & X" relationship report sold as a one-off,
live moon phase, an oracle card, sound-bath sessions, moon rituals, a
journal, and an AI astrologer that answers from the same computed
positions the rest of the app is built on — with a personalising
onboarding quiz, a subscription paywall, and four languages the reader
can switch between in the app.

**There is no account.** Every reading — the daily transit,
compatibility, moon phase, the oracle draw — is computed on the device
from bundled content and orbital mechanics, and works offline.

There is one backend: a stateless Supabase Edge Function proxying the
advisor to DeepSeek, because a model API key cannot ship in a binary. It
stores nothing and holds no user record — see `proxy/README.md`. It is
deployed, and the app does not call it in any current build: no build
compiles `ADVISOR_PROXY_URL`.

**The advisor sends nothing until the user agrees to a screen that says
what it sends**, who receives it and how long it is kept. That gate is
enforced twice — the conversation screen shows the disclosure instead of
a composer, and the transport provider will not build a proxy transport
without a granted consent — and the drafts of the privacy policy and the
two store data-safety declarations are in `docs/`.

Everything else on the network is telemetry and billing: anonymous
product analytics (PostHog), crash reporting (Sentry) and subscription
status (RevenueCat, with anonymous app user IDs). None of them carries a
name, a birth date, or journal text.

The advisor sends computed positions — longitudes, aspects, scores — and
the question. Never a name: `AdvisorContext` has no field that could
hold one, `MessageRedaction` rewrites the ones a user types, and the
proxy rejects them a third time. See `.claude/advisor.md` §1 for why
that is three layers rather than one.

```bash
flutter pub get
dart run build_runner build      # required: much of the app is generated
flutter run
```

Useful flags:

```bash
# Time travel — almost every screen is a function of the date.
flutter run --dart-define=SANCTUM_FAKE_DATE=2026-08-28
```

## Architecture

Flutter's official MVVM guidance (View → ViewModel → Repository → Service)
over a feature-first layout. One rule holds it together:

> **`features/` → `domain/` ← `data/`.** `domain/` imports nothing but
> pure Dart — no Flutter, no Drift, no audio packages. A widget never
> touches a database row or a player directly.

That single constraint is why the business logic is testable in
milliseconds and why storage or audio can be swapped without opening a
widget file.

```
lib/src/
├── core/            Result<T>, Clock, Logger, analytics, crash
│                    reporting, platform channels
├── domain/          PURE DART — models + services, zero Flutter imports
│   ├── models/      quiz, reading, moon, transit, compatibility,
│   │                planet, streak, subscription, conversation,
│   │                advisor context…
│   └── services/    ephemeris (Sun/Mercury/Venus/Mars/Jupiter/Saturn),
│                    transits, aspects, compatibility, moon phase,
│                    energy patterns, reminders, daily selection,
│                    streaks, paywall trigger, reading composer,
│                    chat transport, message budget, redaction
├── data/            Drift database, repositories, content catalogue,
│                    audio handler. The only layer that knows about I/O.
├── design_system/   tokens → theme → effects → atoms (aurora shader,
│                    starfield, glass). No hard-coded colours anywhere.
├── features/        one folder per feature: view/ + view_model/
├── l10n/            ARB files, context.l10n, and the one locale list
│                    both the widget tree and the asset bundle resolve
│                    through
└── routing/         go_router typed routes

proxy/               the one backend: a Supabase Edge Function that
                     proxies the advisor to DeepSeek. Stateless.
```

**Patterns used throughout**

- **`Result<T>`** — sealed, with `Ok`/`Err`. Repositories return it and
  never throw; the compiler forces callers to handle failure. It converts
  to `AsyncValue` at the Riverpod boundary, not before.
- **Injected `Clock`** — "today" is a dependency, so date-driven logic is
  testable at any date instead of depending on when CI runs.
- **ViewModel = Riverpod `Notifier` + immutable UI state.** Views read
  state and call methods; they hold no logic.
- **Repository as the only seam.** Features depend on interfaces; Drift,
  just_audio and shared_preferences live behind them.

## Testing

```bash
flutter test
dart analyze --fatal-infos      # the bar this repo holds
```

Domain logic is covered heavily because it is pure and cheap to test,
and the assertions are pinned to reality wherever reality exists:

- **Moon phases** against US Naval Observatory timestamps.
- **The ephemeris** against documented events — Saturn at the 2020 great
  conjunction lands 0.03° from 0°29′ Aquarius, Venus' greatest
  elongation within 0.11°, the December solstice exactly on 0° Capricorn
  — plus agreement with the hand-written sun-sign table on every
  non-cusp day across seven decades.
- **The paywall trigger** across a simulated two-year user journey.
- **The quiz flow** for branch resurrection and progress overflow.
- **The analytics taxonomy** for anything that could identify a user —
  a property denylist, a primitives-only check, and a length check that
  would catch prose.
- **The report** against the reading it deepens: every score is copied,
  never recomputed, so the paid document can never disagree with the
  free reveal.
- **The advisor payload** for anything that could identify anybody — a
  denied-key list walked to full depth, a primitives-only check, and an
  assertion that a real match's request contains no substring of either
  person's name.
- **The database migration** by building a version 1 database by hand
  and proving a journal written before the upgrade still reads after it.
- **The proxy transport** against a real HTTP server rather than a mock,
  because what it does is parse a byte stream: a frame split across
  packets, a Cyrillic character split down the middle, a connection that
  dies mid-answer.
- **Every locale** for key parity and placeholder parity with English.
  Copy falls back per key at runtime, so a missing translation degrades
  silently instead of failing — which is exactly why the gap is asserted
  here instead.

## Docs

- **`.claude/handoff.md`** — full context: why things are the way they
  are, which alternatives were rejected, what is stubbed, and the
  gotchas that will otherwise cost you an afternoon each. Read it before
  changing anything structural.
- **`.claude/roadmap.md`** — what to build next and why, ordered by
  expected revenue per week of work, plus an explicit list of what *not*
  to build.
- **`.claude/device-testing.md`** — running and verifying on real
  hardware: simulator coordinates, resetting onboarding, adb, and where
  the build sizes actually come from.
- **`.claude/analytics.md`** — every event the app emits, what each one
  answers, and the gaps: six declared events fire from nowhere, and the
  advisor emits nothing at all.
- **`.claude/advisor.md`** — the AI advisor: what it sends and what it
  refuses to, the economy, the build order, and what is left before it
  can ship.
- **`proxy/README.md`** — the one backend. How to deploy it, which key
  goes where, and the checklist that must be clear before any release
  build points at it.
- **`docs/privacy-policy.md`** — a pointer to where the published policy
  actually lives (the `morphostudio` repository), and the list of four
  things that have to change together when what leaves the device does.
- **`docs/store-data-safety.md`** — what to enter in both stores' data
  forms and why. It ships with the release that first points a build at
  the proxy, and it has to agree with the published policy and the
  consent screen.
