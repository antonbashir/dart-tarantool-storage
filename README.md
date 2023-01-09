# Introduction

<img src="dart-logo.png"  height="80" />  <img src="tarantool-logo.png" height="80" />

The main goal of this library is to provide fast and strong database to Dart developers.

This repository contains fork of Tarantool Database (currently 2.8.4 version, will be updated to 2.11 after release).

Currently, there are a lot of local database solutions for Dart (Isaar, Hive, ObjectBox) and a lot of connectors to commonly used databases (such as  Redis, Postgres, Mongo, .etc) as well.

But also there is a need of predictable and controllable data storage solution with ability of data processing logic customization. 

Dart Tarantool storage should satisfy these needs by combining Tarantool features and Dart language features.

## About Tarantool
* [Tarantool Documentation](https://tarantool.io/en/doc)

### Features
* schemed or schemaless per space
* fast
* in-memory or disk engines per space
* asynchronous or synchronous replication modes with raft and automatic leader election
* fluent and predictable data processing: you write your data processing code in procedural style
* transactional
* (after 2.10) MVCC and interactive (stream) transactions - currently not supported in this library
* [sharding](https://www.tarantool.io/en/doc/latest/reference/reference_rock/vshard/) - currently not supported in this library


# Idea and concepts

## Architecture

![Main diagram](dart-tarantool-storage.svg)

## Processing

Tarantool is used as shared library (.so) and running in separate single thread.

Circular buffer between Tarantool and Dart code is used to transport messages from Dart to Tarantool.

After execution of message Tarantool thread will notify DartVM with Dart_Post. 

Message structure: `{type,function,input,output,batch[{function,input,output,error}],error}`.

* `type` - type of message
* `function` - pointer to binding function which should be called in Tarantool thread and has access to Tarantool API
* `input` - binding function argument
* `output` - holder for function result
* `error` - holder for Tarantool error which could happen during function calling
* `batch` - array of structures similar to message (for bulk execution of functions)

### Message types
* call - calling function on Tarantool thread with access to Tarantool API
* batch - mark that it is batch message and binding should handle batch processing
* begin - Tarantool transaction begin
* commit - Tarantool transaction commit
* rollback - Tarantool transaction rollback
* stop - used only inside native binding code, stops the binding message loop

### Message input variations
* management request - operations for manage Tarantool, for example initialize, shutdown, .etc 
* space request - data operations for space, usually contains space id
* index request - data operations for index, usually contains space id and index id
* iterator next request - get next element of iterator
* execution request - execute Lua or Native function on Tarantool thread with access to Tarantool API

# Installation & Usage

### Quick start

1. Create Dart project with pubspec.yaml
2. Add this section to dependencies:
```
  tarantool_storage:
    git: 
      url: https://github.com/antonbashir/dart-tarantool-storage/
      path: binding/dart
```
3. Run `dart pub get`
4. Run `dart run tarantool_storage:setup`
5. Look at the [API](#API) and Enjoy!

## Sample

You can find simple example [here](https://github.com/antonbashir/dart-tarantool-sample)

## Management

To initialize and boot library use `Storage.boot()`.

You can provide bootstrap lua script, change configuration and also provide initial user which will be used for replication.

## Lua custom modules

There are Lua files in `lua` directory.

They are loading from root file `storage.lua`.

You can write custom code in the end of that file or in `module.lua` file. 

All of Tarantool Lua APIs are available for usage.

For execution of custom Lua functions you can use `StorageExecutor.lua`.

## Native custom modules
There are native header files in `native` directory.

You can compile them using `dart run tarantool_storage:compile`.

You can write custom definitions in `module.h` file and create `module.c` for implementations.

All of Tarantool Native APIs are available for usage in your functions.

For execution of custom Native functions you can use `StorageExecutor.native`.

## Reloading
If `activateReloader` in `Storage.boot` function is specified, Tarantool will reload Native and Lua modules on receiving SIGHUP signal.

So you can change Lua scripts or Native files (and recompile them) and your changes will be applied after SIGHUP. 

## Packaging

If you want to distribute your module, run `dart run tarantool_storage:pack ${path to main dart file}`.

This command will recompile Native files and create `${directory name}.tar.gz` archive with executables, libraries and lua scripts. 

After this you can transfer archive to whatever place you want, unarchive it and run `module.exe`.

# API

## Storage
* `Future<void> boot(StorageBootstrapScript script, StorageMessageLoopConfiguration loop, {StorageBootConfiguration? boot, activateReloader = false}) async`
* `bool mutable()`
* `bool initialized()`
* `Future<void> awaitInitialized()`
* `Future<void> awaitImmutable()`
* `Future<void> awaitMutable()`
* `void shutdown()`
* `void close()`
* `StorageNativeModule loadModuleByPath(String libraryPath)`
* `StorageNativeModule loadModuleByName(String libraryName)`
* `Future<void> reload() async`
* `executor`

## Executor - StorageExecutor
* `Future<List<List<dynamic>>?> next(StorageIterator iterator, int count)`
* `Future<void> destroyIterator(StorageIterator iterator)`
* `Future<void> begin()`
* `Future<void> commit()`
* `Future<void> rollback()`
* `Future<void> transactional(FutureOr<void> Function(StorageExecutor executor) function)`
* `Future<bool> hasTransaction()`

## Schema - StorageSchema
* `StorageSpace spaceById(int id)`
* `Future<StorageSpace> spaceByName(String name)`
* `Future<int> spaceId(String space)`
* `Future<bool> spaceExists(String space)`
* `Future<StorageIndex> indexByName(String spaceName, String indexName)`
* `Future<bool> indexExists(int spaceId, String indexName)`
* `StorageIndex indexById(int spaceId, int indexId)`
* `Future<int> indexId(int spaceId, String index)`
* `Future<void> createSpace(
    String name, {
    StorageEngine? engine,
    int? fieldCount,
    List<StorageSpaceField>? format,
    int? id,
    bool? ifNotExists,
    bool? local,
    bool? synchronous,
    bool? temporary,
    String? user,
  })`
* `Future<void> alterSpace(
    String name, {
    int? fieldCount,
    List<StorageSpaceField>? format,
    bool? synchronous,
    bool? temporary,
    String? user,
  })`
* `Future<void> renameSpace(String from, String to)`
* `Future<void> dropSpace(String name)`
* `Future<void> createIndex(
    String spaceName,
    String indexName, {
    IndexType? type,
    int? id,
    bool? unique,
    bool? ifNotExists,
    List<StorageIndexPart>? parts,
  })`
* `Future<void> alterIndex(String spaceName, String indexName, {List<StorageIndexPart>? parts})`
* `Future<void> dropIndex(String spaceName, String indexName)`
* `Future<void> createUser(String name, String password, {bool? ifNotExists})`
* `Future<void> dropUser(String name)`
* `Future<void> changePassword(String name, String password)`
* `Future<bool> userExists(String name)`
* `Future<void> grantUser(
    String name, {
    required String privileges,
    String? objectType,
    String? objectName,
    String? roleName,
    bool? ifNotExists,
  })`
* `Future<void> revokeUser(
    String name, {
    required String privileges,
    String? objectType,
    String? objectName,
    String? roleName,
    bool? universe,
    bool? ifNotExists,
  })`

## Space - StorageSpace
* `Future<int> count({List<dynamic> key = const [], StorageIteratorType iteratorType = StorageIteratorType.eq})`
* `Future<bool> isEmpty()`
* `Future<bool> isNotEmpty()`
* `Future<int> length()`
* `Future<StorageIterator> iterator({List<dynamic> key = const [], StorageIteratorType iteratorType = StorageIteratorType.eq})`
* `Future<List<dynamic>> insert(List<dynamic> data)`
* `Future<List<dynamic>> put(List<dynamic> data)`
* `Future<List<dynamic>> get(List<dynamic> key)`
* `Future<List<dynamic>> delete(List<dynamic> key)`
* `Future<List<dynamic>> min({List<dynamic> key = const []})`
* `Future<List<dynamic>> max({List<dynamic> key = const []})`
* `Future<void> truncate()`
* `Future<List<dynamic>> update(List<dynamic> key, List<StorageUpdateOperation> operations)`
* `Future<List<dynamic>> upsert(List<dynamic> tuple, List<StorageUpdateOperation> operations)`
* `Future<List<dynamic>> select({
    List<dynamic> key = const [],
    int offset = 0,
    int limit = int32Max,
    StorageIteratorType iteratorType = StorageIteratorType.eq,
  })`
* `Future<List<dynamic>> batch(StorageBatchSpaceBuilder Function(StorageBatchSpaceBuilder builder) builder)`

## Index - StorageIndex
* `Future<int> count({List<dynamic> key = const [], StorageIteratorType iteratorType = StorageIteratorType.eq})`
* `Future<int> length()`
* `Future<StorageIterator> iterator({List<dynamic> key = const [], StorageIteratorType iteratorType = StorageIteratorType.eq})`
* `Future<List<dynamic>> get(List<dynamic> key)`
* `Future<List<dynamic>> min({List<dynamic> key = const []})`
* `Future<List<dynamic>> max({List<dynamic> key = const []})`
* `Future<List<dynamic>> update(List<dynamic> key, List<StorageUpdateOperation> operations)`
* `Future<List<dynamic>> select({
    List<dynamic> key = const [],
    int offset = 0,
    int limit = int32Max,
    StorageIteratorType iteratorType = StorageIteratorType.eq,
  })`
* `Future<List<dynamic>> batch(StorageBatchIndexBuilder Function(StorageBatchIndexBuilder builder) builder)`

## Iterator
* `Future<List<List<dynamic>>?> next({int count = 1})`
* `Future<void> destroy()`
* `Future<void> destroy()`
* `Future<List<dynamic>> collect({
    bool Function(List<dynamic> value)? filter,
    dynamic Function(List<dynamic> value)? map,
    int? limit,
    int? offset,
    int count = 1,
  })`
* `Future<void> forEach(
    void Function(dynamic element) action, {
    bool Function(List<dynamic> value)? filter,
    dynamic Function(List<dynamic> value)? map,
    int? limit,
    int? offset,
    int count = 1,
  })`
* `Stream<dynamic> stream({
    bool Function(List<dynamic> value)? filter,
    dynamic Function(List<dynamic> value)? map,
    int? limit,
    int? offset,
    int count = 1,
  }) async*`


## Batch

### StorageBatchSpaceBuilder
* `void insert(List<dynamic> data)`
* `void put(List<dynamic> data)`
* `void put(List<dynamic> data)`
* `void delete(List<dynamic> data)`
* `void update(List<dynamic> key, List<StorageUpdateOperation> operations)`
* `void upsert(List<dynamic> tuple, List<StorageUpdateOperation> operations)`
* `void insertMany(List<List<dynamic>> data)`
* `void putMany(List<List<dynamic>> data)`
* `void putMany(List<List<dynamic>> data)`
* `void deleteMany(List<List<dynamic>> data)`

### StorageBatchIndexBuilder
* `void update(List<dynamic> key, List<StorageUpdateOperation> operations)`

## Lua - StorageLuaExecutor
* `Future<void> startBackup()`
* `Future<void> stopBackup()`
* `Future<void> promote()`
* `Future<void> configure(StorageConfiguration configuration)`
* `Future<List<dynamic>> script(String expression, {List<dynamic> arguments = const []})`
* `Future<void> file(File file)`
* `Future<void> require(String module)`
* `Future<List<dynamic>> call(String function, {List<dynamic> arguments = const []})`

## Native - StorageNativeExecutor
`Future<Pointer<Void>> call(tarantool_function function, {tarantool_function_argument? argument})`

# Configuration

## StorageConfiguration
## StorageMessageLoopConfiguration
## StorageBootConfiguration
## StorageReplicationConfiguration

# Perfomance

TODO: Make benchmark on preferable machine

Latest benchmark results (count of entities - 1M, single dart Isolate):

* Get RPS: 200k
* Lua function RPS: 200k
* Select time: 250 milliseconds
* Iterator time (with 1k prefetch count): 1 second
* Batch insert: 2.7 seconds

# Limitations

* Linux only
* Currently, Tarantool VShard is not supported, but you still can use it by writing lua code to `module.lua`
* Currently, Tarantool MVCC is not tested, but you can enable it by configuration
* Currently, tested only on x86 architecture, arm and others are not tested but could work
* Not production tested, current version is coded and tested by function unit tests, bugs are possible
* Process restart required to restart Tarantool, because it can't be fully shutdown programmatically and some stuff stays in memory
* Full size of library static build is 70mb which could be critical for embedded or mobile devices

# Further work

1. Benchmarks and optimization
2. CI for building library and way to provide it to user modules (currently library included with sources, that is not good)
3. Dart network transport based on io_uring
4. Flutter UI for management and administration
5. Upgrade to Tarantool 2.11
6. Demo project

# Contribution

Currently maintainer hasn't resources on maintain pull requests but issues are welcome. 

Every issue will be observed, discussed and applied or closed if this project does not need it.