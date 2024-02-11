#ifndef TARANTOOL_LAUNCHER_H_INCLUDED
#define TARANTOOL_LAUNCHER_H_INCLUDED

#if defined(__cplusplus)
extern "C"
{
#endif
    void tarantool_launcher_launch(char* binary_path);
    void tarantool_launcher_shutdown(int code);
#if defined(__cplusplus)
}
#endif

#endif