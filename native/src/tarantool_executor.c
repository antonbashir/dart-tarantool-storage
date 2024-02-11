#include "tarantool_executor.h"
#include <liburing.h>
#include <small/small.h>
#include <stdbool.h>
#include <sys/eventfd.h>
#include "fiber.h"
#include "interactor_native.h"

static struct interactor_native* tarantool_interactor;
static int tarantool_eventfd;
static bool active;

int tarantool_executor_initialize(struct tarantool_executor_configuration* configuration)
{
    tarantool_eventfd = eventfd(0, EFD_CLOEXEC | EFD_NONBLOCK);
    tarantool_interactor = calloc(sizeof(struct interactor_native), 1);
    int descriptor;
    if ((descriptor = interactor_native_initialize_default(tarantool_interactor, configuration->interactor_id)) < 0)
    {
        return -descriptor;
    }
    io_uring_register_eventfd(tarantool_interactor->ring, tarantool_eventfd);
    active = true;
    return 0;
}

void tarantool_executor_start(struct tarantool_executor_configuration* configuration)
{
    eventfd_t count;
    struct ev_io io;
    ev_init(&io, (ev_io_cb)fiber_schedule_cb);
    io.data = fiber();
    ev_io_set(&io, tarantool_eventfd, EV_READ);
    ev_set_priority(&io, EV_MAXPRI);
    ev_io_start(loop(), &io);
    while (likely(active))
    {
        io_uring_submit(tarantool_interactor->ring);
        if (likely(io_uring_cq_ready(tarantool_interactor->ring)))
        {
            if (!active) break;
            eventfd_read(tarantool_eventfd, &count);
            interactor_native_process(tarantool_interactor);
            io_uring_submit(tarantool_interactor->ring);
        }
        fiber_yield();
    }
    ev_io_stop(loop(), &io);
    ev_io_set(&io, -1, EV_READ);
    close(tarantool_eventfd);
}

int tarantool_executor_descriptor()
{
    return tarantool_interactor->descriptor;
}

void tarantool_executor_stop()
{
    active = false;
    struct io_uring_sqe* sqe = io_uring_get_sqe(tarantool_interactor->ring);
    while (unlikely(sqe == NULL))
    {
        struct io_uring_cqe* unused;
        io_uring_wait_cqe_nr(tarantool_interactor->ring, &unused, 1);
        sqe = io_uring_get_sqe(tarantool_interactor->ring);
    }
    io_uring_prep_nop(sqe);
    io_uring_submit(tarantool_interactor->ring);
}

void tarantool_executor_destroy()
{
    close(tarantool_eventfd);
    interactor_native_destroy(tarantool_interactor);
}