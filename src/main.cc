/*
 * Copyright 2010-2016, Tarantool AUTHORS, please see AUTHORS file.
 *
 * Redistribution and use in source and binary forms, with or
 * without modification, are permitted provided that the following
 * conditions are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the
 *    following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY <COPYRIGHT HOLDER> ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * <COPYRIGHT HOLDER> OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
#include "main.h"
#include "trivia/config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <grp.h>
#include <getopt.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <sys/resource.h>
#include <pwd.h>
#include <unistd.h>
#include <getopt.h>
#include <locale.h>
#include <libgen.h>
#include <sysexits.h>
#if defined(TARGET_OS_LINUX) && defined(HAVE_PRCTL_H)
#include <sys/prctl.h>
#endif
#include "fiber.h"
#include "cbus.h"
#include "coio_task.h"
#include <crc32.h>
#include "memory.h"
#include <say.h>
#include <rmean.h>
#include <limits.h>
#include "coll/coll.h"
#include "trivia/util.h"
#include "backtrace.h"
#include "tt_pthread.h"
#include "lua/init.h"
#include "box/box.h"
#include "box/error.h"
#include "small/small_features.h"
#include "scoped_guard.h"
#include "random.h"
#include "cfg.h"
#include "version.h"
#include <readline/readline.h>
#include "title.h"
#include <libutil.h>
#include "box/lua/init.h" /* box_lua_init() */
#include "box/session.h"
#include "box/memtx_tx.h"
#include "box/module_cache.h"
#include "systemd.h"
#include "crypto/crypto.h"
#include "core/popen.h"
#include "core/crash.h"
#include "ssl_cert_paths_discover.h"
#include "core/errinj.h"

static pid_t master_pid = getpid();
static struct pidfh *pid_file_handle;
static char *pid_file = NULL;
static char **main_argv;
static int main_argc;
/** Signals handled after start as part of the event loop. */
static ev_signal ev_sigs[5];
static const int ev_sig_count = sizeof(ev_sigs) / sizeof(*ev_sigs);

static double start_time;

/** A preallocated fiber to run on_shutdown triggers. */
static struct fiber *on_shutdown_fiber = NULL;
/** A flag restricting repeated execution of tarantool_exit(). */
static bool is_shutting_down = false;
static int exit_code = 0;

double
tarantool_uptime(void)
{
	return ev_monotonic_now(loop()) - start_time;
}

/**
 * Create a checkpoint from signal handler (SIGUSR1)
 */
static int
sig_checkpoint_f(va_list ap)
{
	(void)ap;
	if (box_checkpoint() != 0)
		diag_log();
	return 0;
}

static void
sig_checkpoint(ev_loop * /* loop */, struct ev_signal * /* w */,
			   int /* revents */)
{
	struct fiber *f = fiber_new("checkpoint", sig_checkpoint_f);
	if (f == NULL)
	{
		say_warn("failed to allocate checkpoint fiber");
		return;
	}
	fiber_wakeup(f);
}

static int
on_shutdown_f(va_list ap)
{
	(void)ap;
	trigger_fiber_run(&box_on_shutdown_trigger_list, NULL,
					  on_shutdown_trigger_timeout);
	ev_break(loop(), EVBREAK_ALL);
	return 0;
}

void tarantool_exit(int code)
{
	start_loop = false;
	if (is_shutting_down)
	{
		/*
		 * We are already running on_shutdown triggers,
		 * and will exit as soon as they'll finish.
		 * Do not execute them twice.
		 */
		return;
	}
	is_shutting_down = true;
	exit_code = code;
	fiber_call(on_shutdown_fiber);
}

static void
signal_cb(ev_loop *loop, struct ev_signal *w, int revents)
{
	(void)loop;
	(void)w;
	(void)revents;

	/**
	 * If running in daemon mode, complain about possibly
	 * sudden and unexpected death.
	 * Real case: an ops A kills the server and ops B files
	 * a bug that the server suddenly died. Make such case
	 * explicit in the log.
	 */
	if (pid_file)
		say_crit("got signal %d - %s", w->signum, strsignal(w->signum));
	tarantool_exit(0);
}

