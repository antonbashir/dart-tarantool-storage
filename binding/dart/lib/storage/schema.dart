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

  Future<bool> spaceExists(String name) => Future.value(false);

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

  Future<bool> indexExists(String spaceName, String indexName) => Future.value(false);

  Future<void> alterIndex(String spaceName, String indexName, {List<IndexPart>? parts}) =>
      _executor.evaluateLuaScript("""box.schema.create_space("$name", {engine = "$engine", field_count = $fieldCount, })""");

  Future<void> dropIndex(String spaceName, String indexName) => _executor.evaluateLuaScript("""box.space["$spaceName"].index["$indexName]:drop()""");

  Future<void> createUser(String name, String password, {bool? ifnotExists}) {}

  Future<void> changePassword(String name, String password) {}

  Future<void> userExists(String name) {}

  Future<void> userGrant(String name, {required String privileges, String? objectType, String? objectName, String? roleName, bool? universe, bool? ifNotExists}) {}

  Future<void> userRevoke(String name, {required String privileges, String? objectType, String? objectName, String? roleName, bool? universe, bool? ifNotExists}) {}

  Future<void> upgrade() => _executor.evaluateLuaScript("box.schema.upgrade()");
}
