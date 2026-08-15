// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sanctum_database.dart';

// ignore_for_file: type=lint
class $PracticeLogTable extends PracticeLog
    with TableInfo<$PracticeLogTable, PracticeLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    completedAt,
    durationSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PracticeLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
    );
  }

  @override
  $PracticeLogTable createAlias(String alias) {
    return $PracticeLogTable(attachedDatabase, alias);
  }
}

class PracticeLogRow extends DataClass implements Insertable<PracticeLogRow> {
  /// Row id.
  final int id;

  /// Catalogue id of the session practised.
  final String sessionId;

  /// When the session finished.
  final DateTime completedAt;

  /// How long was actually listened to, which is not always the full
  /// session — useful later for judging whether content is too long.
  final int durationSeconds;
  const PracticeLogRow({
    required this.id,
    required this.sessionId,
    required this.completedAt,
    required this.durationSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    return map;
  }

  PracticeLogCompanion toCompanion(bool nullToAbsent) {
    return PracticeLogCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      completedAt: Value(completedAt),
      durationSeconds: Value(durationSeconds),
    );
  }

  factory PracticeLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeLogRow(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
    };
  }

  PracticeLogRow copyWith({
    int? id,
    String? sessionId,
    DateTime? completedAt,
    int? durationSeconds,
  }) => PracticeLogRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    completedAt: completedAt ?? this.completedAt,
    durationSeconds: durationSeconds ?? this.durationSeconds,
  );
  PracticeLogRow copyWithCompanion(PracticeLogCompanion data) {
    return PracticeLogRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeLogRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('completedAt: $completedAt, ')
          ..write('durationSeconds: $durationSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, completedAt, durationSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeLogRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.completedAt == this.completedAt &&
          other.durationSeconds == this.durationSeconds);
}

class PracticeLogCompanion extends UpdateCompanion<PracticeLogRow> {
  final Value<int> id;
  final Value<String> sessionId;
  final Value<DateTime> completedAt;
  final Value<int> durationSeconds;
  const PracticeLogCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
  });
  PracticeLogCompanion.insert({
    this.id = const Value.absent(),
    required String sessionId,
    required DateTime completedAt,
    required int durationSeconds,
  }) : sessionId = Value(sessionId),
       completedAt = Value(completedAt),
       durationSeconds = Value(durationSeconds);
  static Insertable<PracticeLogRow> custom({
    Expression<int>? id,
    Expression<String>? sessionId,
    Expression<DateTime>? completedAt,
    Expression<int>? durationSeconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (completedAt != null) 'completed_at': completedAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    });
  }

  PracticeLogCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionId,
    Value<DateTime>? completedAt,
    Value<int>? durationSeconds,
  }) {
    return PracticeLogCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeLogCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('completedAt: $completedAt, ')
          ..write('durationSeconds: $durationSeconds')
          ..write(')'))
        .toString();
  }
}

class $JournalEntriesTable extends JournalEntries
    with TableInfo<$JournalEntriesTable, JournalEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<JournalKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<JournalKind>($JournalEntriesTable.$converterkind);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, kind, body, prompt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      kind: $JournalEntriesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      ),
    );
  }

  @override
  $JournalEntriesTable createAlias(String alias) {
    return $JournalEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<JournalKind, String, String> $converterkind =
      const EnumNameConverter<JournalKind>(JournalKind.values);
}

class JournalEntryRow extends DataClass implements Insertable<JournalEntryRow> {
  /// Row id.
  final int id;

  /// When it was written.
  final DateTime createdAt;

  /// The kind of writing, stored by enum *name* rather than index so
  /// that reordering the enum cannot silently rewrite history.
  final JournalKind kind;

  /// The user's words.
  final String body;

  /// The prompt shown, if any.
  final String? prompt;
  const JournalEntryRow({
    required this.id,
    required this.createdAt,
    required this.kind,
    required this.body,
    this.prompt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    {
      map['kind'] = Variable<String>(
        $JournalEntriesTable.$converterkind.toSql(kind),
      );
    }
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || prompt != null) {
      map['prompt'] = Variable<String>(prompt);
    }
    return map;
  }

  JournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return JournalEntriesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      kind: Value(kind),
      body: Value(body),
      prompt: prompt == null && nullToAbsent
          ? const Value.absent()
          : Value(prompt),
    );
  }

  factory JournalEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalEntryRow(
      id: serializer.fromJson<int>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      kind: $JournalEntriesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      body: serializer.fromJson<String>(json['body']),
      prompt: serializer.fromJson<String?>(json['prompt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'kind': serializer.toJson<String>(
        $JournalEntriesTable.$converterkind.toJson(kind),
      ),
      'body': serializer.toJson<String>(body),
      'prompt': serializer.toJson<String?>(prompt),
    };
  }

  JournalEntryRow copyWith({
    int? id,
    DateTime? createdAt,
    JournalKind? kind,
    String? body,
    Value<String?> prompt = const Value.absent(),
  }) => JournalEntryRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    kind: kind ?? this.kind,
    body: body ?? this.body,
    prompt: prompt.present ? prompt.value : this.prompt,
  );
  JournalEntryRow copyWithCompanion(JournalEntriesCompanion data) {
    return JournalEntryRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      body: data.body.present ? data.body.value : this.body,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntryRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('kind: $kind, ')
          ..write('body: $body, ')
          ..write('prompt: $prompt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, kind, body, prompt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalEntryRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.kind == this.kind &&
          other.body == this.body &&
          other.prompt == this.prompt);
}

class JournalEntriesCompanion extends UpdateCompanion<JournalEntryRow> {
  final Value<int> id;
  final Value<DateTime> createdAt;
  final Value<JournalKind> kind;
  final Value<String> body;
  final Value<String?> prompt;
  const JournalEntriesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.body = const Value.absent(),
    this.prompt = const Value.absent(),
  });
  JournalEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime createdAt,
    required JournalKind kind,
    required String body,
    this.prompt = const Value.absent(),
  }) : createdAt = Value(createdAt),
       kind = Value(kind),
       body = Value(body);
  static Insertable<JournalEntryRow> custom({
    Expression<int>? id,
    Expression<DateTime>? createdAt,
    Expression<String>? kind,
    Expression<String>? body,
    Expression<String>? prompt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (kind != null) 'kind': kind,
      if (body != null) 'body': body,
      if (prompt != null) 'prompt': prompt,
    });
  }

  JournalEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? createdAt,
    Value<JournalKind>? kind,
    Value<String>? body,
    Value<String?>? prompt,
  }) {
    return JournalEntriesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      kind: kind ?? this.kind,
      body: body ?? this.body,
      prompt: prompt ?? this.prompt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $JournalEntriesTable.$converterkind.toSql(kind.value),
      );
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('kind: $kind, ')
          ..write('body: $body, ')
          ..write('prompt: $prompt')
          ..write(')'))
        .toString();
  }
}

class $EnergyCheckInsTable extends EnergyCheckIns
    with TableInfo<$EnergyCheckInsTable, EnergyCheckInRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnergyCheckInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, recordedAt, level, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'energy_check_ins';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnergyCheckInRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnergyCheckInRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnergyCheckInRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $EnergyCheckInsTable createAlias(String alias) {
    return $EnergyCheckInsTable(attachedDatabase, alias);
  }
}

