# Sanctum

A spiritual-wellness app for iOS and Android. A daily reading computed
from the user's own birth chart, compatibility readings against anyone
(or a catalogue of public figures) that export as a four-frame 9:16
carousel for TikTok and Reels, live moon phase, an oracle card,
sound-bath sessions, moon rituals, and a journal — with a personalising
onboarding quiz and a subscription paywall.

**There is no backend and no account.** Every reading — the daily
transit, compatibility, moon phase, the oracle draw — is computed on the
device from bundled content and orbital mechanics, and works offline.

The only network traffic is telemetry: anonymous product analytics
(PostHog) and crash reporting (Sentry). Neither carries a name, a birth
date, or journal text, and the onboarding copy promises exactly that.
See `.claude/handoff.md` for how that promise is enforced in the type
system.

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
│   │                planet, streak, subscription…
│   └── services/    ephemeris (Sun/Mercury/Venus/Mars/Jupiter/Saturn),
│                    transits, aspects, compatibility, moon phase,
│                    energy patterns, reminders, daily selection,
│                    streaks, paywall trigger, reading composer
├── data/            Drift database, repositories, content catalogue,
│                    audio handler. The only layer that knows about I/O.
├── design_system/   tokens → theme → effects → atoms (aurora shader,
│                    starfield, glass). No hard-coded colours anywhere.
├── features/        one folder per feature: view/ + view_model/
└── routing/         go_router typed routes
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
  elongation within 0.1°, the December solstice exactly on 0° Capricorn
  — plus agreement with the hand-written sun-sign table on every
  non-cusp day across seven decades.
- **The paywall trigger** across a simulated two-year user journey.
- **The quiz flow** for branch resurrection and progress overflow.
- **The analytics taxonomy** for anything that could identify a user —
  a property denylist, a primitives-only check, and a length check that
  would catch prose.

## Docs

- **`.claude/handoff.md`** — full context: why things are the way they
  are, which alternatives were rejected, what is stubbed, and what to do
  next. Read it before changing anything structural.
- **`.claude/device-testing.md`** — running and verifying on real
  hardware: simulator coordinates, resetting onboarding, adb, and where
  the build sizes actually come from.
