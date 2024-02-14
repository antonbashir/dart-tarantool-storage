import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart' as ffi;
import 'package:linux_interactor/linux_interactor.dart';
import 'bindings.dart';
import 'configuration.dart';
import 'constants.dart';
import 'exception.dart';
import 'executor.dart';
import 'lookup.dart';
import 'script.dart';

class Storage {
  final Map<String, InteractorNativeModule> _loadedModulesByName = {};
  final Map<String, InteractorNativeModule> _loadedModulesByPath = {};
  final StorageLibrary _library;

  late final _box = ffi.calloc<tarantool_box>(sizeOf<tarantool_box>());

  late StorageExecutor _executor;
  late bool _hasStorageLuaModule;

  StreamSubscription<ProcessSignal>? _reloadListener = null;

  Storage({String? libraryPath}) : _library = StorageLibrary.load(libraryPath: libraryPath);

  StorageExecutor get executor => _executor;

  Future<void> boot(StorageBootstrapScript script, StorageExecutorConfiguration executorConfiguration, {StorageBootConfiguration? bootConfiguration, activateReloader = false}) async {
    if (initialized()) return;
    _hasStorageLuaModule = script.hasStorageLuaModule;
    if (!ffi.using((ffi.Arena allocator) => tarantool_initialize(executorConfiguration.native(_library.path, script.write(), allocator), _box))) {
      throw StorageLauncherException(tarantool_initialization_error().cast<ffi.Utf8>().toDartString());
    }
    if (!initialized()) {
      throw StorageLauncherException(tarantool_initialization_error().cast<ffi.Utf8>().toDartString());
    }
    _executor = StorageExecutor(_box);
    await _executor.initialize();
    if (_hasStorageLuaModule && bootConfiguration != null) {
      await executor.boot(bootConfiguration);
    }
    if (activateReloader) _reloadListener = ProcessSignal.sighup.watch().listen((event) async => await reload());
  }

  bool initialized() => tarantool_initialized();

  bool mutable() => tarantool_is_read_only() == 0;

  bool immutable() => tarantool_is_read_only() == 1;

  Future<void> waitInitialized() => Future.doWhile(() => Future.delayed(awaitStateDuration).then((value) => !initialized()));

  Future<void> waitShutdown() => Future.doWhile(() => Future.delayed(awaitStateDuration).then((value) => initialized()));

  Future<void> waitImmutable() => Future.doWhile(() => Future.delayed(awaitStateDuration).then((value) => !immutable()));

  Future<void> waitMutable() => Future.doWhile(() => Future.delayed(awaitStateDuration).then((value) => !mutable()));

  Future<void> shutdown() async {
    _reloadListener?.cancel();
    await _executor.stop();
    if (!tarantool_shutdown()) {
      throw StorageLauncherException(tarantool_shutdown_error().cast<ffi.Utf8>().toDartString());
    }
    await _executor.destroy();
    //ffi.calloc.free(_box.cast());
  }

  InteractorNativeModule loadModuleByPath(String libraryPath) {
    if (_loadedModulesByPath.containsKey(libraryPath)) return _loadedModulesByPath[libraryPath]!;
    final module = InteractorNativeModule.loadByPath(libraryPath);
    _loadedModulesByName[libraryPath] = module;
    return module;
  }

  InteractorNativeModule loadModuleByName(String libraryName) {
    if (_loadedModulesByName.containsKey(libraryName)) return _loadedModulesByName[libraryName]!;
    final module = InteractorNativeModule.loadByName(libraryName);
    _loadedModulesByName[libraryName] = module;
    return module;
  }

  Future<void> reload() async {
    _loadedModulesByName.entries.toList().forEach((entry) => _loadedModulesByName[entry.key] = entry.value.reload());
    _loadedModulesByPath.entries.toList().forEach((entry) => _loadedModulesByPath[entry.key] = entry.value.reload());
    if (_hasStorageLuaModule) await executor.call(LuaExpressions.reload);
  }
}
