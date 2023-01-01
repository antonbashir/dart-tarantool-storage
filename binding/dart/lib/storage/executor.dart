import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:tarantool_storage/storage/constants.dart';
import 'package:tarantool_storage/storage/schema.dart';

import 'bindings.dart';
import 'exception.dart';
import 'iterator.dart';
import 'tuple.dart';

class StorageExecutor {
  late TarantoolBindings _bindings;
  late RawReceivePort _receiverPort;
  late int _nativePort;
  late StorageSchema _schema;
  final int _ownerId;

  StorageExecutor(this._bindings, this._ownerId) {
    _receiverPort = RawReceivePort(_receive);
    _nativePort = _receiverPort.sendPort.nativePort;
    _schema = StorageSchema(_bindings, this);
  }

  StorageSchema schema() => _schema;

  Future<void> transactional(FutureOr<void> Function(StorageExecutor executor) function) {
    return begin().then((_) => function(this)).then((_) => commit()).onError((error, stackTrace) => rollback());
  }

  Future<List<dynamic>> evaluateLua(String expression, {List<dynamic> arguments = const []}) => using((Arena arena) {
        final request = arena<tarantool_evaluate_request_t>();
        request.ref.expression = expression.toNativeUtf8().cast();
        request.ref.expression_length = expression.length;
        request.ref.input = TarantoolTuple.write(arena, arguments);
        final message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_evaluate.cast();
        message.ref.input = request.cast();
        return sendSingle(message).then((pointer) => TarantoolTuple.read(Pointer.fromAddress(pointer.address).cast()));
      });

  Future<void> evaluateLuaFile(File file) => file.readAsString().then(evaluateLua);

  Future<void> requireLuaModule(String module) => evaluateLua(LuaExpressions.require(module));

  Future<List<dynamic>> executeLua(String function, {List<dynamic> arguments = const []}) => using((Arena arena) {
        final request = arena<tarantool_call_request_t>();
        request.ref.function = function.toNativeUtf8().cast();
        request.ref.function_length = function.length;
        request.ref.input = TarantoolTuple.write(arena, arguments);
        final message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_call.cast();
        message.ref.input = request.cast();
        return sendSingle(message).then((pointer) => TarantoolTuple.read(Pointer.fromAddress(pointer.address).cast()));
      });

  Future<Pointer<Void>> executeNative(tarantool_function function, {tarantool_function_argument? argument}) async => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = function.cast();
        message.ref.input = argument?.cast() ?? nullptr;
        return sendSingle(message);
      });

  Future<List<dynamic>?> next(StorageIterator iterator) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_iterator_next.cast();
        message.ref.input = Pointer.fromAddress(iterator.iterator).cast();
        return sendSingle(message).then((pointer) => pointer == nullptr ? null : TarantoolTuple.read(Pointer.fromAddress(pointer.address).cast()));
      });

  Future<void> destroyIterator(StorageIterator iterator) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_iterator_destroy.cast();
        message.ref.input = Pointer.fromAddress(iterator.iterator).cast();
        return sendSingle(message);
      });

  Future<void> begin() => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_BEGIN;
        return sendSingle(message);
      });

  Future<void> commit() => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_COMMIT;
        return sendSingle(message);
      });

  Future<void> rollback() => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_ROLLBACK;
        return sendSingle(message);
      });

  Future<bool> hasTransaction() => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_in_transaction.cast();
        return sendSingle(message).then((pointer) => pointer.address != 0);
      });

  Future<void> startBackup() => evaluateLua(LuaExpressions.startBackup);

  Future<void> stopBackup() => evaluateLua(LuaExpressions.stopBackup);

  Future<void> promote() => evaluateLua(LuaExpressions.promote);

  Future<Pointer<Void>> sendSingle(Pointer<tarantool_message_t> message) {
    if (_bindings.tarantool_initialized() == 0) return Future.error(StorageShutdownException());
    message.ref.callback_send_port = _nativePort;
    message.ref.owner = _ownerId;
    final completer = Completer<Pointer<tarantool_message_t>>();
    if (!_bindings.tarantool_send_message(message, completer.complete)) {
      completer.completeError(StorageLimitException(), StackTrace.current);
    }
    return completer.future.then((value) {
      if (value.ref.error != nullptr) {
        return hasTransaction().then((has) => has ? rollback().then((_) => _handleSingleError(value)) : _handleSingleError(value));
      }
      return value.ref.output;
    });
  }

  Future<Pointer<tarantool_message_t>> sendBatch(Pointer<tarantool_message_t> message) {
    if (_bindings.tarantool_initialized() == 0) return Future.error(StorageShutdownException());
    message.ref.callback_send_port = _nativePort;
    message.ref.owner = _ownerId;
    final completer = Completer<Pointer<tarantool_message_t>>();
    if (!_bindings.tarantool_send_message(message, completer.complete)) {
      completer.completeError(StorageLimitException(), StackTrace.current);
    }
    return completer.future.then((value) {
      if (value.ref.error != nullptr) {
        return hasTransaction().then((has) => has ? rollback().then((_) => _handleBatchError(value)) : _handleBatchError(value));
      }
      return value;
    });
  }

  void close() => _receiverPort.close();

  Future<Pointer<Void>> _handleSingleError(Pointer<tarantool_message_t> value) {
    Future<Pointer<Void>> future = Future.error(
      value.ref.error_type == tarantool_error_type.TARANTOOL_ERROR_INTERNAL ? StorageExecutionException(value.ref.error.cast<Utf8>().toDartString()) : StorageLimitException(),
      StackTrace.current,
    );
    malloc.free(value.ref.error);
    return future;
  }

  Future<Pointer<tarantool_message_t>> _handleBatchError(Pointer<tarantool_message_t> value) {
    if (value.ref.error_type == tarantool_error_type.TARANTOOL_ERROR_LIMIT) return Future.error(StorageLimitException(), StackTrace.current);
    StringBuffer error = StringBuffer(value.ref.error.cast<Utf8>().toDartString());
    for (var index = 0; index < value.ref.batch_size; index++) {
      final batch = value.ref.batch.elementAt(index).value.ref;
      if (batch.error != nullptr) {
        error.writeln(batch.error.cast<Utf8>().toDartString());
        malloc.free(batch.error);
      }
    }
    malloc.free(value.ref.error);
    return Future.error(StorageExecutionException(error.toString()), StackTrace.current);
  }

  void _receive(dynamic message) {
    Pointer<tarantool_message_t> messagePointer = Pointer.fromAddress(message);
    Object callback = _bindings.dart_get_handle_from_message(messagePointer);
    _bindings.dart_delete_handle_from_message(messagePointer);
    final callback_as_function = callback as void Function(Pointer<dynamic>);
    callback_as_function(messagePointer);
  }
}
