const preferInlinePragma = "vm:prefer-inline";

const empty = "";
const newLine = "\n";
const slash = "/";
const dot = ".";
const equalSpaced = " = ";
const openingBracket = "{";
const closingBracket = "}";
const comma = ",";
const parentDirectorySymbol = '..';
const currentDirectorySymbol = './';

const storageLibraryName = "libstorage.so";
const storagePackageName = "tarantool_storage";

const boxCfgPrefix = "box.cfg{";

const int32Max = 4294967295;
const batchInitiaSize = 512;
const awaitStateDuration = Duration(seconds: 1);
const awaitTransactionDuration = Duration(milliseconds: 1);

const packageConfigJsonFile = "package_config.json";

const loadError = "Unable to load Tarantool binding library";

const pubspecYamlFile = 'pubspec.yaml';
const pubspecYmlFile = 'pubspec.yml';

const universeObjectType = "universe";
const nil = "nil";

class Directories {
  static const native = "/native";
  static const package = "/package";
  static const lua = "/lua";
  static const dotDartTool = ".dart_tool";
}

class Messages {
  static const runPubGet = "Run 'dart pub get'";
  static const specifyDartEntryPoint = 'Specify dart execution entry point';
  static const projectRootNotFound = "Project root not found (parent of 'pubspec.yaml')";
}

class FileExtensions {
  static const exe = "exe";
  static const lua = "lua";
  static const so = "so";
  static const h = "h";
  static const tarGz = "tar.gz";
}

class CompileOptions {
  static const dartExecutable = "dart";
  static const compileCommand = "compile";
  static const outputOption = "-o";
  static const gccExecutable = "gcc";
  static const gccSharedOption = "-shared";
  static const gccFpicOption = "-fPIC";
}

class PackageConfigFields {
  PackageConfigFields._();

  static const rootUri = 'rootUri';
  static const name = 'name';
  static const packages = 'packages';
}

enum UpdateOperationType {
  add,
  subtract,
  bitwiseAnd,
  bitwiseOr,
  bitwiseXor,
  stringSplice,
  insert,
  delete,
  assign,
}

enum StorageIteratorType {
  eq,
  req,
  all,
  lt,
  le,
  ge,
  gt,
  bitsetAllSet,
  bitsetAnySet,
  bitsetAllNotSet,
  overlaps,
  neighbor,
}

enum StorageEngine { memtx, vinly }

enum IndexType { hash, tree, bitset, rtree }

enum FieldType { any, unsigned, string, number, double, integer, boolean, decimal, uuid, scalar, array, map, datetime, varbinary }

enum IndexPartType { unsigned, string, number, double, integer, boolean, decimal, uuid, scalar, datetime, varbinary }

extension UpdateOperationTypeExtension on UpdateOperationType {
  String operation() {
    switch (this) {
      case UpdateOperationType.add:
        return "+";
      case UpdateOperationType.subtract:
        return "-";
      case UpdateOperationType.bitwiseAnd:
        return "&";
      case UpdateOperationType.bitwiseOr:
        return "|";
      case UpdateOperationType.bitwiseXor:
        return "^";
      case UpdateOperationType.stringSplice:
        return ":";
      case UpdateOperationType.insert:
        return "!";
      case UpdateOperationType.delete:
        return "#";
      case UpdateOperationType.assign:
        return "=";
    }
  }
}

class LuaExpressions {
  static String require(String module) => """require '$module'""";
  static String extendPackagePath(String extension) => """package.path = package.path .. ';${extension + "/?.lua"}'""";
  static String extendPackageNativePath(String extension) => """package.cpath = package.cpath .. ';${extension + "/?.so"}'""";

  static const startBackup = "box.backup.start()";
  static const stopBackup = "box.backup.start()";
  static const promote = "box.ctl.promote()";
  static const schemaUpgrade = "box.schema.upgrade()";

  static const createUser = "box.schema.user.create";
  static String dropUser(String name) => "box.schema.user.drop('$name')";
  static String changePassword(String user, String newPassword) => "box.schema.user.passwd('$user', '$newPassword')";
  static const userExists = "box.schema.user.exists";
  static const userGrant = "box.schema.user.grant";
  static const userRevoke = "box.schema.user.revoke";

  static String createIndex(String space) => "box.space['$space']:create_index";
  static String alterIndex(String space, String index) => "box.space['$space'].index['$index']:alter";
  static String dropIndex(String space, String index) => "box.space['$space'].index['$index']:drop()";

  static const createSpace = "box.schema.create_space";
  static String alterSpace(String space) => "box.space['$space']:alter";
  static String renameSpace(String space) => "box.space['$space']:rename";
  static String dropSpace(String space) => "box.space['$space']:drop()";
}

class LuaField {
  static String stringField(String name, String value) => '$name = $value';
  static String tableField(String name, String value) => '$name = {$value}';
  static String quottedField(String name, String value) => "$name = '$value'";
  static String intField(String name, int value) => '$name = $value';
  static String boolField(String name, bool value) => '$name = $value';
}

class LuaArgument {
  static String singleQuottedArgument(String argument, {String? options}) => options != null ? "('$argument', {$options})" : "('$argument')";
  static String singleStringArgument(String argument, {String? options}) => options != null ? "($argument, {$options})" : "($argument)";
  static String singleTableArgument(String table) => "{$table}";
  static String arrayArgument(List<String> arguments) => "(${arguments.join(comma)})";
}

class SchemaFields {
  static const name = "name";
  static const engine = "engine";
  static const fieldCount = "field_count";
  static const format = "format";
  static const id = "id";
  static const ifNotExists = "if_not_exists";
  static const isLocal = "is_local";
  static const isSync = "is_sync";
  static const temporary = "temporary";
  static const field = "field";
  static const type = "type";
  static const unique = "unique";
  static const parts = "parts";
  static const user = "user";
  static const password = "password";
  static const isNullable = "is_nullable";
}
