#!/bin/bash

cd static-build && make clean && cmake -DCMAKE_TARANTOOL_ARGS="-DCMAKE_BUILD_TYPE=RelWithDebInfo;-DENABLE_LTO=true" . && make -j