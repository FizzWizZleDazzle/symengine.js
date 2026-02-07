# =============================================================================
# SymEngine wasm32-unknown-unknown CMake Toolchain (via wasi-sdk)
# =============================================================================
#
# Cross-compiles SymEngine to a static library (.a) targeting
# wasm32-unknown-unknown.  The resulting libsymengine.a can be linked
# into Rust/wasm-bindgen projects built with Trunk or wasm-pack.
#
# Usage:
#   cmake -DCMAKE_TOOLCHAIN_FILE=cmake/Wasm32UnknownToolchain.cmake \
#         -DWASI_SDK_PREFIX=/opt/wasi-sdk ..
#

cmake_minimum_required(VERSION 3.16)

# ---- Locate wasi-sdk --------------------------------------------------
if(NOT DEFINED WASI_SDK_PREFIX)
    if(DEFINED ENV{WASI_SDK_PATH})
        set(WASI_SDK_PREFIX "$ENV{WASI_SDK_PATH}")
    else()
        message(FATAL_ERROR
            "WASI_SDK_PREFIX is not set. Pass -DWASI_SDK_PREFIX=<path> or "
            "set the WASI_SDK_PATH environment variable.")
    endif()
endif()

# ---- System identification ---------------------------------------------
set(CMAKE_SYSTEM_NAME       Generic)
set(CMAKE_SYSTEM_PROCESSOR  wasm32)

# ---- Compilers ----------------------------------------------------------
set(CMAKE_C_COMPILER   "${WASI_SDK_PREFIX}/bin/clang")
set(CMAKE_CXX_COMPILER "${WASI_SDK_PREFIX}/bin/clang++")
set(CMAKE_AR           "${WASI_SDK_PREFIX}/bin/llvm-ar"    CACHE FILEPATH "ar")
set(CMAKE_RANLIB       "${WASI_SDK_PREFIX}/bin/llvm-ranlib" CACHE FILEPATH "ranlib")

set(WASI_SYSROOT "${WASI_SDK_PREFIX}/share/wasi-sysroot")

# ---- Compiler / linker flags -------------------------------------------
set(_WASM_TARGET_FLAGS
    "--target=wasm32-unknown-unknown"
    "--sysroot=${WASI_SYSROOT}"
    "-fno-exceptions"
    "-fno-rtti"
    "-fvisibility=hidden"
)
string(REPLACE ";" " " _WASM_FLAGS_STR "${_WASM_TARGET_FLAGS}")

set(CMAKE_C_FLAGS_INIT   "${_WASM_FLAGS_STR}")
set(CMAKE_CXX_FLAGS_INIT "${_WASM_FLAGS_STR}")

# We can only produce static libraries — no executable linking possible
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# ---- SymEngine feature overrides ---------------------------------------
# Force-disable features that are incompatible with wasm32-unknown-unknown
set(BUILD_SHARED_LIBS            OFF CACHE BOOL "" FORCE)
set(BUILD_TESTS                  OFF CACHE BOOL "" FORCE)
set(BUILD_BENCHMARKS             OFF CACHE BOOL "" FORCE)
set(WITH_SYMENGINE_RCP           ON  CACHE BOOL "" FORCE)
set(WITH_SYMENGINE_THREAD_SAFE   OFF CACHE BOOL "" FORCE)
set(WITH_BFD                     OFF CACHE BOOL "" FORCE)
set(WITH_LLVM                    OFF CACHE BOOL "" FORCE)
set(WITH_PRIMESIEVE              OFF CACHE BOOL "" FORCE)
set(WITH_ECM                     OFF CACHE BOOL "" FORCE)
set(WITH_TCMALLOC                OFF CACHE BOOL "" FORCE)
set(WITH_COTIRE                  OFF CACHE BOOL "" FORCE)
set(WITH_OPENMP                  OFF CACHE BOOL "" FORCE)
