#ifndef TARANTOOL_BOX_H_INCLUDED
#define TARANTOOL_BOX_H_INCLUDED

#include <stddef.h>
#include <stdint.h>
#include "interactor_message.h"

#if defined(__cplusplus)
extern "C"
{
#endif
    struct tarantool_box
    {
          void (*tarantool_evaluate_address)(struct interactor_message*);
          void (*tarantool_call_address)(struct interactor_message*);
          void (*tarantool_iterator_next_single_address)(struct interactor_message*);
          void (*tarantool_iterator_next_many_address)(struct interactor_message*);
          void (*tarantool_iterator_destroy_address)(struct interactor_message*);
          void (*tarantool_free_output_buffer_address)(struct interactor_message*);
          void (*tarantool_space_id_by_name_address)(struct interactor_message*);
          void (*tarantool_space_count_address)(struct interactor_message*);
          void (*tarantool_space_length_address)(struct interactor_message*);
          void (*tarantool_space_iterator_address)(struct interactor_message*);
          void (*tarantool_space_insert_single_address)(struct interactor_message*);
          void (*tarantool_space_insert_many_address)(struct interactor_message*);
          void (*tarantool_space_put_single_address)(struct interactor_message*);
          void (*tarantool_space_put_many_address)(struct interactor_message*);
          void (*tarantool_space_delete_single_address)(struct interactor_message*);
          void (*tarantool_space_delete_many_address)(struct interactor_message*);
          void (*tarantool_space_update_single_address)(struct interactor_message*);
          void (*tarantool_space_update_many_address)(struct interactor_message*);
          void (*tarantool_space_get_address)(struct interactor_message*);
          void (*tarantool_space_min_address)(struct interactor_message*);
          void (*tarantool_space_max_address)(struct interactor_message*);
          void (*tarantool_space_truncate_address)(struct interactor_message*);
          void (*tarantool_space_upsert_address)(struct interactor_message*);
          void (*tarantool_index_count_address)(struct interactor_message*);
          void (*tarantool_index_length_address)(struct interactor_message*);
          void (*tarantool_index_iterator_address)(struct interactor_message*);
          void (*tarantool_index_get_address)(struct interactor_message*);
          void (*tarantool_index_max_address)(struct interactor_message*);
          void (*tarantool_index_min_address)(struct interactor_message*);
          void (*tarantool_index_update_single_address)(struct interactor_message*);
          void (*tarantool_index_update_many_address)(struct interactor_message*);
          void (*tarantool_index_select_address)(struct interactor_message*);
          void (*tarantool_index_id_by_name_address)(struct interactor_message*);
    };

    struct tarantool_space_request
    {
        size_t tuple_size;
        const char* tuple;
        uint32_t space_id;
    };

    struct tarantool_space_count_request
    {
        size_t key_size;
        const char* key;
        uint32_t space_id;
        int iterator_type;
    };

    struct tarantool_space_select_request
    {
        size_t key_size;
        const char* key;
        uint32_t space_id;
        uint32_t offset;
        uint32_t limit;
        int iterator_type;
    };

    struct tarantool_space_update_request
    {
        size_t key_size;
        size_t operations_size;
        const char* key;
        const char* operations;
        uint32_t space_id;
    };

    struct tarantool_space_upsert_request
    {
        size_t tuple_size;
        const char* tuple;
        const char* operations;
        size_t operations_size;
        uint32_t space_id;
    };

    struct tarantool_space_iterator_request
    {
        size_t key_size;
        const char* key;
        uint32_t space_id;
        int type;
    };

    struct tarantool_index_request
    {
        size_t tuple_size;
        const char* tuple;
        uint32_t space_id;
        uint32_t index_id;
    };

    struct tarantool_index_count_request
    {
        size_t key_size;
        const char* key;
        uint32_t space_id;
        uint32_t index_id;
        int iterator_type;
    };

    struct tarantool_index_id_request
    {
        const char* name;
        size_t name_length;
        uint32_t space_id;
    };

    struct tarantool_index_update_request
    {
        const char* key;
        size_t key_size;
        const char* operations;
        size_t operations_size;
        uint32_t space_id;
        uint32_t index_id;
    };

    struct tarantool_call_request
    {
        const char* function;
        const char* input;
        size_t input_size;
        uint32_t function_length;
    };

    struct tarantool_evaluate_request
    {
        const char* expression;
        const char* input;
        size_t input_size;
        uint32_t expression_length;
    };

    struct tarantool_index_iterator_request
    {
        const char* key;
        size_t key_size;
        uint32_t space_id;
        uint32_t index_id;
        int type;
    };

    struct tarantool_index_select_request
    {
        const char* key;
        size_t key_size;
        uint32_t space_id;
        uint32_t index_id;
        uint32_t offset;
        uint32_t limit;
        int iterator_type;
    };

    struct tarantool_index_id
    {
        uint32_t space_id;
        uint32_t index_id;
    };

    struct tarantool_native_module_request
    {
        char* module_name;
        size_t module_name_length;
    };

    struct tarantool_native_function_request
    {
        char* module_name;
        char* function_name;
        size_t module_name_length;
    };

    void tarantool_initialize_box(struct tarantool_box* box);
    void tarantool_destroy_box(struct tarantool_box* box);

    void tarantool_evaluate(struct interactor_message* message);
    void tarantool_call(struct interactor_message* message);

    void tarantool_space_iterator(struct interactor_message* message);
    void tarantool_space_count(struct interactor_message* message);
    void tarantool_space_length(struct interactor_message* message);
    void tarantool_space_truncate(struct interactor_message* message);

    void tarantool_space_put_single(struct interactor_message* message);
    void tarantool_space_insert_single(struct interactor_message* message);
    void tarantool_space_update_single(struct interactor_message* message);
    void tarantool_space_delete_single(struct interactor_message* message);
    void tarantool_space_put_many(struct interactor_message* message);
    void tarantool_space_insert_many(struct interactor_message* message);
    void tarantool_space_update_many(struct interactor_message* message);
    void tarantool_space_delete_many(struct interactor_message* message);
    void tarantool_space_upsert(struct interactor_message* message);
    void tarantool_space_get(struct interactor_message* message);
    void tarantool_space_min(struct interactor_message* message);
    void tarantool_space_max(struct interactor_message* message);
    void tarantool_space_select(struct interactor_message* message);
    void tarantool_space_id_by_name(struct interactor_message* message);

    void tarantool_index_iterator(struct interactor_message* message);
    void tarantool_index_count(struct interactor_message* message);
    void tarantool_index_length(struct interactor_message* message);
    void tarantool_index_id_by_name(struct interactor_message* message);

    void tarantool_index_get(struct interactor_message* message);
    void tarantool_index_min(struct interactor_message* message);
    void tarantool_index_max(struct interactor_message* message);
    void tarantool_index_select(struct interactor_message* message);
    void tarantool_index_update_single(struct interactor_message* message);
    void tarantool_index_update_many(struct interactor_message* message);

    void tarantool_iterator_next_single(struct interactor_message* message);
    void tarantool_iterator_next_many(struct interactor_message* message);

    void tarantool_iterator_destroy(struct interactor_message* message);
    void tarantool_free_output_buffer(struct interactor_message* message);
    void tarantool_free_output_port(struct interactor_message* message);
    void tarantool_free_output_tuple(struct interactor_message* message);
#if defined(__cplusplus)
}
#endif

#endif
