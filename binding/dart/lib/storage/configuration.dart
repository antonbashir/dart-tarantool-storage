import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'bindings.dart';
import 'constants.dart';

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
  set workDir(String? value) => _configurationMap[ConfigurationKeys.workDir] = value;
  set memtxDir(String value) => _configurationMap[ConfigurationKeys.memtxDir] = value;
  set walDir(String value) => _configurationMap[ConfigurationKeys.walDir] = value;
  set vinylDir(String value) => _configurationMap[ConfigurationKeys.vinylDir] = value;
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
  set walMode(String value) => _configurationMap[ConfigurationKeys.walMode] = value;
  set walMaxSize(int value) => _configurationMap[ConfigurationKeys.walMaxSize] = value;
  set walDirRescanDelay(int value) => _configurationMap[ConfigurationKeys.walDirRescanDelay] = value;
  set walQueueMaxSize(int value) => _configurationMap[ConfigurationKeys.walQueueMaxSize] = value;
  set walCleanupDelay(int value) => _configurationMap[ConfigurationKeys.walCleanupDelay] = value;
  set forceRecovery(bool value) => _configurationMap[ConfigurationKeys.forceRecovery] = value;
  set replication(String? value) => _configurationMap[ConfigurationKeys.replication] = value;
  set instanceUuid(String? value) => _configurationMap[ConfigurationKeys.instanceUuid] = value;
  set replicasetUuid(String? value) => _configurationMap[ConfigurationKeys.replicasetUuid] = value;
  set customProcTitle(String? value) => _configurationMap[ConfigurationKeys.customProcTitle] = value;
  set pidFile(int? value) => _configurationMap[ConfigurationKeys.pidFile] = value;
  set background(bool value) => _configurationMap[ConfigurationKeys.background] = value;
  set username(String? value) => _configurationMap[ConfigurationKeys.username] = value;
  set coredump(bool value) => _configurationMap[ConfigurationKeys.coredump] = value;
  set readOnly(bool value) => _configurationMap[ConfigurationKeys.readOnly] = value;
  set hotStandby(bool value) => _configurationMap[ConfigurationKeys.hotStandby] = value;
  set memtxUseMvccEngine(bool value) => _configurationMap[ConfigurationKeys.memtxUseMvccEngine] = value;
  set checkpointInterval(int value) => _configurationMap[ConfigurationKeys.checkpointInterval] = value;
  set checkpointWalThreshold(double value) => _configurationMap[ConfigurationKeys.checkpointWalThreshold] = value;
  set checkpointCount(int value) => _configurationMap[ConfigurationKeys.checkpointCount] = value;
  set workerPoolThreads(int value) => _configurationMap[ConfigurationKeys.workerPoolThreads] = value;
  set electionMode(String value) => _configurationMap[ConfigurationKeys.electionMode] = value;
  set electionTimeout(int value) => _configurationMap[ConfigurationKeys.electionTimeout] = value;
  set replicationTimeout(int value) => _configurationMap[ConfigurationKeys.replicationTimeout] = value;
  set replicationSyncLag(int value) => _configurationMap[ConfigurationKeys.replicationSyncLag] = value;
  set replicationSyncTimeout(int value) => _configurationMap[ConfigurationKeys.replicationSyncTimeout] = value;
  set replicationSynchroQuorum(int value) => _configurationMap[ConfigurationKeys.replicationSynchroQuorum] = value;
  set replicationSynchroTimeout(int value) => _configurationMap[ConfigurationKeys.replicationSynchroTimeout] = value;
  set replicationConnectTimeout(int value) => _configurationMap[ConfigurationKeys.replicationConnectTimeout] = value;
  set replicationConnectQuorum(int? value) => _configurationMap[ConfigurationKeys.replicationConnectQuorum] = value;
  set replicationSkipConflict(bool value) => _configurationMap[ConfigurationKeys.replicationSkipConflict] = value;
  set replicationAnon(bool value) => _configurationMap[ConfigurationKeys.replicationAnon] = value;
  set feedbackEnabled(bool value) => _configurationMap[ConfigurationKeys.feedbackEnabled] = value;
  set feedbackCrashinfo(bool value) => _configurationMap[ConfigurationKeys.feedbackCrashinfo] = value;
  set feedbackHost(String value) => _configurationMap[ConfigurationKeys.feedbackHost] = value;
  set feedbackInterval(int value) => _configurationMap[ConfigurationKeys.feedbackInterval] = value;
  set netMsgMax(int value) => _configurationMap[ConfigurationKeys.netMsgMax] = value;
  set sqlCacheSize(int value) => _configurationMap[ConfigurationKeys.sqlCacheSize] = value;
  set logLevel(int value) => _configurationMap[ConfigurationKeys.logLevel] = value;
  set log(String value) => _configurationMap[ConfigurationKeys.log] = value;

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
}
