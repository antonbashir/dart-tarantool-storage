#ifndef TARANTOOL_FACTORY_H_INCLUDED
#define TARANTOOL_FACTORY_H_INCLUDED

#include "interactor_message.h"
#include "tarantool_tuple.h"

typedef struct mempool tarantool_factory_mempool; 
typedef struct small_alloc tarantool_factory_small_alloc; 
typedef struct interactor_memory tarantool_factory_interactor_memory; 

#if defined(__cplusplus)
extern "C"
{
#endif
    struct tarantool_factory
    {
        tarantool_factory_small_alloc* tarantool_datas;
        tarantool_factory_mempool* tarantool_messages;
        tarantool_factory_mempool* tarantool_call_requests;
        tarantool_factory_mempool* tarantool_evaluate_requests;
        tarantool_factory_mempool* tarantool_space_requests;
        tarantool_factory_mempool* tarantool_space_count_requests;
        tarantool_factory_mempool* tarantool_space_select_requests;
        tarantool_factory_mempool* tarantool_space_update_requests;
        tarantool_factory_mempool* tarantool_space_upsert_requests;
        tarantool_factory_mempool* tarantool_space_iterator_requests;
        tarantool_factory_mempool* tarantool_index_requests;
        tarantool_factory_mempool* tarantool_index_count_requests;
        tarantool_factory_mempool* tarantool_index_id_requests;
        tarantool_factory_mempool* tarantool_index_update_requests;
        tarantool_factory_mempool* tarantool_index_iterator_requests;
        tarantool_factory_mempool* tarantool_index_select_requests;
        tarantool_factory_mempool* tarantool_index_index_ids;
    };

    int tarantool_factory_initialize(struct tarantool_factory* factory, tarantool_factory_interactor_memory* memory);

    struct interactor_message* tarantool_space_request_prepare(struct tarantool_factory* factory, uint32_t space_id, const char* tuple, size_t tuple_size);
    void tarantool_space_request_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_space_count_request_prepare(struct tarantool_factory* factory, uint32_t space_id, int iterator_type, const char* key, size_t key_size);
    void tarantool_space_count_request_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_space_select_request_prepare(struct tarantool_factory* factory, uint32_t space_id, const char* key, size_t key_size, uint32_t offset, uint32_t limit, int iterator_type);
    void tarantool_space_select_request_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_space_update_request_prepare(struct tarantool_factory* factory, uint32_t space_id, const char* key, size_t key_size, const char* operations, size_t operations_size);
    void tarantool_space_update_request_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_space_upsert_request_prepare(struct tarantool_factory* factory, uint32_t space_id, const char* tuple, size_t tuple_size, const char* operations, size_t operations_size);
    void tarantool_space_upsert_request_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_space_iterator_request_prepare(struct tarantool_factory* factory, uint32_t space_id, int type, const char* key, size_t key_size);
    void tarantool_space_iterator_request_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_index_request_prepare(struct tarantool_factory* factory, uint32_t space_id, uint32_t index_id, const char* tuple, size_t tuple_size);
    void tarantool_index_request_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_index_count_request_prepare(struct tarantool_factory* factory, uint32_t space_id, uint32_t index_id, const char* key, size_t key_size, int iterator_type);
    void tarantool_index_count_request_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_index_id_request_prepare(struct tarantool_factory* factory, uint32_t space_id, const char* name, size_t name_length);
    void tarantool_index_id_request_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_index_update_request_prepare(struct tarantool_factory* factory, uint32_t space_id, uint32_t index_id, const char* key, size_t key_size, const char* operations, size_t operations_size);
    void tarantool_index_update_request_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_call_request_prepare(struct tarantool_factory* factory, const char* function, size_t function_length, const char* input, size_t input_size);
    void tarantool_call_request_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_evaluate_request_prepare(struct tarantool_factory* factory, const char* script, size_t script_length, const char* input, size_t input_size);
    void tarantool_evaluate_request_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_index_iterator_request_prepare(struct tarantool_factory* factory, uint32_t space_id, uint32_t index_id, int type, const char* key, size_t key_size);
    void tarantool_index_iterator_request_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_index_select_request_prepare(struct tarantool_factory* factory, uint32_t space_id, uint32_t index_id, const char* key, size_t key_size, uint32_t offset, uint32_t limit, int iterator_type);
    void tarantool_index_select_request_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_index_id_prepare(struct tarantool_factory* factory, uint32_t space_id, uint32_t index_id);
    void tarantool_index_id_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_space_id_by_name_prepare(struct tarantool_factory* factory, const char* name, size_t name_length);
    void tarantool_space_id_by_name_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_space_length_prepare(struct tarantool_factory* factory, uint32_t space_id);
    void tarantool_space_length_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_space_truncate_prepare(struct tarantool_factory* factory, uint32_t space_id);
    void tarantool_space_truncate_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_iterator_next_prepare(struct tarantool_factory* factory, intptr_t iterator, uint32_t count);
    void tarantool_iterator_next_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_iterator_destroy_prepare(struct tarantool_factory* factory, intptr_t iterator);
    void tarantool_iterator_destroy_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_free_output_buffer_prepare(struct tarantool_factory* factory, void* buffer, size_t buffer_size);
    void tarantool_free_output_buffer_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_free_output_port_prepare(struct tarantool_factory* factory, tarantool_tuple_port_t* port);
    void tarantool_free_output_port_free(struct tarantool_factory* factory, struct interactor_message* message);

    struct interactor_message* tarantool_free_output_tuple_prepare(struct tarantool_factory* factory, tarantool_tuple_t* tuple);
    void tarantool_free_output_tuple_free(struct tarantool_factory* factory, struct interactor_message* message);

    const char* tarantool_create_string(struct tarantool_factory* factory, size_t size);
    void tarantool_free_string(struct tarantool_factory* factory, const char* string, size_t size);

    void tarantool_factory_destroy(struct tarantool_factory* factory);
#if defined(__cplusplus)
}
#endif

#endif