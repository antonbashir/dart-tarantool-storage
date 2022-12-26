#include "binding_common.h"
#include "ck_pr.h"
static unsigned int current_owner_id = -1;

unsigned int tarantool_generate_owner_id()
{
  ck_pr_inc_uint(&current_owner_id);
  return current_owner_id;
}