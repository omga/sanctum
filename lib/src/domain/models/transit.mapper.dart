// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'transit.dart';

class TransitAspectMapper extends EnumMapper<TransitAspect> {
  TransitAspectMapper._();

  static TransitAspectMapper? _instance;
  static TransitAspectMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TransitAspectMapper._());
    }
    return _instance!;
  }

  static TransitAspect fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  TransitAspect decode(dynamic value) {
    switch (value) {
      case r'conjunction':
        return TransitAspect.conjunction;
      case r'sextile':
        return TransitAspect.sextile;
      case r'square':
        return TransitAspect.square;
      case r'trine':
        return TransitAspect.trine;
      case r'opposition':
        return TransitAspect.opposition;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(TransitAspect self) {
    switch (self) {
      case TransitAspect.conjunction:
        return r'conjunction';
      case TransitAspect.sextile:
        return r'sextile';
      case TransitAspect.square:
        return r'square';
      case TransitAspect.trine:
        return r'trine';
      case TransitAspect.opposition:
        return r'opposition';
    }
  }
}

extension TransitAspectMapperExtension on TransitAspect {
  String toValue() {
    TransitAspectMapper.ensureInitialized();
    return MapperContainer.globals.toValue<TransitAspect>(this) as String;
  }
}

class TransitMapper extends ClassMapperBase<Transit> {
  TransitMapper._();

  static TransitMapper? _instance;
  static TransitMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TransitMapper._());
      PlanetMapper.ensureInitialized();
      TransitAspectMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Transit';

  static Planet _$transiting(Transit v) => v.transiting;
  static const Field<Transit, Planet> _f$transiting = Field(
    'transiting',
    _$transiting,
  );
  static Planet _$natal(Transit v) => v.natal;
  static const Field<Transit, Planet> _f$natal = Field('natal', _$natal);
  static TransitAspect _$aspect(Transit v) => v.aspect;
  static const Field<Transit, TransitAspect> _f$aspect = Field(
    'aspect',
    _$aspect,
  );
  static double _$orb(Transit v) => v.orb;
  static const Field<Transit, double> _f$orb = Field('orb', _$orb);
  static bool _$retrograde(Transit v) => v.retrograde;
  static const Field<Transit, bool> _f$retrograde = Field(
    'retrograde',
    _$retrograde,
  );

  @override
  final MappableFields<Transit> fields = const {
    #transiting: _f$transiting,
    #natal: _f$natal,
    #aspect: _f$aspect,
    #orb: _f$orb,
    #retrograde: _f$retrograde,
  };

  static Transit _instantiate(DecodingData data) {
    return Transit(
      transiting: data.dec(_f$transiting),
      natal: data.dec(_f$natal),
      aspect: data.dec(_f$aspect),
      orb: data.dec(_f$orb),
      retrograde: data.dec(_f$retrograde),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Transit fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Transit>(map);
  }

  static Transit fromJson(String json) {
    return ensureInitialized().decodeJson<Transit>(json);
  }
}

mixin TransitMappable {
  String toJson() {
    return TransitMapper.ensureInitialized().encodeJson<Transit>(
      this as Transit,
    );
  }

  Map<String, dynamic> toMap() {
    return TransitMapper.ensureInitialized().encodeMap<Transit>(
      this as Transit,
    );
  }

  TransitCopyWith<Transit, Transit, Transit> get copyWith =>
      _TransitCopyWithImpl<Transit, Transit>(
        this as Transit,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return TransitMapper.ensureInitialized().stringifyValue(this as Transit);
  }

  @override
  bool operator ==(Object other) {
    return TransitMapper.ensureInitialized().equalsValue(
      this as Transit,
      other,
    );
  }

  @override
  int get hashCode {
    return TransitMapper.ensureInitialized().hashValue(this as Transit);
  }
}

extension TransitValueCopy<$R, $Out> on ObjectCopyWith<$R, Transit, $Out> {
  TransitCopyWith<$R, Transit, $Out> get $asTransit =>
      $base.as((v, t, t2) => _TransitCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TransitCopyWith<$R, $In extends Transit, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    Planet? transiting,
    Planet? natal,
    TransitAspect? aspect,
    double? orb,
    bool? retrograde,
  });
  TransitCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _TransitCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Transit, $Out>
    implements TransitCopyWith<$R, Transit, $Out> {
  _TransitCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Transit> $mapper =
      TransitMapper.ensureInitialized();
  @override
  $R call({
    Planet? transiting,
    Planet? natal,
    TransitAspect? aspect,
    double? orb,
    bool? retrograde,
  }) => $apply(
    FieldCopyWithData({
      if (transiting != null) #transiting: transiting,
      if (natal != null) #natal: natal,
      if (aspect != null) #aspect: aspect,
      if (orb != null) #orb: orb,
      if (retrograde != null) #retrograde: retrograde,
    }),
  );
  @override
  Transit $make(CopyWithData data) => Transit(
    transiting: data.get(#transiting, or: $value.transiting),
    natal: data.get(#natal, or: $value.natal),
    aspect: data.get(#aspect, or: $value.aspect),
    orb: data.get(#orb, or: $value.orb),
    retrograde: data.get(#retrograde, or: $value.retrograde),
  );

  @override
  TransitCopyWith<$R2, Transit, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _TransitCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

