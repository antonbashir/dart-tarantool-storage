import 'dart:math';

import '../executor/executor.dart';

class StorageIterator {
  final StorageExecutor _executor;
  final int iterator;

  const StorageIterator(this._executor, this.iterator);

  Future<List<List<dynamic>>?> next({int count = 1}) => _executor.next(this, count);

  Future<void> destroy() => _executor.destroyIterator(this);

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
      while ((tuples = await _executor.next(this, count)) != null) {
        if (offset != null && index <= offset) {
          index += count;
          continue;
        }
        if (limit != null && index > limit) return;
        index += count;
        for (List<dynamic> tuple in tuples!) {
          yield (map == null ? tuple : map(tuple));
        }
      }
      await destroy();
      return;
    }
    List<List<dynamic>>? tuples;
    while ((tuples = await _executor.next(this, count)) != null) {
      if (offset != null && index <= offset) {
        index += count;
        continue;
      }
      List<dynamic> filtered = [];
      for (List<dynamic> tuple in tuples!) {
        if (filter(tuple)) filtered.add(tuple);
      }
      if (filtered.isEmpty) continue;
      if (limit != null && index > limit) return;
      index += filtered.length;
      for (List<dynamic> tuple in tuples) {
        yield (map == null ? tuple : map(tuple));
      }
    }
    await destroy();
  }
}
