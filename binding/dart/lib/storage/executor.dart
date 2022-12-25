import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'constants.dart';
import 'exception.dart';
import 'index.dart';
import 'iterator.dart';
import 'space.dart';
import 'tuple.dart';

import 'bindings.dart';

class StorageExecutor {
  late TarantoolBindings _bindings;
  late RawReceivePort _receiverPort;
  late int _nativePort;
  var _transactional = false;

  StorageExecutor(this._bindings) {
    _receiverPort = RawReceivePort(_receive);
    _nativePort = _receiverPort.sendPort.nativePort;
  }

  Future<void> transactional(FutureOr<void> Function(StorageExecutor executor) function) {
    return begin().then((_) => function(this)).then((_) => commit()).onError((error, stackTrace) => rollback());
  }

  StorageSpace space(int id) => StorageSpace(_bindings, this, id);

  StorageIndex index(int spaceId, int indexId) => StorageIndex(_bindings, this, spaceId, indexId);

  Future<int> spaceId(String space) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_space_id_by_name.cast();
        final request = arena<tarantool_space_id_request_t>();
        request.ref.name = space.toNativeUtf8().cast();
        request.ref.name_length = space.length;
        message.ref.input = request.cast();
        return sendSingle(message).then((pointer) => pointer.address);
      });

  Future<int> indexId(int spaceId, String index) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_index_id_by_name.cast();
        final request = arena<tarantool_index_id_request_t>();
        request.ref.space_id = spaceId;
        request.ref.name = index.toNativeUtf8().cast();
        request.ref.name_length = index.length;
        message.ref.input = request.cast();
        return sendSingle(message).then((pointer) => pointer.address);
      });

  Future<void> evaluateLuaScript(String script) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_evaluate.cast();
        message.ref.input = script.toNativeUtf8().cast();
        return sendSingle(message);
      });

  Future<void> evaluateLuaFile(File file) => file.readAsString().then(evaluateLuaScript);

  Future<void> requireLua(String module) => evaluateLuaScript(luaRequireScript(module));

  Future<List<dynamic>> executeLua(String function, {List<dynamic> argument = const []}) => using((Arena arena) {
        final request = arena<tarantool_call_request_t>();
        request.ref.function = function.toNativeUtf8().cast();
        request.ref.function_length = function.length;
        request.ref.input = TarantoolTuple.write(arena, argument);
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

  Future<List<dynamic>> next(StorageIterator iterator) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_iterator_next.cast();
        message.ref.input = Pointer.fromAddress(iterator.iterator).cast();
        return sendSingle(message).then((pointer) => TarantoolTuple.read(Pointer.fromAddress(pointer.address).cast()));
      });

  Future<void> destroyIterator(StorageIterator iterator) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_iterator_destroy.cast();
        message.ref.input = Pointer.fromAddress(iterator.iterator).cast();
        return sendSingle(message);
      });

  Future<void> begin() => using((Arena arena) {
        _transactional = true;
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_BEGIN;
        return sendSingle(message);
      });

  Future<void> commit() => using((Arena arena) {
        _transactional = false;
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_COMMIT;
        return sendSingle(message);
      });

  Future<void> rollback() => using((Arena arena) {
        _transactional = false;
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_ROLLBACK;
        return sendSingle(message);
      });

  Future<Pointer<Void>> sendSingle(Pointer<tarantool_message_t> message) {
    if (!_bindings.tarantool_initialized()) return Future.error(StorageShutdownException());
    message.ref.transactional = _transactional;
    message.ref.callback_send_port = _nativePort;
    final completer = Completer<Pointer<tarantool_message_t>>();
    _bindings.tarantool_send_message(message, completer.complete);
    return completer.future.then((value) => value.ref.output);
  }

  Future<Pointer<tarantool_message_t>> sendBatch(Pointer<tarantool_message_t> message) {
    if (!_bindings.tarantool_initialized()) return Future.error(StorageShutdownException());
    message.ref.callback_send_port = _nativePort;
    final completer = Completer<Pointer<tarantool_message_t>>();
    _bindings.tarantool_send_message(message, completer.complete);
    return completer.future;
  }

  void close() => _receiverPort.close();

  void _receive(dynamic message) {
    Pointer<tarantool_message_t> messagePointer = Pointer.fromAddress(message);
    Object callback = _bindings.dart_get_handle_from_message(messagePointer);
    _bindings.dart_delete_handle_from_message(messagePointer);
    final callback_as_function = callback as void Function(Pointer<dynamic>);
    callback_as_function(messagePointer);
  }
}
