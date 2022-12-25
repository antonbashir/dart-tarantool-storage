#ifndef BINDING_CONTROLLER_H_INCLUDED
#define BINDING_CONTROLLER_H_INCLUDED
#include <stdbool.h>
#include <stddef.h>

#if defined(__cplusplus)
extern "C"
{
#endif
	typedef struct tarantool_configuration
	{
		size_t box_output_buffer_capacity;
		double message_loop_max_sleep_seconds;
		double message_loop_regular_sleep_seconds;
		int message_loop_max_empty_cycles;
		int message_loop_empty_cycles_multiplier;
		int message_loop_initial_empty_cycles;
		size_t message_loop_ring_size;
	} tarantool_configuration_t;

	void tarantool_initialize(char *binary_path, char *script, tarantool_configuration_t *configuration);
	bool tarantool_initialized();
	void tarantool_shutdown(int code);
#if defined(__cplusplus)
}
#endif

#endif
