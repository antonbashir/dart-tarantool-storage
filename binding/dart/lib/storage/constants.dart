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

const nativeDirectory = "/native";
const moduleDirectory = "/module";
const luaDirectory = "/lua";
const dartToolDirectoryName = ".dart_tool";

const storageLibraryName = "libstorage.so";
const storagePackageName = "tarantool_storage";

const boxCfgPrefix = "box.cfg{";

const int32Max = 4294967295;
const batchInitiaSize = 512;
const awaitStateDuration = Duration(seconds: 1);
const awaitTransactionDuration = Duration(milliseconds: 1);

const packageConfigJsonFile = "package_config.json";

const loadError = "Unable to load Tarantool binding library";

const exeExtension = "exe";
const luaExtension = "lua";
const soExtension = "so";
const headerExtension = "h";

const moduleArchivFile = "module.tar.gz";

class PackageConfigFields {
  PackageConfigFields._();

  static const rootUri = 'rootUri';
  static const name = 'name';
  static const packages = 'packages';
}

enum UpdateOperationType { add, subtract, bitwiseAnd, bitwiseOr, bitwiseXor, stringSplice, insert, delete, assign }

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

enum StorageEngine {
  memtx,
  vinly
}

enum IndexType {
  hash,
  tree,
  bitset,
  rtree
}

String requireluaScript(String module) => """require '$module'""";
String extendPackagePathluaScript(String extension) => """package.path = package.path .. ';${extension + "/?.lua"}'""";
String extendPackageNativePathluaScript(String extension) => """package.cpath = package.cpath .. ';${extension + "/?.so"}'""";

const startBackupLuaScript = "box.backup.start()";
const stopBackupLuaScript = "box.backup.start()";
const promoteLuaScript = "box.ctl.promote()";
