#include "tarantool_box.h"
#include <lauxlib.h>
#include <lua.h>
#include "box/box.h"
#include "box/lua/call.h"
#include "box/port.h"
#include "box/session.h"
#include "box/tuple.h"
#include "box/txn.h"
#include "fiber.h"
#include "mempool.h"
#include "msgpuck.h"
#include "port.h"
#include "say.h"
#include "small.h"
#include "small/obuf.h"

#define TARANTOOL_PRIMARY_INDEX_ID 0
#define TARANTOOL_INDEX_BASE_C 0

static struct small_alloc tarantool_box_output_buffers;
static struct mempool tarantool_tuple_ports;

void tarantool_initialize_box(struct tarantool_box* box)
{
    float actual_alloc_factor;
    small_alloc_create(&tarantool_box_output_buffers, cord_slab_cache(), 3 * sizeof(int), sizeof(intptr_t), 1.05, &actual_alloc_factor);
    mempool_create(&tarantool_tuple_ports, cord_slab_cache(), sizeof(struct port));
    box->tarantool_evaluate_address = &tarantool_evaluate;
    box->tarantool_call_address = &tarantool_call;
    box->tarantool_iterator_next_single_address = &tarantool_iterator_next_single;
    box->tarantool_iterator_next_many_address = &tarantool_iterator_next_many;
    box->tarantool_iterator_destroy_address = &tarantool_iterator_destroy;
    box->tarantool_free_output_buffer_address = &tarantool_free_output_buffer;
    box->tarantool_space_id_by_name_address = &tarantool_space_id_by_name;
    box->tarantool_space_count_address = &tarantool_space_count;
    box->tarantool_space_length_address = &tarantool_space_length;
    box->tarantool_space_iterator_address = &tarantool_space_iterator;
    box->tarantool_space_insert_single_address = &tarantool_space_insert_single;
    box->tarantool_space_insert_many_address = &tarantool_space_insert_many;
    box->tarantool_space_put_single_address = &tarantool_space_put_single;
    box->tarantool_space_put_many_address = &tarantool_space_put_many;
    box->tarantool_space_delete_single_address = &tarantool_space_delete_single;
    box->tarantool_space_delete_many_address = &tarantool_space_delete_many;
    box->tarantool_space_update_single_address = &tarantool_space_update_single;
    box->tarantool_space_update_many_address = &tarantool_space_update_many;
    box->tarantool_space_get_address = &tarantool_space_get;
    box->tarantool_space_min_address = &tarantool_space_min;
    box->tarantool_space_max_address = &tarantool_space_max;
    box->tarantool_space_truncate_address = &tarantool_space_truncate;
    box->tarantool_space_upsert_address = &tarantool_space_upsert;
    box->tarantool_index_count_address = &tarantool_index_count;
    box->tarantool_index_length_address = &tarantool_index_length;
    box->tarantool_index_iterator_address = &tarantool_index_iterator;
    box->tarantool_index_get_address = &tarantool_index_get;
    box->tarantool_index_max_address = &tarantool_index_max;
    box->tarantool_index_min_address = &tarantool_index_min;
    box->tarantool_index_update_single_address = &tarantool_index_update_single;
    box->tarantool_index_update_many_address = &tarantool_index_update_many;
    box->tarantool_index_select_address = &tarantool_index_select;
    box->tarantool_index_id_by_name_address = &tarantool_index_id_by_name;
}

void tarantool_evaluate(struct interactor_message* message)
{
    struct tarantool_evaluate_request* request = (struct tarantool_evaluate_request*)message->input;
    struct port out_port, in_port;
    struct obuf out_buffer;
    obuf_create(&out_buffer, cord_slab_cache(), 1);
    port_msgpack_create(&in_port, request->input, request->input_size);
    box_lua_eval(request->expression, request->expression_length, &in_port, &out_port);
    port_destroy(&in_port);
    size_t return_count = ((struct port_lua*)&out_port)->size;
    port_dump_msgpack(&out_port, &out_buffer);
    port_destroy(&out_port);
    size_t size = obuf_size(&out_buffer) + mp_sizeof_array(return_count);
    char* output = smalloc(&tarantool_box_output_buffers, size);
    char* result = mp_encode_array(output, return_count);
    for (size_t i = 0; i < out_buffer.n_iov; i++)
    {
        struct iovec* vec = &out_buffer.iov[i];
        memcpy(result, vec->iov_base, vec->iov_len);
        result += vec->iov_len;
    }
    message->output = output;
    message->output_size = size;
}

