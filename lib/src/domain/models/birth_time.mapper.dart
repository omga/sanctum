// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'birth_time.dart';

class BirthTimeMapper extends ClassMapperBase<BirthTime> {
  BirthTimeMapper._();

  static BirthTimeMapper? _instance;
  static BirthTimeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BirthTimeMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'BirthTime';

  static int? _$minuteOfDay(BirthTime v) => v.minuteOfDay;
  static const Field<BirthTime, int> _f$minuteOfDay = Field(
    'minuteOfDay',
    _$minuteOfDay,
    opt: true,
  );

  @override
  final MappableFields<BirthTime> fields = const {#minuteOfDay: _f$minuteOfDay};

  static BirthTime _instantiate(DecodingData data) {
    return BirthTime(minuteOfDay: data.dec(_f$minuteOfDay));
  }

  @override
  final Function instantiate = _instantiate;

  static BirthTime fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<BirthTime>(map);
  }

  static BirthTime fromJson(String json) {
    return ensureInitialized().decodeJson<BirthTime>(json);
  }
}

mixin BirthTimeMappable {
  String toJson() {
    return BirthTimeMapper.ensureInitialized().encodeJson<BirthTime>(
      this as BirthTime,
    );
  }

  Map<String, dynamic> toMap() {
    return BirthTimeMapper.ensureInitialized().encodeMap<BirthTime>(
      this as BirthTime,
    );
  }

  BirthTimeCopyWith<BirthTime, BirthTime, BirthTime> get copyWith =>
      _BirthTimeCopyWithImpl<BirthTime, BirthTime>(
        this as BirthTime,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return BirthTimeMapper.ensureInitialized().stringifyValue(
      this as BirthTime,
    );
  }

  @override
  bool operator ==(Object other) {
    return BirthTimeMapper.ensureInitialized().equalsValue(
      this as BirthTime,
      other,
    );
  }

  @override
  int get hashCode {
    return BirthTimeMapper.ensureInitialized().hashValue(this as BirthTime);
  }
}

extension BirthTimeValueCopy<$R, $Out> on ObjectCopyWith<$R, BirthTime, $Out> {
  BirthTimeCopyWith<$R, BirthTime, $Out> get $asBirthTime =>
      $base.as((v, t, t2) => _BirthTimeCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class BirthTimeCopyWith<$R, $In extends BirthTime, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? minuteOfDay});
  BirthTimeCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _BirthTimeCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, BirthTime, $Out>
    implements BirthTimeCopyWith<$R, BirthTime, $Out> {
  _BirthTimeCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<BirthTime> $mapper =
      BirthTimeMapper.ensureInitialized();
  @override
  $R call({Object? minuteOfDay = $none}) => $apply(
    FieldCopyWithData({if (minuteOfDay != $none) #minuteOfDay: minuteOfDay}),
  );
  @override
  BirthTime $make(CopyWithData data) =>
      BirthTime(minuteOfDay: data.get(#minuteOfDay, or: $value.minuteOfDay));

  @override
  BirthTimeCopyWith<$R2, BirthTime, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _BirthTimeCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

