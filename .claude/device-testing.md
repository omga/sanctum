# Running and verifying Sanctum on real devices

Companion to `handoff.md`. Everything here was learned the hard way on
a real device or simulator; none of it is guesswork.

---

## 1. iOS Simulator

### Boot, build, launch

The simulator panel cannot attach to a device that is not booted, and the
error says so rather than booting one for you.

```bash
xcrun simctl list devices available
xcrun simctl boot C85E887D-5187-46D9-B1D9-F5512999CC5E
xcrun simctl bootstatus C85E887D-5187-46D9-B1D9-F5512999CC5E -b
```

Boot takes ~35 s on this Mac. Then:

```bash
flutter build ios --simulator --debug
```

and launch `build/ios/iphonesimulator/Runner.app`. A clean build is ~33 s,
an incremental one ~19 s.

Devices installed here: iPhone 17 / 17 Pro / 17 Pro Max / Air / 16e and
the iPad family, on iOS 26.0 and 26.1. Verification was done on **iPhone
17 Pro, iOS 26.1**, `C85E887D-5187-46D9-B1D9-F5512999CC5E`.

### Coordinates — the thing that will waste your afternoon

The iPhone 17 Pro is **402 × 874 points**, and screenshots come back at
**1206 × 2622 pixels** (3x). Taps are in *points*.

Eyeballing a target off the returned screenshot is where this goes wrong:
a tap 20 pt below a button's centre lands outside it and **fails
silently** — no error, no log, nothing on screen changes. Two full
minutes were lost concluding "taps don't reach Flutter" when the real
problem was that the Enter button's centre is y≈782, not the y≈803 that
the image appeared to show.

The reliable method — resample the screenshot to the point width, after
which **image pixel coordinates are tap coordinates, 1:1**:

```bash
xcrun simctl io <udid> screenshot shot.png
sips -s format png --resampleWidth 402 shot.png --out small.png
```

Then read the target's centre straight off `small.png`.

To confirm input works at all before debugging the app, press HOME and
screenshot — SpringBoard reacting proves injection is fine and the
problem is your coordinate.

### Gotchas

