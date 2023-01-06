import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'bindings.dart';
import 'constants.dart';
import 'extensions.dart';

class StorageConfiguration {
  final Map<String, dynamic> _configurationMap;

  const StorageConfiguration(this._configurationMap);

  int? get listen => _configurationMap[ConfigurationKeys.listen];
  int get memtxMemory => _configurationMap[ConfigurationKeys.memtxMemory];
  bool get stripCore => _configurationMap[ConfigurationKeys.stripCore];
  int get memtxMinTupleSize => _configurationMap[ConfigurationKeys.memtxMinTupleSize];
  int get memtxMaxTupleSize => _configurationMap[ConfigurationKeys.memtxMaxTupleSize];
  int get slabAllocGranularity => _configurationMap[ConfigurationKeys.slabAllocGranularity];
  double get slabAllocFactor => _configurationMap[ConfigurationKeys.slabAllocFactor];
  int get iprotoThreads => _configurationMap[ConfigurationKeys.iprotoThreads];
  String? get workDir => _configurationMap[ConfigurationKeys.workDir];
  String get memtxDir => _configurationMap[ConfigurationKeys.memtxDir];
  String get walDir => _configurationMap[ConfigurationKeys.walDir];
  String get vinylDir => _configurationMap[ConfigurationKeys.vinylDir];
  int get vinylMemory => _configurationMap[ConfigurationKeys.vinylMemory];
  int get vinylCache => _configurationMap[ConfigurationKeys.vinylCache];
  int get vinylMaxTupleSize => _configurationMap[ConfigurationKeys.vinylMaxTupleSize];
  int get vinylReadThreads => _configurationMap[ConfigurationKeys.vinylReadThreads];
  int get vinylWriteThreads => _configurationMap[ConfigurationKeys.vinylWriteThreads];
  int get vinylTimeout => _configurationMap[ConfigurationKeys.vinylTimeout];
  int get vinylRunCountPerLevel => _configurationMap[ConfigurationKeys.vinylRunCountPerLevel];
  double get vinylRunSizeRatio => _configurationMap[ConfigurationKeys.vinylRunSizeRatio];
  int? get vinylRangeSize => _configurationMap[ConfigurationKeys.vinylRangeSize];
  int get vinylPageSize => _configurationMap[ConfigurationKeys.vinylPageSize];
  double get vinylBloomFpr => _configurationMap[ConfigurationKeys.vinylBloomFpr];
  int? get ioCollectInterval => _configurationMap[ConfigurationKeys.ioCollectInterval];
  int get readahead => _configurationMap[ConfigurationKeys.readahead];
  int? get snapIoRateLimit => _configurationMap[ConfigurationKeys.snapIoRateLimit];
  double get tooLongThreshold => _configurationMap[ConfigurationKeys.tooLongThreshold];
  String get walMode => _configurationMap[ConfigurationKeys.walMode];
  int get walMaxSize => _configurationMap[ConfigurationKeys.walMaxSize];
  int get walDirRescanDelay => _configurationMap[ConfigurationKeys.walDirRescanDelay];
  int get walQueueMaxSize => _configurationMap[ConfigurationKeys.walQueueMaxSize];
  int get walCleanupDelay => _configurationMap[ConfigurationKeys.walCleanupDelay];
  bool get forceRecovery => _configurationMap[ConfigurationKeys.forceRecovery];
  String? get replication => _configurationMap[ConfigurationKeys.replication];
  String? get instanceUuid => _configurationMap[ConfigurationKeys.instanceUuid];
  String? get replicasetUuid => _configurationMap[ConfigurationKeys.replicasetUuid];
  String? get customProcTitle => _configurationMap[ConfigurationKeys.customProcTitle];
  String? get pidFile => _configurationMap[ConfigurationKeys.pidFile];
  bool get background => _configurationMap[ConfigurationKeys.background];
  String? get username => _configurationMap[ConfigurationKeys.username];
  bool get coredump => _configurationMap[ConfigurationKeys.coredump];
  bool get readOnly => _configurationMap[ConfigurationKeys.readOnly];
  bool get hotStandby => _configurationMap[ConfigurationKeys.hotStandby];
  bool get memtxUseMvccEngine => _configurationMap[ConfigurationKeys.memtxUseMvccEngine];
  int get checkpointInterval => _configurationMap[ConfigurationKeys.checkpointInterval];
  double get checkpointWalThreshold => _configurationMap[ConfigurationKeys.checkpointWalThreshold];
  int get checkpointCount => _configurationMap[ConfigurationKeys.checkpointCount];
  int get workerPoolThreads => _configurationMap[ConfigurationKeys.workerPoolThreads];
  String get electionMode => _configurationMap[ConfigurationKeys.electionMode];
  int get electionTimeout => _configurationMap[ConfigurationKeys.electionTimeout];
  int get replicationTimeout => _configurationMap[ConfigurationKeys.replicationTimeout];
  int get replicationSyncLag => _configurationMap[ConfigurationKeys.replicationSyncLag];
  int get replicationSyncTimeout => _configurationMap[ConfigurationKeys.replicationSyncTimeout];
  int get replicationSynchroQuorum => _configurationMap[ConfigurationKeys.replicationSynchroQuorum];
  int get replicationSynchroTimeout => _configurationMap[ConfigurationKeys.replicationSynchroTimeout];
  double get replicationConnectTimeout => _configurationMap[ConfigurationKeys.replicationConnectTimeout];
  int? get replicationConnectQuorum => _configurationMap[ConfigurationKeys.replicationConnectQuorum];
  bool get replicationSkipConflict => _configurationMap[ConfigurationKeys.replicationSkipConflict];
  bool get replicationAnon => _configurationMap[ConfigurationKeys.replicationAnon];
  bool get feedbackEnabled => _configurationMap[ConfigurationKeys.feedbackEnabled];
  bool get feedbackCrashinfo => _configurationMap[ConfigurationKeys.feedbackCrashinfo];
  String get feedbackHost => _configurationMap[ConfigurationKeys.feedbackHost];
  int get feedbackInterval => _configurationMap[ConfigurationKeys.feedbackInterval];
  int get netMsgMax => _configurationMap[ConfigurationKeys.netMsgMax];
  int get sqlCacheSize => _configurationMap[ConfigurationKeys.sqlCacheSize];
  int get logLevel => _configurationMap[ConfigurationKeys.logLevel];
  String get log => _configurationMap[ConfigurationKeys.log] ?? empty;

