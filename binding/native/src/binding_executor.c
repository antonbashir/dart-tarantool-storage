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
#include "box/txn.h"

#define MESSAGE_BUFFER_ERROR "Failed to allocate message ring buffer"
#define MESSAGE_SEND_ERROR "Failed to resend message into the ring during transaction"
#define BATCH_ERROR_MESSAGE "Batch execution failed"

static ck_ring_buffer_t *tarantool_message_buffer;
static ck_ring_t tarantool_message_ring;
static volatile bool active = false;
unsigned int __thread transaction_owner = -1;
static ck_backoff_t __thread ring_send_backoff = CK_BACKOFF_INITIALIZER;
static int ring_retry_max_count = 3;

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
    message->error = strdup(error->errmsg);
    message->error_type = TARANTOOL_ERROR_INTERNAL;
    message->output = NULL;
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
      message->error = strdup(BATCH_ERROR_MESSAGE);
      element->output = NULL;
      element->error = strdup(error->errmsg);
      element->error_type = TARANTOOL_ERROR_INTERNAL;
      diag_clear(diag_get());
    }
  }
}

static inline void tarantool_message_handle(tarantool_message_t *message)
{
  if (in_txn())
  {
    if (message->owner != transaction_owner)
    {
      int count = 0;
      while (unlikely(!ck_ring_enqueue_mpsc(&tarantool_message_ring, tarantool_message_buffer, message)))
      {
        ck_backoff_eb(&ring_send_backoff);
        if (++count >= ring_retry_max_count)
        {
          ring_send_backoff = CK_BACKOFF_INITIALIZER;
          message->error = strdup(MESSAGE_SEND_ERROR);
          message->error_type = TARANTOOL_ERROR_LIMIT;
          dart_post_pointer(message, message->callback_send_port);
          return;
        }
      }
      ring_send_backoff = CK_BACKOFF_INITIALIZER;
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
  ring_retry_max_count = configuration->message_loop_ring_retry_max_count;
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
      free(tarantool_message_buffer);
      break;
    }

    if (in_txn())
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
  int count = 0;
  while (unlikely(!ck_ring_enqueue_mpsc(&tarantool_message_ring, tarantool_message_buffer, message)))
  {
    ck_backoff_eb(&ring_send_backoff);
    if (++count >= ring_retry_max_count)
    {
      ring_send_backoff = CK_BACKOFF_INITIALIZER;
      return false;
    }
  }
  ring_send_backoff = CK_BACKOFF_INITIALIZER;
  return true;
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