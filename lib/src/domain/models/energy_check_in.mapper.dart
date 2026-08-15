// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'energy_check_in.dart';

class EnergyLevelMapper extends EnumMapper<EnergyLevel> {
  EnergyLevelMapper._();

  static EnergyLevelMapper? _instance;
  static EnergyLevelMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EnergyLevelMapper._());
    }
    return _instance!;
  }

  static EnergyLevel fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  EnergyLevel decode(dynamic value) {
    switch (value) {
      case r'depleted':
        return EnergyLevel.depleted;
      case r'low':
        return EnergyLevel.low;
      case r'steady':
        return EnergyLevel.steady;
      case r'open':
        return EnergyLevel.open;
      case r'radiant':
        return EnergyLevel.radiant;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(EnergyLevel self) {
    switch (self) {
      case EnergyLevel.depleted:
        return r'depleted';
      case EnergyLevel.low:
        return r'low';
      case EnergyLevel.steady:
        return r'steady';
      case EnergyLevel.open:
        return r'open';
      case EnergyLevel.radiant:
        return r'radiant';
    }
  }
}

extension EnergyLevelMapperExtension on EnergyLevel {
  String toValue() {
    EnergyLevelMapper.ensureInitialized();
    return MapperContainer.globals.toValue<EnergyLevel>(this) as String;
  }
}

class EnergyCheckInMapper extends ClassMapperBase<EnergyCheckIn> {
  EnergyCheckInMapper._();

  static EnergyCheckInMapper? _instance;
  static EnergyCheckInMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EnergyCheckInMapper._());
      EnergyLevelMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'EnergyCheckIn';

  static int _$id(EnergyCheckIn v) => v.id;
  static const Field<EnergyCheckIn, int> _f$id = Field('id', _$id);
  static DateTime _$recordedAt(EnergyCheckIn v) => v.recordedAt;
  static const Field<EnergyCheckIn, DateTime> _f$recordedAt = Field(
    'recordedAt',
    _$recordedAt,
  );
  static EnergyLevel _$level(EnergyCheckIn v) => v.level;
  static const Field<EnergyCheckIn, EnergyLevel> _f$level = Field(
    'level',
    _$level,
  );
  static String? _$note(EnergyCheckIn v) => v.note;
  static const Field<EnergyCheckIn, String> _f$note = Field(
    'note',
    _$note,
    opt: true,
  );

  @override
  final MappableFields<EnergyCheckIn> fields = const {
    #id: _f$id,
    #recordedAt: _f$recordedAt,
    #level: _f$level,
    #note: _f$note,
  };

  static EnergyCheckIn _instantiate(DecodingData data) {
    return EnergyCheckIn(
      id: data.dec(_f$id),
      recordedAt: data.dec(_f$recordedAt),
      level: data.dec(_f$level),
      note: data.dec(_f$note),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static EnergyCheckIn fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<EnergyCheckIn>(map);
  }

  static EnergyCheckIn fromJson(String json) {
    return ensureInitialized().decodeJson<EnergyCheckIn>(json);
  }
}

mixin EnergyCheckInMappable {
  String toJson() {
    return EnergyCheckInMapper.ensureInitialized().encodeJson<EnergyCheckIn>(
      this as EnergyCheckIn,
    );
  }

  Map<String, dynamic> toMap() {
    return EnergyCheckInMapper.ensureInitialized().encodeMap<EnergyCheckIn>(
      this as EnergyCheckIn,
    );
  }

  EnergyCheckInCopyWith<EnergyCheckIn, EnergyCheckIn, EnergyCheckIn>
  get copyWith => _EnergyCheckInCopyWithImpl<EnergyCheckIn, EnergyCheckIn>(
    this as EnergyCheckIn,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return EnergyCheckInMapper.ensureInitialized().stringifyValue(
      this as EnergyCheckIn,
    );
  }

  @override
  bool operator ==(Object other) {
    return EnergyCheckInMapper.ensureInitialized().equalsValue(
      this as EnergyCheckIn,
      other,
    );
  }

  @override
  int get hashCode {
    return EnergyCheckInMapper.ensureInitialized().hashValue(
      this as EnergyCheckIn,
    );
  }
}

extension EnergyCheckInValueCopy<$R, $Out>
    on ObjectCopyWith<$R, EnergyCheckIn, $Out> {
  EnergyCheckInCopyWith<$R, EnergyCheckIn, $Out> get $asEnergyCheckIn =>
      $base.as((v, t, t2) => _EnergyCheckInCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class EnergyCheckInCopyWith<$R, $In extends EnergyCheckIn, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? id, DateTime? recordedAt, EnergyLevel? level, String? note});
  EnergyCheckInCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _EnergyCheckInCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, EnergyCheckIn, $Out>
    implements EnergyCheckInCopyWith<$R, EnergyCheckIn, $Out> {
  _EnergyCheckInCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<EnergyCheckIn> $mapper =
      EnergyCheckInMapper.ensureInitialized();
  @override
  $R call({
    int? id,
    DateTime? recordedAt,
    EnergyLevel? level,
    Object? note = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (recordedAt != null) #recordedAt: recordedAt,
      if (level != null) #level: level,
      if (note != $none) #note: note,
    }),
  );
  @override
  EnergyCheckIn $make(CopyWithData data) => EnergyCheckIn(
    id: data.get(#id, or: $value.id),
    recordedAt: data.get(#recordedAt, or: $value.recordedAt),
    level: data.get(#level, or: $value.level),
    note: data.get(#note, or: $value.note),
  );

  @override
  EnergyCheckInCopyWith<$R2, EnergyCheckIn, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _EnergyCheckInCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

