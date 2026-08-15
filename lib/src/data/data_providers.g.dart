// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The database. One per app, closed when the container is disposed.

@ProviderFor(sanctumDatabase)
final sanctumDatabaseProvider = SanctumDatabaseProvider._();

/// The database. One per app, closed when the container is disposed.

final class SanctumDatabaseProvider
    extends
        $FunctionalProvider<SanctumDatabase, SanctumDatabase, SanctumDatabase>
    with $Provider<SanctumDatabase> {
  /// The database. One per app, closed when the container is disposed.
  SanctumDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sanctumDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sanctumDatabaseHash();

  @$internal
  @override
  $ProviderElement<SanctumDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SanctumDatabase create(Ref ref) {
    return sanctumDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SanctumDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SanctumDatabase>(value),
    );
  }
}

String _$sanctumDatabaseHash() => r'4258745390acaaccb1fde5596a66c70ddbde4b3a';

/// Where bundled content is read from.

@ProviderFor(contentCatalogSource)
final contentCatalogSourceProvider = ContentCatalogSourceProvider._();

/// Where bundled content is read from.

final class ContentCatalogSourceProvider
    extends
        $FunctionalProvider<
          ContentCatalogSource,
          ContentCatalogSource,
          ContentCatalogSource
        >
    with $Provider<ContentCatalogSource> {
  /// Where bundled content is read from.
  ContentCatalogSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentCatalogSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentCatalogSourceHash();

  @$internal
  @override
  $ProviderElement<ContentCatalogSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContentCatalogSource create(Ref ref) {
    return contentCatalogSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentCatalogSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContentCatalogSource>(value),
    );
  }
}

String _$contentCatalogSourceHash() =>
    r'6c490f8a6ac8759cd9e943d5a19304c33582d2dc';

/// The parsed content catalogue.
///
/// ## Where `Result` stops and `AsyncValue` starts
///
/// The data layer returns [Result] so failure is in the type and cannot
/// be forgotten. Riverpod already models loading/data/error as
/// `AsyncValue`, so re-wrapping a `Result` inside one would give the UI
/// two error channels to handle for the same failure.
///
/// This provider is the boundary: it unwraps the [Result] and rethrows
/// the failure, letting `AsyncValue.error` carry it from here on. That is
/// why `AppFailure` implements `Exception`.

@ProviderFor(contentCatalog)
final contentCatalogProvider = ContentCatalogProvider._();

/// The parsed content catalogue.
///
/// ## Where `Result` stops and `AsyncValue` starts
///
/// The data layer returns [Result] so failure is in the type and cannot
/// be forgotten. Riverpod already models loading/data/error as
/// `AsyncValue`, so re-wrapping a `Result` inside one would give the UI
/// two error channels to handle for the same failure.
///
/// This provider is the boundary: it unwraps the [Result] and rethrows
/// the failure, letting `AsyncValue.error` carry it from here on. That is
/// why `AppFailure` implements `Exception`.

final class ContentCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<ContentCatalog>,
          ContentCatalog,
          FutureOr<ContentCatalog>
        >
    with $FutureModifier<ContentCatalog>, $FutureProvider<ContentCatalog> {
  /// The parsed content catalogue.
  ///
  /// ## Where `Result` stops and `AsyncValue` starts
  ///
  /// The data layer returns [Result] so failure is in the type and cannot
  /// be forgotten. Riverpod already models loading/data/error as
  /// `AsyncValue`, so re-wrapping a `Result` inside one would give the UI
  /// two error channels to handle for the same failure.
  ///
  /// This provider is the boundary: it unwraps the [Result] and rethrows
  /// the failure, letting `AsyncValue.error` carry it from here on. That is
  /// why `AppFailure` implements `Exception`.
  ContentCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentCatalogHash();

  @$internal
  @override
  $FutureProviderElement<ContentCatalog> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ContentCatalog> create(Ref ref) {
    return contentCatalog(ref);
  }
}

String _$contentCatalogHash() => r'6122fcc665cd5f0aaeb63b43f7e844896bc0ad1a';

/// Stable per-install salt for daily content selection.

@ProviderFor(installSalt)
final installSaltProvider = InstallSaltProvider._();

/// Stable per-install salt for daily content selection.

final class InstallSaltProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Stable per-install salt for daily content selection.
  InstallSaltProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installSaltProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installSaltHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return installSalt(ref);
  }
}

String _$installSaltHash() => r'a87574b587746ed84c31dbf0eb13eecd4084e8e8';

/// Onboarding quiz answers.

@ProviderFor(quizRepository)
final quizRepositoryProvider = QuizRepositoryProvider._();

/// Onboarding quiz answers.

final class QuizRepositoryProvider
    extends $FunctionalProvider<QuizRepository, QuizRepository, QuizRepository>
    with $Provider<QuizRepository> {
  /// Onboarding quiz answers.
  QuizRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quizRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quizRepositoryHash();

  @$internal
  @override
  $ProviderElement<QuizRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  QuizRepository create(Ref ref) {
    return quizRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuizRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuizRepository>(value),
    );
  }
}

