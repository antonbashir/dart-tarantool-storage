import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:linux_interactor/linux_interactor.dart';

import 'bindings.dart';
import 'constants.dart';
import 'executor.dart';
import 'iterator.dart';

class StorageSpace {
  final int _id;
  final int _descriptor;
  final StorageProducer _producer;
  final InteractorTuples _tuples;
  final Pointer<tarantool_factory> _factory;

  StorageSpace(
    this._id,
    this._descriptor,
    this._producer,
    this._factory,
    this._tuples,
  );

  @pragma(preferInlinePragma)
  Future<int> count({StorageIteratorType iteratorType = StorageIteratorType.eq}) {
    final keySize = tupleSizeOfList(1) + tupleSizeOfNull;
    final key = _tuples.allocate(keySize);
    final keyBuffer = key.asTypedList(keySize);
    tupleWriteList(ByteData.view(keyBuffer.buffer, keyBuffer.offsetInBytes), keySize, 0);
    return countBy(key, keySize, iteratorType: iteratorType).whenComplete(() => _tuples.free(key, keySize));
  }

  @pragma(preferInlinePragma)
  int _completeCountBy(Pointer<interactor_message> message) {
    final count = message.outputInt;
    tarantool_space_count_request_free(_factory, message);
    return count;
  }

  @pragma(preferInlinePragma)
  Future<int> countBy(Pointer<Uint8> key, int keySize, {StorageIteratorType iteratorType = StorageIteratorType.eq}) {
    final request = tarantool_space_count_request_prepare(_factory, _id, iteratorType.index, key.cast(), keySize);
    return _producer.spaceCount(_descriptor, request).then(_completeCountBy);
  }

  @pragma(preferInlinePragma)
  Future<bool> isEmpty() => length().then((value) => value == 0);

  @pragma(preferInlinePragma)
  Future<bool> isNotEmpty() => length().then((value) => value != 0);

  @pragma(preferInlinePragma)
  int _completeLength(Pointer<interactor_message> message) {
    final length = message.outputInt;
    tarantool_space_length_free(_factory, message);
    return length;
  }

