import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:linux_interactor/linux_interactor.dart';

import 'bindings.dart';
import 'constants.dart';
import 'executor.dart';
import 'iterator.dart';

class StorageIndex {
  final int _spaceId;
  final int _indexId;
  final int _descriptor;
  final InteractorTuples _tuples;
  final Pointer<tarantool_factory> _factory;
  final StorageProducer _producer;

  StorageIndex(this._spaceId, this._indexId, this._descriptor, this._tuples, this._factory, this._producer);

  Future<int> count({List<dynamic> key = const [], StorageIteratorType iteratorType = StorageIteratorType.eq}) {
    final keySize = tupleSizeOfList(1) + tupleSizeOfNull;
    final key = _tuples.allocate(keySize);
    final keyBuffer = key.asTypedList(keySize);
    tupleWriteList(ByteData.view(keyBuffer.buffer, keyBuffer.offsetInBytes), keySize, 0);
    return countBy(key, keySize, iteratorType: iteratorType).whenComplete(() => _tuples.free(key, keySize));
  }

  @pragma(preferInlinePragma)
  int _completeCountBy(Pointer<interactor_message> message) {
    final count = message.outputInt;
    tarantool_index_count_request_free(_factory, message);
    return count;
  }

  @pragma(preferInlinePragma)
  Future<int> countBy(Pointer<Uint8> key, int keySize, {StorageIteratorType iteratorType = StorageIteratorType.eq}) {
    final request = tarantool_index_count_request_prepare(_factory, _spaceId, _indexId, key.cast(), keySize, iteratorType.index);
    return _producer.indexCount(_descriptor, request).then(_completeCountBy);
  }

  @pragma(preferInlinePragma)
  int _completeLength(Pointer<interactor_message> message) {
    final length = message.outputInt;
    tarantool_index_id_free(_factory, message);
    return length;
  }

  @pragma(preferInlinePragma)
  Future<int> length() => _producer.indexLength(_descriptor, tarantool_index_id_prepare(_factory, _spaceId, _indexId)).then(_completeLength);

  @pragma(preferInlinePragma)
  Future<StorageIterator> iterator({StorageIteratorType iteratorType = StorageIteratorType.eq}) {
    final keySize = tupleSizeOfList(1) + tupleSizeOfNull;
    final key = _tuples.allocate(keySize);
    final keyBuffer = key.asTypedList(keySize);
    tupleWriteList(ByteData.view(keyBuffer.buffer, keyBuffer.offsetInBytes), keySize, 0);
    return iteratorBy(key, keySize, iteratorType: iteratorType).whenComplete(() => _tuples.free(key, keySize));
  }

  @pragma(preferInlinePragma)
  StorageIterator _completeIteratorBy(Pointer<interactor_message> message) {
    final iterator = StorageIterator(_factory, message.outputInt, _producer, _descriptor);
    tarantool_index_iterator_request_free(_factory, message);
    return iterator;
  }

  @pragma(preferInlinePragma)
  Future<StorageIterator> iteratorBy(Pointer<Uint8> key, int keySize, {StorageIteratorType iteratorType = StorageIteratorType.eq}) {
    final request = tarantool_index_iterator_request_prepare(_factory, _spaceId, _indexId, iteratorType.index, key.cast(), keySize);
    return _producer.indexIterator(_descriptor, request).then(_completeIteratorBy);
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_t> _completeGet(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_t>.fromAddress(message.outputInt);
    tarantool_index_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_t>> get(Pointer<Uint8> key, int keySize) {
    final request = tarantool_index_request_prepare(_factory, _spaceId, _indexId, key.cast(), keySize);
    return _producer.indexGet(_descriptor, request).then(_completeGet);
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_t>> min() {
    final keySize = tupleSizeOfList(1) + tupleSizeOfNull;
    final key = _tuples.allocate(keySize);
    final keyBuffer = key.asTypedList(keySize);
    tupleWriteList(ByteData.view(keyBuffer.buffer, keyBuffer.offsetInBytes), keySize, 0);
    return minBy(key, keySize).whenComplete(() => _tuples.free(key, keySize));
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_t> _completeMin(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_t>.fromAddress(message.outputInt);
    tarantool_index_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_t>> minBy(Pointer<Uint8> key, int keySize) {
    final request = tarantool_index_request_prepare(_factory, _spaceId, _indexId, key.cast(), keySize);
    return _producer.indexMin(_descriptor, request).then(_completeMin);
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_t>> max() {
    final keySize = tupleSizeOfList(1) + tupleSizeOfNull;
    final key = _tuples.allocate(keySize);
    final keyBuffer = key.asTypedList(keySize);
    tupleWriteList(ByteData.view(keyBuffer.buffer, keyBuffer.offsetInBytes), keySize, 0);
    return maxBy(key, keySize).whenComplete(() => _tuples.free(key, keySize));
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_t> _completeMax(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_t>.fromAddress(message.outputInt);
    tarantool_index_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_t>> maxBy(Pointer<Uint8> key, int keySize) {
    final request = tarantool_index_request_prepare(_factory, _spaceId, _indexId, key.cast(), keySize);
    return _producer.indexMax(_descriptor, request).then(_completeMax);
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_t> _completeUpdateSingle(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_t>.fromAddress(message.outputInt);
    tarantool_index_update_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_t>> updateSingle(Pointer<Uint8> key, int keySize, Pointer<Uint8> operations, int operationsSize) {
    final request = tarantool_index_update_request_prepare(_factory, _spaceId, _indexId, key.cast(), keySize, operations.cast(), operationsSize);
    return _producer.indexUpdateSingle(_descriptor, request).then(_completeUpdateSingle);
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_port_t> _completeUpdateMany(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_port_t>.fromAddress(message.outputInt);
    tarantool_index_update_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_port_t>> updateMany(Pointer<Uint8> keys, int keysCount, Pointer<Uint8> operations, int operationsCount) {
    final request = tarantool_index_update_request_prepare(_factory, _spaceId, _indexId, keys.cast(), keysCount, operations.cast(), operationsCount);
    return _producer.indexUpdateMany(_descriptor, request).then(_completeUpdateMany);
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_port_t> _completeSelect(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_port_t>.fromAddress(message.outputInt);
    tarantool_index_select_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_port_t>> select({
    int offset = 0,
    int limit = int32Max,
    StorageIteratorType iteratorType = StorageIteratorType.eq,
  }) {
    final keySize = tupleSizeOfList(1) + tupleSizeOfNull;
    final key = _tuples.allocate(keySize);
    final keyBuffer = key.asTypedList(keySize);
    tupleWriteList(ByteData.view(keyBuffer.buffer, keyBuffer.offsetInBytes), keySize, 0);
    return selectBy(key, keySize).whenComplete(() => _tuples.free(key, keySize));
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_port_t>> selectBy(
    Pointer<Uint8> key,
    int keySize, {
    int offset = 0,
    int limit = int32Max,
    StorageIteratorType iteratorType = StorageIteratorType.eq,
  }) {
    final request = tarantool_index_select_request_prepare(_factory, _spaceId, _indexId, key.cast(), keySize, offset, limit, iteratorType.index);
    return _producer.indexSelect(_descriptor, request).then(_completeSelect);
  }
}
