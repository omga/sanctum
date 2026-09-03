import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/theme/sanctum_theme.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_radii.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_spacing.dart';
import 'package:sanctum/src/domain/models/compatibility.dart';
import 'package:sanctum/src/domain/models/zodiac_sign.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/carousel/story_slide.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/element_palette.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/hexagon_chart.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/score_dial.dart';
import 'package:sanctum/src/features/compatibility/view/widgets/sign_avatar.dart';
import 'package:sanctum/src/l10n/l10n.dart';
import 'package:sanctum/src/l10n/sanctum_lexicon.dart';

/// The four frames of a shared match, in posting order.
///
/// ## Why this order
///
/// A carousel is read as a cover plus a payoff, and the swipe between
/// them is the engagement the platform ranks on. So slide one is a
/// thumbnail that has to be legible at an inch tall — two glyphs and a
/// number, nothing else — and slide three is the argument: the
/// directional split, which is the only claim in this app that is about
/// a *person* and therefore the only one anybody defends in a comment.
/// The chart sits between them as the receipts, and the verdict closes.
///
/// Every slide is built with `animate: false`. A capture of a ring
/// caught halfway through its count-up is a bug that only ever appears
/// in someone else's feed, where it cannot be seen or fixed.
abstract final class MatchCarousel {
  /// How many frames a post carries.
  static const int slideCount = 4;

  /// Builds every frame for [match], in order.
  static List<Widget> slidesFor(CompatibilityMatch match) => [
    _CoverSlide(match: match),
    _ShapeSlide(match: match),
    _SplitSlide(match: match),
    _VerdictSlide(match: match),
  ];
}

/// Slide one: the thumbnail. Who, and the number.
class _CoverSlide extends StatelessWidget {
  const _CoverSlide({required this.match});

  final CompatibilityMatch match;

  @override
  Widget build(BuildContext context) {
    return StorySlide(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Side(person: match.you)),
              Padding(
                padding: const EdgeInsets.only(top: SanctumSpacing.xl),
                child: Text(
                  '+',
                  style: context.type.displaySmall.copyWith(
                    color: context.colors.gold,
                  ),
                ),
              ),
              Expanded(child: _Side(person: match.them)),
            ],
          ),
          const SizedBox(height: SanctumSpacing.md),
          _Chip(label: match.aspect.label(context.l10n)),
          const SizedBox(height: SanctumSpacing.xl),
          ScoreDial(
            score: match.overall,
            verdict: match.verdict,
            yours: match.you.sign.element,
            theirs: match.them.sign.element,
            size: 214,
            animate: false,
          ),
        ],
      ),
    );
  }
}

/// Slide two: the receipts.
class _ShapeSlide extends StatelessWidget {
  const _ShapeSlide({required this.match});

