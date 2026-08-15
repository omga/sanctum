// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paywall_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Gathers the real signals the trigger needs.
///
/// This is the only place that knows *where* each signal lives — the
/// database, preferences, the clock. [PaywallTrigger] stays a pure
/// function of the resulting value object, which is why its rules can be
/// tested across a simulated two-year journey in milliseconds.

@ProviderFor(paywallSignals)
final paywallSignalsProvider = PaywallSignalsFamily._();

/// Gathers the real signals the trigger needs.
///
/// This is the only place that knows *where* each signal lives — the
/// database, preferences, the clock. [PaywallTrigger] stays a pure
/// function of the resulting value object, which is why its rules can be
/// tested across a simulated two-year journey in milliseconds.

final class PaywallSignalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaywallSignals>,
          PaywallSignals,
          FutureOr<PaywallSignals>
        >
    with $FutureModifier<PaywallSignals>, $FutureProvider<PaywallSignals> {
  /// Gathers the real signals the trigger needs.
  ///
  /// This is the only place that knows *where* each signal lives — the
  /// database, preferences, the clock. [PaywallTrigger] stays a pure
  /// function of the resulting value object, which is why its rules can be
  /// tested across a simulated two-year journey in milliseconds.
  PaywallSignalsProvider._({
    required PaywallSignalsFamily super.from,
    required bool super.argument,
  }) : super(
         retry: null,
         name: r'paywallSignalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$paywallSignalsHash();

  @override
  String toString() {
    return r'paywallSignalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PaywallSignals> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaywallSignals> create(Ref ref) {
    final argument = this.argument as bool;
    return paywallSignals(ref, explicitIntent: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PaywallSignalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$paywallSignalsHash() => r'90d841690b5deb72f47288800c30560b9ce08bea';

/// Gathers the real signals the trigger needs.
///
/// This is the only place that knows *where* each signal lives — the
/// database, preferences, the clock. [PaywallTrigger] stays a pure
/// function of the resulting value object, which is why its rules can be
/// tested across a simulated two-year journey in milliseconds.

final class PaywallSignalsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PaywallSignals>, bool> {
  PaywallSignalsFamily._()
    : super(
        retry: null,
        name: r'paywallSignalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Gathers the real signals the trigger needs.
  ///
  /// This is the only place that knows *where* each signal lives — the
  /// database, preferences, the clock. [PaywallTrigger] stays a pure
  /// function of the resulting value object, which is why its rules can be
  /// tested across a simulated two-year journey in milliseconds.

  PaywallSignalsProvider call({bool explicitIntent = false}) =>
      PaywallSignalsProvider._(argument: explicitIntent, from: this);

  @override
  String toString() => r'paywallSignalsProvider';
}

/// Whether to show the paywall right now, and how to frame it.

@ProviderFor(paywallDecision)
final paywallDecisionProvider = PaywallDecisionFamily._();

/// Whether to show the paywall right now, and how to frame it.

final class PaywallDecisionProvider
    extends
        $FunctionalProvider<
          AsyncValue<PaywallDecision>,
          PaywallDecision,
          FutureOr<PaywallDecision>
        >
    with $FutureModifier<PaywallDecision>, $FutureProvider<PaywallDecision> {
  /// Whether to show the paywall right now, and how to frame it.
  PaywallDecisionProvider._({
    required PaywallDecisionFamily super.from,
    required bool super.argument,
  }) : super(
         retry: null,
         name: r'paywallDecisionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$paywallDecisionHash();

  @override
  String toString() {
    return r'paywallDecisionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PaywallDecision> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PaywallDecision> create(Ref ref) {
    final argument = this.argument as bool;
    return paywallDecision(ref, explicitIntent: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PaywallDecisionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$paywallDecisionHash() => r'b1f2f68984fbacdc39b1baa7ee0879803a999bf3';

/// Whether to show the paywall right now, and how to frame it.

final class PaywallDecisionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PaywallDecision>, bool> {
  PaywallDecisionFamily._()
    : super(
        retry: null,
        name: r'paywallDecisionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether to show the paywall right now, and how to frame it.

  PaywallDecisionProvider call({bool explicitIntent = false}) =>
      PaywallDecisionProvider._(argument: explicitIntent, from: this);

  @override
  String toString() => r'paywallDecisionProvider';
}

/// The purchasable plans.

@ProviderFor(subscriptionPlans)
final subscriptionPlansProvider = SubscriptionPlansProvider._();

/// The purchasable plans.

final class SubscriptionPlansProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SubscriptionPlan>>,
          List<SubscriptionPlan>,
          FutureOr<List<SubscriptionPlan>>
        >
    with
        $FutureModifier<List<SubscriptionPlan>>,
        $FutureProvider<List<SubscriptionPlan>> {
  /// The purchasable plans.
  SubscriptionPlansProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionPlansProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionPlansHash();

  @$internal
  @override
  $FutureProviderElement<List<SubscriptionPlan>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SubscriptionPlan>> create(Ref ref) {
    return subscriptionPlans(ref);
  }
}

String _$subscriptionPlansHash() => r'2cea06741067e4ced788a3af9d0bab649fb3cc22';

/// Purchase, restore, and recording impressions.

@ProviderFor(PaywallController)
final paywallControllerProvider = PaywallControllerProvider._();

/// Purchase, restore, and recording impressions.
final class PaywallControllerProvider
    extends $AsyncNotifierProvider<PaywallController, void> {
  /// Purchase, restore, and recording impressions.
  PaywallControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paywallControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paywallControllerHash();

  @$internal
  @override
  PaywallController create() => PaywallController();
}

String _$paywallControllerHash() => r'f3614108e45772f8ee9506ed77cbe0db32823618';

/// Purchase, restore, and recording impressions.

abstract class _$PaywallController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
