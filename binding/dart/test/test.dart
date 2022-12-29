@Timeout(Duration(seconds: 60))

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:tarantool_storage/storage/bindings.dart';
import 'package:tarantool_storage/storage/constants.dart';
import 'package:tarantool_storage/storage/schema.dart';
import 'package:tarantool_storage/tarantool_storage.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

late final StorageExecutor _executor;
late final Storage _storage;
late final StorageSpace _space;
late final StorageIndex _index;
final testKey = ["key"];
final testSingleData = [1, "key", "value"];
final testMultipleData = Iterable.generate(10, (index) => [index + 1, "key-${index}", "value"]).toList();

void main() {
  setUpAll(() async {
    Directory.current.listSync().forEach((element) {
      if (element.path.contains("00000")) element.deleteSync();
    });
    _storage = Storage(libraryPath: "${Directory.current.path}/native/$storageLibraryName")..boot(BootstrapScript(StorageDefaults.storage())..file(File("test/test.lua")), StorageDefaults.loop());
    _executor = _storage.executor();
    final spaceId = await _executor.schema().spaceId("test");
    _space = _executor.schema().spaceById(spaceId);
    _index = _executor.schema().indexById(spaceId, await _executor.schema().indexId(spaceId, "test"));
  });

  setUp(() async => await _space.truncate());

  tearDownAll(() => _storage.shutdown());

  group(["schema"], () {
    test("schema operations", testSchema);
  });

  group("[crud]", () {
    test("insert", () async => expect(await _space.insert(testSingleData), equals(testSingleData)));
    test("put", () async => expect(await _space.put(testSingleData), equals(testSingleData)));
    test("get", () async {
      _space.insert(testSingleData);
      expect(await _space.get([1]), equals(testSingleData));
    });
    test("min", () async {
      _space.insert(testSingleData);
      expect(await _space.min(), equals(testSingleData));
    });
    test("max", () async {
      _space.insert(testSingleData);
      expect(await _space.min(), equals(testSingleData));
    });
    test("update", () async {
      final data = [...testSingleData];
      _space.insert(data);
      data[2] = "updated";
      expect(await _space.update([1], [UpdateOperation(UpdateOperationType.assign, 2, "updated")]), equals(data));
    });
    test("delete", () async {
      _space.insert(testSingleData);
      expect(await _space.delete([1]), equals(testSingleData));
    });
    test("isEmpty", () async => expect(await _space.isEmpty(), equals(true)));
    test("count", () async {
      _space.insert(testSingleData);
      expect(await _space.count(), equals(1));
    });
    test("select", () async {
      await Future.wait(testMultipleData.map(_space.insert));
      expect(await _space.select(), equals(testMultipleData));
      expect(await _index.select(), equals(testMultipleData));
    });

    test("get by index", () async {
      _space.insert(testSingleData);
      expect(await _index.get(["key"]), equals(testSingleData));
    });
    test("min by index", () async {
      _space.insert(testSingleData);
      expect(await _index.min(), equals(testSingleData));
    });
    test("max by index", () async {
      _space.insert(testSingleData);
      expect(await _index.min(), equals(testSingleData));
    });
    test("update by index", () async {
      final data = [...testSingleData];
      _space.insert(data);
      data[2] = "updated by index";
      expect(await _index.update(["key"], [UpdateOperation(UpdateOperationType.assign, 2, "updated by index")]), equals(data));
    });

    test("batch insert", () async {
      expect(await _space.batch((builder) => builder..insertMany(testMultipleData)), equals(testMultipleData));
    });
    test("batch put", () async {
      expect(await _space.batch((builder) => builder..putMany(testMultipleData)), equals(testMultipleData));
    });
    test("batch update", () async {
      await _space.batch((builder) => builder..insertMany(testMultipleData));
      final data = [];
      data.add([...testMultipleData[0]]);
      data.add([...testMultipleData[1]]);
      data[0][2] = "updated";
      data[1][2] = "updated";
      expect(
          await _space.batch((builder) => builder
            ..update([1], [UpdateOperation(UpdateOperationType.assign, 2, "updated")])
            ..update([2], [UpdateOperation(UpdateOperationType.assign, 2, "updated")])),
          equals(data));
    });
    test("batch index update", () async {
      await _space.batch((builder) => builder..insertMany(testMultipleData));
      final data = [];
      data.add([...testMultipleData[0]]);
      data.add([...testMultipleData[1]]);
      data[0][2] = "updated";
      data[1][2] = "updated";
      expect(
          await _index.batch((builder) => builder
            ..update(["key-0"], [UpdateOperation(UpdateOperationType.assign, 2, "updated")])
            ..update(["key-1"], [UpdateOperation(UpdateOperationType.assign, 2, "updated")])),
          equals(data));
    });
    test("pairs iterator", testIterator);
    test("fail with error", () async {
      await _space.insert(testSingleData);
      expect(
          () async => await _space.insert(testSingleData),
          throwsA(predicate((exception) =>
              exception is StorageExecutionException &&
              exception.toString() == """Duplicate key exists in unique index "primary" in space "test" with old tuple - [1, "key", "value"] and new tuple - [1, "key", "value"]""")));
    });
  });

  group("[isolate crud]", () {
    test("multi isolate batch", testMultiIsolateInsert);
    test("multi isolate transactional batch", testMultiIsolateTransactionalInsert);
  });

  group("[execution]", () {
    test("execute native", testExecuteNative);
    test("execute lua", testExecuteLua);
  });
}

