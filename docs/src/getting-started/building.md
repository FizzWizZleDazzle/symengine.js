# Building from Source

## Using the Build Script

The simplest way to build:

```bash
./build_wasm.sh --mode=standalone --with-embind
```

### Build Script Options

| Option | Description |
|--------|-------------|
| `--mode=standalone` | Build with JS glue code (default) |
| `--mode=side` | Build pure WASM for dynamic linking |
| `--integer=boostmp` | Use Boost multiprecision (default, no GMP) |
| `--integer=gmp` | Use GMP (faster, GPL licensed) |
| `--build-type=Release` | Release build (default) |
| `--build-type=Debug` | Debug build with symbols |
| `--build-type=MinSizeRel` | Optimize for size |
| `--threads` | Enable pthread support |
| `--with-embind` | Include JavaScript bindings |
| `--clean` | Clean before building |
| `--install-deps` | Download dependencies |

## Using Make

```bash
# Standalone module (default)
make standalone

# Side module for dynamic linking
make side

# Both modes
make both

# With GMP instead of boostmp
make standalone-gmp

# Debug build
make debug

# Optimized for size
make minsize
```

## Using CMake Directly

```bash
mkdir build && cd build

# Configure
emcmake cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DSYMENGINE_WASM_MODE=STANDALONE \
    -DINTEGER_CLASS=boostmp \
    -DSYMENGINE_WASM_EMBIND=ON

# Build
emmake make -j$(nproc)
```

## Output Files

After building, the `dist/` directory contains:

| File | Description |
|------|-------------|
| `symengine.js` | JavaScript glue code (ES6 module) |
| `symengine.wasm` | WebAssembly binary |
| `symengine.d.ts` | TypeScript declarations |

For side module builds, only `symengine.wasm` is produced.
