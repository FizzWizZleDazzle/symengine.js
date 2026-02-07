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
# We compile with --target=wasm32-wasi so the compiler finds libc/libc++
# headers from the sysroot.  Since we only produce a static library (.a),
# no WASI imports are resolved here — they are irrelevant.  The final
# link happens inside the Rust project (targeting wasm32-unknown-unknown),
# which provides WASI stubs and a compatible allocator.
#
# -fno-exceptions is added via CMAKE_CXX_FLAGS_<CONFIG> rather than
# CMAKE_CXX_FLAGS_INIT so that SymEngine's try_compile() C++11 check
# (which contains `throw`) can pass during configuration.
set(_WASM_BASE_FLAGS
    "--target=wasm32-wasi"
    "--sysroot=${WASI_SYSROOT}"
    "-fvisibility=hidden"
)
string(REPLACE ";" " " _WASM_BASE_STR "${_WASM_BASE_FLAGS}")

set(CMAKE_C_FLAGS_INIT   "${_WASM_BASE_STR}")
set(CMAKE_CXX_FLAGS_INIT "${_WASM_BASE_STR}")

# Apply -fno-exceptions -fno-rtti to actual build configurations only
set(_WASM_EXTRA "-fno-exceptions -fno-rtti")
set(CMAKE_C_FLAGS_RELEASE_INIT          "-O2 ${_WASM_EXTRA}")
set(CMAKE_C_FLAGS_MINSIZEREL_INIT       "-Os ${_WASM_EXTRA}")
set(CMAKE_C_FLAGS_RELWITHDEBINFO_INIT   "-O2 -g ${_WASM_EXTRA}")
set(CMAKE_C_FLAGS_DEBUG_INIT            "-g ${_WASM_EXTRA}")
set(CMAKE_CXX_FLAGS_RELEASE_INIT        "-O2 ${_WASM_EXTRA}")
set(CMAKE_CXX_FLAGS_MINSIZEREL_INIT     "-Os ${_WASM_EXTRA}")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO_INIT "-O2 -g ${_WASM_EXTRA}")
set(CMAKE_CXX_FLAGS_DEBUG_INIT          "-g ${_WASM_EXTRA}")

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
