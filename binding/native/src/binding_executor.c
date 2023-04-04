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
#include "sys/eventfd.h"
#include "coio.h"

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
      element->error = strdup(BATCH_ERROR_MESSAGE);
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
  struct ev_io io;
  io.data = fiber();
  ev_init(&io, (ev_io_cb)fiber_schedule_cb);
  io.fd = eventfd(0, 0); // ring_fd

  ev_tstamp start, delay;
  evio_timeout_init(loop(), &start, &delay, TIMEOUT_INFINITY);

  ev_io_set(&io, io.fd, EV_SIGNAL);
  ev_io_start(loop(), &io);

  while (likely(active))
  {
    bool uring_has_cqes = false;
    if (uring_has_cqes)
    {
      tarantool_message_t *message;
      if (unlikely(message->type == TARANTOOL_MESSAGE_STOP))
      {
        active = false;
        free(message);
        if (uring_has_cqes)
        {
          tarantool_message_handle(message);
        }
        free(tarantool_message_buffer);
        break;
      }
      tarantool_message_handle(message);
    }

    while (in_txn())
    {
      // handle and wait cqes
    }

    io.data = fiber();
    fiber_yield_timeout(delay);
    io.data = NULL;
    fiber_testcancel();
    evio_timeout_update(loop(), &start, &delay)
  }

  ev_io_stop(loop(), &io);
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