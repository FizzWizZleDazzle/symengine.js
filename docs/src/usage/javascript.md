# JavaScript/TypeScript Usage

## ES6 Module Import

```javascript
import SymEngine from './symengine.js';

const se = await SymEngine();
```

## TypeScript Support

TypeScript declarations are included:

```typescript
import SymEngine, { Expr, SymEngineModule } from './symengine.js';

const se: SymEngineModule = await SymEngine();

const x: Expr = se.symbol('x');
const result: string = x.pow(se.integer(2)).toString();
```

## Module Configuration

```javascript
const se = await SymEngine({
    // Custom path to .wasm file
    locateFile: (path, prefix) => `/assets/${path}`,

    // Pre-loaded WASM binary
    wasmBinary: await fetch('/symengine.wasm').then(r => r.arrayBuffer()),

    // Callback when ready
    onRuntimeInitialized: () => console.log('Ready!')
});
```

## Working with Expressions

### The Expr Class

All symbolic expressions are wrapped in the `Expr` class:

```javascript
// Create from constructor
const a = new se.Expr(42);        // integer
const b = new se.Expr(3.14);      // float
const c = new se.Expr('x^2 + 1'); // parsed expression

// Create from factory functions
const x = se.symbol('x');
const n = se.integer(100);
const r = se.rational(22, 7);
```

### Method Chaining

```javascript
const result = se.symbol('x')
    .pow(se.integer(2))
    .add(se.integer(1))
    .mul(se.integer(2))
    .expand();

console.log(result.toString());
// "2 + 2*x**2"
```

### Comparison

```javascript
const a = se.parse('x + 1');
const b = se.parse('1 + x');

a.equals(b);  // true (symbolic equality)
```
