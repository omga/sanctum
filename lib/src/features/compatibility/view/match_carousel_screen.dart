import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/design_system/atoms/sanctum_button.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/services/carousel_caption.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/carousel/match_carousel_slides.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/carousel/story_slide.dart';
import 'package:sanctum/src/features/sharing/view_model/share_controller.dart';

/// The four frames the user is about to post, before they post them.
///
/// ## Why there is a preview at all
///
/// The share sheet gives no confirmation of what was handed over, and a
/// carousel is four files rather than one. Seeing the exact frames — in
/// the exact order — is what makes a person willing to press the button
/// on something that goes out under their own name. It is also the only
/// place a bad crop or a clipped name can be caught before it is in a
/// feed and permanent.
///
/// ## Why it is pushed rather than routed
///
/// Every other screen here is a `go_router` route, and this one
/// deliberately is not. `MatchResultRoute` already carries a name and a
/// birth date in its query string — the standing hazard the handoff
/// names — and a second route would put the same pair in a second URL,
/// where crash breadcrumbs and OS logs can reach it. The match is passed
/// as an object instead, and nothing about this screen needs to be
/// deep-linkable.
class MatchCarouselScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const MatchCarouselScreen({required this.match, super.key});

  /// The match being posted.
  final CompatibilityMatch match;

  /// Opens the preview above the shell, so the nav bar cannot draw over
  /// it — the same reason the journal sheets use the root navigator.
  static Future<void> open(BuildContext context, CompatibilityMatch match) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => MatchCarouselScreen(match: match),
      ),
    );
  }

  @override
  ConsumerState<MatchCarouselScreen> createState() => _CarouselState();
}

class _CarouselState extends ConsumerState<MatchCarouselScreen> {
  final PageController _controller = PageController();
  final List<GlobalKey> _keys = List.generate(
    MatchCarousel.slideCount,
    (_) => GlobalKey(),
  );
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _caption => CarouselCaption.forMatch(widget.match);

  Future<void> _share() async {
    await ref
        .read(shareControllerProvider.notifier)
        .shareAll(
          _keys,
          text: _caption,
          pixelRatio: StorySlide.captureScale,
          // Only the page that is on screen has painted a layer, so each
          // frame is brought forward before it is read. Two frames are
          // awaited rather than one: the first builds the page, the
          // second is the one that actually paints it.
          beforeEach: (index) async {
            if (!_controller.hasClients) return;
            _controller.jumpToPage(index);
            await WidgetsBinding.instance.endOfFrame;
            await WidgetsBinding.instance.endOfFrame;
          },
        );
    if (!mounted) return;
    if (_controller.hasClients) _controller.jumpToPage(_page);
  }

  Future<void> _copyCaption() async {
    await Clipboard.setData(ClipboardData(text: _caption));
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Caption copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final slides = MatchCarousel.slidesFor(widget.match);
    final sharing = ref.watch(shareControllerProvider).isLoading;

    ref.listen(shareControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text('$error')));
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Your post', style: type.title),
        iconTheme: IconThemeData(color: colors.textSecondary),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemCount: slides.length,
                  // FittedBox, not Transform.scale, and the difference
                  // is the whole export. A `SizedBox` is clamped by the
                  // constraints it is given — inside a viewport shorter
                  // than 640 the slide is silently laid out at the
                  // viewport's height, and the capture then writes that
                  // height to disk. It looked right on screen and
                  // shipped 1080x1689 files. FittedBox lays its child
                  // out *unbounded*, so the slide is always its true
                  // 360 x 640 and only the display is scaled.
                  itemBuilder: (context, index) => FittedBox(
                    child: ClipRRect(
                      borderRadius: SanctumRadii.lgAll,
                      child: RepaintBoundary(
                        key: _keys[index],
                        child: slides[index],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: SanctumSpacing.lg),
              _Dots(count: slides.length, active: _page),
              const SizedBox(height: SanctumSpacing.lg),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SanctumSpacing.xl,
                  0,
                  SanctumSpacing.xl,
                  SanctumSpacing.lg,
                ),
                child: Column(
                  children: [
                    SanctumButton(
                      label: 'Share all four',
                      icon: Icons.ios_share,
                      expand: true,
                      onPressed: sharing ? null : () => unawaited(_share()),
                    ),
                    const SizedBox(height: SanctumSpacing.sm),
                    SanctumButton(
                      label: 'Copy caption',
                      icon: Icons.content_copy,
                      variant: SanctumButtonVariant.ghost,
                      expand: true,
                      onPressed: () => unawaited(_copyCaption()),
                    ),
                    const SizedBox(height: SanctumSpacing.sm),
                    Text(
                      'Pick TikTok or Instagram. All four go up as one '
                      'carousel — paste the caption when it asks.',
                      textAlign: TextAlign.center,
                      style: type.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // The capture flicks through all four pages, which is visible
          // and looks broken. It happens behind this instead.
          if (sharing)
            Positioned.fill(
              child: ColoredBox(
                color: colors.background.withValues(alpha: 0.92),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: SanctumSpacing.lg),
                      Text('Building your post', style: type.bodyMedium),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Page indicator. Four slides is few enough to draw honestly.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(
              horizontal: SanctumSpacing.xs,
            ),
            width: index == active ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(
              borderRadius: SanctumRadii.pillAll,
              color: index == active
                  ? colors.gold
                  : colors.textTertiary.withValues(alpha: 0.4),
            ),
          ),
      ],
    );
  }
}
