set(lib_sources crypto.c)

set_source_files_compile_flags(${lib_sources})
add_compile_options(-fPIC)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fpic")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fpic")
add_library(crypto STATIC ${lib_sources})
target_link_libraries(crypto ${OPENSSL_LIBRARIES} core)
