import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'bindings.dart';
import 'constants.dart';

class StorageConfiguration {
  final Map<String, dynamic> _configurationMap;

  const StorageConfiguration(this._configurationMap);

  set listen(int? value) => _configurationMap["listen"] = value;
  set memtxMemory(int value) => _configurationMap["memtx_memory"] = value;
  set stripCore(bool value) => _configurationMap["strip_core"] = value;
  set memtxMinTupleSize(int value) => _configurationMap["memtx_min_tuple_size"] = value;
  set memtxMaxTupleSize(int value) => _configurationMap["memtx_max_tuple_size"] = value;
  set slabAllocGranularity(int value) => _configurationMap["slab_alloc_granularity"] = value;
  set slabAllocFactor(double value) => _configurationMap["slab_alloc_factor"] = value;
  set iprotoThreads(int value) => _configurationMap["iproto_threads"] = value;
  set workDir(String? value) => _configurationMap["work_dir"] = value;
  set memtxDir(String value) => _configurationMap["memtx_dir"] = value;
  set walDir(String value) => _configurationMap["wal_dir"] = value;

  set vinylDir(String value) => _configurationMap["vinyl_dir"] = value;
  set vinylMemory(int value) => _configurationMap["vinyl_memory"] = value;
  set vinylCache(int value) => _configurationMap["vinyl_cache"] = value;
  set vinylMaxTupleSize(int value) => _configurationMap["vinyl_max_tuple_size"] = value;
  set vinylReadThreads(int value) => _configurationMap["vinyl_read_threads"] = value;
  set vinylWriteThreads(int value) => _configurationMap["vinyl_write_threads"] = value;
  set vinylTimeout(int value) => _configurationMap["vinyl_timeout"] = value;
  set vinylRunCountPerLevel(int value) => _configurationMap["vinyl_run_count_per_level"] = value;
  set vinylRunSizeRatio(double value) => _configurationMap["vinyl_run_size_ratio"] = value;
  set vinylRangeSize(int? value) => _configurationMap["vinyl_range_size"] = value;
  set vinylPageSize(int value) => _configurationMap["vinyl_page_size"] = value;
  set vinylBloomFpr(double value) => _configurationMap["vinyl_bloom_fpr"] = value;

