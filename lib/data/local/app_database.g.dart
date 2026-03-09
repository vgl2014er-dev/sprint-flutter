// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PlayersTable extends Players with TableInfo<$PlayersTable, Player> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _eloMeta = const VerificationMeta('elo');
  @override
  late final GeneratedColumn<int> elo = GeneratedColumn<int>(
    'elo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _winsMeta = const VerificationMeta('wins');
  @override
  late final GeneratedColumn<int> wins = GeneratedColumn<int>(
    'wins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lossesMeta = const VerificationMeta('losses');
  @override
  late final GeneratedColumn<int> losses = GeneratedColumn<int>(
    'losses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _drawsMeta = const VerificationMeta('draws');
  @override
  late final GeneratedColumn<int> draws = GeneratedColumn<int>(
    'draws',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchesPlayedMeta = const VerificationMeta(
    'matchesPlayed',
  );
  @override
  late final GeneratedColumn<int> matchesPlayed = GeneratedColumn<int>(
    'matches_played',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    elo,
    wins,
    losses,
    draws,
    matchesPlayed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players';
  @override
  VerificationContext validateIntegrity(
    Insertable<Player> instance, {
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
    if (data.containsKey('elo')) {
      context.handle(
        _eloMeta,
        elo.isAcceptableOrUnknown(data['elo']!, _eloMeta),
      );
    } else if (isInserting) {
      context.missing(_eloMeta);
    }
    if (data.containsKey('wins')) {
      context.handle(
        _winsMeta,
        wins.isAcceptableOrUnknown(data['wins']!, _winsMeta),
      );
    } else if (isInserting) {
      context.missing(_winsMeta);
    }
    if (data.containsKey('losses')) {
      context.handle(
        _lossesMeta,
        losses.isAcceptableOrUnknown(data['losses']!, _lossesMeta),
      );
    } else if (isInserting) {
      context.missing(_lossesMeta);
    }
    if (data.containsKey('draws')) {
      context.handle(
        _drawsMeta,
        draws.isAcceptableOrUnknown(data['draws']!, _drawsMeta),
      );
    } else if (isInserting) {
      context.missing(_drawsMeta);
    }
    if (data.containsKey('matches_played')) {
      context.handle(
        _matchesPlayedMeta,
        matchesPlayed.isAcceptableOrUnknown(
          data['matches_played']!,
          _matchesPlayedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_matchesPlayedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Player map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Player(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      elo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elo'],
      )!,
      wins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wins'],
      )!,
      losses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}losses'],
      )!,
      draws: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}draws'],
      )!,
      matchesPlayed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}matches_played'],
      )!,
    );
  }

  @override
  $PlayersTable createAlias(String alias) {
    return $PlayersTable(attachedDatabase, alias);
  }
}

