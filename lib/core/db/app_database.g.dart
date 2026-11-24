// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $HabitsTable extends Habits with TableInfo<$HabitsTable, HabitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _reminderHourMeta = const VerificationMeta(
    'reminderHour',
  );
  @override
  late final GeneratedColumn<int> reminderHour = GeneratedColumn<int>(
    'reminder_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(8),
  );
  static const VerificationMeta _reminderMinuteMeta = const VerificationMeta(
    'reminderMinute',
  );
  @override
  late final GeneratedColumn<int> reminderMinute = GeneratedColumn<int>(
    'reminder_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  reminderTimes = GeneratedColumn<String>(
    'reminder_times',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<List<String>>($HabitsTable.$converterreminderTimes);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  oneTimeReminders = GeneratedColumn<String>(
    'one_time_reminders',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<List<String>>($HabitsTable.$converteroneTimeReminders);
  static const VerificationMeta _streakMeta = const VerificationMeta('streak');
  @override
  late final GeneratedColumn<int> streak = GeneratedColumn<int>(
    'streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastCompletedAtMeta = const VerificationMeta(
    'lastCompletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastCompletedAt =
      GeneratedColumn<DateTime>(
        'last_completed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    enabled,
    reminderHour,
    reminderMinute,
    reminderTimes,
    oneTimeReminders,
    streak,
    lastCompletedAt,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('reminder_hour')) {
      context.handle(
        _reminderHourMeta,
        reminderHour.isAcceptableOrUnknown(
          data['reminder_hour']!,
          _reminderHourMeta,
        ),
      );
    }
    if (data.containsKey('reminder_minute')) {
      context.handle(
        _reminderMinuteMeta,
        reminderMinute.isAcceptableOrUnknown(
          data['reminder_minute']!,
          _reminderMinuteMeta,
        ),
      );
    }
    if (data.containsKey('streak')) {
      context.handle(
        _streakMeta,
        streak.isAcceptableOrUnknown(data['streak']!, _streakMeta),
      );
    }
    if (data.containsKey('last_completed_at')) {
      context.handle(
        _lastCompletedAtMeta,
        lastCompletedAt.isAcceptableOrUnknown(
          data['last_completed_at']!,
          _lastCompletedAtMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      category:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}category'],
          )!,
      enabled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}enabled'],
          )!,
      reminderHour:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}reminder_hour'],
          )!,
      reminderMinute:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}reminder_minute'],
          )!,
      reminderTimes: $HabitsTable.$converterreminderTimes.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}reminder_times'],
        )!,
      ),
      oneTimeReminders: $HabitsTable.$converteroneTimeReminders.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}one_time_reminders'],
        )!,
      ),
      streak:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}streak'],
          )!,
      lastCompletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_completed_at'],
      ),
      sortOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sort_order'],
          )!,
      archived:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}archived'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterreminderTimes =
      const StringListConverter();
  static TypeConverter<List<String>, String> $converteroneTimeReminders =
      const StringListConverter();
}

class HabitRow extends DataClass implements Insertable<HabitRow> {
  final String id;
  final String name;

  /// HabitCategory.name: generic | medicine | water | meditation | reading | exercise
  final String category;
  final bool enabled;
  final int reminderHour;
  final int reminderMinute;

  /// Daily reminder times as "HH:mm".
  final List<String> reminderTimes;

