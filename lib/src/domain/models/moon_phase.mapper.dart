// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'moon_phase.dart';

class MoonPhaseMapper extends EnumMapper<MoonPhase> {
  MoonPhaseMapper._();

  static MoonPhaseMapper? _instance;
  static MoonPhaseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MoonPhaseMapper._());
    }
    return _instance!;
  }

  static MoonPhase fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  MoonPhase decode(dynamic value) {
    switch (value) {
      case r'newMoon':
        return MoonPhase.newMoon;
      case r'waxingCrescent':
        return MoonPhase.waxingCrescent;
      case r'firstQuarter':
        return MoonPhase.firstQuarter;
      case r'waxingGibbous':
        return MoonPhase.waxingGibbous;
      case r'fullMoon':
        return MoonPhase.fullMoon;
      case r'waningGibbous':
        return MoonPhase.waningGibbous;
      case r'lastQuarter':
        return MoonPhase.lastQuarter;
      case r'waningCrescent':
        return MoonPhase.waningCrescent;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(MoonPhase self) {
    switch (self) {
      case MoonPhase.newMoon:
        return r'newMoon';
      case MoonPhase.waxingCrescent:
        return r'waxingCrescent';
      case MoonPhase.firstQuarter:
        return r'firstQuarter';
      case MoonPhase.waxingGibbous:
        return r'waxingGibbous';
      case MoonPhase.fullMoon:
        return r'fullMoon';
      case MoonPhase.waningGibbous:
        return r'waningGibbous';
      case MoonPhase.lastQuarter:
        return r'lastQuarter';
      case MoonPhase.waningCrescent:
        return r'waningCrescent';
    }
  }
}

extension MoonPhaseMapperExtension on MoonPhase {
  String toValue() {
    MoonPhaseMapper.ensureInitialized();
    return MapperContainer.globals.toValue<MoonPhase>(this) as String;
  }
}

class MoonReadingMapper extends ClassMapperBase<MoonReading> {
  MoonReadingMapper._();

  static MoonReadingMapper? _instance;
  static MoonReadingMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MoonReadingMapper._());
      MoonPhaseMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'MoonReading';

  static MoonPhase _$phase(MoonReading v) => v.phase;
  static const Field<MoonReading, MoonPhase> _f$phase = Field('phase', _$phase);
  static double _$cyclePosition(MoonReading v) => v.cyclePosition;
  static const Field<MoonReading, double> _f$cyclePosition = Field(
    'cyclePosition',
    _$cyclePosition,
  );
  static double _$illumination(MoonReading v) => v.illumination;
  static const Field<MoonReading, double> _f$illumination = Field(
    'illumination',
    _$illumination,
  );
  static double _$ageInDays(MoonReading v) => v.ageInDays;
  static const Field<MoonReading, double> _f$ageInDays = Field(
    'ageInDays',
    _$ageInDays,
  );

  @override
  final MappableFields<MoonReading> fields = const {
    #phase: _f$phase,
    #cyclePosition: _f$cyclePosition,
    #illumination: _f$illumination,
    #ageInDays: _f$ageInDays,
  };

  static MoonReading _instantiate(DecodingData data) {
    return MoonReading(
      phase: data.dec(_f$phase),
      cyclePosition: data.dec(_f$cyclePosition),
      illumination: data.dec(_f$illumination),
      ageInDays: data.dec(_f$ageInDays),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static MoonReading fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<MoonReading>(map);
  }

  static MoonReading fromJson(String json) {
    return ensureInitialized().decodeJson<MoonReading>(json);
  }
}

mixin MoonReadingMappable {
  String toJson() {
    return MoonReadingMapper.ensureInitialized().encodeJson<MoonReading>(
      this as MoonReading,
    );
  }

  Map<String, dynamic> toMap() {
    return MoonReadingMapper.ensureInitialized().encodeMap<MoonReading>(
      this as MoonReading,
    );
  }

  MoonReadingCopyWith<MoonReading, MoonReading, MoonReading> get copyWith =>
      _MoonReadingCopyWithImpl<MoonReading, MoonReading>(
        this as MoonReading,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return MoonReadingMapper.ensureInitialized().stringifyValue(
      this as MoonReading,
    );
  }

  @override
  bool operator ==(Object other) {
    return MoonReadingMapper.ensureInitialized().equalsValue(
      this as MoonReading,
      other,
    );
  }

  @override
  int get hashCode {
    return MoonReadingMapper.ensureInitialized().hashValue(this as MoonReading);
  }
}

extension MoonReadingValueCopy<$R, $Out>
    on ObjectCopyWith<$R, MoonReading, $Out> {
  MoonReadingCopyWith<$R, MoonReading, $Out> get $asMoonReading =>
      $base.as((v, t, t2) => _MoonReadingCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class MoonReadingCopyWith<$R, $In extends MoonReading, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    MoonPhase? phase,
    double? cyclePosition,
    double? illumination,
    double? ageInDays,
  });
  MoonReadingCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _MoonReadingCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, MoonReading, $Out>
    implements MoonReadingCopyWith<$R, MoonReading, $Out> {
  _MoonReadingCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<MoonReading> $mapper =
      MoonReadingMapper.ensureInitialized();
  @override
  $R call({
    MoonPhase? phase,
    double? cyclePosition,
    double? illumination,
    double? ageInDays,
  }) => $apply(
    FieldCopyWithData({
      if (phase != null) #phase: phase,
      if (cyclePosition != null) #cyclePosition: cyclePosition,
      if (illumination != null) #illumination: illumination,
      if (ageInDays != null) #ageInDays: ageInDays,
    }),
  );
  @override
  MoonReading $make(CopyWithData data) => MoonReading(
    phase: data.get(#phase, or: $value.phase),
    cyclePosition: data.get(#cyclePosition, or: $value.cyclePosition),
    illumination: data.get(#illumination, or: $value.illumination),
    ageInDays: data.get(#ageInDays, or: $value.ageInDays),
  );

  @override
  MoonReadingCopyWith<$R2, MoonReading, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _MoonReadingCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

