import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'bindings.dart';
import 'configuration.dart';
import 'constants.dart';
import 'lookup.dart';
import 'script.dart';

import 'executor.dart';

class Storage {
  final List<StorageExecutor> _executors = [];

  late TarantoolBindings _bindings;
  late DynamicLibrary _library;
  late StorageExecutor _defaultExecutor;
  late int _ownerId;
  late RawReceivePort _shutdownPort;

  Storage({String? libraryPath, void Function()? onShutdown}) {
    _library = libraryPath != null
        ? File(libraryPath).existsSync()
            ? DynamicLibrary.open(libraryPath)
            : loadBindingLibrary()
        : loadBindingLibrary();
    _bindings = TarantoolBindings(_library);
    _ownerId = _bindings.tarantool_generate_owner_id();
    _defaultExecutor = executor();
    _shutdownPort = RawReceivePort(() {
      onShutdown?.call();
      close();
    });
  }

  void boot(BootstrapScript script, MessageLoopConfiguration loopConfiguration) {
    if (initialized()) return;
    final nativeConfiguration = loopConfiguration.native();
    nativeConfiguration.ref.shutdown_port = _shutdownPort.sendPort.nativePort;
    _bindings.tarantool_initialize(
      Platform.executable.toNativeUtf8().cast<Char>(),
      script.write().toNativeUtf8().cast(),
      nativeConfiguration,
    );
    malloc.free(nativeConfiguration);
  }

  bool mutable() => !_bindings.tarantool_is_read_only();

  bool initialized() => _bindings.tarantool_initialized();

  bool immutable() => _bindings.tarantool_is_read_only();

  Future<void> awaitInitialized() => Future.doWhile(() => Future.delayed(awaitStateDuration).then((value) => !initialized()));

  Future<void> awaitImmutable() => Future.doWhile(() => Future.delayed(awaitStateDuration).then((value) => !immutable()));

  Future<void> awaitMutable() => Future.doWhile(() => Future.delayed(awaitStateDuration).then((value) => mutable()));

  void shutdown() => _bindings.tarantool_shutdown(0);

  void close() {
    _executors.forEach((executor) => executor.close());
    _shutdownPort.close();
  }

  StorageExecutor executor() {
    final executor = StorageExecutor(_bindings, _ownerId);
    _executors.add(executor);
    return executor;
  }

  void execute(void Function(StorageExecutor executor) executor) => executor(_defaultExecutor);
}
