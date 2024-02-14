#include "tarantool_factory.h"
#include <asm-generic/errno-base.h>
#include <interactor_memory.h>
#include "interactor_message.h"
#include "mempool.h"
#include "small.h"
#include "tarantool_box.h"

int tarantool_factory_initialize(struct tarantool_factory* factory, tarantool_factory_interactor_memory* memory)
{
    float actual_alloc_factor;
    
    factory->tarantool_datas = calloc(1, sizeof(struct small_alloc));
    if (!factory->tarantool_datas)
    {
        return -ENOMEM;
    }
    small_alloc_create(factory->tarantool_datas, &memory->cache, 3 * sizeof(int), sizeof(intptr_t), 1.05, &actual_alloc_factor);
    
    factory->tarantool_messages = calloc(1, sizeof(struct mempool));
    if (!factory->tarantool_messages)
    {
        return -ENOMEM;
    }
    mempool_create(factory->tarantool_messages, &memory->cache, sizeof(struct interactor_message));
    
    factory->tarantool_call_requests = calloc(1, sizeof(struct mempool));
    if (!factory->tarantool_call_requests)
    {
        return -ENOMEM;
    }
    mempool_create(factory->tarantool_call_requests, &memory->cache, sizeof(struct tarantool_call_request));
    
    factory->tarantool_evaluate_requests = calloc(1, sizeof(struct mempool));
    if (!factory->tarantool_evaluate_requests)
    {
        return -ENOMEM;
    }
    mempool_create(factory->tarantool_evaluate_requests, &memory->cache, sizeof(struct tarantool_evaluate_request));
    
    factory->tarantool_space_requests = calloc(1, sizeof(struct mempool));
    if (!factory->tarantool_space_requests)
    {
        return -ENOMEM;
    }
    mempool_create(factory->tarantool_space_requests, &memory->cache, sizeof(struct tarantool_space_request));
    
    factory->tarantool_space_count_requests = calloc(1, sizeof(struct mempool));
    if (!factory->tarantool_space_count_requests)
    {
        return -ENOMEM;
    }
    mempool_create(factory->tarantool_space_count_requests, &memory->cache, sizeof(struct tarantool_space_count_request));
    
    factory->tarantool_space_select_requests = calloc(1, sizeof(struct mempool));
    if (!factory->tarantool_space_select_requests)
    {
        return -ENOMEM;
    }
    mempool_create(factory->tarantool_space_select_requests, &memory->cache, sizeof(struct tarantool_space_select_request));
    
    factory->tarantool_space_update_requests = calloc(1, sizeof(struct mempool));
    if (!factory->tarantool_space_update_requests)
    {
        return -ENOMEM;
    }
    mempool_create(factory->tarantool_space_update_requests, &memory->cache, sizeof(struct tarantool_space_update_request));
    
    factory->tarantool_space_upsert_requests = calloc(1, sizeof(struct mempool));
    if (!factory->tarantool_space_upsert_requests)
    {
        return -ENOMEM;
    }
    mempool_create(factory->tarantool_space_upsert_requests, &memory->cache, sizeof(struct tarantool_space_upsert_request));
    
    factory->tarantool_space_iterator_requests = calloc(1, sizeof(struct mempool));
    if (!factory->tarantool_space_iterator_requests)
    {
        return -ENOMEM;
    }
    mempool_create(factory->tarantool_space_iterator_requests, &memory->cache, sizeof(struct tarantool_space_iterator_request));

    factory->tarantool_index_requests = calloc(1, sizeof(struct mempool));
    if (!factory->tarantool_index_requests)
    {
        return -ENOMEM;
    }
    mempool_create(factory->tarantool_index_requests, &memory->cache, sizeof(struct tarantool_index_request));

    factory->tarantool_index_count_requests = calloc(1, sizeof(struct mempool));
    if (!factory->tarantool_index_count_requests)
    {
        return -ENOMEM;
    }
    mempool_create(factory->tarantool_index_count_requests, &memory->cache, sizeof(struct tarantool_index_count_request));

    factory->tarantool_index_id_requests = calloc(1, sizeof(struct mempool));
    if (!factory->tarantool_index_id_requests)
    {
        return -ENOMEM;
    }
    mempool_create(factory->tarantool_index_id_requests, &memory->cache, sizeof(struct tarantool_index_id_request));

    factory->tarantool_index_update_requests = calloc(1, sizeof(struct mempool));
    if (!factory->tarantool_index_update_requests)
    {
        return -ENOMEM;
    }
    mempool_create(factory->tarantool_index_update_requests, &memory->cache, sizeof(struct tarantool_index_update_request));

    factory->tarantool_index_iterator_requests = calloc(1, sizeof(struct mempool));
    if (!factory->tarantool_index_iterator_requests)
    {
        return -ENOMEM;
    }
    mempool_create(factory->tarantool_index_iterator_requests, &memory->cache, sizeof(struct tarantool_index_iterator_request));

    factory->tarantool_index_select_requests = calloc(1, sizeof(struct mempool));
    if (!factory->tarantool_index_select_requests)
    {
        return -ENOMEM;
    }
    mempool_create(factory->tarantool_index_select_requests, &memory->cache, sizeof(struct tarantool_index_select_request));

    factory->tarantool_index_index_ids = calloc(1, sizeof(struct mempool));
    if (!factory->tarantool_index_index_ids)
    {
        return -ENOMEM;
    }
    mempool_create(factory->tarantool_index_index_ids, &memory->cache, sizeof(struct tarantool_index_id));

    return 0;
}

