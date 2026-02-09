#!/usr/bin/env bash
#
# SymEngine WebAssembly Build Script
# ===================================
# Builds SymEngine as a WebAssembly module for web/JS usage.
# Supports both standalone (MAIN_MODULE) and dynamic linking (SIDE_MODULE) builds.
#
# Usage:
#   ./build_wasm.sh [OPTIONS]
#
# Options:
#   --arch=<emscripten|unknown> Target arch (default: emscripten)
#   --mode=<standalone|side>   Build mode (default: standalone, emscripten only)
#   --integer=<gmp|boostmp>    Integer class to use (default: boostmp)
#   --build-type=<Release|Debug|MinSizeRel>  Build type (default: Release)
#   --threads                   Enable thread safety (experimental)
#   --clean                     Clean build directories before building
#   --install-deps              Download and build dependencies
#   --skip-symengine            Only build dependencies, skip SymEngine
#   --with-embind               Include embind JavaScript bindings
#   --single-file               Bundle WASM into JS file (no separate .wasm)
#   --wasi-sdk=<path>           Path to wasi-sdk (for --arch=unknown)
#   --help                      Show this help message
#
# Environment variables:
#   EMSDK                       Path to Emscripten SDK (auto-detected if not set)
#   WASI_SDK_PATH               Path to wasi-sdk installation (for --arch=unknown)
#   SYMENGINE_SRC               Path to SymEngine source (default: ./symengine)
#   BUILD_DIR                   Build directory (default: ./build)
#   INSTALL_PREFIX              Installation prefix (default: ./dist)
#   JOBS                        Parallel build jobs (default: nproc)
#

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYMENGINE_SRC="${SYMENGINE_SRC:-$SCRIPT_DIR/symengine}"
DEPS_DIR="${DEPS_DIR:-$SCRIPT_DIR/deps}"
BUILD_DIR="${BUILD_DIR:-$SCRIPT_DIR/build}"
INSTALL_PREFIX="${INSTALL_PREFIX:-$SCRIPT_DIR/dist}"
JOBS="${JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)}"

# Build options (defaults)
ARCH="emscripten"         # emscripten or unknown (wasm32-unknown-unknown)
BUILD_MODE="standalone"   # standalone or side (SIDE_MODULE)
INTEGER_CLASS="boostmp"   # gmp or boostmp
BUILD_TYPE="Release"
ENABLE_THREADS=false
CLEAN_BUILD=false
INSTALL_DEPS=false
SKIP_SYMENGINE=false
WITH_EMBIND=false
SINGLE_FILE=false         # Bundle WASM into JS file

# Versions
GMP_VERSION="6.3.0"
BOOST_VERSION="1.84.0"
SYMENGINE_VERSION="0.12.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

die() {
    log_error "$@"
    exit 1
}

show_help() {
    head -n 32 "$0" | tail -n 30 | sed 's/^#//'
    exit 0
}

check_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

# =============================================================================
# Parse Arguments
# =============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --arch=*)
                ARCH="${1#*=}"
                [[ "$ARCH" == "emscripten" || "$ARCH" == "unknown" ]] || \
                    die "Invalid arch: $ARCH (must be 'emscripten' or 'unknown')"
                ;;
            --wasi-sdk=*)
                WASI_SDK_PATH="${1#*=}"
                ;;
            --mode=*)
                BUILD_MODE="${1#*=}"
                [[ "$BUILD_MODE" == "standalone" || "$BUILD_MODE" == "side" ]] || \
                    die "Invalid mode: $BUILD_MODE (must be 'standalone' or 'side')"
                ;;
            --integer=*)
                INTEGER_CLASS="${1#*=}"
                [[ "$INTEGER_CLASS" == "gmp" || "$INTEGER_CLASS" == "boostmp" ]] || \
                    die "Invalid integer class: $INTEGER_CLASS (must be 'gmp' or 'boostmp')"
                ;;
            --build-type=*)
                BUILD_TYPE="${1#*=}"
                ;;
            --threads)
                ENABLE_THREADS=true
                ;;
            --clean)
                CLEAN_BUILD=true
                ;;
            --install-deps)
                INSTALL_DEPS=true
                ;;
            --skip-symengine)
                SKIP_SYMENGINE=true
                ;;
            --with-embind)
                WITH_EMBIND=true
                ;;
            --single-file)
                SINGLE_FILE=true
                ;;
            --help|-h)
                show_help
                ;;
            *)
                die "Unknown option: $1"
                ;;
        esac
        shift
    done
}

