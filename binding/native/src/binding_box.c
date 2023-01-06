#include "binding_box.h"
#include "binding_executor.h"
#include <fiber.h>
#include <lua.h>
#include <luajit.h>
#include <lauxlib.h>
#include <cbus.h>
#include "box/txn.h"
#include "box/box.h"
#include "lua/init.h"
#include "main.h"
#include "box/user.h"
#include "box/tuple.h"
#include "box/port.h"
#include "box/lua/call.h"
#include "box/session.h"
#include "small/obuf.h"
#include "small/quota.h"
#include "small/slab_arena.h"
#include "small/slab_cache.h"
#include "small/small.h"

#define TARANTOOL_PRIMARY_INDEX_ID 0
#define TARANTOOL_INDEX_BASE_C 0

static __thread struct obuf output_buffer;

void tarantool_initialize_box(size_t output_buffer_capacity)
{
  obuf_create(&output_buffer, cord_slab_cache(), output_buffer_capacity);
}

static inline tarantool_tuple_t *tarantool_tuple_new(const char *data, size_t size)
{
  tarantool_tuple_t *return_tuple = malloc(sizeof(tarantool_tuple_t));
  if (unlikely(return_tuple == NULL))
  {
    return NULL;
  }
  return_tuple->data = data;
  return_tuple->size = size;
  return return_tuple;
}

static inline tarantool_tuple_t *tarantool_tuple_from_box(box_tuple_t *source)
{
  if (unlikely(source == NULL))
  {
    return NULL;
  }
  size_t size = box_tuple_bsize(source);
  char *data = malloc(size);
  box_tuple_to_buf(source, data, size);
  return tarantool_tuple_new(data, size);
}

static inline tarantool_tuple_t *tarantool_tuple_from_port(struct port_c *source)
{
  int count = port_dump_msgpack((struct port *)source, &output_buffer);
  port_destroy((struct port *)source);
  if (unlikely(count < 0))
  {
    obuf_reset(&output_buffer);
    return NULL;
  }
  size_t result_size = obuf_size(&output_buffer);
  void *result_buffer = malloc(result_size);
  int position = 0;
  int buffer_iov_count = obuf_iovcnt(&output_buffer);
  for (int iov_index = 0; iov_index < buffer_iov_count; iov_index++)
  {
    memcpy(result_buffer + position, output_buffer.iov[iov_index].iov_base, output_buffer.iov[iov_index].iov_len);
    position += output_buffer.iov[iov_index].iov_len;
  }
  obuf_reset(&output_buffer);
  return tarantool_tuple_new(result_buffer, result_size);
}

tarantool_tuple_t *tarantool_evaluate(tarantool_evaluate_request_t *request)
{
  struct port out_port, in_port;
  port_msgpack_create(&in_port, request->input->data, request->input->size);
  box_lua_eval(request->expression, request->expression_length, &in_port, &out_port);
  port_destroy(&in_port);
  uint32_t result_size;
  const char *result = port_get_msgpack(&out_port, &result_size);
  char *result_buffer = malloc((size_t)result_size);
  memcpy(result_buffer, result, result_size);
  tarantool_tuple_t *result_tuple = tarantool_tuple_new(result_buffer, (size_t)result_size);
  port_destroy(&out_port);
  return result_tuple;
}

tarantool_tuple_t *tarantool_call(tarantool_call_request_t *request)
{
  struct port out_port, in_port;
  port_msgpack_create(&in_port, request->input->data, request->input->size);
  box_lua_call(request->function, request->function_length, &in_port, &out_port);
  port_destroy(&in_port);
  uint32_t result_size;
  const char *result = port_get_msgpack(&out_port, &result_size);
  char *result_buffer = malloc((size_t)result_size);
  memcpy(result_buffer, result, result_size);
  tarantool_tuple_t *result_tuple = tarantool_tuple_new(result_buffer, (size_t)result_size);
  port_destroy(&out_port);
  return result_tuple;
}

const char *tarantool_status()
{
  return box_status();
}

int tarantool_is_read_only()
{
  return box_is_ro() ? 1 : 0;
}

int tarantool_begin()
{
  return box_txn_begin();
}

int tarantool_commit()
{
  return box_txn_commit();
}

int tarantool_rollback()
{
  return box_txn_rollback();
}

int tarantool_in_transaction()
{
  return box_txn() ? 1 : 0;
}

