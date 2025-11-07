// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDownloadTaskCollection on Isar {
  IsarCollection<DownloadTask> get downloadTasks => this.collection();
}

const DownloadTaskSchema = CollectionSchema(
  name: r'DownloadTask',
  id: -8326932930248620171,
  properties: {
    r'acceptRanges': PropertySchema(
      id: 0,
      name: r'acceptRanges',
      type: IsarType.bool,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'downloaded': PropertySchema(
      id: 2,
      name: r'downloaded',
      type: IsarType.long,
    ),
    r'etaSeconds': PropertySchema(
      id: 3,
      name: r'etaSeconds',
      type: IsarType.long,
    ),
    r'fileName': PropertySchema(
      id: 4,
      name: r'fileName',
      type: IsarType.string,
    ),
    r'lastRealUrl': PropertySchema(
      id: 5,
      name: r'lastRealUrl',
      type: IsarType.string,
    ),
    r'referer': PropertySchema(
      id: 6,
      name: r'referer',
      type: IsarType.string,
    ),
    r'savePath': PropertySchema(
      id: 7,
      name: r'savePath',
      type: IsarType.string,
    ),
    r'speedBps': PropertySchema(
      id: 8,
      name: r'speedBps',
      type: IsarType.double,
    ),
    r'state': PropertySchema(
      id: 9,
      name: r'state',
      type: IsarType.string,
    ),
    r'tempPath': PropertySchema(
      id: 10,
      name: r'tempPath',
      type: IsarType.string,
    ),
    r'total': PropertySchema(
      id: 11,
      name: r'total',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 12,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'url': PropertySchema(
      id: 13,
      name: r'url',
      type: IsarType.string,
    ),
    r'userAgent': PropertySchema(
      id: 14,
      name: r'userAgent',
      type: IsarType.string,
    )
  },
  estimateSize: _downloadTaskEstimateSize,
  serialize: _downloadTaskSerialize,
  deserialize: _downloadTaskDeserialize,
  deserializeProp: _downloadTaskDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _downloadTaskGetId,
  getLinks: _downloadTaskGetLinks,
  attach: _downloadTaskAttach,
  version: '3.1.0+1',
);

int _downloadTaskEstimateSize(
  DownloadTask object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.fileName.length * 3;
  {
    final value = object.lastRealUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.referer;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.savePath.length * 3;
  bytesCount += 3 + object.state.length * 3;
  bytesCount += 3 + object.tempPath.length * 3;
  bytesCount += 3 + object.url.length * 3;
  {
    final value = object.userAgent;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _downloadTaskSerialize(
  DownloadTask object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.acceptRanges);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeLong(offsets[2], object.downloaded);
  writer.writeLong(offsets[3], object.etaSeconds);
  writer.writeString(offsets[4], object.fileName);
  writer.writeString(offsets[5], object.lastRealUrl);
  writer.writeString(offsets[6], object.referer);
  writer.writeString(offsets[7], object.savePath);
  writer.writeDouble(offsets[8], object.speedBps);
  writer.writeString(offsets[9], object.state);
  writer.writeString(offsets[10], object.tempPath);
  writer.writeLong(offsets[11], object.total);
  writer.writeDateTime(offsets[12], object.updatedAt);
  writer.writeString(offsets[13], object.url);
  writer.writeString(offsets[14], object.userAgent);
}

DownloadTask _downloadTaskDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DownloadTask();
  object.acceptRanges = reader.readBool(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.downloaded = reader.readLong(offsets[2]);
  object.etaSeconds = reader.readLong(offsets[3]);
  object.fileName = reader.readString(offsets[4]);
  object.id = id;
  object.lastRealUrl = reader.readStringOrNull(offsets[5]);
  object.referer = reader.readStringOrNull(offsets[6]);
  object.savePath = reader.readString(offsets[7]);
  object.speedBps = reader.readDouble(offsets[8]);
  object.state = reader.readString(offsets[9]);
  object.tempPath = reader.readString(offsets[10]);
  object.total = reader.readLong(offsets[11]);
  object.updatedAt = reader.readDateTime(offsets[12]);
  object.url = reader.readString(offsets[13]);
  object.userAgent = reader.readStringOrNull(offsets[14]);
  return object;
}

P _downloadTaskDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readDateTime(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _downloadTaskGetId(DownloadTask object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _downloadTaskGetLinks(DownloadTask object) {
  return [];
}

void _downloadTaskAttach(
    IsarCollection<dynamic> col, Id id, DownloadTask object) {
  object.id = id;
}

extension DownloadTaskQueryWhereSort
    on QueryBuilder<DownloadTask, DownloadTask, QWhere> {
  QueryBuilder<DownloadTask, DownloadTask, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DownloadTaskQueryWhere
    on QueryBuilder<DownloadTask, DownloadTask, QWhereClause> {
  QueryBuilder<DownloadTask, DownloadTask, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DownloadTaskQueryFilter
    on QueryBuilder<DownloadTask, DownloadTask, QFilterCondition> {
  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      acceptRangesEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'acceptRanges',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      downloadedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'downloaded',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      downloadedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'downloaded',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      downloadedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'downloaded',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      downloadedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'downloaded',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      etaSecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'etaSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      etaSecondsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'etaSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      etaSecondsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'etaSeconds',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      etaSecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'etaSeconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      fileNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      fileNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      fileNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      fileNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      fileNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      fileNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      fileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fileName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      fileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fileName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      fileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileName',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      fileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fileName',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      lastRealUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastRealUrl',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      lastRealUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastRealUrl',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      lastRealUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastRealUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      lastRealUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastRealUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      lastRealUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastRealUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      lastRealUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastRealUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      lastRealUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastRealUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      lastRealUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastRealUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      lastRealUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastRealUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      lastRealUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastRealUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      lastRealUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastRealUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      lastRealUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastRealUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      refererIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'referer',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      refererIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'referer',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      refererEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      refererGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'referer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      refererLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'referer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      refererBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'referer',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      refererStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'referer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      refererEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'referer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      refererContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'referer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      refererMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'referer',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      refererIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'referer',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      refererIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'referer',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      savePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'savePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      savePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'savePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      savePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'savePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      savePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'savePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      savePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'savePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      savePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'savePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      savePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'savePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      savePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'savePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      savePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'savePath',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      savePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'savePath',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      speedBpsEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'speedBps',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      speedBpsGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'speedBps',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      speedBpsLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'speedBps',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      speedBpsBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'speedBps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> stateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      stateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> stateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> stateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'state',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      stateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> stateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> stateContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> stateMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'state',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      stateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'state',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      stateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'state',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      tempPathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tempPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      tempPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tempPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      tempPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tempPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      tempPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tempPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      tempPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tempPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      tempPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tempPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      tempPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tempPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      tempPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tempPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      tempPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tempPath',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      tempPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tempPath',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> totalEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'total',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      totalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'total',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> totalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'total',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> totalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'total',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> urlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      urlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> urlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> urlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'url',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> urlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> urlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> urlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> urlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'url',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition> urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      userAgentIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userAgent',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      userAgentIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userAgent',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      userAgentEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userAgent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      userAgentGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userAgent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      userAgentLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userAgent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      userAgentBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userAgent',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      userAgentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userAgent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      userAgentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userAgent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      userAgentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userAgent',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      userAgentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userAgent',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      userAgentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userAgent',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterFilterCondition>
      userAgentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userAgent',
        value: '',
      ));
    });
  }
}

extension DownloadTaskQueryObject
    on QueryBuilder<DownloadTask, DownloadTask, QFilterCondition> {}

extension DownloadTaskQueryLinks
    on QueryBuilder<DownloadTask, DownloadTask, QFilterCondition> {}

extension DownloadTaskQuerySortBy
    on QueryBuilder<DownloadTask, DownloadTask, QSortBy> {
  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByAcceptRanges() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'acceptRanges', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy>
      sortByAcceptRangesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'acceptRanges', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByDownloaded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloaded', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy>
      sortByDownloadedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloaded', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByEtaSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'etaSeconds', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy>
      sortByEtaSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'etaSeconds', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByLastRealUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRealUrl', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy>
      sortByLastRealUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRealUrl', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByReferer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referer', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByRefererDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referer', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortBySavePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savePath', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortBySavePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savePath', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortBySpeedBps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speedBps', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortBySpeedBpsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speedBps', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByTempPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempPath', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByTempPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempPath', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByUserAgent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userAgent', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> sortByUserAgentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userAgent', Sort.desc);
    });
  }
}