static void
signal_sigwinch_cb(ev_loop *loop, struct ev_signal *w, int revents)
{
	(void)loop;
	(void)w;
	(void)revents;
	if (rl_instream)
		rl_resize_terminal();
}

static void
signal_free(void)
{
	int i;
	for (i = 0; i < ev_sig_count; i++)
		ev_signal_stop(loop(), &ev_sigs[i]);
}

/** Make sure the child has a default signal disposition. */
static void
signal_reset(void)
{
	for (int i = 0; i < ev_sig_count; i++)
		ev_signal_stop(loop(), &ev_sigs[i]);

	struct sigaction sa;

	/* Reset all signals to their defaults. */
	memset(&sa, 0, sizeof(sa));
	sigemptyset(&sa.sa_mask);
	sa.sa_handler = SIG_DFL;

	if (sigaction(SIGUSR1, &sa, NULL) == -1 ||
		sigaction(SIGINT, &sa, NULL) == -1 ||
		sigaction(SIGTERM, &sa, NULL) == -1 ||
		sigaction(SIGHUP, &sa, NULL) == -1 ||
		sigaction(SIGWINCH, &sa, NULL) == -1)
		say_syserror("sigaction");

	crash_signal_reset();

	/* Unblock any signals blocked by libev. */
	sigset_t sigset;
	sigfillset(&sigset);
	if (sigprocmask(SIG_UNBLOCK, &sigset, NULL) == -1)
		say_syserror("sigprocmask");
}

static void
tarantool_atfork(void)
{
	signal_reset();
	box_atfork();
}

/**
 * Adjust the process signal mask and add handlers for signals.
 */
static void
signal_init(void)
{
	struct sigaction sa;
	memset(&sa, 0, sizeof(sa));

	sa.sa_handler = SIG_IGN;
	sigemptyset(&sa.sa_mask);

	if (sigaction(SIGPIPE, &sa, 0) == -1)
		panic_syserror("sigaction");

	crash_signal_init();

	ev_signal_init(&ev_sigs[0], sig_checkpoint, SIGUSR1);
	ev_signal_init(&ev_sigs[1], signal_cb, SIGINT);
	ev_signal_init(&ev_sigs[2], signal_cb, SIGTERM);
	ev_signal_init(&ev_sigs[3], signal_sigwinch_cb, SIGWINCH);
	ev_signal_init(&ev_sigs[4], say_logrotate, SIGHUP);
	for (int i = 0; i < ev_sig_count; i++)
		ev_signal_start(loop(), &ev_sigs[i]);

	(void)tt_pthread_atfork(NULL, NULL, tarantool_atfork);
}

/** Run in the background. */
static void
daemonize(void)
{
	pid_t pid;
	int fd;

	/* flush buffers to avoid multiple output */
	/* https://github.com/tarantool/tarantool/issues/366 */
	fflush(stdin);
	fflush(stdout);
	fflush(stderr);
	pid = fork();
	switch (pid)
	{
	case -1:
		goto error;
	case 0: /* child */
		master_pid = getpid();
		break;
	default: /* parent */
		/* Tell systemd about new main program using */
		errno = 0;
		master_pid = pid;
		exit(EXIT_SUCCESS);
	}

	if (setsid() == -1)
		goto error;

	/*
	 * tell libev we've just forked, this is necessary to re-initialize
	 * kqueue on FreeBSD.
	 */
	ev_loop_fork(cord()->loop);

	/*
	 * reinit signals after fork, because fork() implicitly calls
	 * signal_reset() via pthread_atfork() hook installed by signal_init().
	 */
	signal_init();

	/* redirect stdin; stdout and stderr handled in say_logger_init */
	fd = open("/dev/null", O_RDONLY);
	if (fd < 0)
		goto error;
	dup2(fd, STDIN_FILENO);
	close(fd);

	return;
error:
	exit(EXIT_FAILURE);
}