class EnergyCheckInRow extends DataClass
    implements Insertable<EnergyCheckInRow> {
  /// Row id.
  final int id;

  /// When it was recorded.
  final DateTime recordedAt;

  /// Ordinal 1–5. Stored as the number so it can be averaged and charted
  /// in SQL without a lookup.
  final int level;

  /// Optional free text.
  final String? note;
  const EnergyCheckInRow({
    required this.id,
    required this.recordedAt,
    required this.level,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['level'] = Variable<int>(level);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  EnergyCheckInsCompanion toCompanion(bool nullToAbsent) {
    return EnergyCheckInsCompanion(
      id: Value(id),
      recordedAt: Value(recordedAt),
      level: Value(level),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory EnergyCheckInRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnergyCheckInRow(
      id: serializer.fromJson<int>(json['id']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      level: serializer.fromJson<int>(json['level']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'level': serializer.toJson<int>(level),
      'note': serializer.toJson<String?>(note),
    };
  }

  EnergyCheckInRow copyWith({
    int? id,
    DateTime? recordedAt,
    int? level,
    Value<String?> note = const Value.absent(),
  }) => EnergyCheckInRow(
    id: id ?? this.id,
    recordedAt: recordedAt ?? this.recordedAt,
    level: level ?? this.level,
    note: note.present ? note.value : this.note,
  );
  EnergyCheckInRow copyWithCompanion(EnergyCheckInsCompanion data) {
    return EnergyCheckInRow(
      id: data.id.present ? data.id.value : this.id,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      level: data.level.present ? data.level.value : this.level,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnergyCheckInRow(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('level: $level, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, recordedAt, level, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnergyCheckInRow &&
          other.id == this.id &&
          other.recordedAt == this.recordedAt &&
          other.level == this.level &&
          other.note == this.note);
}

class EnergyCheckInsCompanion extends UpdateCompanion<EnergyCheckInRow> {
  final Value<int> id;
  final Value<DateTime> recordedAt;
  final Value<int> level;
  final Value<String?> note;
  const EnergyCheckInsCompanion({
    this.id = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.level = const Value.absent(),
    this.note = const Value.absent(),
  });
  EnergyCheckInsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime recordedAt,
    required int level,
    this.note = const Value.absent(),
  }) : recordedAt = Value(recordedAt),
       level = Value(level);
  static Insertable<EnergyCheckInRow> custom({
    Expression<int>? id,
    Expression<DateTime>? recordedAt,
    Expression<int>? level,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (level != null) 'level': level,
      if (note != null) 'note': note,
    });
  }

  EnergyCheckInsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? recordedAt,
    Value<int>? level,
    Value<String?>? note,
  }) {
    return EnergyCheckInsCompanion(
      id: id ?? this.id,
      recordedAt: recordedAt ?? this.recordedAt,
      level: level ?? this.level,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnergyCheckInsCompanion(')
          ..write('id: $id, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('level: $level, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $OracleDrawsTable extends OracleDraws
    with TableInfo<$OracleDrawsTable, OracleDrawRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OracleDrawsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _drawnOnMeta = const VerificationMeta(
    'drawnOn',
  );
  @override
  late final GeneratedColumn<DateTime> drawnOn = GeneratedColumn<DateTime>(
    'drawn_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revealedMeta = const VerificationMeta(
    'revealed',
  );
  @override
  late final GeneratedColumn<bool> revealed = GeneratedColumn<bool>(
    'revealed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("revealed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, cardId, drawnOn, revealed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'oracle_draws';
  @override
  VerificationContext validateIntegrity(
    Insertable<OracleDrawRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('drawn_on')) {
      context.handle(
        _drawnOnMeta,
        drawnOn.isAcceptableOrUnknown(data['drawn_on']!, _drawnOnMeta),
      );
    } else if (isInserting) {
      context.missing(_drawnOnMeta);
    }
    if (data.containsKey('revealed')) {
      context.handle(
        _revealedMeta,
        revealed.isAcceptableOrUnknown(data['revealed']!, _revealedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OracleDrawRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OracleDrawRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      drawnOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}drawn_on'],
      )!,
      revealed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}revealed'],
      )!,
    );
  }

  @override
  $OracleDrawsTable createAlias(String alias) {
    return $OracleDrawsTable(attachedDatabase, alias);
  }
}

class OracleDrawRow extends DataClass implements Insertable<OracleDrawRow> {
  /// Row id.
  final int id;

  /// Catalogue id of the card.
  final String cardId;

  /// The local date the card belongs to, time stripped.
  final DateTime drawnOn;

  /// Whether the user has flipped it yet. A card is *assigned* at
  /// midnight but only *revealed* when tapped, and the difference is the
  /// entire ceremony of the feature.
  final bool revealed;
  const OracleDrawRow({
    required this.id,
    required this.cardId,
    required this.drawnOn,
    required this.revealed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<String>(cardId);
    map['drawn_on'] = Variable<DateTime>(drawnOn);
    map['revealed'] = Variable<bool>(revealed);
    return map;
  }

  OracleDrawsCompanion toCompanion(bool nullToAbsent) {
    return OracleDrawsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      drawnOn: Value(drawnOn),
      revealed: Value(revealed),
    );
  }

  factory OracleDrawRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OracleDrawRow(
      id: serializer.fromJson<int>(json['id']),
      cardId: serializer.fromJson<String>(json['cardId']),
      drawnOn: serializer.fromJson<DateTime>(json['drawnOn']),
      revealed: serializer.fromJson<bool>(json['revealed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardId': serializer.toJson<String>(cardId),
      'drawnOn': serializer.toJson<DateTime>(drawnOn),
      'revealed': serializer.toJson<bool>(revealed),
    };
  }

  OracleDrawRow copyWith({
    int? id,
    String? cardId,
    DateTime? drawnOn,
    bool? revealed,
  }) => OracleDrawRow(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    drawnOn: drawnOn ?? this.drawnOn,
    revealed: revealed ?? this.revealed,
  );
  OracleDrawRow copyWithCompanion(OracleDrawsCompanion data) {
    return OracleDrawRow(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      drawnOn: data.drawnOn.present ? data.drawnOn.value : this.drawnOn,
      revealed: data.revealed.present ? data.revealed.value : this.revealed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OracleDrawRow(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('drawnOn: $drawnOn, ')
          ..write('revealed: $revealed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, cardId, drawnOn, revealed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OracleDrawRow &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.drawnOn == this.drawnOn &&
          other.revealed == this.revealed);
}

class OracleDrawsCompanion extends UpdateCompanion<OracleDrawRow> {
  final Value<int> id;
  final Value<String> cardId;
  final Value<DateTime> drawnOn;
  final Value<bool> revealed;
  const OracleDrawsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.drawnOn = const Value.absent(),
    this.revealed = const Value.absent(),
  });
  OracleDrawsCompanion.insert({
    this.id = const Value.absent(),
    required String cardId,
    required DateTime drawnOn,
    this.revealed = const Value.absent(),
  }) : cardId = Value(cardId),
       drawnOn = Value(drawnOn);
  static Insertable<OracleDrawRow> custom({
    Expression<int>? id,
    Expression<String>? cardId,
    Expression<DateTime>? drawnOn,
    Expression<bool>? revealed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (drawnOn != null) 'drawn_on': drawnOn,
      if (revealed != null) 'revealed': revealed,
    });
  }

  OracleDrawsCompanion copyWith({
    Value<int>? id,
    Value<String>? cardId,
    Value<DateTime>? drawnOn,
    Value<bool>? revealed,
  }) {
    return OracleDrawsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      drawnOn: drawnOn ?? this.drawnOn,
      revealed: revealed ?? this.revealed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (drawnOn.present) {
      map['drawn_on'] = Variable<DateTime>(drawnOn.value);
    }
    if (revealed.present) {
      map['revealed'] = Variable<bool>(revealed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OracleDrawsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('drawnOn: $drawnOn, ')
          ..write('revealed: $revealed')
          ..write(')'))
        .toString();
  }
}

abstract class _$SanctumDatabase extends GeneratedDatabase {
  _$SanctumDatabase(QueryExecutor e) : super(e);
  $SanctumDatabaseManager get managers => $SanctumDatabaseManager(this);
  late final $PracticeLogTable practiceLog = $PracticeLogTable(this);
  late final $JournalEntriesTable journalEntries = $JournalEntriesTable(this);
  late final $EnergyCheckInsTable energyCheckIns = $EnergyCheckInsTable(this);
  late final $OracleDrawsTable oracleDraws = $OracleDrawsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    practiceLog,
    journalEntries,
    energyCheckIns,
    oracleDraws,
  ];
}

typedef $$PracticeLogTableCreateCompanionBuilder =
    PracticeLogCompanion Function({
      Value<int> id,
      required String sessionId,
      required DateTime completedAt,
      required int durationSeconds,
    });
typedef $$PracticeLogTableUpdateCompanionBuilder =
    PracticeLogCompanion Function({
      Value<int> id,
      Value<String> sessionId,
      Value<DateTime> completedAt,
      Value<int> durationSeconds,
    });

class $$PracticeLogTableFilterComposer
    extends Composer<_$SanctumDatabase, $PracticeLogTable> {
  $$PracticeLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PracticeLogTableOrderingComposer
    extends Composer<_$SanctumDatabase, $PracticeLogTable> {
  $$PracticeLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PracticeLogTableAnnotationComposer
    extends Composer<_$SanctumDatabase, $PracticeLogTable> {
  $$PracticeLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );
}

class $$PracticeLogTableTableManager
    extends
        RootTableManager<
          _$SanctumDatabase,
          $PracticeLogTable,
          PracticeLogRow,
          $$PracticeLogTableFilterComposer,
          $$PracticeLogTableOrderingComposer,
          $$PracticeLogTableAnnotationComposer,
          $$PracticeLogTableCreateCompanionBuilder,
          $$PracticeLogTableUpdateCompanionBuilder,
          (
            PracticeLogRow,
            BaseReferences<
              _$SanctumDatabase,
              $PracticeLogTable,
              PracticeLogRow
            >,
          ),
          PracticeLogRow,
          PrefetchHooks Function()
        > {
  $$PracticeLogTableTableManager(_$SanctumDatabase db, $PracticeLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PracticeLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PracticeLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
              }) => PracticeLogCompanion(
                id: id,
                sessionId: sessionId,
                completedAt: completedAt,
                durationSeconds: durationSeconds,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionId,
                required DateTime completedAt,
                required int durationSeconds,
              }) => PracticeLogCompanion.insert(
                id: id,
                sessionId: sessionId,
                completedAt: completedAt,
                durationSeconds: durationSeconds,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PracticeLogTableProcessedTableManager =
    ProcessedTableManager<
      _$SanctumDatabase,
      $PracticeLogTable,
      PracticeLogRow,
      $$PracticeLogTableFilterComposer,
      $$PracticeLogTableOrderingComposer,
      $$PracticeLogTableAnnotationComposer,
      $$PracticeLogTableCreateCompanionBuilder,
      $$PracticeLogTableUpdateCompanionBuilder,
      (
        PracticeLogRow,
        BaseReferences<_$SanctumDatabase, $PracticeLogTable, PracticeLogRow>,
      ),
      PracticeLogRow,
      PrefetchHooks Function()
    >;
typedef $$JournalEntriesTableCreateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<int> id,
      required DateTime createdAt,
      required JournalKind kind,
      required String body,
      Value<String?> prompt,
    });
typedef $$JournalEntriesTableUpdateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> createdAt,
      Value<JournalKind> kind,
      Value<String> body,
      Value<String?> prompt,
    });

class $$JournalEntriesTableFilterComposer
    extends Composer<_$SanctumDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<JournalKind, JournalKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalEntriesTableOrderingComposer
    extends Composer<_$SanctumDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalEntriesTableAnnotationComposer
    extends Composer<_$SanctumDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<JournalKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);
}

class $$JournalEntriesTableTableManager
    extends
        RootTableManager<
          _$SanctumDatabase,
          $JournalEntriesTable,
          JournalEntryRow,
          $$JournalEntriesTableFilterComposer,
          $$JournalEntriesTableOrderingComposer,
          $$JournalEntriesTableAnnotationComposer,
          $$JournalEntriesTableCreateCompanionBuilder,
          $$JournalEntriesTableUpdateCompanionBuilder,
          (
            JournalEntryRow,
            BaseReferences<
              _$SanctumDatabase,
              $JournalEntriesTable,
              JournalEntryRow
            >,
          ),
          JournalEntryRow,
          PrefetchHooks Function()
        > {
  $$JournalEntriesTableTableManager(
    _$SanctumDatabase db,
    $JournalEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<JournalKind> kind = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> prompt = const Value.absent(),
              }) => JournalEntriesCompanion(
                id: id,
                createdAt: createdAt,
                kind: kind,
                body: body,
                prompt: prompt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime createdAt,
                required JournalKind kind,
                required String body,
                Value<String?> prompt = const Value.absent(),
              }) => JournalEntriesCompanion.insert(
                id: id,
                createdAt: createdAt,
                kind: kind,
                body: body,
                prompt: prompt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$SanctumDatabase,
      $JournalEntriesTable,
      JournalEntryRow,
      $$JournalEntriesTableFilterComposer,
      $$JournalEntriesTableOrderingComposer,
      $$JournalEntriesTableAnnotationComposer,
      $$JournalEntriesTableCreateCompanionBuilder,
      $$JournalEntriesTableUpdateCompanionBuilder,
      (
        JournalEntryRow,
        BaseReferences<
          _$SanctumDatabase,
          $JournalEntriesTable,
          JournalEntryRow
        >,
      ),
      JournalEntryRow,
      PrefetchHooks Function()
    >;
typedef $$EnergyCheckInsTableCreateCompanionBuilder =
    EnergyCheckInsCompanion Function({
      Value<int> id,
      required DateTime recordedAt,
      required int level,
      Value<String?> note,
    });
typedef $$EnergyCheckInsTableUpdateCompanionBuilder =
    EnergyCheckInsCompanion Function({
      Value<int> id,
      Value<DateTime> recordedAt,
      Value<int> level,
      Value<String?> note,
    });

class $$EnergyCheckInsTableFilterComposer
    extends Composer<_$SanctumDatabase, $EnergyCheckInsTable> {
  $$EnergyCheckInsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnergyCheckInsTableOrderingComposer
    extends Composer<_$SanctumDatabase, $EnergyCheckInsTable> {
  $$EnergyCheckInsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnergyCheckInsTableAnnotationComposer
    extends Composer<_$SanctumDatabase, $EnergyCheckInsTable> {
  $$EnergyCheckInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$EnergyCheckInsTableTableManager
    extends
        RootTableManager<
          _$SanctumDatabase,
          $EnergyCheckInsTable,
          EnergyCheckInRow,
          $$EnergyCheckInsTableFilterComposer,
          $$EnergyCheckInsTableOrderingComposer,
          $$EnergyCheckInsTableAnnotationComposer,
          $$EnergyCheckInsTableCreateCompanionBuilder,
          $$EnergyCheckInsTableUpdateCompanionBuilder,
          (
            EnergyCheckInRow,
            BaseReferences<
              _$SanctumDatabase,
              $EnergyCheckInsTable,
              EnergyCheckInRow
            >,
          ),
          EnergyCheckInRow,
          PrefetchHooks Function()
        > {
  $$EnergyCheckInsTableTableManager(
    _$SanctumDatabase db,
    $EnergyCheckInsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnergyCheckInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnergyCheckInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnergyCheckInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => EnergyCheckInsCompanion(
                id: id,
                recordedAt: recordedAt,
                level: level,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime recordedAt,
                required int level,
                Value<String?> note = const Value.absent(),
              }) => EnergyCheckInsCompanion.insert(
                id: id,
                recordedAt: recordedAt,
                level: level,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnergyCheckInsTableProcessedTableManager =
    ProcessedTableManager<
      _$SanctumDatabase,
      $EnergyCheckInsTable,
      EnergyCheckInRow,
      $$EnergyCheckInsTableFilterComposer,
      $$EnergyCheckInsTableOrderingComposer,
      $$EnergyCheckInsTableAnnotationComposer,
      $$EnergyCheckInsTableCreateCompanionBuilder,
      $$EnergyCheckInsTableUpdateCompanionBuilder,
      (
        EnergyCheckInRow,
        BaseReferences<
          _$SanctumDatabase,
          $EnergyCheckInsTable,
          EnergyCheckInRow
        >,
      ),
      EnergyCheckInRow,
      PrefetchHooks Function()
    >;
typedef $$OracleDrawsTableCreateCompanionBuilder =
    OracleDrawsCompanion Function({
      Value<int> id,
      required String cardId,
      required DateTime drawnOn,
      Value<bool> revealed,
    });
typedef $$OracleDrawsTableUpdateCompanionBuilder =
    OracleDrawsCompanion Function({
      Value<int> id,
      Value<String> cardId,
      Value<DateTime> drawnOn,
      Value<bool> revealed,
    });

class $$OracleDrawsTableFilterComposer
    extends Composer<_$SanctumDatabase, $OracleDrawsTable> {
  $$OracleDrawsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get drawnOn => $composableBuilder(
    column: $table.drawnOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get revealed => $composableBuilder(
    column: $table.revealed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OracleDrawsTableOrderingComposer
    extends Composer<_$SanctumDatabase, $OracleDrawsTable> {
  $$OracleDrawsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get drawnOn => $composableBuilder(
    column: $table.drawnOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get revealed => $composableBuilder(
    column: $table.revealed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OracleDrawsTableAnnotationComposer
    extends Composer<_$SanctumDatabase, $OracleDrawsTable> {
  $$OracleDrawsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<DateTime> get drawnOn =>
      $composableBuilder(column: $table.drawnOn, builder: (column) => column);

  GeneratedColumn<bool> get revealed =>
      $composableBuilder(column: $table.revealed, builder: (column) => column);
}

class $$OracleDrawsTableTableManager
    extends
        RootTableManager<
          _$SanctumDatabase,
          $OracleDrawsTable,
          OracleDrawRow,
          $$OracleDrawsTableFilterComposer,
          $$OracleDrawsTableOrderingComposer,
          $$OracleDrawsTableAnnotationComposer,
          $$OracleDrawsTableCreateCompanionBuilder,
          $$OracleDrawsTableUpdateCompanionBuilder,
          (
            OracleDrawRow,
            BaseReferences<_$SanctumDatabase, $OracleDrawsTable, OracleDrawRow>,
          ),
          OracleDrawRow,
          PrefetchHooks Function()
        > {
  $$OracleDrawsTableTableManager(_$SanctumDatabase db, $OracleDrawsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OracleDrawsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OracleDrawsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OracleDrawsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> cardId = const Value.absent(),
                Value<DateTime> drawnOn = const Value.absent(),
                Value<bool> revealed = const Value.absent(),
              }) => OracleDrawsCompanion(
                id: id,
                cardId: cardId,
                drawnOn: drawnOn,
                revealed: revealed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String cardId,
                required DateTime drawnOn,
                Value<bool> revealed = const Value.absent(),
              }) => OracleDrawsCompanion.insert(
                id: id,
                cardId: cardId,
                drawnOn: drawnOn,
                revealed: revealed,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OracleDrawsTableProcessedTableManager =
    ProcessedTableManager<
      _$SanctumDatabase,
      $OracleDrawsTable,
      OracleDrawRow,
      $$OracleDrawsTableFilterComposer,
      $$OracleDrawsTableOrderingComposer,
      $$OracleDrawsTableAnnotationComposer,
      $$OracleDrawsTableCreateCompanionBuilder,
      $$OracleDrawsTableUpdateCompanionBuilder,
      (
        OracleDrawRow,
        BaseReferences<_$SanctumDatabase, $OracleDrawsTable, OracleDrawRow>,
      ),
      OracleDrawRow,
      PrefetchHooks Function()
    >;

class $SanctumDatabaseManager {
  final _$SanctumDatabase _db;
  $SanctumDatabaseManager(this._db);
  $$PracticeLogTableTableManager get practiceLog =>
      $$PracticeLogTableTableManager(_db, _db.practiceLog);
  $$JournalEntriesTableTableManager get journalEntries =>
      $$JournalEntriesTableTableManager(_db, _db.journalEntries);
  $$EnergyCheckInsTableTableManager get energyCheckIns =>
      $$EnergyCheckInsTableTableManager(_db, _db.energyCheckIns);
  $$OracleDrawsTableTableManager get oracleDraws =>
      $$OracleDrawsTableTableManager(_db, _db.oracleDraws);
}
