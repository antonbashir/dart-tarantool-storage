#include "tarantool_launcher.h"
#include <getopt.h>
#include <grp.h>
#include <libgen.h>
#include <locale.h>
#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sysexits.h>
#include <unistd.h>
#include "trivia/config.h"
#if TARGET_OS_LINUX && defined(HAVE_PRCTL_H)
#include <sys/prctl.h>
#endif
#include <crc32.h>
#include <readline/readline.h>
#include <rmean.h>
#include <say.h>
#include "backtrace.h"
#include "box/box.h"
#include "box/error.h"
#include "box/flightrec.h"
#include "box/lua/init.h"
#include "box/memtx_tx.h"
#include "box/module_cache.h"
#include "box/watcher.h"
#include "cbus.h"
#include "cfg.h"
#include "coio_task.h"
#include "coll/coll.h"
#include "core/crash.h"
#include "core/errinj.h"
#include "core/event.h"
#include "core/popen.h"
#include "core/ssl.h"
#include "fiber.h"
#include "lua/init.h"
#include "lua/utils.h"
#include "memory.h"
#include "on_shutdown.h"
#include "random.h"
#include "small/small_features.h"
#include "ssl_cert_paths_discover.h"
#include "title.h"
#include "trivia/util.h"
#include "tt_pthread.h"
#include "version.h"

struct ev_loop;
struct ev_signal;
typedef void (*sigint_cb_t)(struct ev_loop* loop, struct ev_signal* w, int revents);
static pid_t master_pid = getpid();
static char** main_argv;
static int main_argc;
static ev_signal ev_sigs[5];
static const int ev_sig_count = sizeof(ev_sigs) / sizeof(*ev_sigs);
static double start_time;
static struct fiber* on_shutdown_fiber = NULL;
static bool shutdown_started = false;
static bool shutdown_finished = false;
static int exit_code = 0;
char tarantool_path[PATH_MAX];
long tarantool_start_time;

static void tarantool_exit(int code)
{
    start_loop = false;
    if (shutdown_started)
    {
        return;
    }
    shutdown_started = true;
    exit_code = code;
    box_broadcast_fmt("box.shutdown", "%b", true);
    fiber_wakeup(on_shutdown_fiber);
}

static void signal_cb(ev_loop* loop, struct ev_signal* w, int revents)
{
    (void)loop;
    (void)w;
    (void)revents;

    say_warn("got signal %d - %s", w->signum, strsignal(w->signum));
    tarantool_exit(0);
}
static sigint_cb_t signal_sigint_cb = signal_cb;

static void signal_sigwinch_cb(ev_loop* loop, struct ev_signal* w, int revents)
{
    (void)loop;
    (void)w;
    (void)revents;
    if (rl_instream)
    {
        rl_resize_terminal();
    }
}

static void signal_free(void)
{
    int i;
    for (i = 0; i < ev_sig_count; i++)
        ev_signal_stop(loop(), &ev_sigs[i]);
}

static void signal_reset(void)
{
    for (int i = 0; i < ev_sig_count; i++)
        ev_signal_stop(loop(), &ev_sigs[i]);

    struct sigaction sa;

    memset(&sa, 0, sizeof(sa));
    sigemptyset(&sa.sa_mask);
    sa.sa_handler = SIG_DFL;

    if (sigaction(SIGUSR1, &sa, NULL) == -1 ||
        sigaction(SIGINT, &sa, NULL) == -1 ||
        sigaction(SIGTERM, &sa, NULL) == -1 ||
        sigaction(SIGHUP, &sa, NULL) == -1 ||
        sigaction(SIGWINCH, &sa, NULL) == -1)
        say_syserror("sigaction");

    fiber_signal_reset();
    crash_signal_reset();

    sigset_t sigset;
    sigfillset(&sigset);
    if (pthread_sigmask(SIG_UNBLOCK, &sigset, NULL) == -1)
        say_syserror("pthread_sigmask");
}

static int sig_checkpoint_f(va_list ap)
{
    (void)ap;
    if (box_checkpoint() != 0)
        diag_log();
    return 0;
}

static void sig_checkpoint(ev_loop* loop, struct ev_signal* w, int revents)
{
    (void)loop;
    (void)w;
    (void)revents;

    struct fiber* f = fiber_new_system("checkpoint", sig_checkpoint_f);
    if (f == NULL)
    {
        say_warn("failed to allocate checkpoint fiber");
        return;
    }

    fiber_wakeup(f);
}

static void signal_init(void)
{
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));

    sa.sa_handler = SIG_IGN;
    sigemptyset(&sa.sa_mask);

    if (sigaction(SIGPIPE, &sa, 0) == -1)
        panic_syserror("sigaction");

    fiber_signal_init();
    crash_signal_init();

    ev_signal_init(&ev_sigs[0], sig_checkpoint, SIGUSR1);
    ev_signal_init(&ev_sigs[1], signal_sigint_cb, SIGINT);
    ev_signal_init(&ev_sigs[2], signal_cb, SIGTERM);
    ev_signal_init(&ev_sigs[3], signal_sigwinch_cb, SIGWINCH);
    ev_signal_init(&ev_sigs[4], say_logrotate, SIGHUP);
    for (int i = 0; i < ev_sig_count; i++)
        ev_signal_start(loop(), &ev_sigs[i]);

    tt_pthread_atfork(NULL, NULL, signal_reset);
}

static void free_readline_state(void)
{
    if (isatty(STDIN_FILENO))
    {
        rl_cleanup_after_signal();
    }
}

