// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'quiz.dart';

class QuizQuestionKindMapper extends EnumMapper<QuizQuestionKind> {
  QuizQuestionKindMapper._();

  static QuizQuestionKindMapper? _instance;
  static QuizQuestionKindMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = QuizQuestionKindMapper._());
    }
    return _instance!;
  }

  static QuizQuestionKind fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  QuizQuestionKind decode(dynamic value) {
    switch (value) {
      case r'single':
        return QuizQuestionKind.single;
      case r'multi':
        return QuizQuestionKind.multi;
      case r'date':
        return QuizQuestionKind.date;
      case r'text':
        return QuizQuestionKind.text;
      case r'interstitial':
        return QuizQuestionKind.interstitial;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(QuizQuestionKind self) {
    switch (self) {
      case QuizQuestionKind.single:
        return r'single';
      case QuizQuestionKind.multi:
        return r'multi';
      case QuizQuestionKind.date:
        return r'date';
      case QuizQuestionKind.text:
        return r'text';
      case QuizQuestionKind.interstitial:
        return r'interstitial';
    }
  }
}

extension QuizQuestionKindMapperExtension on QuizQuestionKind {
  String toValue() {
    QuizQuestionKindMapper.ensureInitialized();
    return MapperContainer.globals.toValue<QuizQuestionKind>(this) as String;
  }
}

class QuizOptionMapper extends ClassMapperBase<QuizOption> {
  QuizOptionMapper._();

  static QuizOptionMapper? _instance;
  static QuizOptionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = QuizOptionMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'QuizOption';

  static String _$id(QuizOption v) => v.id;
  static const Field<QuizOption, String> _f$id = Field('id', _$id);
  static String _$label(QuizOption v) => v.label;
  static const Field<QuizOption, String> _f$label = Field('label', _$label);
  static String? _$detail(QuizOption v) => v.detail;
  static const Field<QuizOption, String> _f$detail = Field(
    'detail',
    _$detail,
    opt: true,
  );

  @override
  final MappableFields<QuizOption> fields = const {
    #id: _f$id,
    #label: _f$label,
    #detail: _f$detail,
  };

  static QuizOption _instantiate(DecodingData data) {
    return QuizOption(
      id: data.dec(_f$id),
      label: data.dec(_f$label),
      detail: data.dec(_f$detail),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static QuizOption fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<QuizOption>(map);
  }

  static QuizOption fromJson(String json) {
    return ensureInitialized().decodeJson<QuizOption>(json);
  }
}

mixin QuizOptionMappable {
  String toJson() {
    return QuizOptionMapper.ensureInitialized().encodeJson<QuizOption>(
      this as QuizOption,
    );
  }

  Map<String, dynamic> toMap() {
    return QuizOptionMapper.ensureInitialized().encodeMap<QuizOption>(
      this as QuizOption,
    );
  }

  QuizOptionCopyWith<QuizOption, QuizOption, QuizOption> get copyWith =>
      _QuizOptionCopyWithImpl<QuizOption, QuizOption>(
        this as QuizOption,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return QuizOptionMapper.ensureInitialized().stringifyValue(
      this as QuizOption,
    );
  }

  @override
  bool operator ==(Object other) {
    return QuizOptionMapper.ensureInitialized().equalsValue(
      this as QuizOption,
      other,
    );
  }

  @override
  int get hashCode {
    return QuizOptionMapper.ensureInitialized().hashValue(this as QuizOption);
  }
}

extension QuizOptionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, QuizOption, $Out> {
  QuizOptionCopyWith<$R, QuizOption, $Out> get $asQuizOption =>
      $base.as((v, t, t2) => _QuizOptionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class QuizOptionCopyWith<$R, $In extends QuizOption, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? id, String? label, String? detail});
  QuizOptionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _QuizOptionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, QuizOption, $Out>
    implements QuizOptionCopyWith<$R, QuizOption, $Out> {
  _QuizOptionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<QuizOption> $mapper =
      QuizOptionMapper.ensureInitialized();
  @override
  $R call({String? id, String? label, Object? detail = $none}) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (label != null) #label: label,
      if (detail != $none) #detail: detail,
    }),
  );
  @override
  QuizOption $make(CopyWithData data) => QuizOption(
    id: data.get(#id, or: $value.id),
    label: data.get(#label, or: $value.label),
    detail: data.get(#detail, or: $value.detail),
  );

  @override
  QuizOptionCopyWith<$R2, QuizOption, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _QuizOptionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class QuizConditionMapper extends ClassMapperBase<QuizCondition> {
  QuizConditionMapper._();

  static QuizConditionMapper? _instance;
  static QuizConditionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = QuizConditionMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'QuizCondition';

  static String _$questionId(QuizCondition v) => v.questionId;
  static const Field<QuizCondition, String> _f$questionId = Field(
    'questionId',
    _$questionId,
  );
  static List<String> _$anyOf(QuizCondition v) => v.anyOf;
  static const Field<QuizCondition, List<String>> _f$anyOf = Field(
    'anyOf',
    _$anyOf,
  );

  @override
  final MappableFields<QuizCondition> fields = const {
    #questionId: _f$questionId,
    #anyOf: _f$anyOf,
  };

  static QuizCondition _instantiate(DecodingData data) {
    return QuizCondition(
      questionId: data.dec(_f$questionId),
      anyOf: data.dec(_f$anyOf),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static QuizCondition fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<QuizCondition>(map);
  }

  static QuizCondition fromJson(String json) {
    return ensureInitialized().decodeJson<QuizCondition>(json);
  }
}

mixin QuizConditionMappable {
  String toJson() {
    return QuizConditionMapper.ensureInitialized().encodeJson<QuizCondition>(
      this as QuizCondition,
    );
  }

  Map<String, dynamic> toMap() {
    return QuizConditionMapper.ensureInitialized().encodeMap<QuizCondition>(
      this as QuizCondition,
    );
  }

  QuizConditionCopyWith<QuizCondition, QuizCondition, QuizCondition>
  get copyWith => _QuizConditionCopyWithImpl<QuizCondition, QuizCondition>(
    this as QuizCondition,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return QuizConditionMapper.ensureInitialized().stringifyValue(
      this as QuizCondition,
    );
  }

  @override
  bool operator ==(Object other) {
    return QuizConditionMapper.ensureInitialized().equalsValue(
      this as QuizCondition,
      other,
    );
  }

  @override
  int get hashCode {
    return QuizConditionMapper.ensureInitialized().hashValue(
      this as QuizCondition,
    );
  }
}

extension QuizConditionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, QuizCondition, $Out> {
  QuizConditionCopyWith<$R, QuizCondition, $Out> get $asQuizCondition =>
      $base.as((v, t, t2) => _QuizConditionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class QuizConditionCopyWith<$R, $In extends QuizCondition, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get anyOf;
  $R call({String? questionId, List<String>? anyOf});
  QuizConditionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _QuizConditionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, QuizCondition, $Out>
    implements QuizConditionCopyWith<$R, QuizCondition, $Out> {
  _QuizConditionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<QuizCondition> $mapper =
      QuizConditionMapper.ensureInitialized();
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get anyOf =>
      ListCopyWith(
        $value.anyOf,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(anyOf: v),
      );
  @override
  $R call({String? questionId, List<String>? anyOf}) => $apply(
    FieldCopyWithData({
      if (questionId != null) #questionId: questionId,
      if (anyOf != null) #anyOf: anyOf,
    }),
  );
  @override
  QuizCondition $make(CopyWithData data) => QuizCondition(
    questionId: data.get(#questionId, or: $value.questionId),
    anyOf: data.get(#anyOf, or: $value.anyOf),
  );

  @override
  QuizConditionCopyWith<$R2, QuizCondition, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _QuizConditionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class QuizQuestionMapper extends ClassMapperBase<QuizQuestion> {
  QuizQuestionMapper._();

  static QuizQuestionMapper? _instance;
  static QuizQuestionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = QuizQuestionMapper._());
      QuizQuestionKindMapper.ensureInitialized();
      QuizOptionMapper.ensureInitialized();
      QuizConditionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'QuizQuestion';

  static String _$id(QuizQuestion v) => v.id;
  static const Field<QuizQuestion, String> _f$id = Field('id', _$id);
  static QuizQuestionKind _$kind(QuizQuestion v) => v.kind;
  static const Field<QuizQuestion, QuizQuestionKind> _f$kind = Field(
    'kind',
    _$kind,
  );
  static String _$title(QuizQuestion v) => v.title;
  static const Field<QuizQuestion, String> _f$title = Field('title', _$title);
  static String? _$subtitle(QuizQuestion v) => v.subtitle;
  static const Field<QuizQuestion, String> _f$subtitle = Field(
    'subtitle',
    _$subtitle,
    opt: true,
  );
  static List<QuizOption> _$options(QuizQuestion v) => v.options;
  static const Field<QuizQuestion, List<QuizOption>> _f$options = Field(
    'options',
    _$options,
    opt: true,
    def: const [],
  );
  static QuizCondition? _$showIf(QuizQuestion v) => v.showIf;
  static const Field<QuizQuestion, QuizCondition> _f$showIf = Field(
    'showIf',
    _$showIf,
    opt: true,
  );

  @override
  final MappableFields<QuizQuestion> fields = const {
    #id: _f$id,
    #kind: _f$kind,
    #title: _f$title,
    #subtitle: _f$subtitle,
    #options: _f$options,
    #showIf: _f$showIf,
  };

  static QuizQuestion _instantiate(DecodingData data) {
    return QuizQuestion(
      id: data.dec(_f$id),
      kind: data.dec(_f$kind),
      title: data.dec(_f$title),
      subtitle: data.dec(_f$subtitle),
      options: data.dec(_f$options),
      showIf: data.dec(_f$showIf),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static QuizQuestion fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<QuizQuestion>(map);
  }

  static QuizQuestion fromJson(String json) {
    return ensureInitialized().decodeJson<QuizQuestion>(json);
  }
}

mixin QuizQuestionMappable {
  String toJson() {
    return QuizQuestionMapper.ensureInitialized().encodeJson<QuizQuestion>(
      this as QuizQuestion,
    );
  }

  Map<String, dynamic> toMap() {
    return QuizQuestionMapper.ensureInitialized().encodeMap<QuizQuestion>(
      this as QuizQuestion,
    );
  }

  QuizQuestionCopyWith<QuizQuestion, QuizQuestion, QuizQuestion> get copyWith =>
      _QuizQuestionCopyWithImpl<QuizQuestion, QuizQuestion>(
        this as QuizQuestion,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return QuizQuestionMapper.ensureInitialized().stringifyValue(
      this as QuizQuestion,
    );
  }

  @override
  bool operator ==(Object other) {
    return QuizQuestionMapper.ensureInitialized().equalsValue(
      this as QuizQuestion,
      other,
    );
  }

  @override
  int get hashCode {
    return QuizQuestionMapper.ensureInitialized().hashValue(
      this as QuizQuestion,
    );
  }
}

extension QuizQuestionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, QuizQuestion, $Out> {
  QuizQuestionCopyWith<$R, QuizQuestion, $Out> get $asQuizQuestion =>
      $base.as((v, t, t2) => _QuizQuestionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class QuizQuestionCopyWith<$R, $In extends QuizQuestion, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, QuizOption, QuizOptionCopyWith<$R, QuizOption, QuizOption>>
  get options;
  QuizConditionCopyWith<$R, QuizCondition, QuizCondition>? get showIf;
  $R call({
    String? id,
    QuizQuestionKind? kind,
    String? title,
    String? subtitle,
    List<QuizOption>? options,
    QuizCondition? showIf,
  });
  QuizQuestionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _QuizQuestionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, QuizQuestion, $Out>
    implements QuizQuestionCopyWith<$R, QuizQuestion, $Out> {
  _QuizQuestionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<QuizQuestion> $mapper =
      QuizQuestionMapper.ensureInitialized();
  @override
  ListCopyWith<$R, QuizOption, QuizOptionCopyWith<$R, QuizOption, QuizOption>>
  get options => ListCopyWith(
    $value.options,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(options: v),
  );
  @override
  QuizConditionCopyWith<$R, QuizCondition, QuizCondition>? get showIf =>
      $value.showIf?.copyWith.$chain((v) => call(showIf: v));
  @override
  $R call({
    String? id,
    QuizQuestionKind? kind,
    String? title,
    Object? subtitle = $none,
    List<QuizOption>? options,
    Object? showIf = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (kind != null) #kind: kind,
      if (title != null) #title: title,
      if (subtitle != $none) #subtitle: subtitle,
      if (options != null) #options: options,
      if (showIf != $none) #showIf: showIf,
    }),
  );
  @override
  QuizQuestion $make(CopyWithData data) => QuizQuestion(
    id: data.get(#id, or: $value.id),
    kind: data.get(#kind, or: $value.kind),
    title: data.get(#title, or: $value.title),
    subtitle: data.get(#subtitle, or: $value.subtitle),
    options: data.get(#options, or: $value.options),
    showIf: data.get(#showIf, or: $value.showIf),
  );

  @override
  QuizQuestionCopyWith<$R2, QuizQuestion, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _QuizQuestionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class QuizAnswersMapper extends ClassMapperBase<QuizAnswers> {
  QuizAnswersMapper._();

  static QuizAnswersMapper? _instance;
  static QuizAnswersMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = QuizAnswersMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'QuizAnswers';

  static Map<String, List<String>> _$selections(QuizAnswers v) => v.selections;
  static const Field<QuizAnswers, Map<String, List<String>>> _f$selections =
      Field('selections', _$selections, opt: true, def: const {});
  static Map<String, DateTime> _$dates(QuizAnswers v) => v.dates;
  static const Field<QuizAnswers, Map<String, DateTime>> _f$dates = Field(
    'dates',
    _$dates,
    opt: true,
    def: const {},
  );
  static Map<String, String> _$texts(QuizAnswers v) => v.texts;
  static const Field<QuizAnswers, Map<String, String>> _f$texts = Field(
    'texts',
    _$texts,
    opt: true,
    def: const {},
  );

  @override
  final MappableFields<QuizAnswers> fields = const {
    #selections: _f$selections,
    #dates: _f$dates,
    #texts: _f$texts,
  };

  static QuizAnswers _instantiate(DecodingData data) {
    return QuizAnswers(
      selections: data.dec(_f$selections),
      dates: data.dec(_f$dates),
      texts: data.dec(_f$texts),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static QuizAnswers fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<QuizAnswers>(map);
  }

  static QuizAnswers fromJson(String json) {
    return ensureInitialized().decodeJson<QuizAnswers>(json);
  }
}

mixin QuizAnswersMappable {
  String toJson() {
    return QuizAnswersMapper.ensureInitialized().encodeJson<QuizAnswers>(
      this as QuizAnswers,
    );
  }

  Map<String, dynamic> toMap() {
    return QuizAnswersMapper.ensureInitialized().encodeMap<QuizAnswers>(
      this as QuizAnswers,
    );
  }

  QuizAnswersCopyWith<QuizAnswers, QuizAnswers, QuizAnswers> get copyWith =>
      _QuizAnswersCopyWithImpl<QuizAnswers, QuizAnswers>(
        this as QuizAnswers,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return QuizAnswersMapper.ensureInitialized().stringifyValue(
      this as QuizAnswers,
    );
  }

  @override
  bool operator ==(Object other) {
    return QuizAnswersMapper.ensureInitialized().equalsValue(
      this as QuizAnswers,
      other,
    );
  }

  @override
  int get hashCode {
    return QuizAnswersMapper.ensureInitialized().hashValue(this as QuizAnswers);
  }
}

extension QuizAnswersValueCopy<$R, $Out>
    on ObjectCopyWith<$R, QuizAnswers, $Out> {
  QuizAnswersCopyWith<$R, QuizAnswers, $Out> get $asQuizAnswers =>
      $base.as((v, t, t2) => _QuizAnswersCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class QuizAnswersCopyWith<$R, $In extends QuizAnswers, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>
  >
  get selections;
  MapCopyWith<$R, String, DateTime, ObjectCopyWith<$R, DateTime, DateTime>>
  get dates;
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>> get texts;
  $R call({
    Map<String, List<String>>? selections,
    Map<String, DateTime>? dates,
    Map<String, String>? texts,
  });
  QuizAnswersCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _QuizAnswersCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, QuizAnswers, $Out>
    implements QuizAnswersCopyWith<$R, QuizAnswers, $Out> {
  _QuizAnswersCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<QuizAnswers> $mapper =
      QuizAnswersMapper.ensureInitialized();
  @override
  MapCopyWith<
    $R,
    String,
    List<String>,
    ObjectCopyWith<$R, List<String>, List<String>>
  >
  get selections => MapCopyWith(
    $value.selections,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(selections: v),
  );
  @override
  MapCopyWith<$R, String, DateTime, ObjectCopyWith<$R, DateTime, DateTime>>
  get dates => MapCopyWith(
    $value.dates,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(dates: v),
  );
  @override
  MapCopyWith<$R, String, String, ObjectCopyWith<$R, String, String>>
  get texts => MapCopyWith(
    $value.texts,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(texts: v),
  );
  @override
  $R call({
    Map<String, List<String>>? selections,
    Map<String, DateTime>? dates,
    Map<String, String>? texts,
  }) => $apply(
    FieldCopyWithData({
      if (selections != null) #selections: selections,
      if (dates != null) #dates: dates,
      if (texts != null) #texts: texts,
    }),
  );
  @override
  QuizAnswers $make(CopyWithData data) => QuizAnswers(
    selections: data.get(#selections, or: $value.selections),
    dates: data.get(#dates, or: $value.dates),
    texts: data.get(#texts, or: $value.texts),
  );

  @override
  QuizAnswersCopyWith<$R2, QuizAnswers, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _QuizAnswersCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

