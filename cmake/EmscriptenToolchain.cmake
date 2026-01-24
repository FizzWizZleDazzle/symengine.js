# =============================================================================
# SymEngine Emscripten CMake Toolchain Configuration
# =============================================================================
#
# This file provides CMake configuration for building SymEngine as WebAssembly.
# It can be used directly or included in your own CMake projects.
#
# Usage with emcmake:
#   emcmake cmake -DCMAKE_TOOLCHAIN_FILE=$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake \
#                 -C /path/to/EmscriptenToolchain.cmake ..
#
# Or set options directly:
#   emcmake cmake -DSYMENGINE_WASM_MODE=SIDE_MODULE ..
#

cmake_minimum_required(VERSION 3.16)

# =============================================================================
# Build Mode Configuration
# =============================================================================

# SYMENGINE_WASM_MODE: Controls the type of WebAssembly output
#   STANDALONE  - Creates a main module with JS glue code (default)
#   SIDE_MODULE - Creates a pure WASM module for dynamic linking
#   STATIC      - Creates a static library for linking into other WASM projects
set(SYMENGINE_WASM_MODE "STANDALONE" CACHE STRING "WASM build mode")
set_property(CACHE SYMENGINE_WASM_MODE PROPERTY STRINGS "STANDALONE" "SIDE_MODULE" "STATIC")

# =============================================================================
# Feature Flags
# =============================================================================

option(SYMENGINE_WASM_THREADS "Enable pthread support (experimental)" OFF)
option(SYMENGINE_WASM_EMBIND "Enable embind JavaScript bindings" ON)
option(SYMENGINE_WASM_ES6 "Export as ES6 module" ON)
option(SYMENGINE_WASM_SIMD "Enable SIMD optimizations" OFF)
option(SYMENGINE_WASM_EXCEPTIONS "Enable C++ exception support" ON)

# Memory configuration
set(SYMENGINE_WASM_INITIAL_MEMORY "16MB" CACHE STRING "Initial WASM memory")
set(SYMENGINE_WASM_MAXIMUM_MEMORY "4GB" CACHE STRING "Maximum WASM memory")
set(SYMENGINE_WASM_STACK_SIZE "1MB" CACHE STRING "WASM stack size")

# =============================================================================
# Compiler Flags
# =============================================================================

# Base flags for all modes
set(SYMENGINE_WASM_COMPILE_FLAGS
    -fno-rtti
    -fno-exceptions
)

if(SYMENGINE_WASM_EXCEPTIONS)
    list(REMOVE_ITEM SYMENGINE_WASM_COMPILE_FLAGS -fno-exceptions)
    list(APPEND SYMENGINE_WASM_COMPILE_FLAGS -fwasm-exceptions)
endif()

if(SYMENGINE_WASM_SIMD)
    list(APPEND SYMENGINE_WASM_COMPILE_FLAGS -msimd128)
endif()

if(SYMENGINE_WASM_THREADS)
    list(APPEND SYMENGINE_WASM_COMPILE_FLAGS -pthread)
endif()

# =============================================================================
# Linker Flags
# =============================================================================

# Base link flags
set(SYMENGINE_WASM_LINK_FLAGS
    "-sALLOW_MEMORY_GROWTH=1"
    "-sINITIAL_MEMORY=${SYMENGINE_WASM_INITIAL_MEMORY}"
    "-sMAXIMUM_MEMORY=${SYMENGINE_WASM_MAXIMUM_MEMORY}"
    "-sSTACK_SIZE=${SYMENGINE_WASM_STACK_SIZE}"
    "-sFILESYSTEM=0"
    "-sASSERTIONS=0"
    "-sDISABLE_EXCEPTION_CATCHING=0"
)

if(SYMENGINE_WASM_ES6)
    list(APPEND SYMENGINE_WASM_LINK_FLAGS "-sEXPORT_ES6=1")
endif()

if(SYMENGINE_WASM_THREADS)
    list(APPEND SYMENGINE_WASM_LINK_FLAGS
        "-pthread"
        "-sPTHREAD_POOL_SIZE=navigator.hardwareConcurrency"
        "-sUSE_PTHREADS=1"
    )
endif()

if(SYMENGINE_WASM_EMBIND)
    list(APPEND SYMENGINE_WASM_LINK_FLAGS "-lembind")
endif()