String _$quizRepositoryHash() => r'884cbc1405198588dc08879690662c1403dd7977';

/// App settings store.

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

/// App settings store.

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  /// App settings store.
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'7433501c35d2c407f588cefd66620ee7317960fa';

/// Practice log and streaks.

@ProviderFor(practiceRepository)
final practiceRepositoryProvider = PracticeRepositoryProvider._();

/// Practice log and streaks.

final class PracticeRepositoryProvider
    extends
        $FunctionalProvider<
          PracticeRepository,
          PracticeRepository,
          PracticeRepository
        >
    with $Provider<PracticeRepository> {
  /// Practice log and streaks.
  PracticeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'practiceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$practiceRepositoryHash();

  @$internal
  @override
  $ProviderElement<PracticeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PracticeRepository create(Ref ref) {
    return practiceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PracticeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PracticeRepository>(value),
    );
  }
}

String _$practiceRepositoryHash() =>
    r'92d0141857009e695f9e04253cf763b8dd896140';

/// Journal entries.

@ProviderFor(journalRepository)
final journalRepositoryProvider = JournalRepositoryProvider._();

/// Journal entries.

final class JournalRepositoryProvider
    extends
        $FunctionalProvider<
          JournalRepository,
          JournalRepository,
          JournalRepository
        >
    with $Provider<JournalRepository> {
  /// Journal entries.
  JournalRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'journalRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$journalRepositoryHash();

  @$internal
  @override
  $ProviderElement<JournalRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JournalRepository create(Ref ref) {
    return journalRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JournalRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JournalRepository>(value),
    );
  }
}

String _$journalRepositoryHash() => r'5752c5e4d0bcf2606f172b01f4282c9bb0b0da1c';

/// Energy check-ins.

@ProviderFor(energyRepository)
final energyRepositoryProvider = EnergyRepositoryProvider._();

/// Energy check-ins.

final class EnergyRepositoryProvider
    extends
        $FunctionalProvider<
          EnergyRepository,
          EnergyRepository,
          EnergyRepository
        >
    with $Provider<EnergyRepository> {
  /// Energy check-ins.
  EnergyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'energyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$energyRepositoryHash();

  @$internal
  @override
  $ProviderElement<EnergyRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EnergyRepository create(Ref ref) {
    return energyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EnergyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EnergyRepository>(value),
    );
  }
}

String _$energyRepositoryHash() => r'4750b112dcd5daa92fe8900c5346c176d5fa499c';

/// Oracle draws.

@ProviderFor(oracleRepository)
final oracleRepositoryProvider = OracleRepositoryProvider._();

/// Oracle draws.

final class OracleRepositoryProvider
    extends
        $FunctionalProvider<
          OracleRepository,
          OracleRepository,
          OracleRepository
        >
    with $Provider<OracleRepository> {
  /// Oracle draws.
  OracleRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'oracleRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$oracleRepositoryHash();

  @$internal
  @override
  $ProviderElement<OracleRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OracleRepository create(Ref ref) {
    return oracleRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OracleRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OracleRepository>(value),
    );
  }
}

String _$oracleRepositoryHash() => r'd85c6ed579933f78a5f5333a21fd9f134f558f95';

/// The local stand-in for a real store.
///
/// One object serves both interfaces below, exactly as RevenueCat's
/// `Purchases` does. Replacing it means changing these three providers
/// and nothing else in the app.

@ProviderFor(subscriptionStore)
final subscriptionStoreProvider = SubscriptionStoreProvider._();

/// The local stand-in for a real store.
///
/// One object serves both interfaces below, exactly as RevenueCat's
/// `Purchases` does. Replacing it means changing these three providers
/// and nothing else in the app.

final class SubscriptionStoreProvider
    extends
        $FunctionalProvider<
          LocalSubscriptionRepository,
          LocalSubscriptionRepository,
          LocalSubscriptionRepository
        >
    with $Provider<LocalSubscriptionRepository> {
  /// The local stand-in for a real store.
  ///
  /// One object serves both interfaces below, exactly as RevenueCat's
  /// `Purchases` does. Replacing it means changing these three providers
  /// and nothing else in the app.
  SubscriptionStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionStoreHash();

  @$internal
  @override
  $ProviderElement<LocalSubscriptionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalSubscriptionRepository create(Ref ref) {
    return subscriptionStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalSubscriptionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalSubscriptionRepository>(value),
    );
  }
}

String _$subscriptionStoreHash() => r'f179b1c4d66a720d3a612cc6fb47b6fa7d492789';

/// What the user has access to. Most features depend only on this.

@ProviderFor(entitlementRepository)
final entitlementRepositoryProvider = EntitlementRepositoryProvider._();

/// What the user has access to. Most features depend only on this.