intptr_t tarantool_space_iterator(tarantool_space_iterator_request_t *request)
{
  return (intptr_t)box_index_iterator(request->space_id,
                                      TARANTOOL_PRIMARY_INDEX_ID,
                                      request->type,
                                      request->key->data,
                                      request->key->data + request->key->size);
}

uint64_t tarantool_space_count(tarantool_space_count_request_t *request)
{
  return box_index_count(request->space_id,
                         TARANTOOL_PRIMARY_INDEX_ID,
                         request->iterator_type,
                         request->key->data,
                         request->key->data + request->key->size);
}

uint64_t tarantool_space_length(uint32_t id)
{
  return box_index_len(id, TARANTOOL_PRIMARY_INDEX_ID);
}

tarantool_tuple_t *tarantool_space_put(tarantool_space_request_t *request)
{
  box_tuple_t *result;
  if (unlikely(box_replace(request->space_id,
                           request->tuple->data,
                           request->tuple->data + request->tuple->size,
                           &result) < 0))
  {
    return NULL;
  }
  return tarantool_tuple_from_box(result);
}

tarantool_tuple_t *tarantool_space_insert(tarantool_space_request_t *request)
{
  box_tuple_t *result;
  if (unlikely(box_insert(request->space_id,
                          request->tuple->data,
                          request->tuple->data + request->tuple->size,
                          &result) < 0))
  {
    return NULL;
  }
  return tarantool_tuple_from_box(result);
}

tarantool_tuple_t *tarantool_space_update(tarantool_space_update_request_t *request)
{
  box_tuple_t *result;
  if (unlikely(box_update(request->space_id,
                          TARANTOOL_PRIMARY_INDEX_ID,
                          request->key->data,
                          request->key->data + request->key->size,
                          request->operations->data,
                          request->operations->data + request->operations->size,
                          TARANTOOL_INDEX_BASE_C,
                          &result) < 0))
  {
    return NULL;
  }
  return tarantool_tuple_from_box(result);
}

tarantool_tuple_t *tarantool_space_upsert(tarantool_space_upsert_request_t *request)
{
  box_tuple_t *result;
  if (unlikely(box_upsert(request->space_id,
                          TARANTOOL_PRIMARY_INDEX_ID,
                          request->tuple->data,
                          request->tuple->data + request->tuple->size,
                          request->operations->data,
                          request->operations->data + request->operations->size,
                          TARANTOOL_INDEX_BASE_C,
                          &result) < 0))
  {
    return NULL;
  }
  return tarantool_tuple_from_box(result);
}

tarantool_tuple_t *tarantool_space_get(tarantool_space_request_t *request)
{
  box_tuple_t *result;
  if (unlikely(box_index_get(request->space_id,
                             TARANTOOL_PRIMARY_INDEX_ID,
                             request->tuple->data,
                             request->tuple->data + request->tuple->size,
                             &result) < 0))
  {
    return NULL;
  }
  return tarantool_tuple_from_box(result);
}

tarantool_tuple_t *tarantool_space_min(tarantool_space_request_t *request)
{
  box_tuple_t *result;
  if (unlikely(box_index_min(request->space_id,
                             TARANTOOL_PRIMARY_INDEX_ID,
                             request->tuple->data,
                             request->tuple->data + request->tuple->size,
                             &result) < 0))
  {
    return NULL;
  }
  return tarantool_tuple_from_box(result);
}

tarantool_tuple_t *tarantool_space_max(tarantool_space_request_t *request)
{
  box_tuple_t *result;
  if (unlikely(box_index_max(request->space_id,
                             TARANTOOL_PRIMARY_INDEX_ID,
                             request->tuple->data,
                             request->tuple->data + request->tuple->size,
                             &result) < 0))
  {
    return NULL;
  }
  return tarantool_tuple_from_box(result);
}

tarantool_tuple_t *tarantool_space_select(tarantool_space_select_request_t *request)
{
  struct port port;
  if (unlikely(box_select(request->space_id,
                          TARANTOOL_PRIMARY_INDEX_ID,
                          request->iterator_type,
                          request->offset,
                          request->limit,
                          request->key->data,
                          request->key->data + request->key->size,
                          &port) < 0))
  {
    return NULL;
  }

  return tarantool_tuple_from_port((struct port_c *)&port);
}

