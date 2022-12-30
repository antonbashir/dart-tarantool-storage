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
  late TarantoolBindings _bindings;
  late DynamicLibrary _library;
  late StorageExecutor _executor;
  late RawReceivePort _shutdownPort;

  Storage({String? libraryPath}) {
    _library = libraryPath != null
        ? File(libraryPath).existsSync()
            ? DynamicLibrary.open(libraryPath)
            : loadBindingLibrary()
        : loadBindingLibrary();
    _bindings = TarantoolBindings(_library);
    _executor = StorageExecutor(_bindings, _bindings.tarantool_generate_owner_id());
    _shutdownPort = RawReceivePort((_) => close());
  }

  void boot(StorageBootstrapScript script, StorageMessageLoopConfiguration loopConfiguration) {
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
  }

  StorageExecutor executor() => _executor;

  DynamicLibrary library() => _library;

  void execute(void Function(StorageExecutor executor) executor) => executor(_executor);
}
