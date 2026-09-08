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

## 6. Money, and the mechanic that conflicts with a decision already made

`handoff.md`, "The reveal exports as a four-frame carousel", records that
share-gating was designed and **rejected**, for three reasons that all
still apply here:

> the platform only reports that an app was picked, never that anything
> was posted […] requiring a public post to unlock functionality is the
> shape of thing App Review rejects; and the export *is* the acquisition
> channel, so charging friction for it taxes the only growth this product
> has.

Apple's own position is split in a way that matters: incentivising users
to post about your app on social media is permitted, but §3.1.1 says apps
"may not use their own mechanisms to unlock content or functionality". If
the palm report is *also* sold for money, then share-to-unlock is exactly
such a mechanism, and it is the reviewer's call which sentence wins.

**Recommended shape, which gets the same outcome without the bet:**

- **The video is free, ungated, always.** It is the growth channel. Never
  put a toll on it.
- **The scan and the three named lines are free.** That is the payoff
  people film.
- **The deep palm reading is the product**, sold through the consumable
  path `sanctum.report.relationship` already proved out, and included for
  subscribers under the same once-ever rule `ReportGate` implements.
- **If you want a share incentive, make it additive.** Mirror
  `CompatibilityGate.hasSharedInvite`: a completed share grants an *extra
  free scan*, never the paid reading. Reuse `ShareController.shareInvite`
  and inherit its documented honesty about what `ShareResultStatus`
  actually proves.

Implement as `PalmGate` in `domain/services/`, beside `ReportGate` and
`CompatibilityGate`, in the same shape: a pure function from state to an
enum, tested exhaustively.

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

Branch `palm-scan`, seven commits, ~134 tests. **Nothing has run on a
device**, because nothing that needs one exists yet.

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

`PalmRidgeExtractor` is the last interface with no implementation, and
it is nullable on purpose: with none, a scan still completes and draws the bare template —
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
- **The ridge fragment shader**, the offscreen renderer and the
  exporter. Without the shader a scan still completes and draws the
  bare template — tier 1 of §4, which is a demo rather than a product.
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
