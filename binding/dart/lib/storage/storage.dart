import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'configuration.dart';
import 'constants.dart';
import 'executor/executor.dart';
import 'lookup.dart';
import 'script.dart';

class Storage {
  Map<String, StorageNativeModule> _loadedModulesByName = {};
  Map<String, StorageNativeModule> _loadedModulesByPath = {};

  late TarantoolBindings _bindings;
  late StorageLibrary _library;
  late StorageExecutor _executor;
  late RawReceivePort _shutdownPort;
  final bool activateReloader;

  StreamSubscription<ProcessSignal>? _reloadListener = null;
  bool _hasStorageLuaModule = false;

  Storage({String? libraryPath, this.activateReloader = false}) {
    _library = libraryPath != null
        ? File(libraryPath).existsSync()
            ? StorageLibrary(DynamicLibrary.open(libraryPath), libraryPath)
            : loadBindingLibrary()
        : loadBindingLibrary();
    _bindings = TarantoolBindings(_library.library);
    _executor = StorageExecutor(_bindings, _bindings.tarantool_generate_owner_id());
    _shutdownPort = RawReceivePort((_) => close());
  }

  StorageExecutor get executor => _executor;

  StorageLibrary get library => _library;

  TarantoolBindings get bindings => _bindings;

  Future<void> boot(StorageBootstrapScript script, StorageMessageLoopConfiguration loop, {StorageBootConfiguration? boot}) async {
    if (initialized()) return;
    _hasStorageLuaModule = script.hasStorageLuaModule;
    final nativeConfiguration = loop.native(_library.path);
    nativeConfiguration.ref.shutdown_port = _shutdownPort.sendPort.nativePort;
    _bindings.tarantool_initialize(
      Platform.executable.toNativeUtf8().cast<Char>(),
      script.write().toNativeUtf8().cast(),
      nativeConfiguration,
    );
    malloc.free(nativeConfiguration);
    if (_hasStorageLuaModule && boot != null) {
      await executor.lua.call(LuaExpressions.boot, arguments: [boot.user, boot.password]);
    }
    if (boot != null) {
      await Future.delayed(boot.delay);
    }
    await executor.lua.promote();
    if (activateReloader) _reloadListener = ProcessSignal.sighup.watch().listen((event) => reload());
  }

  bool mutable() => _bindings.tarantool_is_read_only() == 0;

  bool initialized() => _bindings.tarantool_initialized() == 1;

  bool immutable() => _bindings.tarantool_is_read_only() == 1;

  Future<void> awaitInitialized() => Future.doWhile(() => Future.delayed(awaitStateDuration).then((value) => !initialized()));

  Future<void> awaitImmutable() => Future.doWhile(() => Future.delayed(awaitStateDuration).then((value) => !immutable()));

  Future<void> awaitMutable() => Future.doWhile(() => Future.delayed(awaitStateDuration).then((value) => !mutable()));

  void shutdown() => _bindings.tarantool_shutdown(0);

  void close() {
    _executor.close();
    _shutdownPort.close();
    _reloadListener?.cancel();
  }

  StorageNativeModule loadModuleByPath(String libraryPath) {
    if (_loadedModulesByPath.containsKey(libraryPath)) return _loadedModulesByPath[libraryPath]!;
    final module = StorageNativeModule._loadByFile(libraryPath);
    _loadedModulesByName[libraryPath] = module;
    return module;
  }

  StorageNativeModule loadModuleByName(String libraryName) {
    if (_loadedModulesByName.containsKey(libraryName)) return _loadedModulesByName[libraryName]!;
    final module = StorageNativeModule._loadByName(libraryName);
    _loadedModulesByName[libraryName] = module;
    return module;
  }

  Future<void> reload() async {
    _loadedModulesByName.entries.forEach((entry) => _loadedModulesByName[entry.key] = entry.value._reload());
    _loadedModulesByPath.entries.forEach((entry) => _loadedModulesByPath[entry.key] = entry.value._reload());
    if (_hasStorageLuaModule) await executor.lua.call(LuaExpressions.reload);
  }

  void execute(void Function(StorageExecutor executor) executor) => executor(_executor);
}

class StorageNativeModule {
  final String libraryName;
  final String libraryPath;
  final DynamicLibrary library;

  const StorageNativeModule._(this.libraryName, this.libraryPath, this.library);

  static StorageNativeModule _loadByFile(String library) => StorageNativeModule._(
        library,
        library,
        Platform.isLinux ? DynamicLibrary.open(library) : throw UnsupportedError(loadError),
      );

  static StorageNativeModule _loadByName(String name) {
    name = name + dot + FileExtensions.so;
    try {
      return StorageNativeModule._(
        Directory.current.path + slash + name,
        Directory.current.path + slash + name,
        Platform.isLinux ? DynamicLibrary.open(name) : throw UnsupportedError(loadError),
      );
    } on ArgumentError {
      final projectRoot = findProjectRoot();
      if (projectRoot == null) throw UnsupportedError(loadError);
      final libraryFile = File(projectRoot + Directories.native + slash + name);
      if (libraryFile.existsSync()) {
        return StorageNativeModule._(name, libraryFile.path, DynamicLibrary.open(libraryFile.path));
      }
      throw UnsupportedError(loadError);
    }
  }

  void _unload() => _dlClose(library.handle);

  StorageNativeModule _reload() {
    _unload();
    return _loadByFile(libraryPath);
  }

  int Function(Pointer<Void>) get _dlClose => _standartLibrary.lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(dlCloseFunction).asFunction();

  DynamicLibrary get _standartLibrary => DynamicLibrary.process();
}
