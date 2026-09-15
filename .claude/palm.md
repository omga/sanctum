# Sanctum — the palm scan

Written 2026-09-07. Partly built 2026-09-08 on branch `palm-scan` —
see §10 for what exists and what does not.

**The feature.** Point the camera at your palm; the app finds the hand,
draws your principal lines onto it with an animation worth filming, and
offers a reading. The video is the artifact people post.

---

## 0. The short answers

- **`vision_ai`: no.** It is the wrong shape and the wrong risk. §1.
- **AR libraries: no.** Neither ARKit nor ARCore tracks hands on a
  phone. They are for putting furniture on a floor. §1.
- **Use hand *landmarks*, not "palm reading AI".** 21 points from a
  MediaPipe model via LiteRT. That is the only ML in the feature. §1.
- **Size: ~+8–12 MB**, taking the arm64 release APK from 30.3 MB to the
  high 30s. The 100 MB fear comes from FFmpeg and from bundling full
  MediaPipe on iOS; this plan does neither. §2.
- **Do not record the screen.** Flutter cannot capture a camera preview.
  Capture one still, render the film offscreen. §3 — this is the single
  most important decision in the document.
- **Do not gate the video on a TikTok post.** `handoff.md` already
  rejected that exact mechanic, for reasons that still hold. Sell the
  report instead. §6.
- **A palm scan is hand geometry, which is named biometric data in
  Illinois.** Cheap to get right, expensive to retrofit. §7.

---

## 1. Libraries: what to use, what to refuse

### `vision_ai` — no

Measured on pub.dev 2026-09-07: **2 likes, 53 weekly downloads, 140 pub
points, first published three months ago**, one maintainer. That is not
a dependency to put under a headline feature.

The shape is wrong even if the traction were there:

- It sells **gesture recognition** (thumbs up, peace, fist) and **facial
  emotion**. We need neither. The one useful thing inside it — 21 hand
  landmarks — is the part it treats as an implementation detail.
- It pulls **three ML runtimes**: MediaPipe Tasks, Google ML Kit Face
  Detection, and TFLite. We would ship all three to use one.
- Models live in a second package, `vision_ai_models`, which copies
  `gesture_recognizer.task` and `emotion_classifier.tflite` into app
  storage at runtime. Two packages and a runtime copy step, for
  landmarks we can get directly.

### AR libraries — no, and not for size reasons

**ARKit has no hand tracking on iOS.** Hand tracking is a visionOS API.
**ARCore has no hand tracking either.** Both do plane detection and 6DoF
world tracking so you can stand a 3D object on a table. Neither of them
will find a palm, and `ar_flutter_plugin` / `arcore_flutter_plugin`
inherit that. They are also the heaviest thing we could add. Wrong tool,
not an expensive tool.

The word "AR" is doing damage here. What this feature needs is not a
world-tracking session. It is: *where is the hand, how big, how rotated*
— four numbers and a warp.

### What to use

**`hand_detection`** (`hugo.ml`, verified publisher, v4.1.0, ~1.5k weekly
downloads, Android + iOS + desktop + web, LiteRT runtime, MediaPipe hand
models, 21 landmarks with handedness). It is the only cross-platform
option with a verified publisher and real usage.

The obvious alternative, **`hand_landmarker`**, bundles the MediaPipe
`.task` and is faster to wire up — but it is **Android-only**, which
ends the conversation.

**Escape hatch, and it is a short one.** If `hand_detection` disappoints,
the fallback is `flutter_litert` plus MediaPipe's two `.tflite` files
loaded directly. It is a day of work: the palm detector outputs a rotated
box, the landmark model outputs 21×3. Worth knowing that the floor is
low, because it means this dependency is replaceable rather than
load-bearing.

**Also needed:** `camera` (flutter.dev, BSD-3, iOS 13+/Android 24+ —
both below our iOS 15 target). Preview, image stream, and `takePicture`.

---

## 2. Size, with numbers

Today, from `device-testing.md`: **30.3 MB release APK, arm64**, of which
~19 MB is the Flutter engine plus our AOT code and cannot be moved.

| addition | arm64, pre-compression |
|---|---|
| `camera` | ~0.3–0.5 MB |
| LiteRT native runtime | ~2.7 MB |
| palm detection + hand landmark models | ~4–8 MB |
| video encoder | **0 MB native** — MediaCodec / AVFoundation are OS |
| our Dart, shader, line templates | <0.2 MB |

**≈ +8–12 MB → high 30s MB.** For comparison, Sentry alone cost 3.8 MB.

Two levers if it matters: the **lite** landmark model instead of full
(the full `hand_landmarker.task` bundle is 7.82 MB; the lite variants are
roughly half), and the font subsetting already identified in
`device-testing.md` as ~2 MB of free headroom.

**How this becomes 100 MB, so we do not do it:** `ffmpeg_kit_flutter`
(20–80 MB depending on package, and the project was retired in 2025), or
adding MediaPipe Tasks as a native pod on iOS on top of a TFLite runtime
that is already there. Both are avoidable. Neither is in this plan.

No store cliff either way — Play's 100 MB cap applies to legacy APKs, not
App Bundles, and Apple's cellular download limit is 200 MB.

---

## 3. The architecture decision: capture a still, render the film offscreen