# =============================================================================
# Environment Setup
# =============================================================================

setup_emscripten() {
    log_info "Setting up Emscripten environment..."

    # Try to find EMSDK
    if [[ -z "${EMSDK:-}" ]]; then
        # Common locations
        local search_paths=(
            "$HOME/emsdk"
            "/opt/emsdk"
            "/usr/local/emsdk"
            "$SCRIPT_DIR/emsdk"
        )

        for path in "${search_paths[@]}"; do
            if [[ -f "$path/emsdk_env.sh" ]]; then
                EMSDK="$path"
                break
            fi
        done
    fi

    if [[ -z "${EMSDK:-}" ]]; then
        die "Emscripten SDK not found. Please set EMSDK environment variable or install emsdk."
    fi

    log_info "Using EMSDK at: $EMSDK"

    # Source the environment
    # shellcheck source=/dev/null
    source "$EMSDK/emsdk_env.sh" 2>/dev/null || true

    # Verify emcc is available
    check_command emcc
    check_command emcmake
    check_command emmake

    EMCC_VERSION=$(emcc --version | head -n1)
    log_info "Emscripten version: $EMCC_VERSION"
}

# =============================================================================
# wasm32-unknown-unknown Setup (via wasi-sdk)
# =============================================================================

setup_wasi_sdk() {
    log_info "Setting up wasi-sdk environment..."

    # Try to find wasi-sdk
    if [[ -z "${WASI_SDK_PATH:-}" ]]; then
        local search_paths=(
            "/opt/wasi-sdk"
            "$HOME/wasi-sdk"
            "$SCRIPT_DIR/wasi-sdk"
        )
        for path in "${search_paths[@]}"; do
            if [[ -d "$path" && -f "$path/bin/clang" ]]; then
                WASI_SDK_PATH="$path"
                break
            fi
        done
    fi

    if [[ -z "${WASI_SDK_PATH:-}" ]]; then
        die "wasi-sdk not found. Install it and set WASI_SDK_PATH, pass --wasi-sdk=<path>, or place it at /opt/wasi-sdk."
    fi

    if [[ ! -f "$WASI_SDK_PATH/bin/clang" ]]; then
        die "wasi-sdk clang not found at $WASI_SDK_PATH/bin/clang"
    fi

    export WASI_SDK_PATH
    WASI_CC="$WASI_SDK_PATH/bin/clang"
    WASI_CXX="$WASI_SDK_PATH/bin/clang++"
    WASI_AR="$WASI_SDK_PATH/bin/llvm-ar"
    WASI_RANLIB="$WASI_SDK_PATH/bin/llvm-ranlib"
    WASI_SYSROOT="$WASI_SDK_PATH/share/wasi-sysroot"

    log_info "Using wasi-sdk at: $WASI_SDK_PATH"
    log_info "Clang version: $($WASI_CC --version | head -n1)"
}

build_gmp_wasm_unknown() {
    local gmp_build_dir="$BUILD_DIR/gmp-wasm-unknown"
    local gmp_install_dir="$DEPS_DIR/gmp-wasm-unknown"

    if [[ -f "$gmp_install_dir/lib/libgmp.a" ]]; then
        log_info "GMP (wasm-unknown) already built at $gmp_install_dir"
        return 0
    fi

    log_info "Building GMP $GMP_VERSION for wasm32-unknown-unknown..."
    mkdir -p "$gmp_build_dir" "$gmp_install_dir"

    # Download GMP (shared with emscripten path)
    local gmp_src="$DEPS_DIR/gmp-${GMP_VERSION}"
    if [[ ! -d "$gmp_src" ]]; then
        log_info "Downloading GMP..."
        local gmp_url="https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.xz"
        curl -fsSL "$gmp_url" -o "$DEPS_DIR/gmp.tar.xz"
        tar xJf "$DEPS_DIR/gmp.tar.xz" -C "$DEPS_DIR"
        rm "$DEPS_DIR/gmp.tar.xz"
    fi

    cd "$gmp_build_dir"

    local wasm_cflags="--target=wasm32-wasi --sysroot=$WASI_SYSROOT -O2 -fno-exceptions"

    "$gmp_src/configure" \
        --prefix="$gmp_install_dir" \
        --host=none \
        --disable-assembly \
        --enable-static \
        --disable-shared \
        CC="$WASI_CC" \
        CXX="$WASI_CXX" \
        AR="$WASI_AR" \
        RANLIB="$WASI_RANLIB" \
        CFLAGS="$wasm_cflags" \
        CXXFLAGS="$wasm_cflags"

    make -j"$JOBS"
    make install

    cd "$SCRIPT_DIR"
    log_success "GMP (wasm-unknown) built successfully"
}