void tarantool_call(struct interactor_message* message)
{
    struct tarantool_call_request* request = (struct tarantool_call_request*)message->input;
    struct port out_port, in_port;
    struct obuf out_buffer;
    obuf_create(&out_buffer, cord_slab_cache(), 1);
    port_msgpack_create(&in_port, request->input, request->input_size);
    say_info("port_msgpack_create(&in_port, request->input, request->input_size);");
    box_lua_call(request->function, request->function_length, &in_port, &out_port);
    say_info("box_lua_call(request->function, request->function_length, &in_port, &out_port);");
    port_destroy(&in_port);
    size_t return_count = ((struct port_lua*)&out_port)->size;
    port_dump_msgpack(&out_port, &out_buffer);
    port_destroy(&out_port);
    size_t size = obuf_size(&out_buffer) + mp_sizeof_array(return_count);
    char* output = smalloc(&tarantool_box_output_buffers, size);
    char* result = mp_encode_array(output, return_count);
    for (size_t i = 0; i < out_buffer.n_iov; i++)
    {
        struct iovec* vec = &out_buffer.iov[i];
        memcpy(result, vec->iov_base, vec->iov_len);
        result += vec->iov_len;
    }
    message->output = output;
    message->output_size = size;
}

void tarantool_space_iterator(struct interactor_message* message)
{
    struct tarantool_space_iterator_request* request = (struct tarantool_space_iterator_request*)message->input;
    message->output = (void*)box_index_iterator(request->space_id,
                                                TARANTOOL_PRIMARY_INDEX_ID,
                                                request->type,
                                                request->key,
                                                request->key + request->key_size);
}

void tarantool_space_count(struct interactor_message* message)
{
    struct tarantool_space_count_request* request = (struct tarantool_space_count_request*)message->input;
    message->output = (void*)box_index_count(request->space_id,
                                             TARANTOOL_PRIMARY_INDEX_ID,
                                             request->iterator_type,
                                             request->key,
                                             request->key + request->key_size);
}

void tarantool_space_length(struct interactor_message* message)
{
    message->output = (void*)box_index_len((uint32_t)(intptr_t)message->input, TARANTOOL_PRIMARY_INDEX_ID);
}

void tarantool_space_put_single(struct interactor_message* message)
{
    struct tarantool_space_request* request = (struct tarantool_space_request*)message->input;
    box_tuple_t* result;
    if (unlikely(box_replace(request->space_id,
                             request->tuple,
                             request->tuple + request->tuple_size,
                             &result) < 0))
    {
        return;
    }
    tuple_ref(result);
    message->output = result;
}

void tarantool_space_insert_single(struct interactor_message* message)
{
    struct tarantool_space_request* request = (struct tarantool_space_request*)message->input;
    box_tuple_t* result;
    if (unlikely(box_insert(request->space_id,
                            request->tuple,
                            request->tuple + request->tuple_size,
                            &result) < 0))
    {
        return;
    }
    tuple_ref(result);
    message->output = result;
}

void tarantool_space_delete_single(struct interactor_message* message)
{
    struct tarantool_space_request* request = (struct tarantool_space_request*)message->input;
    box_tuple_t* result;
    if (unlikely(box_delete(request->space_id,
                            TARANTOOL_PRIMARY_INDEX_ID,
                            request->tuple,
                            request->tuple + request->tuple_size,
                            &result) < 0))
    {
        return;
    }
    tuple_ref(result);
    message->output = result;
}

