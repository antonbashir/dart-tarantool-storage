import 'dart:async';
import 'dart:collection';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import '../executor/executor.dart';
import '../extensions.dart';
import '../bindings.dart';
import '../constants.dart';
import '../tuple.dart';

import 'batch.dart';
import 'updater.dart';
import 'iterator.dart';

class StorageSpace {
  final TarantoolBindings _bindings;
  final StorageExecutor _executor;
  final int _id;
  final TarantoolTupleDescriptor _descriptor;

  const StorageSpace(this._bindings, this._executor, this._id, this._descriptor);

  Future<int> count({List<dynamic> key = const [], StorageIteratorType iteratorType = StorageIteratorType.eq}) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_space_count.cast();
    final request = calloc<tarantool_space_count_request_t>();
    request.ref.space_id = _id;
    request.ref.iterator_type = iteratorType.index;
    request.ref.key = _descriptor.write(key);
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => pointer.address);
  }

  Future<bool> isEmpty() => length().then((value) => value == 0);

  Future<bool> isNotEmpty() => length().then((value) => value != 0);

  Future<int> length() {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_space_length.cast();
    message.ref.input = Pointer.fromAddress(_id).cast();
    return _executor.sendSingle(message).then((pointer) => pointer.address);
  }

  Future<StorageIterator> iterator({List<dynamic> key = const [], StorageIteratorType iteratorType = StorageIteratorType.eq}) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_space_iterator.cast();
    final request = calloc<tarantool_space_iterator_request_t>();
    request.ref.space_id = _id;
    request.ref.type = iteratorType.index;
    request.ref.key = _descriptor.write(key);
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => pointer.address).then((iterator) => StorageIterator(_executor, iterator));
  }

  Future<List<dynamic>> insert(List<dynamic> data) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_space_insert.cast();
    final request = calloc<tarantool_space_request_t>();
    request.ref.space_id = _id;
    request.ref.tuple = _descriptor.write(data);
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => _descriptor.read(Pointer.fromAddress(pointer.address).cast()));
  }

  Future<List<dynamic>> put(List<dynamic> data) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_space_put.cast();
    final request = calloc<tarantool_space_request_t>();
    request.ref.space_id = _id;
    request.ref.tuple = _descriptor.write(data);
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => _descriptor.read(Pointer.fromAddress(pointer.address).cast()));
  }

  Future<List<dynamic>> get(List<dynamic> key) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_space_get.cast();
    final request = calloc<tarantool_space_request_t>();
    request.ref.space_id = _id;
    request.ref.tuple = _descriptor.write(key);
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => _descriptor.read(Pointer.fromAddress(pointer.address).cast()));
  }

  Future<List<dynamic>> delete(List<dynamic> key) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_space_delete.cast();
    final request = calloc<tarantool_space_request_t>();
    request.ref.space_id = _id;
    request.ref.tuple = _descriptor.write(key);
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => _descriptor.read(Pointer.fromAddress(pointer.address).cast()));
  }

  Future<List<dynamic>> min({List<dynamic> key = const []}) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_space_min.cast();
    final request = calloc<tarantool_space_request_t>();
    request.ref.space_id = _id;
    request.ref.tuple = _descriptor.write(key);
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => _descriptor.read(Pointer.fromAddress(pointer.address).cast()));
  }

  Future<List<dynamic>> max({List<dynamic> key = const []}) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_space_max.cast();
    final request = calloc<tarantool_space_request_t>();
    request.ref.space_id = _id;
    request.ref.tuple = _descriptor.write(key);
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => _descriptor.read(Pointer.fromAddress(pointer.address).cast()));
  }

  Future<void> truncate() {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_space_truncate.cast();
    message.ref.input = Pointer.fromAddress(_id);
    return _executor.sendSingle(message);
  }

  Future<List<dynamic>> update(List<dynamic> key, List<StorageUpdateOperation> operations) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_space_update.cast();
    final request = calloc<tarantool_space_update_request_t>();
    request.ref.space_id = _id;
    request.ref.key = _descriptor.write(key);
    request.ref.operations = _descriptor.write(operations
        .map((operation) => [
              operation.type.operation(),
              operation.field,
              operation.value,
            ])
        .toList());
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => _descriptor.read(Pointer.fromAddress(pointer.address).cast()));
  }

  Future<List<dynamic>> upsert(List<dynamic> tuple, List<StorageUpdateOperation> operations) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_space_upsert.cast();
    final request = calloc<tarantool_space_upsert_request_t>();
    request.ref.space_id = _id;
    request.ref.tuple = _descriptor.write(tuple);
    request.ref.operations = _descriptor.write(operations
        .map((operation) => [
              operation.type.operation(),
              operation.field,
              operation.value,
            ])
        .toList());
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => _descriptor.read(Pointer.fromAddress(pointer.address).cast()));
  }

  Future<List<dynamic>> select({
    List<dynamic> key = const [],
    int offset = 0,
    int limit = int32Max,
    StorageIteratorType iteratorType = StorageIteratorType.eq,
  }) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_space_select.cast();
    final request = calloc<tarantool_space_select_request_t>();
    request.ref.space_id = _id;
    request.ref.key = _descriptor.write(key);
    request.ref.iterator_type = iteratorType.index;
    request.ref.offset = offset;
    request.ref.limit = limit;
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => _descriptor.read(Pointer.fromAddress(pointer.address).cast()));
  }

  Future<List<dynamic>> batch(StorageBatchSpaceBuilder Function(StorageBatchSpaceBuilder builder) builder) {
    Pointer<tarantool_message_t> message = builder(StorageBatchSpaceBuilder(_bindings, _id, _descriptor)).build();
    return _executor.sendBatch(message).then((message) {
      Queue<dynamic> outputs = ListQueue(message.ref.batch_size);
      for (var i = 0; i < message.ref.batch_size; i++) {
        Pointer<tarantool_message_batch_element_t> batch = message.ref.batch[i];
        outputs.add(_descriptor.read(batch.ref.output.cast()));
        calloc.free(batch);
      }
      calloc.free(message.ref.batch);
      calloc.free(message);
      return outputs.toList();
    });
  }
}
