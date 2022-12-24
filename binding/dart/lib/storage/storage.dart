import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'bindings.dart';
import 'configuration.dart';
import 'lookup.dart';
import 'script.dart';

import 'executor.dart';

class Storage {
  final List<StorageExecutor> executors = [];

  late TarantoolBindings _bindings;
  late DynamicLibrary _library;
  late StorageExecutor _defaultExecutor;

  Storage({String? libraryPath}) {
    _library = libraryPath != null
        ? File(libraryPath).existsSync()
            ? DynamicLibrary.open(libraryPath)
            : loadBindingLibrary()
        : loadBindingLibrary();
    _bindings = TarantoolBindings(_library);
    _defaultExecutor = executor();
  }

  void boot(BootstrapScript script, MessageLoopConfiguration loopConfiguration) {
    if (initialized()) return;
    final nativeConfiguration = loopConfiguration.native();
    print(script.write());
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

  void shutdown() {
    _bindings.tarantool_shutdown(0);
    executors.forEach((executor) => executor.close());
  }

  StorageExecutor executor() {
    final executor = StorageExecutor(_bindings);
    executors.add(executor);
    return executor;
  }

  void execute(void Function(StorageExecutor executor) executor) => executor(_defaultExecutor);
}
