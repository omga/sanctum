# Sanctum

A spiritual-wellness app for iOS and Android. Daily oracle card, live moon
phase, sound-bath sessions, moon rituals, and a journal — with a
personalising onboarding quiz and a subscription paywall.

Everything runs **on device**. There is no backend, no account, and no
network call in the core loop.

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
├── core/            Result<T>, Clock, Logger, platform channels
├── domain/          PURE DART — models + services, zero Flutter imports
│   ├── models/      quiz, reading, moon, streak, subscription…
│   └── services/    moon phase, daily selection, streaks, paywall
│                    trigger, reading composer, fade envelope
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

Domain logic is covered heavily because it is pure and cheap to test —
moon phases are pinned against real US Naval Observatory timestamps, the
paywall trigger is verified across a simulated two-year user journey, and
the quiz flow is tested for branch resurrection and progress overflow.

## Docs

`.claude/handoff.md` — full context: why things are the way they are,
which alternatives were rejected, what is stubbed, and what to do next.
Read it before changing anything structural.
