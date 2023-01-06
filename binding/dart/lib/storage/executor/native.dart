import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'executor.dart';

import '../bindings.dart';

class StorageNativeExecutor {
  final StorageExecutor _executor;

  const StorageNativeExecutor(this._executor);

  Future<Pointer<Void>> call(tarantool_function function, {tarantool_function_argument? argument}) async {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = function.cast();
    message.ref.input = argument?.cast() ?? nullptr;
    return _executor.sendSingle(message, freeInput: false);
  }
}
