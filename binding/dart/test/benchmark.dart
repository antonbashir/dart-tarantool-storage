import 'dart:async';
import 'dart:io';

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
    _storage = Storage(libraryPath: "${Directory.current.path}/native/$storageLibraryName")..boot(BootstrapScript(StorageDefaults.storage())..file(File("test/test.lua")), StorageDefaults.loop());
    _executor = _storage.executor();
    final spaceId = await _executor.spaceId("test");
    _space = _executor.space(spaceId);
    await _executor.transactional((executor) => _space.batch((builder) => builder..insertMany(benchmarkData)));
    print("Benhcing: $benchmarkDataCount");
  });
  tearDownAll(() => _storage.shutdown());
  test("bench get", benchGet, timeout: Timeout(Duration(minutes: 30)));
  test("bench select", benchSelect, timeout: Timeout(Duration(minutes: 30)));
  test("bench batch", benchBatch, timeout: Timeout(Duration(minutes: 30)));
  test("bench execution", benchExecute, timeout: Timeout(Duration(minutes: 30)));
  test("bench iterator", benchIterator, timeout: Timeout(Duration(minutes: 30)));
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

Future<void> benchExecute() async {
  await _executor.evaluateLuaScript("function test() return {'test'} end");
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
  final iterator = await _space.iterator();
  final stopwatch = Stopwatch();
  stopwatch.start();
  await iterator.collect();
  print("Iterator collect seconds: ${stopwatch.elapsedMilliseconds / 1000}");
}
