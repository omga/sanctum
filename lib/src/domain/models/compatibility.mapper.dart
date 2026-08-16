// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'compatibility.dart';

class ZodiacAspectMapper extends EnumMapper<ZodiacAspect> {
  ZodiacAspectMapper._();

  static ZodiacAspectMapper? _instance;
  static ZodiacAspectMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ZodiacAspectMapper._());
    }
    return _instance!;
  }

  static ZodiacAspect fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ZodiacAspect decode(dynamic value) {
    switch (value) {
      case r'conjunction':
        return ZodiacAspect.conjunction;
      case r'semiSextile':
        return ZodiacAspect.semiSextile;
      case r'sextile':
        return ZodiacAspect.sextile;
      case r'square':
        return ZodiacAspect.square;
      case r'trine':
        return ZodiacAspect.trine;
      case r'quincunx':
        return ZodiacAspect.quincunx;
      case r'opposition':
        return ZodiacAspect.opposition;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ZodiacAspect self) {
    switch (self) {
      case ZodiacAspect.conjunction:
        return r'conjunction';
      case ZodiacAspect.semiSextile:
        return r'semiSextile';
      case ZodiacAspect.sextile:
        return r'sextile';
      case ZodiacAspect.square:
        return r'square';
      case ZodiacAspect.trine:
        return r'trine';
      case ZodiacAspect.quincunx:
        return r'quincunx';
      case ZodiacAspect.opposition:
        return r'opposition';
    }
  }
}

extension ZodiacAspectMapperExtension on ZodiacAspect {
  String toValue() {
    ZodiacAspectMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ZodiacAspect>(this) as String;
  }
}

class CompatibilityFacetMapper extends EnumMapper<CompatibilityFacet> {
  CompatibilityFacetMapper._();