  StorageConfiguration copyWith(
      {int? listen,
      int? memtxMemory,
      bool? stripCore,
      int? memtxMinTupleSize,
      int? memtxMaxTupleSize,
      int? slabAllocGranularity,
      double? slabAllocFactor,
      int? iprotoThreads,
      String? workDir,
      String? memtxDir,
      String? walDir,
      String? vinylDir,
      int? vinylMemory,
      int? vinylCache,
      int? vinylMaxTupleSize,
      int? vinylReadThreads,
      int? vinylWriteThreads,
      int? vinylTimeout,
      int? vinylRunCountPerLevel,
      double? vinylRunSizeRatio,
      int? vinylRangeSize,
      int? vinylPageSize,
      double? vinylBloomFpr,
      int? ioCollectInterval,
      int? readahead,
      int? snapIoRateLimit,
      double? tooLongThreshold,
      String? walMode,
      int? walMaxSize,
      int? walDirRescanDelay,
      int? walQueueMaxSize,
      int? walCleanupDelay,
      bool? forceRecovery,
      String? replication,
      String? instanceUuid,
      String? replicasetUuid,
      String? customProcTitle,
      String? pidFile,
      bool? background,
      String? username,
      bool? coredump,
      bool? readOnly,
      bool? hotStandby,
      bool? memtxUseMvccEngine,
      int? checkpointInterval,
      double? checkpointWalThreshold,
      int? checkpointCount,
      int? workerPoolThreads,
      String? electionMode,
      int? electionTimeout,
      int? replicationTimeout,
      int? replicationSyncLag,
      int? replicationSyncTimeout,
      int? replicationSynchroQuorum,
      int? replicationSynchroTimeout,
      double? replicationConnectTimeout,
      int? replicationConnectQuorum,
      bool? replicationSkipConflict,
      bool? replicationAnon,
      bool? feedbackEnabled,
      bool? feedbackCrashinfo,
      String? feedbackHost,
      int? feedbackInterval,
      int? netMsgMax,
      int? sqlCacheSize,
      int? logLevel,
      String? log}) {
    final copy = {..._configurationMap};
    copy[ConfigurationKeys.listen] = listen ?? _configurationMap[ConfigurationKeys.listen];
    copy[ConfigurationKeys.memtxMemory] = memtxMemory ?? _configurationMap[ConfigurationKeys.memtxMemory];
    copy[ConfigurationKeys.stripCore] = stripCore ?? _configurationMap[ConfigurationKeys.stripCore];
    copy[ConfigurationKeys.memtxMinTupleSize] = memtxMinTupleSize ?? _configurationMap[ConfigurationKeys.memtxMinTupleSize];
    copy[ConfigurationKeys.memtxMaxTupleSize] = memtxMaxTupleSize ?? _configurationMap[ConfigurationKeys.memtxMaxTupleSize];
    copy[ConfigurationKeys.slabAllocGranularity] = slabAllocGranularity ?? _configurationMap[ConfigurationKeys.slabAllocGranularity];
    copy[ConfigurationKeys.slabAllocFactor] = slabAllocFactor ?? _configurationMap[ConfigurationKeys.slabAllocFactor];
    copy[ConfigurationKeys.iprotoThreads] = iprotoThreads ?? _configurationMap[ConfigurationKeys.iprotoThreads];
    copy[ConfigurationKeys.workDir] = workDir?.quotted ?? _configurationMap[ConfigurationKeys.workDir];
    copy[ConfigurationKeys.memtxDir] = memtxDir?.quotted ?? _configurationMap[ConfigurationKeys.memtxDir];
    copy[ConfigurationKeys.walDir] = walDir?.quotted ?? _configurationMap[ConfigurationKeys.walDir];
    copy[ConfigurationKeys.vinylDir] = vinylDir?.quotted ?? _configurationMap[ConfigurationKeys.vinylDir];
    copy[ConfigurationKeys.vinylMemory] = vinylMemory ?? _configurationMap[ConfigurationKeys.vinylMemory];
    copy[ConfigurationKeys.vinylCache] = vinylCache ?? _configurationMap[ConfigurationKeys.vinylCache];
    copy[ConfigurationKeys.vinylMaxTupleSize] = vinylMaxTupleSize ?? _configurationMap[ConfigurationKeys.vinylMaxTupleSize];
    copy[ConfigurationKeys.vinylReadThreads] = vinylReadThreads ?? _configurationMap[ConfigurationKeys.vinylReadThreads];
    copy[ConfigurationKeys.vinylWriteThreads] = vinylWriteThreads ?? _configurationMap[ConfigurationKeys.vinylWriteThreads];
    copy[ConfigurationKeys.vinylTimeout] = vinylTimeout ?? _configurationMap[ConfigurationKeys.vinylTimeout];
    copy[ConfigurationKeys.vinylRunCountPerLevel] = vinylRunCountPerLevel ?? _configurationMap[ConfigurationKeys.vinylRunCountPerLevel];
    copy[ConfigurationKeys.vinylRunSizeRatio] = vinylRunSizeRatio ?? _configurationMap[ConfigurationKeys.vinylRunSizeRatio];
    copy[ConfigurationKeys.vinylRangeSize] = vinylRangeSize ?? _configurationMap[ConfigurationKeys.vinylRangeSize];
    copy[ConfigurationKeys.vinylPageSize] = vinylPageSize ?? _configurationMap[ConfigurationKeys.vinylPageSize];
    copy[ConfigurationKeys.vinylBloomFpr] = vinylBloomFpr ?? _configurationMap[ConfigurationKeys.vinylBloomFpr];
    copy[ConfigurationKeys.ioCollectInterval] = ioCollectInterval ?? _configurationMap[ConfigurationKeys.ioCollectInterval];
    copy[ConfigurationKeys.readahead] = readahead ?? _configurationMap[ConfigurationKeys.readahead];
    copy[ConfigurationKeys.snapIoRateLimit] = snapIoRateLimit ?? _configurationMap[ConfigurationKeys.snapIoRateLimit];
    copy[ConfigurationKeys.tooLongThreshold] = tooLongThreshold ?? _configurationMap[ConfigurationKeys.tooLongThreshold];
    copy[ConfigurationKeys.walMode] = walMode ?? _configurationMap[ConfigurationKeys.walMode];
    copy[ConfigurationKeys.walMaxSize] = walMaxSize ?? _configurationMap[ConfigurationKeys.walMaxSize];
    copy[ConfigurationKeys.walDirRescanDelay] = walDirRescanDelay ?? _configurationMap[ConfigurationKeys.walDirRescanDelay];
    copy[ConfigurationKeys.walQueueMaxSize] = walQueueMaxSize ?? _configurationMap[ConfigurationKeys.walQueueMaxSize];
    copy[ConfigurationKeys.walCleanupDelay] = walCleanupDelay ?? _configurationMap[ConfigurationKeys.walCleanupDelay];
    copy[ConfigurationKeys.forceRecovery] = forceRecovery ?? _configurationMap[ConfigurationKeys.forceRecovery];
    copy[ConfigurationKeys.replication] = replication ?? _configurationMap[ConfigurationKeys.replication];
    copy[ConfigurationKeys.instanceUuid] = instanceUuid ?? _configurationMap[ConfigurationKeys.instanceUuid];
    copy[ConfigurationKeys.replicasetUuid] = replicasetUuid ?? _configurationMap[ConfigurationKeys.replicasetUuid];
    copy[ConfigurationKeys.customProcTitle] = customProcTitle ?? _configurationMap[ConfigurationKeys.customProcTitle];
    copy[ConfigurationKeys.pidFile] = pidFile ?? _configurationMap[ConfigurationKeys.pidFile];
    copy[ConfigurationKeys.background] = background ?? _configurationMap[ConfigurationKeys.background];
    copy[ConfigurationKeys.username] = username?.quotted ?? _configurationMap[ConfigurationKeys.username];
    copy[ConfigurationKeys.coredump] = coredump ?? _configurationMap[ConfigurationKeys.coredump];
    copy[ConfigurationKeys.readOnly] = readOnly ?? _configurationMap[ConfigurationKeys.readOnly];
    copy[ConfigurationKeys.hotStandby] = hotStandby ?? _configurationMap[ConfigurationKeys.hotStandby];
    copy[ConfigurationKeys.memtxUseMvccEngine] = memtxUseMvccEngine ?? _configurationMap[ConfigurationKeys.memtxUseMvccEngine];
    copy[ConfigurationKeys.checkpointInterval] = checkpointInterval ?? _configurationMap[ConfigurationKeys.checkpointInterval];
    copy[ConfigurationKeys.checkpointWalThreshold] = checkpointWalThreshold ?? _configurationMap[ConfigurationKeys.checkpointWalThreshold];
    copy[ConfigurationKeys.checkpointCount] = checkpointCount ?? _configurationMap[ConfigurationKeys.checkpointCount];
    copy[ConfigurationKeys.workerPoolThreads] = workerPoolThreads ?? _configurationMap[ConfigurationKeys.workerPoolThreads];
    copy[ConfigurationKeys.electionMode] = electionMode?.quotted ?? _configurationMap[ConfigurationKeys.electionMode];
    copy[ConfigurationKeys.electionTimeout] = electionTimeout ?? _configurationMap[ConfigurationKeys.electionTimeout];
    copy[ConfigurationKeys.replicationTimeout] = replicationTimeout ?? _configurationMap[ConfigurationKeys.replicationTimeout];
    copy[ConfigurationKeys.replicationSyncLag] = replicationSyncLag ?? _configurationMap[ConfigurationKeys.replicationSyncLag];
    copy[ConfigurationKeys.replicationSyncTimeout] = replicationSyncTimeout ?? _configurationMap[ConfigurationKeys.replicationSyncTimeout];
    copy[ConfigurationKeys.replicationSynchroQuorum] = replicationSynchroQuorum ?? _configurationMap[ConfigurationKeys.replicationSynchroQuorum];
    copy[ConfigurationKeys.replicationSynchroTimeout] = replicationSynchroTimeout ?? _configurationMap[ConfigurationKeys.replicationSynchroTimeout];
    copy[ConfigurationKeys.replicationConnectTimeout] = replicationConnectTimeout ?? _configurationMap[ConfigurationKeys.replicationConnectTimeout];
    copy[ConfigurationKeys.replicationConnectQuorum] = replicationConnectQuorum ?? _configurationMap[ConfigurationKeys.replicationConnectQuorum];
    copy[ConfigurationKeys.replicationSkipConflict] = replicationSkipConflict ?? _configurationMap[ConfigurationKeys.replicationSkipConflict];
    copy[ConfigurationKeys.replicationAnon] = replicationAnon ?? _configurationMap[ConfigurationKeys.replicationAnon];
    copy[ConfigurationKeys.feedbackEnabled] = feedbackEnabled ?? _configurationMap[ConfigurationKeys.feedbackEnabled];
    copy[ConfigurationKeys.feedbackCrashinfo] = feedbackCrashinfo ?? _configurationMap[ConfigurationKeys.feedbackCrashinfo];
    copy[ConfigurationKeys.feedbackHost] = feedbackHost?.quotted ?? _configurationMap[ConfigurationKeys.feedbackHost];
    copy[ConfigurationKeys.feedbackInterval] = feedbackInterval ?? _configurationMap[ConfigurationKeys.feedbackInterval];
    copy[ConfigurationKeys.netMsgMax] = netMsgMax ?? _configurationMap[ConfigurationKeys.netMsgMax];
    copy[ConfigurationKeys.sqlCacheSize] = sqlCacheSize ?? _configurationMap[ConfigurationKeys.sqlCacheSize];
    copy[ConfigurationKeys.logLevel] = logLevel ?? _configurationMap[ConfigurationKeys.logLevel];
    copy[ConfigurationKeys.log] = log ?? _configurationMap[ConfigurationKeys.log];
    return StorageConfiguration(copy);
  }

