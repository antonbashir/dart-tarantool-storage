import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:linux_interactor/linux_interactor.dart';

import 'bindings.dart';
import 'configuration.dart';
import 'constants.dart';
import 'schema.dart';
import 'serialization.dart';

class StorageProducer implements InteractorProducer {
  final Pointer<tarantool_box> _box;

  StorageProducer(this._box);

  late final InteractorMethod evaluate;
  late final InteractorMethod call;
  late final InteractorMethod freeOutputBuffer;
  late final InteractorMethod iteratorNextSingle;
  late final InteractorMethod iteratorNextMany;
  late final InteractorMethod iteratorDestroy;
  late final InteractorMethod spaceIdByName;
  late final InteractorMethod spaceCount;
  late final InteractorMethod spaceLength;
  late final InteractorMethod spaceIterator;
  late final InteractorMethod spaceInsertSingle;
  late final InteractorMethod spaceInsertMany;
  late final InteractorMethod spacePutSingle;
  late final InteractorMethod spacePutMany;
  late final InteractorMethod spaceDeleteSingle;
  late final InteractorMethod spaceDeleteMany;
  late final InteractorMethod spaceUpdateSingle;
  late final InteractorMethod spaceUpdateMany;
  late final InteractorMethod spaceGet;
  late final InteractorMethod spaceMin;
  late final InteractorMethod spaceMax;
  late final InteractorMethod spaceTruncate;
  late final InteractorMethod spaceUpsert;
  late final InteractorMethod indexCount;
  late final InteractorMethod indexLength;
  late final InteractorMethod indexIterator;
  late final InteractorMethod indexGet;
  late final InteractorMethod indexMax;
  late final InteractorMethod indexMin;
  late final InteractorMethod indexUpdateSingle;
  late final InteractorMethod indexUpdateMany;
  late final InteractorMethod indexSelect;
  late final InteractorMethod indexIdByName;

  @override
  void initialize(InteractorProducerRegistrat registrat) {
    evaluate = registrat.register(_box.ref.tarantool_evaluate_address);
    call = registrat.register(_box.ref.tarantool_call_address);
    iteratorNextSingle = registrat.register(_box.ref.tarantool_iterator_next_single_address);
    iteratorNextMany = registrat.register(_box.ref.tarantool_iterator_next_many_address);
    iteratorDestroy = registrat.register(_box.ref.tarantool_iterator_destroy_address);
    freeOutputBuffer = registrat.register(_box.ref.tarantool_free_output_buffer_address);
    spaceIdByName = registrat.register(_box.ref.tarantool_space_id_by_name_address);
    spaceCount = registrat.register(_box.ref.tarantool_space_count_address);
    spaceLength = registrat.register(_box.ref.tarantool_space_length_address);
    spaceIterator = registrat.register(_box.ref.tarantool_space_iterator_address);
    spaceInsertSingle = registrat.register(_box.ref.tarantool_space_insert_single_address);
    spaceInsertMany = registrat.register(_box.ref.tarantool_space_insert_many_address);
    spacePutSingle = registrat.register(_box.ref.tarantool_space_put_single_address);
    spacePutMany = registrat.register(_box.ref.tarantool_space_put_many_address);
    spaceDeleteSingle = registrat.register(_box.ref.tarantool_space_delete_single_address);
    spaceDeleteMany = registrat.register(_box.ref.tarantool_space_delete_many_address);
    spaceUpdateSingle = registrat.register(_box.ref.tarantool_space_update_single_address);
    spaceUpdateMany = registrat.register(_box.ref.tarantool_space_update_many_address);
    spaceGet = registrat.register(_box.ref.tarantool_space_get_address);
    spaceMin = registrat.register(_box.ref.tarantool_space_min_address);
    spaceMax = registrat.register(_box.ref.tarantool_space_max_address);
    spaceTruncate = registrat.register(_box.ref.tarantool_space_truncate_address);
    spaceUpsert = registrat.register(_box.ref.tarantool_space_upsert_address);
    indexCount = registrat.register(_box.ref.tarantool_index_count_address);
    indexLength = registrat.register(_box.ref.tarantool_index_length_address);
    indexIterator = registrat.register(_box.ref.tarantool_index_iterator_address);
    indexGet = registrat.register(_box.ref.tarantool_index_get_address);
    indexMax = registrat.register(_box.ref.tarantool_index_max_address);
    indexMin = registrat.register(_box.ref.tarantool_index_min_address);
    indexUpdateSingle = registrat.register(_box.ref.tarantool_index_update_single_address);
    indexUpdateMany = registrat.register(_box.ref.tarantool_index_update_many_address);
    indexSelect = registrat.register(_box.ref.tarantool_index_select_address);
    indexIdByName = registrat.register(_box.ref.tarantool_index_id_by_name_address);
  }
}

class StorageConsumer implements InteractorConsumer {
  StorageConsumer();

  @override
  List<InteractorCallback> callbacks() => [];
}

class StorageExecutor {
  final interactor = Interactor(load: false);

