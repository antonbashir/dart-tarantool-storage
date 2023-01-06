#ifndef BINDING_COMMON_H_INCLUDED
#define BINDING_COMMON_H_INCLUDED

#include "dart/dart_api.h"
#include <stddef.h>

#if defined(__cplusplus)
extern "C"
{
#endif
  enum tarantool_message_type
  {
    TARANTOOL_MESSAGE_CALL = 0,
    TARANTOOL_MESSAGE_BATCH = 1,
    TARANTOOL_MESSAGE_STOP = 2,
    TARANTOOL_MESSAGE_BEGIN = 3,
    TARANTOOL_MESSAGE_COMMIT = 4,
    TARANTOOL_MESSAGE_ROLLBACK = 5,
    tarantool_message_type_MAX,
  };
  
  enum tarantool_error_type
  {
    TARANTOOL_ERROR_LIMIT = 0,
    TARANTOOL_ERROR_INTERNAL = 1,
    tarantool_error_type_MAX,
  };

  typedef void *(*tarantool_function)(void *);
  typedef void (*tarantool_consumer)(void *);
  typedef void *tarantool_function_argument;

  typedef struct tarantool_message_batch_element_t
  {
    tarantool_function function;
    tarantool_function_argument input;
    tarantool_function_argument output;
    char *error;
    enum tarantool_error_type error_type;
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
    char *error;
    enum tarantool_error_type error_type;
    unsigned int owner;
  } tarantool_message_t;

  typedef struct tarantool_tuple_t
  {
    const char *data;
    size_t size;
  } tarantool_tuple_t;

  unsigned int tarantool_generate_owner_id();
#if defined(__cplusplus)
}
#endif

#endif