build_symengine_lib_unknown() {
    log_info "Building SymEngine library for wasm32-unknown-unknown..."

    local symengine_build_dir="$BUILD_DIR/symengine-wasm-unknown"

    if [[ "$CLEAN_BUILD" == true ]]; then
        rm -rf "$symengine_build_dir"
    fi

    mkdir -p "$symengine_build_dir"
    cd "$symengine_build_dir"

    local cmake_args=(
        "-DCMAKE_TOOLCHAIN_FILE=$SCRIPT_DIR/cmake/Wasm32UnknownToolchain.cmake"
        "-DWASI_SDK_PREFIX=$WASI_SDK_PATH"
        "-DCMAKE_BUILD_TYPE=$BUILD_TYPE"
        "-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX/wasm-unknown"
        "-DINTEGER_CLASS=$INTEGER_CLASS"
    )

    if [[ "$INTEGER_CLASS" == "boostmp" ]]; then
        cmake_args+=(
            "-DWITH_GMP=OFF"
            "-DWITH_MPFR=OFF"
            "-DWITH_MPC=OFF"
            "-DWITH_FLINT=OFF"
            "-DWITH_ARB=OFF"
            "-DBoost_INCLUDE_DIR=$DEPS_DIR/boost"
        )
    else
        cmake_args+=(
            "-DWITH_GMP=ON"
            "-DGMP_INCLUDE_DIR=$DEPS_DIR/gmp-wasm-unknown/include"
            "-DGMP_LIBRARY=$DEPS_DIR/gmp-wasm-unknown/lib/libgmp.a"
            "-DWITH_MPFR=OFF"
            "-DWITH_MPC=OFF"
        )
    fi

    log_info "Configuring SymEngine (wasm-unknown)..."
    cmake "${cmake_args[@]}" "$SYMENGINE_SRC"

    log_info "Compiling SymEngine (wasm-unknown)..."
    make -j"$JOBS" symengine

    cd "$SCRIPT_DIR"
    log_success "SymEngine library built (wasm-unknown)"
}

