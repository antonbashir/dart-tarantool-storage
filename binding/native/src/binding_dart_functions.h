#ifndef BINDING_DART_FUNCTIONS_H_INCLUDED
#define BINDING_DART_FUNCTIONS_H_INCLUDED
#include "binding_common_types.h"

#if defined(__cplusplus)
extern "C"
{
#endif
    Dart_Handle dart_get_handle_from_message(struct tarantool_message_t *message);
    void dart_delete_handle_from_message(struct tarantool_message_t *message);
#if defined(__cplusplus)
}
#endif

#endif
