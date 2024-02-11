#ifndef TARANTOOL_H_INCLUDED
#define TARANTOOL_H_INCLUDED

#include <stdbool.h>
#include <stddef.h>
#include "tarantool_box.h"

#if defined(__cplusplus)
extern "C"
{
#endif
    struct tarantool_configuration
    {
        const char* library_path;
        const char* binary_path;
        const char* initial_script;
        struct interactor_native_configuration* interactor_configuration;
        uint64_t initialization_timeout_seconds;
        uint64_t shutdown_timeout_seconds;
        size_t box_output_buffer_capacity;
        size_t executor_ring_size;
    };

    bool tarantool_initialize(struct tarantool_configuration* configuration, struct tarantool_box* box);
    bool tarantool_initialized();
    const char* tarantool_status();
    int tarantool_is_read_only();
    const char* tarantool_initialization_error();
    const char* tarantool_shutdown_error();
    bool tarantool_shutdown();
#if defined(__cplusplus)
}
#endif

#endif
