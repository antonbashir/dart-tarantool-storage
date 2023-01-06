import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../constants.dart';
import 'executor.dart';
import '../tuple.dart';

class StorageLuaExecutor {
  final TarantoolBindings _bindings;
  final StorageExecutor _executor;

  const StorageLuaExecutor(this._bindings, this._executor);

  Future<List<dynamic>> script(String expression, {List<dynamic> arguments = const []}) => using((Arena arena) {
        final request = arena<tarantool_evaluate_request_t>();
        request.ref.expression = expression.toNativeUtf8().cast();
        request.ref.expression_length = expression.length;
        request.ref.input = TarantoolTuple.write(arena, arguments);
        final message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_evaluate.cast();
        message.ref.input = request.cast();
        return _executor.sendSingle(message).then((pointer) => TarantoolTuple.read(Pointer.fromAddress(pointer.address).cast()));
      });

  Future<void> file(File file) => file.readAsString().then(script);

  Future<void> require(String module) => script(LuaExpressions.require(module));

  Future<List<dynamic>> call(String function, {List<dynamic> arguments = const []}) => using((Arena arena) {
        final request = arena<tarantool_call_request_t>();
        request.ref.function = function.toNativeUtf8().cast();
        request.ref.function_length = function.length;
        request.ref.input = TarantoolTuple.write(arena, arguments);
        final message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_call.cast();
        message.ref.input = request.cast();
        return _executor.sendSingle(message).then((pointer) => TarantoolTuple.read(Pointer.fromAddress(pointer.address).cast()));
      });
}
