// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'subscription_plan.dart';

class BillingPeriodMapper extends EnumMapper<BillingPeriod> {
  BillingPeriodMapper._();

  static BillingPeriodMapper? _instance;
  static BillingPeriodMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BillingPeriodMapper._());
    }
    return _instance!;
  }

  static BillingPeriod fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  BillingPeriod decode(dynamic value) {
    switch (value) {
      case r'monthly':
        return BillingPeriod.monthly;
      case r'yearly':
        return BillingPeriod.yearly;
      case r'lifetime':
        return BillingPeriod.lifetime;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(BillingPeriod self) {
    switch (self) {
      case BillingPeriod.monthly:
        return r'monthly';
      case BillingPeriod.yearly:
        return r'yearly';
      case BillingPeriod.lifetime:
        return r'lifetime';
    }
  }
}

extension BillingPeriodMapperExtension on BillingPeriod {
  String toValue() {
    BillingPeriodMapper.ensureInitialized();
    return MapperContainer.globals.toValue<BillingPeriod>(this) as String;
  }
}

class SubscriptionPlanMapper extends ClassMapperBase<SubscriptionPlan> {
  SubscriptionPlanMapper._();

  static SubscriptionPlanMapper? _instance;
  static SubscriptionPlanMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SubscriptionPlanMapper._());
      BillingPeriodMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SubscriptionPlan';

  static String _$id(SubscriptionPlan v) => v.id;
  static const Field<SubscriptionPlan, String> _f$id = Field('id', _$id);
  static BillingPeriod _$period(SubscriptionPlan v) => v.period;
  static const Field<SubscriptionPlan, BillingPeriod> _f$period = Field(
    'period',
    _$period,
  );
  static String _$displayPrice(SubscriptionPlan v) => v.displayPrice;
  static const Field<SubscriptionPlan, String> _f$displayPrice = Field(
    'displayPrice',
    _$displayPrice,
  );
  static String? _$displayPricePerMonth(SubscriptionPlan v) =>
      v.displayPricePerMonth;
  static const Field<SubscriptionPlan, String> _f$displayPricePerMonth = Field(
    'displayPricePerMonth',
    _$displayPricePerMonth,
  );
  static int _$trialDays(SubscriptionPlan v) => v.trialDays;
  static const Field<SubscriptionPlan, int> _f$trialDays = Field(
    'trialDays',
    _$trialDays,
    opt: true,
    def: 0,
  );
  static int? _$savingsPercent(SubscriptionPlan v) => v.savingsPercent;
  static const Field<SubscriptionPlan, int> _f$savingsPercent = Field(
    'savingsPercent',
    _$savingsPercent,
    opt: true,
  );

  @override
  final MappableFields<SubscriptionPlan> fields = const {
    #id: _f$id,
    #period: _f$period,
    #displayPrice: _f$displayPrice,
    #displayPricePerMonth: _f$displayPricePerMonth,
    #trialDays: _f$trialDays,
    #savingsPercent: _f$savingsPercent,
  };

  static SubscriptionPlan _instantiate(DecodingData data) {
    return SubscriptionPlan(
      id: data.dec(_f$id),
      period: data.dec(_f$period),
      displayPrice: data.dec(_f$displayPrice),
      displayPricePerMonth: data.dec(_f$displayPricePerMonth),
      trialDays: data.dec(_f$trialDays),
      savingsPercent: data.dec(_f$savingsPercent),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SubscriptionPlan fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SubscriptionPlan>(map);
  }

  static SubscriptionPlan fromJson(String json) {
    return ensureInitialized().decodeJson<SubscriptionPlan>(json);
  }
}

mixin SubscriptionPlanMappable {
  String toJson() {
    return SubscriptionPlanMapper.ensureInitialized()
        .encodeJson<SubscriptionPlan>(this as SubscriptionPlan);
  }

  Map<String, dynamic> toMap() {
    return SubscriptionPlanMapper.ensureInitialized()
        .encodeMap<SubscriptionPlan>(this as SubscriptionPlan);
  }

  SubscriptionPlanCopyWith<SubscriptionPlan, SubscriptionPlan, SubscriptionPlan>
  get copyWith =>
      _SubscriptionPlanCopyWithImpl<SubscriptionPlan, SubscriptionPlan>(
        this as SubscriptionPlan,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SubscriptionPlanMapper.ensureInitialized().stringifyValue(
      this as SubscriptionPlan,
    );
  }

  @override
  bool operator ==(Object other) {
    return SubscriptionPlanMapper.ensureInitialized().equalsValue(
      this as SubscriptionPlan,
      other,
    );
  }

  @override
  int get hashCode {
    return SubscriptionPlanMapper.ensureInitialized().hashValue(
      this as SubscriptionPlan,
    );
  }
}

extension SubscriptionPlanValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SubscriptionPlan, $Out> {
  SubscriptionPlanCopyWith<$R, SubscriptionPlan, $Out>
  get $asSubscriptionPlan =>
      $base.as((v, t, t2) => _SubscriptionPlanCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SubscriptionPlanCopyWith<$R, $In extends SubscriptionPlan, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    BillingPeriod? period,
    String? displayPrice,
    String? displayPricePerMonth,
    int? trialDays,
    int? savingsPercent,
  });
  SubscriptionPlanCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SubscriptionPlanCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SubscriptionPlan, $Out>
    implements SubscriptionPlanCopyWith<$R, SubscriptionPlan, $Out> {
  _SubscriptionPlanCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SubscriptionPlan> $mapper =
      SubscriptionPlanMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    BillingPeriod? period,
    String? displayPrice,
    Object? displayPricePerMonth = $none,
    int? trialDays,
    Object? savingsPercent = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (period != null) #period: period,
      if (displayPrice != null) #displayPrice: displayPrice,
      if (displayPricePerMonth != $none)
        #displayPricePerMonth: displayPricePerMonth,
      if (trialDays != null) #trialDays: trialDays,
      if (savingsPercent != $none) #savingsPercent: savingsPercent,
    }),
  );
  @override
  SubscriptionPlan $make(CopyWithData data) => SubscriptionPlan(
    id: data.get(#id, or: $value.id),
    period: data.get(#period, or: $value.period),
    displayPrice: data.get(#displayPrice, or: $value.displayPrice),
    displayPricePerMonth: data.get(
      #displayPricePerMonth,
      or: $value.displayPricePerMonth,
    ),
    trialDays: data.get(#trialDays, or: $value.trialDays),
    savingsPercent: data.get(#savingsPercent, or: $value.savingsPercent),
  );

  @override
  SubscriptionPlanCopyWith<$R2, SubscriptionPlan, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SubscriptionPlanCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