build_wasm_unknown_module() {
    log_info "Installing wasm32-unknown-unknown artifacts..."

    local symengine_build_dir="$BUILD_DIR/symengine-wasm-unknown"
    local output_lib_dir="$INSTALL_PREFIX/wasm-unknown/lib"
    local output_inc_dir="$INSTALL_PREFIX/wasm-unknown/include/symengine"

    mkdir -p "$output_lib_dir" "$output_inc_dir"

    # Copy static library
    local symengine_lib="$symengine_build_dir/symengine/libsymengine.a"
    if [[ ! -f "$symengine_lib" ]]; then
        die "SymEngine library not found at $symengine_lib"
    fi
    cp "$symengine_lib" "$output_lib_dir/"

    # Copy GMP library if using GMP
    if [[ "$INTEGER_CLASS" == "gmp" ]]; then
        local gmp_lib="$DEPS_DIR/gmp-wasm-unknown/lib/libgmp.a"
        if [[ -f "$gmp_lib" ]]; then
            cp "$gmp_lib" "$output_lib_dir/"
        fi
    fi

    # Copy wasi-sdk C/C++ runtime libraries (needed by C++ code in libsymengine).
    local wasi_lib_dir="$WASI_SDK_PATH/share/wasi-sysroot/lib/wasm32-wasi"
    for lib in libc++.a libc++abi.a; do
        if [[ -f "$wasi_lib_dir/$lib" ]]; then
            cp "$wasi_lib_dir/$lib" "$output_lib_dir/"
        else
            log_warn "wasi-sdk library not found: $wasi_lib_dir/$lib"
        fi
    done

    # Ship a stripped libc.a WITHOUT dlmalloc/sbrk.  The Rust project
    # provides malloc/free/calloc/realloc that delegate to Rust's
    # allocator, avoiding a dual-allocator conflict at runtime.
    if [[ -f "$wasi_lib_dir/libc.a" ]]; then
        cp "$wasi_lib_dir/libc.a" "$output_lib_dir/libc.a"
        local ar_tool
        ar_tool="$(command -v llvm-ar-18 2>/dev/null || command -v llvm-ar 2>/dev/null || echo "$WASI_SDK_PATH/bin/llvm-ar")"
        "$ar_tool" d "$output_lib_dir/libc.a" dlmalloc.o sbrk.o atexit.o __cxa_atexit.o 2>/dev/null || true
        log_info "Stripped dlmalloc/sbrk/atexit from libc.a (Rust provides allocator; stubs prevent global dtors)"
    else
        log_warn "wasi-sdk library not found: $wasi_lib_dir/libc.a"
    fi

    # Copy headers
    install_headers "$output_inc_dir" "$symengine_build_dir"

    log_success "Artifacts installed to $INSTALL_PREFIX/wasm-unknown/"

    # Print summary
    echo ""
    log_info "Build Summary:"
    echo "  Arch: wasm32-unknown-unknown"
    echo "  Integer Class: $INTEGER_CLASS"
    echo "  Build Type: $BUILD_TYPE"
    echo "  Library: $output_lib_dir/libsymengine.a"
    echo "  Headers: $output_inc_dir/"

    local lib_size
    lib_size=$(du -h "$output_lib_dir/libsymengine.a" | cut -f1)
    echo "  Library Size: $lib_size"
}

install_headers() {
    local dest_dir="$1"
    local build_dir="$2"

    # cwrapper.h from source
    cp "$SYMENGINE_SRC/symengine/cwrapper.h" "$dest_dir/"

    # symengine_config.h is generated by CMake into the build directory
    cp "$build_dir/symengine/symengine_config.h" "$dest_dir/"

    # symengine_exception.h from source
    cp "$SYMENGINE_SRC/symengine/symengine_exception.h" "$dest_dir/"

    log_info "Headers installed to $dest_dir"
}

# =============================================================================
# Dependency Management (wasm-unknown)
# =============================================================================

install_dependencies_unknown() {
    log_info "Installing dependencies (wasm-unknown)..."

    download_symengine
    download_boost  # Always needed (header-only utilities)

    if [[ "$INTEGER_CLASS" == "gmp" ]]; then
        build_gmp_wasm_unknown
    fi

    log_success "Dependencies installed (wasm-unknown)"
}

# =============================================================================
# Dependency Management
# =============================================================================

download_symengine() {
    if [[ -d "$SYMENGINE_SRC" ]]; then
        log_info "SymEngine source already exists at $SYMENGINE_SRC"
        return 0
    fi

    log_info "Downloading SymEngine v$SYMENGINE_VERSION..."
    mkdir -p "$(dirname "$SYMENGINE_SRC")"

    local url="https://github.com/symengine/symengine/archive/refs/tags/v${SYMENGINE_VERSION}.tar.gz"
    curl -fsSL "$url" | tar xz -C "$(dirname "$SYMENGINE_SRC")"
    mv "$(dirname "$SYMENGINE_SRC")/symengine-${SYMENGINE_VERSION}" "$SYMENGINE_SRC"

    log_success "SymEngine downloaded to $SYMENGINE_SRC"
}

download_boost() {
    local boost_dir="$DEPS_DIR/boost"

    if [[ -d "$boost_dir" ]]; then
        log_info "Boost already exists at $boost_dir"
        return 0
    fi

    log_info "Downloading Boost $BOOST_VERSION (headers only)..."
    mkdir -p "$DEPS_DIR"

    # Boost uses underscores in archive names
    local boost_ver_underscore="${BOOST_VERSION//./_}"
    local url="https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${boost_ver_underscore}.tar.gz"

    curl -fsSL "$url" | tar xz -C "$DEPS_DIR"
    mv "$DEPS_DIR/boost_${boost_ver_underscore}" "$boost_dir"

    log_success "Boost downloaded to $boost_dir"
}

