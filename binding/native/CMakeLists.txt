cmake_minimum_required(VERSION 2.8)
project(TARANTOOL_LIBRARY C CXX)
set(CMAKE_REQUIRED_DEFINITIONS "-D_GNU_SOURCE")

include_directories(${MSGPUCK_INCLUDE_DIRS})

set(CK_VERSION 0.6.0)
include(FetchContent)
FetchContent_Declare(
    ck
    URL http://concurrencykit.org/releases/ck-${CK_VERSION}.tar.gz
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/ck
)
FetchContent_MakeAvailable(ck)
include_directories(${ck_SOURCE_DIR}/include)
set(DEPENDENCY_CFLAGS "-fPIC")
set(DEPENDENCY_CPPFLAGS "-fPIC")
set(DEPENDENCY_LDFLAGS)

if(APPLE)
    set(DEPENDENCY_CFLAGS "${CMAKE_C_SYSROOT_FLAG} ${CMAKE_OSX_SYSROOT}")
    set(DEPENDENCY_CPPFLAGS "${CMAKE_C_SYSROOT_FLAG} ${CMAKE_OSX_SYSROOT}")
endif()

add_custom_target(ck
    COMMAND ./configure
    CC=${CMAKE_C_COMPILER}
    CXX=${CMAKE_CXX_COMPILER}
    CFLAGS=${DEPENDENCY_CFLAGS}
    CPPFLAGS=${DEPENDENCY_CPPFLAGS}
    LDFLAGS=${DEPENDENCY_LDFLAGS}
    --prefix=${ck_SOURCE_DIR}/build && make && make install
    WORKING_DIRECTORY ${ck_SOURCE_DIR}
)

file(GLOB SOURCES
    src/**.h
    src/**.c
)
file(GLOB TEST_SOURCES
    test/**.h
    test/**.c
)

add_library(tarantool_binding SHARED ${SOURCES})
add_dependencies(tarantool_binding ck api)
set_target_properties(tarantool_binding PROPERTIES COMPILE_FLAGS "-fPIC")
target_link_libraries(tarantool_binding PUBLIC tarantool_library ${ck_SOURCE_DIR}/build/lib/libck.a)
add_custom_command(TARGET tarantool_binding POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:tarantool_binding> ${CMAKE_CURRENT_SOURCE_DIR}/../dart/native/libstorage.so
)
add_custom_command(TARGET tarantool_binding POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/src/module.h ${CMAKE_CURRENT_SOURCE_DIR}/../dart/native/module.h
)
add_custom_command(TARGET tarantool_binding POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/src/lib/msgpuck/msgpuck.h ${CMAKE_CURRENT_SOURCE_DIR}/../dart/native/msgpuck.h
)
add_custom_command(TARGET tarantool_binding POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/src/binding_extension.h ${CMAKE_CURRENT_SOURCE_DIR}/../dart/native/extension.h
)

add_executable(tarantool_binding_test ${SOURCES} ${TEST_SOURCES})
add_dependencies(tarantool_binding_test ck)
set_target_properties(tarantool_binding_test PROPERTIES COMPILE_FLAGS "-fPIC")
target_link_libraries(tarantool_binding_test PUBLIC tarantool_binding ${ck_SOURCE_DIR}/build/lib/libck.a)
