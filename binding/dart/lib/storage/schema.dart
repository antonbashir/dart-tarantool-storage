import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:tarantool_storage/storage/bindings.dart';

import 'constants.dart';
import 'executor.dart';
import 'index.dart';
import 'space.dart';

class SpaceFormatPart {
  final String name;
  final String type;
  final bool nullable;

  SpaceFormatPart(this.name, this.type, {this.nullable = false});

  String lua() => "";
}

class IndexPart {
  final int field;
  final String type;
  final bool nullable;

  IndexPart(this.field, this.type, {this.nullable = false});

  String lua() => "";
}

class StorageSchema {
  final StorageExecutor _executor;
  final TarantoolBindings _bindings;

  StorageSchema(this._bindings, this._executor);

  StorageSpace spaceById(int id) => StorageSpace(_bindings, _executor, id);

  StorageIndex indexById(int spaceId, int indexId) => StorageIndex(_bindings, _executor, spaceId, indexId);

  Future<StorageSpace> spaceByName(String name) => spaceId(name).then((id) => StorageSpace(_bindings, _executor, id));

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
    return spaceId(spaceName).then((spaceId) => indexId(spaceId, indexName).then((indexId) => StorageIndex(_bindings, _executor, spaceId, indexId)));
  }

  Future<bool> indexExists(int spaceId, String indexName) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_index_id_by_name.cast();
        final request = arena<tarantool_index_id_request_t>();
        request.ref.space_id = spaceId;
        request.ref.name = indexName.toNativeUtf8().cast();
        request.ref.name_length = indexName.length;
        message.ref.input = request.cast();
        return _executor.sendSingle(message).then((pointer) => pointer.address != 0);
      });

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
    List<SpaceFormatPart>? format,
    int? id,
    bool? ifNotExists,
    bool? local,
    bool? synchronous,
    bool? temporary,
    String? user,
  }) =>
      _executor.evaluateLuaScript("""box.schema.create_space("$name", {engine = "$engine", field_count = $fieldCount, })""");

  Future<void> alterSpace(
    String name, {
    int? fieldCount,
    List<SpaceFormatPart>? format,
    bool? synchronous,
    bool? temporary,
    String? user,
  }) =>
      _executor.evaluateLuaScript("""box.schema.create_space("$name", {engine = "$engine", field_count = $fieldCount, })""");

  Future<void> renameSpace(String from, String to) => _executor.evaluateLuaScript("""box.space["$from"]:rename("$to")""");

  Future<void> dropSpace(String name) => _executor.evaluateLuaScript("""box.space["$name"]:drop()""");

  Future<void> createIndex(String spaceName, String indexName, {IndexType? type, int? id, bool? unique, bool? ifnotExists, List<IndexPart>? parts}) =>
      _executor.evaluateLuaScript("""box.schema.create_space("$name", {engine = "$engine", field_count = $fieldCount, })""");

  Future<void> alterIndex(String spaceName, String indexName, {List<IndexPart>? parts}) =>
      _executor.evaluateLuaScript("""box.schema.create_space("$name", {engine = "$engine", field_count = $fieldCount, })""");

  Future<void> dropIndex(String spaceName, String indexName) => _executor.evaluateLuaScript("""box.space["$spaceName"].index["$indexName]:drop()""");

  Future<void> createUser(String name, String password, {bool? ifnotExists}) =>
      _executor.evaluateLuaScript("""box.schema.user.create("$name", {password = "$password", if_not_exists = $ifnotExists})""");

  Future<void> changePassword(String name, String password) => _executor.evaluateLuaScript("""box.schema.user.passwd('$name', '$password')""");

  Future<void> userExists(String name) => _executor.executeLua("box.schema.user.exists", argument: [name]);

  Future<void> userGrant(String name, {required String privileges, String? objectType, String? objectName, String? roleName, bool? universe, bool? ifNotExists}) {}

  Future<void> userRevoke(String name, {required String privileges, String? objectType, String? objectName, String? roleName, bool? universe, bool? ifNotExists}) {}

  Future<void> upgrade() => _executor.evaluateLuaScript("box.schema.upgrade()");
}
