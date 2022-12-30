import 'dart:collection';
import 'dart:ffi';

import 'extensions.dart';
import 'bindings.dart';
import 'constants.dart';
import 'tuple.dart';
import 'updater.dart';

class StorageBatchSpaceBuilder {
  final Queue<Pointer<tarantool_message_batch_element_t>> _batches = ListQueue(batchInitiaSize);
  final TarantoolBindings _bindings;
  final int _id;
  final Allocator _allocator;

  StorageBatchSpaceBuilder(this._bindings, this._id, this._allocator);

  void insert(List<dynamic> data) {
    Pointer<tarantool_message_batch_element_t> message = _allocator<tarantool_message_batch_element_t>();
    message.ref.function = _bindings.addresses.tarantool_space_insert.cast();
    final request = _allocator<tarantool_space_request_t>();
    request.ref.space_id = _id;
    request.ref.tuple = TarantoolTuple.write(_allocator, data);
    message.ref.input = request.cast();
    _batches.add(message);
  }

  void put(List<dynamic> data) {
    Pointer<tarantool_message_batch_element_t> message = _allocator<tarantool_message_batch_element_t>();
    message.ref.function = _bindings.addresses.tarantool_space_put.cast();
    final request = _allocator<tarantool_space_request_t>();
    request.ref.space_id = _id;
    request.ref.tuple = TarantoolTuple.write(_allocator, data);
    message.ref.input = request.cast();
    _batches.add(message);
  }

  void delete(List<dynamic> data) {
    Pointer<tarantool_message_batch_element_t> message = _allocator<tarantool_message_batch_element_t>();
    message.ref.function = _bindings.addresses.tarantool_space_delete.cast();
    final request = _allocator<tarantool_space_request_t>();
    request.ref.space_id = _id;
    request.ref.tuple = TarantoolTuple.write(_allocator, data);
    message.ref.input = request.cast();
    _batches.add(message);
  }

  void update(List<dynamic> key, List<StorageUpdateOperation> operations) {
    Pointer<tarantool_message_batch_element_t> message = _allocator<tarantool_message_batch_element_t>();
    message.ref.function = _bindings.addresses.tarantool_space_update.cast();
    final request = _allocator<tarantool_space_update_request_t>();
    request.ref.space_id = _id;
    request.ref.key = TarantoolTuple.write(_allocator, key);
    request.ref.operations = TarantoolTuple.write(
        _allocator,
        operations
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
    Pointer<tarantool_message_batch_element_t> message = _allocator<tarantool_message_batch_element_t>();
    message.ref.function = _bindings.addresses.tarantool_space_upsert.cast();
    final request = _allocator<tarantool_space_upsert_request_t>();
    request.ref.space_id = _id;
    request.ref.tuple = TarantoolTuple.write(_allocator, tuple);
    request.ref.operations = TarantoolTuple.write(
        _allocator,
        operations
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
    Pointer<tarantool_message_t> message = _allocator<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_BATCH;
    final Pointer<Pointer<tarantool_message_batch_element_t>> batchData = _allocator.allocate(sizeOf<Pointer<tarantool_message_batch_element_t>>() * _batches.length);
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
  final Allocator _allocator;

  StorageBatchIndexBuilder(this._bindings, this._spaceId, this._indexId, this._allocator);

  void update(List<dynamic> key, List<StorageUpdateOperation> operations) {
    Pointer<tarantool_message_batch_element_t> message = _allocator<tarantool_message_batch_element_t>();
    message.ref.function = _bindings.addresses.tarantool_index_update.cast();
    final request = _allocator<tarantool_index_update_request_t>();
    request.ref.space_id = _spaceId;
    request.ref.index_id = _indexId;
    request.ref.key = TarantoolTuple.write(_allocator, key);
    request.ref.operations = TarantoolTuple.write(
        _allocator,
        operations
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
    Pointer<tarantool_message_t> message = _allocator<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_BATCH;
    final Pointer<Pointer<tarantool_message_batch_element_t>> batchData = _allocator.allocate(sizeOf<Pointer<tarantool_message_batch_element_t>>() * batches.length);
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
