import 'dart:async';
import 'dart:collection';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings.dart';
import '../constants.dart';
import '../executor/executor.dart';
import '../extensions.dart';
import '../tuple.dart';
import 'batch.dart';
import 'iterator.dart';
import 'updater.dart';

class StorageIndex {
  final TarantoolBindings _bindings;
  final StorageExecutor _executor;
  final int _spaceId;
  final int _indexId;
  final TarantoolTupleDescriptor _descriptor;

  StorageIndex(this._bindings, this._executor, this._spaceId, this._indexId, this._descriptor);

  Future<int> count({List<dynamic> key = const [], StorageIteratorType iteratorType = StorageIteratorType.eq}) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_index_count.cast();
    final request = calloc<tarantool_index_count_request_t>();
    request.ref.space_id = _spaceId;
    request.ref.index_id = _indexId;
    request.ref.iterator_type = iteratorType.index;
    request.ref.key = _descriptor.write(key);
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => pointer.address);
  }

  Future<int> length() {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_index_length.cast();
    final request = calloc<tarantool_index_id_t>();
    request.ref.space_id = _spaceId;
    request.ref.index_id = _indexId;
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => pointer.address);
  }

  Future<StorageIterator> iterator({List<dynamic> key = const [], StorageIteratorType iteratorType = StorageIteratorType.eq}) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_index_iterator.cast();
    final request = calloc<tarantool_index_iterator_request_t>();
    request.ref.space_id = _spaceId;
    request.ref.index_id = _indexId;
    request.ref.type = iteratorType.index;
    request.ref.key = _descriptor.write(key);
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => pointer.address).then((iterator) => StorageIterator(_executor, iterator));
  }

  Future<List<dynamic>> get(List<dynamic> key) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_index_get.cast();
    final request = calloc<tarantool_index_request_t>();
    request.ref.space_id = _spaceId;
    request.ref.index_id = _indexId;
    request.ref.tuple = _descriptor.write(key);
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => _descriptor.read(Pointer.fromAddress(pointer.address).cast()));
  }

  Future<List<dynamic>> min({List<dynamic> key = const []}) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_index_min.cast();
    final request = calloc<tarantool_index_request_t>();
    request.ref.space_id = _spaceId;
    request.ref.index_id = _indexId;
    request.ref.tuple = _descriptor.write(key);
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => _descriptor.read(Pointer.fromAddress(pointer.address).cast()));
  }

  Future<List<dynamic>> max({List<dynamic> key = const []}) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
    message.ref.function = _bindings.addresses.tarantool_index_max.cast();
    final request = calloc<tarantool_index_request_t>();
    request.ref.space_id = _spaceId;
    request.ref.index_id = _indexId;
    request.ref.tuple = _descriptor.write(key);
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => _descriptor.read(Pointer.fromAddress(pointer.address).cast()));
  }

  Future<List<dynamic>> update(List<dynamic> key, List<StorageUpdateOperation> operations) {
    Pointer<tarantool_message_t> message = calloc<tarantool_message_t>();
    message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
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
    message.ref.function = _bindings.addresses.tarantool_index_select.cast();
    final request = calloc<tarantool_index_select_request_t>();
    request.ref.space_id = _spaceId;
    request.ref.index_id = _indexId;
    request.ref.key = _descriptor.write(key);
    request.ref.iterator_type = iteratorType.index;
    request.ref.offset = offset;
    request.ref.limit = limit;
    message.ref.input = request.cast();
    return _executor.sendSingle(message).then((pointer) => _descriptor.read(Pointer.fromAddress(pointer.address).cast()));
  }

  Future<List<dynamic>> batch(StorageBatchIndexBuilder Function(StorageBatchIndexBuilder builder) builder) {
    Pointer<tarantool_message_t> message = builder(StorageBatchIndexBuilder(_bindings, _spaceId, _indexId, _descriptor)).build();
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
