#include "tarantool.h"
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <interactor_native.h>
#include <lauxlib.h>
#include <lua.h>
#include <luajit.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include "box/box.h"
#include "cbus.h"
#include "lib/core/fiber.h"
#include "lua/init.h"
#include "on_shutdown.h"
#include "tarantool_box.h"
#include "tarantool_executor.h"
#include "tarantool_launcher.h"

#define TARANTOOL_EXECUTOR_FIBER "executor"

#define TARANTOOL_LUA_ERROR "Failed to execute initial Lua script"

static struct tarantool_storage
{
    pthread_t main_thread_id;
    pthread_mutex_t initialization_mutex;
    pthread_cond_t initialization_condition;
    pthread_mutex_t shutdown_mutex;
    pthread_cond_t shutdown_condition;
    bool initialized;
    char* initialization_error;
    char* shutdown_error;
    struct tarantool_configuration configuration;
    struct tarantool_box* box;
} storage;

struct tarantool_initialization_args
{
    const char* binary_path;
    const char* script;
};

static int tarantool_shutdown_trigger(void* ignore)
{
    (void)ignore;
    tarantool_executor_stop();
    ev_break(loop(), EVBREAK_ALL);
    return 0;
}

static int tarantool_fiber(va_list args)
{
    (void)args;
    struct tarantool_executor_configuration executor_configuration = {
        .executor_ring_size = storage.configuration.executor_ring_size,
    };
    int error;
    if (error = tarantool_executor_initialize(&executor_configuration))
    {
        tarantool_executor_destroy();
        storage.initialization_error = strerror(error);
        return 0;
    }
    if (error = pthread_mutex_lock(&storage.initialization_mutex))
    {
        tarantool_executor_destroy();
        storage.initialization_error = strerror(error);
        return 0;
    }
    storage.initialized = true;
    if (error = pthread_cond_broadcast(&storage.initialization_condition))
    {
        tarantool_executor_destroy();
        storage.initialized = false;
        storage.initialization_error = strerror(error);
        return 0;
    }
    if (error = pthread_mutex_unlock(&storage.initialization_mutex))
    {
        tarantool_executor_destroy();
        storage.initialized = false;
        storage.initialization_error = strerror(error);
        return 0;
    }
    tarantool_initialize_box(storage.box);
    tarantool_executor_start(&executor_configuration);
    tarantool_destroy_box(storage.box);
    ev_break(loop(), EVBREAK_ALL);
    return 0;
}

static void* tarantool_process_initialization(void* input)
{
    struct tarantool_initialization_args* args = (struct tarantool_initialization_args*)input;

    tarantool_launcher_launch((char*)args->binary_path);

    int events = ev_activecnt(loop());

    if (tarantool_lua_run_string((char*)args->script) != 0)
    {
        diag_log();
        storage.initialization_error = TARANTOOL_LUA_ERROR;
        return NULL;
    }

    start_loop = start_loop && ev_activecnt(loop()) > events;

    region_free(&fiber()->gc);
    free(input);

    if (box_on_shutdown(NULL, tarantool_shutdown_trigger, NULL) != 0)
    {
        storage.initialization_error = strerror(errno);
        return NULL;
    }

    ev_now_update(loop());
    fiber_start(fiber_new(TARANTOOL_EXECUTOR_FIBER, tarantool_fiber));
    ev_run(loop(), 0);

    if (storage.initialized)
    {
        int error;
        if (error = pthread_mutex_lock(&storage.shutdown_mutex))
        {
            storage.shutdown_error = strerror(error);
            return NULL;
        }
        tarantool_launcher_shutdown(0);
        storage.initialized = false;
        if (error = pthread_cond_broadcast(&storage.shutdown_condition))
        {
            storage.shutdown_error = strerror(error);
            return NULL;
        }
        if (error = pthread_mutex_unlock(&storage.shutdown_mutex))
        {
            storage.shutdown_error = strerror(error);
            return NULL;
        }
    }
    return NULL;
}

bool tarantool_initialize(struct tarantool_configuration* configuration, struct tarantool_box* box)
{
    if (storage.initialized)
    {
        return true;
    }

    if (dlopen(configuration->library_path, RTLD_NOW | RTLD_GLOBAL) == NULL)
    {
        storage.initialization_error = dlerror();
        return false;
    }

    storage.configuration = *configuration;
    storage.initialization_error = "";
    storage.box = box;

    struct tarantool_initialization_args* args = malloc(sizeof(struct tarantool_initialization_args));
    if (args == NULL)
    {
        storage.initialization_error = strerror(ENOMEM);
        return false;
    }

    args->binary_path = configuration->binary_path;
    args->script = configuration->initial_script;

    struct timespec timeout;
    timespec_get(&timeout, TIME_UTC);
    timeout.tv_sec += configuration->initialization_timeout_seconds;
    int error;
    if (error = pthread_create(&storage.main_thread_id, NULL, tarantool_process_initialization, args))
    {
        storage.initialization_error = strerror(error);
        return false;
    }
    if (error = pthread_mutex_lock(&storage.initialization_mutex))
    {
        storage.initialization_error = strerror(error);
        return false;
    }
    while (!storage.initialized)
    {
        if (error = pthread_cond_timedwait(&storage.initialization_condition, &storage.initialization_mutex, &timeout))
        {
            storage.initialization_error = strerror(error);
            return false;
        }
    }
    if (error = pthread_mutex_unlock(&storage.initialization_mutex))
    {
        storage.initialization_error = strerror(error);
        return false;
    }
    if (error = pthread_cond_destroy(&storage.initialization_condition))
    {
        storage.initialization_error = strerror(error);
        return false;
    }
    if (error = pthread_mutex_destroy(&storage.initialization_mutex))
    {
        storage.initialization_error = strerror(error);
        return false;
    }
    return strlen(storage.initialization_error) == 0;
}

bool tarantool_shutdown()
{
    if (!storage.initialized)
    {
        return true;
    }
    tarantool_executor_stop();
    int error;
    if (error = pthread_mutex_lock(&storage.shutdown_mutex))
    {
        storage.shutdown_error = strerror(error);
        return false;
    }
    struct timespec timeout;
    timespec_get(&timeout, TIME_UTC);
    timeout.tv_sec += storage.configuration.shutdown_timeout_seconds;
    while (storage.initialized)
    {
        if (error = pthread_cond_timedwait(&storage.shutdown_condition, &storage.shutdown_mutex, &timeout))
        {
            storage.shutdown_error = strerror(error);
            return false;
        }
    }
    if (error = pthread_mutex_unlock(&storage.shutdown_mutex))
    {
        storage.shutdown_error = strerror(error);
        return false;
    }
    if (error = pthread_cond_destroy(&storage.shutdown_condition))
    {
        storage.shutdown_error = strerror(error);
        return false;
    }
    if (error = pthread_mutex_destroy(&storage.shutdown_mutex))
    {
        storage.shutdown_error = strerror(error);
        return false;
    }
    return true;
}

bool tarantool_initialized()
{
    return storage.initialized;
}

const char* tarantool_status()
{
    return box_status();
}

int tarantool_is_read_only()
{
    return box_is_ro() ? 1 : 0;
}

const char* tarantool_initialization_error()
{
    return storage.initialization_error;
}

const char* tarantool_shutdown_error()
{
    return storage.shutdown_error;
}