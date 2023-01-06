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

class StorageIndex {
  final TarantoolBindings _bindings;
  final StorageExecutor _executor;
  final int _spaceId;
  final int _indexId;

  StorageIndex(this._bindings, this._executor, this._spaceId, this._indexId);

  Future<int> count({List<dynamic> key = const [], StorageIteratorType iteratorType = StorageIteratorType.eq}) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_index_count.cast();
        final request = arena<tarantool_index_count_request_t>();
        request.ref.space_id = _spaceId;
        request.ref.index_id = _indexId;
        request.ref.iterator_type = iteratorType.index;
        request.ref.key = TarantoolTuple.write(arena, key);
        message.ref.input = request.cast();
        return _executor.sendSingle(message).then((pointer) => pointer.address);
      });

  Future<int> length() => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_index_length.cast();
        final request = arena<tarantool_index_id_t>();
        request.ref.space_id = _spaceId;
        request.ref.index_id = _indexId;
        message.ref.input = request.cast();
        return _executor.sendSingle(message).then((pointer) => pointer.address);
      });

  Future<StorageIterator> iterator({List<dynamic> key = const [], StorageIteratorType iteratorType = StorageIteratorType.eq}) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_index_iterator.cast();
        final request = arena<tarantool_index_iterator_request_t>();
        request.ref.space_id = _spaceId;
        request.ref.index_id = _indexId;
        request.ref.type = iteratorType.index;
        request.ref.key = TarantoolTuple.write(arena, key);
        message.ref.input = request.cast();
        return _executor.sendSingle(message).then((pointer) => pointer.address).then((iterator) => StorageIterator(_executor, iterator));
      });

  Future<List<dynamic>> get(List<dynamic> key) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_index_get.cast();
        final request = arena<tarantool_index_request_t>();
        request.ref.space_id = _spaceId;
        request.ref.index_id = _indexId;
        request.ref.tuple = TarantoolTuple.write(arena, key);
        message.ref.input = request.cast();
        return _executor.sendSingle(message).then((pointer) => TarantoolTuple.read(Pointer.fromAddress(pointer.address).cast()));
      });

  Future<List<dynamic>> min({List<dynamic> key = const []}) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_index_min.cast();
        final request = arena<tarantool_index_request_t>();
        request.ref.space_id = _spaceId;
        request.ref.index_id = _indexId;
        request.ref.tuple = TarantoolTuple.write(arena, key);
        message.ref.input = request.cast();
        return _executor.sendSingle(message).then((pointer) => TarantoolTuple.read(Pointer.fromAddress(pointer.address).cast()));
      });

  Future<List<dynamic>> max({List<dynamic> key = const []}) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_index_max.cast();
        final request = arena<tarantool_index_request_t>();
        request.ref.space_id = _spaceId;
        request.ref.index_id = _indexId;
        request.ref.tuple = TarantoolTuple.write(arena, key);
        message.ref.input = request.cast();
        return _executor.sendSingle(message).then((pointer) => TarantoolTuple.read(Pointer.fromAddress(pointer.address).cast()));
      });

  Future<List<dynamic>> update(List<dynamic> key, List<StorageUpdateOperation> operations) => using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_index_update.cast();
        final request = arena<tarantool_index_update_request_t>();
        request.ref.space_id = _spaceId;
        request.ref.index_id = _indexId;
        request.ref.key = TarantoolTuple.write(arena, key);
        request.ref.operations = TarantoolTuple.write(
            arena,
            operations
                .map((operation) => [
                      operation.type.operation(),
                      operation.field,
                      operation.value,
                    ])
                .toList());
        message.ref.input = request.cast();
        return _executor.sendSingle(message).then((pointer) => TarantoolTuple.read(Pointer.fromAddress(pointer.address).cast()));
      });

  Future<List<dynamic>> select({
    List<dynamic> key = const [],
    int offset = 0,
    int limit = int32Max,
    StorageIteratorType iteratorType = StorageIteratorType.eq,
  }) =>
      using((Arena arena) {
        Pointer<tarantool_message_t> message = arena<tarantool_message_t>();
        message.ref.type = tarantool_message_type.TARANTOOL_MESSAGE_CALL;
        message.ref.function = _bindings.addresses.tarantool_index_select.cast();
        final request = arena<tarantool_index_select_request_t>();
        request.ref.space_id = _spaceId;
        request.ref.index_id = _indexId;
        request.ref.key = TarantoolTuple.write(arena, key);
        request.ref.iterator_type = iteratorType.index;
        request.ref.offset = offset;
        request.ref.limit = limit;
        message.ref.input = request.cast();
        return _executor.sendSingle(message).then((pointer) => TarantoolTuple.read(Pointer.fromAddress(pointer.address).cast()));
      });

  Future<List<dynamic>> batch(StorageBatchIndexBuilder Function(StorageBatchIndexBuilder builder) builder) => using((Arena arena) {
        Pointer<tarantool_message_t> message = builder(StorageBatchIndexBuilder(_bindings, _spaceId, _indexId, arena)).build();
        return _executor.sendBatch(message).then((message) {
          Queue<dynamic> outputs = ListQueue(message.ref.batch_size);
          for (var i = 0; i < message.ref.batch_size; i++) {
            outputs.add(TarantoolTuple.read(message.ref.batch[i].ref.output.cast()));
          }
          return outputs.toList();
        });
      });
}