final class EntitlementRepositoryProvider
    extends
        $FunctionalProvider<
          EntitlementRepository,
          EntitlementRepository,
          EntitlementRepository
        >
    with $Provider<EntitlementRepository> {
  /// What the user has access to. Most features depend only on this.
  EntitlementRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entitlementRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entitlementRepositoryHash();

  @$internal
  @override
  $ProviderElement<EntitlementRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EntitlementRepository create(Ref ref) {
    return entitlementRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EntitlementRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EntitlementRepository>(value),
    );
  }
}

String _$entitlementRepositoryHash() =>
    r'a2dfe84e7d85f17110685d4187316c677fdfb234';

/// Buying a subscription. Only the paywall depends on this.

@ProviderFor(subscriptionRepository)
final subscriptionRepositoryProvider = SubscriptionRepositoryProvider._();

/// Buying a subscription. Only the paywall depends on this.

final class SubscriptionRepositoryProvider
    extends
        $FunctionalProvider<
          SubscriptionRepository,
          SubscriptionRepository,
          SubscriptionRepository
        >
    with $Provider<SubscriptionRepository> {
  /// Buying a subscription. Only the paywall depends on this.
  SubscriptionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionRepositoryHash();

  @$internal
  @override
  $ProviderElement<SubscriptionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubscriptionRepository create(Ref ref) {
    return subscriptionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubscriptionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubscriptionRepository>(value),
    );
  }
}

String _$subscriptionRepositoryHash() =>
    r'447120aac583ff1d50358205776ac29512f7f8e6';

/// The live entitlement, as a stream.

@ProviderFor(entitlement)
final entitlementProvider = EntitlementProvider._();

/// The live entitlement, as a stream.

final class EntitlementProvider
    extends
        $FunctionalProvider<
          AsyncValue<SanctumEntitlement>,
          SanctumEntitlement,
          Stream<SanctumEntitlement>
        >
    with
        $FutureModifier<SanctumEntitlement>,
        $StreamProvider<SanctumEntitlement> {
  /// The live entitlement, as a stream.
  EntitlementProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'entitlementProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$entitlementHash();

  @$internal
  @override
  $StreamProviderElement<SanctumEntitlement> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SanctumEntitlement> create(Ref ref) {
    return entitlement(ref);
  }
}

String _$entitlementHash() => r'b8ea13314f647e8c6e72f3693d84a54a025f8db3';

/// Whether the user is premium right now.

@ProviderFor(isPremium)
final isPremiumProvider = IsPremiumProvider._();

/// Whether the user is premium right now.

final class IsPremiumProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the user is premium right now.
  IsPremiumProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isPremiumProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isPremiumHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isPremium(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isPremiumHash() => r'e079d23048ddc9ea4741240628c9ad4cd5731e44';

/// The audio engine.
///
/// Overridden in `bootstrap()` with the handler returned by
/// `AudioService.init()`. It cannot be constructed lazily here because
/// initialising the background service is async and must happen exactly
/// once, before the first frame — so this throws rather than silently
/// handing out a second, non-background player.

@ProviderFor(audioService)
final audioServiceProvider = AudioServiceProvider._();

/// The audio engine.
///
/// Overridden in `bootstrap()` with the handler returned by
/// `AudioService.init()`. It cannot be constructed lazily here because
/// initialising the background service is async and must happen exactly
/// once, before the first frame — so this throws rather than silently
/// handing out a second, non-background player.

final class AudioServiceProvider
    extends
        $FunctionalProvider<
          SanctumAudioService,
          SanctumAudioService,
          SanctumAudioService
        >
    with $Provider<SanctumAudioService> {
  /// The audio engine.
  ///
  /// Overridden in `bootstrap()` with the handler returned by
  /// `AudioService.init()`. It cannot be constructed lazily here because
  /// initialising the background service is async and must happen exactly
  /// once, before the first frame — so this throws rather than silently
  /// handing out a second, non-background player.
  AudioServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioServiceHash();

  @$internal
  @override
  $ProviderElement<SanctumAudioService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SanctumAudioService create(Ref ref) {
    return audioService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SanctumAudioService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SanctumAudioService>(value),
    );
  }
}

String _$audioServiceHash() => r'8fdf76ae6b2e224db8f17e8b5ddaa61e5f96cc9e';

/// Live session progress.

@ProviderFor(sessionPlayback)
final sessionPlaybackProvider = SessionPlaybackProvider._();

/// Live session progress.

final class SessionPlaybackProvider
    extends
        $FunctionalProvider<
          AsyncValue<SessionPlaybackState>,
          SessionPlaybackState,
          Stream<SessionPlaybackState>
        >
    with
        $FutureModifier<SessionPlaybackState>,
        $StreamProvider<SessionPlaybackState> {
  /// Live session progress.
  SessionPlaybackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionPlaybackProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionPlaybackHash();

  @$internal
  @override
  $StreamProviderElement<SessionPlaybackState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SessionPlaybackState> create(Ref ref) {
    return sessionPlayback(ref);
  }
}

String _$sessionPlaybackHash() => r'4a69acd1b3f97f6c24543881fba8b2905393f81f';
