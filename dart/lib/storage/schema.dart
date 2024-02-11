import 'dart:ffi';
import 'dart:typed_data';

import 'package:linux_interactor/linux_interactor.dart';
import 'extensions.dart';
import 'bindings.dart';
import 'constants.dart';
import 'executor.dart';
import 'index.dart';
import 'lua.dart';
import 'serialization.dart';
import 'space.dart';

class StorageSpaceField {
  final String _name;
  final String _type;
  final bool nullable;

  StorageSpaceField._(this._name, this._type, this.nullable);

  factory StorageSpaceField.any(String name, {bool nullable = false}) => StorageSpaceField._(name, StorageFieldType.any.name, nullable);
  factory StorageSpaceField.unsigned(String name, {bool nullable = false}) => StorageSpaceField._(name, StorageFieldType.unsigned.name, nullable);
  factory StorageSpaceField.string(String name, {bool nullable = false}) => StorageSpaceField._(name, StorageFieldType.string.name, nullable);
  factory StorageSpaceField.number(String name, {bool nullable = false}) => StorageSpaceField._(name, StorageFieldType.number.name, nullable);
  factory StorageSpaceField.double(String name, {bool nullable = false}) => StorageSpaceField._(name, StorageFieldType.double.name, nullable);
  factory StorageSpaceField.integer(String name, {bool nullable = false}) => StorageSpaceField._(name, StorageFieldType.integer.name, nullable);
  factory StorageSpaceField.boolean(String name, {bool nullable = false}) => StorageSpaceField._(name, StorageFieldType.boolean.name, nullable);
  factory StorageSpaceField.decimal(String name, {bool nullable = false}) => StorageSpaceField._(name, StorageFieldType.decimal.name, nullable);
  factory StorageSpaceField.uuid(String name, {bool nullable = false}) => StorageSpaceField._(name, StorageFieldType.uuid.name, nullable);
  factory StorageSpaceField.scalar(String name, {bool nullable = false}) => StorageSpaceField._(name, StorageFieldType.scalar.name, nullable);
  factory StorageSpaceField.array(String name, {bool nullable = false}) => StorageSpaceField._(name, StorageFieldType.array.name, nullable);
  factory StorageSpaceField.map(String name, {bool nullable = false}) => StorageSpaceField._(name, StorageFieldType.map.name, nullable);
  factory StorageSpaceField.datetime(String name, {bool nullable = false}) => StorageSpaceField._(name, StorageFieldType.datetime.name, nullable);
  factory StorageSpaceField.varbinary(String name, {bool nullable = false}) => StorageSpaceField._(name, StorageFieldType.varbinary.name, nullable);

  String format() => LuaArgument.singleTableArgument(
        [
          LuaField.quotedField(SchemaFields.name, _name),
          LuaField.quotedField(SchemaFields.type, _type),
          LuaField.boolField(SchemaFields.isNullable, nullable),
        ].join(comma),
      );
}

class StorageIndexPart {
  final int? fieldIndex;
  final String? fieldName;
  final String? type;
  final bool? nullable;

  StorageIndexPart._({this.fieldIndex, this.type, this.nullable, this.fieldName});

  factory StorageIndexPart.unsigned(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: StorageIndexPartType.unsigned.name, nullable: nullable);
  factory StorageIndexPart.string(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: StorageIndexPartType.string.name, nullable: nullable);
  factory StorageIndexPart.number(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: StorageIndexPartType.number.name, nullable: nullable);
  factory StorageIndexPart.double(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: StorageIndexPartType.double.name, nullable: nullable);
  factory StorageIndexPart.integer(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: StorageIndexPartType.integer.name, nullable: nullable);
  factory StorageIndexPart.boolean(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: StorageIndexPartType.boolean.name, nullable: nullable);
  factory StorageIndexPart.decimal(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: StorageIndexPartType.decimal.name, nullable: nullable);
  factory StorageIndexPart.uuid(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: StorageIndexPartType.uuid.name, nullable: nullable);
  factory StorageIndexPart.scalar(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: StorageIndexPartType.scalar.name, nullable: nullable);
  factory StorageIndexPart.datetime(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: StorageIndexPartType.datetime.name, nullable: nullable);
  factory StorageIndexPart.varbinary(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: StorageIndexPartType.varbinary.name, nullable: nullable);
  factory StorageIndexPart.byName(String field) => StorageIndexPart._(fieldName: field);

  String format() => fieldName != null && fieldName!.isNotEmpty
      ? LuaArgument.singleTableArgument(fieldName!.quoted)
      : LuaArgument.singleTableArgument(
          [
            LuaField.intField(SchemaFields.field, fieldIndex!),
            LuaField.quotedField(SchemaFields.type, type!),
            LuaField.boolField(SchemaFields.isNullable, nullable!),
          ].join(comma),
        );
}

class StorageSchema {
  final int _descriptor;
  final InteractorTuples _tuples;
  final StorageExecutor _executor;
  final StorageSerialization _serialization;
  final StorageProducer _producer;
  final Pointer<tarantool_factory> _factory;

