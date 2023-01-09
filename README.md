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
* [return] `List<List<dynamic>>?` - Tuples or null if iterator reached the end

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
* [optional] `bool ifNotExists` - If true then Tarantool will ignore space existence and update it
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
* `String spaceName` - Space name (owner of creating index)
* `String indexName` - Index name
* [optional] `StorageIndexType type` - Index type (could be hash, set, tree, bitset, rtree)
* [optional] `int id` - Index id
* [optional] `bool unique` - If true then index should not contains duplicates
* [optional] `bool ifNotExists` - If true then Tarantool will ignore index existence and update it
* [optional] `List<StorageIndexPart> parts` - Index parts. Every part includes field number and field type

### [async] `alterIndex()` - DDL operation for altering Tarantool index
* `String spaceName` - Space name (owner of altering index)
* `String indexName` - Index name
* [optional] `List<StorageIndexPart> parts` - Index parts. Every part includes field number and field type

### [async] `dropIndex()` DDL operation for dropping Tarantool space
* `String spaceName` - Space name (owner of dropping index)
* `String indexName` - Index name

### [async] `createUser()` - DDL operation for creating Tarantool user
* `String name` - User name
* `String password` - User password
* [optional] `bool ifNotExists` - If true then Tarantool will ignore user existence and update it

### [async] `dropUser()` - DDL operation for dropping Tarantool user
* `String name` - User name

### [async] `changePassword()` - Changing Tarnatool user password
* `String name` - User name
* `String password` - New user password

* [async] `userExists()` - Checking that Tarantool user exists
* `String name` - User name
* [return] `bool` - True if exists

### [async] `grantUser()` - DDL operation for granting Tarantool user permissions [see](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_schema/user_grant/)
* `String name` - User name
* `String privileges` - User privileges
* [optional] `String objectType` - Permission object type
* [optional]  `String objectName` - Permission object name
* [optional] `String roleName` - User role
* [optional] `bool ifNotExists` - If true then Tarantool will ignore grant existence

### [async] `revokeUser()` - DDL operation for revoking Tarantool user permissions [see](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_schema/user_revoke/)
* `String name` - User name
* `String privileges` - User privileges
* [optional] `String objectType` - Permission object type
* [optional]  `String objectName` - Permission object name
* [optional] `String roleName` - User role
* [optional] `bool ifNotExists` - If true then Tarantool will ignore grant existence

## Space - StorageSpace
### [async] `count()` - Counting tuples in the space
* [optional] `List<dynamic> key` - Include in count only matched tuples by key
* [optional] `StorageIteratorType iteratorType` - Tarantool iterator type [see](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_index/pairs/)
* [return] `int` - Count of tuples

### [async] `isEmpty()` - Checking that space is empty
* [return] `bool` - True if empty

### [async] `isNotEmpty()` - Checking that space is not empty
* [return] `bool` - True if not empty

### [async] `length()` - Getting space length (faster than count)
* [return] `int` - Space length

### [async] `iterator()` - Creating iterator for tuples ([see pairs](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_space/pairs/))
* [optional] `List<dynamic> key` - Include only matched tuples by key
* [optional] `StorageIteratorType iteratorType` - Tarantool iterator type [see](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_index/pairs/)
* [return] `StorageIterator` - Created iterator instance

### [async] `insert()` - Inserting tuple into the space
* `List<dynamic> data` - Tuple
* [return] `List<dynamic>` - Inserted tuple

### [async] `put()` - Putting tuple into the space (ignore existence)
* `List<dynamic> data` - Tuple
* [return] `List<dynamic>` - Putted tuple

### [async] `get()` - Getting tuple from the space by key
* `List<dynamic> key` - Key to find tuple
* [return] `List<dynamic>` - Received tuple

### [async] `delete()` - Deleting tuple from the space
* `List<dynamic> key` - Key to find tuple for deletion
* [return] `List<dynamic>` - Deleted tuple

### [async] `min()` - Getting minimal tuple from the space
* [optional] `List<dynamic> key` - Key to find tuple
* [return] `List<dynamic>` - Received tuple

### [async] `max()` - Getting maximal tuple from the space
* [optional] `List<dynamic> key` - Key to find tuple
* [return] `List<dynamic>` - Received tuple

### [async] `truncate()` - Truncating space

### [async] `update()` - Updating space tuple by key with operations
* `List<dynamic> key` - Tuple key
* `List<StorageUpdateOperation> operations` - Update oeprations. [See](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_space/update/)
* [return] `List<dynamic>` - Updated tuple