  final Pointer<tarantool_box> _box;

  late final StorageSchema _schema;
  late final int _descriptor;
  late final InteractorTuples _tuples;
  late final StorageProducer _producer;
  late final Pointer<tarantool_factory> _factory;
  late final StorageSerialization _serialization;

  StorageExecutor(this._box);

  StorageSchema get schema => _schema;

  InteractorTuples get tuples => _tuples;

  Future<void> initialize() async {
    final worker = InteractorWorker(interactor.worker(InteractorDefaults.worker()));
    await worker.initialize();
    _descriptor = tarantool_executor_descriptor();
    _factory = ffi.calloc<tarantool_factory>(sizeOf<tarantool_factory>());
    tarantool_factory_initialize(_factory, worker.memory);
    worker.consumer(StorageConsumer());
    _producer = worker.producer(StorageProducer(_box));
    _tuples = worker.tuples;
    _serialization = StorageSerialization(_factory);
    _schema = StorageSchema(_descriptor, _factory, this, _tuples, _serialization, _producer);
    worker.activate();
  }

  Future<void> stop() => interactor.shutdown();

  void destroy() {
    tarantool_factory_destroy(_factory);
    ffi.calloc.free(_factory.cast());
  }

  @pragma(preferInlinePragma)
  Future<void> startBackup() => evaluate(LuaExpressions.startBackup);

  @pragma(preferInlinePragma)
  Future<void> stopBackup() => evaluate(LuaExpressions.stopBackup);

  @pragma(preferInlinePragma)
  Future<void> configure(StorageConfiguration configuration) => evaluate(configuration.format());

  @pragma(preferInlinePragma)
  Future<void> boot(StorageBootConfiguration configuration) {
    final size = configuration.tupleSize;
    final (pointer, buffer, data) = _tuples.prepare(size);
    configuration.serialize(buffer, data, 0);
    return call(LuaExpressions.boot, input: pointer, size: size);
  }

  @pragma(preferInlinePragma)
  Future<(Uint8List, void Function())> evaluate(String expression, {Pointer<Uint8>? input, int size = 0}) {
    final (expressionString, expressionLength) = _serialization.createString(expression);
    if (input != null) {
      final message = tarantool_evaluate_request_prepare(_factory, expressionString, expressionLength, input.cast(), size);
      return _producer.evaluate(_descriptor, message).then(_parseLuaEvaluate).whenComplete(() => _serialization.freeString(expressionString, expressionLength));
    }
    (input, size) = InteractorTuples.emptyList;
    final message = tarantool_evaluate_request_prepare(_factory, expressionString, expressionLength, input.cast(), size);
    return _producer.evaluate(_descriptor, message).then(_parseLuaEvaluate).whenComplete(() => _serialization.freeString(expressionString, expressionLength));
  }

  @pragma(preferInlinePragma)
  Future<(Uint8List, void Function())> call(String function, {Pointer<Uint8>? input, int size = 0}) {
    final (functionString, functionLength) = _serialization.createString(function);
    if (input != null) {
      final message = tarantool_call_request_prepare(_factory, functionString, functionLength, input.cast(), size);
      return _producer.call(_descriptor, message).then(_parseLuaCall).whenComplete(() => _serialization.freeString(functionString, functionLength));
    }
    (input, size) = InteractorTuples.emptyList;
    final message = tarantool_call_request_prepare(_factory, functionString, functionLength, input.cast(), size);
    return _producer.call(_descriptor, message).then(_parseLuaCall).whenComplete(() => _serialization.freeString(functionString, functionLength));
  }

  @pragma(preferInlinePragma)
  Future<void> file(File file) => file.readAsString().then(evaluate);

  @pragma(preferInlinePragma)
  Future<void> require(String module) => evaluate(LuaExpressions.require(module));

  @pragma(preferInlinePragma)
  void _freeLuaBuffer(Pointer<interactor_message> freeMessage) => tarantool_free_output_buffer_free(_factory, freeMessage);

  @pragma(preferInlinePragma)
  (Uint8List, void Function()) _parseLuaEvaluate(Pointer<interactor_message> message) {
    final buffer = message.outputPointer;
    final bufferSize = message.outputSize;
    final result = buffer.cast<Uint8>().asTypedList(message.outputSize);
    tarantool_evaluate_request_free(_factory, message);
    return (result, () => _producer.freeOutputBuffer(_descriptor, tarantool_free_output_buffer_prepare(_factory, buffer, bufferSize)).then(_freeLuaBuffer));
  }

  @pragma(preferInlinePragma)
  (Uint8List, void Function()) _parseLuaCall(Pointer<interactor_message> message) {
    final buffer = message.outputPointer;
    final bufferSize = message.outputSize;
    final result = message.outputPointer.cast<Uint8>().asTypedList(message.outputSize);
    tarantool_call_request_free(_factory, message);
    return (result, () => _producer.freeOutputBuffer(_descriptor, tarantool_free_output_buffer_prepare(_factory, buffer, bufferSize)).then(_freeLuaBuffer));
  }
}
