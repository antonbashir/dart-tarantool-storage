import 'dart:io';

import 'package:tarantool_storage/tarantool_storage.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main(List<String> args) => test("test replica ${args[0]}", () async {
      final storage = Storage();
      final workDirectory = Directory(Directory.current.path + "/test/tarantool_${int.parse(args[0].toString())}");
      final bootConfiguration = StorageDefaults.boot();
      final configuration = StorageDefaults.storage().copyWith(
        listen: args[0].toString(),
        replication: StorageReplicationConfiguration()
            .addAddressReplica("127.0.0.1", args[1], user: bootConfiguration.user, password: bootConfiguration.password)
            .addAddressReplica("127.0.0.1", args[2], user: bootConfiguration.user, password: bootConfiguration.password)
            .addAddressReplica("127.0.0.1", args[3], user: bootConfiguration.user, password: bootConfiguration.password)
            .format(),
        workDir: workDirectory.path,
      );
      if (workDirectory.existsSync()) {
        workDirectory.deleteSync(recursive: true);
      }
      workDirectory.createSync();
      await storage.boot(
        StorageBootstrapScript(configuration)..includeStorageLuaModule(),
        StorageDefaults.executor(),
        bootConfiguration: StorageDefaults.boot(randomizeDelay: true),
      );
      await storage.waitInitialized();
      expect(storage.initialized(), equals(true));
      await Future.delayed(Duration(seconds: 1));
      storage.shutdown();
      workDirectory.deleteSync(recursive: true);
    });