const char* tarantool_create_string(struct tarantool_factory* factory, size_t size)
{
    return smalloc(factory->tarantool_datas, size);
}

void tarantool_free_string(struct tarantool_factory* factory, const char* string, size_t size)
{
    smfree(factory->tarantool_datas, (void*)string, size);
}

struct interactor_message* tarantool_space_request_prepare(struct tarantool_factory* factory, uint32_t space_id, const char* tuple, size_t tuple_size)
{
    struct tarantool_space_request* request = mempool_alloc(factory->tarantool_space_requests);
    request->space_id = space_id;
    request->tuple = tuple;
    request->tuple_size = tuple_size;
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = request;
    return message;
}

void tarantool_space_request_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_space_requests, message->input);
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_space_count_request_prepare(struct tarantool_factory* factory, uint32_t space_id, int iterator_type, const char* key, size_t key_size)
{
    struct tarantool_space_count_request* request = mempool_alloc(factory->tarantool_space_count_requests);
    request->space_id = space_id;
    request->iterator_type = iterator_type;
    request->key = key;
    request->key_size = key_size;
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = request;
    return message;
}

void tarantool_space_count_request_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_space_count_requests, message->input);
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_space_select_request_prepare(struct tarantool_factory* factory, uint32_t space_id, const char* key, size_t key_size, uint32_t offset, uint32_t limit, int iterator_type)
{
    struct tarantool_space_select_request* request = mempool_alloc(factory->tarantool_space_select_requests);
    request->space_id = space_id;
    request->key = key;
    request->key_size = key_size;
    request->offset = offset;
    request->limit = limit;
    request->iterator_type = iterator_type;
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = request;
    return message;
}

void tarantool_space_select_request_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_space_select_requests, message->input);
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_space_update_request_prepare(struct tarantool_factory* factory, uint32_t space_id, const char* key, size_t key_size, const char* operations, size_t operations_size)
{
    struct tarantool_space_update_request* request = mempool_alloc(factory->tarantool_space_update_requests);
    request->space_id = space_id;
    request->key = key;
    request->key_size = key_size;
    request->operations = operations;
    request->operations_size = operations_size;
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = request;
    return message;
}

void tarantool_space_update_request_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_space_update_requests, message->input);
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_space_upsert_request_prepare(struct tarantool_factory* factory, uint32_t space_id, const char* tuple, size_t tuple_size, const char* operations, size_t operations_size)
{
    struct tarantool_space_upsert_request* request = mempool_alloc(factory->tarantool_space_upsert_requests);
    request->space_id = space_id;
    request->tuple = tuple;
    request->tuple_size = tuple_size;
    request->operations = operations;
    request->operations_size = operations_size;
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = request;
    return message;
}

