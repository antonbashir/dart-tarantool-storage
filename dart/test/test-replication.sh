#!/bin/bash

dart compile exe test/replica.dart

pids=""
test/replica.exe 3302 3302 3303 3304 &
pids+=" $!"
test/replica.exe 3303 3302 3303 3304 &
pids+=" $!"
test/replica.exe 3304 3302 3303 3304 &
pids+=" $!"

result=0
for p in $pids; do
        if wait $p; then
                result=0
        else
                result=1
        fi
done
exit $result

