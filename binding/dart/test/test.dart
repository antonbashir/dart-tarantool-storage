@Timeout(Duration(seconds: 60))

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:tarantool_storage/storage/bindings.dart';
import 'package:tarantool_storage/storage/constants.dart';
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
    final spaceId = await _executor.spaceId("test");
    _space = _executor.spaceById(spaceId);
    _index = _executor.indexById(spaceId, await _executor.indexId(spaceId, "test"));
  });

  setUp(() async => await _space.truncate());

  tearDownAll(() => _storage.shutdown());

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
    test("multi isolate batch", testMultiIsolateInsert);
    test("multi isolate transactional batch", testMultiIsolateTransactionalInsert);
  });

  group("[execution]", () {
    test("execute native", testExecuteNative);
    test("execute lua", testExecuteLua);
  });

  test("pairs iterator", testIterator);
}

Future<void> testExecuteLua() async {
  await _executor.evaluateLuaScript("function test() return {'test'} end");
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
  final count = 100;
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
      await storage.executor().spaceByName("test").then((space) => space.insert(element));
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
  final count = 100;
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
      await executor.spaceByName("test").then((space) => executor.transactional((executor) => space.insert(element)));
      storage.close();
    }, element, onExit: port.sendPort);
  }
  for (var port in ports) {
    await port.first;
  }
  ports.forEach((port) => port.close());
  expect(await _space.select(), equals(data));
}