  static CompatibilityFacetMapper? _instance;
  static CompatibilityFacetMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CompatibilityFacetMapper._());
    }
    return _instance!;
  }

  static CompatibilityFacet fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  CompatibilityFacet decode(dynamic value) {
    switch (value) {
      case r'spark':
        return CompatibilityFacet.spark;
      case r'vibe':
        return CompatibilityFacet.vibe;
      case r'trust':
        return CompatibilityFacet.trust;
      case r'drama':
        return CompatibilityFacet.drama;
      case r'depth':
        return CompatibilityFacet.depth;
      case r'future':
        return CompatibilityFacet.future;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(CompatibilityFacet self) {
    switch (self) {
      case CompatibilityFacet.spark:
        return r'spark';
      case CompatibilityFacet.vibe:
        return r'vibe';
      case CompatibilityFacet.trust:
        return r'trust';
      case CompatibilityFacet.drama:
        return r'drama';
      case CompatibilityFacet.depth:
        return r'depth';
      case CompatibilityFacet.future:
        return r'future';
    }
  }
}

extension CompatibilityFacetMapperExtension on CompatibilityFacet {
  String toValue() {
    CompatibilityFacetMapper.ensureInitialized();
    return MapperContainer.globals.toValue<CompatibilityFacet>(this) as String;
  }
}

class DirectionKindMapper extends EnumMapper<DirectionKind> {
  DirectionKindMapper._();

  static DirectionKindMapper? _instance;
  static DirectionKindMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DirectionKindMapper._());
    }
    return _instance!;
  }

  static DirectionKind fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  DirectionKind decode(dynamic value) {
    switch (value) {
      case r'pull':
        return DirectionKind.pull;
      case r'power':
        return DirectionKind.power;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(DirectionKind self) {
    switch (self) {
      case DirectionKind.pull:
        return r'pull';
      case DirectionKind.power:
        return r'power';
    }
  }
}

extension DirectionKindMapperExtension on DirectionKind {
  String toValue() {
    DirectionKindMapper.ensureInitialized();
    return MapperContainer.globals.toValue<DirectionKind>(this) as String;
  }
}

class DirectionalReadingMapper extends ClassMapperBase<DirectionalReading> {
  DirectionalReadingMapper._();

  static DirectionalReadingMapper? _instance;
  static DirectionalReadingMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DirectionalReadingMapper._());
      DirectionKindMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'DirectionalReading';

  static DirectionKind _$kind(DirectionalReading v) => v.kind;
  static const Field<DirectionalReading, DirectionKind> _f$kind = Field(
    'kind',
    _$kind,
  );
  static int _$yourShare(DirectionalReading v) => v.yourShare;
  static const Field<DirectionalReading, int> _f$yourShare = Field(
    'yourShare',
    _$yourShare,
  );
  static String _$line(DirectionalReading v) => v.line;
  static const Field<DirectionalReading, String> _f$line = Field(
    'line',
    _$line,
  );

  @override
  final MappableFields<DirectionalReading> fields = const {
    #kind: _f$kind,
    #yourShare: _f$yourShare,
    #line: _f$line,
  };

  static DirectionalReading _instantiate(DecodingData data) {
    return DirectionalReading(
      kind: data.dec(_f$kind),
      yourShare: data.dec(_f$yourShare),
      line: data.dec(_f$line),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DirectionalReading fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DirectionalReading>(map);
  }

  static DirectionalReading fromJson(String json) {
    return ensureInitialized().decodeJson<DirectionalReading>(json);
  }
}

mixin DirectionalReadingMappable {
  String toJson() {
    return DirectionalReadingMapper.ensureInitialized()
        .encodeJson<DirectionalReading>(this as DirectionalReading);
  }

  Map<String, dynamic> toMap() {
    return DirectionalReadingMapper.ensureInitialized()
        .encodeMap<DirectionalReading>(this as DirectionalReading);
  }

  DirectionalReadingCopyWith<
    DirectionalReading,
    DirectionalReading,
    DirectionalReading
  >
  get copyWith =>
      _DirectionalReadingCopyWithImpl<DirectionalReading, DirectionalReading>(
        this as DirectionalReading,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return DirectionalReadingMapper.ensureInitialized().stringifyValue(
      this as DirectionalReading,
    );
  }

  @override
  bool operator ==(Object other) {
    return DirectionalReadingMapper.ensureInitialized().equalsValue(
      this as DirectionalReading,
      other,
    );
  }

  @override
  int get hashCode {
    return DirectionalReadingMapper.ensureInitialized().hashValue(
      this as DirectionalReading,
    );
  }
}

extension DirectionalReadingValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DirectionalReading, $Out> {
  DirectionalReadingCopyWith<$R, DirectionalReading, $Out>
  get $asDirectionalReading => $base.as(
    (v, t, t2) => _DirectionalReadingCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class DirectionalReadingCopyWith<
  $R,
  $In extends DirectionalReading,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({DirectionKind? kind, int? yourShare, String? line});
  DirectionalReadingCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DirectionalReadingCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DirectionalReading, $Out>
    implements DirectionalReadingCopyWith<$R, DirectionalReading, $Out> {
  _DirectionalReadingCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DirectionalReading> $mapper =
      DirectionalReadingMapper.ensureInitialized();
  @override
  $R call({DirectionKind? kind, int? yourShare, String? line}) => $apply(
    FieldCopyWithData({
      if (kind != null) #kind: kind,
      if (yourShare != null) #yourShare: yourShare,
      if (line != null) #line: line,
    }),
  );
  @override
  DirectionalReading $make(CopyWithData data) => DirectionalReading(
    kind: data.get(#kind, or: $value.kind),
    yourShare: data.get(#yourShare, or: $value.yourShare),
    line: data.get(#line, or: $value.line),
  );

  @override
  DirectionalReadingCopyWith<$R2, DirectionalReading, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _DirectionalReadingCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class FacetScoreMapper extends ClassMapperBase<FacetScore> {
  FacetScoreMapper._();

  static FacetScoreMapper? _instance;
  static FacetScoreMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = FacetScoreMapper._());
      CompatibilityFacetMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FacetScore';

  static CompatibilityFacet _$facet(FacetScore v) => v.facet;
  static const Field<FacetScore, CompatibilityFacet> _f$facet = Field(
    'facet',
    _$facet,
  );
  static int _$score(FacetScore v) => v.score;
  static const Field<FacetScore, int> _f$score = Field('score', _$score);

  @override
  final MappableFields<FacetScore> fields = const {
    #facet: _f$facet,
    #score: _f$score,
  };

  static FacetScore _instantiate(DecodingData data) {
    return FacetScore(facet: data.dec(_f$facet), score: data.dec(_f$score));
  }

  @override
  final Function instantiate = _instantiate;

  static FacetScore fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FacetScore>(map);
  }

  static FacetScore fromJson(String json) {
    return ensureInitialized().decodeJson<FacetScore>(json);
  }
}

mixin FacetScoreMappable {
  String toJson() {
    return FacetScoreMapper.ensureInitialized().encodeJson<FacetScore>(
      this as FacetScore,
    );
  }

  Map<String, dynamic> toMap() {
    return FacetScoreMapper.ensureInitialized().encodeMap<FacetScore>(
      this as FacetScore,
    );
  }

  FacetScoreCopyWith<FacetScore, FacetScore, FacetScore> get copyWith =>
      _FacetScoreCopyWithImpl<FacetScore, FacetScore>(
        this as FacetScore,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return FacetScoreMapper.ensureInitialized().stringifyValue(
      this as FacetScore,
    );
  }

  @override
  bool operator ==(Object other) {
    return FacetScoreMapper.ensureInitialized().equalsValue(
      this as FacetScore,
      other,
    );
  }

  @override
  int get hashCode {
    return FacetScoreMapper.ensureInitialized().hashValue(this as FacetScore);
  }
}

extension FacetScoreValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FacetScore, $Out> {
  FacetScoreCopyWith<$R, FacetScore, $Out> get $asFacetScore =>
      $base.as((v, t, t2) => _FacetScoreCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class FacetScoreCopyWith<$R, $In extends FacetScore, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({CompatibilityFacet? facet, int? score});
  FacetScoreCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _FacetScoreCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FacetScore, $Out>
    implements FacetScoreCopyWith<$R, FacetScore, $Out> {
  _FacetScoreCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FacetScore> $mapper =
      FacetScoreMapper.ensureInitialized();
  @override
  $R call({CompatibilityFacet? facet, int? score}) => $apply(
    FieldCopyWithData({
      if (facet != null) #facet: facet,
      if (score != null) #score: score,
    }),
  );
  @override
  FacetScore $make(CopyWithData data) => FacetScore(
    facet: data.get(#facet, or: $value.facet),
    score: data.get(#score, or: $value.score),
  );

  @override
  FacetScoreCopyWith<$R2, FacetScore, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _FacetScoreCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class MatchPersonMapper extends ClassMapperBase<MatchPerson> {
  MatchPersonMapper._();

  static MatchPersonMapper? _instance;
  static MatchPersonMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MatchPersonMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'MatchPerson';

  static String _$name(MatchPerson v) => v.name;
  static const Field<MatchPerson, String> _f$name = Field('name', _$name);
  static DateTime _$birthDate(MatchPerson v) => v.birthDate;
  static const Field<MatchPerson, DateTime> _f$birthDate = Field(
    'birthDate',
    _$birthDate,
  );
  static String? _$celebrityId(MatchPerson v) => v.celebrityId;
  static const Field<MatchPerson, String> _f$celebrityId = Field(
    'celebrityId',
    _$celebrityId,
    opt: true,
  );

  @override
  final MappableFields<MatchPerson> fields = const {
    #name: _f$name,
    #birthDate: _f$birthDate,
    #celebrityId: _f$celebrityId,
  };

  static MatchPerson _instantiate(DecodingData data) {
    return MatchPerson(
      name: data.dec(_f$name),
      birthDate: data.dec(_f$birthDate),
      celebrityId: data.dec(_f$celebrityId),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static MatchPerson fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<MatchPerson>(map);
  }

  static MatchPerson fromJson(String json) {
    return ensureInitialized().decodeJson<MatchPerson>(json);
  }
}

mixin MatchPersonMappable {
  String toJson() {
    return MatchPersonMapper.ensureInitialized().encodeJson<MatchPerson>(
      this as MatchPerson,
    );
  }

  Map<String, dynamic> toMap() {
    return MatchPersonMapper.ensureInitialized().encodeMap<MatchPerson>(
      this as MatchPerson,
    );
  }

  MatchPersonCopyWith<MatchPerson, MatchPerson, MatchPerson> get copyWith =>
      _MatchPersonCopyWithImpl<MatchPerson, MatchPerson>(
        this as MatchPerson,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return MatchPersonMapper.ensureInitialized().stringifyValue(
      this as MatchPerson,
    );
  }

  @override
  bool operator ==(Object other) {
    return MatchPersonMapper.ensureInitialized().equalsValue(
      this as MatchPerson,
      other,
    );
  }

  @override
  int get hashCode {
    return MatchPersonMapper.ensureInitialized().hashValue(this as MatchPerson);
  }
}

extension MatchPersonValueCopy<$R, $Out>
    on ObjectCopyWith<$R, MatchPerson, $Out> {
  MatchPersonCopyWith<$R, MatchPerson, $Out> get $asMatchPerson =>
      $base.as((v, t, t2) => _MatchPersonCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class MatchPersonCopyWith<$R, $In extends MatchPerson, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? name, DateTime? birthDate, String? celebrityId});
  MatchPersonCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _MatchPersonCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, MatchPerson, $Out>
    implements MatchPersonCopyWith<$R, MatchPerson, $Out> {
  _MatchPersonCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<MatchPerson> $mapper =
      MatchPersonMapper.ensureInitialized();
  @override
  $R call({String? name, DateTime? birthDate, Object? celebrityId = $none}) =>
      $apply(
        FieldCopyWithData({
          if (name != null) #name: name,
          if (birthDate != null) #birthDate: birthDate,
          if (celebrityId != $none) #celebrityId: celebrityId,
        }),
      );
  @override
  MatchPerson $make(CopyWithData data) => MatchPerson(
    name: data.get(#name, or: $value.name),
    birthDate: data.get(#birthDate, or: $value.birthDate),
    celebrityId: data.get(#celebrityId, or: $value.celebrityId),
  );

  @override
  MatchPersonCopyWith<$R2, MatchPerson, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _MatchPersonCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CompatibilityMatchMapper extends ClassMapperBase<CompatibilityMatch> {
  CompatibilityMatchMapper._();

  static CompatibilityMatchMapper? _instance;
  static CompatibilityMatchMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CompatibilityMatchMapper._());
      MatchPersonMapper.ensureInitialized();
      ZodiacAspectMapper.ensureInitialized();
      FacetScoreMapper.ensureInitialized();
      DirectionalReadingMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CompatibilityMatch';

  static MatchPerson _$you(CompatibilityMatch v) => v.you;
  static const Field<CompatibilityMatch, MatchPerson> _f$you = Field(
    'you',
    _$you,
  );
  static MatchPerson _$them(CompatibilityMatch v) => v.them;
  static const Field<CompatibilityMatch, MatchPerson> _f$them = Field(
    'them',
    _$them,
  );
  static ZodiacAspect _$aspect(CompatibilityMatch v) => v.aspect;
  static const Field<CompatibilityMatch, ZodiacAspect> _f$aspect = Field(
    'aspect',
    _$aspect,
  );
  static int _$overall(CompatibilityMatch v) => v.overall;
  static const Field<CompatibilityMatch, int> _f$overall = Field(
    'overall',
    _$overall,
  );
  static List<FacetScore> _$facets(CompatibilityMatch v) => v.facets;
  static const Field<CompatibilityMatch, List<FacetScore>> _f$facets = Field(
    'facets',
    _$facets,
  );
  static String _$verdict(CompatibilityMatch v) => v.verdict;
  static const Field<CompatibilityMatch, String> _f$verdict = Field(
    'verdict',
    _$verdict,
  );
  static String _$dynamicLine(CompatibilityMatch v) => v.dynamicLine;
  static const Field<CompatibilityMatch, String> _f$dynamicLine = Field(
    'dynamicLine',
    _$dynamicLine,
  );
  static String _$elementLine(CompatibilityMatch v) => v.elementLine;
  static const Field<CompatibilityMatch, String> _f$elementLine = Field(
    'elementLine',
    _$elementLine,
  );
  static String _$worksLine(CompatibilityMatch v) => v.worksLine;
  static const Field<CompatibilityMatch, String> _f$worksLine = Field(
    'worksLine',
    _$worksLine,
  );
  static String _$watchLine(CompatibilityMatch v) => v.watchLine;
  static const Field<CompatibilityMatch, String> _f$watchLine = Field(
    'watchLine',
    _$watchLine,
  );
  static String _$shareLine(CompatibilityMatch v) => v.shareLine;
  static const Field<CompatibilityMatch, String> _f$shareLine = Field(
    'shareLine',
    _$shareLine,
  );
  static DirectionalReading _$pull(CompatibilityMatch v) => v.pull;
  static const Field<CompatibilityMatch, DirectionalReading> _f$pull = Field(
    'pull',
    _$pull,
  );
  static DirectionalReading _$power(CompatibilityMatch v) => v.power;
  static const Field<CompatibilityMatch, DirectionalReading> _f$power = Field(
    'power',
    _$power,
  );
  static DateTime _$createdAt(CompatibilityMatch v) => v.createdAt;
  static const Field<CompatibilityMatch, DateTime> _f$createdAt = Field(
    'createdAt',
    _$createdAt,
  );

  @override
  final MappableFields<CompatibilityMatch> fields = const {
    #you: _f$you,
    #them: _f$them,
    #aspect: _f$aspect,
    #overall: _f$overall,
    #facets: _f$facets,
    #verdict: _f$verdict,
    #dynamicLine: _f$dynamicLine,
    #elementLine: _f$elementLine,
    #worksLine: _f$worksLine,
    #watchLine: _f$watchLine,
    #shareLine: _f$shareLine,
    #pull: _f$pull,
    #power: _f$power,
    #createdAt: _f$createdAt,
  };

  static CompatibilityMatch _instantiate(DecodingData data) {
    return CompatibilityMatch(
      you: data.dec(_f$you),
      them: data.dec(_f$them),
      aspect: data.dec(_f$aspect),
      overall: data.dec(_f$overall),
      facets: data.dec(_f$facets),
      verdict: data.dec(_f$verdict),
      dynamicLine: data.dec(_f$dynamicLine),
      elementLine: data.dec(_f$elementLine),
      worksLine: data.dec(_f$worksLine),
      watchLine: data.dec(_f$watchLine),
      shareLine: data.dec(_f$shareLine),
      pull: data.dec(_f$pull),
      power: data.dec(_f$power),
      createdAt: data.dec(_f$createdAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CompatibilityMatch fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CompatibilityMatch>(map);
  }

  static CompatibilityMatch fromJson(String json) {
    return ensureInitialized().decodeJson<CompatibilityMatch>(json);
  }
}

mixin CompatibilityMatchMappable {
  String toJson() {
    return CompatibilityMatchMapper.ensureInitialized()
        .encodeJson<CompatibilityMatch>(this as CompatibilityMatch);
  }

  Map<String, dynamic> toMap() {
    return CompatibilityMatchMapper.ensureInitialized()
        .encodeMap<CompatibilityMatch>(this as CompatibilityMatch);
  }

  CompatibilityMatchCopyWith<
    CompatibilityMatch,
    CompatibilityMatch,
    CompatibilityMatch
  >
  get copyWith =>
      _CompatibilityMatchCopyWithImpl<CompatibilityMatch, CompatibilityMatch>(
        this as CompatibilityMatch,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CompatibilityMatchMapper.ensureInitialized().stringifyValue(
      this as CompatibilityMatch,
    );
  }

  @override
  bool operator ==(Object other) {
    return CompatibilityMatchMapper.ensureInitialized().equalsValue(
      this as CompatibilityMatch,
      other,
    );
  }

  @override
  int get hashCode {
    return CompatibilityMatchMapper.ensureInitialized().hashValue(
      this as CompatibilityMatch,
    );
  }
}

extension CompatibilityMatchValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CompatibilityMatch, $Out> {
  CompatibilityMatchCopyWith<$R, CompatibilityMatch, $Out>
  get $asCompatibilityMatch => $base.as(
    (v, t, t2) => _CompatibilityMatchCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class CompatibilityMatchCopyWith<
  $R,
  $In extends CompatibilityMatch,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  MatchPersonCopyWith<$R, MatchPerson, MatchPerson> get you;
  MatchPersonCopyWith<$R, MatchPerson, MatchPerson> get them;
  ListCopyWith<$R, FacetScore, FacetScoreCopyWith<$R, FacetScore, FacetScore>>
  get facets;
  DirectionalReadingCopyWith<$R, DirectionalReading, DirectionalReading>
  get pull;
  DirectionalReadingCopyWith<$R, DirectionalReading, DirectionalReading>
  get power;
  $R call({
    MatchPerson? you,
    MatchPerson? them,
    ZodiacAspect? aspect,
    int? overall,
    List<FacetScore>? facets,
    String? verdict,
    String? dynamicLine,
    String? elementLine,
    String? worksLine,
    String? watchLine,
    String? shareLine,
    DirectionalReading? pull,
    DirectionalReading? power,
    DateTime? createdAt,
  });
  CompatibilityMatchCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CompatibilityMatchCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CompatibilityMatch, $Out>
    implements CompatibilityMatchCopyWith<$R, CompatibilityMatch, $Out> {
  _CompatibilityMatchCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CompatibilityMatch> $mapper =
      CompatibilityMatchMapper.ensureInitialized();
  @override
  MatchPersonCopyWith<$R, MatchPerson, MatchPerson> get you =>
      $value.you.copyWith.$chain((v) => call(you: v));
  @override
  MatchPersonCopyWith<$R, MatchPerson, MatchPerson> get them =>
      $value.them.copyWith.$chain((v) => call(them: v));
  @override
  ListCopyWith<$R, FacetScore, FacetScoreCopyWith<$R, FacetScore, FacetScore>>
  get facets => ListCopyWith(
    $value.facets,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(facets: v),
  );
  @override
  DirectionalReadingCopyWith<$R, DirectionalReading, DirectionalReading>
  get pull => $value.pull.copyWith.$chain((v) => call(pull: v));
  @override
  DirectionalReadingCopyWith<$R, DirectionalReading, DirectionalReading>
  get power => $value.power.copyWith.$chain((v) => call(power: v));
  @override
  $R call({
    MatchPerson? you,
    MatchPerson? them,
    ZodiacAspect? aspect,
    int? overall,
    List<FacetScore>? facets,
    String? verdict,
    String? dynamicLine,
    String? elementLine,
    String? worksLine,
    String? watchLine,
    String? shareLine,
    DirectionalReading? pull,
    DirectionalReading? power,
    DateTime? createdAt,
  }) => $apply(
    FieldCopyWithData({
      if (you != null) #you: you,
      if (them != null) #them: them,
      if (aspect != null) #aspect: aspect,
      if (overall != null) #overall: overall,
      if (facets != null) #facets: facets,
      if (verdict != null) #verdict: verdict,
      if (dynamicLine != null) #dynamicLine: dynamicLine,
      if (elementLine != null) #elementLine: elementLine,
      if (worksLine != null) #worksLine: worksLine,
      if (watchLine != null) #watchLine: watchLine,
      if (shareLine != null) #shareLine: shareLine,
      if (pull != null) #pull: pull,
      if (power != null) #power: power,
      if (createdAt != null) #createdAt: createdAt,
    }),
  );
  @override
  CompatibilityMatch $make(CopyWithData data) => CompatibilityMatch(
    you: data.get(#you, or: $value.you),
    them: data.get(#them, or: $value.them),
    aspect: data.get(#aspect, or: $value.aspect),
    overall: data.get(#overall, or: $value.overall),
    facets: data.get(#facets, or: $value.facets),
    verdict: data.get(#verdict, or: $value.verdict),
    dynamicLine: data.get(#dynamicLine, or: $value.dynamicLine),
    elementLine: data.get(#elementLine, or: $value.elementLine),
    worksLine: data.get(#worksLine, or: $value.worksLine),
    watchLine: data.get(#watchLine, or: $value.watchLine),
    shareLine: data.get(#shareLine, or: $value.shareLine),
    pull: data.get(#pull, or: $value.pull),
    power: data.get(#power, or: $value.power),
    createdAt: data.get(#createdAt, or: $value.createdAt),
  );

  @override
  CompatibilityMatchCopyWith<$R2, CompatibilityMatch, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CompatibilityMatchCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class CompatibilityStateMapper extends ClassMapperBase<CompatibilityState> {
  CompatibilityStateMapper._();

  static CompatibilityStateMapper? _instance;
  static CompatibilityStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CompatibilityStateMapper._());
      CompatibilityMatchMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'CompatibilityState';

  static List<CompatibilityMatch> _$matches(CompatibilityState v) => v.matches;
  static const Field<CompatibilityState, List<CompatibilityMatch>> _f$matches =
      Field('matches', _$matches, opt: true, def: const []);
  static List<String> _$revealedIds(CompatibilityState v) => v.revealedIds;
  static const Field<CompatibilityState, List<String>> _f$revealedIds = Field(
    'revealedIds',
    _$revealedIds,
    opt: true,
    def: const [],
  );
  static bool _$hasSharedInvite(CompatibilityState v) => v.hasSharedInvite;
  static const Field<CompatibilityState, bool> _f$hasSharedInvite = Field(
    'hasSharedInvite',
    _$hasSharedInvite,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<CompatibilityState> fields = const {
    #matches: _f$matches,
    #revealedIds: _f$revealedIds,
    #hasSharedInvite: _f$hasSharedInvite,
  };

  static CompatibilityState _instantiate(DecodingData data) {
    return CompatibilityState(
      matches: data.dec(_f$matches),
      revealedIds: data.dec(_f$revealedIds),
      hasSharedInvite: data.dec(_f$hasSharedInvite),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CompatibilityState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CompatibilityState>(map);
  }

  static CompatibilityState fromJson(String json) {
    return ensureInitialized().decodeJson<CompatibilityState>(json);
  }
}

mixin CompatibilityStateMappable {
  String toJson() {
    return CompatibilityStateMapper.ensureInitialized()
        .encodeJson<CompatibilityState>(this as CompatibilityState);
  }

  Map<String, dynamic> toMap() {
    return CompatibilityStateMapper.ensureInitialized()
        .encodeMap<CompatibilityState>(this as CompatibilityState);
  }

  CompatibilityStateCopyWith<
    CompatibilityState,
    CompatibilityState,
    CompatibilityState
  >
  get copyWith =>
      _CompatibilityStateCopyWithImpl<CompatibilityState, CompatibilityState>(
        this as CompatibilityState,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return CompatibilityStateMapper.ensureInitialized().stringifyValue(
      this as CompatibilityState,
    );
  }

  @override
  bool operator ==(Object other) {
    return CompatibilityStateMapper.ensureInitialized().equalsValue(
      this as CompatibilityState,
      other,
    );
  }

  @override
  int get hashCode {
    return CompatibilityStateMapper.ensureInitialized().hashValue(
      this as CompatibilityState,
    );
  }
}

extension CompatibilityStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CompatibilityState, $Out> {
  CompatibilityStateCopyWith<$R, CompatibilityState, $Out>
  get $asCompatibilityState => $base.as(
    (v, t, t2) => _CompatibilityStateCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class CompatibilityStateCopyWith<
  $R,
  $In extends CompatibilityState,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    CompatibilityMatch,
    CompatibilityMatchCopyWith<$R, CompatibilityMatch, CompatibilityMatch>
  >
  get matches;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get revealedIds;
  $R call({
    List<CompatibilityMatch>? matches,
    List<String>? revealedIds,
    bool? hasSharedInvite,
  });
  CompatibilityStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CompatibilityStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CompatibilityState, $Out>
    implements CompatibilityStateCopyWith<$R, CompatibilityState, $Out> {
  _CompatibilityStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CompatibilityState> $mapper =
      CompatibilityStateMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    CompatibilityMatch,
    CompatibilityMatchCopyWith<$R, CompatibilityMatch, CompatibilityMatch>
  >
  get matches => ListCopyWith(
    $value.matches,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(matches: v),
  );
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>>
  get revealedIds => ListCopyWith(
    $value.revealedIds,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(revealedIds: v),
  );
  @override
  $R call({
    List<CompatibilityMatch>? matches,
    List<String>? revealedIds,
    bool? hasSharedInvite,
  }) => $apply(
    FieldCopyWithData({
      if (matches != null) #matches: matches,
      if (revealedIds != null) #revealedIds: revealedIds,
      if (hasSharedInvite != null) #hasSharedInvite: hasSharedInvite,
    }),
  );
  @override
  CompatibilityState $make(CopyWithData data) => CompatibilityState(
    matches: data.get(#matches, or: $value.matches),
    revealedIds: data.get(#revealedIds, or: $value.revealedIds),
    hasSharedInvite: data.get(#hasSharedInvite, or: $value.hasSharedInvite),
  );

  @override
  CompatibilityStateCopyWith<$R2, CompatibilityState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CompatibilityStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