extension DownloadTaskQuerySortThenBy
    on QueryBuilder<DownloadTask, DownloadTask, QSortThenBy> {
  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByAcceptRanges() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'acceptRanges', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy>
      thenByAcceptRangesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'acceptRanges', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByDownloaded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloaded', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy>
      thenByDownloadedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloaded', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByEtaSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'etaSeconds', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy>
      thenByEtaSecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'etaSeconds', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByLastRealUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRealUrl', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy>
      thenByLastRealUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastRealUrl', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByReferer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referer', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByRefererDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referer', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenBySavePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savePath', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenBySavePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savePath', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenBySpeedBps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speedBps', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenBySpeedBpsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'speedBps', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByTempPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempPath', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByTempPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tempPath', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByUserAgent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userAgent', Sort.asc);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QAfterSortBy> thenByUserAgentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userAgent', Sort.desc);
    });
  }
}

extension DownloadTaskQueryWhereDistinct
    on QueryBuilder<DownloadTask, DownloadTask, QDistinct> {
  QueryBuilder<DownloadTask, DownloadTask, QDistinct> distinctByAcceptRanges() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'acceptRanges');
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QDistinct> distinctByDownloaded() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'downloaded');
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QDistinct> distinctByEtaSeconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'etaSeconds');
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QDistinct> distinctByFileName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QDistinct> distinctByLastRealUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastRealUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QDistinct> distinctByReferer(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'referer', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QDistinct> distinctBySavePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'savePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QDistinct> distinctBySpeedBps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'speedBps');
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QDistinct> distinctByState(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'state', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QDistinct> distinctByTempPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tempPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QDistinct> distinctByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'total');
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QDistinct> distinctByUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'url', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadTask, DownloadTask, QDistinct> distinctByUserAgent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userAgent', caseSensitive: caseSensitive);
    });
  }
}

