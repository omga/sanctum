import 'package:flutter/material.dart';
import 'package:sanctum/src/design_system/tokens/sanctum_motion.dart';

/// Cross-fades between the shell's branches.
///
/// ## Why a Stack and not an AnimatedSwitcher
///
/// Every branch stays mounted. That is the whole point of a stateful
/// shell: the Sound tab keeps playing, the Journal keeps its scroll
/// offset, and Today does not refetch when you come back to it. An
/// `AnimatedSwitcher` would dispose the outgoing branch and undo all of
/// that, so the animation has to happen *around* a Stack that never lets
/// anything go.
///
/// ## What this costs, and what stops it costing more
///
/// An opacity layer is the expensive part of a cross-fade, and this app
/// already runs a fragment shader and a starfield ticker behind every
/// screen — so the budget is genuinely tight.
///
/// Three things keep it cheap:
///
/// - **A branch at opacity 0 is not painted at all.** `AnimatedOpacity`
///   short-circuits, so idle branches cost nothing beyond layout, and
///   layout of an unchanged subtree is a relayout boundary.
/// - **The outgoing branch leaves faster than the incoming arrives**
///   ([_exit] vs [_enter]), so the window where two layers are composited
///   is about a third of the transition rather than all of it.
/// - **Inactive branches have their tickers switched off.** Without
///   `TickerMode`, every `flutter_animate` entry and every
///   `TweenAnimationBuilder` on three hidden screens keeps driving frames
///   for a user who is looking at the fourth.
///
/// The movement itself is transform-only — a small rise and a hair of
/// scale — because transforms are effectively free next to compositing.
class BranchSwitcher extends StatelessWidget {
  /// Creates a switcher.
  const BranchSwitcher({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  /// The branch currently selected.
  final int currentIndex;

  /// One navigator per branch, in branch order.
  final List<Widget> children;

  /// How long the incoming branch takes to settle.
  static const _enter = Duration(milliseconds: 260);

  /// How long the outgoing branch takes to clear. Deliberately shorter.
  static const _exit = Duration(milliseconds: 110);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final (index, child) in children.indexed)
          _Branch(
            key: ValueKey(index),
            active: index == currentIndex,
            child: child,
          ),
      ],
    );
  }
}

class _Branch extends StatelessWidget {
  const _Branch({required this.active, required this.child, super.key});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Ordering here is load-bearing, and getting it wrong does not look
    // like a bug in a widget test — it looks like a stuck screen on a
    // device. TickerMode must sit *inside* the animations, wrapping only
    // the branch content.
    //
    // With it on the outside, switching away disables the ticker on the
    // very frame the branch starts leaving, which freezes the
    // AnimatedOpacity driving its own fade-out. The outgoing branch then
    // stops at whatever opacity it reached in that first frame and stays
    // there, permanently painted over the incoming one.
    return IgnorePointer(
      ignoring: !active,
      child: AnimatedOpacity(
        opacity: active ? 1 : 0,
        duration: active ? BranchSwitcher._enter : BranchSwitcher._exit,
        curve: active ? SanctumMotion.enter : SanctumMotion.exit,
        child: AnimatedScale(
          scale: active ? 1 : 0.985,
          duration: BranchSwitcher._enter,
          curve: SanctumMotion.enter,
          child: AnimatedSlide(
            offset: active ? Offset.zero : const Offset(0, 0.012),
            duration: BranchSwitcher._enter,
            curve: SanctumMotion.enter,
            child: TickerMode(
              enabled: active,
              // Keeps a branch mid-transition from marking the aurora
              // and starfield behind it dirty every frame.
              child: RepaintBoundary(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
