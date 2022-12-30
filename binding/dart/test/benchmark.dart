import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:tarantool_storage/storage/constants.dart';
import 'package:tarantool_storage/tarantool_storage.dart';
import 'package:test/scaffolding.dart';

late final StorageExecutor _executor;
late final Storage _storage;
late final StorageSpace _space;
final benchmarkDataCount = 1000000;
final benchmarkData = Iterable.generate(benchmarkDataCount, (index) => [index + 1, "key-${index}", "value"]).toList();

void main() {
  setUpAll(() async {
    Directory.current.listSync().forEach((element) {
      if (element.path.contains("00000")) element.deleteSync();
    });
    _storage = Storage(libraryPath: "${Directory.current.path}/native/$storageLibraryName")
      ..boot(StorageBootstrapScript(StorageDefaults.storage())..file(File("test/test.lua")), StorageDefaults.loop());
    _executor = _storage.executor();
    final spaceId = await _executor.schema().spaceId("test");
    _space = _executor.schema().spaceById(spaceId);
    await _executor.transactional((executor) => _space.batch((builder) => builder..insertMany(benchmarkData)));
    print("Benhcing: $benchmarkDataCount");
  });
  tearDownAll(() => _storage.shutdown());
  test("bench get", benchGet, timeout: Timeout(Duration(minutes: 30)));
  test("bench select", benchSelect, timeout: Timeout(Duration(minutes: 30)));
  test("bench batch", benchBatch, timeout: Timeout(Duration(minutes: 30)));
  test("bench execution", benchExecute, timeout: Timeout(Duration(minutes: 30)));
  test("bench iterator", benchIterator, timeout: Timeout(Duration(minutes: 30)));
  test("bench isolated get", benchIsolatedGet, timeout: Timeout(Duration(minutes: 30)));
}

Future<void> benchGet() async {
  int counter = 0;
  final completer = Completer();
  final stopwatch = Stopwatch();
  stopwatch.start();
  for (var i = 0; i < benchmarkDataCount; i++) {
    _space.get([i + 1]).then((value) {
      if (++counter >= benchmarkDataCount) {
        completer.complete(null);
      }
    });
  }
  await completer.future;
  print("Get RPS: ${benchmarkDataCount ~/ (stopwatch.elapsedMilliseconds / 1000)}");
}

Future<void> benchIsolatedGet() async {
  final stopwatch = Stopwatch();
  final isolateCount = 2;
  final ports = <ReceivePort>[];
  for (var isolateIndex = 0; isolateIndex < isolateCount; isolateIndex++) {
    ReceivePort port = ReceivePort();
    ports.add(port);
    Isolate.spawn<int>((count) async {
      final completer = Completer();
      int counter = 0;
      final storage = Storage(libraryPath: "${Directory.current.path}/native/$storageLibraryName");
      final space = await storage.executor().schema().spaceByName("test");
      for (var i = 0; i < count; i++) {
        space.get([i + 1]).then((value) {
          if (++counter >= count) {
            completer.complete(null);
          }
        });
      }
      await completer.future;
      storage.close();
    }, benchmarkDataCount, onExit: port.sendPort);
  }
  stopwatch.start();
  for (var port in ports) {
    await port.first;
  }
  print("Get RPS ($isolateCount isolates): ${(benchmarkDataCount * isolateCount) ~/ (stopwatch.elapsedMilliseconds / 1000)}");
  ports.forEach((port) => port.close());
}

Future<void> benchExecute() async {
  await _executor.evaluateLua("function test() return {'test'} end");
  int counter = 0;
  final completer = Completer();
  final stopwatch = Stopwatch();
  stopwatch.start();
  for (var i = 0; i < benchmarkDataCount; i++) {
    _executor.executeLua("test").then((value) {
      if (++counter >= benchmarkDataCount) {
        completer.complete(null);
      }
    });
  }
  await completer.future;
  print("Execute RPS: ${benchmarkDataCount ~/ (stopwatch.elapsedMilliseconds / 1000)}");
}

Future<void> benchSelect() async {
  final stopwatch = Stopwatch();
  stopwatch.start();
  await _space.select();
  print("Select seconds: ${stopwatch.elapsedMilliseconds / 1000}");
}

Future<void> benchBatch() async {
  final stopwatch = Stopwatch();
  stopwatch.start();
  await _executor.transactional((executor) => _space.batch((builder) => builder..putMany(benchmarkData)));
  print("Batch seconds: ${stopwatch.elapsedMilliseconds / 1000}");
}

Future<void> benchIterator() async {
  final stopwatch = Stopwatch();
  stopwatch.start();
  await _space.iterator().then((value) => value.collect());
  print("Iterator collect seconds: ${stopwatch.elapsedMilliseconds / 1000}");
}
