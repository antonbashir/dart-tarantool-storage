#ifndef BINDING_EXECUTOR_H_INCLUDED
#define BINDING_EXECUTOR_H_INCLUDED
#include "binding_common.h"

#if defined(__cplusplus)
extern "C"
{
#endif
	typedef struct tarantool_message_loop_configuration
	{
		double message_loop_max_sleep_seconds;
		double message_loop_regular_sleep_seconds;
		int message_loop_max_empty_cycles;
		int message_loop_empty_cycles_multiplier;
		int message_loop_initial_empty_cycles;
		size_t message_loop_ring_size;
		size_t message_loop_ring_retry_max_count;
	} tarantool_message_loop_configuration_t;

	void tarantool_message_loop_initialize(tarantool_message_loop_configuration_t *configuration);
	void tarantool_message_loop_start(tarantool_message_loop_configuration_t *configuration);
	void tarantool_message_loop_stop();
	bool tarantool_message_loop_active();
	bool tarantool_send_message(tarantool_message_t *message, Dart_Handle callback);
#if defined(__cplusplus)
}
#endif

#endif
