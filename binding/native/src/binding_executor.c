#include "binding_executor.h"
#include <small/region.h>
#include <stdbool.h>
#include <cbus.h>
#include <fiber.h>
#include "binding_box.h"
#include <small/small.h>
#include "box/tuple.h"
#include "ck_ring.h"
#include "ck_backoff.h"
#include "dart/dart_api_dl.h"

#define MESSAGE_BUFFER_ERROR "Failed to allocate message ring buffer"

static ck_ring_buffer_t *tarantool_message_buffer;
static ck_ring_t tarantool_message_ring;
static volatile bool active = false;
unsigned int __thread transaction_owner = -1;

static inline void dart_post_pointer(void *pointer, Dart_Port port)
{
  Dart_CObject dart_object;
  dart_object.type = Dart_CObject_kInt64;
  dart_object.value.as_int64 = (int64_t)pointer;
  Dart_PostCObject(port, &dart_object);
};

static inline void tarantool_message_handle_call(tarantool_message_t *message)
{
  message->output = message->function(message->input);
  struct error *error = diag_last_error(diag_get());
  if (unlikely(error))
  {
    message->failed = true;
    error_log(error);
    diag_clear(diag_get());
  }
}

static inline void tarantool_message_handle_batch(tarantool_message_t *message)
{
  for (size_t index = 0; index < message->batch_size; index++)
  {
    tarantool_message_batch_element_t *element = message->batch[index];
    element->output = element->function(element->input);
    struct error *error = diag_last_error(diag_get());
    if (unlikely(error))
    {
      message->failed = true;
      element->failed = true;
      element->output = NULL;
      error_log(error);
      diag_clear(diag_get());
    }
  }
}

static inline void tarantool_message_handle(tarantool_message_t *message)
{
  if (tarantool_in_transaction())
  {
    if (message->owner != transaction_owner) {
      ck_ring_enqueue_mpsc(&tarantool_message_ring, tarantool_message_buffer, message);
      return;
    }
  }
  switch (message->type)
  {
  case TARANTOOL_MESSAGE_CALL:
    tarantool_message_handle_call(message);
    dart_post_pointer(message, message->callback_send_port);
    return;
  case TARANTOOL_MESSAGE_BATCH:
    tarantool_message_handle_batch(message);
    dart_post_pointer(message, message->callback_send_port);
    return;
  case TARANTOOL_MESSAGE_BEGIN:
    transaction_owner = message->owner;
    tarantool_begin();
    dart_post_pointer(message, message->callback_send_port);
    return;
  case TARANTOOL_MESSAGE_ROLLBACK:
    tarantool_rollback();
    dart_post_pointer(message, message->callback_send_port);
    return;
  case TARANTOOL_MESSAGE_COMMIT:
    tarantool_commit();
    dart_post_pointer(message, message->callback_send_port);
    return;
  default:
    return;
  }
}

void tarantool_message_loop_initialize(tarantool_message_loop_configuration_t *configuration)
{
  tarantool_message_buffer = malloc(sizeof(ck_ring_buffer_t) * configuration->message_loop_ring_size);
  if (tarantool_message_buffer == NULL)
  {
    say_crit(MESSAGE_BUFFER_ERROR);
    return;
  }
  ck_ring_init(&tarantool_message_ring, configuration->message_loop_ring_size);
  active = true;
}

void tarantool_message_loop_start(tarantool_message_loop_configuration_t *configuration)
{
  int initial_empty_cycles = configuration->message_loop_initial_empty_cycles;
  int max_empty_cycles = configuration->message_loop_max_empty_cycles;
  int cycles_multiplier = configuration->message_loop_empty_cycles_multiplier;
  double regular_sleep_seconds = configuration->message_loop_regular_sleep_seconds;
  double max_sleep_seconds = configuration->message_loop_max_sleep_seconds;
  int current_empty_cycles = 0;
  int curent_empty_cycles_limit = initial_empty_cycles;

  while (likely(active))
  {
    tarantool_message_t *message;
    if (ck_ring_dequeue_mpsc(&tarantool_message_ring, tarantool_message_buffer, &message))
    {
      current_empty_cycles = 0;
      curent_empty_cycles_limit = initial_empty_cycles;

      if (likely(message->type != TARANTOOL_MESSAGE_STOP))
      {
        tarantool_message_handle(message);
        continue;
      }

      active = false;
      free(message);
      while (ck_ring_dequeue_mpsc(&tarantool_message_ring, tarantool_message_buffer, &message))
      {
        tarantool_message_handle(message);
      }

      break;
    }

    if (tarantool_in_transaction())
    {
      continue;
    }

    current_empty_cycles++;
    if (current_empty_cycles >= max_empty_cycles)
    {
      fiber_sleep(max_sleep_seconds);
      continue;
    }

    if (current_empty_cycles >= curent_empty_cycles_limit)
    {
      curent_empty_cycles_limit *= cycles_multiplier;
      fiber_sleep(regular_sleep_seconds);
      continue;
    }
  }
}

bool tarantool_send_message(tarantool_message_t *message, Dart_Handle callback)
{
  if (unlikely(active == false))
  {
    return false;
  }
  message->callback_handle = (Dart_Handle *)Dart_NewPersistentHandle(callback);
  return ck_ring_enqueue_mpsc(&tarantool_message_ring, tarantool_message_buffer, message);
}

void tarantool_message_loop_stop()
{
  tarantool_message_t *message = malloc(sizeof(tarantool_message_t));
  message->type = TARANTOOL_MESSAGE_STOP;
  ck_ring_enqueue_mpsc(&tarantool_message_ring, tarantool_message_buffer, message);
}

bool tarantool_message_loop_active()
{
  return active;
}

tarantool_tuple_t *tarantool_tuple_from_box(box_tuple_t *source)
{
  size_t size = box_tuple_bsize(source);
  char *data = malloc(size);
  box_tuple_to_buf(source, data, size);
  return tarantool_tuple_new(data, size);
}

tarantool_tuple_t *tarantool_tuple_new(char *data, size_t size)
{
  tarantool_tuple_t *return_tuple = malloc(sizeof(tarantool_tuple_t));
  if (unlikely(return_tuple == NULL))
  {
    return NULL;
  }
  return_tuple->data = data;
  return_tuple->size = size;
  return return_tuple;
}

void *tarantool_tuple_allocate(size_t size)
{
  return malloc(size);
}

void tarantool_tuple_free(tarantool_tuple_t *tuple)
{
  free(tuple->data);
  free(tuple);
}
