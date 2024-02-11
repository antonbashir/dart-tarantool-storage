#ifndef TARANTOOL_COMMON_H_INCLUDED
#define TARANTOOL_COMMON_H_INCLUDED

#if defined(__cplusplus)
extern "C"
{
#endif
    typedef void* (*tarantool_function)(void*);
    typedef void (*tarantool_consumer)(void*);
    typedef void* tarantool_function_argument;
#if defined(__cplusplus)
}
#endif

#endif