build_gmp() {
    local gmp_build_dir="$BUILD_DIR/gmp"
    local gmp_install_dir="$DEPS_DIR/gmp-wasm"

    if [[ -f "$gmp_install_dir/lib/libgmp.a" ]]; then
        log_info "GMP already built at $gmp_install_dir"
        return 0
    fi

    log_info "Building GMP $GMP_VERSION for WebAssembly..."
    mkdir -p "$gmp_build_dir" "$gmp_install_dir"

    # Download GMP
    local gmp_src="$DEPS_DIR/gmp-${GMP_VERSION}"
    if [[ ! -d "$gmp_src" ]]; then
        log_info "Downloading GMP..."
        local gmp_url="https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.xz"
        curl -fsSL "$gmp_url" -o "$DEPS_DIR/gmp.tar.xz"
        tar xJf "$DEPS_DIR/gmp.tar.xz" -C "$DEPS_DIR"
        rm "$DEPS_DIR/gmp.tar.xz"
    fi

    cd "$gmp_build_dir"

    # Configure GMP for Emscripten
    # --disable-assembly is CRITICAL for WebAssembly
    # Use wasm32 as host to properly configure for WebAssembly
    emconfigure "$gmp_src/configure" \
        --prefix="$gmp_install_dir" \
        --host=wasm32-unknown-emscripten \
        --disable-assembly \
        --enable-static \
        --disable-shared \
        CFLAGS="-O2" \
        CXXFLAGS="-O2"

    # Build and install
    emmake make -j"$JOBS"
    emmake make install

    cd "$SCRIPT_DIR"
    log_success "GMP built successfully"
}

install_dependencies() {
    log_info "Installing dependencies..."

    download_symengine

    if [[ "$INTEGER_CLASS" == "boostmp" ]]; then
        download_boost
    else
        download_boost  # Still needed for some utilities
        build_gmp
    fi

    log_success "Dependencies installed"
}

# =============================================================================
# CMake Configuration
# =============================================================================

generate_cmake_cache() {
    local cmake_args=(
        "-DCMAKE_BUILD_TYPE=$BUILD_TYPE"
        "-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX"
        "-DBUILD_SHARED_LIBS=OFF"
        "-DBUILD_TESTS=OFF"
        "-DBUILD_BENCHMARKS=OFF"
        "-DWITH_SYMENGINE_RCP=ON"
        "-DWITH_SYMENGINE_ASSERT=OFF"
        "-DINTEGER_CLASS=$INTEGER_CLASS"
    )

    # Thread safety
    if [[ "$ENABLE_THREADS" == true ]]; then
        cmake_args+=("-DWITH_SYMENGINE_THREAD_SAFE=ON")
    else
        cmake_args+=("-DWITH_SYMENGINE_THREAD_SAFE=OFF")
        cmake_args+=("-DWITH_OPENMP=OFF")
    fi

    # Disable optional features not suitable for WASM
    cmake_args+=(
        "-DWITH_BFD=OFF"
        "-DWITH_LLVM=OFF"
        "-DWITH_PRIMESIEVE=OFF"
        "-DWITH_ECM=OFF"
        "-DWITH_TCMALLOC=OFF"
        "-DWITH_COTIRE=OFF"
    )

    # Integer class specific settings
    if [[ "$INTEGER_CLASS" == "boostmp" ]]; then
        cmake_args+=(
            "-DWITH_GMP=OFF"
            "-DWITH_MPFR=OFF"
            "-DWITH_MPC=OFF"
            "-DWITH_FLINT=OFF"
            "-DWITH_ARB=OFF"
            "-DBoost_INCLUDE_DIR=$DEPS_DIR/boost"
        )
    else
        cmake_args+=(
            "-DWITH_GMP=ON"
            "-DGMP_INCLUDE_DIR=$DEPS_DIR/gmp-wasm/include"
            "-DGMP_LIBRARY=$DEPS_DIR/gmp-wasm/lib/libgmp.a"
            "-DWITH_MPFR=OFF"
            "-DWITH_MPC=OFF"
        )
    fi

    echo "${cmake_args[@]}"
}