### [async] `upsert()` - Updating with operations or inserting tuple in the space 
* `List<dynamic> tuple` - Tuple
* `List<StorageUpdateOperation> operations` - Update oeprations. [See](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_space/update/)
* [return] `List<dynamic>` - Updated or inserted tuple

### [async] `select()` - Selecting tuples from the space
* [optional] `List<dynamic> key` - Selecting tuples only matched with key
* [optional] `int offset` - Offset for selection
* [optional] `int limit` - Limit for selection
* [optional] `StorageIteratorType iteratorType` - Tarantool iterator type [see](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_space/pairs/)
* [return] `List<dynamic>` - Selected tuples

### [async] `batch()` - Batch operations provider
* `Function(StorageBatchSpaceBuilder builder) builder` - Batch operations builder
* [return] `List<dynamic>` - Result tuple after batch execution

## Index - StorageIndex 
### [async] `count()` - Counting tuples in the space
* [optional] `List<dynamic> key` - Include in count only matched tuples by key
* [optional] `StorageIteratorType iteratorType` - Tarantool iterator type [see](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_space/pairs/)
* [return] `int` - Count of tuples

### [async] `iterator()` - Creating iterator for tuples ([see pairs](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_space/pairs/))
* [optional] `List<dynamic> key` - Include only matched tuples by key
* [optional] `StorageIteratorType iteratorType` - Tarantool iterator type [see](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_space/pairs/)
* [return] `StorageIterator` - Created iterator instance

### [async] `delete()` - Deleting tuple from the space by index
* `List<dynamic> key` - Key to find tuple for deletion
* [return] `List<dynamic>` - Deleted tuple

### [async] `min()` - Getting minimal tuple from the space
* [optional] `List<dynamic> key` - Key to find tuple
* [return] `List<dynamic>` - Received tuple

### [async] `max()` - Getting maximal tuple from the space
* [optional] `List<dynamic> key` - Key to find tuple
* [return] `List<dynamic>`  - Received tuple

### [async] `update()` - Updating space tuple by key with operations
* `List<dynamic> key` - Tuple key
* `List<StorageUpdateOperation> operations` - Update oeprations. [See](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_index/update/)
* [return] `List<dynamic>`

### [async] `select()` - Selecting tuples from the space
* [optional] `List<dynamic` - Selecting tuples only matched with key
* [optional] `int offset` - Offset for selection
* [optional] `int limit` - Limit for selection
* [optional] `StorageIteratorType iteratorType` - Tarantool iterator type [see](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_index/pairs/)
* [return] `List<dynamic>` -  Selected tuples

### [async] `batch()` - Batch operations provider
* `Function(StorageBatchIndexBuilder builder) builder` - Batch operations builder
* [return] `List<dynamic>` - Result tuple after batch execution

## Iterator - StorageIterator
### [async] `next()` - Getting next element of the iterator
* [optional] `count` - Prefetch count. Binding can prefetch more tuples than 1 and combine it after return
* [return] `List<List<dynamic>>?` - Tuples or null if iterator reached the end

### [async] `destroy()` - Destroying Tarnatool iterator

### [async] `collect()` - Collecting all elements by iterator
* [optional] `bool Function(List<dynamic> value) filter` - Iterator filter
* [optional] `dynamic Function(List<dynamic> value) map` - Iterator mapper
* [optional] `int limit` - Iterator limit
* [optional] `int offset` - Iterator offset
* [optional] `int count` - Prefetch count. Binding can prefetch more tuples than 1 and combine it after return
* [return] `List<dynamic>` - Collected tuples

### [async] `forEach()` - Executing actin for all elements by iterator
* `void Function(dynamic element) action` - Action on tuple
* [optional] `bool Function(List<dynamic> value) filter` - Iterator filter
* [optional] `dynamic Function(List<dynamic> value) map` - Iterator mapper
* [optional] `int limit` - Iterator limit
* [optional] `int offset` - Iterator offset
* [optional] `int count`  - Prefetch count. Binding can prefetch more tuples than 1 and combine it after return

### [async] `stream()` - Stream of tuples from iterator
* [optional] `bool Function(List<dynamic> value) filter` - Iterator filter
* [optional] `dynamic Function(List<dynamic> value) map` - Iterator mapper
* [optional] `int limit` - Iterator limit
* [optional] `int offset` - Iterator offset
* [optional] `int count` - Prefetch count. Binding can prefetch more tuples than 1 and combine it after return
* [return] `Stream<dynamic>` - Stream of tuples

