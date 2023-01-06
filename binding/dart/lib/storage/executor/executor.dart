import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../exception.dart';
import '../schema/iterator.dart';
import '../schema/schema.dart';
import '../tuple.dart';
import 'lua.dart';
import 'native.dart';

class StorageExecutor {
  late TarantoolBindings _bindings;
  late RawReceivePort _receiverPort;
  late int _nativePort;
  late StorageSchema _schema;
  late StorageNativeExecutor _native;
  late StorageLuaExecutor _lua;
  late TarantoolTupleDescriptor _descriptor;
  final int _ownerId;

  StorageExecutor(this._bindings, this._ownerId) {
    _receiverPort = RawReceivePort(_receive);
    _nativePort = _receiverPort.sendPort.nativePort;
    _native = StorageNativeExecutor(this);
    _descriptor = TarantoolTupleDescriptor(_bindings);
    _lua = StorageLuaExecutor(_bindings, this, _descriptor);
    _schema = StorageSchema(_bindings, this, _descriptor);
  }

  StorageSchema get schema => _schema;

  StorageNativeExecutor get native => _native;

  StorageLuaExecutor get lua => _lua;

  Future<List<dynamic>?> next(StorageIterator iterator) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_iterator_next.cast();
    message.ref.input = Pointer.fromAddress(iterator.iterator).cast();
    return sendSingle(message, freeInput: false).then((pointer) => pointer == nullptr ? null : _descriptor.read(Pointer.fromAddress(pointer.address).cast()));
  }

  Future<void> destroyIterator(StorageIterator iterator) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_iterator_destroy.cast();
    message.ref.input = Pointer.fromAddress(iterator.iterator).cast();
    return sendSingle(message, freeInput: false);
  }

  Future<void> begin() {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_BEGIN;
    return sendSingle(message, freeInput: false);
  }

  Future<void> commit() {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_COMMIT;
    return sendSingle(message, freeInput: false);
  }

  Future<void> rollback() {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_ROLLBACK;
    return sendSingle(message, freeInput: false);
  }

  Future<void> transactional(FutureOr<void> Function(StorageExecutor executor) function) {
    return begin().then((_) => function(this)).then((_) => commit()).onError((error, stackTrace) => rollback());
  }

  Future<bool> hasTransaction() {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_in_transaction.cast();
    return sendSingle(message, freeInput: false).then((pointer) => pointer.address != 0);
  }

  Future<Pointer<Void>> sendSingle(Pointer<tarantool_message_t> message, {required freeInput}) {
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
      if (freeInput) calloc.free(value.ref.input);
      calloc.free(value);
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

  Future<Pointer<Void>> _handleSingleError(Pointer<tarantool_message_t> message) {
    Future<Pointer<Void>> future = Future.error(
      StorageExecutionException(message.ref.error.cast<Utf8>().toDartString()),
      StackTrace.current,
    );
    calloc.free(message.ref.error);
    calloc.free(message);
    return future;
  }

  Future<Pointer<tarantool_message_t>> _handleBatchError(Pointer<tarantool_message_t> message) {
    if (message.ref.error_type == tarantool_error_type.TARANTOOL_ERROR_LIMIT) return Future.error(StorageLimitException(), StackTrace.current);
    StringBuffer error = StringBuffer(message.ref.error.cast<Utf8>().toDartString());
    for (var index = 0; index < message.ref.batch_size; index++) {
      Pointer<tarantool_message_batch_element_t> batch = message.ref.batch[index];
      if (batch.ref.error != nullptr) {
        error.writeln(batch.ref.error.cast<Utf8>().toDartString());
        calloc.free(batch.ref.error);
      }
      calloc.free(batch);
    }
    calloc.free(message.ref.batch);
    calloc.free(message.ref.error);
    calloc.free(message);
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