- **The keyboard tutorial overlay** ("Speed up your typing by sliding
  your finger…") covers the bottom half of the screen the first time a
  `TextField` takes focus on a fresh simulator. Dismiss its blue
  *Continue* before typing, or every subsequent tap hits the overlay.
- **Re-reaching onboarding needs an uninstall.** `setOnboarded()` fires
  when the quiz completes, *before* the payoff screen renders, so a
  relaunch drops you into Today. Clearing state:
  ```bash
  xcrun simctl uninstall <udid> com.soulheals.sanctum
  ```
- **App logs**, when you need to know whether a touch reached the app:
  ```bash
  xcrun simctl spawn <udid> log stream --level debug --predicate 'processImagePath CONTAINS "Runner"'
  ```
  `UIKit:EventDispatch … Sending UIEvent … to window` means the touch
  arrived and the problem is above the OS layer.

### Verified on iOS specifically

- Zodiac glyphs (U+2648–2653) render as **real symbols, not coloured
  emoji tiles** — the bundled Noto Sans Symbols does its job on iOS as
  well as Android. See `handoff.md` §3 before swapping that font.
- The payoff screen's `share_plus` capture reaches the iOS share sheet as
  a real image. iOS labels it "Plain Text and 1 Document" because the
  payload is text *plus* a file; that is not a bug, and an explicit
  `image/png` mime type on the `XFile` changes nothing (tried, reverted).

---

## 2. Android

### Driving a real Pixel

Two adb entries can appear for one phone (wireless plus TLS pairing), so
plain `adb shell` fails with "more than one device". Use the transport
id from `adb devices -l`:

```bash
adb devices -l
adb -t 1 install -r build/app/outputs/flutter-apk/app-release.apk
adb -t 1 shell am start -n com.soulheals.sanctum/.MainActivity
adb -t 1 logcat -d | grep -iE "sentry|posthog|FATAL|AndroidRuntime"
```

`adb -t 1 shell am crash com.soulheals.sanctum` forces a real JVM crash,
which is how the crash-reporting path was verified end to end.

What a healthy launch looks like in logcat:

- `PostHog: com.posthog.posthog.AUTO_INIT is disabled!` — the Dart-side
  configuration is in charge, as intended.
- `PostHogFlutter: Android onFeatureFlags triggered` — the SDK reached
  the server.
- `libsentry.so` / `libsentry-android.so` loaded — the native crash
  handler is installed.
- `SentryDeviceInf: avc: denied { read } for name="version"` is benign.
  Sentry probes the kernel version, SELinux refuses, it moves on.

**A release build is not debuggable**, so `run-as` will not open its data
directory and the Sentry envelope cache cannot be inspected the way it
can on the simulator. Confirm delivery in the Sentry dashboard instead,
or install a debug build.

### Why the debug build reads as ~170 MB + ~93 MB on a Pixel 6

Measured, not estimated. Both figures are **artefacts of the debug
build** and neither exists in a release build.

| | bytes | what it is |
|---|---|---|
| `app-debug.apk` | 169,645,895 | what Settings calls "App size" |
| `app-release.apk` (arm64) | 28.8 MB | what ships |

Inside the debug APK:

| | size | release equivalent |
|---|---|---|
| `assets/flutter_assets/kernel_blob.bin` | 85 MB | gone — replaced by 7.3 MB AOT `libapp.so` |
| `lib/arm64-v8a/libflutter.so` | 38.8 MB | 11.7 MB (stripped AOT engine) |
| `lib/arm64-v8a/libVkLayer_khronos_validation.so` | 15.2 MB | gone — Vulkan validation layers are debug-only |
| `isolate_snapshot_data` | 11.6 MB | gone |
| `classes*.dex` | ~19 MB | 2.0 MB (R8 runs in release, not debug) |
| `MaterialIcons-Regular.otf` | 1.6 MB | 3.5 KB (tree-shaken to the icons actually used) |

And the "User data: 97 MB" is **not user data**. Measured on device:

```
93M   app_flutter        <- 83 MB kernel_blob.bin + 11 MB isolate_snapshot_data
237K  code_cache
24K   files
12K   shared_prefs
7.0K  cache
3.5K  databases
```

`flutter run` syncs `flutter_assets` into `/data/data/<pkg>/app_flutter/`
so hot reload can swap the kernel without reinstalling — leaving a
**second copy** of the 83 MB kernel blob, which Android's storage screen
attributes to user data. The `res_timestamp-*` marker file beside it is
the tooling's sync stamp.

Sanctum's actual persisted state is **~40 KB**: `sanctum.sqlite` is 24 KB
and `shared_prefs` is 12 KB.

Inspect it yourself:

```bash
adb shell "run-as com.soulheals.sanctum sh -c 'du -sh -- *'"
```

`adb shell dumpsys package com.soulheals.sanctum | grep flags=` shows
`DEBUGGABLE` when a debug build is what is installed.

### Where the 28.8 MB release APK actually goes

| | size |
|---|---|
| `libflutter.so` (engine) | 11.7 MB |
| `libapp.so` (our AOT Dart) | 7.3 MB |
| `libsentry*.so` | ~3.8 MB |
| three variable fonts | 2.4 MB |
| `classes.dex` | 2.0 MB |
| `libsqlite3.so` | 1.7 MB |

~19 MB of that is engine plus AOT code and is the Flutter floor — a
native Android build of the same app would be far smaller, and no amount
of asset work changes it.

The APK was 23.8 MB before observability. `flutter_local_notifications`
(plus Android core-library desugaring) and `posthog_flutter` cost about
1.2 MB between them; Sentry's native SDK is the single largest addition
at roughly 3.8 MB.

The only headroom worth having is the fonts: all three ship with full
charsets, and `NotoSansSymbols-Variable.ttf` is 372 KB to provide
**twelve glyphs**. Subsetting all three to the codepoints actually used
would recover roughly 2 MB. Nothing else in the asset bundle is
significant.

`flutter build appbundle --release` produces a large `.aab`, which
alarms people — it carries every ABI. Play delivers only the matching
split, so a Pixel 6 downloads approximately the arm64 figure above.

**A Gradle failure with a full disk lies to you.** A build that ran out
of space reported `Starting AGP 9+, only the new DSL interface will be
read` — a Flutter Fix box pattern-matched onto unrelated output.
`android.newDsl=false` was already set and AGP was never involved. Check
`df -h /` before believing that message; iOS and Android build outputs
together run to several GB and `build/` is safe to delete.

**Release currently signs with the debug keystore** (`build.gradle.kts`
has the TODO). That must be fixed before any store upload.
