import 'dart:collection';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../extensions.dart';
import '../bindings.dart';
import '../constants.dart';
import '../tuple.dart';

import 'updater.dart';

class StorageBatchSpaceBuilder {
  final Queue<Pointer<tarantool_message_batch_element_t>> _batches = ListQueue(batchInitiaSize);
  final TarantoolBindings _bindings;
  final int _id;
  final TarantoolTupleDescriptor _descriptor;

  StorageBatchSpaceBuilder(this._bindings, this._id, this._descriptor);

  void insert(List<dynamic> data) {
    Pointer<tarantool_message_batch_element_t> message = calloc<tarantool_message_batch_element_t>();
    message.ref.function = _bindings.addresses.tarantool_space_insert.cast();
    final request = calloc<tarantool_space_request_t>();
    request.ref.space_id = _id;
    request.ref.tuple = _descriptor.write(data);
    message.ref.input = request.cast();
    _batches.add(message);
  }

  void put(List<dynamic> data) {
    Pointer<tarantool_message_batch_element_t> message = calloc<tarantool_message_batch_element_t>();
    message.ref.function = _bindings.addresses.tarantool_space_put.cast();
    final request = calloc<tarantool_space_request_t>();
    request.ref.space_id = _id;
    request.ref.tuple = _descriptor.write(data);
    message.ref.input = request.cast();
    _batches.add(message);
  }

  void delete(List<dynamic> data) {
    Pointer<tarantool_message_batch_element_t> message = calloc<tarantool_message_batch_element_t>();
    message.ref.function = _bindings.addresses.tarantool_space_delete.cast();
    final request = calloc<tarantool_space_request_t>();
    request.ref.space_id = _id;
    request.ref.tuple = _descriptor.write(data);
    message.ref.input = request.cast();
    _batches.add(message);
  }

  void update(List<dynamic> key, List<StorageUpdateOperation> operations) {
    Pointer<tarantool_message_batch_element_t> message = calloc<tarantool_message_batch_element_t>();
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
    _batches.add(message);
  }

  void upsert(List<dynamic> tuple, List<StorageUpdateOperation> operations) {
    Pointer<tarantool_message_batch_element_t> message = calloc<tarantool_message_batch_element_t>();
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
    _batches.add(message);
  }

  void insertMany(List<List<dynamic>> data) => data.forEach(insert);

  void putMany(List<List<dynamic>> data) => data.forEach(put);

  void deleteMany(List<List<dynamic>> data) => data.forEach(delete);

  Pointer<tarantool_message_t> build() {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_BATCH;
    final Pointer<Pointer<tarantool_message_batch_element_t>> batchData = calloc.allocate(sizeOf<Pointer<tarantool_message_batch_element_t>>() * _batches.length);
    var batchIndex = 0;
    message.ref.batch_size = _batches.length;
    while (_batches.isNotEmpty) {
      batchData[batchIndex] = _batches.removeFirst();
      batchIndex++;
    }
    message.ref.batch = batchData;
    return message;
  }
}

class StorageBatchIndexBuilder {
  final Queue<Pointer<tarantool_message_batch_element_t>> batches = ListQueue(batchInitiaSize);
  final TarantoolBindings _bindings;
  final int _spaceId;
  final int _indexId;
  final TarantoolTupleDescriptor _descriptor;

  StorageBatchIndexBuilder(this._bindings, this._spaceId, this._indexId, this._descriptor);

  void update(List<dynamic> key, List<StorageUpdateOperation> operations) {
    Pointer<tarantool_message_batch_element_t> message = calloc<tarantool_message_batch_element_t>();
    message.ref.function = _bindings.addresses.tarantool_index_update.cast();
    final request = calloc<tarantool_index_update_request_t>();
    request.ref.space_id = _spaceId;
    request.ref.index_id = _indexId;
    request.ref.key = _descriptor.write(key);
    request.ref.operations = _descriptor.write(operations
        .map((operation) => [
              operation.type.operation(),
              operation.field,
              operation.value,
            ])
        .toList());
    message.ref.input = request.cast();
    batches.add(message);
  }

  Pointer<tarantool_message_t> build() {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_BATCH;
    final Pointer<Pointer<tarantool_message_batch_element_t>> batchData = calloc.allocate(sizeOf<Pointer<tarantool_message_batch_element_t>>() * batches.length);
    var batchIndex = 0;
    message.ref.batch_size = batches.length;
    while (batches.isNotEmpty) {
      batchData[batchIndex] = batches.removeFirst();
      batchIndex++;
    }
    message.ref.batch = batchData;
    return message;
  }
}
