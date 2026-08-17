import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/effects/starfield.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';

/// One 9:16 frame of an exported carousel.
///
/// ## Why 360 x 640 and not 1080 x 1920
///
/// The slide is laid out in *logical* pixels and captured at
/// [captureScale], which lands on exactly 1080 x 1920 — TikTok and
/// Reels' native canvas. Laying it out at 1080 instead would mean every
/// font size, radius and spacing token in the design system needed a
/// parallel "but three times bigger" value, and the first one anybody
/// forgot would be invisible until it was in someone's feed. At 360 wide
/// the existing tokens are the right size and the capture does the
/// scaling.
///
/// ## Why it is self-contained
///
/// Its own background, its own stars, no ancestor it depends on: this
/// widget is captured to a PNG, and anything it inherits from the screen
/// behind it would simply be missing from the file. The starfield is
/// passed `enabled: false` so the sky is static — a captured frame of a
/// twinkling star is a different image every time, which makes the
/// export non-deterministic and untestable for no benefit.
///
/// ## The gutters are not padding, they are TikTok
///
/// Measured off a real post on a Pixel 6, not guessed. TikTok draws the
/// caption, username and sound over the bottom **16.8%** of the image
/// and the action rail over the right **15%**, and on a 20:9 screen it
/// also *crops* 3.6% off each side to fill. The first version reserved
/// 14.4% at the bottom and 8.9% at the sides, and both were short: the
/// facet pills landed under "Add 1st" and the closing quote ran beneath
/// the like button.
///
/// [railGutter] is applied to **both** sides even though only the right
/// is covered. An off-centre composition reads as a mistake where a
/// slightly smaller centred one reads as intentional — and the same
/// asset goes to Instagram Stories, where the overlays sit elsewhere.
/// Symmetry is what makes one export safe on both.
class StorySlide extends StatelessWidget {
  /// Creates a slide.
  const StorySlide({
    required this.child,
    this.seed = 7,
    this.glowAlignment = const Alignment(0, -0.35),
    super.key,
  });

  /// Logical width. Captured at [captureScale] this is 1080 px.
  static const double width = 360;

  /// Logical height. Captured at [captureScale] this is 1920 px.
  static const double height = 640;

  /// Device pixel ratio the capture runs at, giving 1440 x 2560.
  ///
  /// 3x — a clean 1080 x 1920 — was the obvious choice and it came back
  /// soft. TikTok draws the image *wider* than the screen to fill a 20:9
  /// phone, so a 1080-wide file is upscaled about 8% before its own
  /// recompression ever runs, and fine serif text on a dark gradient is
  /// the worst case for that. Rendering the type at 4x its layout size
  /// gives the encoder more to work with; the cost is about 0.8 MB a
  /// frame in a file that is discarded after the share sheet closes.
  static const double captureScale = 4;

  /// Space at the bottom reserved for the caption, username and sound.
  static const double chromeGutter = 124;

  /// Space at each side reserved for the action rail. See the class doc
  /// for why the left gets it too.
  static const double railGutter = 54;

  /// Space at the top, clear of the back arrow and search icon.
  static const double topGutter = 48;

  /// Width available to [child], once the side margins are removed.
  static const double contentWidth = width - railGutter * 2;

  /// The slide's content, laid out between the wordmark and the gutter.
  final Widget child;

  /// Seed for this slide's stars, so four slides are four skies.
  final int seed;

  /// Where the bloom sits behind the content.
  final Alignment glowAlignment;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.backgroundEnd,
              colors.background,
              colors.backgroundEnd,
            ],
            stops: const [0, 0.55, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: glowAlignment,
                  radius: 0.85,
                  colors: [
                    colors.glow.withValues(alpha: 0.30),
                    colors.accentSecondary.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
            Starfield(starCount: 110, seed: seed, enabled: false),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                railGutter,
                topGutter,
                railGutter,
                chromeGutter,
              ),
              child: Column(
                children: [
                  Text(
                    'SANCTUM',
                    style: type.caption.copyWith(
                      color: colors.gold,
                      letterSpacing: 6,
                    ),
                  ),
                  // Content is laid out at its natural height and
                  // scaled down if it does not fit, rather than
                  // overflowing. Copy length is not fixed — a longer
                  // directional line or a translated string is one more
                  // line of type — and on a canvas this size an
                  // overflow is not a stripe in a debug build, it is a
                  // clipped sentence in a published post.
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(width: contentWidth, child: child),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
