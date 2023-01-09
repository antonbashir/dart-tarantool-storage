# Introduction

<img src="dart-logo.png"  height="80" />  <img src="tarantool-logo.png" height="80" />

The main goal of this library is to provide fast and strong database to Dart developers.

This repository contains fork of Tarantool Database (currently 2.8.4 version, will be updated to 2.11 after release).

Currently, there are a lot of local database solutions for Dart (Isaar, Hive, ObjectBox) and a lot of connectors to commonly used databases (such as  Redis, Postgres, Mongo, etc.) as well.

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

Ring buffer between Tarantool and Dart code is used to transport messages from Dart to Tarantool.

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
* management request - operations for manage Tarantool, for example initialize, shutdown, etc. 
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

### [async] `boot()` - Initializing and bootstraping Tarantool and binding library components
* `StorageBootstrapScript script` - Initial Lua script representation
* `StorageMessageLoopConfiguration loop` - [See](#StorageMessageLoopConfiguration) 
* [optional] `StorageBootConfiguration boot` - [See](#StorageBootConfiguration)
* [optional] `bool activateReloader` - Activates Tarantool reloading 

### `mutable()`  - Checking that Tarantool is not read only
* [return] `bool` - True if Tarantool is available for writing

### `initialized()` - Checking that Tarantool is read only
* [return] `bool` - True if Tarantool is available for reading

### [async] `awaitInitialized()` - Waiting for Tarantool initialization

### [async] `awaitImmutable()` - Waiting for Tarantool is available for reading

### [async] `awaitMutable()` - Waiting for Tarantool is available for writing

### `shutdown()` - Shutdowning Tarantool and binding

### `close()` - Closing Dart ports 

### `loadModuleByPath()` - Loading Native module by full path
* `String libraryPath` - Module path
* [return] `StorageNativeModule` - Loaded module instance

### `loadModuleByName()` - Loading Native module by name
* `String libraryName` - Module name
* [return] `StorageNativeModule` - Loaded module instance

### `reload()` - Reloading Lua and Native modules

### `executor` - Provider for StorageExecutor

## Executor - StorageExecutor

### [async] `next()` - Getting next element of the iterator
* `StorageIterator iterator` - Input iterator
* `int count` - Prefetch count. Binding can prefetch more tuples than 1 and combine it after return
* [return] `List<List<dynamic>>?` - Tuples

### [async] `destroyIterator()` - Destroying Tarnatool iterator
* `StorageIterator iterator` - Input iterator

### [async] `begin()` - Tarnatool transaction begin

### [async] `commit()` - Tarnatool transaction commit

### [async] `rollback()` - Tarnatool transaction rollback

### [async] `transactional()` - Executing function inside Tarantool transaction
* `Function(StorageExecutor executor) function` - Function which should be executed in transaction

### [async] `hasTransaction()` - Checking transaction status
* [return] `bool` - True if inside transaction

## Schema - StorageSchema

### [async] `spaceById()` - Creating StorageSpace instance for space with id
* `int id` - Input space id 
* [return] `StorageSpace` - Created instance

### [async] `spaceByName()` - Creating StorageSpace instance for space with name
* `String name` - Input space name
* [return] `StorageSpace` - Created instance

### [async] `spaceId()` - Getting space id by its name
* `String space` - Input space name
* [return] `int` - Received space id 

### [async] `spaceExists()` - Checking that space exists inside Tarantool
* `String space` - Input space name
* [return] `bool` - True if space exists

### [async] `indexByName()` - Creating StorageIndex instance for space and index names
* `String spaceName` - Input space name
* `String indexName` - Input index name
* [return] `StorageIndex` - Created instance

### [async] `indexExists()` - Checking that index exists by space id and index name
* `int spaceId` - Input space id
* `String indexName` - Input index name
* [return] `bool` - True if exists

### [async] `indexById()` - Creating StorageIndex instance for space and index ids
* `int spaceId` - Input space id
* `int indexId` - Input index id
* [return] `StorageIndex` - Created instance

### [async] `indexId()` - Getting index id by its name and space id
* `int spaceId` - Input space id
* `String index` - Input index name
* [return] `int` - Received index id

### [async] `createSpace()` - DDL operation for creating Tarantool space
* `String name` - Space name
* [optional] `StorageEngine engine` - Space engine (memtx or vinyl)
* [optional] `int fieldCount` - Space tuple fields count
* [optional] `List<StorageSpaceField> format` - Space tuple format
* [optional] `int id` - Space id
* [optional] `bool ifNotExists` - If true then Tarantool will ignore space existence
* [optional] `bool local` - If true then space will not participate in replication
* [optional] `bool synchronous` - If true then space operations will require synchronous commit
* [optional] `bool temporary` - If true then space will be empty on every server restart
* [optional] `String user` - Space owner

### [async] `alterSpace()` - DDL operation for altering Tarantool space
* `String name` - Space name
* [optional] `int  fieldCount` - Space tuple fields count
* [optional] `List<StorageSpaceField> format` - Space tuple format
* [optional] `bool  synchronous` - If true then space operations will require synchronous commit
* [optional] `bool temporary` - If true then space will be empty on every server restart
* [optional] `String  user` - Space owner

### [async] `renameSpace()` - DDL operation for renaming Tarantool space
* `String from` - Current space name
* `String to` - Space name after rename
 
### [async] `dropSpace()` - DDL operation for dropping Tarantool space
* `String name` - Space name

### [async] `createIndex()` - DDL operation for creating Tarantool index
* `String spaceName` - Space name (owner of created index)
* `String indexName` - Index name
* [optional] `StorageIndexType type` - Index type (could be hash, set, tree, bitset, rtree)
* [optional] `int id` - Index id
* [optional] `bool unique` - If true then index should not contains duplicates
* [optional] `bool ifNotExists` - If true then Tarantool will ignore index existence
* [optional] `List<StorageIndexPart> parts` - Index parts. Every part includes field number and field type

### [async] `alterIndex()`
* `String spaceName`
* `String indexName` 
* [optional] `List<StorageIndexPart> parts`

### [async] `dropIndex()`
* `String spaceName`
* `String indexName`

### [async] `createUser()`
* `String name`
* `String password`
* [optional] `bool ifNotExists`

### [async] `dropUser()`
* `String name`

### [async] `changePassword()`
* `String name`
* `String password`


* [async] `userExists()`
* `String name`
* [return] `bool`

### [async] `grantUser()`
* `String name`
* `String privileges`
* [optional] `String objectType`
* [optional]  `String objectName`
* [optional] `String roleName`
* [optional] `bool ifNotExists`

### [async] `revokeUser()`
* `String name`
* `String privileges`
* [optional] `String objectType`
* [optional] `String objectName`
* [optional] `String roleName`
* [optional] `bool universe`
* [optional] `bool ifNotExists`

## Space - StorageSpace
### [async] `count()`
* [optional] `List<dynamic> key`
* [optional] `StorageIteratorType iteratorType`
* [return] `int`

### [async] `isEmpty()`
* [return] `bool`

### [async] `isNotEmpty()`
* [return] `bool`

### [async] `length()`
* [return] `int`

### [async] `iterator()`
* [optional] `List<dynamic> key`
* [optional] `StorageIteratorType iteratorType`
* [return] `StorageIterator`

### [async] `insert()`
* `List<dynamic> data`
* [return] `List<dynamic>`

### [async] `put()`
* `List<dynamic> data`
* [return] `List<dynamic>`

### [async] `get()`
* `List<dynamic> key`
* [return] `List<dynamic>`

### [async] `delete()`
* `List<dynamic> key`
* [return] `List<dynamic>`

### [async] `min()`
* [optional] `List<dynamic> key`
* [return] `List<dynamic>`

### [async] `max()`
* [optional] `List<dynamic> key`
* [return] `List<dynamic>`

### [async] `truncate()`

### [async] `update()`
* `List<dynamic> key`
* `List<StorageUpdateOperation> operations`
* [return] `List<dynamic>`

### [async] `upsert()`
* `List<dynamic> tuple`
* `List<StorageUpdateOperation> operations`
* [return] `List<dynamic>`

### [async] `select()`
* [optional] `List<dynamic`
* [optional] `int offset`
* [optional] `int limit`
* [optional] `StorageIteratorType iteratorType`
* [return] `List<dynamic>`

### [async] `batch()`
* `Function(StorageBatchSpaceBuilder builder) builder`
* [return] `List<dynamic>`

## Index - StorageIndex
### [async] `count()`
* [optional] `List<dynamic> key`
* [optional] `StorageIteratorType iteratorType`
* [return] `int`

### [async] `iterator()`
* [optional] `List<dynamic> key`
* [optional] `StorageIteratorType iteratorType`
* [return] `StorageIterator`

### [async] `delete()`
* `List<dynamic> key`
* [return] `List<dynamic>`

### [async] `min()`
* [optional] `List<dynamic> key`
* [return] `List<dynamic>`

### [async] `max()`
* [optional] `List<dynamic> key`
* [return] `List<dynamic>`

### [async] `update()`
* `List<dynamic> key`
* `List<StorageUpdateOperation> operations`
* [return] `List<dynamic>`

### [async] `select()`
* [optional] `List<dynamic`
* [optional] `int offset`
* [optional] `int limit`
* [optional] `StorageIteratorType iteratorType`
* [return] `List<dynamic>`

### [async] `batch()`
* `Function(StorageBatchIndexBuilder builder) builder`
* [return] `List<dynamic>`

## Iterator - StorageIterator
### [async] `next()`
* [optional] `count`
* [return] `List<List<dynamic>>?`

### [async] `destroy()`

### [async] `collect()`
* [optional] `bool Function(List<dynamic> value) filter`
* [optional] `dynamic Function(List<dynamic> value) map`
* [optional] `int limit`
* [optional] `int offset`
* [optional] `int count`
* [return] `List<dynamic>`

### [async] `forEach()`
* `void Function(dynamic element) action`
* [optional] `bool Function(List<dynamic> value) filter`
* [optional] `dynamic Function(List<dynamic> value) map`
* [optional] `int limit`
* [optional] `int offset`
* [optional] `int count`

### [async] `stream()`
* [optional] `bool Function(List<dynamic> value) filter`
* [optional] `dynamic Function(List<dynamic> value) map`
* [optional] `int limit`
* [optional] `int offset`
* [optional] `int count`
* [return] `Stream<dynamic>`

## Batch
### StorageBatchSpaceBuilder

#### `insert()`
* `List<dynamic> data`

#### `put()`
* `List<dynamic> data`

#### `put()`
* `List<dynamic> data`

#### `delete()`
* `List<dynamic> data`

#### `update()`
* `List<dynamic> key, List<StorageUpdateOperation> operations`

#### `upsert()`
* `List<dynamic> tuple, List<StorageUpdateOperation> operations`

#### `insertMany()`
* `List<List<dynamic>> data`

#### `putMany()`
* `List<List<dynamic>> data`

#### `putMany()`
* `List<List<dynamic>> data`

#### `deleteMany()`
* `List<List<dynamic>> data`

### StorageBatchIndexBuilder

#### `update()`
* `List<dynamic> key, List<StorageUpdateOperation> operations`

## Lua - StorageLuaExecutor
### [async] `startBackup()`

### [async] `stopBackup()`

### [async] `promote()`

### [async] `configure()`
* `StorageConfiguration configuration`

### [async] `script()`
* `String expression`
* [optional] `List<dynamic> arguments`
* [return] `List<dynamic>`

### [async] `file()`
* `File file`

### [async] `require()`
* `String module`

### [async] `call()`
* `String function`
* [optional] `List<dynamic> arguments`
* [return] `List<dynamic>`

## Native - StorageNativeExecutor
### [async] `call()`
* `tarantool_function function`
* [optional] `tarantool_function_argument argument`
* [return] `Pointer<Void>`

# Configuration

## StorageConfiguration
This class fully identical to [Tarantool configuration](https://www.tarantool.io/en/doc/latest/reference/configuration/)

## StorageMessageLoopConfiguration
* `int boxOutputBufferCapacity` - 
* `double messageLoopMaxSleepSeconds` - 
* `int messageLoopRingSize` - 
* `double messageLoopRegularSleepSeconds` - 
* `int messageLoopMaxEmptyCycles` - 
* `int messageLoopEmptyCyclesMultiplier` - 
* `int messageLoopInitialEmptyCycles` - 
* `int messageLoopRingRetryMaxCount` - 

## StorageBootConfiguration
* `String user` -
* `String password` -
* `Duration delay` -

## StorageReplicationConfiguration

### `addAddressReplica()`
* `String host`
* `String port`
* [optional] `String user` 
* [optional] `String password`

### `addPortReplica()`
* `int port`

### `addReplica()`
* `String uri`

### `format()`
* [return] `String`

# Perfomance

TODO: Make benchmark on preferable machine

Latest benchmark results (count of entities - 1M, single Dart Isolate):

* Get RPS: 200k
* Lua function RPS: 200k
* Select time: 250 milliseconds
* Iterator time (with 1k prefetch count): 1 second
* Batch insert: 2.7 seconds

# Limitations

* Linux only
* Currently, Tarantool VShard is not supported, but you still can use it by writing lua code to `module.lua`
* Currently, Tarantool MVCC is not tested, but you can enable it by configuration
* Currently, tested only on x86 architecture, ARM and others are not tested but could work
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