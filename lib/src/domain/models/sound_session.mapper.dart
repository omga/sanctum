// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'sound_session.dart';

class ChakraMapper extends EnumMapper<Chakra> {
  ChakraMapper._();

  static ChakraMapper? _instance;
  static ChakraMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChakraMapper._());
    }
    return _instance!;
  }

  static Chakra fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  Chakra decode(dynamic value) {
    switch (value) {
      case r'root':
        return Chakra.root;
      case r'sacral':
        return Chakra.sacral;
      case r'solarPlexus':
        return Chakra.solarPlexus;
      case r'heart':
        return Chakra.heart;
      case r'throat':
        return Chakra.throat;
      case r'thirdEye':
        return Chakra.thirdEye;
      case r'crown':
        return Chakra.crown;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(Chakra self) {
    switch (self) {
      case Chakra.root:
        return r'root';
      case Chakra.sacral:
        return r'sacral';
      case Chakra.solarPlexus:
        return r'solarPlexus';
      case Chakra.heart:
        return r'heart';
      case Chakra.throat:
        return r'throat';
      case Chakra.thirdEye:
        return r'thirdEye';
      case Chakra.crown:
        return r'crown';
    }
  }
}

extension ChakraMapperExtension on Chakra {
  String toValue() {
    ChakraMapper.ensureInitialized();
    return MapperContainer.globals.toValue<Chakra>(this) as String;
  }
}

class SoundSessionMapper extends ClassMapperBase<SoundSession> {
  SoundSessionMapper._();

  static SoundSessionMapper? _instance;
  static SoundSessionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SoundSessionMapper._());
      ChakraMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SoundSession';

  static String _$id(SoundSession v) => v.id;
  static const Field<SoundSession, String> _f$id = Field('id', _$id);
  static String _$title(SoundSession v) => v.title;
  static const Field<SoundSession, String> _f$title = Field('title', _$title);
  static double _$frequencyHz(SoundSession v) => v.frequencyHz;
  static const Field<SoundSession, double> _f$frequencyHz = Field(
    'frequencyHz',
    _$frequencyHz,
  );
  static String _$frequencyLabel(SoundSession v) => v.frequencyLabel;
  static const Field<SoundSession, String> _f$frequencyLabel = Field(
    'frequencyLabel',
    _$frequencyLabel,
  );
  static String _$intention(SoundSession v) => v.intention;
  static const Field<SoundSession, String> _f$intention = Field(
    'intention',
    _$intention,
  );
  static int _$durationSeconds(SoundSession v) => v.durationSeconds;
  static const Field<SoundSession, int> _f$durationSeconds = Field(
    'durationSeconds',
    _$durationSeconds,
  );
  static Chakra _$chakra(SoundSession v) => v.chakra;
  static const Field<SoundSession, Chakra> _f$chakra = Field(
    'chakra',
    _$chakra,
  );

  @override
  final MappableFields<SoundSession> fields = const {
    #id: _f$id,
    #title: _f$title,
    #frequencyHz: _f$frequencyHz,
    #frequencyLabel: _f$frequencyLabel,
    #intention: _f$intention,
    #durationSeconds: _f$durationSeconds,
    #chakra: _f$chakra,
  };

  static SoundSession _instantiate(DecodingData data) {
    return SoundSession(
      id: data.dec(_f$id),
      title: data.dec(_f$title),
      frequencyHz: data.dec(_f$frequencyHz),
      frequencyLabel: data.dec(_f$frequencyLabel),
      intention: data.dec(_f$intention),
      durationSeconds: data.dec(_f$durationSeconds),
      chakra: data.dec(_f$chakra),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SoundSession fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SoundSession>(map);
  }

  static SoundSession fromJson(String json) {
    return ensureInitialized().decodeJson<SoundSession>(json);
  }
}

mixin SoundSessionMappable {
  String toJson() {
    return SoundSessionMapper.ensureInitialized().encodeJson<SoundSession>(
      this as SoundSession,
    );
  }

  Map<String, dynamic> toMap() {
    return SoundSessionMapper.ensureInitialized().encodeMap<SoundSession>(
      this as SoundSession,
    );
  }

  SoundSessionCopyWith<SoundSession, SoundSession, SoundSession> get copyWith =>
      _SoundSessionCopyWithImpl<SoundSession, SoundSession>(
        this as SoundSession,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SoundSessionMapper.ensureInitialized().stringifyValue(
      this as SoundSession,
    );
  }

  @override
  bool operator ==(Object other) {
    return SoundSessionMapper.ensureInitialized().equalsValue(
      this as SoundSession,
      other,
    );
  }

  @override
  int get hashCode {
    return SoundSessionMapper.ensureInitialized().hashValue(
      this as SoundSession,
    );
  }
}

extension SoundSessionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SoundSession, $Out> {
  SoundSessionCopyWith<$R, SoundSession, $Out> get $asSoundSession =>
      $base.as((v, t, t2) => _SoundSessionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SoundSessionCopyWith<$R, $In extends SoundSession, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    String? title,
    double? frequencyHz,
    String? frequencyLabel,
    String? intention,
    int? durationSeconds,
    Chakra? chakra,
  });
  SoundSessionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SoundSessionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SoundSession, $Out>
    implements SoundSessionCopyWith<$R, SoundSession, $Out> {
  _SoundSessionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SoundSession> $mapper =
      SoundSessionMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    String? title,
    double? frequencyHz,
    String? frequencyLabel,
    String? intention,
    int? durationSeconds,
    Chakra? chakra,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (title != null) #title: title,
      if (frequencyHz != null) #frequencyHz: frequencyHz,
      if (frequencyLabel != null) #frequencyLabel: frequencyLabel,
      if (intention != null) #intention: intention,
      if (durationSeconds != null) #durationSeconds: durationSeconds,
      if (chakra != null) #chakra: chakra,
    }),
  );
  @override
  SoundSession $make(CopyWithData data) => SoundSession(
    id: data.get(#id, or: $value.id),
    title: data.get(#title, or: $value.title),
    frequencyHz: data.get(#frequencyHz, or: $value.frequencyHz),
    frequencyLabel: data.get(#frequencyLabel, or: $value.frequencyLabel),
    intention: data.get(#intention, or: $value.intention),
    durationSeconds: data.get(#durationSeconds, or: $value.durationSeconds),
    chakra: data.get(#chakra, or: $value.chakra),
  );

  @override
  SoundSessionCopyWith<$R2, SoundSession, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SoundSessionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