  const StorageSchema(
    this._descriptor,
    this._factory,
    this._executor,
    this._tuples,
    this._serialization,
    this._producer,
  );

  StorageSpace spaceById(int id) => StorageSpace(id, _descriptor, _producer, _factory, _tuples);

  Future<StorageSpace> spaceByName(String space) => spaceId(space).then((id) => StorageSpace(id, _descriptor, _producer, _factory, _tuples));

  Future<int> spaceId(String space) {
    final (spaceString, spaceStringLength) = _serialization.createString(space);
    final message = tarantool_space_id_by_name_prepare(_factory, spaceString, spaceStringLength);
    return _producer.spaceIdByName(_descriptor, message).then(_parseSpaceId);
  }

  int _parseSpaceId(Pointer<interactor_message> message) {
    final id = message.outputInt;
    tarantool_space_id_by_name_free(_factory, message);
    return id;
  }

  Future<bool> spaceExists(String space) => spaceId(space).then((id) => id != tarantoolIdNil);

  Future<StorageIndex> indexByName(String spaceName, String indexName) => spaceId(spaceName).then(
        (spaceId) => indexId(spaceId, indexName).then(
          (indexId) => StorageIndex(
            spaceId,
            indexId,
            _descriptor,
            _tuples,
            _factory,
            _producer,
          ),
        ),
      );

  Future<int> indexId(int spaceId, String index) {
    final (indexString, indexStringLength) = _serialization.createString(index);
    final message = tarantool_index_id_request_prepare(_factory, spaceId, indexString, indexStringLength);
    return _producer.indexIdByName(_descriptor, message).then(_parseSpaceId);
  }

  Future<bool> indexExists(int spaceId, String indexName) => indexId(spaceId, indexName).then((id) => id != tarantoolIdNil);

  StorageIndex indexById(int spaceId, int indexId) => StorageIndex(
        spaceId,
        indexId,
        _descriptor,
        _tuples,
        _factory,
        _producer,
      );

  Future<void> createSpace(
    String name, {
    StorageEngine? engine,
    int? fieldCount,
    List<StorageSpaceField>? format,
    int? id,
    bool? ifNotExists,
    bool? local,
    bool? synchronous,
    bool? temporary,
    String? user,
  }) {
    List<String> arguments = [];
    if (engine != null) arguments.add(LuaField.quotedField(SchemaFields.engine, engine.name));
    if (fieldCount != null && fieldCount > 0) arguments.add(LuaField.intField(SchemaFields.fieldCount, fieldCount));
    if (format != null) arguments.add(LuaField.tableField(SchemaFields.format, format.map((part) => part.format()).join(comma)));
    if (id != null) arguments.add(LuaField.intField(SchemaFields.id, id));
    if (ifNotExists != null) arguments.add(LuaField.boolField(SchemaFields.ifNotExists, ifNotExists));
    if (local != null) arguments.add(LuaField.boolField(SchemaFields.isLocal, local));
    if (synchronous != null) arguments.add(LuaField.boolField(SchemaFields.isSync, synchronous));
    if (temporary != null) arguments.add(LuaField.boolField(SchemaFields.temporary, temporary));
    if (user != null && user.isNotEmpty) arguments.add(LuaField.quotedField(SchemaFields.user, user));
    return _executor.evaluate(LuaExpressions.createSpace + LuaArgument.singleQuotedArgument(name, options: arguments.join(comma)));
  }

  Future<void> alterSpace(
    String name, {
    int? fieldCount,
    List<StorageSpaceField>? format,
    bool? synchronous,
    bool? temporary,
    String? user,
  }) {
    List<String> arguments = [name];
    if (fieldCount != null && fieldCount > 0) arguments.add(LuaField.intField(SchemaFields.fieldCount, fieldCount));
    if (format != null) arguments.add(LuaField.tableField(SchemaFields.format, format.map((part) => part.format()).join(comma)));
    if (synchronous != null) arguments.add(LuaField.boolField(SchemaFields.isSync, synchronous));
    if (temporary != null) arguments.add(LuaField.boolField(SchemaFields.temporary, temporary));
    if (temporary != null) arguments.add(LuaField.boolField(SchemaFields.temporary, temporary));
    return _executor.evaluate(LuaExpressions.alterSpace(name) + LuaArgument.singleTableArgument(arguments.join(comma)));
  }

  Future<void> renameSpace(String from, String to) => _executor.evaluate(LuaExpressions.renameSpace(from) + LuaArgument.singleQuotedArgument(to));

  Future<void> dropSpace(String name) => _executor.evaluate(LuaExpressions.dropSpace(name));