# =============================================================================
# Build Functions
# =============================================================================

build_symengine_lib() {
    log_info "Building SymEngine library..."

    local symengine_build_dir="$BUILD_DIR/symengine-$BUILD_MODE"

    if [[ "$CLEAN_BUILD" == true ]]; then
        rm -rf "$symengine_build_dir"
    fi

    mkdir -p "$symengine_build_dir"
    cd "$symengine_build_dir"

    # Get CMake configuration
    local cmake_args
    read -ra cmake_args <<< "$(generate_cmake_cache)"

    # Configure with Emscripten
    log_info "Configuring SymEngine..."
    emcmake cmake "${cmake_args[@]}" "$SYMENGINE_SRC"

    # Build
    log_info "Compiling SymEngine..."
    emmake make -j"$JOBS" symengine

    cd "$SCRIPT_DIR"
    log_success "SymEngine library built"
}

build_wasm_module() {
    log_info "Building WebAssembly module ($BUILD_MODE mode)..."

    local symengine_build_dir="$BUILD_DIR/symengine-$BUILD_MODE"
    local output_dir="$INSTALL_PREFIX"
    mkdir -p "$output_dir"

    # Find the static library
    local symengine_lib="$symengine_build_dir/symengine/libsymengine.a"
    if [[ ! -f "$symengine_lib" ]]; then
        die "SymEngine library not found at $symengine_lib. Run build first."
    fi

    # Common emcc flags
    local emcc_flags=(
        "-O2"
        "-std=c++17"
        "-I$SYMENGINE_SRC"
        "-I$symengine_build_dir"
    )

    # Include paths for dependencies
    if [[ "$INTEGER_CLASS" == "boostmp" ]]; then
        emcc_flags+=("-I$DEPS_DIR/boost")
    else
        emcc_flags+=("-I$DEPS_DIR/gmp-wasm/include")
    fi

    # Link flags
    local link_flags=(
        "-sALLOW_MEMORY_GROWTH=1"
        "-sMAXIMUM_MEMORY=4GB"
        "-sSTACK_SIZE=1MB"
        "-sEXPORT_ES6=1"
        "-sFILESYSTEM=0"
    )

    # Thread support
    if [[ "$ENABLE_THREADS" == true ]]; then
        emcc_flags+=("-pthread")
        link_flags+=("-pthread" "-sPTHREAD_POOL_SIZE=4")
    fi

    # Mode-specific flags
    if [[ "$BUILD_MODE" == "standalone" ]]; then
        # Standalone module with JS glue code
        link_flags+=(
            "-sMODULARIZE=1"
            "-sEXPORT_NAME=SymEngine"
            "-sENVIRONMENT=web,node,worker"
        )
        # Bundle WASM into JS if requested
        if [[ "$SINGLE_FILE" == true ]]; then
            link_flags+=("-sSINGLE_FILE=1")
        fi
        local output_file="$output_dir/symengine.js"
    else
        # SIDE_MODULE for dynamic linking with other projects
        link_flags+=(
            "-sSIDE_MODULE=1"
            "-sEXPORT_ALL=1"
            "--no-entry"
        )
        local output_file="$output_dir/symengine.wasm"
    fi

    # Embind support
    if [[ "$WITH_EMBIND" == true ]]; then
        emcc_flags+=("-lembind")

        # Verify embind bindings exist
        check_embind_bindings

        # Compile the embind wrapper
        log_info "Compiling embind bindings..."
        em++ "${emcc_flags[@]}" \
            -c "$SCRIPT_DIR/src/bindings.cpp" \
            -o "$BUILD_DIR/bindings.o"

        link_flags+=("$BUILD_DIR/bindings.o")
    fi

    # Libraries to link
    local libs=()
    if [[ "$BUILD_MODE" == "side" ]]; then
        # For side modules, use --whole-archive to export all symbols
        libs+=("-Wl,--whole-archive" "$symengine_lib" "-Wl,--no-whole-archive")
    else
        libs+=("$symengine_lib")
    fi
    if [[ "$INTEGER_CLASS" == "gmp" ]]; then
        libs+=("$DEPS_DIR/gmp-wasm/lib/libgmp.a")
    fi

    # Final link
    log_info "Linking WebAssembly module..."
    em++ "${emcc_flags[@]}" \
        "${link_flags[@]}" \
        "${libs[@]}" \
        -o "$output_file"

    log_success "WebAssembly module built: $output_file"

    # Generate TypeScript declarations if standalone
    if [[ "$BUILD_MODE" == "standalone" ]]; then
        generate_typescript_declarations
    fi

    # Print summary
    echo ""
    log_info "Build Summary:"
    echo "  Mode: $BUILD_MODE"
    echo "  Integer Class: $INTEGER_CLASS"
    echo "  Build Type: $BUILD_TYPE"
    echo "  Threads: $ENABLE_THREADS"
    echo "  Embind: $WITH_EMBIND"
    echo "  Single File: $SINGLE_FILE"
    echo "  Output: $output_file"

    if [[ -f "$output_dir/symengine.wasm" ]]; then
        local wasm_size
        wasm_size=$(du -h "$output_dir/symengine.wasm" | cut -f1)
        echo "  WASM Size: $wasm_size"
    fi
}