void tarantool_space_update_single(struct interactor_message* message)
{
    struct tarantool_space_update_request* request = (struct tarantool_space_update_request*)message->input;
    box_tuple_t* result;
    if (unlikely(box_update(request->space_id,
                            TARANTOOL_PRIMARY_INDEX_ID,
                            request->key,
                            request->key + request->key_size,
                            request->operations,
                            request->operations + request->operations_size,
                            TARANTOOL_INDEX_BASE_C,
                            &result) < 0))
    {
        return;
    }
    tuple_ref(result);
    message->output = result;
}

void tarantool_space_put_many(struct interactor_message* message)
{
    struct tarantool_space_request* request = (struct tarantool_space_request*)message->input;
    struct port* port = mempool_alloc(&tarantool_tuple_ports);
    port_c_create(port);
    const char* batch = request->tuple;
    uint32_t count = mp_decode_array(&batch);
    const char* tuple_next = batch;
    const char* tuple_data = tuple_next;
    const char* tuple_next_size = tuple_next;
    struct txn* transaction = txn_begin();
    while (count-- > 0)
    {
        tuple_data = tuple_next;
        uint32_t tuple_size = mp_decode_array(&tuple_next_size);
        box_tuple_t* tuple;
        if (unlikely(box_replace(request->space_id,
                                 tuple_data,
                                 tuple_data + tuple_size,
                                 &tuple) < 0))
        {
            port_destroy(port);
            txn_rollback(transaction);
            return;
        }
        tuple_ref(tuple);
        if (unlikely(port_c_add_tuple(port, tuple)))
        {
            port_destroy(port);
            txn_rollback(transaction);
            return;
        }
        mp_next(&tuple_next);
        tuple_next_size = tuple_next;
    }
    if (txn_commit(transaction))
    {
        port_destroy(port);
        return;
    }
    message->output = port;
}

void tarantool_space_insert_many(struct interactor_message* message)
{
    struct tarantool_space_request* request = (struct tarantool_space_request*)message->input;
    struct port* port = mempool_alloc(&tarantool_tuple_ports);
    port_c_create(port);
    const char* batch = request->tuple;
    uint32_t count = mp_decode_array(&batch);
    const char* tuple_next = batch;
    const char* tuple_data = tuple_next;
    const char* tuple_next_size = tuple_next;
    struct txn* transaction = txn_begin();
    while (count-- > 0)
    {
        tuple_data = tuple_next;
        uint32_t tuple_size = mp_decode_array(&tuple_next_size);
        box_tuple_t* tuple;
        if (unlikely(box_insert(request->space_id,
                                tuple_data,
                                tuple_data + tuple_size,
                                &tuple) < 0))
        {
            port_destroy(port);
            txn_rollback(transaction);
            return;
        }
        tuple_ref(tuple);
        if (unlikely(port_c_add_tuple(port, tuple)))
        {
            port_destroy(port);
            txn_rollback(transaction);
            return;
        }
        mp_next(&tuple_next);
        tuple_next_size = tuple_next;
    }
    if (txn_commit(transaction))
    {
        port_destroy(port);
        return;
    }
    message->output = port;
}