extension DownloadTaskQueryProperty
    on QueryBuilder<DownloadTask, DownloadTask, QQueryProperty> {
  QueryBuilder<DownloadTask, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DownloadTask, bool, QQueryOperations> acceptRangesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'acceptRanges');
    });
  }

  QueryBuilder<DownloadTask, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<DownloadTask, int, QQueryOperations> downloadedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'downloaded');
    });
  }

  QueryBuilder<DownloadTask, int, QQueryOperations> etaSecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'etaSeconds');
    });
  }

  QueryBuilder<DownloadTask, String, QQueryOperations> fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileName');
    });
  }

  QueryBuilder<DownloadTask, String?, QQueryOperations> lastRealUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastRealUrl');
    });
  }

  QueryBuilder<DownloadTask, String?, QQueryOperations> refererProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referer');
    });
  }

  QueryBuilder<DownloadTask, String, QQueryOperations> savePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'savePath');
    });
  }

  QueryBuilder<DownloadTask, double, QQueryOperations> speedBpsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'speedBps');
    });
  }

  QueryBuilder<DownloadTask, String, QQueryOperations> stateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'state');
    });
  }

  QueryBuilder<DownloadTask, String, QQueryOperations> tempPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tempPath');
    });
  }

  QueryBuilder<DownloadTask, int, QQueryOperations> totalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'total');
    });
  }

  QueryBuilder<DownloadTask, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<DownloadTask, String, QQueryOperations> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'url');
    });
  }

  QueryBuilder<DownloadTask, String?, QQueryOperations> userAgentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userAgent');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDownloadPartCollection on Isar {
  IsarCollection<DownloadPart> get downloadParts => this.collection();
}

