#include "tarantool_tuple.h"
#include "box/port.h"
#include "box/tuple.h"

tarantool_tuple_port_entry_t* tarantool_port_first(tarantool_tuple_port_t* port)
{
    return (tarantool_tuple_port_entry_t*)&((struct port_c*)port)->first_entry;
}

tarantool_tuple_port_entry_t* tarantool_port_entry_next(tarantool_tuple_port_entry_t* current)
{
    return (tarantool_tuple_port_entry_t*)current->next;
}

tarantool_tuple_t* tarantool_port_entry_tuple(tarantool_tuple_port_entry_t* current)
{
    return (tarantool_tuple_t*)current->tuple;
}

size_t tarantool_tuple_size(tarantool_tuple_t* tuple)
{
    return tuple_size(tuple);
}

void* tarantool_tuple_data(tarantool_tuple_t* tuple)
{
  return (void*)tuple_data(tuple);
}