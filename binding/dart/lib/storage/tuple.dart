import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'bindings.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as messagePack;

class TarantoolTuple {
  const TarantoolTuple._();

  static Pointer<tarantool_tuple_t> write(Allocator allocator, dynamic data) {
    if (data == null) return nullptr.cast();
    final tuple = allocator<tarantool_tuple_t>();
    final tupleBytes = messagePack.serialize(data);
    final tupleData = allocator.allocate<Uint8>(sizeOf<Uint8>() * tupleBytes.length);
    tupleData.asTypedList(tupleBytes.length).setAll(0, tupleBytes);
    tuple.ref.data = tupleData.cast();
    tuple.ref.size = tupleBytes.length;
    return tuple;
  }

  static dynamic read(Pointer<tarantool_tuple_t> tuple) {
    if (tuple == nullptr) return [];
    Pointer<Uint8> resultBytes = tuple.ref.data.cast();
    final output = messagePack.deserialize(resultBytes.asTypedList(tuple.ref.size));
    malloc.free(tuple.ref.data);
    malloc.free(tuple);
    return output;
  }
}