const DownloadPartSchema = CollectionSchema(
  name: r'DownloadPart',
  id: -2279203014416038296,
  properties: {
    r'downloaded': PropertySchema(
      id: 0,
      name: r'downloaded',
      type: IsarType.long,
    ),
    r'end': PropertySchema(
      id: 1,
      name: r'end',
      type: IsarType.long,
    ),
    r'index': PropertySchema(
      id: 2,
      name: r'index',
      type: IsarType.long,
    ),
    r'start': PropertySchema(
      id: 3,
      name: r'start',
      type: IsarType.long,
    ),
    r'state': PropertySchema(
      id: 4,
      name: r'state',
      type: IsarType.string,
    ),
    r'taskId': PropertySchema(
      id: 5,
      name: r'taskId',
      type: IsarType.long,
    )
  },
  estimateSize: _downloadPartEstimateSize,
  serialize: _downloadPartSerialize,
  deserialize: _downloadPartDeserialize,
  deserializeProp: _downloadPartDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _downloadPartGetId,
  getLinks: _downloadPartGetLinks,
  attach: _downloadPartAttach,
  version: '3.1.0+1',
);

int _downloadPartEstimateSize(
  DownloadPart object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.state.length * 3;
  return bytesCount;
}

void _downloadPartSerialize(
  DownloadPart object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.downloaded);
  writer.writeLong(offsets[1], object.end);
  writer.writeLong(offsets[2], object.index);
  writer.writeLong(offsets[3], object.start);
  writer.writeString(offsets[4], object.state);
  writer.writeLong(offsets[5], object.taskId);
}

DownloadPart _downloadPartDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DownloadPart();
  object.downloaded = reader.readLong(offsets[0]);
  object.end = reader.readLong(offsets[1]);
  object.id = id;
  object.index = reader.readLong(offsets[2]);
  object.start = reader.readLong(offsets[3]);
  object.state = reader.readString(offsets[4]);
  object.taskId = reader.readLong(offsets[5]);
  return object;
}

