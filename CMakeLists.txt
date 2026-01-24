# =============================================================================
# SymEngine.js - WebAssembly Build
# =============================================================================
#
# This CMakeLists.txt builds SymEngine as a WebAssembly module.
#
# Quick Start:
#   mkdir build && cd build
#   emcmake cmake .. -DCMAKE_BUILD_TYPE=Release
#   emmake make -j$(nproc)
#
# Options:
#   -DSYMENGINE_WASM_MODE=STANDALONE|SIDE_MODULE|STATIC
#   -DINTEGER_CLASS=boostmp|gmp
#   -DSYMENGINE_WASM_EMBIND=ON|OFF
#   -DSYMENGINE_WASM_THREADS=ON|OFF
#

cmake_minimum_required(VERSION 3.16)
project(symengine_wasm VERSION 1.0.0 LANGUAGES CXX)

# =============================================================================
# Configuration
# =============================================================================

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include our toolchain configuration
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/EmscriptenToolchain.cmake)

# =============================================================================
# Paths
# =============================================================================

# SymEngine source location
set(SYMENGINE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/symengine"
    CACHE PATH "Path to SymEngine source directory")

# Dependencies
set(DEPS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/deps"
    CACHE PATH "Path to dependencies directory")

# Boost (for boostmp)
set(Boost_INCLUDE_DIR "${DEPS_DIR}/boost"
    CACHE PATH "Path to Boost headers")

# GMP (if using gmp integer class)
set(GMP_INCLUDE_DIR "${DEPS_DIR}/gmp-wasm/include"
    CACHE PATH "Path to GMP headers")
set(GMP_LIBRARY "${DEPS_DIR}/gmp-wasm/lib/libgmp.a"
    CACHE FILEPATH "Path to GMP library")

# =============================================================================
# SymEngine Configuration
# =============================================================================

# Check if SymEngine source exists
if(NOT EXISTS "${SYMENGINE_SOURCE_DIR}/CMakeLists.txt")
    message(FATAL_ERROR
        "SymEngine source not found at ${SYMENGINE_SOURCE_DIR}\n"
        "Please run: ./build_wasm.sh --install-deps\n"
        "Or set SYMENGINE_SOURCE_DIR to your SymEngine source location.")
endif()

# Integer class selection
set(INTEGER_CLASS "boostmp" CACHE STRING "Integer class to use (gmp or boostmp)")
set_property(CACHE INTEGER_CLASS PROPERTY STRINGS "gmp" "boostmp")

# Configure SymEngine options based on integer class
if(INTEGER_CLASS STREQUAL "boostmp")
    set(WITH_GMP OFF CACHE BOOL "" FORCE)
    set(WITH_MPFR OFF CACHE BOOL "" FORCE)
    set(WITH_MPC OFF CACHE BOOL "" FORCE)
    set(WITH_FLINT OFF CACHE BOOL "" FORCE)
    set(WITH_ARB OFF CACHE BOOL "" FORCE)

    # Check Boost exists
    if(NOT EXISTS "${Boost_INCLUDE_DIR}/boost/multiprecision/cpp_int.hpp")
        message(FATAL_ERROR
            "Boost multiprecision headers not found at ${Boost_INCLUDE_DIR}\n"
            "Please run: ./build_wasm.sh --install-deps")
    endif()
else()
    set(WITH_GMP ON CACHE BOOL "" FORCE)

    # Check GMP exists
    if(NOT EXISTS "${GMP_LIBRARY}")
        message(FATAL_ERROR
            "GMP library not found at ${GMP_LIBRARY}\n"
            "Please run: ./build_wasm.sh --install-deps --integer=gmp")
    endif()
endif()

# Add SymEngine as a subdirectory
add_subdirectory(${SYMENGINE_SOURCE_DIR} symengine_build)

# =============================================================================
# WASM Module Target
# =============================================================================

# Collect binding sources
set(WASM_SOURCES "")

if(SYMENGINE_WASM_EMBIND)
    # Check if bindings.cpp exists
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/bindings.cpp")
        list(APPEND WASM_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/bindings.cpp")
    else()
        message(WARNING
            "Embind bindings not found. Run ./build_wasm.sh --with-embind to generate them.")
    endif()
endif()

# If no sources, create a minimal entry point
if(NOT WASM_SOURCES)
    # Create minimal module source
    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/wasm_entry.cpp" [[
// Minimal WASM entry - exposes SymEngine via C ABI
#include <symengine/basic.h>
#include <symengine/parser.h>

extern "C" {
    const char* symengine_version() {
        static std::string version = SYMENGINE_VERSION;
        return version.c_str();
    }
}
]])
    list(APPEND WASM_SOURCES "${CMAKE_CURRENT_BINARY_DIR}/wasm_entry.cpp")
endif()

# Create the main WASM module
if(SYMENGINE_WASM_MODE STREQUAL "STATIC")
    # Static library for linking into other projects
    add_library(symengine_wasm STATIC ${WASM_SOURCES})
else()
    # Executable that produces JS+WASM or just WASM
    add_executable(symengine_wasm ${WASM_SOURCES})
endif()

# Include directories
target_include_directories(symengine_wasm PRIVATE
    ${SYMENGINE_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}/symengine_build
)

if(INTEGER_CLASS STREQUAL "boostmp")
    target_include_directories(symengine_wasm PRIVATE ${Boost_INCLUDE_DIR})
else()
    target_include_directories(symengine_wasm PRIVATE ${GMP_INCLUDE_DIR})
endif()

# Link SymEngine
target_link_libraries(symengine_wasm PRIVATE symengine)

if(INTEGER_CLASS STREQUAL "gmp")
    target_link_libraries(symengine_wasm PRIVATE ${GMP_LIBRARY})
endif()

# Apply WASM-specific configuration
if(NOT SYMENGINE_WASM_MODE STREQUAL "STATIC")
    symengine_wasm_target_setup(symengine_wasm)
endif()

# Set output name
set_target_properties(symengine_wasm PROPERTIES OUTPUT_NAME "symengine")

# =============================================================================
# Installation
# =============================================================================

# Install the WASM module
if(SYMENGINE_WASM_MODE STREQUAL "STANDALONE")
    install(FILES
        "${CMAKE_CURRENT_BINARY_DIR}/symengine.js"
        "${CMAKE_CURRENT_BINARY_DIR}/symengine.wasm"
        DESTINATION lib
    )
elseif(SYMENGINE_WASM_MODE STREQUAL "SIDE_MODULE")
    install(FILES
        "${CMAKE_CURRENT_BINARY_DIR}/symengine.wasm"
        DESTINATION lib
    )
else()
    install(TARGETS symengine_wasm
        ARCHIVE DESTINATION lib
    )
endif()

# Install TypeScript declarations
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/dist/symengine.d.ts")
    install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/dist/symengine.d.ts"
        DESTINATION lib
    )
endif()

# =============================================================================
# Summary
# =============================================================================

symengine_wasm_print_config()

message(STATUS "Integer Class:  ${INTEGER_CLASS}")
message(STATUS "SymEngine:      ${SYMENGINE_SOURCE_DIR}")
message(STATUS "")