static void tarantool_atexit(void)
{
    if (getpid() != master_pid)
        return;

    if (!cord_is_main())
        return;

    free_readline_state();
}

static void tarantool_free(void)
{
    if (getpid() != master_pid)
        return;

    if (!cord_is_main())
        return;

    coio_shutdown();

    box_lua_free();
    box_free();

    title_free(main_argc, main_argv);

    popen_free();
    module_free();

    signal_free();
#ifdef ENABLE_GCOV
    gcov_flush();
#endif
    cbus_free();
    event_free();
    ssl_free();
    memtx_tx_manager_free();
    coll_free();
    say_logger_free();
    fiber_free();
    memory_free();
    random_free();
}

static int on_shutdown_f(va_list ap)
{
    (void)ap;

    if (ev_depth(loop()) == 0)
        fiber_sleep(0.0);

    while (!shutdown_started)
        fiber_yield();

    if (on_shutdown_run_triggers() != 0)
    {
        say_error("on_shutdown triggers failed");
        diag_log();
        diag_clear(diag_get());
    }

    box_shutdown();
    shutdown_finished = true;
    ev_break(loop(), EVBREAK_ALL);
    return 0;
}

extern "C" double tarantool_uptime(void)
{
    return ev_monotonic_now(loop()) - start_time;
}

extern "C" void load_cfg(void)
{
    const char* work_dir = cfg_gets("work_dir");
    if (work_dir != NULL && chdir(work_dir) == -1)
        panic_syserror("can't chdir to `%s'", work_dir);

    if (cfg_geti("coredump"))
    {
        struct rlimit c = {0, 0};
        if (getrlimit(RLIMIT_CORE, &c) < 0)
        {
            say_syserror("getrlimit");
            exit(EX_OSERR);
        }
        c.rlim_cur = c.rlim_max;
        if (setrlimit(RLIMIT_CORE, &c) < 0)
        {
            say_syserror("setrlimit");
            exit(EX_OSERR);
        }
#if TARGET_OS_LINUX && defined(HAVE_PRCTL_H)
        if (prctl(PR_SET_DUMPABLE, 1, 0, 0, 0) < 0)
        {
            say_syserror("prctl");
            exit(EX_OSERR);
        }
#endif
    }

    if (cfg_geti("strip_core"))
    {
        if (!small_test_feature(SMALL_FEATURE_DONTDUMP))
        {
            static const char strip_msg[] = "'strip_core' is set but unsupported";
#if TARGET_OS_LINUX
            say_warn(strip_msg);
#else
            say_verbose(strip_msg);
#endif
        }
    }

    const char* log = cfg_gets("log");

    if (box_init_say() != 0)
    {
        diag_log();
        exit(EXIT_FAILURE);
    }

    if (box_set_flightrec() != 0)
    {
        diag_log();
        exit(EXIT_FAILURE);
    }

    say_info("%s %s %s", tarantool_package(), tarantool_version(), BUILD_INFO);
    int log_level = say_get_log_level();
    say_info("log level %d (%s)", log_level, say_log_level_str(log_level));

    box_cfg();
}

extern "C" sigint_cb_t set_sigint_cb(sigint_cb_t new_sigint_cb)
{
    sigint_cb_t old_cb = signal_sigint_cb;
    ev_set_cb(&ev_sigs[1], new_sigint_cb);
    return old_cb;
}

void tarantool_launcher_launch(char* binary_path)
{
    if (setlocale(LC_CTYPE, "C.UTF-8") == NULL &&
        setlocale(LC_CTYPE, "en_US.UTF-8") == NULL &&
        setlocale(LC_CTYPE, "en_US.utf8") == NULL)
        fprintf(stderr, "Failed to set locale to C.UTF-8\n");
    fpconv_check();

    char** argv = new char*[1];
    argv[0] = (char*)binary_path;
    const char* tarantool_bin = find_path(binary_path);
    if (!tarantool_bin)
        tarantool_bin = binary_path;

    random_init();
    crc32_init();
    memory_init();

    main_argc = 1;
    main_argv = argv;

    fiber_init(fiber_cxx_invoke);
    popen_init();
    coio_init();
    coio_enable();
    signal_init();
    cbus_init();
    coll_init();
    memtx_tx_manager_init();
    module_init();
	  ssl_init();
	  event_init();

    const int override_cert_paths_env_vars = 0;
    if (tnt_ssl_cert_paths_discover(override_cert_paths_env_vars) != 0)
        say_warn("No enough memory for setup ssl certificates paths");

#ifndef NDEBUG
    errinj_set_with_environment_vars();
#endif
    tarantool_lua_init_deferred(tarantool_bin, main_argc, main_argv);

    start_time = ev_monotonic_time();

    try
    {
        box_init();
        box_lua_init(tarantool_L);
        tarantool_lua_postinit(tarantool_L);

        on_shutdown_fiber = fiber_new_system("on_shutdown", on_shutdown_f);

        if (on_shutdown_fiber == NULL)
            diag_raise();

        atexit(tarantool_atexit);

        if (!loop())
            panic("%s", "can't init event loop");

        delete[] argv;
    }
    catch (struct error* e)
    {
        error_log(e);
        panic("%s", "fatal error, exiting the event loop");
    }
    catch (...)
    {
        panic("unknown exception");
    }
}

void tarantool_launcher_shutdown(int code)
{
    if (start_loop)
    {
        say_crit("exiting the event loop");
    }
    if (!shutdown_started)
    {
        tarantool_exit(code);
    }
    tarantool_free();
}
