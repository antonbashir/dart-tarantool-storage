#include "binding_dart_functions.h"
#include "dart/dart_api_dl.h"

Dart_Handle dart_get_handle_from_message(struct tarantool_message_t *message)
{
    return Dart_HandleFromPersistent((Dart_PersistentHandle)message->callback_handle);
}

void dart_delete_handle_from_message(struct tarantool_message_t *message)
{
    Dart_DeletePersistentHandle((Dart_PersistentHandle)message->callback_handle);
}
