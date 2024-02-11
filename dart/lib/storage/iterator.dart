import 'dart:ffi';
import 'dart:math';

import 'package:linux_interactor/linux_interactor.dart';

import 'bindings.dart';
import 'constants.dart';
import 'executor.dart';

class StorageIterator {
  final Pointer<tarantool_factory> _factory;
  final int _iterator;
  final StorageProducer _producer;
  final int _descriptor;

  const StorageIterator(this._factory, this._iterator, this._producer, this._descriptor);

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_t> _completeNextSingle(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_t>.fromAddress(message.outputInt);
    tarantool_iterator_next_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_t>> nextSingle() {
    final request = tarantool_iterator_next_prepare(_factory, _iterator, 1);
    return _producer.iteratorNextSingle(_descriptor, request).then(_completeNextSingle);
  }

  @pragma(preferInlinePragma)
  Pointer<tarantool_tuple_port_t> _completeNextMany(Pointer<interactor_message> message) {
    final tuple = Pointer<tarantool_tuple_port_t>.fromAddress(message.outputInt);
    tarantool_iterator_next_free(_factory, message);
    return tuple;
  }

  @pragma(preferInlinePragma)
  Future<Pointer<tarantool_tuple_port_t>> nextMany({int count = 1}) {
    final request = tarantool_iterator_next_prepare(_factory, _iterator, count);
    return _producer.iteratorNextMany(_descriptor, request).then(_completeNextMany);
  }

  @pragma(preferInlinePragma)
  void _completeDestroy(Pointer<interactor_message> message) => tarantool_iterator_destroy_free(_factory, message);

  @pragma(preferInlinePragma)
  Future<void> destroy() {
    final request = tarantool_iterator_destroy_prepare(_factory, _iterator);
    return _producer.iteratorDestroy(_descriptor, request).then(_completeDestroy);
  }

  Future<List<dynamic>> collect({
    bool Function(List<dynamic> value)? filter,
    dynamic Function(List<dynamic> value)? map,
    int? limit,
    int? offset,
    int count = 1,
  }) =>
      stream(
        filter: filter,
        map: map,
        limit: limit,
        offset: offset,
        count: count,
      ).toList();

  Future<void> forEach(
    void Function(dynamic element) action, {
    bool Function(List<dynamic> value)? filter,
    dynamic Function(List<dynamic> value)? map,
    int? limit,
    int? offset,
    int count = 1,
  }) =>
      stream(
        filter: filter,
        map: map,
        limit: limit,
        offset: offset,
        count: count,
      ).forEach(action);

  Stream<dynamic> stream({
    bool Function(List<dynamic> value)? filter,
    dynamic Function(List<dynamic> value)? map,
    int? limit,
    int? offset,
    int count = 1,
  }) async* {
    var index = 0;
    if (limit != null) count = min(count, limit);
    if (filter == null) {
      List<List<dynamic>>? tuples;
      //while ((tuples = await nextMany(count: count)) != null) {
      //  if (offset != null && index <= offset) {
      //    index += count;
      //    continue;
      //  }
      //  if (limit != null && index > limit) return;
      //  index += count;
      //  for (List<dynamic> tuple in tuples!) {
      //    yield (map == null ? tuple : map(tuple));
      //  }
      //}
      await destroy();
      return;
    }
    List<List<dynamic>>? tuples;
    // while ((tuples = await nextMany(count: count)) != null) {
    //   if (offset != null && index <= offset) {
    //     index += count;
    //     continue;
    //   }
    //   List<dynamic> filtered = [];
    //   for (List<dynamic> tuple in tuples!) {
    //     if (filter(tuple)) filtered.add(tuple);
    //   }
    //   if (filtered.isEmpty) continue;
    //   if (limit != null && index > limit) return;
    //   index += filtered.length;
    //   for (List<dynamic> tuple in tuples) {
    //     yield (map == null ? tuple : map(tuple));
    //   }
    // }
    await destroy();
  }
}
