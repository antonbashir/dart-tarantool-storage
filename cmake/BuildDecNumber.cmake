#
# A macro to build the bundled decNumber lisbrary.
macro(decnumber_build)
    set(decnumber_src
	${PROJECT_SOURCE_DIR}/third_party/decNumber/decNumber.c
	${PROJECT_SOURCE_DIR}/third_party/decNumber/decContext.c
	${PROJECT_SOURCE_DIR}/third_party/decNumber/decPacked.c
    )
    add_compile_options(-fPIC)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fpic")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fpic")
    add_library(decNumber STATIC ${decnumber_src})

    set(DECNUMBER_INCLUDE_DIR ${PROJECT_BINARY_DIR}/third_party/decNumber)
    unset(decnumber_src)
endmacro(decnumber_build)
