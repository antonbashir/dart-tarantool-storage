import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'bindings.dart';
import 'constants.dart';

class StorageSerialization {
  final Pointer<tarantool_factory> _factory;

  StorageSerialization(this._factory);

  @pragma(preferInlinePragma)
  (Pointer<Char>, int) createString(String source) {
    final units = utf8.encode(source);
    final length = source.length;
    final Pointer<Uint8> result = tarantool_create_string(_factory, length).cast();
    final unitsLength = units.length;
    final Uint8List nativeString = result.asTypedList(unitsLength + 1);
    nativeString.setAll(0, units);
    nativeString[unitsLength] = 0;
    return (result.cast(), length);
  }

  @pragma(preferInlinePragma)
  void freeString(Pointer<Char> string, int size) => tarantool_free_string(_factory, string, size);
}
