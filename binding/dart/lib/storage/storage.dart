import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'configuration.dart';
import 'constants.dart';
import 'executor.dart';
import 'lookup.dart';
import 'script.dart';

class Storage {
  List<StorageNativeModule> _loadedModules = [];

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

  Future<void> boot(StorageBootstrapScript script, StorageMessageLoopConfiguration loopConfiguration, {ReplicationConfiguration? replicationConfiguration}) async {
    if (initialized()) return;
    _hasStorageLuaModule = script.hasStorageLuaModule;
    final nativeConfiguration = loopConfiguration.native(_library.path);
    nativeConfiguration.ref.shutdown_port = _shutdownPort.sendPort.nativePort;
    _bindings.tarantool_initialize(
      Platform.executable.toNativeUtf8().cast<Char>(),
      script.write().toNativeUtf8().cast(),
      nativeConfiguration,
    );
    malloc.free(nativeConfiguration);
    if (_hasStorageLuaModule && replicationConfiguration != null) {
      await executor().executeLua(LuaExpressions.boot, arguments: [
        replicationConfiguration.user,
        replicationConfiguration.password,
        replicationConfiguration.delay.inSeconds,
      ]);
    }
    if (activateReloader) _reloadListener = ProcessSignal.sighup.watch().listen((event) => reload());
  }

  bool mutable() => _bindings.tarantool_is_read_only() == 0;

  bool initialized() => _bindings.tarantool_initialized() == 1;

  bool immutable() => _bindings.tarantool_is_read_only() == 1;

  Future<void> awaitInitialized() => Future.doWhile(() => Future.delayed(awaitStateDuration).then((value) => !initialized()));

  Future<void> awaitImmutable() => Future.doWhile(() => Future.delayed(awaitStateDuration).then((value) => !immutable()));

  Future<void> awaitMutable() => Future.doWhile(() => Future.delayed(awaitStateDuration).then((value) => mutable()));

  void shutdown() => _bindings.tarantool_shutdown(0);

  void close() {
    _executor.close();
    _shutdownPort.close();
    _reloadListener?.cancel();
  }

  StorageExecutor executor() => _executor;

  StorageLibrary library() => _library;

  StorageNativeModule loadModuleByFile(String libraryPath) {
    final module = StorageNativeModule._loadByFile(libraryPath);
    _loadedModules.add(module);
    return module;
  }

  StorageNativeModule loadModuleByName(String libraryName) {
    final module = StorageNativeModule._loadByName(libraryName);
    _loadedModules.add(module);
    return module;
  }

  Future<void> reload() async {
    final _newLopaded = <StorageNativeModule>[];
    _loadedModules.forEach((module) => _newLopaded.add(module._reload()));
    _loadedModules = _newLopaded;
    if (_hasStorageLuaModule) await executor().executeLua(LuaExpressions.reload);
  }

  void execute(void Function(StorageExecutor executor) executor) => executor(_executor);
}

class StorageNativeModule {
  final String libraryName;
  final String libraryPath;
  final DynamicLibrary library;

  const StorageNativeModule._(this.libraryName, this.libraryPath, this.library);

  static StorageNativeModule _loadByFile(String library) {
    try {
      return StorageNativeModule._(
        library,
        Directory.current.path + slash + library,
        Platform.isLinux ? DynamicLibrary.open(library) : throw UnsupportedError(loadError),
      );
    } on ArgumentError {
      final projectRoot = findProjectRoot();
      if (projectRoot == null) throw UnsupportedError(loadError);
      final libraryFile = File(projectRoot + Directories.native + slash + library);
      if (libraryFile.existsSync()) return StorageNativeModule._(library, libraryFile.path, DynamicLibrary.open(libraryFile.path));
      throw UnsupportedError(loadError);
    }
  }

  static StorageNativeModule _loadByName(String name) {
    name = name + dot + FileExtensions.so;
    try {
      return StorageNativeModule._(
        name,
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
