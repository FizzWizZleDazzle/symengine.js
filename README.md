# SymEngine.js

WebAssembly build of [SymEngine](https://github.com/symengine/symengine) - a fast symbolic manipulation library.

## Installation

### Direct Import (Browser)

```html
<script type="module">
import SymEngine from 'https://github.com/FizzWizZleDazzle/symengine.js/releases/download/v0.14.0/symengine.0-14-0.js';

const se = await SymEngine();
const expr = se.parse('(x + 1)^2');
console.log(expr.expand().toString()); // 1 + 2*x + x**2
</script>
```

### Download

Pre-built binaries available from [GitHub Releases](https://github.com/FizzWizZleDazzle/symengine.js/releases).

Each release includes:
- `symengine.<version>.js` - Boost MP variant (no native dependencies)
- `symengine.<version>.d.ts` - TypeScript declarations

To use the GMP variant (faster for large integers), build from source with `--integer=gmp`.

## Usage

```javascript
import SymEngine from './symengine.0-14-0.js';

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

## Examples

### Calculus

```javascript
const se = await SymEngine();

// Derivatives
const f = se.parse('x^3 + sin(x)');
console.log(f.diff('x').toString());      // 3*x**2 + cos(x)
console.log(f.diff2('x', 2).toString());  // 6*x - sin(x)

// Partial derivatives
const g = se.parse('x^2*y + y^3');
console.log(g.diff('x').toString());  // 2*x*y
console.log(g.diff('y').toString());  // x**2 + 3*y**2

// Taylor series
const h = se.parse('sin(x)');
console.log(h.series('x', 5).toString());  // x - x**3/6 + x**5/120 + O(x**6)
```

### Trigonometry

```javascript
const se = await SymEngine();
const x = se.symbol('x');

// All trig functions
console.log(se.sin(x).toString());   // sin(x)
console.log(se.cos(x).toString());   // cos(x)
console.log(se.tan(x).toString());   // tan(x)

// Inverse trig
console.log(se.asin(x).toString());  // asin(x)
console.log(se.atan(x).toString());  // atan(x)

// Hyperbolic
console.log(se.sinh(x).toString());  // sinh(x)
console.log(se.cosh(x).toString());  // cosh(x)

// Simplification
const expr = se.parse('sin(x)^2 + cos(x)^2');
console.log(expr.simplify().toString());  // 1
```

### Number Theory

```javascript
const se = await SymEngine();

// Factorials and combinations
console.log(se.factorial(10).toString());    // 3628800
console.log(se.binomial(10, 3).toString());  // 120

// Fibonacci and Lucas
console.log(se.fibonacci(50).toString());    // 12586269025
console.log(se.lucas(50).toString());        // 28143753123

// GCD and LCM
const a = se.integer(48);
const b = se.integer(18);
console.log(se.gcd(a, b).toString());  // 6
console.log(se.lcm(a, b).toString());  // 144

// Prime testing
console.log(se.isPrime(17));      // true
console.log(se.nextPrime(100));   // 101
```

### Code Generation

```javascript
const se = await SymEngine();
const expr = se.parse('x^2 + sin(y)');

// Generate code in different languages
console.log(expr.toCCode());    // pow(x, 2) + sin(y)
console.log(expr.toJSCode());   // Math.pow(x, 2) + Math.sin(y)
console.log(expr.toLatex());    // x^{2} + \sin{y}
console.log(expr.toMathML());   // <math>...</math>
```

## Rust / `wasm32-unknown-unknown`

SymEngine can also be used from Rust WebAssembly projects targeting
`wasm32-unknown-unknown` (the standard target for [Trunk](https://trunkrs.dev/)
and `wasm-bindgen`). A complete working example is in `examples/rust-trunk/`.

```bash
# Build the static library
./build_wasm.sh --arch=unknown --install-deps

# Run the Rust+Trunk demo
cd examples/rust-trunk
trunk serve
```

See the [Rust + Trunk guide](https://fizzwizzledazzle.github.io/symengine.js/rust-wasm-unknown.html) for details.

## Building from Source

Requires [Emscripten SDK](https://emscripten.org/docs/getting_started/downloads.html) for the JavaScript target,
or [wasi-sdk](https://github.com/WebAssembly/wasi-sdk/releases) for the Rust/`wasm32-unknown-unknown` target.

```bash
# Build standalone module with JavaScript bindings
./build_wasm.sh --mode=standalone --with-embind --single-file

# Build static library for Rust
./build_wasm.sh --arch=unknown --install-deps

# See all options
./build_wasm.sh --help
```

### Build Options

| Option | Description |
|--------|-------------|
| `--arch=emscripten` | Target Emscripten (default) |
| `--arch=unknown` | Target `wasm32-unknown-unknown` (static library for Rust) |
| `--mode=standalone` | Build with JS glue code (default, Emscripten only) |
| `--integer=boostmp` | Use Boost.Multiprecision (default, no GMP) |
| `--integer=gmp` | Use GMP (faster, LGPL licensed) |
| `--with-embind` | Include JavaScript bindings (Emscripten only) |
| `--single-file` | Bundle WASM into JS (no separate .wasm file) |
| `--build-type=Release` | Release build (default) |
| `--build-type=MinSizeRel` | Optimize for size |
| `--wasi-sdk=/path` | Override wasi-sdk location (for `--arch=unknown`) |

## Variants

### Boost MP (default)
- No external dependencies
- Uses permissive licenses (MIT, BSD, Boost)
- Good general performance
- ~1.6 MB

### GMP (build from source)
- Uses GNU Multiple Precision library
- Faster for operations with very large integers
- LGPL licensed
- Build with `--integer=gmp`

## Documentation

Full API documentation is available at the [GitHub Pages site](https://fizzwizzledazzle.github.io/symengine.js/).

## Automated Builds

GitHub Actions automatically checks for new SymEngine releases weekly and publishes pre-built binaries.

## License

MIT License. See [LICENSE](LICENSE) for details.

Dependencies:
- SymEngine: BSD-3-Clause
- Boost.Multiprecision: Boost Software License 1.0
- GMP (optional): LGPL v3
