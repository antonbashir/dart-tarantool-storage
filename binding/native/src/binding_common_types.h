#ifndef BINDING_INITIALIZER_H_INCLUDED
#define BINDING_INITIALIZER_H_INCLUDED

#include "dart/dart_api.h"
#include <stddef.h>

#if defined(__cplusplus)
extern "C"
{
#endif
	enum tarantool_message_type
	{
		TARANTOOL_MESSAGE_CALL_FUNCTION = 0,
		TARANTOOL_MESSAGE_BATCH = 1,
		TARANTOOL_MESSAGE_STOP_LOOP = 2,
		tarantool_message_type_MAX,
	};

	typedef void *(*tarantool_function)(void *);
	typedef void (*tarantool_consumer)(void *);
	typedef void *tarantool_function_argument;

	typedef struct tarantool_message_batch_element_t
	{
		tarantool_function function;
		tarantool_function_argument input;
		tarantool_function_argument output;
	} tarantool_message_batch_element_t;

	typedef struct tarantool_message_t
	{
		enum tarantool_message_type type;
		tarantool_function function;
		tarantool_function_argument input;
		tarantool_function_argument output;
		Dart_Port callback_send_port;
		Dart_Handle *callback_handle;
		tarantool_message_batch_element_t **batch;
		size_t batch_size;
    bool transactional;
    bool begin_transaction;
    bool commit_transaction;
	} tarantool_message_t;

	typedef struct tarantool_tuple_t
	{
		char *data;
		size_t size;
	} tarantool_tuple_t;
#if defined(__cplusplus)
}
#endif

#endif
