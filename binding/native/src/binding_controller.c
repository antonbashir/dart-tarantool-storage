#include "binding_controller.h"
#include "box/txn.h"
#include "box/box.h"
#include "lib/core/fiber.h"
#include "lua/init.h"
#include "main.h"
#include <lua.h>
#include <luajit.h>
#include <lauxlib.h>
#include "cbus.h"
#include "binding_executor.h"
#include "binding_box.h"
#include "on_shutdown.h"
#include "dart/dart_api_dl.h"

#define TARANTOOL_MESSAGE_LOOP_FIBER "message-loop"

struct tarantool_storage
{
  pthread_t main_thread_id;
  pthread_mutex_t initialization_mutex;
  pthread_cond_t initialization_condition;
  pthread_mutex_t shutdown_mutex;
  pthread_cond_t shutdown_condition;
  bool initialized;
  tarantool_configuration_t configuration;
};

struct initialization_args
{
  char *binary_path;
  char *script;
};

static struct tarantool_storage storage;

void *tarantool_process_initialization(void *binary_path);
int tarantool_fiber(va_list args);
void tarantool_complete_initialization();

static inline void dart_post_pointer(void *pointer, Dart_Port port)
{
  Dart_CObject dart_object;
  dart_object.type = Dart_CObject_kInt64;
  dart_object.value.as_int64 = (int64_t)pointer;
  Dart_PostCObject(port, &dart_object);
};

int tarantool_shutdown_trigger(void *ignore)
{
  (void)ignore;
  if (tarantool_message_loop_active())
  {
    tarantool_message_loop_stop();
  }
  ev_break(loop(), EVBREAK_ALL);
  return 0;
}

void tarantool_initialize(char *binary_path, char *script, tarantool_configuration_t *configuration)
{
  if (storage.initialized)
  {
    return;
  }
  storage.configuration = *configuration;
  struct initialization_args *args = malloc(sizeof(struct initialization_args));
  args->binary_path = binary_path;
  args->script = script;
  tt_pthread_create(&storage.main_thread_id, NULL, tarantool_process_initialization, args);
  tt_pthread_mutex_lock(&storage.initialization_mutex);
  while (!storage.initialized)
    tt_pthread_cond_wait(&storage.initialization_condition, &storage.initialization_mutex);
  tt_pthread_mutex_unlock(&storage.initialization_mutex);
  tt_pthread_cond_destroy(&storage.initialization_condition);
  tt_pthread_mutex_destroy(&storage.initialization_mutex);
}

void *tarantool_process_initialization(void *input)
{
  struct initialization_args *args = (struct initialization_args *)input;

  tarantool_initialize_library(args->binary_path);

  int events = ev_activecnt(loop());

  if (tarantool_lua_run_string(args->script) != 0)
  {
    diag_log();
    diag_raise();
    return NULL;
  }

  start_loop = start_loop && ev_activecnt(loop()) > events;

  region_free(&fiber()->gc);
  free(input);

  if (start_loop)
  {
    if (box_on_shutdown(NULL, tarantool_shutdown_trigger, NULL) != 0)
    {
      return NULL;
    }
    ev_now_update(loop());
    fiber_start(fiber_new(TARANTOOL_MESSAGE_LOOP_FIBER, tarantool_fiber));
    ev_run(loop(), 0);
  }

  if (storage.initialized)
  {
    tt_pthread_mutex_lock(&storage.shutdown_mutex);
    tarantool_destroy_box();
    tarantool_shutdown_library(0);
    storage.initialized = false;
//    dart_post_pointer(NULL, storage.configuration.shutdown_port);
    tt_pthread_cond_broadcast(&storage.shutdown_condition);
    tt_pthread_mutex_unlock(&storage.shutdown_mutex);
  }
  return NULL;
}

int tarantool_fiber(va_list args)
{
  (void)args;
  tarantool_message_loop_configuration_t loop_configuration = {
      .message_loop_empty_cycles_multiplier = storage.configuration.message_loop_empty_cycles_multiplier,
      .message_loop_initial_empty_cycles = storage.configuration.message_loop_initial_empty_cycles,
      .message_loop_max_empty_cycles = storage.configuration.message_loop_max_empty_cycles,
      .message_loop_max_sleep_seconds = storage.configuration.message_loop_max_sleep_seconds,
      .message_loop_regular_sleep_seconds = storage.configuration.message_loop_regular_sleep_seconds,
      .message_loop_ring_size = storage.configuration.message_loop_ring_size,
  };
  tarantool_message_loop_initialize(&loop_configuration);
  tarantool_initialize_box(storage.configuration.box_output_buffer_capacity);
  tarantool_complete_initialization();
  tarantool_message_loop_start(&loop_configuration);
  ev_break(loop(), EVBREAK_ALL);
  return 0;
}

void tarantool_complete_initialization()
{
  tt_pthread_mutex_lock(&storage.initialization_mutex);
  storage.initialized = true;
  tt_pthread_cond_broadcast(&storage.initialization_condition);
  tt_pthread_mutex_unlock(&storage.initialization_mutex);
}

void tarantool_shutdown(int code)
{
  if (storage.initialized)
  {
    if (tarantool_message_loop_active())
    {
      tarantool_message_loop_stop();
      tt_pthread_mutex_lock(&storage.shutdown_mutex);
      while (storage.initialized)
        tt_pthread_cond_wait(&storage.shutdown_condition, &storage.shutdown_mutex);
      tt_pthread_mutex_unlock(&storage.shutdown_mutex);
      tt_pthread_cond_destroy(&storage.shutdown_condition);
      tt_pthread_mutex_destroy(&storage.shutdown_mutex);
    }
  }
}

bool tarantool_initialized()
{
  return storage.initialized;
}