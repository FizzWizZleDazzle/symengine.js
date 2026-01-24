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
        # Standalone module with JS glue code
        link_flags+=(
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

    cat > "$ts_file" << 'TS_EOF'
/**
 * SymEngine WebAssembly TypeScript Declarations
 */

export interface Expr {
    // String representations
    toString(): string;
    toLatex(): string;
    toMathML(): string;
    toCCode(): string;
    toJSCode(): string;

    // Arithmetic
    add(other: Expr): Expr;
    sub(other: Expr): Expr;
    mul(other: Expr): Expr;
    div(other: Expr): Expr;
    pow(exp: Expr): Expr;
    neg(): Expr;

    // Calculus
    diff(variable: string): Expr;
    diff2(variable: string, n: number): Expr;

    // Transformation
    expand(): Expr;
    simplify(): Expr;
    subs(variable: string, value: Expr): Expr;
    subsExpr(from: Expr, to: Expr): Expr;

    // Comparison
    equals(other: Expr): boolean;
    notEquals(other: Expr): boolean;

    // Evaluation
    evalFloat(): number;
    evalComplex(): string;

    // Type checking
    isNumber(): boolean;
    isInteger(): boolean;
    isRational(): boolean;
    isSymbol(): boolean;
    isAdd(): boolean;
    isMul(): boolean;
    isPow(): boolean;
    isFunction(): boolean;
    isZero(): boolean;
    isOne(): boolean;
    isNegative(): boolean;
    isPositive(): boolean;
    getType(): string;
    hash(): number;

    // Structure
    getArgs(): Expr[];
    getFreeSymbols(): string[];
    coeff(variable: string, n: number): Expr;

    // Series
    series(variable: string, order: number): Expr;

    // Rewrite
    rewriteAsExp(): Expr;
    rewriteAsSin(): Expr;
    rewriteAsCos(): Expr;
}

export interface SymEngineModule {
    Expr: {
        new(): Expr;
        new(expression: string): Expr;
    };

    // Factory functions
    symbol(name: string): Expr;
    integer(n: number): Expr;
    rational(numerator: number, denominator: number): Expr;
    float(value: number): Expr;
    complex(real: number, imag: number): Expr;
    parse(expression: string): Expr;
    version(): string;

    // Constants
    pi(): Expr;
    e(): Expr;
    i(): Expr;
    oo(): Expr;
    inf(): Expr;
    negInf(): Expr;
    complexInf(): Expr;
    nan(): Expr;
    eulerGamma(): Expr;
    catalan(): Expr;
    goldenRatio(): Expr;
    zero(): Expr;
    one(): Expr;

    // Trigonometric
    sin(x: Expr): Expr;
    cos(x: Expr): Expr;
    tan(x: Expr): Expr;
    cot(x: Expr): Expr;
    sec(x: Expr): Expr;
    csc(x: Expr): Expr;
    asin(x: Expr): Expr;
    acos(x: Expr): Expr;
    atan(x: Expr): Expr;
    acot(x: Expr): Expr;
    asec(x: Expr): Expr;
    acsc(x: Expr): Expr;
    atan2(y: Expr, x: Expr): Expr;

    // Hyperbolic
    sinh(x: Expr): Expr;
    cosh(x: Expr): Expr;
    tanh(x: Expr): Expr;
    coth(x: Expr): Expr;
    sech(x: Expr): Expr;
    csch(x: Expr): Expr;
    asinh(x: Expr): Expr;
    acosh(x: Expr): Expr;
    atanh(x: Expr): Expr;
    acoth(x: Expr): Expr;
    asech(x: Expr): Expr;
    acsch(x: Expr): Expr;

    // Exponential/Logarithmic
    exp(x: Expr): Expr;
    log(x: Expr): Expr;
    ln(x: Expr): Expr;
    logBase(x: Expr, base: Expr): Expr;
    lambertW(x: Expr): Expr;

    // Power/Root
    sqrt(x: Expr): Expr;
    cbrt(x: Expr): Expr;
    root(x: Expr, n: Expr): Expr;

    // Special functions
    abs(x: Expr): Expr;
    sign(x: Expr): Expr;
    floor(x: Expr): Expr;
    ceiling(x: Expr): Expr;
    ceil(x: Expr): Expr;
    truncate(x: Expr): Expr;
    trunc(x: Expr): Expr;
    gamma(x: Expr): Expr;
    loggamma(x: Expr): Expr;
    digamma(x: Expr): Expr;
    trigamma(x: Expr): Expr;
    beta(x: Expr, y: Expr): Expr;
    erf(x: Expr): Expr;
    erfc(x: Expr): Expr;
    zeta(x: Expr): Expr;
    dirichletEta(x: Expr): Expr;

    // Number theory
    factorial(n: number): Expr;
    binomial(n: number, k: number): Expr;
    gcd(a: Expr, b: Expr): Expr;
    lcm(a: Expr, b: Expr): Expr;
    mod(a: Expr, b: Expr): Expr;
    quotient(a: Expr, b: Expr): Expr;
    isPrime(n: number): boolean;
    nextPrime(n: number): number;
    fibonacci(n: number): Expr;
    lucas(n: number): Expr;
    bernoulli(n: number): Expr;
    harmonic(n: number): Expr;

    // Min/Max
    min(a: Expr, b: Expr): Expr;
    max(a: Expr, b: Expr): Expr;

    // Piecewise
    piecewise(expr1: Expr, cond1: Expr, otherwise: Expr): Expr;

    // Comparison (symbolic)
    Lt(a: Expr, b: Expr): Expr;
    Le(a: Expr, b: Expr): Expr;
    Gt(a: Expr, b: Expr): Expr;
    Ge(a: Expr, b: Expr): Expr;
    Eq(a: Expr, b: Expr): Expr;
    Ne(a: Expr, b: Expr): Expr;
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