  String format() => LuaExpressions.boxCfg + LuaArgument.singleTableArgument(_configurationMap.entries.map((entry) => LuaField.stringField(entry.key, entry.value.toString())).join(comma));
}

class StorageMessageLoopConfiguration {
  final int boxOutputBufferCapacity;
  final double messageLoopMaxSleepSeconds;
  final int messageLoopRingSize;
  final double messageLoopRegularSleepSeconds;
  final int messageLoopMaxEmptyCycles;
  final int messageLoopEmptyCyclesMultiplier;
  final int messageLoopInitialEmptyCycles;
  final int messageLoopRingRetryMaxCount;

  const StorageMessageLoopConfiguration({
    required this.boxOutputBufferCapacity,
    required this.messageLoopMaxSleepSeconds,
    required this.messageLoopRegularSleepSeconds,
    required this.messageLoopMaxEmptyCycles,
    required this.messageLoopEmptyCyclesMultiplier,
    required this.messageLoopInitialEmptyCycles,
    required this.messageLoopRingSize,
    required this.messageLoopRingRetryMaxCount,
  });

  StorageMessageLoopConfiguration copyWith({
    int? boxOutputBufferCapacity,
    double? messageLoopMaxSleepSeconds,
    double? messageLoopRegularSleepSeconds,
    int? messageLoopMaxEmptyCycles,
    int? messageLoopEmptyCyclesMultiplier,
    int? messageLoopInitialEmptyCycles,
    int? messageLoopRingSize,
    int? messageLoopRingRetryMaxCount,
  }) =>
      StorageMessageLoopConfiguration(
        boxOutputBufferCapacity: boxOutputBufferCapacity ?? this.boxOutputBufferCapacity,
        messageLoopMaxSleepSeconds: messageLoopMaxSleepSeconds ?? this.messageLoopMaxSleepSeconds,
        messageLoopRegularSleepSeconds: messageLoopRegularSleepSeconds ?? this.messageLoopRegularSleepSeconds,
        messageLoopMaxEmptyCycles: messageLoopMaxEmptyCycles ?? this.messageLoopMaxEmptyCycles,
        messageLoopEmptyCyclesMultiplier: messageLoopEmptyCyclesMultiplier ?? this.messageLoopEmptyCyclesMultiplier,
        messageLoopInitialEmptyCycles: messageLoopInitialEmptyCycles ?? this.messageLoopInitialEmptyCycles,
        messageLoopRingSize: messageLoopRingSize ?? this.messageLoopRingSize,
        messageLoopRingRetryMaxCount: messageLoopRingRetryMaxCount ?? this.messageLoopRingRetryMaxCount,
      );