tarantool_tuple_t *tarantool_space_delete(tarantool_space_request_t *request)
{
  box_tuple_t *result;
  if (unlikely(box_delete(request->space_id,
                          TARANTOOL_PRIMARY_INDEX_ID,
                          request->tuple->data,
                          request->tuple->data + request->tuple->size,
                          &result) < 0))
  {
    return NULL;
  }
  return tarantool_tuple_from_box(result);
}

void tarantool_space_truncate(uint32_t id)
{
  box_truncate(id);
}

uint32_t tarantool_space_id_by_name(tarantool_space_id_request_t *request)
{
  return box_space_id_by_name(request->name, request->name_length);
}

int tarantool_has_space(tarantool_space_id_request_t *request)
{
  return tarantool_space_id_by_name(request) != BOX_ID_NIL ? 1 : 0;
}

intptr_t tarantool_index_iterator(tarantool_index_iterator_request_t *request)
{
  return (intptr_t)box_index_iterator(request->space_id,
                                      request->index_id,
                                      request->type,
                                      request->key->data, request->key->data + request->key->size);
}

uint64_t tarantool_index_count(tarantool_index_count_request_t *request)
{
  return box_index_count(request->space_id,
                         request->index_id,
                         request->iterator_type,
                         request->key->data,
                         request->key->data + request->key->size);
}

uint64_t tarantool_index_length(tarantool_index_id_t *id)
{
  return box_index_len(id->space_id, id->index_id);
}

uint32_t tarantool_index_id_by_name(tarantool_index_id_request_t *request)
{
  return box_index_id_by_name(request->space_id, request->name, request->name_length);
}

int tarantool_has_index(tarantool_index_id_request_t *request)
{
  return tarantool_index_id_by_name(request) != BOX_ID_NIL ? 1 : 0;
}

tarantool_tuple_t *tarantool_index_get(tarantool_index_request_t *request)
{
  box_tuple_t *result;
  if (unlikely(box_index_get(request->space_id,
                             request->index_id,
                             request->tuple->data,
                             request->tuple->data + request->tuple->size,
                             &result) < 0))
  {
    return NULL;
  }
  return tarantool_tuple_from_box(result);
}

tarantool_tuple_t *tarantool_index_min(tarantool_index_request_t *request)
{
  box_tuple_t *result;
  if (unlikely(box_index_min(request->space_id,
                             request->index_id,
                             request->tuple->data,
                             request->tuple->data + request->tuple->size,
                             &result) < 0))
  {
    return NULL;
  }
  return tarantool_tuple_from_box(result);
}

tarantool_tuple_t *tarantool_index_max(tarantool_index_request_t *request)
{
  box_tuple_t *result;
  if (unlikely(box_index_max(request->space_id,
                             request->index_id,
                             request->tuple->data,
                             request->tuple->data + request->tuple->size,
                             &result) < 0))
  {
    return NULL;
  }
  return tarantool_tuple_from_box(result);
}

tarantool_tuple_t *tarantool_index_select(tarantool_index_select_request_t *request)
{
  struct port port;
  if (unlikely(box_select(request->space_id,
                          request->index_id,
                          request->iterator_type,
                          request->offset,
                          request->limit,
                          request->key->data,
                          request->key->data + request->key->size,
                          &port) < 0))
  {
    return NULL;
  }

  return tarantool_tuple_from_port((struct port_c *)&port);
}

tarantool_tuple_t *tarantool_index_update(tarantool_index_update_request_t *request)
{
  box_tuple_t *result;
  if (unlikely(box_update(request->space_id,
                          request->index_id,
                          request->key->data,
                          request->key->data + request->key->size,
                          request->operations->data,
                          request->operations->data + request->operations->size,
                          TARANTOOL_INDEX_BASE_C,
                          &result) < 0))
  {
    return NULL;
  }
  return tarantool_tuple_from_box(result);
}

tarantool_tuple_t *tarantool_iterator_next(intptr_t iterator)
{
  box_tuple_t *result;
  if (unlikely(box_iterator_next((box_iterator_t *)iterator, &result) < 0))
  {
    return NULL;
  }
  return tarantool_tuple_from_box(result);
}

void tarantool_iterator_destroy(intptr_t iterator)
{
  box_iterator_free((box_iterator_t *)iterator);
}

void tarantool_destroy_box()
{
  obuf_destroy(&output_buffer);
}

void tarantool_tuple_free(tarantool_tuple_t *tuple)
{
  free((void *)tuple->data);
  free(tuple);
}