Future<void> testSchema() async {
  await _executor.schema().createSpace(
        "test-space",
        engine: StorageEngine.memtx,
        fieldCount: 3,
        format: [
          SpaceField.string("field-1"),
          SpaceField.boolean("field-2"),
          SpaceField.integer("field-3"),
        ],
        id: 3,
        ifNotExists: true,
      );
  expect(await _executor.executeLua("validateCreatedSpace"), equals([true]));
  expect(await _executor.schema().spaceExists("test-space"), isTrue);

  await _executor.schema().createIndex(
    "test-space",
    "test-index",
    id: 0,
    ifNotExists: true,
    type: IndexType.hash,
    unique: true,
    parts: [
      IndexPart.byName("field-1"),
      IndexPart.integer(3),
    ],
  );
  expect(await _executor.executeLua("validateCreatedIndex"), equals([true]));
  expect(await _executor.schema().indexExists(3, "test-index"), isTrue);

  await _executor.schema().createUser("test-user", "test-password", ifNotExists: true);
  expect(await _executor.schema().userExists("test-user"), isTrue);
  await _executor.schema().userGrant("test-user", privileges: "read", objectType: "space", objectName: "test", ifNotExists: true);
  try {
    await _executor.schema().userGrant("test-user", privileges: "write", objectType: "universe");
  } catch (error) {
    expect(
      error,
      predicate((exception) => exception is StorageExecutionException && exception.toString() == "User 'test-user' already has write access on universe"),
    );
  }
  await _executor.schema().userRevoke("test-user", privileges: "read", objectType: "space", objectName: "test", ifNotExists: true);
  await _executor.schema().userRevoke("test-user", privileges: "write", objectType: "universe", ifNotExists: true);
  await _executor.schema().dropUser("test-user");
  expect(await _executor.schema().userExists("test-user"), isFalse);

  await _executor.schema().dropIndex("test-space", "test-index");
  expect(await _executor.schema().indexExists(3, "test-index"), isFalse);

  await _executor.schema().dropSpace("test-space");
  expect(await _executor.schema().spaceExists("test-space"), isFalse);
}

Future<void> testExecuteLua() async {
  await _executor.evaluateLua("function test() return {'test'} end");
  File("test.lua").writeAsStringSync("function testFile() return {'testFile'} end");
  await _executor.evaluateLuaFile(File("test.lua"));
  File("test.lua").deleteSync();
  expect(
      await _executor.executeLua("test"),
      equals([
        ["test"]
      ]));
  expect(
      await _executor.executeLua("testFile"),
      equals([
        ["testFile"]
      ]));
}

Future<void> testExecuteNative() async {
  expect(
      (await _executor.executeNative(
        TarantoolBindings(DynamicLibrary.open("${Directory.current.path}/native/$storageLibraryName")).addresses.tarantool_is_read_only.cast(),
      ))
          .address,
      equals(0));
}

Future<void> testIterator() async {
  await Future.wait(testMultipleData.map(_space.insert));
  expect(await (await _space.iterator()).next(), equals(testMultipleData[0]));
  expect(await (await _space.iterator()).collect(), equals(testMultipleData));
  expect(await (await _index.iterator()).collect(), equals(testMultipleData));
  expect(
    await (await _space.iterator()).collect(map: (value) => value[2], filter: (value) => value[0] != 3, offset: 1, limit: 3),
    equals(testMultipleData.where((element) => element[0] != 3).skip(1).take(2).map((data) => data[2]).toList()),
  );
}

Future<void> testMultiIsolateInsert() async {
  final count = 1000;
  final ports = <ReceivePort>[];
  final data = [];
  for (var i = 0; i < count; i++) {
    ReceivePort port = ReceivePort();
    ports.add(port);
    final element = [...testSingleData];
    element[0] = i + 1;
    element[1] = "key-${i + 1}";
    data.add(element);
    Isolate.spawn<dynamic>((element) async {
      final storage = Storage(libraryPath: "${Directory.current.path}/native/$storageLibraryName");
      await storage.executor().schema().spaceByName("test").then((space) => space.insert(element));
      storage.close();
    }, element, onExit: port.sendPort);
  }
  for (var port in ports) {
    await port.first;
  }
  ports.forEach((port) => port.close());
  expect(await _space.select(), equals(data));
}

Future<void> testMultiIsolateTransactionalInsert() async {
  final count = 1000;
  final ports = <ReceivePort>[];
  final data = [];
  for (var i = 0; i < count; i++) {
    ReceivePort port = ReceivePort();
    ports.add(port);
    final element = [...testSingleData];
    element[0] = i + 1;
    element[1] = "key-${i + 1}";
    data.add(element);
    Isolate.spawn<dynamic>((element) async {
      final storage = Storage(libraryPath: "${Directory.current.path}/native/$storageLibraryName");
      final executor = storage.executor();
      await executor.schema().spaceByName("test").then((space) => executor.transactional((executor) => space.insert(element)));
      storage.close();
    }, element, onExit: port.sendPort);
  }
  for (var port in ports) {
    await port.first;
  }
  ports.forEach((port) => port.close());
  expect(await _space.length(), equals(data.length));
  expect(await _space.select(), containsAll(data));
}