void tarantool_space_update_many(struct interactor_message* message)
{
    struct tarantool_space_update_request* request = (struct tarantool_space_update_request*)message->input;
    struct port* port = mempool_alloc(&tarantool_tuple_ports);
    port_c_create(port);

    const char* key_batch = request->key;
    uint32_t count = mp_decode_array(&key_batch);
    const char* key_next = key_batch;
    const char* key_data = key_next;
    const char* key_next_size = key_next;

    const char* operation_batch = request->operations;
    uint32_t operations_count = mp_decode_array(&operation_batch);
    const char* operation_next = operation_batch;
    const char* operation_data = operation_next;
    const char* operation_next_size = operation_next;

    struct txn* transaction = txn_begin();
    while (count-- > 0)
    {
        key_data = key_next;
        operation_data = operation_next;
        uint32_t key_size = mp_decode_array(&key_next_size);
        uint32_t operation_size = mp_decode_array(&operation_next_size);
        box_tuple_t* tuple;
        if (unlikely(box_update(request->space_id,
                                TARANTOOL_PRIMARY_INDEX_ID,
                                key_data,
                                key_data + key_size,
                                operation_data,
                                operation_data + operation_size,
                                TARANTOOL_INDEX_BASE_C,
                                &tuple) < 0))
        {
            port_destroy(port);
            txn_rollback(transaction);
            return;
        }
        tuple_ref(tuple);
        if (unlikely(port_c_add_tuple(port, tuple)))
        {
            port_destroy(port);
            txn_rollback(transaction);
            return;
        }
        mp_next(&key_next);
        key_next_size = key_next;
        mp_next(&operation_next);
        operation_next_size = operation_next;
    }
    if (txn_commit(transaction))
    {
        port_destroy(port);
        return;
    }
    message->output = port;
}

void tarantool_space_delete_many(struct interactor_message* message)
{
    struct tarantool_space_request* request = (struct tarantool_space_request*)message->input;
    struct port* port = mempool_alloc(&tarantool_tuple_ports);
    port_c_create(port);
    const char* batch = request->tuple;
    uint32_t count = mp_decode_array(&batch);
    const char* tuple_next = batch;
    const char* tuple_data = tuple_next;
    const char* tuple_next_size = tuple_next;
    struct txn* transaction = txn_begin();
    while (count-- > 0)
    {
        tuple_data = tuple_next;
        uint32_t tuple_size = mp_decode_array(&tuple_next_size);
        box_tuple_t* tuple;
        if (unlikely(box_delete(request->space_id,
                                TARANTOOL_PRIMARY_INDEX_ID,
                                tuple_data,
                                tuple_data + tuple_size,
                                &tuple) < 0))
        {
            port_destroy(port);
            txn_rollback(transaction);
            return;
        }
        tuple_ref(tuple);
        if (unlikely(port_c_add_tuple(port, tuple)))
        {
            port_destroy(port);
            txn_rollback(transaction);
            return;
        }
        mp_next(&tuple_next);
        tuple_next_size = tuple_next;
    }
    if (txn_commit(transaction))
    {
        port_destroy(port);
        return;
    }
    message->output = port;
}

void tarantool_space_upsert(struct interactor_message* message)
{
    struct tarantool_space_upsert_request* request = (struct tarantool_space_upsert_request*)message->input;
    box_tuple_t* result;
    if (unlikely(box_upsert(request->space_id,
                            TARANTOOL_PRIMARY_INDEX_ID,
                            request->tuple,
                            request->tuple + request->tuple_size,
                            request->operations,
                            request->operations + request->operations_size,
                            TARANTOOL_INDEX_BASE_C,
                            &result) < 0))
    {
        return;
    }
    tuple_ref(result);
    message->output = result;
}

void tarantool_space_get(struct interactor_message* message)
{
    struct tarantool_space_request* request = (struct tarantool_space_request*)message->input;
    box_tuple_t* result;
    if (unlikely(box_index_get(request->space_id,
                               TARANTOOL_PRIMARY_INDEX_ID,
                               request->tuple,
                               request->tuple + request->tuple_size,
                               &result) < 0))
    {
        return;
    }
    tuple_ref(result);
    message->output = result;
}

void tarantool_space_min(struct interactor_message* message)
{
    struct tarantool_space_request* request = (struct tarantool_space_request*)message->input;
    box_tuple_t* result;
    if (unlikely(box_index_min(request->space_id,
                               TARANTOOL_PRIMARY_INDEX_ID,
                               request->tuple,
                               request->tuple + request->tuple_size,
                               &result) < 0))
    {
        return;
    }
    tuple_ref(result);
    message->output = result;
}

