import 'constants.dart';
import 'executor.dart';

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

  StorageSchema(this._executor);

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

  Future<bool> spaceExists(String name) => _executor.hasSpace(name);

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

  Future<bool> indexExists(String spaceName, String indexName) => _executor.spaceId(spaceName).then((space) => _executor.hasIndex(space, indexName));

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
