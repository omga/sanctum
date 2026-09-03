import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanctum/src/domain/models/paywall.dart';
import 'package:sanctum/src/features/paywall/view_model/paywall_view_model.dart';
import 'package:sanctum/src/routing/app_router.dart';

/// Watches for an earned moment and opens the paywall when one arrives.
///
/// Wrapped around the Today screen rather than pushed from a dozen call
/// sites, so there is exactly one place that can open the paywall
/// automatically — which is what makes "am I nagging people?" an
/// answerable question.
///
/// It checks once per mount. Not on a timer, not on every rebuild: a
/// paywall that can appear while someone is mid-tap is how you get a
/// purchase the user did not mean to make, and then a refund.
class PaywallPresenter extends ConsumerStatefulWidget {
  /// Wraps [child].
  const PaywallPresenter({required this.child, super.key});

  /// The screen underneath.
  final Widget child;

  @override
  ConsumerState<PaywallPresenter> createState() => _PaywallPresenterState();
}

class _PaywallPresenterState extends ConsumerState<PaywallPresenter> {
  /// Guards against a second presentation within one app run, however
  /// many times this widget rebuilds.
  static bool _shownThisLaunch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_check()));
  }

  Future<void> _check() async {
    if (_shownThisLaunch) return;

    // The subscription is the fix, not ceremony. `paywallDecision` is
    // auto-dispose and awaits `streakProvider`, a Drift stream that has
    // not emitted when this runs on launch. A bare
    // `ref.read(...future)` registers no listener, so Riverpod collects
    // the whole chain on the next scheduler pass — before the first row
    // arrives — and the await completes with `Bad state: the provider
    // streakProvider(...) was disposed during loading state`.
    //
    // The visible symptom was nothing at all: an error logged to the VM
    // service, and an automatic paywall that never appeared. That is the
    // fourth time an auto-dispose provider reached only through
    // `ref.read` has failed silently in this codebase — see the handoff.
    // Holding a listener across the await is what keeps it alive; the
    // listener itself has nothing to do.
    final subscription = ref.listenManual(
      paywallDecisionProvider(),
      (_, _) {},
    );

    final PaywallDecision decision;
    try {
      decision = await ref.read(paywallDecisionProvider().future);
    } finally {
      subscription.close();
    }
    if (!mounted) return;

    if (decision case ShowPaywall(:final moment)) {
      _shownThisLaunch = true;
      unawaited(PaywallRoute(moment: moment).push<void>(context));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
