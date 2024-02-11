#ifndef TARANTOOL_EXECUTOR_H_INCLUDED
#define TARANTOOL_EXECUTOR_H_INCLUDED

#include <stdbool.h>
#include "interactor_native.h"

#if defined(__cplusplus)
extern "C"
{
#endif
    struct tarantool_executor_configuration
    {
        size_t executor_ring_size;
        struct interactor_native_configuration interactor_configuration;
        uint32_t interactor_id;
    };

    int tarantool_executor_initialize(struct tarantool_executor_configuration* configuration);
    void tarantool_executor_start(struct tarantool_executor_configuration* configuration);
    void tarantool_executor_stop();
    void tarantool_executor_destroy();
    int tarantool_executor_descriptor();
#if defined(__cplusplus)
}
#endif

#endif