  @pragma(preferInlinePragma)
  Future<int> length() => _producer.spaceLength(_descriptor, tarantool_space_length_prepare(_factory, _id)).then(_completeLength);

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
    tarantool_space_iterator_request_free(_factory, message);
    return iterator;
  }

  @pragma(preferInlinePragma)
  Future<StorageIterator> iteratorBy(Pointer<Uint8> key, int keySize, {StorageIteratorType iteratorType = StorageIteratorType.eq}) {
    final request = tarantool_space_iterator_request_prepare(_factory, _id, iteratorType.index, key.cast(), keySize);
    return _producer.spaceIterator(_descriptor, request).then(_completeIteratorBy);
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_t> _completeInsertSingle(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_t>.fromAddress(message.outputInt);
    tarantool_index_select_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_port_t> _completeInsertMany(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_port_t>.fromAddress(message.outputInt);
    tarantool_index_select_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_t>> insertSingle(Pointer<Uint8> tuple, int tupleSize) {
    final request = tarantool_space_request_prepare(_factory, _id, tuple.cast(), tupleSize);
    return _producer.spaceInsertSingle(_descriptor, request).then(_completeInsertSingle);
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_port_t>> insertMany(Pointer<Uint8> tuples, int tuplesCount) {
    final request = tarantool_space_request_prepare(_factory, _id, tuples.cast(), tuplesCount);
    return _producer.spaceInsertMany(_descriptor, request).then(_completeInsertMany);
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_t> _completePutSingle(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_t>.fromAddress(message.outputInt);
    tarantool_space_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_t>> putSingle(Pointer<Uint8> tuple, int tupleSize) {
    final request = tarantool_space_request_prepare(_factory, _id, tuple.cast(), tupleSize);
    return _producer.spaceInsertSingle(_descriptor, request).then(_completePutSingle);
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_port_t> _completePutMany(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_port_t>.fromAddress(message.outputInt);
    tarantool_space_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_port_t>> putMany(Pointer<Uint8> tuples, int tuplesCount) {
    final request = tarantool_space_request_prepare(_factory, _id, tuples.cast(), tuplesCount);
    return _producer.spaceInsertMany(_descriptor, request).then(_completePutMany);
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_t> _completeDeleteSingle(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_t>.fromAddress(message.outputInt);
    tarantool_space_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_t>> deleteSingle(Pointer<Uint8> key, int keySize) {
    final request = tarantool_space_request_prepare(_factory, _id, key.cast(), keySize);
    return _producer.spaceDeleteSingle(_descriptor, request).then(_completeDeleteSingle);
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_port_t> _completeDeleteMany(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_port_t>.fromAddress(message.outputInt);
    tarantool_space_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_port_t>> deleteSingleMany(Pointer<Uint8> keys, int keysCount) {
    final request = tarantool_space_request_prepare(_factory, _id, keys.cast(), keysCount);
    return _producer.spaceDeleteMany(_descriptor, request).then(_completeDeleteMany);
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_t> _completeGet(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_t>.fromAddress(message.outputInt);
    tarantool_space_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_t>> get(Pointer<Uint8> key, int keySize) {
    final request = tarantool_space_request_prepare(_factory, _id, key.cast(), keySize);
    return _producer.spaceGet(_descriptor, request).then(_completeGet);
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
    tarantool_space_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_t>> minBy(Pointer<Uint8> key, int keySize) {
    final request = tarantool_space_request_prepare(_factory, _id, key.cast(), keySize);
    return _producer.spaceMin(_descriptor, request).then(_completeMin);
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
    tarantool_space_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_t>> maxBy(Pointer<Uint8> key, int keySize) {
    final request = tarantool_space_request_prepare(_factory, _id, key.cast(), keySize);
    return _producer.spaceMax(_descriptor, request).then(_completeMax);
  }

  @pragma(preferInlinePragma)
  Future<void> truncate() {
    return _producer.spaceTruncate(_descriptor, tarantool_space_truncate_prepare(_factory, _id)).then((message) => tarantool_space_truncate_free(_factory, message));
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_t> _completeUpdateSingle(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_t>.fromAddress(message.outputInt);
    tarantool_space_update_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_t>> updateSingle(Pointer<Uint8> key, int keySize, Pointer<Uint8> operations, int operationsSize) {
    final request = tarantool_space_update_request_prepare(_factory, _id, key.cast(), keySize, operations.cast(), operationsSize);
    return _producer.spaceUpdateSingle(_descriptor, request).then(_completeUpdateSingle);
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_port_t> _completeUpdateMany(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_port_t>.fromAddress(message.outputInt);
    tarantool_space_update_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_port_t>> updateMany(Pointer<Uint8> keys, int keysCount, Pointer<Uint8> operations, int operationsCount) {
    final request = tarantool_space_update_request_prepare(_factory, _id, keys.cast(), keysCount, operations.cast(), operationsCount);
    return _producer.spaceUpdateMany(_descriptor, request).then(_completeUpdateMany);
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_t> _completeUpsert(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_t>.fromAddress(message.outputInt);
    tarantool_space_upsert_request_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_t>> upsert(Pointer<Uint8> tuple, int tupleSize, Pointer<Uint8> operations, int operationsSize) {
    final request = tarantool_space_upsert_request_prepare(_factory, _id, tuple.cast(), tupleSize, operations.cast(), operationsSize);
    return _producer.spaceUpdateSingle(_descriptor, request).then(_completeUpsert);
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_port_t> _completeSelect(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_port_t>.fromAddress(message.outputInt);
    tarantool_space_select_request_free(_factory, message);
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
    final request = tarantool_space_select_request_prepare(_factory, _id, key.cast(), keySize, offset, limit, iteratorType.index);
    return _producer.spaceInsertSingle(_descriptor, request).then(_completeSelect);
  }
}
