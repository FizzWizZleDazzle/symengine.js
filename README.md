# SymEngine.js

WebAssembly build of [SymEngine](https://github.com/symengine/symengine) - a fast symbolic manipulation library.

## Installation

### From CDN (Browser)

```html
<script type="module">
import SymEngine from 'https://cdn.jsdelivr.net/gh/FizzWizZleDazzle/symengine.js@latest/dist/symengine.js';

const se = await SymEngine();
const expr = se.parse('(x + 1)^2');
console.log(expr.expand().toString()); // 1 + 2*x + x**2
</script>
```

Or use unpkg:
```javascript
import SymEngine from 'https://unpkg.com/@aspect/symengine.js/dist/symengine.js';
```

### From GitHub Releases

Download pre-built binaries from [GitHub Releases](https://github.com/FizzWizZleDazzle/symengine.js/releases).

Each release includes:
- `symengine.<version>.js` - Boost MP variant (no native dependencies)
- `symengine.<version>.gmp.js` - GMP variant (faster for large integers)
- `symengine.<version>.d.ts` - TypeScript declarations

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

## Building from Source

Requires [Emscripten SDK](https://emscripten.org/docs/getting_started/downloads.html).

```bash
# Build standalone module with JavaScript bindings
./build_wasm.sh --mode=standalone --with-embind --single-file

# See all options
./build_wasm.sh --help
```

### Build Options

| Option | Description |
|--------|-------------|
| `--mode=standalone` | Build with JS glue code (default) |
| `--integer=boostmp` | Use Boost.Multiprecision (default, no GMP) |
| `--integer=gmp` | Use GMP (faster, LGPL licensed) |
| `--with-embind` | Include JavaScript bindings |
| `--single-file` | Bundle WASM into JS (no separate .wasm file) |
| `--build-type=Release` | Release build (default) |
| `--build-type=MinSizeRel` | Optimize for size |

## Variants

### Boost MP (default)
- No external dependencies
- Uses permissive licenses (MIT, BSD, Boost)
- Good general performance
- ~1.3 MB

### GMP
- Uses GNU Multiple Precision library
- Faster for operations with very large integers
- LGPL licensed
- ~1.4 MB

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
