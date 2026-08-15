// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'journal_entry.dart';

class JournalKindMapper extends EnumMapper<JournalKind> {
  JournalKindMapper._();

  static JournalKindMapper? _instance;
  static JournalKindMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = JournalKindMapper._());
    }
    return _instance!;
  }

  static JournalKind fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  JournalKind decode(dynamic value) {
    switch (value) {
      case r'gratitude':
        return JournalKind.gratitude;
      case r'manifestation':
        return JournalKind.manifestation;
      case r'reflection':
        return JournalKind.reflection;
      case r'ritual':
        return JournalKind.ritual;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(JournalKind self) {
    switch (self) {
      case JournalKind.gratitude:
        return r'gratitude';
      case JournalKind.manifestation:
        return r'manifestation';
      case JournalKind.reflection:
        return r'reflection';
      case JournalKind.ritual:
        return r'ritual';
    }
  }
}

extension JournalKindMapperExtension on JournalKind {
  String toValue() {
    JournalKindMapper.ensureInitialized();
    return MapperContainer.globals.toValue<JournalKind>(this) as String;
  }
}

class JournalEntryMapper extends ClassMapperBase<JournalEntry> {
  JournalEntryMapper._();

  static JournalEntryMapper? _instance;
  static JournalEntryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = JournalEntryMapper._());
      JournalKindMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'JournalEntry';

  static int _$id(JournalEntry v) => v.id;
  static const Field<JournalEntry, int> _f$id = Field('id', _$id);
  static DateTime _$createdAt(JournalEntry v) => v.createdAt;
  static const Field<JournalEntry, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
  );
  static JournalKind _$kind(JournalEntry v) => v.kind;
  static const Field<JournalEntry, JournalKind> _f$kind = Field('kind', _$kind);
  static String _$body(JournalEntry v) => v.body;
  static const Field<JournalEntry, String> _f$body = Field('body', _$body);
  static String? _$prompt(JournalEntry v) => v.prompt;
  static const Field<JournalEntry, String> _f$prompt = Field(
    'prompt',
    _$prompt,
    opt: true,
  );

  @override
  final MappableFields<JournalEntry> fields = const {
    #id: _f$id,
    #createdAt: _f$createdAt,
    #kind: _f$kind,
    #body: _f$body,
    #prompt: _f$prompt,
  };

  static JournalEntry _instantiate(DecodingData data) {
    return JournalEntry(
      id: data.dec(_f$id),
      createdAt: data.dec(_f$createdAt),
      kind: data.dec(_f$kind),
      body: data.dec(_f$body),
      prompt: data.dec(_f$prompt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static JournalEntry fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<JournalEntry>(map);
  }

  static JournalEntry fromJson(String json) {
    return ensureInitialized().decodeJson<JournalEntry>(json);
  }
}

mixin JournalEntryMappable {
  String toJson() {
    return JournalEntryMapper.ensureInitialized().encodeJson<JournalEntry>(
      this as JournalEntry,
    );
  }

  Map<String, dynamic> toMap() {
    return JournalEntryMapper.ensureInitialized().encodeMap<JournalEntry>(
      this as JournalEntry,
    );
  }

  JournalEntryCopyWith<JournalEntry, JournalEntry, JournalEntry> get copyWith =>
      _JournalEntryCopyWithImpl<JournalEntry, JournalEntry>(
        this as JournalEntry,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return JournalEntryMapper.ensureInitialized().stringifyValue(
      this as JournalEntry,
    );
  }

  @override
  bool operator ==(Object other) {
    return JournalEntryMapper.ensureInitialized().equalsValue(
      this as JournalEntry,
      other,
    );
  }

  @override
  int get hashCode {
    return JournalEntryMapper.ensureInitialized().hashValue(
      this as JournalEntry,
    );
  }
}

extension JournalEntryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, JournalEntry, $Out> {
  JournalEntryCopyWith<$R, JournalEntry, $Out> get $asJournalEntry =>
      $base.as((v, t, t2) => _JournalEntryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class JournalEntryCopyWith<$R, $In extends JournalEntry, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    int? id,
    DateTime? createdAt,
    JournalKind? kind,
    String? body,
    String? prompt,
  });
  JournalEntryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _JournalEntryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, JournalEntry, $Out>
    implements JournalEntryCopyWith<$R, JournalEntry, $Out> {
  _JournalEntryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<JournalEntry> $mapper =
      JournalEntryMapper.ensureInitialized();
  @override
  $R call({
    int? id,
    DateTime? createdAt,
    JournalKind? kind,
    String? body,
    Object? prompt = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (createdAt != null) #createdAt: createdAt,
      if (kind != null) #kind: kind,
      if (body != null) #body: body,
      if (prompt != $none) #prompt: prompt,
    }),
  );
  @override
  JournalEntry $make(CopyWithData data) => JournalEntry(
    id: data.get(#id, or: $value.id),
    createdAt: data.get(#createdAt, or: $value.createdAt),
    kind: data.get(#kind, or: $value.kind),
    body: data.get(#body, or: $value.body),
    prompt: data.get(#prompt, or: $value.prompt),
  );

  @override
  JournalEntryCopyWith<$R2, JournalEntry, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _JournalEntryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

