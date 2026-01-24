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
#   --mode=<standalone|side>   Build mode (default: standalone)
#   --integer=<gmp|boostmp>    Integer class to use (default: boostmp)
#   --build-type=<Release|Debug|MinSizeRel>  Build type (default: Release)
#   --threads                   Enable thread safety (experimental)
#   --clean                     Clean build directories before building
#   --install-deps              Download and build dependencies
#   --skip-symengine            Only build dependencies, skip SymEngine
#   --with-embind               Include embind JavaScript bindings
#   --help                      Show this help message
#
# Environment variables:
#   EMSDK                       Path to Emscripten SDK (auto-detected if not set)
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
BUILD_MODE="standalone"   # standalone (MAIN_MODULE) or side (SIDE_MODULE)
INTEGER_CLASS="boostmp"   # gmp or boostmp
BUILD_TYPE="Release"
ENABLE_THREADS=false
CLEAN_BUILD=false
INSTALL_DEPS=false
SKIP_SYMENGINE=false
WITH_EMBIND=false

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
    head -n 25 "$0" | tail -n 23 | sed 's/^#//'
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
        curl -fsSL "https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.xz" | \
            tar xJ -C "$DEPS_DIR"
    fi

    cd "$gmp_build_dir"

    # Configure GMP for Emscripten
    # --disable-assembly is CRITICAL for WebAssembly
    emconfigure "$gmp_src/configure" \
        --prefix="$gmp_install_dir" \
        --host=none \
        --build=none \
        --disable-assembly \
        --enable-static \
        --disable-shared \
        --enable-cxx \
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
        # Standalone MAIN_MODULE - includes runtime and can load side modules
        link_flags+=(
            "-sMAIN_MODULE=2"
            "-sMODULARIZE=1"
            "-sEXPORT_NAME=SymEngine"
            "-sENVIRONMENT=web,node,worker"
        )
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

        # Create embind wrapper if it doesn't exist
        create_embind_wrapper

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
    echo "  Output: $output_file"

    if [[ -f "$output_dir/symengine.wasm" ]]; then
        local wasm_size
        wasm_size=$(du -h "$output_dir/symengine.wasm" | cut -f1)
        echo "  WASM Size: $wasm_size"
    fi
}

