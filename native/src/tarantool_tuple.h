#ifndef TARANTOOL_TUPLE_H_INCLUDED
#define TARANTOOL_TUPLE_H_INCLUDED

#include <stddef.h>

typedef struct tuple tarantool_tuple_t;
typedef struct port tarantool_tuple_port_t;
typedef struct tuple_iterator tarantool_tuple_iterator_t;
typedef struct port_c_entry tarantool_tuple_port_entry_t;

#if defined(__cplusplus)
extern "C"
{
#endif
    tarantool_tuple_port_entry_t* tarantool_port_first(tarantool_tuple_port_t* port);
    tarantool_tuple_port_entry_t* tarantool_port_entry_next(tarantool_tuple_port_entry_t* current);
    tarantool_tuple_t* tarantool_port_entry_tuple(tarantool_tuple_port_entry_t* current);
    size_t tarantool_tuple_size(tarantool_tuple_t* tuple);
    void* tarantool_tuple_data(tarantool_tuple_t* tuple);
#if defined(__cplusplus)
}
#endif

#endif