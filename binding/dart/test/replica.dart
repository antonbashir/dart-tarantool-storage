import 'dart:io';

import 'package:tarantool_storage/tarantool_storage.dart';

void main(List<String> args) {
  final storage = Storage();
  final configuration = StorageDefaults.storage();
  configuration.listen = int.parse(args[0].toString());
  configuration.replication = "{'replicator:replicator@127.0.0.1:3301', 'replicator:replicator@127.0.0.1:3302', 'replicator:replicator@127.0.0.1:3303'}";
  configuration.workDir = "tarantool_${configuration.listen.toString()}";
  Directory(configuration.workDir = Directory.current.path + "/tarantool_" + configuration.listen.toString()).createSync();
  storage.boot(
      StorageBootstrapScript(configuration)
        ..includeStorageLuaModule()
        ..includeLuaModulePath(Directory.current.parent.path + "/" + "lua"),
      StorageDefaults.loop(),
      replicationConfiguration: StorageDefaults.replication());
  print(storage.mutable());
  storage.shutdown();
}
