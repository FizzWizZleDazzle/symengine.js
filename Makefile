# =============================================================================
# SymEngine.js Makefile
# =============================================================================
# Convenience wrapper around the build script
#

.PHONY: all standalone side deps clean distclean help test \
       wasm-unknown wasm-unknown-gmp wasm-unknown-clean

# Default: build standalone module with embind
all: standalone

# Download dependencies and SymEngine source
deps:
	./build_wasm.sh --install-deps --skip-symengine

# Build standalone module (MAIN_MODULE with JS glue)
standalone: deps
	./build_wasm.sh --mode=standalone --with-embind

# Build side module (pure WASM for dynamic linking)
side: deps
	./build_wasm.sh --mode=side

# Build both modes
both: standalone side

# Build with GMP instead of boostmp (smaller but requires GMP compilation)
standalone-gmp: deps
	./build_wasm.sh --mode=standalone --integer=gmp --with-embind

side-gmp: deps
	./build_wasm.sh --mode=side --integer=gmp

# Build with thread support
standalone-threads: deps
	./build_wasm.sh --mode=standalone --with-embind --threads

# Debug build
debug: deps
	./build_wasm.sh --mode=standalone --with-embind --build-type=Debug

# Optimized for size
minsize: deps
	./build_wasm.sh --mode=standalone --with-embind --build-type=MinSizeRel

# Build static library for wasm32-unknown-unknown (Rust/Trunk)
wasm-unknown: deps
	./build_wasm.sh --arch=unknown

wasm-unknown-gmp: deps
	./build_wasm.sh --arch=unknown --integer=gmp

wasm-unknown-clean:
	rm -rf build/symengine-wasm-unknown build/gmp-wasm-unknown dist/wasm-unknown

# Clean build artifacts
clean:
	rm -rf build

# Clean everything including dependencies
distclean: clean
	rm -rf deps symengine dist

# Run tests (if available)
test: standalone
	@echo "Testing WASM module..."
	@if command -v node >/dev/null 2>&1; then \
		node examples/test.mjs; \
	else \
		echo "Node.js not found, skipping tests"; \
	fi

# Show help
help:
	@echo "SymEngine.js Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all           - Build standalone module (default)"
	@echo "  deps          - Download dependencies only"
	@echo "  standalone    - Build standalone WASM module with JS glue"
	@echo "  side          - Build side module for dynamic linking"
	@echo "  both          - Build both standalone and side modules"
	@echo "  standalone-gmp- Build with GMP (instead of boost multiprecision)"
	@echo "  side-gmp      - Build side module with GMP"
	@echo "  standalone-threads - Build with pthread support"
	@echo "  debug         - Build debug version"
	@echo "  minsize       - Build optimized for size"
	@echo "  wasm-unknown  - Build static lib for wasm32-unknown-unknown (Rust/Trunk)"
	@echo "  wasm-unknown-gmp - Build wasm-unknown with GMP"
	@echo "  wasm-unknown-clean - Clean wasm-unknown build artifacts"
	@echo "  clean         - Remove build directory"
	@echo "  distclean     - Remove all generated files and dependencies"
	@echo "  test          - Run basic tests"
	@echo "  help          - Show this help"
	@echo ""
	@echo "Environment Variables:"
	@echo "  EMSDK         - Path to Emscripten SDK"
	@echo "  WASI_SDK_PATH - Path to wasi-sdk (for wasm-unknown targets)"
	@echo "  JOBS          - Number of parallel build jobs"
	@echo ""
	@echo "For more options, run: ./build_wasm.sh --help"
