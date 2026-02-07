# SymEngine.js

**SymEngine.js** is a WebAssembly build of [SymEngine](https://github.com/symengine/symengine), a fast symbolic manipulation library written in C++.

## Features

- **Fast symbolic computation** in the browser and Node.js
- **No dependencies** - pure WebAssembly module
- **Dynamic linking** support for integration with Rust/C++ projects
- **ES6 module** with TypeScript declarations
- **Permissive licensing** when built with `boostmp`

## Quick Example

```javascript
import SymEngine from 'symengine';

const se = await SymEngine();

// Parse and manipulate expressions
const expr = se.parse('(x + 1)^3');
console.log(expr.expand().toString());
// Output: 1 + 3*x + 3*x**2 + x**3

// Symbolic differentiation
const deriv = expr.diff('x');
console.log(deriv.toString());
// Output: 3*(1 + x)**2

// Substitution
const result = expr.subs('x', se.integer(2));
console.log(result.evalFloat());
// Output: 27
```

## Build Targets

| Target | Output | Use Case |
|--------|--------|----------|
| `standalone` | `.js` + `.wasm` | Direct use in JS/TS projects (Emscripten) |
| `side` | `.wasm` only | Dynamic linking with other WASM (Emscripten) |
| `--arch=unknown` | `libsymengine.a` | Static library for Rust/`wasm32-unknown-unknown` |
