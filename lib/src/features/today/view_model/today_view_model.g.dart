// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The live draw state for [day].

@ProviderFor(oracleDraw)
final oracleDrawProvider = OracleDrawFamily._();

/// The live draw state for [day].

final class OracleDrawProvider
    extends
        $FunctionalProvider<
          AsyncValue<OracleDrawState?>,
          OracleDrawState?,
          Stream<OracleDrawState?>
        >
    with $FutureModifier<OracleDrawState?>, $StreamProvider<OracleDrawState?> {
  /// The live draw state for [day].
  OracleDrawProvider._({
    required OracleDrawFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'oracleDrawProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$oracleDrawHash();

  @override
  String toString() {
    return r'oracleDrawProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<OracleDrawState?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<OracleDrawState?> create(Ref ref) {
    final argument = this.argument as DateTime;
    return oracleDraw(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OracleDrawProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$oracleDrawHash() => r'ff375c55ad4f55b3dbf3340afeab4d24471ab3ff';

/// The live draw state for [day].

final class OracleDrawFamily extends $Family
    with $FunctionalFamilyOverride<Stream<OracleDrawState?>, DateTime> {
  OracleDrawFamily._()
    : super(
        retry: null,
        name: r'oracleDrawProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The live draw state for [day].

  OracleDrawProvider call(DateTime day) =>
      OracleDrawProvider._(argument: day, from: this);

  @override
  String toString() => r'oracleDrawProvider';
}

/// The live streak as of [day].

@ProviderFor(streak)
final streakProvider = StreakFamily._();

/// The live streak as of [day].

final class StreakProvider
    extends
        $FunctionalProvider<
          AsyncValue<StreakSummary>,
          StreakSummary,
          Stream<StreakSummary>
        >
    with $FutureModifier<StreakSummary>, $StreamProvider<StreakSummary> {
  /// The live streak as of [day].
  StreakProvider._({
    required StreakFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'streakProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$streakHash();

  @override
  String toString() {
    return r'streakProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<StreakSummary> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<StreakSummary> create(Ref ref) {
    final argument = this.argument as DateTime;
    return streak(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StreakProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$streakHash() => r'755fed7e9868ff8f86c0631fb85ad7ef946bd5cc';

/// The live streak as of [day].

final class StreakFamily extends $Family
    with $FunctionalFamilyOverride<Stream<StreakSummary>, DateTime> {
  StreakFamily._()
    : super(
        retry: null,
        name: r'streakProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The live streak as of [day].

  StreakProvider call(DateTime day) =>
      StreakProvider._(argument: day, from: this);

  @override
  String toString() => r'streakProvider';
}

/// The live energy check-in for [day].

@ProviderFor(energyFor)
final energyForProvider = EnergyForFamily._();

/// The live energy check-in for [day].

final class EnergyForProvider
    extends
        $FunctionalProvider<
          AsyncValue<EnergyCheckIn?>,
          EnergyCheckIn?,
          Stream<EnergyCheckIn?>
        >
    with $FutureModifier<EnergyCheckIn?>, $StreamProvider<EnergyCheckIn?> {
  /// The live energy check-in for [day].
  EnergyForProvider._({
    required EnergyForFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'energyForProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$energyForHash();

  @override
  String toString() {
    return r'energyForProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<EnergyCheckIn?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<EnergyCheckIn?> create(Ref ref) {
    final argument = this.argument as DateTime;
    return energyFor(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EnergyForProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$energyForHash() => r'c94da3bdd8e53c55971d9f60812c21e29d731181';

/// The live energy check-in for [day].

final class EnergyForFamily extends $Family
    with $FunctionalFamilyOverride<Stream<EnergyCheckIn?>, DateTime> {
  EnergyForFamily._()
    : super(
        retry: null,
        name: r'energyForProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The live energy check-in for [day].

  EnergyForProvider call(DateTime day) =>
      EnergyForProvider._(argument: day, from: this);

  @override
  String toString() => r'energyForProvider';
}

/// Composes the Today screen's state.

@ProviderFor(todayState)
final todayStateProvider = TodayStateProvider._();

/// Composes the Today screen's state.

final class TodayStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<TodayUiState>,
          TodayUiState,
          FutureOr<TodayUiState>
        >
    with $FutureModifier<TodayUiState>, $FutureProvider<TodayUiState> {
  /// Composes the Today screen's state.
  TodayStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayStateHash();

  @$internal
  @override
  $FutureProviderElement<TodayUiState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TodayUiState> create(Ref ref) {
    return todayState(ref);
  }
}

String _$todayStateHash() => r'0cd90ad57932619a6fdaa086f077e184c14fca74';

/// Actions the Today screen can take.
///
/// The command pattern: each method moves this notifier through
/// loading → data/error, so the UI can disable a control while its write
/// is in flight and surface a failure without the screen itself ever
/// touching a repository or writing a `try`.

@ProviderFor(TodayController)
final todayControllerProvider = TodayControllerProvider._();

/// Actions the Today screen can take.
///
/// The command pattern: each method moves this notifier through
/// loading → data/error, so the UI can disable a control while its write
/// is in flight and surface a failure without the screen itself ever
/// touching a repository or writing a `try`.
final class TodayControllerProvider
    extends $AsyncNotifierProvider<TodayController, void> {
  /// Actions the Today screen can take.
  ///
  /// The command pattern: each method moves this notifier through
  /// loading → data/error, so the UI can disable a control while its write
  /// is in flight and surface a failure without the screen itself ever
  /// touching a repository or writing a `try`.
  TodayControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayControllerHash();

  @$internal
  @override
  TodayController create() => TodayController();
}

String _$todayControllerHash() => r'4fbab04e2ed1c911b385f203a1233bafd027b269';

/// Actions the Today screen can take.
///
/// The command pattern: each method moves this notifier through
/// loading → data/error, so the UI can disable a control while its write
/// is in flight and surface a failure without the screen itself ever
/// touching a repository or writing a `try`.

abstract class _$TodayController extends $AsyncNotifier<void> {
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
