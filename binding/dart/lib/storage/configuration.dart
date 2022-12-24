import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'bindings.dart';
import 'constants.dart';

class StorageConfiguration {
  final Map<String, dynamic> configurationMap;

  const StorageConfiguration(this.configurationMap);

  set listen(int? value) => configurationMap["listen"] = value;
  set memtxMemory(int value) => configurationMap["memtx_memory"] = value;
  set stripCore(bool value) => configurationMap["strip_core"] = value;
  set memtxMinTupleSize(int value) => configurationMap["memtx_min_tuple_size"] = value;
  set memtxMaxTupleSize(int value) => configurationMap["memtx_max_tuple_size"] = value;
  set slabAllocGranularity(int value) => configurationMap["slab_alloc_granularity"] = value;
  set slabAllocFactor(double value) => configurationMap["slab_alloc_factor"] = value;
  set iprotoThreads(int value) => configurationMap["iproto_threads"] = value;
  set workDir(String? value) => configurationMap["work_dir"] = value;
  set memtxDir(String value) => configurationMap["memtx_dir"] = value;
  set walDir(String value) => configurationMap["wal_dir"] = value;

  set vinylDir(String value) => configurationMap["vinyl_dir"] = value;
  set vinylMemory(int value) => configurationMap["vinyl_memory"] = value;
  set vinylCache(int value) => configurationMap["vinyl_cache"] = value;
  set vinylMaxTupleSize(int value) => configurationMap["vinyl_max_tuple_size"] = value;
  set vinylReadThreads(int value) => configurationMap["vinyl_read_threads"] = value;
  set vinylWriteThreads(int value) => configurationMap["vinyl_write_threads"] = value;
  set vinylTimeout(int value) => configurationMap["vinyl_timeout"] = value;
  set vinylRunCountPerLevel(int value) => configurationMap["vinyl_run_count_per_level"] = value;
  set vinylRunSizeRatio(double value) => configurationMap["vinyl_run_size_ratio"] = value;
  set vinylRangeSize(int? value) => configurationMap["vinyl_range_size"] = value;
  set vinylPageSize(int value) => configurationMap["vinyl_page_size"] = value;
  set vinylBloomFpr(double value) => configurationMap["vinyl_bloom_fpr"] = value;

  set ioCollectInterval(int? value) => configurationMap["io_collect_interval"] = value;
  set readahead(int value) => configurationMap["readahead"] = value;
  set snapIoRateLimit(int? value) => configurationMap["snap_io_rate_limit"] = value;
  set tooLongThreshold(double value) => configurationMap["too_long_threshold"] = value;
  set walMode(String value) => configurationMap["wal_mode"] = value;
  set walMaxSize(int value) => configurationMap["wal_max_size"] = value;
  set walDirRescanDelay(int value) => configurationMap["wal_dir_rescan_delay"] = value;
  set walQueueMaxSize(int value) => configurationMap["wal_queue_max_size"] = value;
  set walCleanupDelay(int value) => configurationMap["wal_cleanup_delay"] = value;
  set forceRecovery(bool value) => configurationMap["force_recovery"] = value;
  set replication(String? value) => configurationMap["replication"] = value;
  set instanceUuid(String? value) => configurationMap["instance_uuid"] = value;
  set replicasetUuid(String? value) => configurationMap["replicaset_uuid"] = value;
  set customProcTitle(String? value) => configurationMap["custom_proc_title"] = value;
  set pidFile(int? value) => configurationMap["pid_file"] = value;
  set background(bool value) => configurationMap["background"] = value;
  set username(String? value) => configurationMap["username"] = value;
  set coredump(bool value) => configurationMap["coredump"] = value;
  set readOnly(bool value) => configurationMap["read_only"] = value;
  set hotStandby(bool value) => configurationMap["hot_standby"] = value;
  set memtxUseMvccEngine(bool value) => configurationMap["memtx_use_mvcc_engine"] = value;
  set checkpointInterval(int value) => configurationMap["checkpoint_interval"] = value;
  set checkpointWalThreshold(double value) => configurationMap["checkpoint_wal_threshold"] = value;
  set checkpointCount(int value) => configurationMap["checkpoint_count"] = value;
  set workerPoolThreads(int value) => configurationMap["worker_pool_threads"] = value;
  set electionMode(String value) => configurationMap["election_mode"] = value;
  set electionTimeout(int value) => configurationMap["election_timeout"] = value;
  set replicationTimeout(int value) => configurationMap["replication_timeout"] = value;
  set replicationSyncLag(int value) => configurationMap["replication_sync_lag"] = value;
  set replicationSyncTimeout(int value) => configurationMap["replication_sync_timeout"] = value;
  set replicationSynchroQuorum(int value) => configurationMap["replication_synchro_quorum"] = value;
  set replicationSynchroTimeout(int value) => configurationMap["replication_synchro_timeout"] = value;
  set replicationConnectTimeout(int value) => configurationMap["replication_connect_timeout"] = value;
  set replicationConnectQuorum(int? value) => configurationMap["replication_connect_quorum"] = value;
  set replicationSkipConflict(bool value) => configurationMap["replication_skip_conflict"] = value;
  set replicationAnon(bool value) => configurationMap["replication_anon"] = value;
  set feedbackEnabled(bool value) => configurationMap["feedback_enabled"] = value;
  set feedbackCrashinfo(bool value) => configurationMap["feedback_crashinfo"] = value;
  set feedbackHost(String value) => configurationMap["feedback_host"] = value;
  set feedbackInterval(int value) => configurationMap["feedback_interval"] = value;
  set netMsgMax(int value) => configurationMap["net_msg_max"] = value;
  set sqlCacheSize(int value) => configurationMap["sql_cache_size"] = value;

  String write() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln(boxCfgPrefix);
    configurationMap.forEach((key, value) {
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
  final double messageLoopRegularSleepSeconds;
  final int messageLoopMaxEmptyCycles;
  final int messageLoopEmptyCyclesMultiplier;
  final int messageLoopInitialEmptyCycles;

  const MessageLoopConfiguration({
    required this.boxOutputBufferCapacity,
    required this.messageLoopMaxSleepSeconds,
    required this.messageLoopRegularSleepSeconds,
    required this.messageLoopMaxEmptyCycles,
    required this.messageLoopEmptyCyclesMultiplier,
    required this.messageLoopInitialEmptyCycles,
  });

  Pointer<tarantool_configuration_t> native() {
    Pointer<tarantool_configuration_t> configuration = malloc<tarantool_configuration_t>();
    configuration.ref.box_output_buffer_capacity = boxOutputBufferCapacity;
    configuration.ref.message_loop_empty_cycles_multiplier = messageLoopEmptyCyclesMultiplier;
    configuration.ref.message_loop_max_empty_cycles = messageLoopMaxEmptyCycles;
    configuration.ref.message_loop_initial_empty_cycles = messageLoopInitialEmptyCycles;
    configuration.ref.message_loop_regular_sleep_seconds = messageLoopRegularSleepSeconds;
    configuration.ref.message_loop_max_sleep_seconds = messageLoopMaxSleepSeconds;
    return configuration;
  }
}