check_embind_bindings() {
    local bindings_file="$SCRIPT_DIR/src/bindings.cpp"

    if [[ ! -f "$bindings_file" ]]; then
        die "Embind bindings not found at $bindings_file"
    fi
}

generate_typescript_declarations() {
    local ts_file="$INSTALL_PREFIX/symengine.d.ts"
    cp "$SCRIPT_DIR/src/symengine.d.ts" "$ts_file"
    log_info "TypeScript declarations installed: $ts_file"
}

# =============================================================================
# Main
# =============================================================================

main() {
    parse_args "$@"

    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║           SymEngine WebAssembly Build System                 ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""

    # Setup
    check_command cmake
    check_command curl
    check_command tar

    if [[ "$ARCH" == "unknown" ]]; then
        # ---- wasm32-unknown-unknown path (via wasi-sdk) ----
        setup_wasi_sdk

        # Install dependencies if requested or needed
        local need_deps_unknown=false
        if [[ "$INSTALL_DEPS" == true ]]; then
            need_deps_unknown=true
        elif [[ ! -d "$SYMENGINE_SRC" ]]; then
            need_deps_unknown=true
        elif [[ "$INTEGER_CLASS" == "gmp" ]] && [[ ! -f "$DEPS_DIR/gmp-wasm-unknown/lib/libgmp.a" ]]; then
            need_deps_unknown=true
        elif [[ "$INTEGER_CLASS" == "boostmp" ]] && [[ ! -d "$DEPS_DIR/boost" ]]; then
            need_deps_unknown=true
        fi

        if [[ "$need_deps_unknown" == true ]]; then
            install_dependencies_unknown
        fi

        # Build SymEngine
        if [[ "$SKIP_SYMENGINE" != true ]]; then
            build_symengine_lib_unknown
            build_wasm_unknown_module
        fi
    else
        # ---- wasm32-unknown-emscripten path (existing) ----
        setup_emscripten

        # Install dependencies if requested or needed
        local need_deps=false
        if [[ "$INSTALL_DEPS" == true ]]; then
            need_deps=true
        elif [[ ! -d "$SYMENGINE_SRC" ]]; then
            need_deps=true
        elif [[ "$INTEGER_CLASS" == "gmp" ]] && [[ ! -f "$DEPS_DIR/gmp-wasm/lib/libgmp.a" ]]; then
            need_deps=true
        elif [[ "$INTEGER_CLASS" == "boostmp" ]] && [[ ! -d "$DEPS_DIR/boost" ]]; then
            need_deps=true
        fi

        if [[ "$need_deps" == true ]]; then
            install_dependencies
        fi

        # Build SymEngine
        if [[ "$SKIP_SYMENGINE" != true ]]; then
            build_symengine_lib
            build_wasm_module
        fi
    fi

    echo ""
    log_success "Build complete!"
}

main "$@"