class Player extends DataClass implements Insertable<Player> {
  final String id;
  final String name;
  final int elo;
  final int wins;
  final int losses;
  final int draws;
  final int matchesPlayed;
  const Player({
    required this.id,
    required this.name,
    required this.elo,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.matchesPlayed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['elo'] = Variable<int>(elo);
    map['wins'] = Variable<int>(wins);
    map['losses'] = Variable<int>(losses);
    map['draws'] = Variable<int>(draws);
    map['matches_played'] = Variable<int>(matchesPlayed);
    return map;
  }

  PlayersCompanion toCompanion(bool nullToAbsent) {
    return PlayersCompanion(
      id: Value(id),
      name: Value(name),
      elo: Value(elo),
      wins: Value(wins),
      losses: Value(losses),
      draws: Value(draws),
      matchesPlayed: Value(matchesPlayed),
    );
  }

  factory Player.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Player(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      elo: serializer.fromJson<int>(json['elo']),
      wins: serializer.fromJson<int>(json['wins']),
      losses: serializer.fromJson<int>(json['losses']),
      draws: serializer.fromJson<int>(json['draws']),
      matchesPlayed: serializer.fromJson<int>(json['matchesPlayed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'elo': serializer.toJson<int>(elo),
      'wins': serializer.toJson<int>(wins),
      'losses': serializer.toJson<int>(losses),
      'draws': serializer.toJson<int>(draws),
      'matchesPlayed': serializer.toJson<int>(matchesPlayed),
    };
  }

  Player copyWith({
    String? id,
    String? name,
    int? elo,
    int? wins,
    int? losses,
    int? draws,
    int? matchesPlayed,
  }) => Player(
    id: id ?? this.id,
    name: name ?? this.name,
    elo: elo ?? this.elo,
    wins: wins ?? this.wins,
    losses: losses ?? this.losses,
    draws: draws ?? this.draws,
    matchesPlayed: matchesPlayed ?? this.matchesPlayed,
  );
  Player copyWithCompanion(PlayersCompanion data) {
    return Player(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      elo: data.elo.present ? data.elo.value : this.elo,
      wins: data.wins.present ? data.wins.value : this.wins,
      losses: data.losses.present ? data.losses.value : this.losses,
      draws: data.draws.present ? data.draws.value : this.draws,
      matchesPlayed: data.matchesPlayed.present
          ? data.matchesPlayed.value
          : this.matchesPlayed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Player(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('elo: $elo, ')
          ..write('wins: $wins, ')
          ..write('losses: $losses, ')
          ..write('draws: $draws, ')
          ..write('matchesPlayed: $matchesPlayed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, elo, wins, losses, draws, matchesPlayed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Player &&
          other.id == this.id &&
          other.name == this.name &&
          other.elo == this.elo &&
          other.wins == this.wins &&
          other.losses == this.losses &&
          other.draws == this.draws &&
          other.matchesPlayed == this.matchesPlayed);
}

class PlayersCompanion extends UpdateCompanion<Player> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> elo;
  final Value<int> wins;
  final Value<int> losses;
  final Value<int> draws;
  final Value<int> matchesPlayed;
  final Value<int> rowid;
  const PlayersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.elo = const Value.absent(),
    this.wins = const Value.absent(),
    this.losses = const Value.absent(),
    this.draws = const Value.absent(),
    this.matchesPlayed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayersCompanion.insert({
    required String id,
    required String name,
    required int elo,
    required int wins,
    required int losses,
    required int draws,
    required int matchesPlayed,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       elo = Value(elo),
       wins = Value(wins),
       losses = Value(losses),
       draws = Value(draws),
       matchesPlayed = Value(matchesPlayed);
  static Insertable<Player> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? elo,
    Expression<int>? wins,
    Expression<int>? losses,
    Expression<int>? draws,
    Expression<int>? matchesPlayed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (elo != null) 'elo': elo,
      if (wins != null) 'wins': wins,
      if (losses != null) 'losses': losses,
      if (draws != null) 'draws': draws,
      if (matchesPlayed != null) 'matches_played': matchesPlayed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? elo,
    Value<int>? wins,
    Value<int>? losses,
    Value<int>? draws,
    Value<int>? matchesPlayed,
    Value<int>? rowid,
  }) {
    return PlayersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      elo: elo ?? this.elo,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
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
    if (elo.present) {
      map['elo'] = Variable<int>(elo.value);
    }
    if (wins.present) {
      map['wins'] = Variable<int>(wins.value);
    }
    if (losses.present) {
      map['losses'] = Variable<int>(losses.value);
    }
    if (draws.present) {
      map['draws'] = Variable<int>(draws.value);
    }
    if (matchesPlayed.present) {
      map['matches_played'] = Variable<int>(matchesPlayed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('elo: $elo, ')
          ..write('wins: $wins, ')
          ..write('losses: $losses, ')
          ..write('draws: $draws, ')
          ..write('matchesPlayed: $matchesPlayed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MatchHistoryTable extends MatchHistory
    with TableInfo<$MatchHistoryTable, MatchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _p1IdMeta = const VerificationMeta('p1Id');
  @override
  late final GeneratedColumn<String> p1Id = GeneratedColumn<String>(
    'p1_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _p2IdMeta = const VerificationMeta('p2Id');
  @override
  late final GeneratedColumn<String> p2Id = GeneratedColumn<String>(
    'p2_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _p1NameMeta = const VerificationMeta('p1Name');
  @override
  late final GeneratedColumn<String> p1Name = GeneratedColumn<String>(
    'p1_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _p2NameMeta = const VerificationMeta('p2Name');
  @override
  late final GeneratedColumn<String> p2Name = GeneratedColumn<String>(
    'p2_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _p1EloBeforeMeta = const VerificationMeta(
    'p1EloBefore',
  );
  @override
  late final GeneratedColumn<int> p1EloBefore = GeneratedColumn<int>(
    'p1_elo_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _p2EloBeforeMeta = const VerificationMeta(
    'p2EloBefore',
  );
  @override
  late final GeneratedColumn<int> p2EloBefore = GeneratedColumn<int>(
    'p2_elo_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _p1EloAfterMeta = const VerificationMeta(
    'p1EloAfter',
  );
  @override
  late final GeneratedColumn<int> p1EloAfter = GeneratedColumn<int>(
    'p1_elo_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _p2EloAfterMeta = const VerificationMeta(
    'p2EloAfter',
  );
  @override
  late final GeneratedColumn<int> p2EloAfter = GeneratedColumn<int>(
    'p2_elo_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultMeta = const VerificationMeta('result');
  @override
  late final GeneratedColumn<String> result = GeneratedColumn<String>(
    'result',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    p1Id,
    p2Id,
    p1Name,
    p2Name,
    p1EloBefore,
    p2EloBefore,
    p1EloAfter,
    p2EloAfter,
    result,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'match_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<MatchHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('p1_id')) {
      context.handle(
        _p1IdMeta,
        p1Id.isAcceptableOrUnknown(data['p1_id']!, _p1IdMeta),
      );
    } else if (isInserting) {
      context.missing(_p1IdMeta);
    }
    if (data.containsKey('p2_id')) {
      context.handle(
        _p2IdMeta,
        p2Id.isAcceptableOrUnknown(data['p2_id']!, _p2IdMeta),
      );
    } else if (isInserting) {
      context.missing(_p2IdMeta);
    }
    if (data.containsKey('p1_name')) {
      context.handle(
        _p1NameMeta,
        p1Name.isAcceptableOrUnknown(data['p1_name']!, _p1NameMeta),
      );
    } else if (isInserting) {
      context.missing(_p1NameMeta);
    }
    if (data.containsKey('p2_name')) {
      context.handle(
        _p2NameMeta,
        p2Name.isAcceptableOrUnknown(data['p2_name']!, _p2NameMeta),
      );
    } else if (isInserting) {
      context.missing(_p2NameMeta);
    }
    if (data.containsKey('p1_elo_before')) {
      context.handle(
        _p1EloBeforeMeta,
        p1EloBefore.isAcceptableOrUnknown(
          data['p1_elo_before']!,
          _p1EloBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_p1EloBeforeMeta);
    }
    if (data.containsKey('p2_elo_before')) {
      context.handle(
        _p2EloBeforeMeta,
        p2EloBefore.isAcceptableOrUnknown(
          data['p2_elo_before']!,
          _p2EloBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_p2EloBeforeMeta);
    }
    if (data.containsKey('p1_elo_after')) {
      context.handle(
        _p1EloAfterMeta,
        p1EloAfter.isAcceptableOrUnknown(
          data['p1_elo_after']!,
          _p1EloAfterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_p1EloAfterMeta);
    }
    if (data.containsKey('p2_elo_after')) {
      context.handle(
        _p2EloAfterMeta,
        p2EloAfter.isAcceptableOrUnknown(
          data['p2_elo_after']!,
          _p2EloAfterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_p2EloAfterMeta);
    }
    if (data.containsKey('result')) {
      context.handle(
        _resultMeta,
        result.isAcceptableOrUnknown(data['result']!, _resultMeta),
      );
    } else if (isInserting) {
      context.missing(_resultMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MatchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatchHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      p1Id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}p1_id'],
      )!,
      p2Id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}p2_id'],
      )!,
      p1Name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}p1_name'],
      )!,
      p2Name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}p2_name'],
      )!,
      p1EloBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}p1_elo_before'],
      )!,
      p2EloBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}p2_elo_before'],
      )!,
      p1EloAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}p1_elo_after'],
      )!,
      p2EloAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}p2_elo_after'],
      )!,
      result: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $MatchHistoryTable createAlias(String alias) {
    return $MatchHistoryTable(attachedDatabase, alias);
  }
}

class MatchHistoryData extends DataClass
    implements Insertable<MatchHistoryData> {
  final String id;
  final String p1Id;
  final String p2Id;
  final String p1Name;
  final String p2Name;
  final int p1EloBefore;
  final int p2EloBefore;
  final int p1EloAfter;
  final int p2EloAfter;
  final String result;
  final int timestamp;
  const MatchHistoryData({
    required this.id,
    required this.p1Id,
    required this.p2Id,
    required this.p1Name,
    required this.p2Name,
    required this.p1EloBefore,
    required this.p2EloBefore,
    required this.p1EloAfter,
    required this.p2EloAfter,
    required this.result,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['p1_id'] = Variable<String>(p1Id);
    map['p2_id'] = Variable<String>(p2Id);
    map['p1_name'] = Variable<String>(p1Name);
    map['p2_name'] = Variable<String>(p2Name);
    map['p1_elo_before'] = Variable<int>(p1EloBefore);
    map['p2_elo_before'] = Variable<int>(p2EloBefore);
    map['p1_elo_after'] = Variable<int>(p1EloAfter);
    map['p2_elo_after'] = Variable<int>(p2EloAfter);
    map['result'] = Variable<String>(result);
    map['timestamp'] = Variable<int>(timestamp);
    return map;
  }

  MatchHistoryCompanion toCompanion(bool nullToAbsent) {
    return MatchHistoryCompanion(
      id: Value(id),
      p1Id: Value(p1Id),
      p2Id: Value(p2Id),
      p1Name: Value(p1Name),
      p2Name: Value(p2Name),
      p1EloBefore: Value(p1EloBefore),
      p2EloBefore: Value(p2EloBefore),
      p1EloAfter: Value(p1EloAfter),
      p2EloAfter: Value(p2EloAfter),
      result: Value(result),
      timestamp: Value(timestamp),
    );
  }

  factory MatchHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatchHistoryData(
      id: serializer.fromJson<String>(json['id']),
      p1Id: serializer.fromJson<String>(json['p1Id']),
      p2Id: serializer.fromJson<String>(json['p2Id']),
      p1Name: serializer.fromJson<String>(json['p1Name']),
      p2Name: serializer.fromJson<String>(json['p2Name']),
      p1EloBefore: serializer.fromJson<int>(json['p1EloBefore']),
      p2EloBefore: serializer.fromJson<int>(json['p2EloBefore']),
      p1EloAfter: serializer.fromJson<int>(json['p1EloAfter']),
      p2EloAfter: serializer.fromJson<int>(json['p2EloAfter']),
      result: serializer.fromJson<String>(json['result']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'p1Id': serializer.toJson<String>(p1Id),
      'p2Id': serializer.toJson<String>(p2Id),
      'p1Name': serializer.toJson<String>(p1Name),
      'p2Name': serializer.toJson<String>(p2Name),
      'p1EloBefore': serializer.toJson<int>(p1EloBefore),
      'p2EloBefore': serializer.toJson<int>(p2EloBefore),
      'p1EloAfter': serializer.toJson<int>(p1EloAfter),
      'p2EloAfter': serializer.toJson<int>(p2EloAfter),
      'result': serializer.toJson<String>(result),
      'timestamp': serializer.toJson<int>(timestamp),
    };
  }

  MatchHistoryData copyWith({
    String? id,
    String? p1Id,
    String? p2Id,
    String? p1Name,
    String? p2Name,
    int? p1EloBefore,
    int? p2EloBefore,
    int? p1EloAfter,
    int? p2EloAfter,
    String? result,
    int? timestamp,
  }) => MatchHistoryData(
    id: id ?? this.id,
    p1Id: p1Id ?? this.p1Id,
    p2Id: p2Id ?? this.p2Id,
    p1Name: p1Name ?? this.p1Name,
    p2Name: p2Name ?? this.p2Name,
    p1EloBefore: p1EloBefore ?? this.p1EloBefore,
    p2EloBefore: p2EloBefore ?? this.p2EloBefore,
    p1EloAfter: p1EloAfter ?? this.p1EloAfter,
    p2EloAfter: p2EloAfter ?? this.p2EloAfter,
    result: result ?? this.result,
    timestamp: timestamp ?? this.timestamp,
  );
  MatchHistoryData copyWithCompanion(MatchHistoryCompanion data) {
    return MatchHistoryData(
      id: data.id.present ? data.id.value : this.id,
      p1Id: data.p1Id.present ? data.p1Id.value : this.p1Id,
      p2Id: data.p2Id.present ? data.p2Id.value : this.p2Id,
      p1Name: data.p1Name.present ? data.p1Name.value : this.p1Name,
      p2Name: data.p2Name.present ? data.p2Name.value : this.p2Name,
      p1EloBefore: data.p1EloBefore.present
          ? data.p1EloBefore.value
          : this.p1EloBefore,
      p2EloBefore: data.p2EloBefore.present
          ? data.p2EloBefore.value
          : this.p2EloBefore,
      p1EloAfter: data.p1EloAfter.present
          ? data.p1EloAfter.value
          : this.p1EloAfter,
      p2EloAfter: data.p2EloAfter.present
          ? data.p2EloAfter.value
          : this.p2EloAfter,
      result: data.result.present ? data.result.value : this.result,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatchHistoryData(')
          ..write('id: $id, ')
          ..write('p1Id: $p1Id, ')
          ..write('p2Id: $p2Id, ')
          ..write('p1Name: $p1Name, ')
          ..write('p2Name: $p2Name, ')
          ..write('p1EloBefore: $p1EloBefore, ')
          ..write('p2EloBefore: $p2EloBefore, ')
          ..write('p1EloAfter: $p1EloAfter, ')
          ..write('p2EloAfter: $p2EloAfter, ')
          ..write('result: $result, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    p1Id,
    p2Id,
    p1Name,
    p2Name,
    p1EloBefore,
    p2EloBefore,
    p1EloAfter,
    p2EloAfter,
    result,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatchHistoryData &&
          other.id == this.id &&
          other.p1Id == this.p1Id &&
          other.p2Id == this.p2Id &&
          other.p1Name == this.p1Name &&
          other.p2Name == this.p2Name &&
          other.p1EloBefore == this.p1EloBefore &&
          other.p2EloBefore == this.p2EloBefore &&
          other.p1EloAfter == this.p1EloAfter &&
          other.p2EloAfter == this.p2EloAfter &&
          other.result == this.result &&
          other.timestamp == this.timestamp);
}

class MatchHistoryCompanion extends UpdateCompanion<MatchHistoryData> {
  final Value<String> id;
  final Value<String> p1Id;
  final Value<String> p2Id;
  final Value<String> p1Name;
  final Value<String> p2Name;
  final Value<int> p1EloBefore;
  final Value<int> p2EloBefore;
  final Value<int> p1EloAfter;
  final Value<int> p2EloAfter;
  final Value<String> result;
  final Value<int> timestamp;
  final Value<int> rowid;
  const MatchHistoryCompanion({
    this.id = const Value.absent(),
    this.p1Id = const Value.absent(),
    this.p2Id = const Value.absent(),
    this.p1Name = const Value.absent(),
    this.p2Name = const Value.absent(),
    this.p1EloBefore = const Value.absent(),
    this.p2EloBefore = const Value.absent(),
    this.p1EloAfter = const Value.absent(),
    this.p2EloAfter = const Value.absent(),
    this.result = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatchHistoryCompanion.insert({
    required String id,
    required String p1Id,
    required String p2Id,
    required String p1Name,
    required String p2Name,
    required int p1EloBefore,
    required int p2EloBefore,
    required int p1EloAfter,
    required int p2EloAfter,
    required String result,
    required int timestamp,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       p1Id = Value(p1Id),
       p2Id = Value(p2Id),
       p1Name = Value(p1Name),
       p2Name = Value(p2Name),
       p1EloBefore = Value(p1EloBefore),
       p2EloBefore = Value(p2EloBefore),
       p1EloAfter = Value(p1EloAfter),
       p2EloAfter = Value(p2EloAfter),
       result = Value(result),
       timestamp = Value(timestamp);
  static Insertable<MatchHistoryData> custom({
    Expression<String>? id,
    Expression<String>? p1Id,
    Expression<String>? p2Id,
    Expression<String>? p1Name,
    Expression<String>? p2Name,
    Expression<int>? p1EloBefore,
    Expression<int>? p2EloBefore,
    Expression<int>? p1EloAfter,
    Expression<int>? p2EloAfter,
    Expression<String>? result,
    Expression<int>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (p1Id != null) 'p1_id': p1Id,
      if (p2Id != null) 'p2_id': p2Id,
      if (p1Name != null) 'p1_name': p1Name,
      if (p2Name != null) 'p2_name': p2Name,
      if (p1EloBefore != null) 'p1_elo_before': p1EloBefore,
      if (p2EloBefore != null) 'p2_elo_before': p2EloBefore,
      if (p1EloAfter != null) 'p1_elo_after': p1EloAfter,
      if (p2EloAfter != null) 'p2_elo_after': p2EloAfter,
      if (result != null) 'result': result,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatchHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? p1Id,
    Value<String>? p2Id,
    Value<String>? p1Name,
    Value<String>? p2Name,
    Value<int>? p1EloBefore,
    Value<int>? p2EloBefore,
    Value<int>? p1EloAfter,
    Value<int>? p2EloAfter,
    Value<String>? result,
    Value<int>? timestamp,
    Value<int>? rowid,
  }) {
    return MatchHistoryCompanion(
      id: id ?? this.id,
      p1Id: p1Id ?? this.p1Id,
      p2Id: p2Id ?? this.p2Id,
      p1Name: p1Name ?? this.p1Name,
      p2Name: p2Name ?? this.p2Name,
      p1EloBefore: p1EloBefore ?? this.p1EloBefore,
      p2EloBefore: p2EloBefore ?? this.p2EloBefore,
      p1EloAfter: p1EloAfter ?? this.p1EloAfter,
      p2EloAfter: p2EloAfter ?? this.p2EloAfter,
      result: result ?? this.result,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (p1Id.present) {
      map['p1_id'] = Variable<String>(p1Id.value);
    }
    if (p2Id.present) {
      map['p2_id'] = Variable<String>(p2Id.value);
    }
    if (p1Name.present) {
      map['p1_name'] = Variable<String>(p1Name.value);
    }
    if (p2Name.present) {
      map['p2_name'] = Variable<String>(p2Name.value);
    }
    if (p1EloBefore.present) {
      map['p1_elo_before'] = Variable<int>(p1EloBefore.value);
    }
    if (p2EloBefore.present) {
      map['p2_elo_before'] = Variable<int>(p2EloBefore.value);
    }
    if (p1EloAfter.present) {
      map['p1_elo_after'] = Variable<int>(p1EloAfter.value);
    }
    if (p2EloAfter.present) {
      map['p2_elo_after'] = Variable<int>(p2EloAfter.value);
    }
    if (result.present) {
      map['result'] = Variable<String>(result.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchHistoryCompanion(')
          ..write('id: $id, ')
          ..write('p1Id: $p1Id, ')
          ..write('p2Id: $p2Id, ')
          ..write('p1Name: $p1Name, ')
          ..write('p2Name: $p2Name, ')
          ..write('p1EloBefore: $p1EloBefore, ')
          ..write('p2EloBefore: $p2EloBefore, ')
          ..write('p1EloAfter: $p1EloAfter, ')
          ..write('p2EloAfter: $p2EloAfter, ')
          ..write('result: $result, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
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
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
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

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
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
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
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

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
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
    return (StringBuffer('AppSettingsCompanion(')
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
  late final $PlayersTable players = $PlayersTable(this);
  late final $MatchHistoryTable matchHistory = $MatchHistoryTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    players,
    matchHistory,
    appSettings,
  ];
}

typedef $$PlayersTableCreateCompanionBuilder =
    PlayersCompanion Function({
      required String id,
      required String name,
      required int elo,
      required int wins,
      required int losses,
      required int draws,
      required int matchesPlayed,
      Value<int> rowid,
    });
typedef $$PlayersTableUpdateCompanionBuilder =
    PlayersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> elo,
      Value<int> wins,
      Value<int> losses,
      Value<int> draws,
      Value<int> matchesPlayed,
      Value<int> rowid,
    });

class $$PlayersTableFilterComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableFilterComposer({
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

  ColumnFilters<int> get elo => $composableBuilder(
    column: $table.elo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wins => $composableBuilder(
    column: $table.wins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get losses => $composableBuilder(
    column: $table.losses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get draws => $composableBuilder(
    column: $table.draws,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get matchesPlayed => $composableBuilder(
    column: $table.matchesPlayed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableOrderingComposer({
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

  ColumnOrderings<int> get elo => $composableBuilder(
    column: $table.elo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wins => $composableBuilder(
    column: $table.wins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get losses => $composableBuilder(
    column: $table.losses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get draws => $composableBuilder(
    column: $table.draws,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get matchesPlayed => $composableBuilder(
    column: $table.matchesPlayed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableAnnotationComposer({
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

  GeneratedColumn<int> get elo =>
      $composableBuilder(column: $table.elo, builder: (column) => column);

  GeneratedColumn<int> get wins =>
      $composableBuilder(column: $table.wins, builder: (column) => column);

  GeneratedColumn<int> get losses =>
      $composableBuilder(column: $table.losses, builder: (column) => column);

  GeneratedColumn<int> get draws =>
      $composableBuilder(column: $table.draws, builder: (column) => column);

  GeneratedColumn<int> get matchesPlayed => $composableBuilder(
    column: $table.matchesPlayed,
    builder: (column) => column,
  );
}

class $$PlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayersTable,
          Player,
          $$PlayersTableFilterComposer,
          $$PlayersTableOrderingComposer,
          $$PlayersTableAnnotationComposer,
          $$PlayersTableCreateCompanionBuilder,
          $$PlayersTableUpdateCompanionBuilder,
          (Player, BaseReferences<_$AppDatabase, $PlayersTable, Player>),
          Player,
          PrefetchHooks Function()
        > {
  $$PlayersTableTableManager(_$AppDatabase db, $PlayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> elo = const Value.absent(),
                Value<int> wins = const Value.absent(),
                Value<int> losses = const Value.absent(),
                Value<int> draws = const Value.absent(),
                Value<int> matchesPlayed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayersCompanion(
                id: id,
                name: name,
                elo: elo,
                wins: wins,
                losses: losses,
                draws: draws,
                matchesPlayed: matchesPlayed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int elo,
                required int wins,
                required int losses,
                required int draws,
                required int matchesPlayed,
                Value<int> rowid = const Value.absent(),
              }) => PlayersCompanion.insert(
                id: id,
                name: name,
                elo: elo,
                wins: wins,
                losses: losses,
                draws: draws,
                matchesPlayed: matchesPlayed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayersTable,
      Player,
      $$PlayersTableFilterComposer,
      $$PlayersTableOrderingComposer,
      $$PlayersTableAnnotationComposer,
      $$PlayersTableCreateCompanionBuilder,
      $$PlayersTableUpdateCompanionBuilder,
      (Player, BaseReferences<_$AppDatabase, $PlayersTable, Player>),
      Player,
      PrefetchHooks Function()
    >;
typedef $$MatchHistoryTableCreateCompanionBuilder =
    MatchHistoryCompanion Function({
      required String id,
      required String p1Id,
      required String p2Id,
      required String p1Name,
      required String p2Name,
      required int p1EloBefore,
      required int p2EloBefore,
      required int p1EloAfter,
      required int p2EloAfter,
      required String result,
      required int timestamp,
      Value<int> rowid,
    });
typedef $$MatchHistoryTableUpdateCompanionBuilder =
    MatchHistoryCompanion Function({
      Value<String> id,
      Value<String> p1Id,
      Value<String> p2Id,
      Value<String> p1Name,
      Value<String> p2Name,
      Value<int> p1EloBefore,
      Value<int> p2EloBefore,
      Value<int> p1EloAfter,
      Value<int> p2EloAfter,
      Value<String> result,
      Value<int> timestamp,
      Value<int> rowid,
    });

class $$MatchHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $MatchHistoryTable> {
  $$MatchHistoryTableFilterComposer({
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

  ColumnFilters<String> get p1Id => $composableBuilder(
    column: $table.p1Id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get p2Id => $composableBuilder(
    column: $table.p2Id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get p1Name => $composableBuilder(
    column: $table.p1Name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get p2Name => $composableBuilder(
    column: $table.p2Name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get p1EloBefore => $composableBuilder(
    column: $table.p1EloBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get p2EloBefore => $composableBuilder(
    column: $table.p2EloBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get p1EloAfter => $composableBuilder(
    column: $table.p1EloAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get p2EloAfter => $composableBuilder(
    column: $table.p2EloAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MatchHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $MatchHistoryTable> {
  $$MatchHistoryTableOrderingComposer({
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

  ColumnOrderings<String> get p1Id => $composableBuilder(
    column: $table.p1Id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get p2Id => $composableBuilder(
    column: $table.p2Id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get p1Name => $composableBuilder(
    column: $table.p1Name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get p2Name => $composableBuilder(
    column: $table.p2Name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get p1EloBefore => $composableBuilder(
    column: $table.p1EloBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get p2EloBefore => $composableBuilder(
    column: $table.p2EloBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get p1EloAfter => $composableBuilder(
    column: $table.p1EloAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get p2EloAfter => $composableBuilder(
    column: $table.p2EloAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get result => $composableBuilder(
    column: $table.result,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MatchHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatchHistoryTable> {
  $$MatchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get p1Id =>
      $composableBuilder(column: $table.p1Id, builder: (column) => column);

  GeneratedColumn<String> get p2Id =>
      $composableBuilder(column: $table.p2Id, builder: (column) => column);

  GeneratedColumn<String> get p1Name =>
      $composableBuilder(column: $table.p1Name, builder: (column) => column);

  GeneratedColumn<String> get p2Name =>
      $composableBuilder(column: $table.p2Name, builder: (column) => column);

  GeneratedColumn<int> get p1EloBefore => $composableBuilder(
    column: $table.p1EloBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get p2EloBefore => $composableBuilder(
    column: $table.p2EloBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get p1EloAfter => $composableBuilder(
    column: $table.p1EloAfter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get p2EloAfter => $composableBuilder(
    column: $table.p2EloAfter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get result =>
      $composableBuilder(column: $table.result, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$MatchHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MatchHistoryTable,
          MatchHistoryData,
          $$MatchHistoryTableFilterComposer,
          $$MatchHistoryTableOrderingComposer,
          $$MatchHistoryTableAnnotationComposer,
          $$MatchHistoryTableCreateCompanionBuilder,
          $$MatchHistoryTableUpdateCompanionBuilder,
          (
            MatchHistoryData,
            BaseReferences<_$AppDatabase, $MatchHistoryTable, MatchHistoryData>,
          ),
          MatchHistoryData,
          PrefetchHooks Function()
        > {
  $$MatchHistoryTableTableManager(_$AppDatabase db, $MatchHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatchHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> p1Id = const Value.absent(),
                Value<String> p2Id = const Value.absent(),
                Value<String> p1Name = const Value.absent(),
                Value<String> p2Name = const Value.absent(),
                Value<int> p1EloBefore = const Value.absent(),
                Value<int> p2EloBefore = const Value.absent(),
                Value<int> p1EloAfter = const Value.absent(),
                Value<int> p2EloAfter = const Value.absent(),
                Value<String> result = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatchHistoryCompanion(
                id: id,
                p1Id: p1Id,
                p2Id: p2Id,
                p1Name: p1Name,
                p2Name: p2Name,
                p1EloBefore: p1EloBefore,
                p2EloBefore: p2EloBefore,
                p1EloAfter: p1EloAfter,
                p2EloAfter: p2EloAfter,
                result: result,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String p1Id,
                required String p2Id,
                required String p1Name,
                required String p2Name,
                required int p1EloBefore,
                required int p2EloBefore,
                required int p1EloAfter,
                required int p2EloAfter,
                required String result,
                required int timestamp,
                Value<int> rowid = const Value.absent(),
              }) => MatchHistoryCompanion.insert(
                id: id,
                p1Id: p1Id,
                p2Id: p2Id,
                p1Name: p1Name,
                p2Name: p2Name,
                p1EloBefore: p1EloBefore,
                p2EloBefore: p2EloBefore,
                p1EloAfter: p1EloAfter,
                p2EloAfter: p2EloAfter,
                result: result,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MatchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MatchHistoryTable,
      MatchHistoryData,
      $$MatchHistoryTableFilterComposer,
      $$MatchHistoryTableOrderingComposer,
      $$MatchHistoryTableAnnotationComposer,
      $$MatchHistoryTableCreateCompanionBuilder,
      $$MatchHistoryTableUpdateCompanionBuilder,
      (
        MatchHistoryData,
        BaseReferences<_$AppDatabase, $MatchHistoryTable, MatchHistoryData>,
      ),
      MatchHistoryData,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
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

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db, _db.players);
  $$MatchHistoryTableTableManager get matchHistory =>
      $$MatchHistoryTableTableManager(_db, _db.matchHistory);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
