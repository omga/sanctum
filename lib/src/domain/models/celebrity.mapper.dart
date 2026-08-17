// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'celebrity.dart';

class CelebrityGroupMapper extends EnumMapper<CelebrityGroup> {
  CelebrityGroupMapper._();

  static CelebrityGroupMapper? _instance;
  static CelebrityGroupMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CelebrityGroupMapper._());
    }
    return _instance!;
  }

  static CelebrityGroup fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  CelebrityGroup decode(dynamic value) {
    switch (value) {
      case r'music':
        return CelebrityGroup.music;
      case r'screen':
        return CelebrityGroup.screen;
      case r'influencer':
        return CelebrityGroup.influencer;
      case r'sport':
        return CelebrityGroup.sport;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(CelebrityGroup self) {
    switch (self) {
      case CelebrityGroup.music:
        return r'music';
      case CelebrityGroup.screen:
        return r'screen';
      case CelebrityGroup.influencer:
        return r'influencer';
      case CelebrityGroup.sport:
        return r'sport';
    }
  }
}

extension CelebrityGroupMapperExtension on CelebrityGroup {
  String toValue() {
    CelebrityGroupMapper.ensureInitialized();
    return MapperContainer.globals.toValue<CelebrityGroup>(this) as String;
  }
}

class CelebrityMapper extends ClassMapperBase<Celebrity> {
  CelebrityMapper._();

  static CelebrityMapper? _instance;
  static CelebrityMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CelebrityMapper._());
      CelebrityGroupMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Celebrity';

  static String _$id(Celebrity v) => v.id;
  static const Field<Celebrity, String> _f$id = Field('id', _$id);
  static String _$name(Celebrity v) => v.name;
  static const Field<Celebrity, String> _f$name = Field('name', _$name);
  static String _$knownFor(Celebrity v) => v.knownFor;
  static const Field<Celebrity, String> _f$knownFor = Field(
    'knownFor',
    _$knownFor,
  );
  static DateTime _$birthDate(Celebrity v) => v.birthDate;
  static const Field<Celebrity, DateTime> _f$birthDate = Field(
    'birthDate',
    _$birthDate,
  );
  static CelebrityGroup _$group(Celebrity v) => v.group;
  static const Field<Celebrity, CelebrityGroup> _f$group = Field(
    'group',
    _$group,
  );

  @override
  final MappableFields<Celebrity> fields = const {
    #id: _f$id,
    #name: _f$name,
    #knownFor: _f$knownFor,
    #birthDate: _f$birthDate,
    #group: _f$group,
  };

  static Celebrity _instantiate(DecodingData data) {
    return Celebrity(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      knownFor: data.dec(_f$knownFor),
      birthDate: data.dec(_f$birthDate),
      group: data.dec(_f$group),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Celebrity fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Celebrity>(map);
  }

  static Celebrity fromJson(String json) {
    return ensureInitialized().decodeJson<Celebrity>(json);
  }
}

mixin CelebrityMappable {
  String toJson() {
    return CelebrityMapper.ensureInitialized().encodeJson<Celebrity>(
      this as Celebrity,
    );
  }

  Map<String, dynamic> toMap() {
    return CelebrityMapper.ensureInitialized().encodeMap<Celebrity>(
      this as Celebrity,
    );
  }

  CelebrityCopyWith<Celebrity, Celebrity, Celebrity> get copyWith =>
      _CelebrityCopyWithImpl<Celebrity, Celebrity>(
        this as Celebrity,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CelebrityMapper.ensureInitialized().stringifyValue(
      this as Celebrity,
    );
  }

  @override
  bool operator ==(Object other) {
    return CelebrityMapper.ensureInitialized().equalsValue(
      this as Celebrity,
      other,
    );
  }

  @override
  int get hashCode {
    return CelebrityMapper.ensureInitialized().hashValue(this as Celebrity);
  }
}

extension CelebrityValueCopy<$R, $Out> on ObjectCopyWith<$R, Celebrity, $Out> {
  CelebrityCopyWith<$R, Celebrity, $Out> get $asCelebrity =>
      $base.as((v, t, t2) => _CelebrityCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CelebrityCopyWith<$R, $In extends Celebrity, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? name,
    String? knownFor,
    DateTime? birthDate,
    CelebrityGroup? group,
  });
  CelebrityCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _CelebrityCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, Celebrity, $Out>
    implements CelebrityCopyWith<$R, Celebrity, $Out> {
  _CelebrityCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Celebrity> $mapper =
      CelebrityMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? name,
    String? knownFor,
    DateTime? birthDate,
    CelebrityGroup? group,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (name != null) #name: name,
      if (knownFor != null) #knownFor: knownFor,
      if (birthDate != null) #birthDate: birthDate,
      if (group != null) #group: group,
    }),
  );
  @override
  Celebrity $make(CopyWithData data) => Celebrity(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    knownFor: data.get(#knownFor, or: $value.knownFor),
    birthDate: data.get(#birthDate, or: $value.birthDate),
    group: data.get(#group, or: $value.group),
  );

  @override
  CelebrityCopyWith<$R2, Celebrity, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CelebrityCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

