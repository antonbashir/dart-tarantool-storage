const preferInlinePragma = "vm:prefer-inline";

const empty = "";
const newLine = "\n";
const slash = "/";
const dot = ".";
const star = "*";
const equalSpaced = " = ";
const openingBracket = "{";
const closingBracket = "}";
const comma = ",";
const parentDirectorySymbol = '..';
const currentDirectorySymbol = './';

const storageLibraryName = "libstorage.so";
const storagePackageName = "tarantool_storage";
const storageLuaModule = "storage";

const boxCfgPrefix = "box.cfg{";

const int32Max = 4294967295;
const batchInitiaSize = 512;
const awaitStateDuration = Duration(seconds: 1);
const awaitTransactionDuration = Duration(milliseconds: 1);

const packageConfigJsonFile = "package_config.json";

const loadError = "Unable to load Tarantool binding library";

const dlCloseFunction = 'dlclose';

const pubspecYamlFile = 'pubspec.yaml';
const pubspecYmlFile = 'pubspec.yml';

const universeObjectType = "universe";
const nil = "nil";

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

enum StorageEngine {
  memtx,
  vinly,
}

enum IndexType {
  hash,
  tree,
  bitset,
  rtree,
}

enum FieldType {
  any,
  unsigned,
  string,
  number,
  double,
  integer,
  boolean,
  decimal,
  uuid,
  scalar,
  array,
  map,
  datetime,
  varbinary,
}

enum IndexPartType {
  unsigned,
  string,
  number,
  double,
  integer,
  boolean,
  decimal,
  uuid,
  scalar,
  datetime,
  varbinary,
}

class Directories {
  const Directories._();

  static const native = "/native";
  static const package = "/package";
  static const lua = "/lua";
  static const dotDartTool = ".dart_tool";
}

class Messages {
  const Messages._();

  static const runPubGet = "Run 'dart pub get'";
  static const specifyDartEntryPoint = 'Specify dart execution entry point';
  static const projectRootNotFound = "Project root not found (parent of 'pubspec.yaml')";
  static const nativeDirectoryNotFound = "Native root not found (run 'dart run tarantool_storage:setup')";
  static const nativeSourcesNotFound = "Native root does not contain any *.c or *.cpp sources";
}

class FileExtensions {
  const FileExtensions._();

  static const exe = "exe";
  static const lua = "lua";
  static const so = "so";
  static const h = "h";
  static const c = "c";
  static const cpp = "cpp";
  static const hpp = "hpp";
  static const tarGz = "tar.gz";
}

class CompileOptions {
  const CompileOptions._();

  static const dartExecutable = "dart";
  static const tarExecutable = "tar";
  static const tarOption = "-czf";
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

class LuaExpressions {
  const LuaExpressions._();

  static const reload = 'reload';
  static const boot = 'boot';

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
  const LuaField._();

  static String stringField(String name, String value) => '$name = $value';
  static String tableField(String name, String value) => '$name = {$value}';
  static String quottedField(String name, String value) => "$name = '$value'";
  static String intField(String name, int value) => '$name = $value';
  static String boolField(String name, bool value) => '$name = $value';
}

class LuaArgument {
  const LuaArgument._();

  static String singleQuottedArgument(String argument, {String? options}) => options != null ? "('$argument', {$options})" : "('$argument')";
  static String singleStringArgument(String argument, {String? options}) => options != null ? "($argument, {$options})" : "($argument)";
  static String singleTableArgument(String table) => "{$table}";
  static String arrayArgument(List<String> arguments) => "(${arguments.join(comma)})";
}

class SchemaFields {
  const SchemaFields._();

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

class ConfigurationKeys {
  const ConfigurationKeys._();

  static const listen = "listen";
  static const memtxMemory = "memtx_memory";
  static const stripCore = "strip_core";
  static const memtxMinTupleSize = "memtx_min_tuple_size";
  static const memtxMaxTupleSize = "memtx_max_tuple_size";
  static const slabAllocGranularity = "slab_alloc_granularity";
  static const slabAllocFactor = "slab_alloc_factor";
  static const iprotoThreads = "iproto_threads";
  static const workDir = "work_dir";
  static const memtxDir = "memtx_dir";
  static const walDir = "wal_dir";
  static const vinylDir = "vinyl_dir";
  static const vinylMemory = "vinyl_memory";
  static const vinylCache = "vinyl_cache";
  static const vinylMaxTupleSize = "vinyl_max_tuple_size";
  static const vinylReadThreads = "vinyl_read_threads";
  static const vinylWriteThreads = "vinyl_write_threads";
  static const vinylTimeout = "vinyl_timeout";
  static const vinylRunCountPerLevel = "vinyl_run_count_per_level";
  static const vinylRunSizeRatio = "vinyl_run_size_ratio";
  static const vinylRangeSize = "vinyl_range_size";
  static const vinylPageSize = "vinyl_page_size";
  static const vinylBloomFpr = "vinyl_bloom_fpr";
  static const ioCollectInterval = "io_collect_interval";
  static const readahead = "readahead";
  static const snapIoRateLimit = "snap_io_rate_limit";
  static const tooLongThreshold = "too_long_threshold";
  static const walMode = "wal_mode";
  static const walMaxSize = "wal_max_size";
  static const walDirRescanDelay = "wal_dir_rescan_delay";
  static const walQueueMaxSize = "wal_queue_max_size";
  static const walCleanupDelay = "wal_cleanup_delay";
  static const forceRecovery = "force_recovery";
  static const replication = "replication";
  static const instanceUuid = "instance_uuid";
  static const replicasetUuid = "replicaset_uuid";
  static const customProcTitle = "custom_proc_title";
  static const pidFile = "pid_file";
  static const background = "background";
  static const username = "username";
  static const coredump = "coredump";
  static const readOnly = "read_only";
  static const hotStandby = "hot_standby";
  static const memtxUseMvccEngine = "memtx_use_mvcc_engine";
  static const checkpointInterval = "checkpoint_interval";
  static const checkpointWalThreshold = "checkpoint_wal_threshold";
  static const checkpointCount = "checkpoint_count";
  static const workerPoolThreads = "worker_pool_threads";
  static const electionMode = "election_mode";
  static const electionTimeout = "election_timeout";
  static const replicationTimeout = "replication_timeout";
  static const replicationSyncLag = "replication_sync_lag";
  static const replicationSyncTimeout = "replication_sync_timeout";
  static const replicationSynchroQuorum = "replication_synchro_quorum";
  static const replicationSynchroTimeout = "replication_synchro_timeout";
  static const replicationConnectTimeout = "replication_connect_timeout";
  static const replicationConnectQuorum = "replication_connect_quorum";
  static const replicationSkipConflict = "replication_skip_conflict";
  static const replicationAnon = "replication_anon";
  static const feedbackEnabled = "feedback_enabled";
  static const feedbackCrashinfo = "feedback_crashinfo";
  static const feedbackHost = "feedback_host";
  static const feedbackInterval = "feedback_interval";
  static const netMsgMax = "net_msg_max";
  static const sqlCacheSize = "sql_cache_size";
  static const logLevel = "log_level";
  static const log = "log";
}
