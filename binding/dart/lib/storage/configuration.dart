import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'bindings.dart';
import 'constants.dart';
import 'extensions.dart';

class StorageConfiguration {
  final Map<String, dynamic> _configurationMap;

  const StorageConfiguration(this._configurationMap);

  set listen(int? value) => _configurationMap[ConfigurationKeys.listen] = value;
  set memtxMemory(int value) => _configurationMap[ConfigurationKeys.memtxMemory] = value;
  set stripCore(bool value) => _configurationMap[ConfigurationKeys.stripCore] = value;
  set memtxMinTupleSize(int value) => _configurationMap[ConfigurationKeys.memtxMinTupleSize] = value;
  set memtxMaxTupleSize(int value) => _configurationMap[ConfigurationKeys.memtxMaxTupleSize] = value;
  set slabAllocGranularity(int value) => _configurationMap[ConfigurationKeys.slabAllocGranularity] = value;
  set slabAllocFactor(double value) => _configurationMap[ConfigurationKeys.slabAllocFactor] = value;
  set iprotoThreads(int value) => _configurationMap[ConfigurationKeys.iprotoThreads] = value;
  set workDir(String? value) => _configurationMap[ConfigurationKeys.workDir] = value?.quotted;
  set memtxDir(String value) => _configurationMap[ConfigurationKeys.memtxDir] = value.quotted;
  set walDir(String value) => _configurationMap[ConfigurationKeys.walDir] = value.quotted;
  set vinylDir(String value) => _configurationMap[ConfigurationKeys.vinylDir] = value.quotted;
  set vinylMemory(int value) => _configurationMap[ConfigurationKeys.vinylMemory] = value;
  set vinylCache(int value) => _configurationMap[ConfigurationKeys.vinylCache] = value;
  set vinylMaxTupleSize(int value) => _configurationMap[ConfigurationKeys.vinylMaxTupleSize] = value;
  set vinylReadThreads(int value) => _configurationMap[ConfigurationKeys.vinylReadThreads] = value;
  set vinylWriteThreads(int value) => _configurationMap[ConfigurationKeys.vinylWriteThreads] = value;
  set vinylTimeout(int value) => _configurationMap[ConfigurationKeys.vinylTimeout] = value;
  set vinylRunCountPerLevel(int value) => _configurationMap[ConfigurationKeys.vinylRunCountPerLevel] = value;
  set vinylRunSizeRatio(double value) => _configurationMap[ConfigurationKeys.vinylRunSizeRatio] = value;
  set vinylRangeSize(int? value) => _configurationMap[ConfigurationKeys.vinylRangeSize] = value;
  set vinylPageSize(int value) => _configurationMap[ConfigurationKeys.vinylPageSize] = value;
  set vinylBloomFpr(double value) => _configurationMap[ConfigurationKeys.vinylBloomFpr] = value;
  set ioCollectInterval(int? value) => _configurationMap[ConfigurationKeys.ioCollectInterval] = value;
  set readahead(int value) => _configurationMap[ConfigurationKeys.readahead] = value;
  set snapIoRateLimit(int? value) => _configurationMap[ConfigurationKeys.snapIoRateLimit] = value;
  set tooLongThreshold(double value) => _configurationMap[ConfigurationKeys.tooLongThreshold] = value;
  set walMode(String value) => _configurationMap[ConfigurationKeys.walMode] = value.quotted;
  set walMaxSize(int value) => _configurationMap[ConfigurationKeys.walMaxSize] = value;
  set walDirRescanDelay(int value) => _configurationMap[ConfigurationKeys.walDirRescanDelay] = value;
  set walQueueMaxSize(int value) => _configurationMap[ConfigurationKeys.walQueueMaxSize] = value;
  set walCleanupDelay(int value) => _configurationMap[ConfigurationKeys.walCleanupDelay] = value;
  set forceRecovery(bool value) => _configurationMap[ConfigurationKeys.forceRecovery] = value;
  set replication(String? value) => _configurationMap[ConfigurationKeys.replication] = value;
  set instanceUuid(String? value) => _configurationMap[ConfigurationKeys.instanceUuid] = value?.quotted;
  set replicasetUuid(String? value) => _configurationMap[ConfigurationKeys.replicasetUuid] = value?.quotted;
  set customProcTitle(String? value) => _configurationMap[ConfigurationKeys.customProcTitle] = value?.quotted;
  set pidFile(String? value) => _configurationMap[ConfigurationKeys.pidFile] = value?.quotted;
  set background(bool value) => _configurationMap[ConfigurationKeys.background] = value;
  set username(String? value) => _configurationMap[ConfigurationKeys.username] = value?.quotted;
  set coredump(bool value) => _configurationMap[ConfigurationKeys.coredump] = value;
  set readOnly(bool value) => _configurationMap[ConfigurationKeys.readOnly] = value;
  set hotStandby(bool value) => _configurationMap[ConfigurationKeys.hotStandby] = value;
  set memtxUseMvccEngine(bool value) => _configurationMap[ConfigurationKeys.memtxUseMvccEngine] = value;
  set checkpointInterval(int value) => _configurationMap[ConfigurationKeys.checkpointInterval] = value;
  set checkpointWalThreshold(double value) => _configurationMap[ConfigurationKeys.checkpointWalThreshold] = value;
  set checkpointCount(int value) => _configurationMap[ConfigurationKeys.checkpointCount] = value;
  set workerPoolThreads(int value) => _configurationMap[ConfigurationKeys.workerPoolThreads] = value;
  set electionMode(String value) => _configurationMap[ConfigurationKeys.electionMode] = value.quotted;
  set electionTimeout(int value) => _configurationMap[ConfigurationKeys.electionTimeout] = value;
  set replicationTimeout(int value) => _configurationMap[ConfigurationKeys.replicationTimeout] = value;
  set replicationSyncLag(int value) => _configurationMap[ConfigurationKeys.replicationSyncLag] = value;
  set replicationSyncTimeout(int value) => _configurationMap[ConfigurationKeys.replicationSyncTimeout] = value;
  set replicationSynchroQuorum(int value) => _configurationMap[ConfigurationKeys.replicationSynchroQuorum] = value;
  set replicationSynchroTimeout(int value) => _configurationMap[ConfigurationKeys.replicationSynchroTimeout] = value;
  set replicationConnectTimeout(double value) => _configurationMap[ConfigurationKeys.replicationConnectTimeout] = value;
  set replicationConnectQuorum(int? value) => _configurationMap[ConfigurationKeys.replicationConnectQuorum] = value;
  set replicationSkipConflict(bool value) => _configurationMap[ConfigurationKeys.replicationSkipConflict] = value;
  set replicationAnon(bool value) => _configurationMap[ConfigurationKeys.replicationAnon] = value;
  set feedbackEnabled(bool value) => _configurationMap[ConfigurationKeys.feedbackEnabled] = value;
  set feedbackCrashinfo(bool value) => _configurationMap[ConfigurationKeys.feedbackCrashinfo] = value;
  set feedbackHost(String value) => _configurationMap[ConfigurationKeys.feedbackHost] = value.quotted;
  set feedbackInterval(int value) => _configurationMap[ConfigurationKeys.feedbackInterval] = value;
  set netMsgMax(int value) => _configurationMap[ConfigurationKeys.netMsgMax] = value;
  set sqlCacheSize(int value) => _configurationMap[ConfigurationKeys.sqlCacheSize] = value;
  set logLevel(int value) => _configurationMap[ConfigurationKeys.logLevel] = value;
  set log(String value) => _configurationMap[ConfigurationKeys.log] = value.quotted;

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

  String format() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln(boxCfgPrefix);
    _configurationMap.forEach((key, value) {
      if (value != null) {
        buffer.writeln(key + equalSpaced + value.toString() + comma);
      }
    });
    buffer.writeln(closingBracket);
    return buffer.toString();
  }
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

class ReplicationConfiguration {
  final String user;
  final String password;
  final Duration delay;

  ReplicationConfiguration(this.user, this.password, this.delay);

  ReplicationConfiguration copyWith({String? user, String? password, Duration? delay}) => ReplicationConfiguration(
        user ?? this.user,
        password ?? this.password,
        delay ?? this.delay,
      );
}
