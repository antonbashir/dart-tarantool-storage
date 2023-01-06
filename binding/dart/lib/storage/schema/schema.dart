import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../extensions.dart';
import '../bindings.dart';
import '../constants.dart';
import '../executor/executor.dart';
import '../tuple.dart';
import 'index.dart';
import 'space.dart';

class StorageSpaceField {
  final String _name;
  final String _type;
  final bool nullable;

  StorageSpaceField._(this._name, this._type, this.nullable);

  factory StorageSpaceField.any(String name, {bool nullable = false}) => StorageSpaceField._(name, FieldType.any.name, nullable);
  factory StorageSpaceField.unsigned(String name, {bool nullable = false}) => StorageSpaceField._(name, FieldType.unsigned.name, nullable);
  factory StorageSpaceField.string(String name, {bool nullable = false}) => StorageSpaceField._(name, FieldType.string.name, nullable);
  factory StorageSpaceField.number(String name, {bool nullable = false}) => StorageSpaceField._(name, FieldType.number.name, nullable);
  factory StorageSpaceField.double(String name, {bool nullable = false}) => StorageSpaceField._(name, FieldType.double.name, nullable);
  factory StorageSpaceField.integer(String name, {bool nullable = false}) => StorageSpaceField._(name, FieldType.integer.name, nullable);
  factory StorageSpaceField.boolean(String name, {bool nullable = false}) => StorageSpaceField._(name, FieldType.boolean.name, nullable);
  factory StorageSpaceField.decimal(String name, {bool nullable = false}) => StorageSpaceField._(name, FieldType.decimal.name, nullable);
  factory StorageSpaceField.uuid(String name, {bool nullable = false}) => StorageSpaceField._(name, FieldType.uuid.name, nullable);
  factory StorageSpaceField.scalar(String name, {bool nullable = false}) => StorageSpaceField._(name, FieldType.scalar.name, nullable);
  factory StorageSpaceField.array(String name, {bool nullable = false}) => StorageSpaceField._(name, FieldType.array.name, nullable);
  factory StorageSpaceField.map(String name, {bool nullable = false}) => StorageSpaceField._(name, FieldType.map.name, nullable);
  factory StorageSpaceField.datetime(String name, {bool nullable = false}) => StorageSpaceField._(name, FieldType.datetime.name, nullable);
  factory StorageSpaceField.varbinary(String name, {bool nullable = false}) => StorageSpaceField._(name, FieldType.varbinary.name, nullable);

  String format() => LuaArgument.singleTableArgument(
        [
          LuaField.quottedField(SchemaFields.name, _name),
          LuaField.quottedField(SchemaFields.type, _type),
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

  factory StorageIndexPart.unsigned(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: IndexPartType.unsigned.name, nullable: nullable);
  factory StorageIndexPart.string(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: IndexPartType.string.name, nullable: nullable);
  factory StorageIndexPart.number(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: IndexPartType.number.name, nullable: nullable);
  factory StorageIndexPart.double(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: IndexPartType.double.name, nullable: nullable);
  factory StorageIndexPart.integer(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: IndexPartType.integer.name, nullable: nullable);
  factory StorageIndexPart.boolean(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: IndexPartType.boolean.name, nullable: nullable);
  factory StorageIndexPart.decimal(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: IndexPartType.decimal.name, nullable: nullable);
  factory StorageIndexPart.uuid(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: IndexPartType.uuid.name, nullable: nullable);
  factory StorageIndexPart.scalar(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: IndexPartType.scalar.name, nullable: nullable);
  factory StorageIndexPart.datetime(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: IndexPartType.datetime.name, nullable: nullable);
  factory StorageIndexPart.varbinary(int field, {bool nullable = false}) => StorageIndexPart._(fieldIndex: field, type: IndexPartType.varbinary.name, nullable: nullable);
  factory StorageIndexPart.byName(String field) => StorageIndexPart._(fieldName: field);

  String format() => fieldName != null && fieldName!.isNotEmpty
      ? LuaArgument.singleTableArgument(fieldName!.quotted)
      : LuaArgument.singleTableArgument(
          [
            LuaField.intField(SchemaFields.field, fieldIndex!),
            LuaField.quottedField(SchemaFields.type, type!),
            LuaField.boolField(SchemaFields.isNullable, nullable!),
          ].join(comma),
        );
}

class StorageSchema {
  final StorageExecutor _executor;
  final TarantoolBindings _bindings;
  final TarantoolTupleDescriptor _descriptor;

  const StorageSchema(this._bindings, this._executor, this._descriptor);

  StorageSpace spaceById(int id) => StorageSpace(_bindings, _executor, id, _descriptor);

  Future<StorageSpace> spaceByName(String name) => spaceId(name).then((id) => StorageSpace(_bindings, _executor, id, _descriptor));

  Future<int> spaceId(String space) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_space_id_by_name.cast();
        final request = arena<tarantool_space_id_request_t>();
        request.ref.name = space.toNativeUtf8().cast();
        request.ref.name_length = space.length;
        message.ref.input = request.cast();
        return _executor.sendSingle(message).then((pointer) => pointer.address);
      });