## Batch
### StorageBatchSpaceBuilder

#### `insert()` - Adding insert operation to batch
* `List<dynamic> data` - Inserting tuple

#### `put()` - Adding put operation to batch
* `List<dynamic> data` - Putting tupple

#### `delete()` - Adding delete operation to batch
* `List<dynamic> data` - Deleting tuple

#### `update()` - Adding update operation to batch
* `List<dynamic> key` - Tuple key
* `List<StorageUpdateOperation> operations` - Update oeprations. [See](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_index/update/)

#### `upsert()` - Adding update operation to batch
* `List<dynamic> tuple` - Tuple to insert or update
* `List<StorageUpdateOperation> operations` - Update oeprations. [See](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_index/update/)

#### `insertMany()` - Adding insert operations to batch
* `List<List<dynamic>> data` - Inserted tuples

#### `putMany()` - Adding put operations to batch
* `List<List<dynamic>> data` - Putted tuples

#### `deleteMany()` - Adding delete operations to batch
* `List<List<dynamic>> data` - Deleted tuples

### StorageBatchIndexBuilder

#### `update()` - Adding update operation to batch
* `List<dynamic> key` - Tuple key
* `List<StorageUpdateOperation> operations` - Update oeprations. [See](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_index/update/)

## Lua - StorageLuaExecutor
### [async] `startBackup()` - Executing box.backup.start() [see](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_backup/start/)

### [async] `stopBackup()` - Executing box.backup.stop() [see](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_backup/stop/)

### [async] `promote()` - Executing box.ctl.promote() [see](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_ctl/promote/)

### [async] `configure()` - Executing box.cfg{} [see](https://www.tarantool.io/en/doc/latest/reference/reference_lua/box_cfg/)
* `StorageConfiguration configuration` - Tarantool Configuration

### [async] `script()` - Evaluating Lua script
* `String expression` - Script
* [optional] `List<dynamic> arguments` - Script arguments
* [return] `List<dynamic>` - Script result

### [async] `file()` - Evaluating Lua file
* `File file` - Lua script file

### [async] `require()` - Calling Lua 'require' function
* `String module` - Requiring module

### [async] `call()` - Calling Lua function
* `String function` - Lua function
* [optional] `List<dynamic> arguments` - Lua function arguments
* [return] `List<dynamic>` - Lua function result

## Native - StorageNativeExecutor
### [async] `call()` - Calling Native function
* `tarantool_function function` - Pointer to Native function
* [optional] `tarantool_function_argument argument` - Pointer or Native value as function argument
* [return] `Pointer<Void>` - Pointer to function result

# Configuration

## StorageConfiguration
This class fully identical to [Tarantool configuration](https://www.tarantool.io/en/doc/latest/reference/configuration/)

## StorageMessageLoopConfiguration
* `int boxOutputBufferCapacity` - Internal buffer initial capacity for some returing tuples
* `double messageLoopMaxSleepSeconds` - Max count of seconds for binding message loop idle sleeping time
* `int messageLoopRingSize` - Internal ring buffer size for all messages between Dart and Tarantool
* `double messageLoopRegularSleepSeconds` - Count of seconds for binding message loop idle sleeping time before count of empty cycles reached maximum
* `int messageLoopMaxEmptyCycles` - Maximum of empty cycles
* `int messageLoopEmptyCyclesMultiplier` - Multiplier for empty cycles
* `int messageLoopInitialEmptyCycles` - Initial count for empty cycles
* `int messageLoopRingRetryMaxCount` - Maximum retry count during tries of returing message into queue (used in concurrent transactions)

## StorageBootConfiguration
* `String user` - Initial Tarantool user name
* `String password` - Initial Tarantool user password
* `Duration delay` - Delay after boot (could be usable for delay between replica bootstraps)

## StorageReplicationConfiguration

### `addAddressReplica()` - Adding new replica with host and port to configuration
* `String host` - Replica host
* `String port` - Replica port
* [optional] `String user` - Replication user (should exists on all replicas)
* [optional] `String password` - Replication user password

### `addPortReplica()` - Adding new replica with localhost and port to configuration
* `int port` - Replica port

### `addReplica()` - Adding new replica with uri to configuration
* `String uri` - Replica uri

### `format()` - Creating final replica configuration in Lua table representation
* [return] `String` - Lua table

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