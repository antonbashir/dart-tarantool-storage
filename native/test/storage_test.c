#include "msgpuck.h"
#include "say.h"
#include "tarantool.h"

int main(int argc, char** argv)
{
    struct timeval st, et;

    gettimeofday(&st, NULL);
    for (size_t i = 0; i < 1000; i++)
    {
        char* buffer = malloc(1024);
        mp_encode_array(buffer, 3);
        mp_encode_uint(buffer, 10);
        mp_encode_str(buffer, "test", strlen("test"));
        mp_encode_bool(buffer, true);
    }
    gettimeofday(&et, NULL);

    int elapsed = ((et.tv_sec - st.tv_sec) * 1000000) + (et.tv_usec - st.tv_usec);
    printf("Sorting time: %d micro seconds\n", elapsed);
    return 0;
}