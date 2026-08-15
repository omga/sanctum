// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'ritual.dart';

class RitualMapper extends ClassMapperBase<Ritual> {
  RitualMapper._();

  static RitualMapper? _instance;
  static RitualMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RitualMapper._());
      MoonPhaseMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Ritual';

  static String _$id(Ritual v) => v.id;
  static const Field<Ritual, String> _f$id = Field('id', _$id);
  static String _$moon(Ritual v) => v.moon;
  static const Field<Ritual, String> _f$moon = Field('moon', _$moon);
  static String _$title(Ritual v) => v.title;
  static const Field<Ritual, String> _f$title = Field('title', _$title);
  static MoonPhase _$phase(Ritual v) => v.phase;
  static const Field<Ritual, MoonPhase> _f$phase = Field('phase', _$phase);
  static String _$opening(Ritual v) => v.opening;
  static const Field<Ritual, String> _f$opening = Field('opening', _$opening);
  static List<String> _$steps(Ritual v) => v.steps;
  static const Field<Ritual, List<String>> _f$steps = Field('steps', _$steps);

  @override
  final MappableFields<Ritual> fields = const {
    #id: _f$id,
    #moon: _f$moon,
    #title: _f$title,
    #phase: _f$phase,
    #opening: _f$opening,
    #steps: _f$steps,
  };

  static Ritual _instantiate(DecodingData data) {
    return Ritual(
      id: data.dec(_f$id),
      moon: data.dec(_f$moon),
      title: data.dec(_f$title),
      phase: data.dec(_f$phase),
      opening: data.dec(_f$opening),
      steps: data.dec(_f$steps),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static Ritual fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Ritual>(map);
  }

  static Ritual fromJson(String json) {
    return ensureInitialized().decodeJson<Ritual>(json);
  }
}

mixin RitualMappable {
  String toJson() {
    return RitualMapper.ensureInitialized().encodeJson<Ritual>(this as Ritual);
  }

  Map<String, dynamic> toMap() {
    return RitualMapper.ensureInitialized().encodeMap<Ritual>(this as Ritual);
  }

  RitualCopyWith<Ritual, Ritual, Ritual> get copyWith =>
      _RitualCopyWithImpl<Ritual, Ritual>(this as Ritual, $identity, $identity);
  @override
  String toString() {
    return RitualMapper.ensureInitialized().stringifyValue(this as Ritual);
  }

  @override
  bool operator ==(Object other) {
    return RitualMapper.ensureInitialized().equalsValue(this as Ritual, other);
  }

  @override
  int get hashCode {
    return RitualMapper.ensureInitialized().hashValue(this as Ritual);
  }
}

extension RitualValueCopy<$R, $Out> on ObjectCopyWith<$R, Ritual, $Out> {
  RitualCopyWith<$R, Ritual, $Out> get $asRitual =>
      $base.as((v, t, t2) => _RitualCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class RitualCopyWith<$R, $In extends Ritual, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get steps;
  $R call({
    String? id,
    String? moon,
    String? title,
    MoonPhase? phase,
    String? opening,
    List<String>? steps,
  });
  RitualCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _RitualCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Ritual, $Out>
    implements RitualCopyWith<$R, Ritual, $Out> {
  _RitualCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Ritual> $mapper = RitualMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get steps =>
      ListCopyWith(
        $value.steps,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(steps: v),
      );
  @override
  $R call({
    String? id,
    String? moon,
    String? title,
    MoonPhase? phase,
    String? opening,
    List<String>? steps,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (moon != null) #moon: moon,
      if (title != null) #title: title,
      if (phase != null) #phase: phase,
      if (opening != null) #opening: opening,
      if (steps != null) #steps: steps,
    }),
  );
  @override
  Ritual $make(CopyWithData data) => Ritual(
    id: data.get(#id, or: $value.id),
    moon: data.get(#moon, or: $value.moon),
    title: data.get(#title, or: $value.title),
    phase: data.get(#phase, or: $value.phase),
    opening: data.get(#opening, or: $value.opening),
    steps: data.get(#steps, or: $value.steps),
  );

  @override
  RitualCopyWith<$R2, Ritual, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _RitualCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