  Future<void> createIndex(
    String spaceName,
    String indexName, {
    StorageIndexType? type,
    int? id,
    bool? unique,
    bool? ifNotExists,
    List<StorageIndexPart>? parts,
  }) {
    List<String> arguments = [];
    if (type != null) arguments.add(LuaField.quotedField(SchemaFields.type, type.name));
    if (id != null) arguments.add(LuaField.intField(SchemaFields.id, id));
    if (ifNotExists != null) arguments.add(LuaField.boolField(SchemaFields.ifNotExists, ifNotExists));
    if (unique != null) arguments.add(LuaField.boolField(SchemaFields.unique, unique));
    if (parts != null) arguments.add(LuaField.tableField(SchemaFields.parts, parts.map((part) => part.format()).join(comma)));
    return _executor.evaluate(LuaExpressions.createIndex(spaceName) + LuaArgument.singleQuotedArgument(indexName, options: arguments.join(comma)));
  }

  Future<void> alterIndex(String spaceName, String indexName, {List<StorageIndexPart>? parts}) {
    List<String> arguments = [if (parts != null) LuaField.tableField(SchemaFields.parts, parts.map((part) => part.format()).join(comma))];
    return _executor.evaluate(LuaExpressions.alterIndex(spaceName, indexName) + LuaArgument.singleTableArgument(arguments.join(comma)));
  }

  Future<void> dropIndex(String spaceName, String indexName) => _executor.evaluate(LuaExpressions.dropIndex(spaceName, indexName));

  Future<void> createUser(String name, String password, {bool? ifNotExists}) {
    List<String> arguments = [LuaField.quotedField(SchemaFields.password, password)];
    if (ifNotExists != null) arguments.add(LuaField.boolField(SchemaFields.ifNotExists, ifNotExists));
    return _executor.evaluate(LuaExpressions.createUser + LuaArgument.singleQuotedArgument(name, options: arguments.join(comma)));
  }

  Future<void> dropUser(String name) => _executor.evaluate(LuaExpressions.dropUser(name));

  Future<void> changePassword(String name, String password) => _executor.evaluate(LuaExpressions.changePassword(name, password));

  Future<bool> userExists(String name) {
    final tupleSize = tupleSizeOfList(1) + tupleSizeOfString(name.length);
    final tuple = _tuples.allocate(tupleSize);
    final buffer = tuple.asTypedList(tupleSize);
    final data = ByteData.view(buffer.buffer, buffer.offsetInBytes);
    var offset = 0;
    offset = tupleWriteList(data, tupleSize, offset);
    offset = tupleWriteString(buffer, data, name, offset);
    return _executor
        .call(
          LuaExpressions.userExists,
          input: tuple,
          size: tupleSize,
        )
        .then(tarantoolCallExtractBool)
        .then((value) => value ?? false)
        .whenComplete(() => _tuples.free(tuple, tupleSize));
  }

  Future<void> grantUser(
    String name,
    String privileges, {
    String? objectType,
    String? objectName,
    String? roleName,
    bool? ifNotExists,
  }) {
    List<String> arguments = [name.quoted];
    if (roleName != null && roleName.isNotEmpty) {
      arguments.add(roleName.quoted);
      arguments.add(nil);
      arguments.add(nil);
      if (ifNotExists != null) arguments.add(LuaArgument.singleTableArgument(LuaField.boolField(SchemaFields.ifNotExists, ifNotExists)));
      return _executor.evaluate(LuaExpressions.userGrant + LuaArgument.arrayArgument(arguments));
    }
    arguments.add(privileges.quoted);
    arguments.add(objectType?.quoted ?? universeObjectType.quoted);
    arguments.add(objectName?.quoted ?? nil);
    if (ifNotExists != null) arguments.add(LuaArgument.singleTableArgument(LuaField.boolField(SchemaFields.ifNotExists, ifNotExists)));
    return _executor.evaluate(LuaExpressions.userGrant + LuaArgument.arrayArgument(arguments));
  }

  Future<void> revokeUser(
    String name,
    String privileges, {
    String? objectType,
    String? objectName,
    String? roleName,
    bool? ifNotExists,
  }) {
    List<String> arguments = [name.quoted];
    if (roleName != null && roleName.isNotEmpty) {
      arguments.add(roleName.quoted);
      arguments.add(nil);
      arguments.add(nil);
      if (ifNotExists != null) arguments.add(LuaArgument.singleTableArgument(LuaField.boolField(SchemaFields.ifNotExists, ifNotExists)));
      return _executor.evaluate(LuaExpressions.userRevoke + LuaArgument.arrayArgument(arguments));
    }
    arguments.add(privileges.quoted);
    arguments.add(objectType?.quoted ?? universeObjectType.quoted);
    arguments.add(objectName?.quoted ?? nil);
    if (ifNotExists != null) arguments.add(LuaArgument.singleTableArgument(LuaField.boolField(SchemaFields.ifNotExists, ifNotExists)));
    return _executor.evaluate(LuaExpressions.userRevoke + LuaArgument.arrayArgument(arguments));
  }

  Future<void> upgrade() => _executor.evaluate(LuaExpressions.schemaUpgrade);
}
