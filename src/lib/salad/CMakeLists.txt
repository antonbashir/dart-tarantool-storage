add_compile_options(-fPIC)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fpic")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fpic")
set(lib_sources rope.c rtree.c guava.c bloom.c)
set_source_files_compile_flags(${lib_sources})
add_library(salad STATIC ${lib_sources})