void load_cfg(void)
{
	const char *work_dir = cfg_gets("work_dir");
	if (work_dir != NULL && chdir(work_dir) == -1)
		panic_syserror("can't chdir to `%s'", work_dir);

	const char *username = cfg_gets("username");
	if (username != NULL)
	{
		if (getuid() == 0 || geteuid() == 0)
		{
			struct passwd *pw;
			errno = 0;
			if ((pw = getpwnam(username)) == 0)
			{
				if (errno)
				{
					say_syserror("getpwnam: %s",
								 username);
				}
				else
				{
					say_error("User not found: %s",
							  username);
				}
				exit(EX_NOUSER);
			}
			if (setgid(pw->pw_gid) < 0 || setgroups(0, NULL) < 0 ||
				setuid(pw->pw_uid) < 0 || seteuid(pw->pw_uid))
			{
				say_syserror("setgid/setuid");
				exit(EX_OSERR);
			}
		}
		else
		{
			say_error("can't switch to %s: i'm not root",
					  username);
		}
	}

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
#if defined(TARGET_OS_LINUX) && defined(HAVE_PRCTL_H)
		if (prctl(PR_SET_DUMPABLE, 1, 0, 0, 0) < 0)
		{
			say_syserror("prctl");
			exit(EX_OSERR);
		}
#endif
	}

	/*
	 * If we're requested to strip coredump
	 * make sure we can do that, otherwise
	 * require user to not turn it on.
	 */
	if (cfg_geti("strip_core"))
	{
		if (!small_test_feature(SMALL_FEATURE_DONTDUMP))
		{
			static const char strip_msg[] =
				"'strip_core' is set but unsupported";
#ifdef TARGET_OS_LINUX
			/*
			 * Linux is known to support madvise(DONT_DUMP)
			 * feature, thus warn on this platform only. The
			 * rest should be notified on verbose level only
			 * to not spam a user.
			 */
			say_warn(strip_msg);
#else
			say_verbose(strip_msg);
#endif
		}
	}

	int background = cfg_geti("background");
	const char *log = cfg_gets("log");
	const char *log_format = cfg_gets("log_format");
	pid_file = (char *)cfg_gets("pid_file");
	if (pid_file != NULL)
	{
		pid_file = abspath(pid_file);
		if (pid_file == NULL)
			panic("out of memory");
	}

	if (background)
	{
		if (log == NULL)
		{
			say_crit(
				"'background' requires "
				"'log' configuration option to be set");
			exit(EXIT_FAILURE);
		}
		if (pid_file == NULL)
		{
			say_crit(
				"'background' requires "
				"'pid_file' configuration option to be set");
			exit(EXIT_FAILURE);
		}
	}

	/*
	 * pid file check must happen before logger init in order for the
	 * error message to show in stderr
	 */
	if (pid_file != NULL)
	{
		pid_t other_pid = -1;
		pid_file_handle = pidfile_open(pid_file, 0644, &other_pid);
		if (pid_file_handle == NULL)
		{
			if (errno == EEXIST)
			{
				say_crit(
					"the daemon is already running: PID %d",
					(int)other_pid);
			}
			else
			{
				say_syserror(
					"failed to create pid file '%s'",
					pid_file);
			}
			exit(EXIT_FAILURE);
		}
	}

	/*
	 * logger init must happen before daemonising in order for the error
	 * to show and for the process to exit with a failure status
	 */
	say_logger_init(log,
					cfg_geti("log_level"),
					cfg_getb("log_nonblock"),
					log_format,
					background);

	memtx_tx_manager_use_mvcc_engine = cfg_getb("memtx_use_mvcc_engine");

	if (background)
		daemonize();

	/*
	 * after (optional) daemonising to avoid confusing messages with
	 * different pids
	 */
	say_crit("%s %s", tarantool_package(), tarantool_version());
	say_crit("log level %i", cfg_geti("log_level"));

	if (pid_file_handle != NULL)
	{
		if (pidfile_write(pid_file_handle) == -1)
			say_syserror("failed to update pid file '%s'", pid_file);
	}

	title_set_custom(cfg_gets("custom_proc_title"));
	title_update();
	box_cfg();
}

void free_rl_state(void)
{
	/* tarantool_lua_free() was formerly reponsible for terminal reset,
	 * but it is no longer called
	 */
	if (isatty(STDIN_FILENO))
	{
		/*
		 * Restore terminal state. Doesn't hurt if exiting not
		 * due to a signal.
		 */
		rl_cleanup_after_signal();
	}
}