void tarantool_space_upsert_request_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_space_upsert_requests, message->input);
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_space_iterator_request_prepare(struct tarantool_factory* factory, uint32_t space_id, int type, const char* key, size_t key_size)
{
    struct tarantool_space_iterator_request* request = mempool_alloc(factory->tarantool_space_iterator_requests);
    request->space_id = space_id;
    request->type = type;
    request->key = key;
    request->key_size = key_size;
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = request;
    return message;
}

void tarantool_space_iterator_request_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_space_iterator_requests, message->input);
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_index_request_prepare(struct tarantool_factory* factory, uint32_t space_id, uint32_t index_id, const char* tuple, size_t tuple_size)
{
    struct tarantool_index_request* request = mempool_alloc(factory->tarantool_index_requests);
    request->space_id = space_id;
    request->index_id = index_id;
    request->tuple = tuple;
    request->tuple_size = tuple_size;
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = request;
    return message;
}

void tarantool_index_request_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_index_requests, message->input);
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_index_count_request_prepare(struct tarantool_factory* factory, uint32_t space_id, uint32_t index_id, const char* key, size_t key_size, int iterator_type)
{
    struct tarantool_index_count_request* request = mempool_alloc(factory->tarantool_index_count_requests);
    request->space_id = space_id;
    request->index_id = index_id;
    request->key = key;
    request->key_size = key_size;
    request->iterator_type = iterator_type;
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = request;
    return message;
}

void tarantool_index_count_request_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_index_count_requests, message->input);
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_index_id_request_prepare(struct tarantool_factory* factory, uint32_t space_id, const char* name, size_t name_length)
{
    struct tarantool_index_id_request* request = mempool_alloc(factory->tarantool_index_id_requests);
    request->space_id = space_id;
    request->name = name;
    request->name_length = name_length;
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = request;
    return message;
}

void tarantool_index_id_request_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_index_id_requests, message->input);
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_index_update_request_prepare(struct tarantool_factory* factory, uint32_t space_id, uint32_t index_id, const char* key, size_t key_size, const char* operations, size_t operations_size)
{
    struct tarantool_index_update_request* request = mempool_alloc(factory->tarantool_index_update_requests);
    request->space_id = space_id;
    request->index_id = index_id;
    request->key = key;
    request->key_size = key_size;
    request->operations = operations;
    request->operations_size = operations_size;
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = request;
    return message;
}

void tarantool_index_update_request_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_index_update_requests, message->input);
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_call_request_prepare(struct tarantool_factory* factory, const char* function, size_t function_length, const char* input, size_t input_size)
{
    struct tarantool_call_request* request = mempool_alloc(factory->tarantool_call_requests);
    request->function = function;
    request->function_length = function_length;
    request->input = input;
    request->input_size = input_size;
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = request;
    return message;
}

void tarantool_call_request_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_call_requests, message->input);
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_evaluate_request_prepare(struct tarantool_factory* factory, const char* script, size_t script_length, const char* input, size_t input_size)
{
    struct tarantool_evaluate_request* request = mempool_alloc(factory->tarantool_evaluate_requests);
    request->expression = script;
    request->expression_length = script_length;
    request->input = input;
    request->input_size = input_size;
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = request;
    return message;
}

void tarantool_evaluate_request_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_evaluate_requests, message->input);
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_index_iterator_request_prepare(struct tarantool_factory* factory, uint32_t space_id, uint32_t index_id, int type, const char* key, size_t key_size)
{
    struct tarantool_index_iterator_request* request = mempool_alloc(factory->tarantool_index_iterator_requests);
    request->space_id = space_id;
    request->index_id = index_id;
    request->type = type;
    request->key = key;
    request->key_size = key_size;
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = request;
    return message;
}

void tarantool_index_iterator_request_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_index_id_requests, message->input);
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_index_select_request_prepare(struct tarantool_factory* factory, uint32_t space_id, uint32_t index_id, const char* key, size_t key_size, uint32_t offset, uint32_t limit, int iterator_type)
{
    struct tarantool_index_select_request* request = mempool_alloc(factory->tarantool_index_select_requests);
    request->space_id = space_id;
    request->index_id = index_id;
    request->key = key;
    request->key_size = key_size;
    request->offset = offset;
    request->limit = limit;
    request->iterator_type = iterator_type;
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = request;
    return message;
}

