
import '../executor/executor.dart';

class StorageIterator {
  final StorageExecutor _executor;
  final int iterator;

  const StorageIterator(this._executor, this.iterator);

  Future<List<dynamic>?> next() => _executor.next(this);

  Future<void> destroy() => _executor.destroyIterator(this);

  Future<List<dynamic>> collect({
    bool Function(List<dynamic> value)? filter,
    dynamic Function(List<dynamic> value)? map,
    int? limit,
    int? offset,
  }) =>
      stream(filter: filter, map: map, limit: limit, offset: offset).toList();

  Future<void> forEach(
    void Function(dynamic element) action, {
    bool Function(List<dynamic> value)? filter,
    dynamic Function(List<dynamic> value)? map,
    int? limit,
    int? offset,
  }) =>
      stream(filter: filter, map: map, limit: limit, offset: offset).forEach(action);

  Stream<dynamic> stream({
    bool Function(List<dynamic> value)? filter,
    dynamic Function(List<dynamic> value)? map,
    int? limit,
    int? offset,
  }) async* {
    var index = 0;
    if (filter == null) {
      List<dynamic>? value;
      while ((value = await _executor.next(this)) != null) {
        if (offset != null && index <= offset) {
          index++;
          continue;
        }
        if (limit != null && index > limit) return;
        index++;
        yield (map == null ? value : map(value!));
      }
      await destroy();
      return;
    }
    List<dynamic>? value;
    while ((value = await _executor.next(this)) != null) {
      if (offset != null && index <= offset) {
        index++;
        continue;
      }
      if (!filter(value!)) continue;
      if (limit != null && index > limit) return;
      index++;
      yield (map == null ? value : map(value));
    }
    await destroy();
  }
}
