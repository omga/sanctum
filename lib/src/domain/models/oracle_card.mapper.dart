// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'oracle_card.dart';

class OracleCardMapper extends ClassMapperBase<OracleCard> {
  OracleCardMapper._();

  static OracleCardMapper? _instance;
  static OracleCardMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = OracleCardMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'OracleCard';

  static String _$id(OracleCard v) => v.id;
  static const Field<OracleCard, String> _f$id = Field('id', _$id);
  static String _$name(OracleCard v) => v.name;
  static const Field<OracleCard, String> _f$name = Field('name', _$name);
  static String _$message(OracleCard v) => v.message;
  static const Field<OracleCard, String> _f$message = Field(
    'message',
    _$message,
  );
  static String _$guidance(OracleCard v) => v.guidance;
  static const Field<OracleCard, String> _f$guidance = Field(
    'guidance',
    _$guidance,
  );

  @override
  final MappableFields<OracleCard> fields = const {
    #id: _f$id,
    #name: _f$name,
    #message: _f$message,
    #guidance: _f$guidance,
  };

  static OracleCard _instantiate(DecodingData data) {
    return OracleCard(
      id: data.dec(_f$id),
      name: data.dec(_f$name),
      message: data.dec(_f$message),
      guidance: data.dec(_f$guidance),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static OracleCard fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<OracleCard>(map);
  }

  static OracleCard fromJson(String json) {
    return ensureInitialized().decodeJson<OracleCard>(json);
  }
}

mixin OracleCardMappable {
  String toJson() {
    return OracleCardMapper.ensureInitialized().encodeJson<OracleCard>(
      this as OracleCard,
    );
  }

  Map<String, dynamic> toMap() {
    return OracleCardMapper.ensureInitialized().encodeMap<OracleCard>(
      this as OracleCard,
    );
  }

  OracleCardCopyWith<OracleCard, OracleCard, OracleCard> get copyWith =>
      _OracleCardCopyWithImpl<OracleCard, OracleCard>(
        this as OracleCard,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return OracleCardMapper.ensureInitialized().stringifyValue(
      this as OracleCard,
    );
  }

  @override
  bool operator ==(Object other) {
    return OracleCardMapper.ensureInitialized().equalsValue(
      this as OracleCard,
      other,
    );
  }

  @override
  int get hashCode {
    return OracleCardMapper.ensureInitialized().hashValue(this as OracleCard);
  }
}

extension OracleCardValueCopy<$R, $Out>
    on ObjectCopyWith<$R, OracleCard, $Out> {
  OracleCardCopyWith<$R, OracleCard, $Out> get $asOracleCard =>
      $base.as((v, t, t2) => _OracleCardCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class OracleCardCopyWith<$R, $In extends OracleCard, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? id, String? name, String? message, String? guidance});
  OracleCardCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _OracleCardCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, OracleCard, $Out>
    implements OracleCardCopyWith<$R, OracleCard, $Out> {
  _OracleCardCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<OracleCard> $mapper =
      OracleCardMapper.ensureInitialized();
  @override
  $R call({String? id, String? name, String? message, String? guidance}) =>
      $apply(
        FieldCopyWithData({
          if (id != null) #id: id,
          if (name != null) #name: name,
          if (message != null) #message: message,
          if (guidance != null) #guidance: guidance,
        }),
      );
  @override
  OracleCard $make(CopyWithData data) => OracleCard(
    id: data.get(#id, or: $value.id),
    name: data.get(#name, or: $value.name),
    message: data.get(#message, or: $value.message),
    guidance: data.get(#guidance, or: $value.guidance),
  );

  @override
  OracleCardCopyWith<$R2, OracleCard, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _OracleCardCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

