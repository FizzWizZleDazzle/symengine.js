# Build Options

## Integer Class

### boostmp (Default)

Uses Boost.Multiprecision for arbitrary precision integers.

```bash
./build_wasm.sh --integer=boostmp
```

**Pros:**
- No external dependencies
- All permissive licenses (MIT, BSD, Boost)
- Header-only, simple to build

**Cons:**
- Slower for large integers
- Some advanced features disabled

### gmp

Uses GNU Multiple Precision library.

```bash
./build_wasm.sh --integer=gmp
```

**Pros:**
- Faster arithmetic
- Full feature support

**Cons:**
- LGPL license
- Requires compiling GMP for WASM
- Larger binary size

## Build Types

### Release (Default)

```bash
./build_wasm.sh --build-type=Release
```

Optimizations: `-O2`

### MinSizeRel

```bash
./build_wasm.sh --build-type=MinSizeRel
```

Optimizations: `-Os` (optimize for size)

### Debug

```bash
./build_wasm.sh --build-type=Debug
```

Includes debug symbols, assertions enabled.

## CMake Options

| Option | Default | Description |
|--------|---------|-------------|
| `SYMENGINE_WASM_MODE` | STANDALONE | STANDALONE, SIDE_MODULE, or STATIC |
| `SYMENGINE_WASM_EMBIND` | ON | Include JavaScript bindings |
| `SYMENGINE_WASM_ES6` | ON | Export as ES6 module |
| `SYMENGINE_WASM_THREADS` | OFF | Enable pthread support |
| `SYMENGINE_WASM_SIMD` | OFF | Enable SIMD optimizations |
| `SYMENGINE_WASM_EXCEPTIONS` | ON | Enable C++ exceptions |

## Memory Settings

```cmake
set(SYMENGINE_WASM_INITIAL_MEMORY "16MB")
set(SYMENGINE_WASM_MAXIMUM_MEMORY "4GB")
set(SYMENGINE_WASM_STACK_SIZE "1MB")
```

## Emscripten Flags Reference

Key flags used in the build:

```
-sALLOW_MEMORY_GROWTH=1    # Dynamic memory
-sMAXIMUM_MEMORY=4GB       # Memory limit
-sMODULARIZE=1             # ES6-compatible
-sEXPORT_ES6=1             # ES6 module output
-sFILESYSTEM=0             # No virtual filesystem
-lembind                    # JavaScript bindings
```