void tarantool_space_max(struct interactor_message* message)
{
    struct tarantool_space_request* request = (struct tarantool_space_request*)message->input;
    box_tuple_t* result;
    if (unlikely(box_index_max(request->space_id,
                               TARANTOOL_PRIMARY_INDEX_ID,
                               request->tuple,
                               request->tuple + request->tuple_size,
                               &result) < 0))
    {
        return;
    }
    tuple_ref(result);
    message->output = result;
}

void tarantool_space_select(struct interactor_message* message)
{
    struct tarantool_space_select_request* request = (struct tarantool_space_select_request*)message->input;
    struct port* port = mempool_alloc(&tarantool_tuple_ports);
    if (unlikely(box_select(request->space_id,
                            TARANTOOL_PRIMARY_INDEX_ID,
                            request->iterator_type,
                            request->offset,
                            request->limit,
                            request->key,
                            request->key + request->key_size,
                            NULL, NULL, false,
                            port) < 0))
    {
        return;
    }

    message->output = port;
}

void tarantool_space_truncate(struct interactor_message* message)
{
    box_truncate((uint32_t)(intptr_t)message->input);
}

void tarantool_space_id_by_name(struct interactor_message* message)
{
    message->output = (void*)(intptr_t)box_space_id_by_name(message->input, message->input_size);
}

void tarantool_index_iterator(struct interactor_message* message)
{
    struct tarantool_index_iterator_request* request = (struct tarantool_index_iterator_request*)message->input;
    message->output = (void*)box_index_iterator(request->space_id,
                                                request->index_id,
                                                request->type,
                                                request->key, request->key + request->key_size);
}

void tarantool_index_count(struct interactor_message* message)
{
    struct tarantool_index_count_request* request = (struct tarantool_index_count_request*)message->input;
    message->output = (void*)box_index_count(request->space_id,
                                             request->index_id,
                                             request->iterator_type,
                                             request->key,
                                             request->key + request->key_size);
}

void tarantool_index_length(struct interactor_message* message)
{
    struct tarantool_index_id* id = (struct tarantool_index_id*)message->input;
    message->output = (void*)box_index_len(id->space_id, id->index_id);
}

void tarantool_index_id_by_name(struct interactor_message* message)
{
    struct tarantool_index_id_request* request = (struct tarantool_index_id_request*)message->input;
    message->output = (void*)(intptr_t)box_index_id_by_name(request->space_id, request->name, request->name_length);
}

void tarantool_index_get(struct interactor_message* message)
{
    struct tarantool_index_request* request = (struct tarantool_index_request*)message->input;
    box_tuple_t* result;
    if (unlikely(box_index_get(request->space_id,
                               request->index_id,
                               request->tuple,
                               request->tuple + request->tuple_size,
                               &result) < 0))
    {
        return;
    }
    tuple_ref(result);
    message->output = result;
}

void tarantool_index_min(struct interactor_message* message)
{
    struct tarantool_index_request* request = (struct tarantool_index_request*)message->input;
    box_tuple_t* result;
    if (unlikely(box_index_min(request->space_id,
                               request->index_id,
                               request->tuple,
                               request->tuple + request->tuple_size,
                               &result) < 0))
    {
        return;
    }
    tuple_ref(result);
    message->output = result;
}

void tarantool_index_max(struct interactor_message* message)
{
    struct tarantool_index_request* request = (struct tarantool_index_request*)message->input;
    box_tuple_t* result;
    if (unlikely(box_index_max(request->space_id,
                               request->index_id,
                               request->tuple,
                               request->tuple + request->tuple_size,
                               &result) < 0))
    {
        return;
    }
    tuple_ref(result);
    message->output = result;
}

void tarantool_index_select(struct interactor_message* message)
{
    struct tarantool_index_select_request* request = (struct tarantool_index_select_request*)message->input;
    struct port* port = mempool_alloc(&tarantool_tuple_ports);
    if (unlikely(box_select(request->space_id,
                            request->index_id,
                            request->iterator_type,
                            request->offset,
                            request->limit,
                            request->key,
                            request->key + request->key_size,
                            NULL, NULL, false,
                            port) < 0))
    {
        return;
    }
    message->output = port;
}

