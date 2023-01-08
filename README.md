# Introduction

The main goal of this library is to provide fast and strong database to Dart developers.

This repository contains fork of Tarantool Database (currently 2.8.4 version, will be updated to 2.11 after release).

Currently there are a lot of local database solutions for Dart (Isaar, Hive, ObjectBox) and a lot of connectors to famous databases (such as  Redis, Postgres, Mongo, .etc).

But also exists need of predictable and controllable data storage solution with freedom of customization of data processing logic. 

Dart Tarantool storage should helps with this need by combining Tarantool features and Dart language features.

## About Tarantool
* [Tarantool Documentation](https://tarantool.io/en/doc)

### Features
* schema and schemaless per space
* speed
* in-memory and disk engines per space
* asynchronouse replication and synchronous replication with raft and auto leader election
* fluent and predictable data processing (you write code in procedural style which is working with your data)
* transactional
* (after 2.10) MVCC and interactive (stream) transactions - currently not supported in this library
* [sharding](https://www.tarantool.io/en/doc/latest/reference/reference_rock/vshard/) - currently not supported in this library


# Idea and concepts

![Main diagram](dart-tarantool-storage.svg)

## Architecture

Tarantool is using as shared library (.so) and running in separate single thread.

Between Tarantool and Dart code existing ring buffer which transporting messages from Dart to Tarantool.

After execution of message Tarantool thread will notify DartVM with Dart_Post. 

Message structure: `{type,function,input,output,batch[{function,input,output,error}],error}`.

* `type` - type or action of message
* `function` - pointer to binding function which should be called in Tarantool thread and has access to Tarantool API
* `input` - binding function argument
* `output` - holder for function result
* `error` - holder for Tarantool error which could happen during function calling
* `batch` - array of structure simillar to message (for bulk execution of functions)

### Message types
* call
* batch
* begin
* commit
* rollback
* stop

### Message input variations
* management request
* space request
* index request
* index request


# Installation


# Usage 

## Sample

## Lua custom modules


## Native custom modules


# API

## Storage
## Space
## Index
## Iterator
## Lua
## Native

# Perfomance

TODO: Make benchmark on preferable machine

Latest benchmark results (count of entities - 1M, single dart Isolate):

* Get RPS: 200k
* Lua function RPS: 170k
* Select time: 250 milliseconds
* Iterator time (with 1k prefetch count): 1 second
* Batch insert: 2.7 seconds

# Limitations

* Linux only
* Currently not supported Tarantool VShard but you stil can use it by writing lua code to `extension.lua`
* Currently not tested Tarantool MVCC but you can enable it by configuration
* Currently tested only on x86 proccessors, arm and other not tested but could work
* Not production tested, current version be just coded and tested by function unit tests, possible bug