# Mode-specific flags
if(SYMENGINE_WASM_MODE STREQUAL "STANDALONE")
    list(APPEND SYMENGINE_WASM_LINK_FLAGS
        "-sMAIN_MODULE=2"
        "-sMODULARIZE=1"
        "-sEXPORT_NAME=SymEngine"
        "-sENVIRONMENT=web,node,worker"
    )
elseif(SYMENGINE_WASM_MODE STREQUAL "SIDE_MODULE")
    list(APPEND SYMENGINE_WASM_LINK_FLAGS
        "-sSIDE_MODULE=2"
        "-sEXPORT_ALL=1"
        "--no-entry"
    )
    # Remove incompatible flags
    list(REMOVE_ITEM SYMENGINE_WASM_LINK_FLAGS
        "-sMAIN_MODULE=2"
        "-sMODULARIZE=1"
    )
endif()

# =============================================================================
# SymEngine Configuration Defaults
# =============================================================================

# Recommended settings for SymEngine WASM builds
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries")
set(BUILD_TESTS OFF CACHE BOOL "Build tests")
set(BUILD_BENCHMARKS OFF CACHE BOOL "Build benchmarks")
set(WITH_SYMENGINE_RCP ON CACHE BOOL "Use SymEngine RCP")
set(WITH_SYMENGINE_THREAD_SAFE ${SYMENGINE_WASM_THREADS} CACHE BOOL "Thread safety")

# Disable features not compatible with WASM
set(WITH_BFD OFF CACHE BOOL "BFD support")
set(WITH_LLVM OFF CACHE BOOL "LLVM support")
set(WITH_PRIMESIEVE OFF CACHE BOOL "Primesieve")
set(WITH_ECM OFF CACHE BOOL "ECM")
set(WITH_TCMALLOC OFF CACHE BOOL "TCMalloc")
set(WITH_COTIRE OFF CACHE BOOL "Cotire")
set(WITH_OPENMP OFF CACHE BOOL "OpenMP")

# =============================================================================
# Helper Functions
# =============================================================================

# Function to apply WASM flags to a target
function(symengine_wasm_target_setup target)
    target_compile_options(${target} PRIVATE ${SYMENGINE_WASM_COMPILE_FLAGS})

    # Join link flags with spaces
    string(REPLACE ";" " " _link_flags "${SYMENGINE_WASM_LINK_FLAGS}")
    set_target_properties(${target} PROPERTIES LINK_FLAGS "${_link_flags}")

    # Set output suffix based on mode
    if(SYMENGINE_WASM_MODE STREQUAL "SIDE_MODULE")
        set_target_properties(${target} PROPERTIES SUFFIX ".wasm")
    else()
        set_target_properties(${target} PROPERTIES SUFFIX ".js")
    endif()
endfunction()

# Function to create a complete WASM module from SymEngine
function(symengine_create_wasm_module name)
    cmake_parse_arguments(PARSE_ARGV 1 ARG
        ""
        "OUTPUT_NAME"
        "SOURCES;LIBRARIES"
    )

    if(NOT ARG_SOURCES)
        message(FATAL_ERROR "symengine_create_wasm_module requires SOURCES")
    endif()

    # Create executable (Emscripten builds executables, not libraries, for final WASM)
    add_executable(${name} ${ARG_SOURCES})

    # Apply WASM configuration
    symengine_wasm_target_setup(${name})

    # Link SymEngine and any additional libraries
    target_link_libraries(${name} PRIVATE
        symengine
        ${ARG_LIBRARIES}
    )

    # Set output name
    if(ARG_OUTPUT_NAME)
        set_target_properties(${name} PROPERTIES OUTPUT_NAME ${ARG_OUTPUT_NAME})
    endif()
endfunction()

# =============================================================================
# Print Configuration Summary
# =============================================================================

function(symengine_wasm_print_config)
    message(STATUS "")
    message(STATUS "SymEngine WASM Configuration:")
    message(STATUS "  Mode:        ${SYMENGINE_WASM_MODE}")
    message(STATUS "  Threads:     ${SYMENGINE_WASM_THREADS}")
    message(STATUS "  Embind:      ${SYMENGINE_WASM_EMBIND}")
    message(STATUS "  ES6:         ${SYMENGINE_WASM_ES6}")
    message(STATUS "  SIMD:        ${SYMENGINE_WASM_SIMD}")
    message(STATUS "  Exceptions:  ${SYMENGINE_WASM_EXCEPTIONS}")
    message(STATUS "  Memory:      ${SYMENGINE_WASM_INITIAL_MEMORY} - ${SYMENGINE_WASM_MAXIMUM_MEMORY}")
    message(STATUS "")
endfunction()