  final CompatibilityMatch match;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return StorySlide(
      seed: 19,
      glowAlignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Heading(context.l10n.carouselShapeHeading),
          const SizedBox(height: SanctumSpacing.lg),
          HexagonChart(
            facets: match.facets,
            size: StorySlide.contentWidth,
            animate: false,
          ),
          const SizedBox(height: SanctumSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _FacetPill(
                  score: match.strongest,
                  label: context.l10n.carouselHighest,
                  color: colors.gold,
                ),
              ),
              Expanded(
                child: _FacetPill(
                  score: match.weakest,
                  label: context.l10n.carouselLowest,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Slide three: the argument.
class _SplitSlide extends StatelessWidget {
  const _SplitSlide({required this.match});

  final CompatibilityMatch match;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final pull = match.pull;

    return StorySlide(
      seed: 43,
      glowAlignment: const Alignment(0, -0.15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Heading(pull.kind.label(context.l10n).toUpperCase()),
          const SizedBox(height: SanctumSpacing.xxl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _SplitEnd(
                  percent: pull.yourShare,
                  name: match.you.name,
                  element: match.you.sign.element,
                  leading: pull.leansYou,
                  align: CrossAxisAlignment.start,
                ),
              ),
              Expanded(
                child: _SplitEnd(
                  percent: pull.theirShare,
                  name: match.them.name,
                  element: match.them.sign.element,
                  leading: !pull.leansYou,
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: SanctumSpacing.lg),
          _SplitBar(match: match),
          const SizedBox(height: SanctumSpacing.xxl),
          Text(
            pull.line,
            style: type.quote.copyWith(fontSize: 23, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Slide four: the close.
class _VerdictSlide extends StatelessWidget {
  const _VerdictSlide({required this.match});

  final CompatibilityMatch match;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;

    return StorySlide(
      seed: 61,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SignAvatar(sign: match.you.sign, size: 54),
              const SizedBox(width: SanctumSpacing.md),
              SignAvatar(sign: match.them.sign, size: 54),
            ],
          ),
          const SizedBox(height: SanctumSpacing.xxl),
          Text(
            match.shareLine,
            style: type.quote.copyWith(fontSize: 30, height: 1.35),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SanctumSpacing.xxl),
          SizedBox(
            width: 64,
            child: Divider(color: colors.gold.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: SanctumSpacing.xl),
          Text(
            context.l10n.carouselFindYours,
            style: type.bodyLarge.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: SanctumSpacing.sm),
          Text(
            context.l10n.commonEntertainmentOnly,
            style: type.caption,
          ),
        ],
      ),
    );
  }
}

/// One person on the cover: disc, name, sign.
///
/// The name is scaled down rather than ellipsized. On the result screen
/// a clipped name is a small blemish; on an exported image it is
/// permanent, and "Selena Go..." beside a compatibility score reads as a
/// broken app to every person who sees the post.
class _Side extends StatelessWidget {
  const _Side({required this.person});

  final MatchPerson person;

  @override
  Widget build(BuildContext context) {
    final type = context.type;

    return Column(
      children: [
        SignAvatar(sign: person.sign, size: 84),
        const SizedBox(height: SanctumSpacing.sm),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            person.name,
            style: type.bodyLarge,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
        Text(person.sign.label(context.l10n), style: type.caption),
      ],
    );
  }
}

/// One end of the split: the number, then who it belongs to.
class _SplitEnd extends StatelessWidget {
  const _SplitEnd({
    required this.percent,
    required this.name,
    required this.element,
    required this.leading,
    required this.align,
  });

  final int percent;
  final String name;
  final ZodiacElement element;
  final bool leading;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final tint = ElementPalette.lead(element, colors);

    return Column(
      crossAxisAlignment: align,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$percent%',
            style: type.displayLarge.copyWith(
              fontSize: leading ? 54 : 40,
              color: leading ? tint : colors.textSecondary,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(name, style: type.bodyMedium, maxLines: 1),
        ),
      ],
    );
  }
}

/// The split itself, as one bar made of both people's element colours.
class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.match});

  final CompatibilityMatch match;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final yours = ElementPalette.lead(match.you.sign.element, colors);
    final theirs = ElementPalette.lead(match.them.sign.element, colors);

    return ClipRRect(
      borderRadius: SanctumRadii.pillAll,
      child: SizedBox(
        height: 10,
        child: Row(
          // Without `stretch` the bar lays out its 10pt and paints
          // nothing: a Row centres by default, which leaves its
          // children a *loose* height, and a childless ColoredBox takes
          // `constraints.smallest` — height zero. It is invisible on
          // screen and invisible in a widget test that only checks the
          // tree, which is how it survived to a device.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: match.pull.yourShare,
              child: ColoredBox(color: yours.withValues(alpha: 0.85)),
            ),
            const SizedBox(width: 3),
            Expanded(
              flex: match.pull.theirShare,
              child: ColoredBox(color: theirs.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A letterspaced overline.
class _Heading extends StatelessWidget {
  const _Heading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    // Scaled rather than wrapped. "WHO WANTS IT MORE" is already the
    // widest thing on this slide in English, and letter-spaced uppercase
    // grows fastest of anything when translated — German and Ukrainian
    // both run half again as long. Wrapping it to two lines pushes the
    // bar below it off the safe area; shrinking it is invisible.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: context.type.caption.copyWith(
          color: context.colors.gold,
          letterSpacing: 3,
        ),
      ),
    );
  }
}

/// The aspect name, in the same pill the result screen uses.
class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: SanctumRadii.pillAll,
        color: colors.glassFill,
        border: Border.all(color: colors.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SanctumSpacing.lg,
          vertical: SanctumSpacing.xs + 2,
        ),
        // A pill that wraps stops being a pill. The aspect names are one
        // word in English ("Magnetic") and are not everywhere, so the
        // text scales inside a fixed shape instead.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            style: context.type.caption.copyWith(
              color: colors.gold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// A facet and its score, as one small pill.
class _FacetPill extends StatelessWidget {
  const _FacetPill({
    required this.score,
    required this.label,
    required this.color,
  });

  final FacetScore score;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final type = context.type;

    return Column(
      children: [
        Text(
          label,
          style: type.caption.copyWith(color: color, letterSpacing: 2),
        ),
        const SizedBox(height: SanctumSpacing.xxs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${score.facet.label(context.l10n)} ${score.score}',
            style: type.bodyLarge.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