void tarantool_index_select_request_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_index_select_requests, message->input);
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_index_id_prepare(struct tarantool_factory* factory, uint32_t space_id, uint32_t index_id)
{
    struct tarantool_index_id* id = mempool_alloc(factory->tarantool_index_index_ids);
    id->space_id = space_id;
    id->index_id = index_id;
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = id;
    return message;
}

void tarantool_index_id_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_index_index_ids, message->input);
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_space_id_by_name_prepare(struct tarantool_factory* factory, const char* name, size_t name_length)
{
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = (void*)name;
    message->input_size = name_length;
    return message;
}

void tarantool_space_id_by_name_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_space_length_prepare(struct tarantool_factory* factory, uint32_t space_id)
{
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = (void*)(uintptr_t)space_id;
    return message;
}

void tarantool_space_length_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_space_truncate_prepare(struct tarantool_factory* factory, uint32_t space_id)
{
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = (void*)(uintptr_t)space_id;
    return message;
}

void tarantool_space_truncate_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_iterator_next_prepare(struct tarantool_factory* factory, intptr_t iterator, uint32_t count)
{
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = (void*)iterator;
    message->input_size = count;
    return message;
}

void tarantool_iterator_next_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_iterator_destroy_prepare(struct tarantool_factory* factory, intptr_t iterator)
{
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = (void*)iterator;
    return message;
}

void tarantool_iterator_destroy_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_free_output_buffer_prepare(struct tarantool_factory* factory, void* buffer, size_t buffer_size)
{
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = buffer;
    message->input_size = buffer_size;
    return message;
}

void tarantool_free_output_buffer_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_free_output_port_prepare(struct tarantool_factory* factory, tarantool_tuple_port_t* port)
{
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = (void*)port;
    return message;
}

void tarantool_free_output_port_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_messages, message);
}

struct interactor_message* tarantool_free_output_tuple_prepare(struct tarantool_factory* factory, tarantool_tuple_t* tuple)
{
    struct interactor_message* message = mempool_alloc(factory->tarantool_messages);
    message->input = (void*)tuple;
    return message;
}

void tarantool_free_output_tuple_free(struct tarantool_factory* factory, struct interactor_message* message)
{
    mempool_free(factory->tarantool_messages, message);
}

void tarantool_factory_destroy(struct tarantool_factory* factory)
{
    small_alloc_destroy(factory->tarantool_datas);
    mempool_destroy(factory->tarantool_messages);
    mempool_destroy(factory->tarantool_call_requests);
    mempool_destroy(factory->tarantool_evaluate_requests);
    mempool_destroy(factory->tarantool_space_requests);
    mempool_destroy(factory->tarantool_space_count_requests);
    mempool_destroy(factory->tarantool_space_select_requests);
    mempool_destroy(factory->tarantool_space_update_requests);
    mempool_destroy(factory->tarantool_space_upsert_requests);
    mempool_destroy(factory->tarantool_space_iterator_requests);
    mempool_destroy(factory->tarantool_index_requests);
    mempool_destroy(factory->tarantool_index_count_requests);
    mempool_destroy(factory->tarantool_index_id_requests);
    mempool_destroy(factory->tarantool_index_update_requests);
    mempool_destroy(factory->tarantool_index_iterator_requests);
    mempool_destroy(factory->tarantool_index_select_requests);
    mempool_destroy(factory->tarantool_index_index_ids);
    free(factory->tarantool_datas);
    free(factory->tarantool_messages);
    free(factory->tarantool_call_requests);
    free(factory->tarantool_evaluate_requests);
    free(factory->tarantool_space_requests);
    free(factory->tarantool_space_count_requests);
    free(factory->tarantool_space_select_requests);
    free(factory->tarantool_space_update_requests);
    free(factory->tarantool_space_upsert_requests);
    free(factory->tarantool_space_iterator_requests);
    free(factory->tarantool_index_requests);
    free(factory->tarantool_index_count_requests);
    free(factory->tarantool_index_id_requests);
    free(factory->tarantool_index_update_requests);
    free(factory->tarantool_index_iterator_requests);
    free(factory->tarantool_index_select_requests);
    free(factory->tarantool_index_index_ids);
}