  Future<bool> spaceExists(String space) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_has_space.cast();
        final request = arena<tarantool_space_id_request_t>();
        request.ref.name = space.toNativeUtf8().cast();
        request.ref.name_length = space.length;
        message.ref.input = request.cast();
        return _executor.sendSingle(message).then((pointer) => pointer.address != 0);
      });

  Future<StorageIndex> indexByName(String spaceName, String indexName) {
    return spaceId(spaceName).then((spaceId) => indexId(spaceId, indexName).then((indexId) => StorageIndex(_bindings, _executor, spaceId, indexId, _descriptor)));
  }

  Future<bool> indexExists(int spaceId, String indexName) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_has_index.cast();
        final request = arena<tarantool_index_id_request_t>();
        request.ref.space_id = spaceId;
        request.ref.name = indexName.toNativeUtf8().cast();
        request.ref.name_length = indexName.length;
        message.ref.input = request.cast();
        return _executor.sendSingle(message).then((pointer) => pointer.address != 0);
      });

  StorageIndex indexById(int spaceId, int indexId) => StorageIndex(_bindings, _executor, spaceId, indexId, _descriptor);

  Future<int> indexId(int spaceId, String index) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_index_id_by_name.cast();
        final request = arena<tarantool_index_id_request_t>();
        request.ref.space_id = spaceId;
        request.ref.name = index.toNativeUtf8().cast();
        request.ref.name_length = index.length;
        message.ref.input = request.cast();
        return _executor.sendSingle(message).then((pointer) => pointer.address);
      });

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
    if (engine != null) arguments.add(LuaField.quottedField(SchemaFields.engine, engine.name));
    if (fieldCount != null && fieldCount > 0) arguments.add(LuaField.intField(SchemaFields.fieldCount, fieldCount));
    if (format != null) arguments.add(LuaField.tableField(SchemaFields.format, format.map((part) => part.format()).join(comma)));
    if (id != null) arguments.add(LuaField.intField(SchemaFields.id, id));
    if (ifNotExists != null) arguments.add(LuaField.boolField(SchemaFields.ifNotExists, ifNotExists));
    if (local != null) arguments.add(LuaField.boolField(SchemaFields.isLocal, local));
    if (synchronous != null) arguments.add(LuaField.boolField(SchemaFields.isSync, synchronous));
    if (temporary != null) arguments.add(LuaField.boolField(SchemaFields.temporary, temporary));
    if (user != null && user.isNotEmpty) arguments.add(LuaField.quottedField(SchemaFields.user, user));
    return _executor.lua.script(LuaExpressions.createSpace + LuaArgument.singleQuottedArgument(name, options: arguments.join(comma)));
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
    return _executor.lua.script(LuaExpressions.alterSpace(name) + LuaArgument.singleTableArgument(arguments.join(comma)));
  }

  Future<void> renameSpace(String from, String to) => _executor.lua.script(LuaExpressions.renameSpace(from) + LuaArgument.singleQuottedArgument(to));

  Future<void> dropSpace(String name) => _executor.lua.script(LuaExpressions.dropSpace(name));

  Future<void> createIndex(
    String spaceName,
    String indexName, {
    IndexType? type,
    int? id,
    bool? unique,
    bool? ifNotExists,
    List<StorageIndexPart>? parts,
  }) {
    List<String> arguments = [];
    if (type != null) arguments.add(LuaField.quottedField(SchemaFields.type, type.name));
    if (id != null) arguments.add(LuaField.intField(SchemaFields.id, id));
    if (ifNotExists != null) arguments.add(LuaField.boolField(SchemaFields.ifNotExists, ifNotExists));
    if (unique != null) arguments.add(LuaField.boolField(SchemaFields.unique, unique));
    if (parts != null) arguments.add(LuaField.tableField(SchemaFields.parts, parts.map((part) => part.format()).join(comma)));
    return _executor.lua.script(LuaExpressions.createIndex(spaceName) + LuaArgument.singleQuottedArgument(indexName, options: arguments.join(comma)));
  }

  Future<void> alterIndex(String spaceName, String indexName, {List<StorageIndexPart>? parts}) {
    List<String> arguments = [if (parts != null) LuaField.tableField(SchemaFields.parts, parts.map((part) => part.format()).join(comma))];
    return _executor.lua.script(LuaExpressions.alterIndex(spaceName, indexName) + LuaArgument.singleTableArgument(arguments.join(comma)));
  }

  Future<void> dropIndex(String spaceName, String indexName) => _executor.lua.script(LuaExpressions.dropIndex(spaceName, indexName));

  Future<void> createUser(String name, String password, {bool? ifNotExists}) {
    List<String> arguments = [LuaField.quottedField(SchemaFields.password, password)];
    if (ifNotExists != null) arguments.add(LuaField.boolField(SchemaFields.ifNotExists, ifNotExists));
    return _executor.lua.script(LuaExpressions.createUser + LuaArgument.singleQuottedArgument(name, options: arguments.join(comma)));
  }

  Future<void> dropUser(String name) => _executor.lua.script(LuaExpressions.dropUser(name));

  Future<void> changePassword(String name, String password) => _executor.lua.script(LuaExpressions.changePassword(name, password));

  Future<bool> userExists(String name) => _executor.lua.call(LuaExpressions.userExists, arguments: [name]).then((value) => value.first);

  Future<void> grantUser(
    String name, {
    required String privileges,
    String? objectType,
    String? objectName,
    String? roleName,
    bool? ifNotExists,
  }) {
    List<String> arguments = [name.quotted];
    if (roleName != null && roleName.isNotEmpty) {
      arguments.add(roleName.quotted);
      arguments.add(nil);
      arguments.add(nil);
      if (ifNotExists != null) arguments.add(LuaArgument.singleTableArgument(LuaField.boolField(SchemaFields.ifNotExists, ifNotExists)));
      return _executor.lua.script(LuaExpressions.userGrant + LuaArgument.arrayArgument(arguments));
    }
    arguments.add(privileges.quotted);
    arguments.add(objectType?.quotted ?? universeObjectType.quotted);
    arguments.add(objectName?.quotted ?? nil);
    if (ifNotExists != null) arguments.add(LuaArgument.singleTableArgument(LuaField.boolField(SchemaFields.ifNotExists, ifNotExists)));
    return _executor.lua.script(LuaExpressions.userGrant + LuaArgument.arrayArgument(arguments));
  }

  Future<void> revokeUser(
    String name, {
    required String privileges,
    String? objectType,
    String? objectName,
    String? roleName,
    bool? universe,
    bool? ifNotExists,
  }) {
    List<String> arguments = [name.quotted];
    if (roleName != null && roleName.isNotEmpty) {
      arguments.add(roleName.quotted);
      arguments.add(nil);
      arguments.add(nil);
      if (ifNotExists != null) arguments.add(LuaArgument.singleTableArgument(LuaField.boolField(SchemaFields.ifNotExists, ifNotExists)));
      return _executor.lua.script(LuaExpressions.userRevoke + LuaArgument.arrayArgument(arguments));
    }
    arguments.add(privileges.quotted);
    arguments.add(objectType?.quotted ?? universeObjectType.quotted);
    arguments.add(objectName?.quotted ?? nil);
    if (ifNotExists != null) arguments.add(LuaArgument.singleTableArgument(LuaField.boolField(SchemaFields.ifNotExists, ifNotExists)));
    return _executor.lua.script(LuaExpressions.userRevoke + LuaArgument.arrayArgument(arguments));
  }

  Future<void> upgrade() => _executor.lua.script(LuaExpressions.schemaUpgrade);
}
