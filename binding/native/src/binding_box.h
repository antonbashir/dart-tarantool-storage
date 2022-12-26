#ifndef BINDING_BOX_H_INCLUDED
#define BINDING_BOX_H_INCLUDED
#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>
#include "binding_common.h"
#include "binding_controller.h"
#include "binding_executor.h"
#include "binding_dart_functions.h"

#if defined(__cplusplus)
extern "C"
{
#endif
	typedef struct tarantool_space_id_request_t
	{
		char *name;
		size_t name_length;
	} tarantool_space_id_request_t;

	typedef struct tarantool_space_request_t
	{
		uint32_t space_id;
		tarantool_tuple_t *tuple;
	} tarantool_space_request_t;

	typedef struct tarantool_space_count_request_t
	{
		uint32_t space_id;
		int iterator_type;
		tarantool_tuple_t *key;
	} tarantool_space_count_request_t;

	typedef struct tarantool_space_select_request_t
	{
		uint32_t space_id;
		tarantool_tuple_t *key;
		uint32_t offset;
		uint32_t limit;
		int iterator_type;
	} tarantool_space_select_request_t;

	typedef struct tarantool_space_update_request_t
	{
		uint32_t space_id;
		tarantool_tuple_t *key;
		tarantool_tuple_t *operations;
	} tarantool_space_update_request_t;

	typedef struct tarantool_space_upsert_request_t
	{
		uint32_t space_id;
		tarantool_tuple_t *tuple;
		tarantool_tuple_t *operations;
	} tarantool_space_upsert_request_t;

	typedef struct tarantool_space_iterator_request_t
	{
		uint32_t space_id;
		int type;
		tarantool_tuple_t *key;
	} tarantool_space_iterator_request_t;

	typedef struct tarantool_index_request_t
	{
		uint32_t space_id;
		uint32_t index_id;
		tarantool_tuple_t *tuple;
	} tarantool_index_request_t;

	typedef struct tarantool_index_count_request_t
	{
		uint32_t space_id;
		uint32_t index_id;
		tarantool_tuple_t *key;
		int iterator_type;
	} tarantool_index_count_request_t;

	typedef struct tarantool_index_id_request_t
	{
		uint32_t space_id;
		char *name;
		size_t name_length;
	} tarantool_index_id_request_t;

	typedef struct tarantool_index_update_request_t
	{
		uint32_t space_id;
		uint32_t index_id;
		tarantool_tuple_t *key;
		tarantool_tuple_t *operations;
	} tarantool_index_update_request_t;

	typedef struct tarantool_call_request_t
	{
		char *function;
		uint32_t function_length;
		tarantool_tuple_t *input;
	} tarantool_call_request_t;

	typedef struct tarantool_index_iterator_request_t
	{
		uint32_t space_id;
		uint32_t index_id;
		int type;
		tarantool_tuple_t *key;
	} tarantool_index_iterator_request_t;

	typedef struct tarantool_index_select_request_t
	{
		uint32_t space_id;
		uint32_t index_id;
		tarantool_tuple_t *key;
		uint32_t offset;
		uint32_t limit;
		int iterator_type;
	} tarantool_index_select_request_t;

	typedef struct tarantool_index_id_t
	{
		uint32_t space_id;
		uint32_t index_id;
	} tarantool_index_id_t;

	void tarantool_initialize_box(size_t output_buffer_capacity);
	void tarantool_destroy_box();

	int tarantool_evaluate(const char *script);
	tarantool_tuple_t *tarantool_call(tarantool_call_request_t *request);

	const char *tarantool_status();
	bool tarantool_is_read_only();

	int tarantool_begin();
	int tarantool_commit();
	int tarantool_rollback();
	bool tarantool_in_transaction();

	intptr_t tarantool_space_iterator(tarantool_space_iterator_request_t *request);
	uint64_t tarantool_space_count(tarantool_space_count_request_t *request);
	uint64_t tarantool_space_length(uint32_t id);
	void tarantool_space_truncate(uint32_t id);

	tarantool_tuple_t *tarantool_space_put(tarantool_space_request_t *request);
	tarantool_tuple_t *tarantool_space_insert(tarantool_space_request_t *request);
	tarantool_tuple_t *tarantool_space_update(tarantool_space_update_request_t *request);
	tarantool_tuple_t *tarantool_space_upsert(tarantool_space_upsert_request_t *request);
	tarantool_tuple_t *tarantool_space_get(tarantool_space_request_t *request);
	tarantool_tuple_t *tarantool_space_min(tarantool_space_request_t *request);
	tarantool_tuple_t *tarantool_space_max(tarantool_space_request_t *request);
	tarantool_tuple_t *tarantool_space_select(tarantool_space_select_request_t *request);
	tarantool_tuple_t *tarantool_space_delete(tarantool_space_request_t *request);
	uint32_t tarantool_space_id_by_name(tarantool_space_id_request_t *request);

	intptr_t tarantool_index_iterator(tarantool_index_iterator_request_t *request);
	uint64_t tarantool_index_count(tarantool_index_count_request_t *request);
	uint64_t tarantool_index_length(tarantool_index_id_t *id);
	uint32_t tarantool_index_id_by_name(tarantool_index_id_request_t *request);

	tarantool_tuple_t *tarantool_index_get(tarantool_index_request_t *request);
	tarantool_tuple_t *tarantool_index_min(tarantool_index_request_t *request);
	tarantool_tuple_t *tarantool_index_max(tarantool_index_request_t *request);
	tarantool_tuple_t *tarantool_index_select(tarantool_index_select_request_t *request);
	tarantool_tuple_t *tarantool_index_update(tarantool_index_update_request_t *request);

	tarantool_tuple_t *tarantool_iterator_next(intptr_t iterator);
	void tarantool_iterator_destroy(intptr_t iterator);
#if defined(__cplusplus)
}
#endif

#endif