P _downloadPartDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _downloadPartGetId(DownloadPart object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _downloadPartGetLinks(DownloadPart object) {
  return [];
}

void _downloadPartAttach(
    IsarCollection<dynamic> col, Id id, DownloadPart object) {
  object.id = id;
}

extension DownloadPartQueryWhereSort
    on QueryBuilder<DownloadPart, DownloadPart, QWhere> {
  QueryBuilder<DownloadPart, DownloadPart, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DownloadPartQueryWhere
    on QueryBuilder<DownloadPart, DownloadPart, QWhereClause> {
  QueryBuilder<DownloadPart, DownloadPart, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DownloadPartQueryFilter
    on QueryBuilder<DownloadPart, DownloadPart, QFilterCondition> {
  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition>
      downloadedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'downloaded',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition>
      downloadedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'downloaded',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition>
      downloadedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'downloaded',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition>
      downloadedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'downloaded',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> endEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'end',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition>
      endGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'end',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> endLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'end',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> endBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'end',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> indexEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'index',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition>
      indexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'index',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> indexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'index',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> indexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'index',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> startEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'start',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition>
      startGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'start',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> startLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'start',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> startBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'start',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> stateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition>
      stateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> stateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> stateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'state',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition>
      stateStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> stateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> stateContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'state',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> stateMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'state',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition>
      stateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'state',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition>
      stateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'state',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> taskIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taskId',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition>
      taskIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taskId',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition>
      taskIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taskId',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterFilterCondition> taskIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taskId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DownloadPartQueryObject
    on QueryBuilder<DownloadPart, DownloadPart, QFilterCondition> {}

extension DownloadPartQueryLinks
    on QueryBuilder<DownloadPart, DownloadPart, QFilterCondition> {}

extension DownloadPartQuerySortBy
    on QueryBuilder<DownloadPart, DownloadPart, QSortBy> {
  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> sortByDownloaded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloaded', Sort.asc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy>
      sortByDownloadedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloaded', Sort.desc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> sortByEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.asc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> sortByEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.desc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> sortByIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'index', Sort.asc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> sortByIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'index', Sort.desc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> sortByStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.asc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> sortByStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.desc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> sortByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> sortByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> sortByTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.asc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> sortByTaskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.desc);
    });
  }
}

extension DownloadPartQuerySortThenBy
    on QueryBuilder<DownloadPart, DownloadPart, QSortThenBy> {
  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> thenByDownloaded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloaded', Sort.asc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy>
      thenByDownloadedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloaded', Sort.desc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> thenByEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.asc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> thenByEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'end', Sort.desc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> thenByIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'index', Sort.asc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> thenByIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'index', Sort.desc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> thenByStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.asc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> thenByStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'start', Sort.desc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> thenByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> thenByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> thenByTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.asc);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QAfterSortBy> thenByTaskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.desc);
    });
  }
}

extension DownloadPartQueryWhereDistinct
    on QueryBuilder<DownloadPart, DownloadPart, QDistinct> {
  QueryBuilder<DownloadPart, DownloadPart, QDistinct> distinctByDownloaded() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'downloaded');
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QDistinct> distinctByEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'end');
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QDistinct> distinctByIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'index');
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QDistinct> distinctByStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'start');
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QDistinct> distinctByState(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'state', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadPart, DownloadPart, QDistinct> distinctByTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taskId');
    });
  }
}

extension DownloadPartQueryProperty
    on QueryBuilder<DownloadPart, DownloadPart, QQueryProperty> {
  QueryBuilder<DownloadPart, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DownloadPart, int, QQueryOperations> downloadedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'downloaded');
    });
  }

  QueryBuilder<DownloadPart, int, QQueryOperations> endProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'end');
    });
  }

  QueryBuilder<DownloadPart, int, QQueryOperations> indexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'index');
    });
  }

  QueryBuilder<DownloadPart, int, QQueryOperations> startProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'start');
    });
  }

  QueryBuilder<DownloadPart, String, QQueryOperations> stateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'state');
    });
  }

  QueryBuilder<DownloadPart, int, QQueryOperations> taskIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taskId');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDownloadLogCollection on Isar {
  IsarCollection<DownloadLog> get downloadLogs => this.collection();
}

const DownloadLogSchema = CollectionSchema(
  name: r'DownloadLog',
  id: 7901839366697521484,
  properties: {
    r'level': PropertySchema(
      id: 0,
      name: r'level',
      type: IsarType.string,
    ),
    r'message': PropertySchema(
      id: 1,
      name: r'message',
      type: IsarType.string,
    ),
    r'taskId': PropertySchema(
      id: 2,
      name: r'taskId',
      type: IsarType.long,
    ),
    r'ts': PropertySchema(
      id: 3,
      name: r'ts',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _downloadLogEstimateSize,
  serialize: _downloadLogSerialize,
  deserialize: _downloadLogDeserialize,
  deserializeProp: _downloadLogDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _downloadLogGetId,
  getLinks: _downloadLogGetLinks,
  attach: _downloadLogAttach,
  version: '3.1.0+1',
);

int _downloadLogEstimateSize(
  DownloadLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.level.length * 3;
  bytesCount += 3 + object.message.length * 3;
  return bytesCount;
}

void _downloadLogSerialize(
  DownloadLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.level);
  writer.writeString(offsets[1], object.message);
  writer.writeLong(offsets[2], object.taskId);
  writer.writeDateTime(offsets[3], object.ts);
}

DownloadLog _downloadLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DownloadLog();
  object.id = id;
  object.level = reader.readString(offsets[0]);
  object.message = reader.readString(offsets[1]);
  object.taskId = reader.readLong(offsets[2]);
  object.ts = reader.readDateTime(offsets[3]);
  return object;
}