  /// One-time reminders as ISO-8601 local date-times.
  final List<String> oneTimeReminders;
  final int streak;
  final DateTime? lastCompletedAt;
  final int sortOrder;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HabitRow({
    required this.id,
    required this.name,
    required this.category,
    required this.enabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.reminderTimes,
    required this.oneTimeReminders,
    required this.streak,
    this.lastCompletedAt,
    required this.sortOrder,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['enabled'] = Variable<bool>(enabled);
    map['reminder_hour'] = Variable<int>(reminderHour);
    map['reminder_minute'] = Variable<int>(reminderMinute);
    {
      map['reminder_times'] = Variable<String>(
        $HabitsTable.$converterreminderTimes.toSql(reminderTimes),
      );
    }
    {
      map['one_time_reminders'] = Variable<String>(
        $HabitsTable.$converteroneTimeReminders.toSql(oneTimeReminders),
      );
    }
    map['streak'] = Variable<int>(streak);
    if (!nullToAbsent || lastCompletedAt != null) {
      map['last_completed_at'] = Variable<DateTime>(lastCompletedAt);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      enabled: Value(enabled),
      reminderHour: Value(reminderHour),
      reminderMinute: Value(reminderMinute),
      reminderTimes: Value(reminderTimes),
      oneTimeReminders: Value(oneTimeReminders),
      streak: Value(streak),
      lastCompletedAt:
          lastCompletedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(lastCompletedAt),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HabitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      reminderHour: serializer.fromJson<int>(json['reminderHour']),
      reminderMinute: serializer.fromJson<int>(json['reminderMinute']),
      reminderTimes: serializer.fromJson<List<String>>(json['reminderTimes']),
      oneTimeReminders: serializer.fromJson<List<String>>(
        json['oneTimeReminders'],
      ),
      streak: serializer.fromJson<int>(json['streak']),
      lastCompletedAt: serializer.fromJson<DateTime?>(json['lastCompletedAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'enabled': serializer.toJson<bool>(enabled),
      'reminderHour': serializer.toJson<int>(reminderHour),
      'reminderMinute': serializer.toJson<int>(reminderMinute),
      'reminderTimes': serializer.toJson<List<String>>(reminderTimes),
      'oneTimeReminders': serializer.toJson<List<String>>(oneTimeReminders),
      'streak': serializer.toJson<int>(streak),
      'lastCompletedAt': serializer.toJson<DateTime?>(lastCompletedAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HabitRow copyWith({
    String? id,
    String? name,
    String? category,
    bool? enabled,
    int? reminderHour,
    int? reminderMinute,
    List<String>? reminderTimes,
    List<String>? oneTimeReminders,
    int? streak,
    Value<DateTime?> lastCompletedAt = const Value.absent(),
    int? sortOrder,
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => HabitRow(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    enabled: enabled ?? this.enabled,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    reminderTimes: reminderTimes ?? this.reminderTimes,
    oneTimeReminders: oneTimeReminders ?? this.oneTimeReminders,
    streak: streak ?? this.streak,
    lastCompletedAt:
        lastCompletedAt.present ? lastCompletedAt.value : this.lastCompletedAt,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HabitRow copyWithCompanion(HabitsCompanion data) {
    return HabitRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      reminderHour:
          data.reminderHour.present
              ? data.reminderHour.value
              : this.reminderHour,
      reminderMinute:
          data.reminderMinute.present
              ? data.reminderMinute.value
              : this.reminderMinute,
      reminderTimes:
          data.reminderTimes.present
              ? data.reminderTimes.value
              : this.reminderTimes,
      oneTimeReminders:
          data.oneTimeReminders.present
              ? data.oneTimeReminders.value
              : this.oneTimeReminders,
      streak: data.streak.present ? data.streak.value : this.streak,
      lastCompletedAt:
          data.lastCompletedAt.present
              ? data.lastCompletedAt.value
              : this.lastCompletedAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('enabled: $enabled, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('reminderTimes: $reminderTimes, ')
          ..write('oneTimeReminders: $oneTimeReminders, ')
          ..write('streak: $streak, ')
          ..write('lastCompletedAt: $lastCompletedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    enabled,
    reminderHour,
    reminderMinute,
    reminderTimes,
    oneTimeReminders,
    streak,
    lastCompletedAt,
    sortOrder,
    archived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.enabled == this.enabled &&
          other.reminderHour == this.reminderHour &&
          other.reminderMinute == this.reminderMinute &&
          other.reminderTimes == this.reminderTimes &&
          other.oneTimeReminders == this.oneTimeReminders &&
          other.streak == this.streak &&
          other.lastCompletedAt == this.lastCompletedAt &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HabitsCompanion extends UpdateCompanion<HabitRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<bool> enabled;
  final Value<int> reminderHour;
  final Value<int> reminderMinute;
  final Value<List<String>> reminderTimes;
  final Value<List<String>> oneTimeReminders;
  final Value<int> streak;
  final Value<DateTime?> lastCompletedAt;
  final Value<int> sortOrder;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.enabled = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.reminderTimes = const Value.absent(),
    this.oneTimeReminders = const Value.absent(),
    this.streak = const Value.absent(),
    this.lastCompletedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitsCompanion.insert({
    required String id,
    required String name,
    required String category,
    this.enabled = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.reminderTimes = const Value.absent(),
    this.oneTimeReminders = const Value.absent(),
    this.streak = const Value.absent(),
    this.lastCompletedAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       category = Value(category),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<HabitRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<bool>? enabled,
    Expression<int>? reminderHour,
    Expression<int>? reminderMinute,
    Expression<String>? reminderTimes,
    Expression<String>? oneTimeReminders,
    Expression<int>? streak,
    Expression<DateTime>? lastCompletedAt,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (enabled != null) 'enabled': enabled,
      if (reminderHour != null) 'reminder_hour': reminderHour,
      if (reminderMinute != null) 'reminder_minute': reminderMinute,
      if (reminderTimes != null) 'reminder_times': reminderTimes,
      if (oneTimeReminders != null) 'one_time_reminders': oneTimeReminders,
      if (streak != null) 'streak': streak,
      if (lastCompletedAt != null) 'last_completed_at': lastCompletedAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? category,
    Value<bool>? enabled,
    Value<int>? reminderHour,
    Value<int>? reminderMinute,
    Value<List<String>>? reminderTimes,
    Value<List<String>>? oneTimeReminders,
    Value<int>? streak,
    Value<DateTime?>? lastCompletedAt,
    Value<int>? sortOrder,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      enabled: enabled ?? this.enabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      oneTimeReminders: oneTimeReminders ?? this.oneTimeReminders,
      streak: streak ?? this.streak,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (reminderHour.present) {
      map['reminder_hour'] = Variable<int>(reminderHour.value);
    }
    if (reminderMinute.present) {
      map['reminder_minute'] = Variable<int>(reminderMinute.value);
    }
    if (reminderTimes.present) {
      map['reminder_times'] = Variable<String>(
        $HabitsTable.$converterreminderTimes.toSql(reminderTimes.value),
      );
    }
    if (oneTimeReminders.present) {
      map['one_time_reminders'] = Variable<String>(
        $HabitsTable.$converteroneTimeReminders.toSql(oneTimeReminders.value),
      );
    }
    if (streak.present) {
      map['streak'] = Variable<int>(streak.value);
    }
    if (lastCompletedAt.present) {
      map['last_completed_at'] = Variable<DateTime>(lastCompletedAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('enabled: $enabled, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('reminderTimes: $reminderTimes, ')
          ..write('oneTimeReminders: $oneTimeReminders, ')
          ..write('streak: $streak, ')
          ..write('lastCompletedAt: $lastCompletedAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicineDetailsTable extends MedicineDetails
    with TableInfo<$MedicineDetailsTable, MedicineDetailsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicineDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _medicineNameMeta = const VerificationMeta(
    'medicineName',
  );
  @override
  late final GeneratedColumn<String> medicineName = GeneratedColumn<String>(
    'medicine_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doseMeta = const VerificationMeta('dose');
  @override
  late final GeneratedColumn<String> dose = GeneratedColumn<String>(
    'dose',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    habitId,
    medicineName,
    dose,
    notes,
    startDate,
    endDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medicine_details';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicineDetailsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('medicine_name')) {
      context.handle(
        _medicineNameMeta,
        medicineName.isAcceptableOrUnknown(
          data['medicine_name']!,
          _medicineNameMeta,
        ),
      );
    }
    if (data.containsKey('dose')) {
      context.handle(
        _doseMeta,
        dose.isAcceptableOrUnknown(data['dose']!, _doseMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {habitId};
  @override
  MedicineDetailsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicineDetailsRow(
      habitId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}habit_id'],
          )!,
      medicineName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medicine_name'],
      ),
      dose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dose'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
    );
  }

  @override
  $MedicineDetailsTable createAlias(String alias) {
    return $MedicineDetailsTable(attachedDatabase, alias);
  }
}

class MedicineDetailsRow extends DataClass
    implements Insertable<MedicineDetailsRow> {
  final String habitId;
  final String? medicineName;
  final String? dose;
  final String? notes;

  /// "YYYY-MM-DD" (local calendar date).
  final String? startDate;
  final String? endDate;
  const MedicineDetailsRow({
    required this.habitId,
    this.medicineName,
    this.dose,
    this.notes,
    this.startDate,
    this.endDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['habit_id'] = Variable<String>(habitId);
    if (!nullToAbsent || medicineName != null) {
      map['medicine_name'] = Variable<String>(medicineName);
    }
    if (!nullToAbsent || dose != null) {
      map['dose'] = Variable<String>(dose);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<String>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    return map;
  }

  MedicineDetailsCompanion toCompanion(bool nullToAbsent) {
    return MedicineDetailsCompanion(
      habitId: Value(habitId),
      medicineName:
          medicineName == null && nullToAbsent
              ? const Value.absent()
              : Value(medicineName),
      dose: dose == null && nullToAbsent ? const Value.absent() : Value(dose),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      startDate:
          startDate == null && nullToAbsent
              ? const Value.absent()
              : Value(startDate),
      endDate:
          endDate == null && nullToAbsent
              ? const Value.absent()
              : Value(endDate),
    );
  }

  factory MedicineDetailsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicineDetailsRow(
      habitId: serializer.fromJson<String>(json['habitId']),
      medicineName: serializer.fromJson<String?>(json['medicineName']),
      dose: serializer.fromJson<String?>(json['dose']),
      notes: serializer.fromJson<String?>(json['notes']),
      startDate: serializer.fromJson<String?>(json['startDate']),
      endDate: serializer.fromJson<String?>(json['endDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'habitId': serializer.toJson<String>(habitId),
      'medicineName': serializer.toJson<String?>(medicineName),
      'dose': serializer.toJson<String?>(dose),
      'notes': serializer.toJson<String?>(notes),
      'startDate': serializer.toJson<String?>(startDate),
      'endDate': serializer.toJson<String?>(endDate),
    };
  }

  MedicineDetailsRow copyWith({
    String? habitId,
    Value<String?> medicineName = const Value.absent(),
    Value<String?> dose = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> startDate = const Value.absent(),
    Value<String?> endDate = const Value.absent(),
  }) => MedicineDetailsRow(
    habitId: habitId ?? this.habitId,
    medicineName: medicineName.present ? medicineName.value : this.medicineName,
    dose: dose.present ? dose.value : this.dose,
    notes: notes.present ? notes.value : this.notes,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
  );
  MedicineDetailsRow copyWithCompanion(MedicineDetailsCompanion data) {
    return MedicineDetailsRow(
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      medicineName:
          data.medicineName.present
              ? data.medicineName.value
              : this.medicineName,
      dose: data.dose.present ? data.dose.value : this.dose,
      notes: data.notes.present ? data.notes.value : this.notes,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicineDetailsRow(')
          ..write('habitId: $habitId, ')
          ..write('medicineName: $medicineName, ')
          ..write('dose: $dose, ')
          ..write('notes: $notes, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(habitId, medicineName, dose, notes, startDate, endDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicineDetailsRow &&
          other.habitId == this.habitId &&
          other.medicineName == this.medicineName &&
          other.dose == this.dose &&
          other.notes == this.notes &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate);
}

class MedicineDetailsCompanion extends UpdateCompanion<MedicineDetailsRow> {
  final Value<String> habitId;
  final Value<String?> medicineName;
  final Value<String?> dose;
  final Value<String?> notes;
  final Value<String?> startDate;
  final Value<String?> endDate;
  final Value<int> rowid;
  const MedicineDetailsCompanion({
    this.habitId = const Value.absent(),
    this.medicineName = const Value.absent(),
    this.dose = const Value.absent(),
    this.notes = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicineDetailsCompanion.insert({
    required String habitId,
    this.medicineName = const Value.absent(),
    this.dose = const Value.absent(),
    this.notes = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : habitId = Value(habitId);
  static Insertable<MedicineDetailsRow> custom({
    Expression<String>? habitId,
    Expression<String>? medicineName,
    Expression<String>? dose,
    Expression<String>? notes,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (habitId != null) 'habit_id': habitId,
      if (medicineName != null) 'medicine_name': medicineName,
      if (dose != null) 'dose': dose,
      if (notes != null) 'notes': notes,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicineDetailsCompanion copyWith({
    Value<String>? habitId,
    Value<String?>? medicineName,
    Value<String?>? dose,
    Value<String?>? notes,
    Value<String?>? startDate,
    Value<String?>? endDate,
    Value<int>? rowid,
  }) {
    return MedicineDetailsCompanion(
      habitId: habitId ?? this.habitId,
      medicineName: medicineName ?? this.medicineName,
      dose: dose ?? this.dose,
      notes: notes ?? this.notes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (medicineName.present) {
      map['medicine_name'] = Variable<String>(medicineName.value);
    }
    if (dose.present) {
      map['dose'] = Variable<String>(dose.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicineDetailsCompanion(')
          ..write('habitId: $habitId, ')
          ..write('medicineName: $medicineName, ')
          ..write('dose: $dose, ')
          ..write('notes: $notes, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WaterSettingsTable extends WaterSettings
    with TableInfo<$WaterSettingsTable, WaterSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaterSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _targetGlassesMeta = const VerificationMeta(
    'targetGlasses',
  );
  @override
  late final GeneratedColumn<int> targetGlasses = GeneratedColumn<int>(
    'target_glasses',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [habitId, targetGlasses];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'water_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<WaterSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('target_glasses')) {
      context.handle(
        _targetGlassesMeta,
        targetGlasses.isAcceptableOrUnknown(
          data['target_glasses']!,
          _targetGlassesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {habitId};
  @override
  WaterSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaterSettingsRow(
      habitId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}habit_id'],
          )!,
      targetGlasses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_glasses'],
      ),
    );
  }

  @override
  $WaterSettingsTable createAlias(String alias) {
    return $WaterSettingsTable(attachedDatabase, alias);
  }
}

class WaterSettingsRow extends DataClass
    implements Insertable<WaterSettingsRow> {
  final String habitId;
  final int? targetGlasses;
  const WaterSettingsRow({required this.habitId, this.targetGlasses});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['habit_id'] = Variable<String>(habitId);
    if (!nullToAbsent || targetGlasses != null) {
      map['target_glasses'] = Variable<int>(targetGlasses);
    }
    return map;
  }

  WaterSettingsCompanion toCompanion(bool nullToAbsent) {
    return WaterSettingsCompanion(
      habitId: Value(habitId),
      targetGlasses:
          targetGlasses == null && nullToAbsent
              ? const Value.absent()
              : Value(targetGlasses),
    );
  }

  factory WaterSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaterSettingsRow(
      habitId: serializer.fromJson<String>(json['habitId']),
      targetGlasses: serializer.fromJson<int?>(json['targetGlasses']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'habitId': serializer.toJson<String>(habitId),
      'targetGlasses': serializer.toJson<int?>(targetGlasses),
    };
  }

  WaterSettingsRow copyWith({
    String? habitId,
    Value<int?> targetGlasses = const Value.absent(),
  }) => WaterSettingsRow(
    habitId: habitId ?? this.habitId,
    targetGlasses:
        targetGlasses.present ? targetGlasses.value : this.targetGlasses,
  );
  WaterSettingsRow copyWithCompanion(WaterSettingsCompanion data) {
    return WaterSettingsRow(
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      targetGlasses:
          data.targetGlasses.present
              ? data.targetGlasses.value
              : this.targetGlasses,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaterSettingsRow(')
          ..write('habitId: $habitId, ')
          ..write('targetGlasses: $targetGlasses')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(habitId, targetGlasses);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaterSettingsRow &&
          other.habitId == this.habitId &&
          other.targetGlasses == this.targetGlasses);
}

class WaterSettingsCompanion extends UpdateCompanion<WaterSettingsRow> {
  final Value<String> habitId;
  final Value<int?> targetGlasses;
  final Value<int> rowid;
  const WaterSettingsCompanion({
    this.habitId = const Value.absent(),
    this.targetGlasses = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WaterSettingsCompanion.insert({
    required String habitId,
    this.targetGlasses = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : habitId = Value(habitId);
  static Insertable<WaterSettingsRow> custom({
    Expression<String>? habitId,
    Expression<int>? targetGlasses,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (habitId != null) 'habit_id': habitId,
      if (targetGlasses != null) 'target_glasses': targetGlasses,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WaterSettingsCompanion copyWith({
    Value<String>? habitId,
    Value<int?>? targetGlasses,
    Value<int>? rowid,
  }) {
    return WaterSettingsCompanion(
      habitId: habitId ?? this.habitId,
      targetGlasses: targetGlasses ?? this.targetGlasses,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (targetGlasses.present) {
      map['target_glasses'] = Variable<int>(targetGlasses.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaterSettingsCompanion(')
          ..write('habitId: $habitId, ')
          ..write('targetGlasses: $targetGlasses, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MeditationSettingsTable extends MeditationSettings
    with TableInfo<$MeditationSettingsTable, MeditationSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeditationSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _goalMinutesMeta = const VerificationMeta(
    'goalMinutes',
  );
  @override
  late final GeneratedColumn<int> goalMinutes = GeneratedColumn<int>(
    'goal_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [habitId, goalMinutes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meditation_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<MeditationSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('goal_minutes')) {
      context.handle(
        _goalMinutesMeta,
        goalMinutes.isAcceptableOrUnknown(
          data['goal_minutes']!,
          _goalMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {habitId};
  @override
  MeditationSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeditationSettingsRow(
      habitId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}habit_id'],
          )!,
      goalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_minutes'],
      ),
    );
  }

  @override
  $MeditationSettingsTable createAlias(String alias) {
    return $MeditationSettingsTable(attachedDatabase, alias);
  }
}

class MeditationSettingsRow extends DataClass
    implements Insertable<MeditationSettingsRow> {
  final String habitId;
  final int? goalMinutes;
  const MeditationSettingsRow({required this.habitId, this.goalMinutes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['habit_id'] = Variable<String>(habitId);
    if (!nullToAbsent || goalMinutes != null) {
      map['goal_minutes'] = Variable<int>(goalMinutes);
    }
    return map;
  }

  MeditationSettingsCompanion toCompanion(bool nullToAbsent) {
    return MeditationSettingsCompanion(
      habitId: Value(habitId),
      goalMinutes:
          goalMinutes == null && nullToAbsent
              ? const Value.absent()
              : Value(goalMinutes),
    );
  }

  factory MeditationSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeditationSettingsRow(
      habitId: serializer.fromJson<String>(json['habitId']),
      goalMinutes: serializer.fromJson<int?>(json['goalMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'habitId': serializer.toJson<String>(habitId),
      'goalMinutes': serializer.toJson<int?>(goalMinutes),
    };
  }

  MeditationSettingsRow copyWith({
    String? habitId,
    Value<int?> goalMinutes = const Value.absent(),
  }) => MeditationSettingsRow(
    habitId: habitId ?? this.habitId,
    goalMinutes: goalMinutes.present ? goalMinutes.value : this.goalMinutes,
  );
  MeditationSettingsRow copyWithCompanion(MeditationSettingsCompanion data) {
    return MeditationSettingsRow(
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      goalMinutes:
          data.goalMinutes.present ? data.goalMinutes.value : this.goalMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeditationSettingsRow(')
          ..write('habitId: $habitId, ')
          ..write('goalMinutes: $goalMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(habitId, goalMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeditationSettingsRow &&
          other.habitId == this.habitId &&
          other.goalMinutes == this.goalMinutes);
}

class MeditationSettingsCompanion
    extends UpdateCompanion<MeditationSettingsRow> {
  final Value<String> habitId;
  final Value<int?> goalMinutes;
  final Value<int> rowid;
  const MeditationSettingsCompanion({
    this.habitId = const Value.absent(),
    this.goalMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeditationSettingsCompanion.insert({
    required String habitId,
    this.goalMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : habitId = Value(habitId);
  static Insertable<MeditationSettingsRow> custom({
    Expression<String>? habitId,
    Expression<int>? goalMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (habitId != null) 'habit_id': habitId,
      if (goalMinutes != null) 'goal_minutes': goalMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeditationSettingsCompanion copyWith({
    Value<String>? habitId,
    Value<int?>? goalMinutes,
    Value<int>? rowid,
  }) {
    return MeditationSettingsCompanion(
      habitId: habitId ?? this.habitId,
      goalMinutes: goalMinutes ?? this.goalMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (goalMinutes.present) {
      map['goal_minutes'] = Variable<int>(goalMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeditationSettingsCompanion(')
          ..write('habitId: $habitId, ')
          ..write('goalMinutes: $goalMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseSettingsTable extends ExerciseSettings
    with TableInfo<$ExerciseSettingsTable, ExerciseSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _goalMinutesMeta = const VerificationMeta(
    'goalMinutes',
  );
  @override
  late final GeneratedColumn<int> goalMinutes = GeneratedColumn<int>(
    'goal_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stepsGoalMeta = const VerificationMeta(
    'stepsGoal',
  );
  @override
  late final GeneratedColumn<int> stepsGoal = GeneratedColumn<int>(
    'steps_goal',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _walkEveryMinutesMeta = const VerificationMeta(
    'walkEveryMinutes',
  );
  @override
  late final GeneratedColumn<int> walkEveryMinutes = GeneratedColumn<int>(
    'walk_every_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stretchEveryMinutesMeta =
      const VerificationMeta('stretchEveryMinutes');
  @override
  late final GeneratedColumn<int> stretchEveryMinutes = GeneratedColumn<int>(
    'stretch_every_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weekPlanJsonMeta = const VerificationMeta(
    'weekPlanJson',
  );
  @override
  late final GeneratedColumn<String> weekPlanJson = GeneratedColumn<String>(
    'week_plan_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _milestonesJsonMeta = const VerificationMeta(
    'milestonesJson',
  );
  @override
  late final GeneratedColumn<String> milestonesJson = GeneratedColumn<String>(
    'milestones_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    habitId,
    goalMinutes,
    stepsGoal,
    walkEveryMinutes,
    stretchEveryMinutes,
    weekPlanJson,
    milestonesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('goal_minutes')) {
      context.handle(
        _goalMinutesMeta,
        goalMinutes.isAcceptableOrUnknown(
          data['goal_minutes']!,
          _goalMinutesMeta,
        ),
      );
    }
    if (data.containsKey('steps_goal')) {
      context.handle(
        _stepsGoalMeta,
        stepsGoal.isAcceptableOrUnknown(data['steps_goal']!, _stepsGoalMeta),
      );
    }
    if (data.containsKey('walk_every_minutes')) {
      context.handle(
        _walkEveryMinutesMeta,
        walkEveryMinutes.isAcceptableOrUnknown(
          data['walk_every_minutes']!,
          _walkEveryMinutesMeta,
        ),
      );
    }
    if (data.containsKey('stretch_every_minutes')) {
      context.handle(
        _stretchEveryMinutesMeta,
        stretchEveryMinutes.isAcceptableOrUnknown(
          data['stretch_every_minutes']!,
          _stretchEveryMinutesMeta,
        ),
      );
    }
    if (data.containsKey('week_plan_json')) {
      context.handle(
        _weekPlanJsonMeta,
        weekPlanJson.isAcceptableOrUnknown(
          data['week_plan_json']!,
          _weekPlanJsonMeta,
        ),
      );
    }
    if (data.containsKey('milestones_json')) {
      context.handle(
        _milestonesJsonMeta,
        milestonesJson.isAcceptableOrUnknown(
          data['milestones_json']!,
          _milestonesJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {habitId};
  @override
  ExerciseSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseSettingsRow(
      habitId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}habit_id'],
          )!,
      goalMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_minutes'],
      ),
      stepsGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}steps_goal'],
      ),
      walkEveryMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}walk_every_minutes'],
      ),
      stretchEveryMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stretch_every_minutes'],
      ),
      weekPlanJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}week_plan_json'],
      ),
      milestonesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}milestones_json'],
      ),
    );
  }

  @override
  $ExerciseSettingsTable createAlias(String alias) {
    return $ExerciseSettingsTable(attachedDatabase, alias);
  }
}

class ExerciseSettingsRow extends DataClass
    implements Insertable<ExerciseSettingsRow> {
  final String habitId;
  final int? goalMinutes;
  final int? stepsGoal;
  final int? walkEveryMinutes;
  final int? stretchEveryMinutes;
  final String? weekPlanJson;
  final String? milestonesJson;
  const ExerciseSettingsRow({
    required this.habitId,
    this.goalMinutes,
    this.stepsGoal,
    this.walkEveryMinutes,
    this.stretchEveryMinutes,
    this.weekPlanJson,
    this.milestonesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['habit_id'] = Variable<String>(habitId);
    if (!nullToAbsent || goalMinutes != null) {
      map['goal_minutes'] = Variable<int>(goalMinutes);
    }
    if (!nullToAbsent || stepsGoal != null) {
      map['steps_goal'] = Variable<int>(stepsGoal);
    }
    if (!nullToAbsent || walkEveryMinutes != null) {
      map['walk_every_minutes'] = Variable<int>(walkEveryMinutes);
    }
    if (!nullToAbsent || stretchEveryMinutes != null) {
      map['stretch_every_minutes'] = Variable<int>(stretchEveryMinutes);
    }
    if (!nullToAbsent || weekPlanJson != null) {
      map['week_plan_json'] = Variable<String>(weekPlanJson);
    }
    if (!nullToAbsent || milestonesJson != null) {
      map['milestones_json'] = Variable<String>(milestonesJson);
    }
    return map;
  }

  ExerciseSettingsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseSettingsCompanion(
      habitId: Value(habitId),
      goalMinutes:
          goalMinutes == null && nullToAbsent
              ? const Value.absent()
              : Value(goalMinutes),
      stepsGoal:
          stepsGoal == null && nullToAbsent
              ? const Value.absent()
              : Value(stepsGoal),
      walkEveryMinutes:
          walkEveryMinutes == null && nullToAbsent
              ? const Value.absent()
              : Value(walkEveryMinutes),
      stretchEveryMinutes:
          stretchEveryMinutes == null && nullToAbsent
              ? const Value.absent()
              : Value(stretchEveryMinutes),
      weekPlanJson:
          weekPlanJson == null && nullToAbsent
              ? const Value.absent()
              : Value(weekPlanJson),
      milestonesJson:
          milestonesJson == null && nullToAbsent
              ? const Value.absent()
              : Value(milestonesJson),
    );
  }

  factory ExerciseSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseSettingsRow(
      habitId: serializer.fromJson<String>(json['habitId']),
      goalMinutes: serializer.fromJson<int?>(json['goalMinutes']),
      stepsGoal: serializer.fromJson<int?>(json['stepsGoal']),
      walkEveryMinutes: serializer.fromJson<int?>(json['walkEveryMinutes']),
      stretchEveryMinutes: serializer.fromJson<int?>(
        json['stretchEveryMinutes'],
      ),
      weekPlanJson: serializer.fromJson<String?>(json['weekPlanJson']),
      milestonesJson: serializer.fromJson<String?>(json['milestonesJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'habitId': serializer.toJson<String>(habitId),
      'goalMinutes': serializer.toJson<int?>(goalMinutes),
      'stepsGoal': serializer.toJson<int?>(stepsGoal),
      'walkEveryMinutes': serializer.toJson<int?>(walkEveryMinutes),
      'stretchEveryMinutes': serializer.toJson<int?>(stretchEveryMinutes),
      'weekPlanJson': serializer.toJson<String?>(weekPlanJson),
      'milestonesJson': serializer.toJson<String?>(milestonesJson),
    };
  }

  ExerciseSettingsRow copyWith({
    String? habitId,
    Value<int?> goalMinutes = const Value.absent(),
    Value<int?> stepsGoal = const Value.absent(),
    Value<int?> walkEveryMinutes = const Value.absent(),
    Value<int?> stretchEveryMinutes = const Value.absent(),
    Value<String?> weekPlanJson = const Value.absent(),
    Value<String?> milestonesJson = const Value.absent(),
  }) => ExerciseSettingsRow(
    habitId: habitId ?? this.habitId,
    goalMinutes: goalMinutes.present ? goalMinutes.value : this.goalMinutes,
    stepsGoal: stepsGoal.present ? stepsGoal.value : this.stepsGoal,
    walkEveryMinutes:
        walkEveryMinutes.present
            ? walkEveryMinutes.value
            : this.walkEveryMinutes,
    stretchEveryMinutes:
        stretchEveryMinutes.present
            ? stretchEveryMinutes.value
            : this.stretchEveryMinutes,
    weekPlanJson: weekPlanJson.present ? weekPlanJson.value : this.weekPlanJson,
    milestonesJson:
        milestonesJson.present ? milestonesJson.value : this.milestonesJson,
  );
  ExerciseSettingsRow copyWithCompanion(ExerciseSettingsCompanion data) {
    return ExerciseSettingsRow(
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      goalMinutes:
          data.goalMinutes.present ? data.goalMinutes.value : this.goalMinutes,
      stepsGoal: data.stepsGoal.present ? data.stepsGoal.value : this.stepsGoal,
      walkEveryMinutes:
          data.walkEveryMinutes.present
              ? data.walkEveryMinutes.value
              : this.walkEveryMinutes,
      stretchEveryMinutes:
          data.stretchEveryMinutes.present
              ? data.stretchEveryMinutes.value
              : this.stretchEveryMinutes,
      weekPlanJson:
          data.weekPlanJson.present
              ? data.weekPlanJson.value
              : this.weekPlanJson,
      milestonesJson:
          data.milestonesJson.present
              ? data.milestonesJson.value
              : this.milestonesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseSettingsRow(')
          ..write('habitId: $habitId, ')
          ..write('goalMinutes: $goalMinutes, ')
          ..write('stepsGoal: $stepsGoal, ')
          ..write('walkEveryMinutes: $walkEveryMinutes, ')
          ..write('stretchEveryMinutes: $stretchEveryMinutes, ')
          ..write('weekPlanJson: $weekPlanJson, ')
          ..write('milestonesJson: $milestonesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    habitId,
    goalMinutes,
    stepsGoal,
    walkEveryMinutes,
    stretchEveryMinutes,
    weekPlanJson,
    milestonesJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseSettingsRow &&
          other.habitId == this.habitId &&
          other.goalMinutes == this.goalMinutes &&
          other.stepsGoal == this.stepsGoal &&
          other.walkEveryMinutes == this.walkEveryMinutes &&
          other.stretchEveryMinutes == this.stretchEveryMinutes &&
          other.weekPlanJson == this.weekPlanJson &&
          other.milestonesJson == this.milestonesJson);
}

class ExerciseSettingsCompanion extends UpdateCompanion<ExerciseSettingsRow> {
  final Value<String> habitId;
  final Value<int?> goalMinutes;
  final Value<int?> stepsGoal;
  final Value<int?> walkEveryMinutes;
  final Value<int?> stretchEveryMinutes;
  final Value<String?> weekPlanJson;
  final Value<String?> milestonesJson;
  final Value<int> rowid;
  const ExerciseSettingsCompanion({
    this.habitId = const Value.absent(),
    this.goalMinutes = const Value.absent(),
    this.stepsGoal = const Value.absent(),
    this.walkEveryMinutes = const Value.absent(),
    this.stretchEveryMinutes = const Value.absent(),
    this.weekPlanJson = const Value.absent(),
    this.milestonesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseSettingsCompanion.insert({
    required String habitId,
    this.goalMinutes = const Value.absent(),
    this.stepsGoal = const Value.absent(),
    this.walkEveryMinutes = const Value.absent(),
    this.stretchEveryMinutes = const Value.absent(),
    this.weekPlanJson = const Value.absent(),
    this.milestonesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : habitId = Value(habitId);
  static Insertable<ExerciseSettingsRow> custom({
    Expression<String>? habitId,
    Expression<int>? goalMinutes,
    Expression<int>? stepsGoal,
    Expression<int>? walkEveryMinutes,
    Expression<int>? stretchEveryMinutes,
    Expression<String>? weekPlanJson,
    Expression<String>? milestonesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (habitId != null) 'habit_id': habitId,
      if (goalMinutes != null) 'goal_minutes': goalMinutes,
      if (stepsGoal != null) 'steps_goal': stepsGoal,
      if (walkEveryMinutes != null) 'walk_every_minutes': walkEveryMinutes,
      if (stretchEveryMinutes != null)
        'stretch_every_minutes': stretchEveryMinutes,
      if (weekPlanJson != null) 'week_plan_json': weekPlanJson,
      if (milestonesJson != null) 'milestones_json': milestonesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseSettingsCompanion copyWith({
    Value<String>? habitId,
    Value<int?>? goalMinutes,
    Value<int?>? stepsGoal,
    Value<int?>? walkEveryMinutes,
    Value<int?>? stretchEveryMinutes,
    Value<String?>? weekPlanJson,
    Value<String?>? milestonesJson,
    Value<int>? rowid,
  }) {
    return ExerciseSettingsCompanion(
      habitId: habitId ?? this.habitId,
      goalMinutes: goalMinutes ?? this.goalMinutes,
      stepsGoal: stepsGoal ?? this.stepsGoal,
      walkEveryMinutes: walkEveryMinutes ?? this.walkEveryMinutes,
      stretchEveryMinutes: stretchEveryMinutes ?? this.stretchEveryMinutes,
      weekPlanJson: weekPlanJson ?? this.weekPlanJson,
      milestonesJson: milestonesJson ?? this.milestonesJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (goalMinutes.present) {
      map['goal_minutes'] = Variable<int>(goalMinutes.value);
    }
    if (stepsGoal.present) {
      map['steps_goal'] = Variable<int>(stepsGoal.value);
    }
    if (walkEveryMinutes.present) {
      map['walk_every_minutes'] = Variable<int>(walkEveryMinutes.value);
    }
    if (stretchEveryMinutes.present) {
      map['stretch_every_minutes'] = Variable<int>(stretchEveryMinutes.value);
    }
    if (weekPlanJson.present) {
      map['week_plan_json'] = Variable<String>(weekPlanJson.value);
    }
    if (milestonesJson.present) {
      map['milestones_json'] = Variable<String>(milestonesJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseSettingsCompanion(')
          ..write('habitId: $habitId, ')
          ..write('goalMinutes: $goalMinutes, ')
          ..write('stepsGoal: $stepsGoal, ')
          ..write('walkEveryMinutes: $walkEveryMinutes, ')
          ..write('stretchEveryMinutes: $stretchEveryMinutes, ')
          ..write('weekPlanJson: $weekPlanJson, ')
          ..write('milestonesJson: $milestonesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitLogsTable extends HabitLogs
    with TableInfo<$HabitLogsTable, HabitLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metricMeta = const VerificationMeta('metric');
  @override
  late final GeneratedColumn<String> metric = GeneratedColumn<String>(
    'metric',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    habitId,
    day,
    metric,
    value,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('metric')) {
      context.handle(
        _metricMeta,
        metric.isAcceptableOrUnknown(data['metric']!, _metricMeta),
      );
    } else if (isInserting) {
      context.missing(_metricMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {habitId, day, metric};
  @override
  HabitLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitLogRow(
      habitId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}habit_id'],
          )!,
      day:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}day'],
          )!,
      metric:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}metric'],
          )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      ),
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $HabitLogsTable createAlias(String alias) {
    return $HabitLogsTable(attachedDatabase, alias);
  }
}

class HabitLogRow extends DataClass implements Insertable<HabitLogRow> {
  final String habitId;

  /// Local calendar day "YYYY-MM-DD".
  final String day;

  /// See [HabitMetric].
  final String metric;
  final int? value;
  final DateTime updatedAt;
  const HabitLogRow({
    required this.habitId,
    required this.day,
    required this.metric,
    this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['habit_id'] = Variable<String>(habitId);
    map['day'] = Variable<String>(day);
    map['metric'] = Variable<String>(metric);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<int>(value);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HabitLogsCompanion toCompanion(bool nullToAbsent) {
    return HabitLogsCompanion(
      habitId: Value(habitId),
      day: Value(day),
      metric: Value(metric),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory HabitLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitLogRow(
      habitId: serializer.fromJson<String>(json['habitId']),
      day: serializer.fromJson<String>(json['day']),
      metric: serializer.fromJson<String>(json['metric']),
      value: serializer.fromJson<int?>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'habitId': serializer.toJson<String>(habitId),
      'day': serializer.toJson<String>(day),
      'metric': serializer.toJson<String>(metric),
      'value': serializer.toJson<int?>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HabitLogRow copyWith({
    String? habitId,
    String? day,
    String? metric,
    Value<int?> value = const Value.absent(),
    DateTime? updatedAt,
  }) => HabitLogRow(
    habitId: habitId ?? this.habitId,
    day: day ?? this.day,
    metric: metric ?? this.metric,
    value: value.present ? value.value : this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HabitLogRow copyWithCompanion(HabitLogsCompanion data) {
    return HabitLogRow(
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      day: data.day.present ? data.day.value : this.day,
      metric: data.metric.present ? data.metric.value : this.metric,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitLogRow(')
          ..write('habitId: $habitId, ')
          ..write('day: $day, ')
          ..write('metric: $metric, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(habitId, day, metric, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitLogRow &&
          other.habitId == this.habitId &&
          other.day == this.day &&
          other.metric == this.metric &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class HabitLogsCompanion extends UpdateCompanion<HabitLogRow> {
  final Value<String> habitId;
  final Value<String> day;
  final Value<String> metric;
  final Value<int?> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HabitLogsCompanion({
    this.habitId = const Value.absent(),
    this.day = const Value.absent(),
    this.metric = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitLogsCompanion.insert({
    required String habitId,
    required String day,
    required String metric,
    this.value = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : habitId = Value(habitId),
       day = Value(day),
       metric = Value(metric),
       updatedAt = Value(updatedAt);
  static Insertable<HabitLogRow> custom({
    Expression<String>? habitId,
    Expression<String>? day,
    Expression<String>? metric,
    Expression<int>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (habitId != null) 'habit_id': habitId,
      if (day != null) 'day': day,
      if (metric != null) 'metric': metric,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitLogsCompanion copyWith({
    Value<String>? habitId,
    Value<String>? day,
    Value<String>? metric,
    Value<int?>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return HabitLogsCompanion(
      habitId: habitId ?? this.habitId,
      day: day ?? this.day,
      metric: metric ?? this.metric,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (metric.present) {
      map['metric'] = Variable<String>(metric.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitLogsCompanion(')
          ..write('habitId: $habitId, ')
          ..write('day: $day, ')
          ..write('metric: $metric, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentItemsTable extends ContentItems
    with TableInfo<$ContentItemsTable, ContentItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaUrlMeta = const VerificationMeta(
    'mediaUrl',
  );
  @override
  late final GeneratedColumn<String> mediaUrl = GeneratedColumn<String>(
    'media_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaFormatMeta = const VerificationMeta(
    'mediaFormat',
  );
  @override
  late final GeneratedColumn<String> mediaFormat = GeneratedColumn<String>(
    'media_format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _licenseMeta = const VerificationMeta(
    'license',
  );
  @override
  late final GeneratedColumn<String> license = GeneratedColumn<String>(
    'license',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _licenseUrlMeta = const VerificationMeta(
    'licenseUrl',
  );
  @override
  late final GeneratedColumn<String> licenseUrl = GeneratedColumn<String>(
    'license_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attributionMeta = const VerificationMeta(
    'attribution',
  );
  @override
  late final GeneratedColumn<String> attribution = GeneratedColumn<String>(
    'attribution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> tags =
      GeneratedColumn<String>(
        'tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($ContentItemsTable.$convertertags);
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _popularityMeta = const VerificationMeta(
    'popularity',
  );
  @override
  late final GeneratedColumn<int> popularity = GeneratedColumn<int>(
    'popularity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _firstSeenAtMeta = const VerificationMeta(
    'firstSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> firstSeenAt = GeneratedColumn<DateTime>(
    'first_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seenMeta = const VerificationMeta('seen');
  @override
  late final GeneratedColumn<bool> seen = GeneratedColumn<bool>(
    'seen',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("seen" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    provider,
    kind,
    title,
    subtitle,
    description,
    mediaUrl,
    mediaFormat,
    imageUrl,
    sourceUrl,
    license,
    licenseUrl,
    attribution,
    tags,
    language,
    durationSeconds,
    popularity,
    firstSeenAt,
    lastSeenAt,
    seen,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('media_url')) {
      context.handle(
        _mediaUrlMeta,
        mediaUrl.isAcceptableOrUnknown(data['media_url']!, _mediaUrlMeta),
      );
    }
    if (data.containsKey('media_format')) {
      context.handle(
        _mediaFormatMeta,
        mediaFormat.isAcceptableOrUnknown(
          data['media_format']!,
          _mediaFormatMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    }
    if (data.containsKey('license')) {
      context.handle(
        _licenseMeta,
        license.isAcceptableOrUnknown(data['license']!, _licenseMeta),
      );
    } else if (isInserting) {
      context.missing(_licenseMeta);
    }
    if (data.containsKey('license_url')) {
      context.handle(
        _licenseUrlMeta,
        licenseUrl.isAcceptableOrUnknown(data['license_url']!, _licenseUrlMeta),
      );
    }
    if (data.containsKey('attribution')) {
      context.handle(
        _attributionMeta,
        attribution.isAcceptableOrUnknown(
          data['attribution']!,
          _attributionMeta,
        ),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('popularity')) {
      context.handle(
        _popularityMeta,
        popularity.isAcceptableOrUnknown(data['popularity']!, _popularityMeta),
      );
    }
    if (data.containsKey('first_seen_at')) {
      context.handle(
        _firstSeenAtMeta,
        firstSeenAt.isAcceptableOrUnknown(
          data['first_seen_at']!,
          _firstSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstSeenAtMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    if (data.containsKey('seen')) {
      context.handle(
        _seenMeta,
        seen.isAcceptableOrUnknown(data['seen']!, _seenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContentItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentItemRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      provider:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}provider'],
          )!,
      kind:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}kind'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      mediaUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_url'],
      ),
      mediaFormat:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}media_format'],
          )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      ),
      license:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}license'],
          )!,
      licenseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}license_url'],
      ),
      attribution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribution'],
      ),
      tags: $ContentItemsTable.$convertertags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tags'],
        )!,
      ),
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      popularity:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}popularity'],
          )!,
      firstSeenAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}first_seen_at'],
          )!,
      lastSeenAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}last_seen_at'],
          )!,
      seen:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}seen'],
          )!,
    );
  }

  @override
  $ContentItemsTable createAlias(String alias) {
    return $ContentItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertertags =
      const StringListConverter();
}

class ContentItemRow extends DataClass implements Insertable<ContentItemRow> {
  /// "<provider>:<externalId>", e.g. "gutenberg:1342".
  final String id;
  final String provider;

  /// book | audio | exercise
  final String kind;
  final String title;
  final String? subtitle;
  final String? description;

  /// Direct media link (EPUB, MP3, …) — fetched only when the user opens it.
  final String? mediaUrl;

  /// epub | html | mp3 | none
  final String mediaFormat;
  final String? imageUrl;
  final String? sourceUrl;
  final String license;
  final String? licenseUrl;
  final String? attribution;
  final List<String> tags;
  final String? language;
  final int? durationSeconds;
  final int popularity;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;

  /// False for items that arrived in a refresh after the first one, until the
  /// user has viewed them — drives the "New" badges.
  final bool seen;
  const ContentItemRow({
    required this.id,
    required this.provider,
    required this.kind,
    required this.title,
    this.subtitle,
    this.description,
    this.mediaUrl,
    required this.mediaFormat,
    this.imageUrl,
    this.sourceUrl,
    required this.license,
    this.licenseUrl,
    this.attribution,
    required this.tags,
    this.language,
    this.durationSeconds,
    required this.popularity,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.seen,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider'] = Variable<String>(provider);
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || mediaUrl != null) {
      map['media_url'] = Variable<String>(mediaUrl);
    }
    map['media_format'] = Variable<String>(mediaFormat);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || sourceUrl != null) {
      map['source_url'] = Variable<String>(sourceUrl);
    }
    map['license'] = Variable<String>(license);
    if (!nullToAbsent || licenseUrl != null) {
      map['license_url'] = Variable<String>(licenseUrl);
    }
    if (!nullToAbsent || attribution != null) {
      map['attribution'] = Variable<String>(attribution);
    }
    {
      map['tags'] = Variable<String>(
        $ContentItemsTable.$convertertags.toSql(tags),
      );
    }
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['popularity'] = Variable<int>(popularity);
    map['first_seen_at'] = Variable<DateTime>(firstSeenAt);
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    map['seen'] = Variable<bool>(seen);
    return map;
  }

  ContentItemsCompanion toCompanion(bool nullToAbsent) {
    return ContentItemsCompanion(
      id: Value(id),
      provider: Value(provider),
      kind: Value(kind),
      title: Value(title),
      subtitle:
          subtitle == null && nullToAbsent
              ? const Value.absent()
              : Value(subtitle),
      description:
          description == null && nullToAbsent
              ? const Value.absent()
              : Value(description),
      mediaUrl:
          mediaUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(mediaUrl),
      mediaFormat: Value(mediaFormat),
      imageUrl:
          imageUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(imageUrl),
      sourceUrl:
          sourceUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(sourceUrl),
      license: Value(license),
      licenseUrl:
          licenseUrl == null && nullToAbsent
              ? const Value.absent()
              : Value(licenseUrl),
      attribution:
          attribution == null && nullToAbsent
              ? const Value.absent()
              : Value(attribution),
      tags: Value(tags),
      language:
          language == null && nullToAbsent
              ? const Value.absent()
              : Value(language),
      durationSeconds:
          durationSeconds == null && nullToAbsent
              ? const Value.absent()
              : Value(durationSeconds),
      popularity: Value(popularity),
      firstSeenAt: Value(firstSeenAt),
      lastSeenAt: Value(lastSeenAt),
      seen: Value(seen),
    );
  }

  factory ContentItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentItemRow(
      id: serializer.fromJson<String>(json['id']),
      provider: serializer.fromJson<String>(json['provider']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      description: serializer.fromJson<String?>(json['description']),
      mediaUrl: serializer.fromJson<String?>(json['mediaUrl']),
      mediaFormat: serializer.fromJson<String>(json['mediaFormat']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      sourceUrl: serializer.fromJson<String?>(json['sourceUrl']),
      license: serializer.fromJson<String>(json['license']),
      licenseUrl: serializer.fromJson<String?>(json['licenseUrl']),
      attribution: serializer.fromJson<String?>(json['attribution']),
      tags: serializer.fromJson<List<String>>(json['tags']),
      language: serializer.fromJson<String?>(json['language']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      popularity: serializer.fromJson<int>(json['popularity']),
      firstSeenAt: serializer.fromJson<DateTime>(json['firstSeenAt']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
      seen: serializer.fromJson<bool>(json['seen']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'provider': serializer.toJson<String>(provider),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String?>(subtitle),
      'description': serializer.toJson<String?>(description),
      'mediaUrl': serializer.toJson<String?>(mediaUrl),
      'mediaFormat': serializer.toJson<String>(mediaFormat),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'sourceUrl': serializer.toJson<String?>(sourceUrl),
      'license': serializer.toJson<String>(license),
      'licenseUrl': serializer.toJson<String?>(licenseUrl),
      'attribution': serializer.toJson<String?>(attribution),
      'tags': serializer.toJson<List<String>>(tags),
      'language': serializer.toJson<String?>(language),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'popularity': serializer.toJson<int>(popularity),
      'firstSeenAt': serializer.toJson<DateTime>(firstSeenAt),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
      'seen': serializer.toJson<bool>(seen),
    };
  }

  ContentItemRow copyWith({
    String? id,
    String? provider,
    String? kind,
    String? title,
    Value<String?> subtitle = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> mediaUrl = const Value.absent(),
    String? mediaFormat,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> sourceUrl = const Value.absent(),
    String? license,
    Value<String?> licenseUrl = const Value.absent(),
    Value<String?> attribution = const Value.absent(),
    List<String>? tags,
    Value<String?> language = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    int? popularity,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    bool? seen,
  }) => ContentItemRow(
    id: id ?? this.id,
    provider: provider ?? this.provider,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    description: description.present ? description.value : this.description,
    mediaUrl: mediaUrl.present ? mediaUrl.value : this.mediaUrl,
    mediaFormat: mediaFormat ?? this.mediaFormat,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    sourceUrl: sourceUrl.present ? sourceUrl.value : this.sourceUrl,
    license: license ?? this.license,
    licenseUrl: licenseUrl.present ? licenseUrl.value : this.licenseUrl,
    attribution: attribution.present ? attribution.value : this.attribution,
    tags: tags ?? this.tags,
    language: language.present ? language.value : this.language,
    durationSeconds:
        durationSeconds.present ? durationSeconds.value : this.durationSeconds,
    popularity: popularity ?? this.popularity,
    firstSeenAt: firstSeenAt ?? this.firstSeenAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    seen: seen ?? this.seen,
  );
  ContentItemRow copyWithCompanion(ContentItemsCompanion data) {
    return ContentItemRow(
      id: data.id.present ? data.id.value : this.id,
      provider: data.provider.present ? data.provider.value : this.provider,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      description:
          data.description.present ? data.description.value : this.description,
      mediaUrl: data.mediaUrl.present ? data.mediaUrl.value : this.mediaUrl,
      mediaFormat:
          data.mediaFormat.present ? data.mediaFormat.value : this.mediaFormat,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      license: data.license.present ? data.license.value : this.license,
      licenseUrl:
          data.licenseUrl.present ? data.licenseUrl.value : this.licenseUrl,
      attribution:
          data.attribution.present ? data.attribution.value : this.attribution,
      tags: data.tags.present ? data.tags.value : this.tags,
      language: data.language.present ? data.language.value : this.language,
      durationSeconds:
          data.durationSeconds.present
              ? data.durationSeconds.value
              : this.durationSeconds,
      popularity:
          data.popularity.present ? data.popularity.value : this.popularity,
      firstSeenAt:
          data.firstSeenAt.present ? data.firstSeenAt.value : this.firstSeenAt,
      lastSeenAt:
          data.lastSeenAt.present ? data.lastSeenAt.value : this.lastSeenAt,
      seen: data.seen.present ? data.seen.value : this.seen,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentItemRow(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('description: $description, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaFormat: $mediaFormat, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('license: $license, ')
          ..write('licenseUrl: $licenseUrl, ')
          ..write('attribution: $attribution, ')
          ..write('tags: $tags, ')
          ..write('language: $language, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('popularity: $popularity, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('seen: $seen')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    provider,
    kind,
    title,
    subtitle,
    description,
    mediaUrl,
    mediaFormat,
    imageUrl,
    sourceUrl,
    license,
    licenseUrl,
    attribution,
    tags,
    language,
    durationSeconds,
    popularity,
    firstSeenAt,
    lastSeenAt,
    seen,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentItemRow &&
          other.id == this.id &&
          other.provider == this.provider &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.description == this.description &&
          other.mediaUrl == this.mediaUrl &&
          other.mediaFormat == this.mediaFormat &&
          other.imageUrl == this.imageUrl &&
          other.sourceUrl == this.sourceUrl &&
          other.license == this.license &&
          other.licenseUrl == this.licenseUrl &&
          other.attribution == this.attribution &&
          other.tags == this.tags &&
          other.language == this.language &&
          other.durationSeconds == this.durationSeconds &&
          other.popularity == this.popularity &&
          other.firstSeenAt == this.firstSeenAt &&
          other.lastSeenAt == this.lastSeenAt &&
          other.seen == this.seen);
}

class ContentItemsCompanion extends UpdateCompanion<ContentItemRow> {
  final Value<String> id;
  final Value<String> provider;
  final Value<String> kind;
  final Value<String> title;
  final Value<String?> subtitle;
  final Value<String?> description;
  final Value<String?> mediaUrl;
  final Value<String> mediaFormat;
  final Value<String?> imageUrl;
  final Value<String?> sourceUrl;
  final Value<String> license;
  final Value<String?> licenseUrl;
  final Value<String?> attribution;
  final Value<List<String>> tags;
  final Value<String?> language;
  final Value<int?> durationSeconds;
  final Value<int> popularity;
  final Value<DateTime> firstSeenAt;
  final Value<DateTime> lastSeenAt;
  final Value<bool> seen;
  final Value<int> rowid;
  const ContentItemsCompanion({
    this.id = const Value.absent(),
    this.provider = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.description = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.mediaFormat = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.license = const Value.absent(),
    this.licenseUrl = const Value.absent(),
    this.attribution = const Value.absent(),
    this.tags = const Value.absent(),
    this.language = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.popularity = const Value.absent(),
    this.firstSeenAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.seen = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentItemsCompanion.insert({
    required String id,
    required String provider,
    required String kind,
    required String title,
    this.subtitle = const Value.absent(),
    this.description = const Value.absent(),
    this.mediaUrl = const Value.absent(),
    this.mediaFormat = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    required String license,
    this.licenseUrl = const Value.absent(),
    this.attribution = const Value.absent(),
    this.tags = const Value.absent(),
    this.language = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.popularity = const Value.absent(),
    required DateTime firstSeenAt,
    required DateTime lastSeenAt,
    this.seen = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       provider = Value(provider),
       kind = Value(kind),
       title = Value(title),
       license = Value(license),
       firstSeenAt = Value(firstSeenAt),
       lastSeenAt = Value(lastSeenAt);
  static Insertable<ContentItemRow> custom({
    Expression<String>? id,
    Expression<String>? provider,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? description,
    Expression<String>? mediaUrl,
    Expression<String>? mediaFormat,
    Expression<String>? imageUrl,
    Expression<String>? sourceUrl,
    Expression<String>? license,
    Expression<String>? licenseUrl,
    Expression<String>? attribution,
    Expression<String>? tags,
    Expression<String>? language,
    Expression<int>? durationSeconds,
    Expression<int>? popularity,
    Expression<DateTime>? firstSeenAt,
    Expression<DateTime>? lastSeenAt,
    Expression<bool>? seen,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (provider != null) 'provider': provider,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (description != null) 'description': description,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (mediaFormat != null) 'media_format': mediaFormat,
      if (imageUrl != null) 'image_url': imageUrl,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (license != null) 'license': license,
      if (licenseUrl != null) 'license_url': licenseUrl,
      if (attribution != null) 'attribution': attribution,
      if (tags != null) 'tags': tags,
      if (language != null) 'language': language,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (popularity != null) 'popularity': popularity,
      if (firstSeenAt != null) 'first_seen_at': firstSeenAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (seen != null) 'seen': seen,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? provider,
    Value<String>? kind,
    Value<String>? title,
    Value<String?>? subtitle,
    Value<String?>? description,
    Value<String?>? mediaUrl,
    Value<String>? mediaFormat,
    Value<String?>? imageUrl,
    Value<String?>? sourceUrl,
    Value<String>? license,
    Value<String?>? licenseUrl,
    Value<String?>? attribution,
    Value<List<String>>? tags,
    Value<String?>? language,
    Value<int?>? durationSeconds,
    Value<int>? popularity,
    Value<DateTime>? firstSeenAt,
    Value<DateTime>? lastSeenAt,
    Value<bool>? seen,
    Value<int>? rowid,
  }) {
    return ContentItemsCompanion(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaFormat: mediaFormat ?? this.mediaFormat,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      license: license ?? this.license,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      attribution: attribution ?? this.attribution,
      tags: tags ?? this.tags,
      language: language ?? this.language,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      popularity: popularity ?? this.popularity,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      seen: seen ?? this.seen,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (mediaUrl.present) {
      map['media_url'] = Variable<String>(mediaUrl.value);
    }
    if (mediaFormat.present) {
      map['media_format'] = Variable<String>(mediaFormat.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (license.present) {
      map['license'] = Variable<String>(license.value);
    }
    if (licenseUrl.present) {
      map['license_url'] = Variable<String>(licenseUrl.value);
    }
    if (attribution.present) {
      map['attribution'] = Variable<String>(attribution.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(
        $ContentItemsTable.$convertertags.toSql(tags.value),
      );
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (popularity.present) {
      map['popularity'] = Variable<int>(popularity.value);
    }
    if (firstSeenAt.present) {
      map['first_seen_at'] = Variable<DateTime>(firstSeenAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (seen.present) {
      map['seen'] = Variable<bool>(seen.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentItemsCompanion(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('description: $description, ')
          ..write('mediaUrl: $mediaUrl, ')
          ..write('mediaFormat: $mediaFormat, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('license: $license, ')
          ..write('licenseUrl: $licenseUrl, ')
          ..write('attribution: $attribution, ')
          ..write('tags: $tags, ')
          ..write('language: $language, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('popularity: $popularity, ')
          ..write('firstSeenAt: $firstSeenAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('seen: $seen, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentSyncStatesTable extends ContentSyncStates
    with TableInfo<$ContentSyncStatesTable, ContentSyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentSyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSuccessAtMeta = const VerificationMeta(
    'lastSuccessAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSuccessAt =
      GeneratedColumn<DateTime>(
        'last_success_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemCountMeta = const VerificationMeta(
    'itemCount',
  );
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
    'item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    provider,
    lastAttemptAt,
    lastSuccessAt,
    lastError,
    itemCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_sync_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentSyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_success_at')) {
      context.handle(
        _lastSuccessAtMeta,
        lastSuccessAt.isAcceptableOrUnknown(
          data['last_success_at']!,
          _lastSuccessAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('item_count')) {
      context.handle(
        _itemCountMeta,
        itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {provider};
  @override
  ContentSyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentSyncStateRow(
      provider:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}provider'],
          )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastSuccessAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_success_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      itemCount:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}item_count'],
          )!,
    );
  }

  @override
  $ContentSyncStatesTable createAlias(String alias) {
    return $ContentSyncStatesTable(attachedDatabase, alias);
  }
}

class ContentSyncStateRow extends DataClass
    implements Insertable<ContentSyncStateRow> {
  final String provider;
  final DateTime? lastAttemptAt;
  final DateTime? lastSuccessAt;
  final String? lastError;
  final int itemCount;
  const ContentSyncStateRow({
    required this.provider,
    this.lastAttemptAt,
    this.lastSuccessAt,
    this.lastError,
    required this.itemCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider'] = Variable<String>(provider);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || lastSuccessAt != null) {
      map['last_success_at'] = Variable<DateTime>(lastSuccessAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['item_count'] = Variable<int>(itemCount);
    return map;
  }

  ContentSyncStatesCompanion toCompanion(bool nullToAbsent) {
    return ContentSyncStatesCompanion(
      provider: Value(provider),
      lastAttemptAt:
          lastAttemptAt == null && nullToAbsent
              ? const Value.absent()
              : Value(lastAttemptAt),
      lastSuccessAt:
          lastSuccessAt == null && nullToAbsent
              ? const Value.absent()
              : Value(lastSuccessAt),
      lastError:
          lastError == null && nullToAbsent
              ? const Value.absent()
              : Value(lastError),
      itemCount: Value(itemCount),
    );
  }

  factory ContentSyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentSyncStateRow(
      provider: serializer.fromJson<String>(json['provider']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      lastSuccessAt: serializer.fromJson<DateTime?>(json['lastSuccessAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'provider': serializer.toJson<String>(provider),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'lastSuccessAt': serializer.toJson<DateTime?>(lastSuccessAt),
      'lastError': serializer.toJson<String?>(lastError),
      'itemCount': serializer.toJson<int>(itemCount),
    };
  }

  ContentSyncStateRow copyWith({
    String? provider,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<DateTime?> lastSuccessAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    int? itemCount,
  }) => ContentSyncStateRow(
    provider: provider ?? this.provider,
    lastAttemptAt:
        lastAttemptAt.present ? lastAttemptAt.value : this.lastAttemptAt,
    lastSuccessAt:
        lastSuccessAt.present ? lastSuccessAt.value : this.lastSuccessAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    itemCount: itemCount ?? this.itemCount,
  );
  ContentSyncStateRow copyWithCompanion(ContentSyncStatesCompanion data) {
    return ContentSyncStateRow(
      provider: data.provider.present ? data.provider.value : this.provider,
      lastAttemptAt:
          data.lastAttemptAt.present
              ? data.lastAttemptAt.value
              : this.lastAttemptAt,
      lastSuccessAt:
          data.lastSuccessAt.present
              ? data.lastSuccessAt.value
              : this.lastSuccessAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentSyncStateRow(')
          ..write('provider: $provider, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('lastError: $lastError, ')
          ..write('itemCount: $itemCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(provider, lastAttemptAt, lastSuccessAt, lastError, itemCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentSyncStateRow &&
          other.provider == this.provider &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastSuccessAt == this.lastSuccessAt &&
          other.lastError == this.lastError &&
          other.itemCount == this.itemCount);
}

class ContentSyncStatesCompanion extends UpdateCompanion<ContentSyncStateRow> {
  final Value<String> provider;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> lastSuccessAt;
  final Value<String?> lastError;
  final Value<int> itemCount;
  final Value<int> rowid;
  const ContentSyncStatesCompanion({
    this.provider = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentSyncStatesCompanion.insert({
    required String provider,
    this.lastAttemptAt = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : provider = Value(provider);
  static Insertable<ContentSyncStateRow> custom({
    Expression<String>? provider,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? lastSuccessAt,
    Expression<String>? lastError,
    Expression<int>? itemCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (provider != null) 'provider': provider,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastSuccessAt != null) 'last_success_at': lastSuccessAt,
      if (lastError != null) 'last_error': lastError,
      if (itemCount != null) 'item_count': itemCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentSyncStatesCompanion copyWith({
    Value<String>? provider,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime?>? lastSuccessAt,
    Value<String?>? lastError,
    Value<int>? itemCount,
    Value<int>? rowid,
  }) {
    return ContentSyncStatesCompanion(
      provider: provider ?? this.provider,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastError: lastError ?? this.lastError,
      itemCount: itemCount ?? this.itemCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (lastSuccessAt.present) {
      map['last_success_at'] = Variable<DateTime>(lastSuccessAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentSyncStatesCompanion(')
          ..write('provider: $provider, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('lastError: $lastError, ')
          ..write('itemCount: $itemCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaRow(
      key:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}key'],
          )!,
      value:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}value'],
          )!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaRow extends DataClass implements Insertable<AppMetaRow> {
  final String key;
  final String value;
  const AppMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(key: Value(key), value: Value(value));
  }

  factory AppMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppMetaRow copyWith({String? key, String? value}) =>
      AppMetaRow(key: key ?? this.key, value: value ?? this.value);
  AppMetaRow copyWithCompanion(AppMetaCompanion data) {
    return AppMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $MedicineDetailsTable medicineDetails = $MedicineDetailsTable(
    this,
  );
  late final $WaterSettingsTable waterSettings = $WaterSettingsTable(this);
  late final $MeditationSettingsTable meditationSettings =
      $MeditationSettingsTable(this);
  late final $ExerciseSettingsTable exerciseSettings = $ExerciseSettingsTable(
    this,
  );
  late final $HabitLogsTable habitLogs = $HabitLogsTable(this);
  late final $ContentItemsTable contentItems = $ContentItemsTable(this);
  late final $ContentSyncStatesTable contentSyncStates =
      $ContentSyncStatesTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    habits,
    medicineDetails,
    waterSettings,
    meditationSettings,
    exerciseSettings,
    habitLogs,
    contentItems,
    contentSyncStates,
    appMeta,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('medicine_details', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('water_settings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('meditation_settings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('exercise_settings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('habit_logs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$HabitsTableCreateCompanionBuilder =
    HabitsCompanion Function({
      required String id,
      required String name,
      required String category,
      Value<bool> enabled,
      Value<int> reminderHour,
      Value<int> reminderMinute,
      Value<List<String>> reminderTimes,
      Value<List<String>> oneTimeReminders,
      Value<int> streak,
      Value<DateTime?> lastCompletedAt,
      Value<int> sortOrder,
      Value<bool> archived,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$HabitsTableUpdateCompanionBuilder =
    HabitsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> category,
      Value<bool> enabled,
      Value<int> reminderHour,
      Value<int> reminderMinute,
      Value<List<String>> reminderTimes,
      Value<List<String>> oneTimeReminders,
      Value<int> streak,
      Value<DateTime?> lastCompletedAt,
      Value<int> sortOrder,
      Value<bool> archived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$HabitsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitsTable, HabitRow> {
  $$HabitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MedicineDetailsTable, List<MedicineDetailsRow>>
  _medicineDetailsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.medicineDetails,
    aliasName: $_aliasNameGenerator(db.habits.id, db.medicineDetails.habitId),
  );

  $$MedicineDetailsTableProcessedTableManager get medicineDetailsRefs {
    final manager = $$MedicineDetailsTableTableManager(
      $_db,
      $_db.medicineDetails,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _medicineDetailsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WaterSettingsTable, List<WaterSettingsRow>>
  _waterSettingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.waterSettings,
    aliasName: $_aliasNameGenerator(db.habits.id, db.waterSettings.habitId),
  );

  $$WaterSettingsTableProcessedTableManager get waterSettingsRefs {
    final manager = $$WaterSettingsTableTableManager(
      $_db,
      $_db.waterSettings,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_waterSettingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $MeditationSettingsTable,
    List<MeditationSettingsRow>
  >
  _meditationSettingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.meditationSettings,
        aliasName: $_aliasNameGenerator(
          db.habits.id,
          db.meditationSettings.habitId,
        ),
      );

  $$MeditationSettingsTableProcessedTableManager get meditationSettingsRefs {
    final manager = $$MeditationSettingsTableTableManager(
      $_db,
      $_db.meditationSettings,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _meditationSettingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExerciseSettingsTable, List<ExerciseSettingsRow>>
  _exerciseSettingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exerciseSettings,
    aliasName: $_aliasNameGenerator(db.habits.id, db.exerciseSettings.habitId),
  );

  $$ExerciseSettingsTableProcessedTableManager get exerciseSettingsRefs {
    final manager = $$ExerciseSettingsTableTableManager(
      $_db,
      $_db.exerciseSettings,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseSettingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HabitLogsTable, List<HabitLogRow>>
  _habitLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.habitLogs,
    aliasName: $_aliasNameGenerator(db.habits.id, db.habitLogs.habitId),
  );

  $$HabitLogsTableProcessedTableManager get habitLogsRefs {
    final manager = $$HabitLogsTableTableManager(
      $_db,
      $_db.habitLogs,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HabitsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get reminderTimes => $composableBuilder(
    column: $table.reminderTimes,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get oneTimeReminders => $composableBuilder(
    column: $table.oneTimeReminders,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get streak => $composableBuilder(
    column: $table.streak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCompletedAt => $composableBuilder(
    column: $table.lastCompletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> medicineDetailsRefs(
    Expression<bool> Function($$MedicineDetailsTableFilterComposer f) f,
  ) {
    final $$MedicineDetailsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medicineDetails,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicineDetailsTableFilterComposer(
            $db: $db,
            $table: $db.medicineDetails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> waterSettingsRefs(
    Expression<bool> Function($$WaterSettingsTableFilterComposer f) f,
  ) {
    final $$WaterSettingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.waterSettings,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WaterSettingsTableFilterComposer(
            $db: $db,
            $table: $db.waterSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> meditationSettingsRefs(
    Expression<bool> Function($$MeditationSettingsTableFilterComposer f) f,
  ) {
    final $$MeditationSettingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.meditationSettings,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MeditationSettingsTableFilterComposer(
            $db: $db,
            $table: $db.meditationSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exerciseSettingsRefs(
    Expression<bool> Function($$ExerciseSettingsTableFilterComposer f) f,
  ) {
    final $$ExerciseSettingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseSettings,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseSettingsTableFilterComposer(
            $db: $db,
            $table: $db.exerciseSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> habitLogsRefs(
    Expression<bool> Function($$HabitLogsTableFilterComposer f) f,
  ) {
    final $$HabitLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitLogs,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitLogsTableFilterComposer(
            $db: $db,
            $table: $db.habitLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTimes => $composableBuilder(
    column: $table.reminderTimes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oneTimeReminders => $composableBuilder(
    column: $table.oneTimeReminders,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streak => $composableBuilder(
    column: $table.streak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCompletedAt => $composableBuilder(
    column: $table.lastCompletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get reminderTimes =>
      $composableBuilder(
        column: $table.reminderTimes,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<List<String>, String> get oneTimeReminders =>
      $composableBuilder(
        column: $table.oneTimeReminders,
        builder: (column) => column,
      );

  GeneratedColumn<int> get streak =>
      $composableBuilder(column: $table.streak, builder: (column) => column);

  GeneratedColumn<DateTime> get lastCompletedAt => $composableBuilder(
    column: $table.lastCompletedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> medicineDetailsRefs<T extends Object>(
    Expression<T> Function($$MedicineDetailsTableAnnotationComposer a) f,
  ) {
    final $$MedicineDetailsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.medicineDetails,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicineDetailsTableAnnotationComposer(
            $db: $db,
            $table: $db.medicineDetails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> waterSettingsRefs<T extends Object>(
    Expression<T> Function($$WaterSettingsTableAnnotationComposer a) f,
  ) {
    final $$WaterSettingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.waterSettings,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WaterSettingsTableAnnotationComposer(
            $db: $db,
            $table: $db.waterSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> meditationSettingsRefs<T extends Object>(
    Expression<T> Function($$MeditationSettingsTableAnnotationComposer a) f,
  ) {
    final $$MeditationSettingsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.meditationSettings,
          getReferencedColumn: (t) => t.habitId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MeditationSettingsTableAnnotationComposer(
                $db: $db,
                $table: $db.meditationSettings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> exerciseSettingsRefs<T extends Object>(
    Expression<T> Function($$ExerciseSettingsTableAnnotationComposer a) f,
  ) {
    final $$ExerciseSettingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseSettings,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseSettingsTableAnnotationComposer(
            $db: $db,
            $table: $db.exerciseSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> habitLogsRefs<T extends Object>(
    Expression<T> Function($$HabitLogsTableAnnotationComposer a) f,
  ) {
    final $$HabitLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitLogs,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.habitLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTable,
          HabitRow,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (HabitRow, $$HabitsTableReferences),
          HabitRow,
          PrefetchHooks Function({
            bool medicineDetailsRefs,
            bool waterSettingsRefs,
            bool meditationSettingsRefs,
            bool exerciseSettingsRefs,
            bool habitLogsRefs,
          })
        > {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<List<String>> reminderTimes = const Value.absent(),
                Value<List<String>> oneTimeReminders = const Value.absent(),
                Value<int> streak = const Value.absent(),
                Value<DateTime?> lastCompletedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                name: name,
                category: category,
                enabled: enabled,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                reminderTimes: reminderTimes,
                oneTimeReminders: oneTimeReminders,
                streak: streak,
                lastCompletedAt: lastCompletedAt,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String category,
                Value<bool> enabled = const Value.absent(),
                Value<int> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<List<String>> reminderTimes = const Value.absent(),
                Value<List<String>> oneTimeReminders = const Value.absent(),
                Value<int> streak = const Value.absent(),
                Value<DateTime?> lastCompletedAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => HabitsCompanion.insert(
                id: id,
                name: name,
                category: category,
                enabled: enabled,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                reminderTimes: reminderTimes,
                oneTimeReminders: oneTimeReminders,
                streak: streak,
                lastCompletedAt: lastCompletedAt,
                sortOrder: sortOrder,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$HabitsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({
            medicineDetailsRefs = false,
            waterSettingsRefs = false,
            meditationSettingsRefs = false,
            exerciseSettingsRefs = false,
            habitLogsRefs = false,
          }) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (medicineDetailsRefs) db.medicineDetails,
                if (waterSettingsRefs) db.waterSettings,
                if (meditationSettingsRefs) db.meditationSettings,
                if (exerciseSettingsRefs) db.exerciseSettings,
                if (habitLogsRefs) db.habitLogs,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (medicineDetailsRefs)
                    await $_getPrefetchedData<
                      HabitRow,
                      $HabitsTable,
                      MedicineDetailsRow
                    >(
                      currentTable: table,
                      referencedTable: $$HabitsTableReferences
                          ._medicineDetailsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$HabitsTableReferences(
                                db,
                                table,
                                p0,
                              ).medicineDetailsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.habitId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (waterSettingsRefs)
                    await $_getPrefetchedData<
                      HabitRow,
                      $HabitsTable,
                      WaterSettingsRow
                    >(
                      currentTable: table,
                      referencedTable: $$HabitsTableReferences
                          ._waterSettingsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$HabitsTableReferences(
                                db,
                                table,
                                p0,
                              ).waterSettingsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.habitId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (meditationSettingsRefs)
                    await $_getPrefetchedData<
                      HabitRow,
                      $HabitsTable,
                      MeditationSettingsRow
                    >(
                      currentTable: table,
                      referencedTable: $$HabitsTableReferences
                          ._meditationSettingsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$HabitsTableReferences(
                                db,
                                table,
                                p0,
                              ).meditationSettingsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.habitId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (exerciseSettingsRefs)
                    await $_getPrefetchedData<
                      HabitRow,
                      $HabitsTable,
                      ExerciseSettingsRow
                    >(
                      currentTable: table,
                      referencedTable: $$HabitsTableReferences
                          ._exerciseSettingsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$HabitsTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseSettingsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.habitId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (habitLogsRefs)
                    await $_getPrefetchedData<
                      HabitRow,
                      $HabitsTable,
                      HabitLogRow
                    >(
                      currentTable: table,
                      referencedTable: $$HabitsTableReferences
                          ._habitLogsRefsTable(db),
                      managerFromTypedResult:
                          (p0) =>
                              $$HabitsTableReferences(
                                db,
                                table,
                                p0,
                              ).habitLogsRefs,
                      referencedItemsForCurrentItem:
                          (item, referencedItems) => referencedItems.where(
                            (e) => e.habitId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTable,
      HabitRow,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (HabitRow, $$HabitsTableReferences),
      HabitRow,
      PrefetchHooks Function({
        bool medicineDetailsRefs,
        bool waterSettingsRefs,
        bool meditationSettingsRefs,
        bool exerciseSettingsRefs,
        bool habitLogsRefs,
      })
    >;
typedef $$MedicineDetailsTableCreateCompanionBuilder =
    MedicineDetailsCompanion Function({
      required String habitId,
      Value<String?> medicineName,
      Value<String?> dose,
      Value<String?> notes,
      Value<String?> startDate,
      Value<String?> endDate,
      Value<int> rowid,
    });
typedef $$MedicineDetailsTableUpdateCompanionBuilder =
    MedicineDetailsCompanion Function({
      Value<String> habitId,
      Value<String?> medicineName,
      Value<String?> dose,
      Value<String?> notes,
      Value<String?> startDate,
      Value<String?> endDate,
      Value<int> rowid,
    });

final class $$MedicineDetailsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MedicineDetailsTable,
          MedicineDetailsRow
        > {
  $$MedicineDetailsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HabitsTable _habitIdTable(_$AppDatabase db) => db.habits.createAlias(
    $_aliasNameGenerator(db.medicineDetails.habitId, db.habits.id),
  );

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MedicineDetailsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicineDetailsTable> {
  $$MedicineDetailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get medicineName => $composableBuilder(
    column: $table.medicineName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dose => $composableBuilder(
    column: $table.dose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MedicineDetailsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicineDetailsTable> {
  $$MedicineDetailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get medicineName => $composableBuilder(
    column: $table.medicineName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dose => $composableBuilder(
    column: $table.dose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MedicineDetailsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicineDetailsTable> {
  $$MedicineDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get medicineName => $composableBuilder(
    column: $table.medicineName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dose =>
      $composableBuilder(column: $table.dose, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MedicineDetailsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicineDetailsTable,
          MedicineDetailsRow,
          $$MedicineDetailsTableFilterComposer,
          $$MedicineDetailsTableOrderingComposer,
          $$MedicineDetailsTableAnnotationComposer,
          $$MedicineDetailsTableCreateCompanionBuilder,
          $$MedicineDetailsTableUpdateCompanionBuilder,
          (MedicineDetailsRow, $$MedicineDetailsTableReferences),
          MedicineDetailsRow,
          PrefetchHooks Function({bool habitId})
        > {
  $$MedicineDetailsTableTableManager(
    _$AppDatabase db,
    $MedicineDetailsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$MedicineDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$MedicineDetailsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$MedicineDetailsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> habitId = const Value.absent(),
                Value<String?> medicineName = const Value.absent(),
                Value<String?> dose = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicineDetailsCompanion(
                habitId: habitId,
                medicineName: medicineName,
                dose: dose,
                notes: notes,
                startDate: startDate,
                endDate: endDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String habitId,
                Value<String?> medicineName = const Value.absent(),
                Value<String?> dose = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicineDetailsCompanion.insert(
                habitId: habitId,
                medicineName: medicineName,
                dose: dose,
                notes: notes,
                startDate: startDate,
                endDate: endDate,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$MedicineDetailsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (habitId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.habitId,
                            referencedTable: $$MedicineDetailsTableReferences
                                ._habitIdTable(db),
                            referencedColumn:
                                $$MedicineDetailsTableReferences
                                    ._habitIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MedicineDetailsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicineDetailsTable,
      MedicineDetailsRow,
      $$MedicineDetailsTableFilterComposer,
      $$MedicineDetailsTableOrderingComposer,
      $$MedicineDetailsTableAnnotationComposer,
      $$MedicineDetailsTableCreateCompanionBuilder,
      $$MedicineDetailsTableUpdateCompanionBuilder,
      (MedicineDetailsRow, $$MedicineDetailsTableReferences),
      MedicineDetailsRow,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$WaterSettingsTableCreateCompanionBuilder =
    WaterSettingsCompanion Function({
      required String habitId,
      Value<int?> targetGlasses,
      Value<int> rowid,
    });
typedef $$WaterSettingsTableUpdateCompanionBuilder =
    WaterSettingsCompanion Function({
      Value<String> habitId,
      Value<int?> targetGlasses,
      Value<int> rowid,
    });

final class $$WaterSettingsTableReferences
    extends
        BaseReferences<_$AppDatabase, $WaterSettingsTable, WaterSettingsRow> {
  $$WaterSettingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HabitsTable _habitIdTable(_$AppDatabase db) => db.habits.createAlias(
    $_aliasNameGenerator(db.waterSettings.habitId, db.habits.id),
  );

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WaterSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $WaterSettingsTable> {
  $$WaterSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get targetGlasses => $composableBuilder(
    column: $table.targetGlasses,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WaterSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $WaterSettingsTable> {
  $$WaterSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get targetGlasses => $composableBuilder(
    column: $table.targetGlasses,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WaterSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaterSettingsTable> {
  $$WaterSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get targetGlasses => $composableBuilder(
    column: $table.targetGlasses,
    builder: (column) => column,
  );

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WaterSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaterSettingsTable,
          WaterSettingsRow,
          $$WaterSettingsTableFilterComposer,
          $$WaterSettingsTableOrderingComposer,
          $$WaterSettingsTableAnnotationComposer,
          $$WaterSettingsTableCreateCompanionBuilder,
          $$WaterSettingsTableUpdateCompanionBuilder,
          (WaterSettingsRow, $$WaterSettingsTableReferences),
          WaterSettingsRow,
          PrefetchHooks Function({bool habitId})
        > {
  $$WaterSettingsTableTableManager(_$AppDatabase db, $WaterSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$WaterSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$WaterSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$WaterSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> habitId = const Value.absent(),
                Value<int?> targetGlasses = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WaterSettingsCompanion(
                habitId: habitId,
                targetGlasses: targetGlasses,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String habitId,
                Value<int?> targetGlasses = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WaterSettingsCompanion.insert(
                habitId: habitId,
                targetGlasses: targetGlasses,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$WaterSettingsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (habitId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.habitId,
                            referencedTable: $$WaterSettingsTableReferences
                                ._habitIdTable(db),
                            referencedColumn:
                                $$WaterSettingsTableReferences
                                    ._habitIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WaterSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaterSettingsTable,
      WaterSettingsRow,
      $$WaterSettingsTableFilterComposer,
      $$WaterSettingsTableOrderingComposer,
      $$WaterSettingsTableAnnotationComposer,
      $$WaterSettingsTableCreateCompanionBuilder,
      $$WaterSettingsTableUpdateCompanionBuilder,
      (WaterSettingsRow, $$WaterSettingsTableReferences),
      WaterSettingsRow,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$MeditationSettingsTableCreateCompanionBuilder =
    MeditationSettingsCompanion Function({
      required String habitId,
      Value<int?> goalMinutes,
      Value<int> rowid,
    });
typedef $$MeditationSettingsTableUpdateCompanionBuilder =
    MeditationSettingsCompanion Function({
      Value<String> habitId,
      Value<int?> goalMinutes,
      Value<int> rowid,
    });

final class $$MeditationSettingsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MeditationSettingsTable,
          MeditationSettingsRow
        > {
  $$MeditationSettingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HabitsTable _habitIdTable(_$AppDatabase db) => db.habits.createAlias(
    $_aliasNameGenerator(db.meditationSettings.habitId, db.habits.id),
  );

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MeditationSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $MeditationSettingsTable> {
  $$MeditationSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get goalMinutes => $composableBuilder(
    column: $table.goalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MeditationSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $MeditationSettingsTable> {
  $$MeditationSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get goalMinutes => $composableBuilder(
    column: $table.goalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MeditationSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MeditationSettingsTable> {
  $$MeditationSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get goalMinutes => $composableBuilder(
    column: $table.goalMinutes,
    builder: (column) => column,
  );

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MeditationSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MeditationSettingsTable,
          MeditationSettingsRow,
          $$MeditationSettingsTableFilterComposer,
          $$MeditationSettingsTableOrderingComposer,
          $$MeditationSettingsTableAnnotationComposer,
          $$MeditationSettingsTableCreateCompanionBuilder,
          $$MeditationSettingsTableUpdateCompanionBuilder,
          (MeditationSettingsRow, $$MeditationSettingsTableReferences),
          MeditationSettingsRow,
          PrefetchHooks Function({bool habitId})
        > {
  $$MeditationSettingsTableTableManager(
    _$AppDatabase db,
    $MeditationSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$MeditationSettingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$MeditationSettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$MeditationSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> habitId = const Value.absent(),
                Value<int?> goalMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeditationSettingsCompanion(
                habitId: habitId,
                goalMinutes: goalMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String habitId,
                Value<int?> goalMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MeditationSettingsCompanion.insert(
                habitId: habitId,
                goalMinutes: goalMinutes,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$MeditationSettingsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (habitId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.habitId,
                            referencedTable: $$MeditationSettingsTableReferences
                                ._habitIdTable(db),
                            referencedColumn:
                                $$MeditationSettingsTableReferences
                                    ._habitIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MeditationSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MeditationSettingsTable,
      MeditationSettingsRow,
      $$MeditationSettingsTableFilterComposer,
      $$MeditationSettingsTableOrderingComposer,
      $$MeditationSettingsTableAnnotationComposer,
      $$MeditationSettingsTableCreateCompanionBuilder,
      $$MeditationSettingsTableUpdateCompanionBuilder,
      (MeditationSettingsRow, $$MeditationSettingsTableReferences),
      MeditationSettingsRow,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$ExerciseSettingsTableCreateCompanionBuilder =
    ExerciseSettingsCompanion Function({
      required String habitId,
      Value<int?> goalMinutes,
      Value<int?> stepsGoal,
      Value<int?> walkEveryMinutes,
      Value<int?> stretchEveryMinutes,
      Value<String?> weekPlanJson,
      Value<String?> milestonesJson,
      Value<int> rowid,
    });
typedef $$ExerciseSettingsTableUpdateCompanionBuilder =
    ExerciseSettingsCompanion Function({
      Value<String> habitId,
      Value<int?> goalMinutes,
      Value<int?> stepsGoal,
      Value<int?> walkEveryMinutes,
      Value<int?> stretchEveryMinutes,
      Value<String?> weekPlanJson,
      Value<String?> milestonesJson,
      Value<int> rowid,
    });

final class $$ExerciseSettingsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ExerciseSettingsTable,
          ExerciseSettingsRow
        > {
  $$ExerciseSettingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HabitsTable _habitIdTable(_$AppDatabase db) => db.habits.createAlias(
    $_aliasNameGenerator(db.exerciseSettings.habitId, db.habits.id),
  );

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExerciseSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseSettingsTable> {
  $$ExerciseSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get goalMinutes => $composableBuilder(
    column: $table.goalMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stepsGoal => $composableBuilder(
    column: $table.stepsGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get walkEveryMinutes => $composableBuilder(
    column: $table.walkEveryMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stretchEveryMinutes => $composableBuilder(
    column: $table.stretchEveryMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weekPlanJson => $composableBuilder(
    column: $table.weekPlanJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get milestonesJson => $composableBuilder(
    column: $table.milestonesJson,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseSettingsTable> {
  $$ExerciseSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get goalMinutes => $composableBuilder(
    column: $table.goalMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stepsGoal => $composableBuilder(
    column: $table.stepsGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get walkEveryMinutes => $composableBuilder(
    column: $table.walkEveryMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stretchEveryMinutes => $composableBuilder(
    column: $table.stretchEveryMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekPlanJson => $composableBuilder(
    column: $table.weekPlanJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get milestonesJson => $composableBuilder(
    column: $table.milestonesJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseSettingsTable> {
  $$ExerciseSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get goalMinutes => $composableBuilder(
    column: $table.goalMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stepsGoal =>
      $composableBuilder(column: $table.stepsGoal, builder: (column) => column);

  GeneratedColumn<int> get walkEveryMinutes => $composableBuilder(
    column: $table.walkEveryMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stretchEveryMinutes => $composableBuilder(
    column: $table.stretchEveryMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weekPlanJson => $composableBuilder(
    column: $table.weekPlanJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get milestonesJson => $composableBuilder(
    column: $table.milestonesJson,
    builder: (column) => column,
  );

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseSettingsTable,
          ExerciseSettingsRow,
          $$ExerciseSettingsTableFilterComposer,
          $$ExerciseSettingsTableOrderingComposer,
          $$ExerciseSettingsTableAnnotationComposer,
          $$ExerciseSettingsTableCreateCompanionBuilder,
          $$ExerciseSettingsTableUpdateCompanionBuilder,
          (ExerciseSettingsRow, $$ExerciseSettingsTableReferences),
          ExerciseSettingsRow,
          PrefetchHooks Function({bool habitId})
        > {
  $$ExerciseSettingsTableTableManager(
    _$AppDatabase db,
    $ExerciseSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$ExerciseSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ExerciseSettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$ExerciseSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> habitId = const Value.absent(),
                Value<int?> goalMinutes = const Value.absent(),
                Value<int?> stepsGoal = const Value.absent(),
                Value<int?> walkEveryMinutes = const Value.absent(),
                Value<int?> stretchEveryMinutes = const Value.absent(),
                Value<String?> weekPlanJson = const Value.absent(),
                Value<String?> milestonesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseSettingsCompanion(
                habitId: habitId,
                goalMinutes: goalMinutes,
                stepsGoal: stepsGoal,
                walkEveryMinutes: walkEveryMinutes,
                stretchEveryMinutes: stretchEveryMinutes,
                weekPlanJson: weekPlanJson,
                milestonesJson: milestonesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String habitId,
                Value<int?> goalMinutes = const Value.absent(),
                Value<int?> stepsGoal = const Value.absent(),
                Value<int?> walkEveryMinutes = const Value.absent(),
                Value<int?> stretchEveryMinutes = const Value.absent(),
                Value<String?> weekPlanJson = const Value.absent(),
                Value<String?> milestonesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseSettingsCompanion.insert(
                habitId: habitId,
                goalMinutes: goalMinutes,
                stepsGoal: stepsGoal,
                walkEveryMinutes: walkEveryMinutes,
                stretchEveryMinutes: stretchEveryMinutes,
                weekPlanJson: weekPlanJson,
                milestonesJson: milestonesJson,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$ExerciseSettingsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (habitId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.habitId,
                            referencedTable: $$ExerciseSettingsTableReferences
                                ._habitIdTable(db),
                            referencedColumn:
                                $$ExerciseSettingsTableReferences
                                    ._habitIdTable(db)
                                    .id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExerciseSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseSettingsTable,
      ExerciseSettingsRow,
      $$ExerciseSettingsTableFilterComposer,
      $$ExerciseSettingsTableOrderingComposer,
      $$ExerciseSettingsTableAnnotationComposer,
      $$ExerciseSettingsTableCreateCompanionBuilder,
      $$ExerciseSettingsTableUpdateCompanionBuilder,
      (ExerciseSettingsRow, $$ExerciseSettingsTableReferences),
      ExerciseSettingsRow,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$HabitLogsTableCreateCompanionBuilder =
    HabitLogsCompanion Function({
      required String habitId,
      required String day,
      required String metric,
      Value<int?> value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$HabitLogsTableUpdateCompanionBuilder =
    HabitLogsCompanion Function({
      Value<String> habitId,
      Value<String> day,
      Value<String> metric,
      Value<int?> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$HabitLogsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitLogsTable, HabitLogRow> {
  $$HabitLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) => db.habits.createAlias(
    $_aliasNameGenerator(db.habitLogs.habitId, db.habits.id),
  );

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HabitLogsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metric => $composableBuilder(
    column: $table.metric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get metric =>
      $composableBuilder(column: $table.metric, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitLogsTable,
          HabitLogRow,
          $$HabitLogsTableFilterComposer,
          $$HabitLogsTableOrderingComposer,
          $$HabitLogsTableAnnotationComposer,
          $$HabitLogsTableCreateCompanionBuilder,
          $$HabitLogsTableUpdateCompanionBuilder,
          (HabitLogRow, $$HabitLogsTableReferences),
          HabitLogRow,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitLogsTableTableManager(_$AppDatabase db, $HabitLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$HabitLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$HabitLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$HabitLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> habitId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> metric = const Value.absent(),
                Value<int?> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitLogsCompanion(
                habitId: habitId,
                day: day,
                metric: metric,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String habitId,
                required String day,
                required String metric,
                Value<int?> value = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => HabitLogsCompanion.insert(
                habitId: habitId,
                day: day,
                metric: metric,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          $$HabitLogsTableReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                T extends TableManagerState<
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic,
                  dynamic
                >
              >(state) {
                if (habitId) {
                  state =
                      state.withJoin(
                            currentTable: table,
                            currentColumn: table.habitId,
                            referencedTable: $$HabitLogsTableReferences
                                ._habitIdTable(db),
                            referencedColumn:
                                $$HabitLogsTableReferences._habitIdTable(db).id,
                          )
                          as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HabitLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitLogsTable,
      HabitLogRow,
      $$HabitLogsTableFilterComposer,
      $$HabitLogsTableOrderingComposer,
      $$HabitLogsTableAnnotationComposer,
      $$HabitLogsTableCreateCompanionBuilder,
      $$HabitLogsTableUpdateCompanionBuilder,
      (HabitLogRow, $$HabitLogsTableReferences),
      HabitLogRow,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$ContentItemsTableCreateCompanionBuilder =
    ContentItemsCompanion Function({
      required String id,
      required String provider,
      required String kind,
      required String title,
      Value<String?> subtitle,
      Value<String?> description,
      Value<String?> mediaUrl,
      Value<String> mediaFormat,
      Value<String?> imageUrl,
      Value<String?> sourceUrl,
      required String license,
      Value<String?> licenseUrl,
      Value<String?> attribution,
      Value<List<String>> tags,
      Value<String?> language,
      Value<int?> durationSeconds,
      Value<int> popularity,
      required DateTime firstSeenAt,
      required DateTime lastSeenAt,
      Value<bool> seen,
      Value<int> rowid,
    });
typedef $$ContentItemsTableUpdateCompanionBuilder =
    ContentItemsCompanion Function({
      Value<String> id,
      Value<String> provider,
      Value<String> kind,
      Value<String> title,
      Value<String?> subtitle,
      Value<String?> description,
      Value<String?> mediaUrl,
      Value<String> mediaFormat,
      Value<String?> imageUrl,
      Value<String?> sourceUrl,
      Value<String> license,
      Value<String?> licenseUrl,
      Value<String?> attribution,
      Value<List<String>> tags,
      Value<String?> language,
      Value<int?> durationSeconds,
      Value<int> popularity,
      Value<DateTime> firstSeenAt,
      Value<DateTime> lastSeenAt,
      Value<bool> seen,
      Value<int> rowid,
    });

class $$ContentItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ContentItemsTable> {
  $$ContentItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaFormat => $composableBuilder(
    column: $table.mediaFormat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get license => $composableBuilder(
    column: $table.license,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get licenseUrl => $composableBuilder(
    column: $table.licenseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get tags =>
      $composableBuilder(
        column: $table.tags,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get popularity => $composableBuilder(
    column: $table.popularity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get seen => $composableBuilder(
    column: $table.seen,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContentItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContentItemsTable> {
  $$ContentItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaUrl => $composableBuilder(
    column: $table.mediaUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaFormat => $composableBuilder(
    column: $table.mediaFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get license => $composableBuilder(
    column: $table.license,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get licenseUrl => $composableBuilder(
    column: $table.licenseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get popularity => $composableBuilder(
    column: $table.popularity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get seen => $composableBuilder(
    column: $table.seen,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContentItemsTable> {
  $$ContentItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaUrl =>
      $composableBuilder(column: $table.mediaUrl, builder: (column) => column);

  GeneratedColumn<String> get mediaFormat => $composableBuilder(
    column: $table.mediaFormat,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get license =>
      $composableBuilder(column: $table.license, builder: (column) => column);

  GeneratedColumn<String> get licenseUrl => $composableBuilder(
    column: $table.licenseUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get popularity => $composableBuilder(
    column: $table.popularity,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get firstSeenAt => $composableBuilder(
    column: $table.firstSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get seen =>
      $composableBuilder(column: $table.seen, builder: (column) => column);
}

class $$ContentItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContentItemsTable,
          ContentItemRow,
          $$ContentItemsTableFilterComposer,
          $$ContentItemsTableOrderingComposer,
          $$ContentItemsTableAnnotationComposer,
          $$ContentItemsTableCreateCompanionBuilder,
          $$ContentItemsTableUpdateCompanionBuilder,
          (
            ContentItemRow,
            BaseReferences<_$AppDatabase, $ContentItemsTable, ContentItemRow>,
          ),
          ContentItemRow,
          PrefetchHooks Function()
        > {
  $$ContentItemsTableTableManager(_$AppDatabase db, $ContentItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ContentItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ContentItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$ContentItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> mediaUrl = const Value.absent(),
                Value<String> mediaFormat = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                Value<String> license = const Value.absent(),
                Value<String?> licenseUrl = const Value.absent(),
                Value<String?> attribution = const Value.absent(),
                Value<List<String>> tags = const Value.absent(),
                Value<String?> language = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<int> popularity = const Value.absent(),
                Value<DateTime> firstSeenAt = const Value.absent(),
                Value<DateTime> lastSeenAt = const Value.absent(),
                Value<bool> seen = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentItemsCompanion(
                id: id,
                provider: provider,
                kind: kind,
                title: title,
                subtitle: subtitle,
                description: description,
                mediaUrl: mediaUrl,
                mediaFormat: mediaFormat,
                imageUrl: imageUrl,
                sourceUrl: sourceUrl,
                license: license,
                licenseUrl: licenseUrl,
                attribution: attribution,
                tags: tags,
                language: language,
                durationSeconds: durationSeconds,
                popularity: popularity,
                firstSeenAt: firstSeenAt,
                lastSeenAt: lastSeenAt,
                seen: seen,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String provider,
                required String kind,
                required String title,
                Value<String?> subtitle = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> mediaUrl = const Value.absent(),
                Value<String> mediaFormat = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> sourceUrl = const Value.absent(),
                required String license,
                Value<String?> licenseUrl = const Value.absent(),
                Value<String?> attribution = const Value.absent(),
                Value<List<String>> tags = const Value.absent(),
                Value<String?> language = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<int> popularity = const Value.absent(),
                required DateTime firstSeenAt,
                required DateTime lastSeenAt,
                Value<bool> seen = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentItemsCompanion.insert(
                id: id,
                provider: provider,
                kind: kind,
                title: title,
                subtitle: subtitle,
                description: description,
                mediaUrl: mediaUrl,
                mediaFormat: mediaFormat,
                imageUrl: imageUrl,
                sourceUrl: sourceUrl,
                license: license,
                licenseUrl: licenseUrl,
                attribution: attribution,
                tags: tags,
                language: language,
                durationSeconds: durationSeconds,
                popularity: popularity,
                firstSeenAt: firstSeenAt,
                lastSeenAt: lastSeenAt,
                seen: seen,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContentItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContentItemsTable,
      ContentItemRow,
      $$ContentItemsTableFilterComposer,
      $$ContentItemsTableOrderingComposer,
      $$ContentItemsTableAnnotationComposer,
      $$ContentItemsTableCreateCompanionBuilder,
      $$ContentItemsTableUpdateCompanionBuilder,
      (
        ContentItemRow,
        BaseReferences<_$AppDatabase, $ContentItemsTable, ContentItemRow>,
      ),
      ContentItemRow,
      PrefetchHooks Function()
    >;
typedef $$ContentSyncStatesTableCreateCompanionBuilder =
    ContentSyncStatesCompanion Function({
      required String provider,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> lastSuccessAt,
      Value<String?> lastError,
      Value<int> itemCount,
      Value<int> rowid,
    });
typedef $$ContentSyncStatesTableUpdateCompanionBuilder =
    ContentSyncStatesCompanion Function({
      Value<String> provider,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> lastSuccessAt,
      Value<String?> lastError,
      Value<int> itemCount,
      Value<int> rowid,
    });

class $$ContentSyncStatesTableFilterComposer
    extends Composer<_$AppDatabase, $ContentSyncStatesTable> {
  $$ContentSyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContentSyncStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ContentSyncStatesTable> {
  $$ContentSyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContentSyncStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContentSyncStatesTable> {
  $$ContentSyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get itemCount =>
      $composableBuilder(column: $table.itemCount, builder: (column) => column);
}

class $$ContentSyncStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContentSyncStatesTable,
          ContentSyncStateRow,
          $$ContentSyncStatesTableFilterComposer,
          $$ContentSyncStatesTableOrderingComposer,
          $$ContentSyncStatesTableAnnotationComposer,
          $$ContentSyncStatesTableCreateCompanionBuilder,
          $$ContentSyncStatesTableUpdateCompanionBuilder,
          (
            ContentSyncStateRow,
            BaseReferences<
              _$AppDatabase,
              $ContentSyncStatesTable,
              ContentSyncStateRow
            >,
          ),
          ContentSyncStateRow,
          PrefetchHooks Function()
        > {
  $$ContentSyncStatesTableTableManager(
    _$AppDatabase db,
    $ContentSyncStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ContentSyncStatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$ContentSyncStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$ContentSyncStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> provider = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> lastSuccessAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentSyncStatesCompanion(
                provider: provider,
                lastAttemptAt: lastAttemptAt,
                lastSuccessAt: lastSuccessAt,
                lastError: lastError,
                itemCount: itemCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String provider,
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> lastSuccessAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentSyncStatesCompanion.insert(
                provider: provider,
                lastAttemptAt: lastAttemptAt,
                lastSuccessAt: lastSuccessAt,
                lastError: lastError,
                itemCount: itemCount,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContentSyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContentSyncStatesTable,
      ContentSyncStateRow,
      $$ContentSyncStatesTableFilterComposer,
      $$ContentSyncStatesTableOrderingComposer,
      $$ContentSyncStatesTableAnnotationComposer,
      $$ContentSyncStatesTableCreateCompanionBuilder,
      $$ContentSyncStatesTableUpdateCompanionBuilder,
      (
        ContentSyncStateRow,
        BaseReferences<
          _$AppDatabase,
          $ContentSyncStatesTable,
          ContentSyncStateRow
        >,
      ),
      ContentSyncStateRow,
      PrefetchHooks Function()
    >;
typedef $$AppMetaTableCreateCompanionBuilder =
    AppMetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppMetaTableUpdateCompanionBuilder =
    AppMetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetaTable,
          AppMetaRow,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (
            AppMetaRow,
            BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaRow>,
          ),
          AppMetaRow,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) =>
                  AppMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetaTable,
      AppMetaRow,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (AppMetaRow, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaRow>),
      AppMetaRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$MedicineDetailsTableTableManager get medicineDetails =>
      $$MedicineDetailsTableTableManager(_db, _db.medicineDetails);
  $$WaterSettingsTableTableManager get waterSettings =>
      $$WaterSettingsTableTableManager(_db, _db.waterSettings);
  $$MeditationSettingsTableTableManager get meditationSettings =>
      $$MeditationSettingsTableTableManager(_db, _db.meditationSettings);
  $$ExerciseSettingsTableTableManager get exerciseSettings =>
      $$ExerciseSettingsTableTableManager(_db, _db.exerciseSettings);
  $$HabitLogsTableTableManager get habitLogs =>
      $$HabitLogsTableTableManager(_db, _db.habitLogs);
  $$ContentItemsTableTableManager get contentItems =>
      $$ContentItemsTableTableManager(_db, _db.contentItems);
  $$ContentSyncStatesTableTableManager get contentSyncStates =>
      $$ContentSyncStatesTableTableManager(_db, _db.contentSyncStates);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
}