**Flutter cannot screenshot a camera preview.** The preview is a platform
view; `RenderRepaintBoundary.toImage()` returns the painted widgets and a
*blank hole* where the camera was. This is
[flutter#18989](https://github.com/flutter/flutter/issues/18989),
[#102866](https://github.com/flutter/flutter/issues/102866) and
[#163639](https://github.com/flutter/flutter/issues/163639) — years old,
both platforms, not going away.

So "animate over the live camera and record the screen" is a dead end
unless we add a native screen recorder, which means a system permission
prompt, the status bar in the output, and no control over dropped frames.

**Do this instead:**

1. **Live preview** with the alignment guide, tracking landmarks off the
   image stream at ~15 fps. This phase is never recorded — it is the
   viewfinder, and it only has to feel responsive.
2. **On lock, `takePicture()`.** One high-resolution still. Everything
   downstream uses only this frame. It is sharper than any stream frame,
   which matters a lot in §4.
3. **One full-quality landmark pass** on the still.
4. **Rectify.** Wrist, the five MCP knuckles and the thumb CMC give a
   homography onto a canonical frontal palm square. From here on, all
   geometry is in palm space, where the lines always live in the same
   place regardless of how the hand was held.
5. **Render offscreen.** `PictureRecorder` → `ui.Image` → RGBA →
   `flutter_quick_video_encoder`, at a fixed dt of 1/30 s. 1080×1920.
   Deterministic: the same scan produces a byte-identical video on a
   flagship and on a four-year-old midrange.
6. **The same painter drives the on-screen reveal and the export.** One
   `CustomPainter` taking `(geometry, t)`. `ShareController` already
   carries the reasoning for this — "a share path that quietly differs
   between two screens is a growth bug nobody will ever file" — and it
   applies harder when one of the paths is the product's only growth
   channel.

**The known risk, stated plainly.** `flutter_quick_video_encoder` uses
hardware encoders with no FFmpeg and has no native `.so` of its own,
which is exactly what we want — but its **last release was 23 months ago**
and its open issue
[#13](https://github.com/chipweinberger/flutter_quick_video_encoder/issues/13)
is *"[iOS] AVAssetWriter fails on real device when encoding pre-rendered
frames"*, which is precisely our use case. This is spike S1 in §8, and it
must run on a real iPhone before anything else is built. The fallback is
~150 lines of AVAssetWriter and MediaCodec behind a `MethodChannel`;
`core/platform/app_task.dart` is the pattern to copy.

---

## 4. Where the lines actually come from

**Be honest internally about this.** There is no off-the-shelf mobile
model that segments palm creases. It is an open research problem — see
*Efficient Palm-Line Segmentation with U-Net Context Fusion Module*
([arXiv:2102.12127](https://arxiv.org/abs/2102.12127)) and
[yeonsumia/palmistry](https://github.com/yeonsumia/palmistry) (Apache-2.0:
MediaPipe landmarks → warp → U-Net → k-means, the same pipeline shape as
below). Every pub.dev package that sounds like it detects palm lines is
detecting hand *landmarks*.

Three tiers. Ship tier 1, and tier 2 is what makes the feature worth
building at all.

### Tier 1 — the template warp. 0 MB. Ship it.

Author the principal lines once, by hand, as cubic Béziers in canonical
palm space. Push them through the homography from §3. They land on the
real hand, at the real scale and rotation, and track it.

This is what the palm apps on the store are doing. It is honest enough —
the lines are in the right anatomical place — and it costs nothing.

### Tier 2 — crease snapping. Still 0 MB. This is the differentiator.

On the rectified crop, run a ridge/valley filter — Frangi-lite, or Sobel
over a CLAHE pass — **as a `FragmentProgram`**. This repo already drives
`shaders/aurora.frag` from a ticker; the loading and painting pattern in
`design_system/effects/aurora_background.dart` transfers directly.

Then, for each control point on each template line, search ±N px along
the line's normal for the strongest ridge response and pull the point
there, with a smoothness constraint so a single dark speck cannot kink
the curve.

Result: lines that follow *this person's* actual creases. Roughly 200
lines of Dart and one fragment shader, no model, no download.

**Why this is not optional.** The format lives or dies on whether two
people who film it get visibly different results. If every video shows
the same three curves in the same place, the comments will say so within
a week and the channel closes. Tier 1 alone is a demo. Tier 1 + tier 2 is
a product.

### Tier 3 — a real segmenter. Deferred.

Train or convert a small U-Net, quantise to int8, ship ~1–3 MB. Only if
S3 in §8 says tier 2 is not enough. Do not start here.

---

## 5. The animation

Everything needed is already in the repo: `flutter_animate`,
`SanctumMotion`, the aurora shader, the starfield, the glass card, and
`StorySlide`'s **measured** TikTok safe areas — bottom 16.8%, sides 15%,
plus the 3.6% each side that TikTok crops on a 20:9 screen. Those numbers
were read off a real posted video; do not re-guess them.

Target 9–11 s. Long enough to hold, short enough to loop.

| t (s) | beat |
|---|---|
| 0.0–1.2 | **Align.** Reticle; an edge-lit outline snaps to the detected hand; haptic on lock. |
| 1.2–2.2 | **Capture.** Shutter bloom, the still freezes and desaturates toward ink. |
| 2.2–4.0 | **Scan.** A light bar sweeps the palm and reveals the ridge-filter texture behind it. This is the shader doing real work — show it. |
| 4.0–7.0 | **Draw.** Heart, head, life, in sequence. Each is `PathMetric.extractPath(0, t·len)` with a bright leading spark and a trailing glow; the name fades in at each terminus. |
| 7.0–8.5 | **Constellate.** Nodes pop at the intersections and mounts, joined by hairlines — the visual bridge to the astrology the rest of the app is. |
| 8.5–11 | **Verdict.** One headline claim and the mark, inside the measured gutters. |

Craft notes that decide whether this reads as premium or as stickers on a
photo:

- Stroke width scales with palm size **in the warped frame**, never a
  constant pixel value.
- Glow via `MaskFilter.blur` on a second stroke pass; the spark via
  additive `BlendMode.plus`.
- A grain and vignette pass over the composite, so the drawn layer and
  the photographed layer share a surface.
- The offscreen renderer advances by fixed dt. The on-screen preview may
  drop frames; the export never can.

---

## 6. Money: the reading is free, the report is paid

> **Decided 2026-09-11**, replacing the share-gated first reading this
> section used to describe. **Not built yet** — `PalmGate` still sells the
> first reading for a share and the second for Premium. The delta is at
> the end of this section.

### The shape

- **Free for everyone, with no gate:** the scan, the lines, the reveal,
  Save, Share, and the short reading — one paragraph per claimed line.
- **One paid product: the full palm report**, a one-time purchase.
  Included for Premium subscribers, who never meet its price.

### Why the reading should be free

- **The share gate taxed the moment people are most delighted**, for three
  or four paragraphs. It was also unenforceable — the share sheet reports
  that an app was picked, never that anything was posted.
- **The reading is part of what gets posted.** People screenshot the one
  sentence that describes them. Gating it charges the growth channel twice:
  once for the video and again for the caption.
- **It removes the App Store 3.1.1 question entirely.** Nothing is traded
  for a share any more, so no reviewer has to decide whether a share is a
  payment mechanism.

### Why a non-consumable, not one report per scan

This is the part the relationship report's shape gets wrong for palms.

- **A scan is never stored** — see §7, and it is the design, not a gap. A
  report bought for one scan disappears when the user leaves the screen or
  the app is killed. That is a refund request with a receipt attached.
- **Consumables do not restore.** `roadmap.md` §1 already records this as
  an open problem for the relationship report; a palm report would inherit
  it and make it worse.
- **A non-consumable "full palm report" unlock restores through the store,
  applies to every future scan and to both hands, and needs no backend and
  no stored scan.** It fits the privacy model instead of fighting it.

If per-report revenue is wanted later, the only honest route is to store
the *derived profile* — three length bands, clarity, whether fate was
found — which describes a reading, not a hand. Decide that deliberately
before building it; do not drift into storing a scan.

**Price:** store-priced like the relationship report. Start at its tier and
test one above: it unlocks every future scan, not one pairing.

### Where the offer appears

Not on the reveal — that is the share moment, and a price there competes
with it, the lesson `roadmap.md` §1 already paid for. **At the foot of the
free reading**, after the last paragraph, when curiosity is highest. A
subscriber sees the full report in its place and no offer at all.

### What the report may say

What is measured: each line's length against this hand's prior (three
bands), how clearly it read, whether a fate line was found, and which hand
it was. What is **not** measured: breaks, forks, islands, chains, mounts.
The report may not describe anything in the second list, however standard
it is in the genre. Depth comes from three honest places:

- **Combinations.** How the heart and head lines negotiate, head against
  life, the reading with a fate line and without one. Three lines in three
  bands is 27 combinations before fate — real depth from real measurements.
- **Both hands.** Palmistry reads the non-dominant hand as what you were
  given and the dominant hand as what you made of it. That is a second scan
  and a reason to take it.
- **Palm against birth chart.** The app already computes the chart. Where
  the hands and the chart agree, and where they argue, is a report no
  palm-only app can make.

"Sell depth, not prophecy" (`roadmap.md` §1) applies: no timelines, no ages,
and the life line is vitality, never lifespan.

### Other monetisation to try, briefly

- **Two hands as a hook.** "My hands do not match" is a video format in its
  own right, and an upsell into the report.
- **Palm compatibility.** Scan a partner's hand for a match reading, feeding
  the existing relationship one-off. The other person has to be in the room,
  which makes it an in-person share.
- **A paywall moment after a free reading,** through the existing
  earned-moment trigger, for subscription conversion.
- **"Ask about your palm"** through the advisor once `roadmap.md` §2 ships.
  The profile is bands rather than geometry, and it still goes through the
  consent gate like everything else the advisor sends.
- **Gift a report** with store promo codes.
- **Not:** ads; any toll on the video, the still or Save; share-to-unlock on
  anything paid.

### Build delta

- `PalmGate`: the reading is always open; the report is open when owned or
  when the user is Premium.
- `PalmRepository`'s unlocked-scan ids and shared flag go; ownership comes
  from a RevenueCat non-consumable, provisionally `sanctum.report.palm`.
- Report copy lives in `assets/content/<locale>/copy.json` under
  `palm.report.*`, written to §11.

---

## 7. Privacy, and the one new legal exposure

**This is the first feature in Sanctum that touches biometrics.** Illinois
BIPA names "scan of hand or face geometry" in its definition of a
biometric identifier; Texas CUBI is similar, and GDPR Art. 9 treats
biometric data as special category. Worth a lawyer's hour before launch,
not after.

The mitigation is cheap **because the app is already built this way**:

- The image is **never transmitted**. There is no endpoint to send it to.
- The image is **never persisted**. Landmarks and derived geometry stay
  in memory; the still goes to a temp file and is deleted after the
  export — the same discipline the carousel already uses ("~1.5 MB each
  and deleted after the share").
- Nothing derived from the palm goes to analytics. The closed-set
  `AnalyticsEvent` design makes that structural rather than a rule
  someone has to remember: add `palmScanStarted`, `palmLockAcquired`,
  `palmVideoExported`, `palmShareCompleted`, `palmReportOffered`,
  `palmReportPurchased`, and give none of them a constructor that could
  carry a measurement.

What still has to be written:

- **`NSCameraUsageDescription`** — currently absent from
  `ios/Runner/Info.plist`, and an honest string, not "to use the camera".
- **A one-screen disclosure before the first scan**, reusing the advisor
  consent pattern: what is captured, that it stays on the device, that it
  is deleted.
- **A privacy-policy paragraph**, plus the four-things-change-together
  checklist in `docs/privacy-policy.md`.
- **`docs/store-data-safety.md`**: "camera used, nothing collected" is a
  real answer in both forms, but it has to be entered deliberately.
- **The entertainment disclaimer.** `roadmap.md` §7 already lists its
  absence outside the payoff screen as debt. Palmistry is the feature
  most likely to make a reviewer care.

---

## 8. Order of work

### Phase 0 — three spikes, 2–3 days. Do these before committing.

- **S1 — the encoder.** 300 `PictureRecorder` frames → mp4, on a **real
  iPhone** and a real Android. Issue #13 is the whole risk in this plan.
  Output: keep `flutter_quick_video_encoder`, or write the channel.
- **S2 — the detector and the size.** `hand_detection` running on both
  platforms; `flutter build apk --analyze-size --target-platform=android-arm64`
  before and after. Output: a real number to put against §2's estimate.
- **S3 — do two palms look different?** Tier 2 crease snapping over ~20
  real photos in varied light. Output: the answer to whether this format
  survives contact with a comment section.

### Phase 1 — the scan, ~1 week
Camera screen, alignment guide, live tracking, still capture, homography.
`PalmGeometry` lands in `domain/` as pure Dart — landmarks in, warp and
warped curves out — so it is testable in milliseconds like everything
else there. Pin it with ~20 checked-in landmark fixtures: the warp is
stable, and every curve stays inside the palm hull.

### Phase 2 — the film, ~1 week
The painter, the beat sheet, the offscreen renderer, the export, the
share. One painter, two consumers.

### Phase 3 — the reading and the gate, 3–4 days
`PalmComposer` in `domain/`, copy in `assets/content/<locale>/`,
`PalmGate`, IAP wiring, four locales.

### Phase 4 — polish
Haptics. The failure states that decide the retry rate: no hand, too
dark, too close, back of hand. Analytics. Disclaimers.

**≈3–4 weeks for two people**, plus translation.

---

## 9. The objection, stated once

`roadmap.md` §4 ranks acquisition as: (1) **post twenty videos** — "still
the riskiest untested assumption, and still free" — and (2) 9:16 video
export, with the reason attached: *"Video only after carousels show the
format travels — building a video encoder for an unproven format is the
wrong order."*

This feature is §4.2 plus a camera, an ML runtime, a shader pipeline and
a new content domain, bet on a channel that still has not been tested
with the free assets already shipped.

Two things pull the other way, and they are not small. The encoder is
built either way, so phase 2 is §4.2 rather than a detour. And a palm
scan is a **better** TikTok object than a carousel — it is a proven
format on that platform, it is native to video in a way four still frames
never are, and it gives the viewer something to do rather than read.

So: build it. But run phase 0 and the twenty carousel posts **in the same
week**, so that if the channel is the problem, three weeks of camera work
is not how we find out.


---

## 10. What is built, as of 2026-09-08

Branch `palm-scan`. **Run five times on a Pixel 6** — see below. The first crashed, the second detected nothing, the third drew in the wrong place, the fourth drew an outline that was not a hand and a life line bowed backwards, and the fifth put heart and head exactly on their creases with the life line sometimes a tenth of a palm off. Each cause found has a fix and a test; the fifth still needs a device to confirm.

### Built and tested

| | where |
|---|---|
| Landmarks, curves, readiness | `domain/models/palm.dart` |
| The affine warp and the frame checks | `domain/services/palm_geometry.dart` |
| The authored line set | `domain/services/palm_line_template.dart` |
| Crease snapping and line support | `domain/services/palm_crease_snapper.dart` |
| Rectify → snap → place, and what a hand may be told | `domain/services/palm_composer.dart` |
| Who pays for a reading | `domain/services/palm_gate.dart` |
| The beat sheet | `features/palm/view/palm_reveal_timeline.dart` |
| The painter | `features/palm/view/widgets/palm_reveal_painter.dart` |
| The scan's state machine | `features/palm/view_model/palm_scan_view_model.dart` |
| What a scan is allowed to say | `domain/services/palm_reading_composer.dart` |
| Earned readings and shares | `data/repositories/palm_repository.dart` |
| The viewfinder | `features/palm/view/widgets/palm_guide_painter.dart` |
| The scan screen | `features/palm/view/palm_scan_screen.dart` |
| The reading, gated | `features/palm/view/palm_reading_screen.dart` |
| The camera | `data/services/palm/camera_palm_camera.dart` |
| The preview surface | `features/palm/view/widgets/palm_camera_preview.dart` |
| The landmark detector | `data/services/palm/hand_detection_palm_detector.dart` |

All of `domain/` is pure Dart and runs in milliseconds. The painter is
tested by rasterising and counting pixels, which is the only way to
assert that a line lands on the hand rather than near it.

### Seams cut, implementations missing

Every seam is implemented. `PalmRidgeExtractor` stays nullable on
purpose: with none, a scan still completes and draws the bare template —
a worse product, but a working one, and the right thing to ship on the
first device build while S3 is open.

`PalmCamera` is implemented. It takes the **back** camera deliberately:
a front sensor costs the crease filter detail it never gets back, and a
mirrored frame flips reported handedness and pose chirality together,
which is precisely the case `HandLandmarks.isPalmFacing` cannot detect.

### Size: §2 was wrong, and by a lot

Measured with `--split-per-abi`, which is what a device downloads:

| | arm64 APK |
|---|---|
| before the palm scan | 30.3 MB |
| `camera` | 32.2 MB |
| `hand_detection` | **65.6 MB** |

**§2 estimated +8–12 MB for the whole feature. The real figure is
+33.4 MB**, and the app is now twice what it was. The breakdown:
OpenCV `libdartcv.so` 11.4 MB, LiteRT and TensorFlow Lite plus two GPU
delegates ~15.3 MB, the two models 7.8 MB, ~6.5 MB of `classes.dex`.

The estimate went wrong in two places. It assumed one ML runtime, and
`flutter_litert` ships two side by side with their accelerators. And it
did not know `hand_detection` runs its pre-processing on OpenCV — the
crop, rotate and colour conversion the MediaPipe pipeline needs — which
is where `dartcv4` and 11.4 MB come from.

**Measure with `--split-per-abi`, never `--target-platform`.** The
plugin ships native libraries as jniLibs, which `abiFilters` does not
reach, so a `--target-platform=android-arm64` build reports 95 MB while
carrying x86_64 and armeabi-v7a copies of LiteRT no device would ever
receive. That number is an artefact.

**The leaner route, costed.** `flutter_litert` alone needs no OpenCV and
no CMake, which would save the 11.4 MB and the toolchain — roughly
53 MB — but means hand-rolling the MediaPipe pipeline: SSD anchor
decode, non-maximum suppression, the rotated ROI crop and the landmark
pass. Days of work whose hardest part cannot be validated without device
captures. Weighed on 2026-09-08 and declined: twelve megabytes is not
worth that risk. Worth revisiting only if the size becomes a real
constraint.

### CMake is now a build prerequisite

`dartcv4` compiles a native asset for the host, so `flutter test` fails
before a single test runs without it. `brew install cmake`, and the
README says so. It comes from OpenCV alone — `flutter_litert` ships
prebuilt libraries.

### First run on a Pixel 6, and what it found

Ran 2026-09-08. The camera opened, the guide drew, and the app died of
an out-of-memory kill inside a minute, with `logcat` printing
`Replacing 272 out of 272 node(s) with delegate` and `Replacing 165 out
of 165` in pairs — the palm and landmark models being loaded and
delegated, **once per frame**.

`palmDetectorProvider` is auto-disposed, and `ref.read` of an
auto-disposed provider that nothing listens to creates it, hands back
the value, and disposes it again. So every frame built a fresh detector,
which loaded both TFLite models and re-applied XNNPack. The camera
escaped the same fate only because the preview surface happens to
`watch` it.

Fixed by watching both from `build`, which makes them dependencies of
the notifier: built once, alive for the scan, disposed with it.
`palm_scan_view_model_test.dart` asserts the construction count, and
that test was checked against the old code to be sure it fails on it.

Two things went in alongside:

- **The preview stream dropped to `ResolutionPreset.medium`.** The
  detector downscales to 640 on the long edge anyway, so 720p was 1.4 MB
  a frame allocated thirty times a second to be resized away.
- **Inference is throttled to one every 80 ms.** The busy guard alone
  runs the detector as fast as the phone allows, which pegs a core to
  track a hand that is barely moving. The interval is a provider so
  tests can set it to zero.

**"No buttons whatsoever" is half a real finding.** There is no shutter
by design — the scan waits for eight steady frames and fires itself,
because pressing a button moves the hand that is the subject. But the
app bar, the back arrow and the instruction are all white over whatever
the lens is pointing at, and against a bright wall none of them is
visible. A viewfinder with nothing readable on it reads as an app that
failed to load. There is a scrim behind them now.

### Second run: no detection at all, and a guide shaped like a blob

Ran 2026-09-08, after the crash fix. No lag, models loaded once, and the
viewfinder said "hold your palm up to the camera" for ever with a palm
held up to the camera.

**The stream was configured as `ImageFormatGroup.nv21`.** The detector's
frame preparation takes a single plane only when it is packed four-byte
colour; everything else must arrive as two planes or three. `nv21` is
one tightly packed plane, so every frame was rejected *before*
inference: an empty list back, no error, no log line, and a model that
had loaded perfectly and never once saw an image. `yuv420` gives three
planes and is what the package's own README asks for. It also stops
Android falling back to JPEG frames.

Two more found while looking:

- **Palm-only detections were winning the size comparison.** With
  tracking on, the package can return a box with no landmarks and no
  handedness alongside a full detection. Picking the largest before
  filtering meant the box won and a perfectly good hand reported as no
  hand. Filter first, then pick.
- **iOS frames would have been read as RGBA.** The package defaults
  `isBgra` to `Platform.isMacOS`, which is false on an iPhone, so an
  iOS frame — which really is BGRA — would go in with red and blue
  swapped. The model still finds hands in a colour-shifted image, just
  less well, which is the kind of degradation nobody traces. Passed
  explicitly now.

**And the guide was eleven authored points**, which on a phone read as a
lopsided circle: roughly square, no fingers, nothing about it saying
"hand". Points authored by eye cannot be checked by the person authoring
them. It is built now — a capsule down each finger and across the palm,
taken from `PalmGeometry.canonicalHand`, unioned and stroked. The test
fixtures were re-pointed at that same map, so the target, the detected
outline and every posed test hand are one anatomy.

A debug-only readout in the corner names the readiness the checks land
on, because `noHand` and `backOfHand` need telling apart from outside
and the loop for finding out is build, install, hold a hand up.

### Tier 2 is built: the lines are pulled onto real creases

`CanvasPalmRidgeExtractor` rectifies the captured still into a 256-pixel
canonical square, and `PalmRidgeFilter` measures how crease-like every
pixel in it is. `PalmCreaseSnapper` — written weeks before anything
could feed it — now has a field to search.

**Rectify first, then filter.** The filter's probe widths are pixel
distances, so on a raw photograph they would measure a different
fraction of a hand on every scan. After the warp they are a fixed
fraction of a palm, and the field is already in the space the snapper
searches, with no second transform between the two to get wrong.

**A crease is not an edge.** An edge is bright on one side and dark on
the other; a crease is dark with bright on *both* sides, a few pixels
across, running in an unknown direction. So the test is "darker than its
two flanks", at four orientations and two widths, keeping the best
answer.

**Dart, not a fragment shader.** §4 called for a shader on the
assumption this ran per preview frame. It does not — it runs once, on
the still, while the reveal's first beat plays. At that budget the
filter is free in Dart, and it can be tested against images the test
builds itself rather than against whatever the GPU did.

**The contrast floor is the part that matters.** Responses are scaled so
the strongest crease reaches 1, which on a well-lit palm is right and on
a blank wall would stretch sensor noise to look identical.
`PalmRidgeFilter.minimumContrast` stops the divisor shrinking below
seven grey levels, so a featureless image stays near zero and
`PalmProfile.isThin` keeps meaning something.

Two tests carry the weight. One draws creases offset from the template
into a synthetic palm, runs the real filter over the real pixels, and
asserts the snapper more than halves the distance to them. The other
draws creases *through* the warp into a 480 × 640 photograph and reads
them back *through* its inverse — which is the only way to tell a
correct rectification from a plausible one, and the matrix that composes
three transforms is the piece most likely to be silently wrong.

### Fourth run: an outline that was not a hand, and a life line drawn backwards

Ran 2026-09-11. Detection worked, the shutter fired, the reveal played —
and the result showed two things that tests had not.

**The outline did not look like a hand**, especially the thumb. It had
been built from parts twice: first eleven points authored by eye (a
lopsided circle), then a capsule down every bone, unioned (sausage
fingers, a V where five capsules met at the wrist, and a thumb stuck on
at whatever angle the canonical hand held it). The second also pushed
the *canonical* hand through the warp fitted to the knuckles, so the
outline ignored where the user's fingers and thumb actually were.

`PalmSilhouette` now traces one line round the hand from the 21
detected landmarks — up each finger's outer edge, round a tapered tip,
into the web, across to the thumb and back round the thenar bulge —
joined with a **centripetal** Catmull-Rom spline, the variant proven not
to loop at uneven spacing like fingertips and webs. Sides are chosen
relative to the hand (toward the little finger, toward the index), so
both hands trace the same way round. Tests hold it to never crossing
itself on either hand or at an angle, to reaching past every tip, and to
going round the thumb whether it is tucked or splayed. The live outline
eases between detections instead of jumping twelve times a second.

**The size threshold was nearly unreachable on the phone it was run
on.** A Pixel 6's preview is 411 × 914 logical over a 2:3 frame, so the
cover crop hides a third of the width; at `minKnuckleSpan` 0.28 the
largest hand outline that fits on screen cleared it by one percent, and
jitter would flicker it. It is **0.22** now. The creases come from the
full-resolution still, where 0.22 of a 3024-pixel photograph is still
about 660 pixels across the knuckles. A test places a hand exactly on
the target on three screen geometries, Pixel 6 included, and asserts
the checks accept it with ten percent to spare.

**The life line bowed the wrong way.** It encloses the ball of the
thumb, so it bows toward the palm's middle; the template bowed toward
the thumb. At its middle it sat about 0.3 of a palm from the real
crease, and the snapper was only allowed to look 0.045 either side, so
nothing could rescue it.

**So the snapper is a tracer now.** It picked each anchor's best offset
on its own and smoothed afterwards, which failed twice over: a radius
small enough not to jump lines was too small to reach a misplaced
crease, and independent choices on a textured palm landed neighbouring
points on different wrinkles. It now cuts a line into 28 stations,
scores every offset in a ±0.10 band at each, and finds the best
continuous path by dynamic programming, paying for distance from the
template and for bending. The balance was worked out before writing it:
the first weights would have let a single dark speck on a blank palm
pull the line into a detour, so bending is expensive enough that a
one-station gain cannot pay for the trip out and back, while a real
crease repays the transition at every station it runs for. The path may
bow either way — the photograph decides curvature, not the template.

**The heart line was not mirrored.** Everything sat on the correct side;
flipping it end to end would start it under the thumb, where the head
and life lines begin. Its curvature was a guess, though, like the life
line's, and the tracer now settles that from the image.

**The ridge filter scaled by the single strongest response**, and the
crop reaches past the palm — on a hand wearing a ring, the ring's dark
edge sits inside it and set the ruler, leaving every real crease faint.
It scales by the 99th percentile now.

### Fifth run: heart and head on their creases, life sometimes a tenth off

Ran 2026-09-11 on a right hand. Heart and head landed exactly on the
creases — the tracer doing what it was built for. The life line came out
about a tenth of a palm toward the middle of the palm on some scans.

**The life line is the only principal line that depends on the thumb.**
It is the crease bounding the ball of the thumb, and where that mount
sits changes from hand to hand and with how far the thumb is spread. The
warp cannot see that: it is fitted to the wrist and the four finger
knuckles, and the thumb was left out on purpose because it moves. So the
life-line prior sat in the same place whatever the thumb was doing.
When the real crease followed the thumb out toward the edge of the
tracer's band, a weaker crease nearer the template could win, because
the tracer charges for distance and nearness is cheap. That is what
"sometimes" looks like: two creases scoring close, and small changes in
thumb pose deciding between them.

`PalmLineTemplate.lifeAround` fits the prior to the detected thumb base,
carried into canonical space by the same warp as everything else. The
line moves by the base's difference from the canonical hand's, taking
none of it at its start — shared with the head line and tied to the
index web, not the thumb — and all of it from the middle down. The move
is capped at 0.12 so a misdetected or folded thumb cannot drag the prior
across the palm. The tracer does the rest.

Heart and head do not move with the thumb and are untouched; a test
holds them identical.

`PalmReading.priors` records what each line was traced from, and a
line's length is now read against that rather than the canonical
template, so a hand is not told its life line is short because its thumb
sits further out.

The regression test reproduces the report: a thumb base further out, a
real crease that follows it, and a decoy crease a little toward the
palm's middle. It first asserts the *unfitted* template traces onto the
decoy — the bug, so the test is known to discriminate — then that the
fitted prior traces onto the real crease.

**Not yet measured:** the ramp and the cap are reasoned from anatomy,
not fitted to captures. The next device run is what confirms them.

### Sixth run: the pen, a Save button, and a gate that refused good scans

Ran 2026-09-11, after the owner retuned the templates by hand. Every line
drew on its crease. Three things followed.

**A pen line is the most reliable input the tracer gets.** Going over the
creases with a pen before scanning produces a line far darker than any
crease, and the tracer finds it every time. The reveal now says so where
"For entertainment only" used to sit — removed at the owner's request, as
not the voice of the product — and the faint-scan copy offers the pen as
the way through. The disclaimer is gone from the palm screens only; the
payoff screen and the carousel's closing frame still carry theirs, and a
store reviewer who asks for one on the palm feature is a one-key change.

**Save puts the finished reveal in the photo library**, beside Share,
through `gal`. On iOS it asks for add-only access at the moment of the
tap and never for read access. On Android, `WRITE_EXTERNAL_STORAGE` is
back — it had been removed as dead weight when the camera plugin dragged
it in, and stopped being dead weight here — but capped at API 29, the
last version that needs it, so it is never requested on anything newer.
The microphone and the implied read access stay removed, and the
manifest test asserts all three.

Wiring it turned up a latent bug in the reveal's existing Share: it read
an auto-disposed controller on tap without anything watching it, which is
the same trap that once built a detector per camera frame. Both
controllers are watched now.

**"That one came out faint" refused scans whose lines were drawn
correctly** — every bare palm, while the same palm in pen passed. The gate
was a mean line support of 0.2, and the ridge filter scales every
response against the strongest things in the crop, which on most photos
are the hand's edges against the background. So a real crease traced
perfectly reads around a tenth; a pen line reads high. Neither number
says whether a photograph was readable. What does is whether the lines
stand out from the palm around them: `PalmReading.background` is the
mean response across the palm's interior away from every traced line,
and a reading is refused only when the lines rise less than 0.03 above
it. That threshold is a guess, biased toward showing the reading —
refusing one over lines the user can see were drawn correctly is a broken
screen at the point of sale. **Debug builds print clarity, background
and lift on the reading screen**; a handful of scans with and without a
pen is what replaces the guess.

**The retuned life line exposed a fate-line risk.** Its lower arc now
reaches x≈0.49, about four hundredths from the fate line — inside the
tracer's band — so on a hand with no fate line, the fate tracer followed
the life line's crease and scored it as fate. The templates were left as
the owner set them. Instead, fate is traced last, against a field with
the heart, head and life creases faded out, so it can only claim evidence
that belongs to no other line; a real fate line four hundredths from the
life line is still found, and a test holds both.

### The handedness flip, and why it is the riskiest line in the feature

MediaPipe's landmark model emits handedness **assuming its input is
mirrored** — the selfie convention. `hand_detection` passes that output
through untouched, and our frames come from the rear camera and are not
mirrored, so the label arrives inverted.
`HandDetectionPalmDetector.assumesMirroredInput` flips it back.

Get this backwards and `HandLandmarks.isPalmFacing` disagrees with the
pose's chirality for every hand: **every palm reports as the back of a
hand, the readiness check never passes, and the shutter never fires** —
on a scan that looks perfectly aligned. There is no partial failure, and
nothing in the UI would say why.

It follows from MediaPipe's documented convention and from reading this
package's source, and a test pins the end-to-end property. **None of
that is a device.** Spike S2 settles it, and the symptom names itself:
if a real palm held flat to the lens reports
`PalmReadiness.backOfHand`, invert that constant.

### Three permissions the camera plugin drags in

`camera_android_camerax` declares `CAMERA`, `RECORD_AUDIO` and
`WRITE_EXTERNAL_STORAGE`. The last two are removed with
`tools:node="remove"`, and so is `READ_EXTERNAL_STORAGE` — which nobody
declares at all. The merger *implies* it from camerax's `WRITE` request,
and the implication fires off the plugin's own declaration rather than
off the merged result, so removing `WRITE` alone leaves `READ` behind.

That was found by reading `manifest-merger-release-report.txt` after a
real build, not by reasoning about it, and the merged manifest is now
verified to carry `CAMERA` and none of the other three.
`android_manifest_test.dart` asserts all three removals, because the
only symptom of losing them is "Microphone" on the Play listing of an
app whose whole claim is that nothing leaves the device.

`NSCameraUsageDescription` is in `Info.plist` and says what the picture
is for and that it is deleted. `NSMicrophoneUsageDescription` is
deliberately absent: the controller is built with `enableAudio: false`,
and declaring a purpose string for a device the app never opens puts
"Microphone" on the App Store privacy card for nothing.

### Not built at all

- **The three spikes.** Still the gate. S1 in particular — the encoder
  on a real iPhone — decides whether phase 2 is a package or a platform
  channel, and it has not run.
- **The offscreen renderer and the exporter** — spike S1, still the
  gate on §4.2. The reveal plays on screen and shares as a still; there
  is no video yet.
- **The consent screen, the privacy paragraph, and the store data-safety
  entries** in §7. None of them exist, and the feature must not ship
  without them.

### Reachable, and in four languages

A card on Today opens `/palm`; `/palm/reading` sells what the scan says.
Both sit outside the shell so the viewfinder is full-bleed. **Not a
sixth tab** — the bar is fitted to five labels in four locales, and a
scan is something people come to do rather than a place they live.

Copy is split the way this repo splits it: twenty-eight chrome strings
in the ARB, twelve reading paragraphs in
`assets/content/<locale>/copy.json`, because a paragraph about
somebody's hand is the half that needs a human translator. All four
locales are complete and both parity tests pass. **The uk, ru and es
translations are drafts written in the documented voice and have had no
native review** — for uk and ru that is the workflow already in place;
for es it is the same gap §3 of `handoff.md` already records.

### Numbers that moved on contact with arithmetic

Both were guesses in this document and are now pinned by tests:

- An open flat hand computes to **1.70** openness, not the 2.2 first
  assumed, so the threshold sits at 1.55.
- Least squares spreads one cupped knuckle across all five anchors well
  enough that a 14 %-of-palm-length displacement only reaches a 0.046
  residual — so the limit came down from 0.06 to **0.035**, with
  landmark jitter pinned below it as the other end of the gap.

A third distinction had to be added that this document missed entirely:
**a crease support of zero meant two different things.** "We looked and
found nothing" and "we did not look" were the same value, so every scan
on a build with no ridge filter reported as too faint to read — a claim
about the user's hand that nothing had measured.
`PalmReading.measured` separates them now, which matters immediately:
the first device build will have no ridge filter, and without this it
would send every user back to the camera.

Everything in §4's tier list, §5's beat sheet and §6's gate survived
implementation unchanged.

---

## 11. How the reading is written

Rewritten 2026-09-11, after two paragraphs were rightly called generic.

**The difference, by example.** *"You have deep reserves and a habit of
spending them on other people. Worth watching."* works. *"You keep going
steadily, and people rely on that more than they say."* does not. The rules
below are what separates them.

1. **A behaviour, not a trait.** Something the reader can picture herself
   doing — replaying a conversation, disappearing after a sprint — rather
   than an adjective.
2. **Every strength has a cost.** Pure flattery reads as a horoscope. A
   strength with its price reads as being seen — the half of the Barnum
   effect that generic copy leaves out.
3. **Specific enough to feel personal, never checkable.** No siblings,
   jobs, ages or dates.
4. **Never explain palmistry.** The screen already names the line. The
   paragraph is about the reader, not about hands.
5. **Quotable.** Each paragraph has to survive being screenshotted on its
   own, because it will be — it is the caption on the video.
6. **The bands mean different things.** Short, typical and long are three
   different people, not three volumes of one sentence.
7. **Typical gets the best line.** Most hands land in the typical band, so
   those paragraphs are the most read in the app. The two weakest paragraphs
   were both typical.
8. **No prophecy, no lifespan, no diagnosis.** Tiredness and hurt can be
   described; they are never named clinically.
9. **House voice:** dry and concrete, no contractions outside quoted speech,
   British spelling.

**Translation is rewriting, not word-for-word.** The first Ukrainian,
Russian and Spanish drafts were literally accurate and nothing a native
speaker says — *"на повну гучність"*, *"бути впізнаною"*, *"a volumen
completo"*. The rewrite keeps each paragraph's idea and uses the phrase a
native speaker would reach for: *"з головою"*, *"обвести навколо пальця"*,
*"Ojo con eso"*. Ukrainian and Russian follow the voice rules in
`handoff.md` §3 (informal singular, feminine reader); Spanish is `tú`,
Latin-American neutral, and dry by positioning. **Spanish still wants a
native pass** — nobody on the team reads it.