P _downloadLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _downloadLogGetId(DownloadLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _downloadLogGetLinks(DownloadLog object) {
  return [];
}

void _downloadLogAttach(
    IsarCollection<dynamic> col, Id id, DownloadLog object) {
  object.id = id;
}

extension DownloadLogQueryWhereSort
    on QueryBuilder<DownloadLog, DownloadLog, QWhere> {
  QueryBuilder<DownloadLog, DownloadLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DownloadLogQueryWhere
    on QueryBuilder<DownloadLog, DownloadLog, QWhereClause> {
  QueryBuilder<DownloadLog, DownloadLog, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DownloadLogQueryFilter
    on QueryBuilder<DownloadLog, DownloadLog, QFilterCondition> {
  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> levelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'level',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition>
      levelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'level',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> levelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'level',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> levelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'level',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> levelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'level',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> levelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'level',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> levelContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'level',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> levelMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'level',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> levelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'level',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition>
      levelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'level',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> messageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition>
      messageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> messageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> messageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'message',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition>
      messageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> messageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> messageContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'message',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> messageMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'message',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition>
      messageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition>
      messageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'message',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> taskIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taskId',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition>
      taskIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taskId',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> taskIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taskId',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> taskIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taskId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> tsEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ts',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> tsGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ts',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> tsLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ts',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterFilterCondition> tsBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ts',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DownloadLogQueryObject
    on QueryBuilder<DownloadLog, DownloadLog, QFilterCondition> {}

extension DownloadLogQueryLinks
    on QueryBuilder<DownloadLog, DownloadLog, QFilterCondition> {}

extension DownloadLogQuerySortBy
    on QueryBuilder<DownloadLog, DownloadLog, QSortBy> {
  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> sortByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.asc);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> sortByLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.desc);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> sortByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> sortByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> sortByTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.asc);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> sortByTaskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.desc);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> sortByTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.asc);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> sortByTsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.desc);
    });
  }
}

extension DownloadLogQuerySortThenBy
    on QueryBuilder<DownloadLog, DownloadLog, QSortThenBy> {
  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> thenByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.asc);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> thenByLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.desc);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> thenByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> thenByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> thenByTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.asc);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> thenByTaskIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskId', Sort.desc);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> thenByTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.asc);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QAfterSortBy> thenByTsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ts', Sort.desc);
    });
  }
}

extension DownloadLogQueryWhereDistinct
    on QueryBuilder<DownloadLog, DownloadLog, QDistinct> {
  QueryBuilder<DownloadLog, DownloadLog, QDistinct> distinctByLevel(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'level', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QDistinct> distinctByMessage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'message', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QDistinct> distinctByTaskId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taskId');
    });
  }

  QueryBuilder<DownloadLog, DownloadLog, QDistinct> distinctByTs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ts');
    });
  }
}

extension DownloadLogQueryProperty
    on QueryBuilder<DownloadLog, DownloadLog, QQueryProperty> {
  QueryBuilder<DownloadLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DownloadLog, String, QQueryOperations> levelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'level');
    });
  }

  QueryBuilder<DownloadLog, String, QQueryOperations> messageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'message');
    });
  }

  QueryBuilder<DownloadLog, int, QQueryOperations> taskIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taskId');
    });
  }

  QueryBuilder<DownloadLog, DateTime, QQueryOperations> tsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ts');
    });
  }
}
