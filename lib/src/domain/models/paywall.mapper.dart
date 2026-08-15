// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'paywall.dart';

class PaywallMomentMapper extends EnumMapper<PaywallMoment> {
  PaywallMomentMapper._();

  static PaywallMomentMapper? _instance;
  static PaywallMomentMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PaywallMomentMapper._());
    }
    return _instance!;
  }

  static PaywallMoment fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  PaywallMoment decode(dynamic value) {
    switch (value) {
      case r'lockedContent':
        return PaywallMoment.lockedContent;
      case r'streakEarned':
        return PaywallMoment.streakEarned;
      case r'ritualCompleted':
        return PaywallMoment.ritualCompleted;
      case r'sessionsSampled':
        return PaywallMoment.sessionsSampled;
      case r'returningUser':
        return PaywallMoment.returningUser;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(PaywallMoment self) {
    switch (self) {
      case PaywallMoment.lockedContent:
        return r'lockedContent';
      case PaywallMoment.streakEarned:
        return r'streakEarned';
      case PaywallMoment.ritualCompleted:
        return r'ritualCompleted';
      case PaywallMoment.sessionsSampled:
        return r'sessionsSampled';
      case PaywallMoment.returningUser:
        return r'returningUser';
    }
  }
}

extension PaywallMomentMapperExtension on PaywallMoment {
  String toValue() {
    PaywallMomentMapper.ensureInitialized();
    return MapperContainer.globals.toValue<PaywallMoment>(this) as String;
  }
}

class PaywallSignalsMapper extends ClassMapperBase<PaywallSignals> {
  PaywallSignalsMapper._();

  static PaywallSignalsMapper? _instance;
  static PaywallSignalsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PaywallSignalsMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'PaywallSignals';

  static bool _$isPremium(PaywallSignals v) => v.isPremium;
  static const Field<PaywallSignals, bool> _f$isPremium = Field(
    'isPremium',
    _$isPremium,
  );
  static int _$daysSinceInstall(PaywallSignals v) => v.daysSinceInstall;
  static const Field<PaywallSignals, int> _f$daysSinceInstall = Field(
    'daysSinceInstall',
    _$daysSinceInstall,
  );
  static int _$sessionsCompleted(PaywallSignals v) => v.sessionsCompleted;
  static const Field<PaywallSignals, int> _f$sessionsCompleted = Field(
    'sessionsCompleted',
    _$sessionsCompleted,
  );
  static int _$currentStreak(PaywallSignals v) => v.currentStreak;
  static const Field<PaywallSignals, int> _f$currentStreak = Field(
    'currentStreak',
    _$currentStreak,
  );
  static int _$ritualsCompleted(PaywallSignals v) => v.ritualsCompleted;
  static const Field<PaywallSignals, int> _f$ritualsCompleted = Field(
    'ritualsCompleted',
    _$ritualsCompleted,
  );
  static int _$timesShown(PaywallSignals v) => v.timesShown;
  static const Field<PaywallSignals, int> _f$timesShown = Field(
    'timesShown',
    _$timesShown,
  );
  static int _$timesDismissed(PaywallSignals v) => v.timesDismissed;
  static const Field<PaywallSignals, int> _f$timesDismissed = Field(
    'timesDismissed',
    _$timesDismissed,
  );
  static int? _$daysSinceLastShown(PaywallSignals v) => v.daysSinceLastShown;
  static const Field<PaywallSignals, int> _f$daysSinceLastShown = Field(
    'daysSinceLastShown',
    _$daysSinceLastShown,
    opt: true,
  );
  static bool _$explicitIntent(PaywallSignals v) => v.explicitIntent;
  static const Field<PaywallSignals, bool> _f$explicitIntent = Field(
    'explicitIntent',
    _$explicitIntent,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<PaywallSignals> fields = const {
    #isPremium: _f$isPremium,
    #daysSinceInstall: _f$daysSinceInstall,
    #sessionsCompleted: _f$sessionsCompleted,
    #currentStreak: _f$currentStreak,
    #ritualsCompleted: _f$ritualsCompleted,
    #timesShown: _f$timesShown,
    #timesDismissed: _f$timesDismissed,
    #daysSinceLastShown: _f$daysSinceLastShown,
    #explicitIntent: _f$explicitIntent,
  };

  static PaywallSignals _instantiate(DecodingData data) {
    return PaywallSignals(
      isPremium: data.dec(_f$isPremium),
      daysSinceInstall: data.dec(_f$daysSinceInstall),
      sessionsCompleted: data.dec(_f$sessionsCompleted),
      currentStreak: data.dec(_f$currentStreak),
      ritualsCompleted: data.dec(_f$ritualsCompleted),
      timesShown: data.dec(_f$timesShown),
      timesDismissed: data.dec(_f$timesDismissed),
      daysSinceLastShown: data.dec(_f$daysSinceLastShown),
      explicitIntent: data.dec(_f$explicitIntent),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PaywallSignals fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PaywallSignals>(map);
  }

  static PaywallSignals fromJson(String json) {
    return ensureInitialized().decodeJson<PaywallSignals>(json);
  }
}

mixin PaywallSignalsMappable {
  String toJson() {
    return PaywallSignalsMapper.ensureInitialized().encodeJson<PaywallSignals>(
      this as PaywallSignals,
    );
  }

  Map<String, dynamic> toMap() {
    return PaywallSignalsMapper.ensureInitialized().encodeMap<PaywallSignals>(
      this as PaywallSignals,
    );
  }

  PaywallSignalsCopyWith<PaywallSignals, PaywallSignals, PaywallSignals>
  get copyWith => _PaywallSignalsCopyWithImpl<PaywallSignals, PaywallSignals>(
    this as PaywallSignals,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return PaywallSignalsMapper.ensureInitialized().stringifyValue(
      this as PaywallSignals,
    );
  }

  @override
  bool operator ==(Object other) {
    return PaywallSignalsMapper.ensureInitialized().equalsValue(
      this as PaywallSignals,
      other,
    );
  }

  @override
  int get hashCode {
    return PaywallSignalsMapper.ensureInitialized().hashValue(
      this as PaywallSignals,
    );
  }
}

extension PaywallSignalsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PaywallSignals, $Out> {
  PaywallSignalsCopyWith<$R, PaywallSignals, $Out> get $asPaywallSignals =>
      $base.as((v, t, t2) => _PaywallSignalsCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PaywallSignalsCopyWith<$R, $In extends PaywallSignals, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    bool? isPremium,
    int? daysSinceInstall,
    int? sessionsCompleted,
    int? currentStreak,
    int? ritualsCompleted,
    int? timesShown,
    int? timesDismissed,
    int? daysSinceLastShown,
    bool? explicitIntent,
  });
  PaywallSignalsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PaywallSignalsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PaywallSignals, $Out>
    implements PaywallSignalsCopyWith<$R, PaywallSignals, $Out> {
  _PaywallSignalsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PaywallSignals> $mapper =
      PaywallSignalsMapper.ensureInitialized();
  @override
  $R call({
    bool? isPremium,
    int? daysSinceInstall,
    int? sessionsCompleted,
    int? currentStreak,
    int? ritualsCompleted,
    int? timesShown,
    int? timesDismissed,
    Object? daysSinceLastShown = $none,
    bool? explicitIntent,
  }) => $apply(
    FieldCopyWithData({
      if (isPremium != null) #isPremium: isPremium,
      if (daysSinceInstall != null) #daysSinceInstall: daysSinceInstall,
      if (sessionsCompleted != null) #sessionsCompleted: sessionsCompleted,
      if (currentStreak != null) #currentStreak: currentStreak,
      if (ritualsCompleted != null) #ritualsCompleted: ritualsCompleted,
      if (timesShown != null) #timesShown: timesShown,
      if (timesDismissed != null) #timesDismissed: timesDismissed,
      if (daysSinceLastShown != $none) #daysSinceLastShown: daysSinceLastShown,
      if (explicitIntent != null) #explicitIntent: explicitIntent,
    }),
  );
  @override
  PaywallSignals $make(CopyWithData data) => PaywallSignals(
    isPremium: data.get(#isPremium, or: $value.isPremium),
    daysSinceInstall: data.get(#daysSinceInstall, or: $value.daysSinceInstall),
    sessionsCompleted: data.get(
      #sessionsCompleted,
      or: $value.sessionsCompleted,
    ),
    currentStreak: data.get(#currentStreak, or: $value.currentStreak),
    ritualsCompleted: data.get(#ritualsCompleted, or: $value.ritualsCompleted),
    timesShown: data.get(#timesShown, or: $value.timesShown),
    timesDismissed: data.get(#timesDismissed, or: $value.timesDismissed),
    daysSinceLastShown: data.get(
      #daysSinceLastShown,
      or: $value.daysSinceLastShown,
    ),
    explicitIntent: data.get(#explicitIntent, or: $value.explicitIntent),
  );

  @override
  PaywallSignalsCopyWith<$R2, PaywallSignals, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PaywallSignalsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

