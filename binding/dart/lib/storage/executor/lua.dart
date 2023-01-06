import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:tarantool_storage/storage/configuration.dart';

import '../bindings.dart';
import '../constants.dart';
import 'executor.dart';
import '../tuple.dart';

class StorageLuaExecutor {
  final TarantoolBindings _bindings;
  final StorageExecutor _executor;
  final TarantoolTupleDescriptor _descriptor;

  const StorageLuaExecutor(this._bindings, this._executor, this._descriptor);

  Future<void> startBackup() => script(LuaExpressions.startBackup);

  Future<void> stopBackup() => script(LuaExpressions.stopBackup);

  Future<void> promote() => script(LuaExpressions.promote);

  Future<void> configure(StorageConfiguration configuration) => script(configuration.format());

  Future<List<dynamic>> script(String expression, {List<dynamic> arguments = const []}) {
    final request = calloc<tarantool_evaluate_request_t>();
    request.ref.expression = expression.toNativeUtf8().cast();
    request.ref.expression_length = expression.length;
    request.ref.input = _descriptor.write(arguments);
    final message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_evaluate.cast();
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => _descriptor.read(Pointer.fromAddress(pointer.address).cast()));
  }

  Future<void> file(File file) => file.readAsString().then(script);

  Future<void> require(String module) => script(LuaExpressions.require(module));

  Future<List<dynamic>> call(String function, {List<dynamic> arguments = const []}) {
    final request = calloc<tarantool_call_request_t>();
    request.ref.function = function.toNativeUtf8().cast();
    request.ref.function_length = function.length;
    request.ref.input = _descriptor.write(arguments);
    final message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_call.cast();
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => _descriptor.read(Pointer.fromAddress(pointer.address).cast()));
  }
}
