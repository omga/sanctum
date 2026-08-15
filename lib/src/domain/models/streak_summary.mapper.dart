// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'streak_summary.dart';

class StreakSummaryMapper extends ClassMapperBase<StreakSummary> {
  StreakSummaryMapper._();

  static StreakSummaryMapper? _instance;
  static StreakSummaryMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = StreakSummaryMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'StreakSummary';

  static int _$current(StreakSummary v) => v.current;
  static const Field<StreakSummary, int> _f$current = Field(
    'current',
    _$current,
  );
  static int _$longest(StreakSummary v) => v.longest;
  static const Field<StreakSummary, int> _f$longest = Field(
    'longest',
    _$longest,
  );
  static bool _$completedToday(StreakSummary v) => v.completedToday;
  static const Field<StreakSummary, bool> _f$completedToday = Field(
    'completedToday',
    _$completedToday,
  );
  static DateTime? _$lastActiveDate(StreakSummary v) => v.lastActiveDate;
  static const Field<StreakSummary, DateTime> _f$lastActiveDate = Field(
    'lastActiveDate',
    _$lastActiveDate,
    opt: true,
  );

  @override
  final MappableFields<StreakSummary> fields = const {
    #current: _f$current,
    #longest: _f$longest,
    #completedToday: _f$completedToday,
    #lastActiveDate: _f$lastActiveDate,
  };

  static StreakSummary _instantiate(DecodingData data) {
    return StreakSummary(
      current: data.dec(_f$current),
      longest: data.dec(_f$longest),
      completedToday: data.dec(_f$completedToday),
      lastActiveDate: data.dec(_f$lastActiveDate),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static StreakSummary fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<StreakSummary>(map);
  }

  static StreakSummary fromJson(String json) {
    return ensureInitialized().decodeJson<StreakSummary>(json);
  }
}

mixin StreakSummaryMappable {
  String toJson() {
    return StreakSummaryMapper.ensureInitialized().encodeJson<StreakSummary>(
      this as StreakSummary,
    );
  }

  Map<String, dynamic> toMap() {
    return StreakSummaryMapper.ensureInitialized().encodeMap<StreakSummary>(
      this as StreakSummary,
    );
  }

  StreakSummaryCopyWith<StreakSummary, StreakSummary, StreakSummary>
  get copyWith => _StreakSummaryCopyWithImpl<StreakSummary, StreakSummary>(
    this as StreakSummary,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return StreakSummaryMapper.ensureInitialized().stringifyValue(
      this as StreakSummary,
    );
  }

  @override
  bool operator ==(Object other) {
    return StreakSummaryMapper.ensureInitialized().equalsValue(
      this as StreakSummary,
      other,
    );
  }

  @override
  int get hashCode {
    return StreakSummaryMapper.ensureInitialized().hashValue(
      this as StreakSummary,
    );
  }
}

extension StreakSummaryValueCopy<$R, $Out>
    on ObjectCopyWith<$R, StreakSummary, $Out> {
  StreakSummaryCopyWith<$R, StreakSummary, $Out> get $asStreakSummary =>
      $base.as((v, t, t2) => _StreakSummaryCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class StreakSummaryCopyWith<$R, $In extends StreakSummary, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    int? current,
    int? longest,
    bool? completedToday,
    DateTime? lastActiveDate,
  });
  StreakSummaryCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _StreakSummaryCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, StreakSummary, $Out>
    implements StreakSummaryCopyWith<$R, StreakSummary, $Out> {
  _StreakSummaryCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<StreakSummary> $mapper =
      StreakSummaryMapper.ensureInitialized();
  @override
  $R call({
    int? current,
    int? longest,
    bool? completedToday,
    Object? lastActiveDate = $none,
  }) => $apply(
    FieldCopyWithData({
      if (current != null) #current: current,
      if (longest != null) #longest: longest,
      if (completedToday != null) #completedToday: completedToday,
      if (lastActiveDate != $none) #lastActiveDate: lastActiveDate,
    }),
  );
  @override
  StreakSummary $make(CopyWithData data) => StreakSummary(
    current: data.get(#current, or: $value.current),
    longest: data.get(#longest, or: $value.longest),
    completedToday: data.get(#completedToday, or: $value.completedToday),
    lastActiveDate: data.get(#lastActiveDate, or: $value.lastActiveDate),
  );

  @override
  StreakSummaryCopyWith<$R2, StreakSummary, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _StreakSummaryCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