void tarantool_index_update_single(struct interactor_message* message)
{
    struct tarantool_index_update_request* request = (struct tarantool_index_update_request*)message->input;
    box_tuple_t* result;
    if (unlikely(box_update(request->space_id,
                            request->index_id,
                            request->key,
                            request->key + request->key_size,
                            request->operations,
                            request->operations + request->operations_size,
                            TARANTOOL_INDEX_BASE_C,
                            &result) < 0))
    {
        return;
    }
    tuple_ref(result);
    message->output = result;
}

void tarantool_iterator_next_single(struct interactor_message* message)
{
    box_tuple_t* tuple;
    if (unlikely(box_iterator_next((box_iterator_t*)message->input, &tuple) < 0 || !tuple))
    {
        return;
    }
    tuple_ref(tuple);
    message->output = tuple;
}

void tarantool_index_update_many(struct interactor_message* message)
{
    struct tarantool_index_update_request* request = (struct tarantool_index_update_request*)message->input;
    struct port* port = mempool_alloc(&tarantool_tuple_ports);
    port_c_create(port);

    const char* key_batch = request->key;
    uint32_t count = mp_decode_array(&key_batch);
    const char* key_next = key_batch;
    const char* key_data = key_next;
    const char* key_next_size = key_next;

    const char* operation_batch = request->operations;
    uint32_t operations_count = mp_decode_array(&operation_batch);
    const char* operation_next = operation_batch;
    const char* operation_data = operation_next;
    const char* operation_next_size = operation_next;

    struct txn* transaction = txn_begin();
    while (count-- > 0)
    {
        key_data = key_next;
        operation_data = operation_next;
        uint32_t key_size = mp_decode_array(&key_next_size);
        uint32_t operation_size = mp_decode_array(&operation_next_size);
        box_tuple_t* tuple;
        if (unlikely(box_update(request->space_id,
                                request->index_id,
                                key_data,
                                key_data + key_size,
                                operation_data,
                                operation_data + operation_size,
                                TARANTOOL_INDEX_BASE_C,
                                &tuple) < 0))
        {
            port_destroy(port);
            txn_rollback(transaction);
            return;
        }
        tuple_ref(tuple);
        if (unlikely(port_c_add_tuple(port, tuple)))
        {
            port_destroy(port);
            txn_rollback(transaction);
            return;
        }
        mp_next(&key_next);
        key_next_size = key_next;
        mp_next(&operation_next);
        operation_next_size = operation_next;
    }
    if (txn_commit(transaction))
    {
        port_destroy(port);
        return;
    }
    message->output = port;
}

void tarantool_iterator_next_many(struct interactor_message* message)
{
    struct port* port = mempool_alloc(&tarantool_tuple_ports);
    port_c_create(port);
    uint32_t found = 0;
    while (found < message->input_size)
    {
        box_tuple_t* tuple;
        if (unlikely(box_iterator_next((box_iterator_t*)message->input, &tuple) < 0 || !tuple))
        {
            port_destroy(port);
            return;
        }
        if (unlikely(port_c_add_tuple(port, tuple)))
        {
            port_destroy(port);
            return;
        }
        found++;
    }
    message->output = port;
}

void tarantool_iterator_destroy(struct interactor_message* message)
{
    box_iterator_free((box_iterator_t*)message->input);
}

void tarantool_free_output_buffer(struct interactor_message* message)
{
    smfree(&tarantool_box_output_buffers, message->input, message->input_size);
}

void tarantool_free_output_port(struct interactor_message* message)
{
    port_destroy(message->input);
    mempool_free(&tarantool_tuple_ports, message->input);
}

void tarantool_free_output_tuple(struct interactor_message* message)
{
    tuple_unref(message->input);
}

void tarantool_destroy_box(struct tarantool_box* box)
{
    (void)box;
    small_alloc_destroy(&tarantool_box_output_buffers);
    mempool_destroy(&tarantool_tuple_ports);
}