create_embind_wrapper() {
    local bindings_dir="$SCRIPT_DIR/src"
    local bindings_file="$bindings_dir/bindings.cpp"

    if [[ -f "$bindings_file" ]]; then
        return 0
    fi

    log_info "Creating embind bindings source..."
    mkdir -p "$bindings_dir"

    cat > "$bindings_file" << 'EMBIND_EOF'
/**
 * SymEngine Embind Bindings
 * Exposes SymEngine C++ API to JavaScript
 */

#include <emscripten/bind.h>
#include <symengine/symengine_config.h>
#include <symengine/basic.h>
#include <symengine/add.h>
#include <symengine/mul.h>
#include <symengine/pow.h>
#include <symengine/symbol.h>
#include <symengine/integer.h>
#include <symengine/rational.h>
#include <symengine/real_double.h>
#include <symengine/constants.h>
#include <symengine/functions.h>
#include <symengine/derivative.h>
#include <symengine/visitor.h>
#include <symengine/parser.h>
#include <symengine/printers.h>

using namespace emscripten;
using namespace SymEngine;

// Wrapper class for easier JavaScript interaction
class SymEngineExpr {
public:
    RCP<const Basic> expr;

    SymEngineExpr() : expr(integer(0)) {}
    SymEngineExpr(const RCP<const Basic>& e) : expr(e) {}
    SymEngineExpr(int n) : expr(integer(n)) {}
    SymEngineExpr(double d) : expr(real_double(d)) {}
    SymEngineExpr(const std::string& s) : expr(parse(s)) {}

    std::string toString() const {
        return expr->__str__();
    }

    std::string toLatex() const {
        return latex(*expr);
    }

    SymEngineExpr add(const SymEngineExpr& other) const {
        return SymEngineExpr(SymEngine::add(expr, other.expr));
    }

    SymEngineExpr sub(const SymEngineExpr& other) const {
        return SymEngineExpr(SymEngine::sub(expr, other.expr));
    }

    SymEngineExpr mul(const SymEngineExpr& other) const {
        return SymEngineExpr(SymEngine::mul(expr, other.expr));
    }

    SymEngineExpr div(const SymEngineExpr& other) const {
        return SymEngineExpr(SymEngine::div(expr, other.expr));
    }

    SymEngineExpr pow(const SymEngineExpr& exp) const {
        return SymEngineExpr(SymEngine::pow(expr, exp.expr));
    }

    SymEngineExpr neg() const {
        return SymEngineExpr(SymEngine::neg(expr));
    }

    SymEngineExpr diff(const std::string& var) const {
        auto sym = symbol(var);
        return SymEngineExpr(expr->diff(sym));
    }

    SymEngineExpr expand() const {
        return SymEngineExpr(SymEngine::expand(expr));
    }

    SymEngineExpr subs(const std::string& var, const SymEngineExpr& value) const {
        map_basic_basic m;
        m[symbol(var)] = value.expr;
        return SymEngineExpr(expr->subs(m));
    }

    bool equals(const SymEngineExpr& other) const {
        return eq(*expr, *other.expr);
    }

    double evalFloat() const {
        // Try to evaluate to a double
        auto result = evalf(*expr, 53, EvalfDomain::Real);
        if (is_a<RealDouble>(*result)) {
            return down_cast<const RealDouble&>(*result).i;
        }
        return std::nan("");
    }
};

// Factory functions
SymEngineExpr createSymbol(const std::string& name) {
    return SymEngineExpr(symbol(name));
}

SymEngineExpr createInteger(int n) {
    return SymEngineExpr(integer(n));
}

SymEngineExpr createRational(int num, int den) {
    return SymEngineExpr(Rational::from_two_ints(integer(num), integer(den)));
}

SymEngineExpr createFloat(double d) {
    return SymEngineExpr(real_double(d));
}

SymEngineExpr parse_expr(const std::string& s) {
    return SymEngineExpr(parse(s));
}

// Constants
SymEngineExpr getPi() { return SymEngineExpr(pi); }
SymEngineExpr getE() { return SymEngineExpr(E); }
SymEngineExpr getI() { return SymEngineExpr(I); }

// Functions
SymEngineExpr symSin(const SymEngineExpr& x) { return SymEngineExpr(sin(x.expr)); }
SymEngineExpr symCos(const SymEngineExpr& x) { return SymEngineExpr(cos(x.expr)); }
SymEngineExpr symTan(const SymEngineExpr& x) { return SymEngineExpr(tan(x.expr)); }
SymEngineExpr symLog(const SymEngineExpr& x) { return SymEngineExpr(log(x.expr)); }
SymEngineExpr symExp(const SymEngineExpr& x) { return SymEngineExpr(exp(x.expr)); }
SymEngineExpr symSqrt(const SymEngineExpr& x) { return SymEngineExpr(sqrt(x.expr)); }
SymEngineExpr symAbs(const SymEngineExpr& x) { return SymEngineExpr(abs(x.expr)); }

std::string getVersion() {
    return SYMENGINE_VERSION;
}

EMSCRIPTEN_BINDINGS(symengine) {
    class_<SymEngineExpr>("Expr")
        .constructor<>()
        .constructor<int>()
        .constructor<double>()
        .constructor<const std::string&>()
        .function("toString", &SymEngineExpr::toString)
        .function("toLatex", &SymEngineExpr::toLatex)
        .function("add", &SymEngineExpr::add)
        .function("sub", &SymEngineExpr::sub)
        .function("mul", &SymEngineExpr::mul)
        .function("div", &SymEngineExpr::div)
        .function("pow", &SymEngineExpr::pow)
        .function("neg", &SymEngineExpr::neg)
        .function("diff", &SymEngineExpr::diff)
        .function("expand", &SymEngineExpr::expand)
        .function("subs", &SymEngineExpr::subs)
        .function("equals", &SymEngineExpr::equals)
        .function("evalFloat", &SymEngineExpr::evalFloat);

    function("symbol", &createSymbol);
    function("integer", &createInteger);
    function("rational", &createRational);
    function("float", &createFloat);
    function("parse", &parse_expr);
    function("version", &getVersion);

    // Constants
    function("pi", &getPi);
    function("e", &getE);
    function("i", &getI);

    // Functions
    function("sin", &symSin);
    function("cos", &symCos);
    function("tan", &symTan);
    function("log", &symLog);
    function("exp", &symExp);
    function("sqrt", &symSqrt);
    function("abs", &symAbs);
}
EMBIND_EOF

    log_success "Embind bindings created at $bindings_file"
}

generate_typescript_declarations() {
    local ts_file="$INSTALL_PREFIX/symengine.d.ts"

    cat > "$ts_file" << 'TS_EOF'
/**
 * SymEngine WebAssembly TypeScript Declarations
 */

export interface Expr {
    toString(): string;
    toLatex(): string;
    add(other: Expr): Expr;
    sub(other: Expr): Expr;
    mul(other: Expr): Expr;
    div(other: Expr): Expr;
    pow(exp: Expr): Expr;
    neg(): Expr;
    diff(variable: string): Expr;
    expand(): Expr;
    subs(variable: string, value: Expr): Expr;
    equals(other: Expr): boolean;
    evalFloat(): number;
}

export interface SymEngineModule {
    Expr: {
        new(): Expr;
        new(value: number): Expr;
        new(expression: string): Expr;
    };

    // Factory functions
    symbol(name: string): Expr;
    integer(n: number): Expr;
    rational(numerator: number, denominator: number): Expr;
    float(value: number): Expr;
    parse(expression: string): Expr;
    version(): string;

    // Constants
    pi(): Expr;
    e(): Expr;
    i(): Expr;

    // Functions
    sin(x: Expr): Expr;
    cos(x: Expr): Expr;
    tan(x: Expr): Expr;
    log(x: Expr): Expr;
    exp(x: Expr): Expr;
    sqrt(x: Expr): Expr;
    abs(x: Expr): Expr;
}

declare function SymEngine(options?: {
    locateFile?: (path: string, prefix: string) => string;
    wasmBinary?: ArrayBuffer;
    onRuntimeInitialized?: () => void;
}): Promise<SymEngineModule>;

export default SymEngine;
TS_EOF

    log_info "TypeScript declarations generated: $ts_file"
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
    setup_emscripten

    # Install dependencies if requested or needed
    if [[ "$INSTALL_DEPS" == true ]] || [[ ! -d "$SYMENGINE_SRC" ]]; then
        install_dependencies
    fi

    # Build SymEngine
    if [[ "$SKIP_SYMENGINE" != true ]]; then
        build_symengine_lib
        build_wasm_module
    fi

    echo ""
    log_success "Build complete!"
}

main "$@"
