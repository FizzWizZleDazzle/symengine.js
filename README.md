# SymEngine.js

WebAssembly build of [SymEngine](https://github.com/symengine/symengine) - a fast symbolic manipulation library.

## Download

Pre-built binaries are available from [GitHub Releases](https://github.com/FizzWizZleDazzle/symengine.js/releases).

Each release includes:
- `symengine.<version>.js` - JavaScript ES6 module with embind bindings
- `symengine.<version>.wasm` - WebAssembly binary
- `symengine.<version>.d.ts` - TypeScript declarations
- `symengine.<version>.side.wasm` - Side module for dynamic linking with Rust/C++

## Usage

```javascript
import SymEngine from './symengine.0-12-0.js';

const se = await SymEngine();

// Parse and manipulate expressions
const expr = se.parse('(x + 1)^3');
console.log(expr.expand().toString());
// Output: 1 + 3*x + 3*x**2 + x**3

// Symbolic differentiation
console.log(expr.diff('x').toString());
// Output: 3*(1 + x)**2

// Evaluate numerically
const result = se.parse('1/2 + 1/4');
console.log(result.evalFloat());
// Output: 0.75
```

## Building from Source

Requires [Emscripten SDK](https://emscripten.org/docs/getting_started/downloads.html).

```bash
# Build standalone module with JavaScript bindings
./build_wasm.sh --mode=standalone --with-embind

# Build side module for dynamic linking
./build_wasm.sh --mode=side

# See all options
./build_wasm.sh --help
```

### Build Options

| Option | Description |
|--------|-------------|
| `--mode=standalone` | Build with JS glue code (default) |
| `--mode=side` | Build pure WASM for dynamic linking |
| `--integer=boostmp` | Use Boost.Multiprecision (default, no GMP) |
| `--integer=gmp` | Use GMP (faster, LGPL licensed) |
| `--with-embind` | Include JavaScript bindings |
| `--build-type=Release` | Release build (default) |
| `--build-type=MinSizeRel` | Optimize for size |

## Dynamic Linking

The side module (`symengine.<version>.side.wasm`) can be dynamically linked with Rust or C++ WebAssembly projects. See [docs/src/dynamic-linking/](docs/src/dynamic-linking/) for details.

## Integer Class

By default, builds use `boostmp` (Boost.Multiprecision) which:
- Has no external dependencies
- Uses only permissive licenses (MIT, BSD, Boost)
- Is header-only

For faster arithmetic with large numbers, use `--integer=gmp` (requires building GMP for WASM, LGPL licensed).

## Automated Builds

GitHub Actions automatically checks for new SymEngine releases weekly and publishes pre-built binaries.

## License

SymEngine is BSD-3-Clause. Boost.Multiprecision is Boost Software License.