  set ioCollectInterval(int? value) => _configurationMap["io_collect_interval"] = value;
  set readahead(int value) => _configurationMap["readahead"] = value;
  set snapIoRateLimit(int? value) => _configurationMap["snap_io_rate_limit"] = value;
  set tooLongThreshold(double value) => _configurationMap["too_long_threshold"] = value;
  set walMode(String value) => _configurationMap["wal_mode"] = value;
  set walMaxSize(int value) => _configurationMap["wal_max_size"] = value;
  set walDirRescanDelay(int value) => _configurationMap["wal_dir_rescan_delay"] = value;
  set walQueueMaxSize(int value) => _configurationMap["wal_queue_max_size"] = value;
  set walCleanupDelay(int value) => _configurationMap["wal_cleanup_delay"] = value;
  set forceRecovery(bool value) => _configurationMap["force_recovery"] = value;
  set replication(String? value) => _configurationMap["replication"] = value;
  set instanceUuid(String? value) => _configurationMap["instance_uuid"] = value;
  set replicasetUuid(String? value) => _configurationMap["replicaset_uuid"] = value;
  set customProcTitle(String? value) => _configurationMap["custom_proc_title"] = value;
  set pidFile(int? value) => _configurationMap["pid_file"] = value;
  set background(bool value) => _configurationMap["background"] = value;
  set username(String? value) => _configurationMap["username"] = value;
  set coredump(bool value) => _configurationMap["coredump"] = value;
  set readOnly(bool value) => _configurationMap["read_only"] = value;
  set hotStandby(bool value) => _configurationMap["hot_standby"] = value;
  set memtxUseMvccEngine(bool value) => _configurationMap["memtx_use_mvcc_engine"] = value;
  set checkpointInterval(int value) => _configurationMap["checkpoint_interval"] = value;
  set checkpointWalThreshold(double value) => _configurationMap["checkpoint_wal_threshold"] = value;
  set checkpointCount(int value) => _configurationMap["checkpoint_count"] = value;
  set workerPoolThreads(int value) => _configurationMap["worker_pool_threads"] = value;
  set electionMode(String value) => _configurationMap["election_mode"] = value;
  set electionTimeout(int value) => _configurationMap["election_timeout"] = value;
  set replicationTimeout(int value) => _configurationMap["replication_timeout"] = value;
  set replicationSyncLag(int value) => _configurationMap["replication_sync_lag"] = value;
  set replicationSyncTimeout(int value) => _configurationMap["replication_sync_timeout"] = value;
  set replicationSynchroQuorum(int value) => _configurationMap["replication_synchro_quorum"] = value;
  set replicationSynchroTimeout(int value) => _configurationMap["replication_synchro_timeout"] = value;
  set replicationConnectTimeout(int value) => _configurationMap["replication_connect_timeout"] = value;
  set replicationConnectQuorum(int? value) => _configurationMap["replication_connect_quorum"] = value;
  set replicationSkipConflict(bool value) => _configurationMap["replication_skip_conflict"] = value;
  set replicationAnon(bool value) => _configurationMap["replication_anon"] = value;
  set feedbackEnabled(bool value) => _configurationMap["feedback_enabled"] = value;
  set feedbackCrashinfo(bool value) => _configurationMap["feedback_crashinfo"] = value;
  set feedbackHost(String value) => _configurationMap["feedback_host"] = value;
  set feedbackInterval(int value) => _configurationMap["feedback_interval"] = value;
  set netMsgMax(int value) => _configurationMap["net_msg_max"] = value;
  set sqlCacheSize(int value) => _configurationMap["sql_cache_size"] = value;

  set logLevel(int value) => _configurationMap["log_level"] = value;
  set log(String value) => _configurationMap["log"] = value;

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

class MessageLoopConfiguration {
  final int boxOutputBufferCapacity;
  final double messageLoopMaxSleepSeconds;
  final int messageLoopRingSize;
  final double messageLoopRegularSleepSeconds;
  final int messageLoopMaxEmptyCycles;
  final int messageLoopEmptyCyclesMultiplier;
  final int messageLoopInitialEmptyCycles;
  final int messageLoopRingRetryMaxCount;

  const MessageLoopConfiguration({
    required this.boxOutputBufferCapacity,
    required this.messageLoopMaxSleepSeconds,
    required this.messageLoopRegularSleepSeconds,
    required this.messageLoopMaxEmptyCycles,
    required this.messageLoopEmptyCyclesMultiplier,
    required this.messageLoopInitialEmptyCycles,
    required this.messageLoopRingSize,
    required this.messageLoopRingRetryMaxCount,
  });

  Pointer<tarantool_configuration_t> native() {
    Pointer<tarantool_configuration_t> configuration = malloc<tarantool_configuration_t>();
    configuration.ref.box_output_buffer_capacity = boxOutputBufferCapacity;
    configuration.ref.message_loop_empty_cycles_multiplier = messageLoopEmptyCyclesMultiplier;
    configuration.ref.message_loop_max_empty_cycles = messageLoopMaxEmptyCycles;
    configuration.ref.message_loop_initial_empty_cycles = messageLoopInitialEmptyCycles;
    configuration.ref.message_loop_regular_sleep_seconds = messageLoopRegularSleepSeconds;
    configuration.ref.message_loop_max_sleep_seconds = messageLoopMaxSleepSeconds;
    configuration.ref.message_loop_ring_size = messageLoopRingSize;
    configuration.ref.message_loop_ring_retry_max_count = messageLoopRingRetryMaxCount;
    return configuration;
  }
}
