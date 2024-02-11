import 'dart:ffi';

import 'bindings.dart';
import 'constants.dart';

extension StorageTupleExtensions on Pointer<tarantool_tuple_t> {
  @pragma(preferInlinePragma)
  int get size => tarantool_tuple_size(this);

  @pragma(preferInlinePragma)
  Pointer<Uint8> get data => tarantool_tuple_data(this).cast();
}
