cmake_minimum_required(VERSION 3.16.0)
project(root C ASM)

add_definitions("-D_GNU_SOURCE")
set(CMAKE_WARN_DEPRECATED OFF CACHE BOOL "" FORCE)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED true)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED true)

set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -fPIC -O0 -g -Wno-parentheses -fno-stack-protector")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -fPIC -O0 -g -Wno-parentheses -fno-stack-protector")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC -O2 -Wno-parentheses -fno-stack-protector")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -O2 -Wno-parentheses -fno-stack-protector")

set(TARANTOOL_DEPENDENCY_REPOSITORY "developer@git.local:dependencies/tarantool.git")
set(TARANTOOL_DEPENDENCY_VERSION evolution-3.0.0)

include(FetchContent)
include(ExternalProject)

set(WITH_TESTS OFF)
FetchContent_Declare(
  tarantool_dependency
  GIT_REPOSITORY ${TARANTOOL_DEPENDENCY_REPOSITORY}
  GIT_TAG ${TARANTOOL_DEPENDENCY_VERSION}
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/dependencies/libtarantool
)
FetchContent_MakeAvailable(tarantool_dependency)
ExternalProject_Add(tarantool_dependency
  PREFIX tarantool_dependency-prefix
  SOURCE_DIR ${tarantool_dependency_SOURCE_DIR}
  LIST_SEPARATOR :
  CMAKE_ARGS
  -DCMAKE_INSTALL_LOCALSTATEDIR=<INSTALL_DIR>/var
  -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
  -DBUNDLED_LIBS_INSTALL_DIR=${tarantool_dependency_BINARY_DIR}
  -DBUILD_STATIC_WITH_BUNDLED_LIBS=TRUE
  -DENABLE_DIST=TRUE
  -DENABLE_LTO=FALSE
  -DENABLE_HARDENING=TRUE
  -DENABLE_BACKTRACE=FALSE
  -DWITH_TESTS=OFF
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON
  STEP_TARGETS clean build
  BUILD_COMMAND $(MAKE)
  BUILD_ALWAYS TRUE
)
ExternalProject_Get_Property(tarantool_dependency install_dir)
set(TARANTOOL_ISNTALL_DIR ${install_dir})
set(TARANTOOL_LIBRARY ${install_dir}/lib/libtarantool-bundle.a)

add_subdirectory(native)