  Pointer<tarantool_configuration_t> native(String libraryPath) {
    Pointer<tarantool_configuration_t> configuration = malloc<tarantool_configuration_t>();
    configuration.ref.box_output_buffer_capacity = boxOutputBufferCapacity;
    configuration.ref.message_loop_empty_cycles_multiplier = messageLoopEmptyCyclesMultiplier;
    configuration.ref.message_loop_max_empty_cycles = messageLoopMaxEmptyCycles;
    configuration.ref.message_loop_initial_empty_cycles = messageLoopInitialEmptyCycles;
    configuration.ref.message_loop_regular_sleep_seconds = messageLoopRegularSleepSeconds;
    configuration.ref.message_loop_max_sleep_seconds = messageLoopMaxSleepSeconds;
    configuration.ref.message_loop_ring_size = messageLoopRingSize;
    configuration.ref.message_loop_ring_retry_max_count = messageLoopRingRetryMaxCount;
    configuration.ref.library_path = libraryPath.toNativeUtf8().cast();
    return configuration;
  }
}

class StorageBootConfiguration {
  final String user;
  final String password;
  final Duration delay;

  StorageBootConfiguration(this.user, this.password, this.delay);

  StorageBootConfiguration copyWith({String? user, String? password, Duration? delay}) => StorageBootConfiguration(
        user ?? this.user,
        password ?? this.password,
        delay ?? this.delay,
      );
}

class StorageReplicationConfiguration {
  final _replicas = <String>[];

  StorageReplicationConfiguration addAddressReplica(String host, String port, {String? user, String? password}) {
    if (user != null && user.isNotEmpty) {
      if (password != null && password.isNotEmpty) {
        addReplica("$user:$password@$host:$port");
        return this;
      }
      addReplica("$user@$host:$port");
      return this;
    }
    addReplica("$host:$port");
    return this;
  }

  StorageReplicationConfiguration addPortReplica(int port) => addReplica(port.toString());

  StorageReplicationConfiguration addReplica(String uri) => this.._replicas.add(uri.quotted);

  String format() => "$openingBracket${_replicas.join(comma)}$closingBracket";
}