void tarantool_atexit(void)
{
	/* Same checks as in tarantool_free() */
	if (getpid() != master_pid)
		return;

	if (!cord_is_main())
		return;

	free_rl_state();
}

void tarantool_free(void)
{
	/*
	 * Do nothing in a fork.
	 * Note: technically we should do pidfile_close(), however since our
	 * forks do exec immediately we can get away without it, thanks to
	 * the magic O_CLOEXEC
	 */
	if (getpid() != master_pid)
		return;

	/*
	 * It's better to do nothing and keep xlogs opened when
	 * we are called by exit() from a non-main thread.
	 */
	if (!cord_is_main())
		return;

	/* Shutdown worker pool. Waits until threads terminate. */
	coio_shutdown();

	box_free();

	title_free(main_argc, main_argv);

	popen_free();
	module_free();

	/* unlink pidfile. */
	if (pid_file_handle != NULL && pidfile_remove(pid_file_handle) == -1)
		say_syserror("failed to remove pid file '%s'", pid_file);
	free(pid_file);
	signal_free();
#ifdef ENABLE_GCOV
	__gcov_flush();
#endif
	cbus_free();
#if 0
	/*
	 * This doesn't work reliably since things
	 * are too interconnected.
	 */
	tarantool_lua_free();
	session_free();
	user_cache_free();
	fiber_free();
	memory_free();
	random_free();
#endif
	crypto_free();
	memtx_tx_manager_free();
	coll_free();
	systemd_free();
	say_logger_free();
}

extern "C" void **
export_syms(void);

int tarantool_initialize_library(char *binary_path)
{
	if (setlocale(LC_CTYPE, "C.UTF-8") == NULL &&
		setlocale(LC_CTYPE, "en_US.UTF-8") == NULL &&
		setlocale(LC_CTYPE, "en_US.utf8") == NULL)
		fprintf(stderr, "Failed to set locale to C.UTF-8\n");
	fpconv_check();

	char **argv = new char *[1];
	argv[0] = binary_path;
	title_init(1, argv);
	char *tarantool_bin = find_path(binary_path);
	if (!tarantool_bin)
		tarantool_bin = binary_path;

	crash_init(tarantool_bin);
	export_syms();

	random_init();

	crc32_init();
	memory_init();

	main_argc = 1;
	main_argv = argv;

	exception_init();

	fiber_init(fiber_cxx_invoke);
	popen_init();
	coio_init();
	coio_enable();
	signal_init();
	cbus_init();
	coll_init();
	memtx_tx_manager_init();
	module_init();
	crypto_init();
	systemd_init();

	const int override_cert_paths_env_vars = 0;
	int res = ssl_cert_paths_discover(override_cert_paths_env_vars);
	if (res != 0)
		say_warn("No enough memory for setup ssl certificates paths");

#ifndef NDEBUG
	errinj_set_with_environment_vars();
#endif
	tarantool_lua_init(tarantool_bin, main_argc, main_argv);

	start_time = ev_monotonic_time();

	try
	{
		box_init();
		box_lua_init(tarantool_L);
		struct fiber_attr attr;
		fiber_attr_create(&attr);
		attr.flags &= ~FIBER_IS_CANCELLABLE;
		on_shutdown_fiber = fiber_new_ex("on_shutdown", &attr, on_shutdown_f);
		if (on_shutdown_fiber == NULL)
			diag_raise();
		atexit(tarantool_atexit);

		if (!loop())
			panic("%s", "can't init event loop");

		free(argv);
	}
	catch (struct error *e)
	{
		error_log(e);
		systemd_snotify("STATUS=Failed to startup: %s",
						box_error_message(e));
		panic("%s", "fatal error, exiting the event loop");
	}
	catch (...)
	{
		panic("unknown exception");
	}

	return 0;
}

void tarantool_shutdown_library(int code)
{
	if (start_loop)
	{
		say_crit("exiting the event loop");
	}
	if (!is_shutting_down)
	{
		tarantool_exit(code);
	}
	tarantool_free();
}

int main()
{
  return 0;
}