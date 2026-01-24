# Quick Start

## Basic Usage

```javascript
import SymEngine from './symengine.js';

// Initialize the module
const se = await SymEngine();

// Check version
console.log('SymEngine version:', se.version());
```

## Creating Expressions

### Symbols

```javascript
const x = se.symbol('x');
const y = se.symbol('y');
```

### Numbers

```javascript
const n = se.integer(42);
const r = se.rational(1, 2);  // 1/2
const f = se.float(3.14159);
```

### Parsing Strings

```javascript
const expr = se.parse('x^2 + 2*x + 1');
```

## Arithmetic Operations

```javascript
const x = se.symbol('x');
const two = se.integer(2);

// Addition
x.add(two)  // x + 2

// Subtraction
x.sub(two)  // x - 2

// Multiplication
x.mul(two)  // 2*x

// Division
x.div(two)  // x/2

// Power
x.pow(two)  // x^2

// Negation
x.neg()     // -x
```

## Common Operations

### Expand

```javascript
const expr = se.parse('(x + 1)^2');
expr.expand().toString();
// "1 + 2*x + x**2"
```

### Differentiate

```javascript
const expr = se.parse('x^3 + sin(x)');
expr.diff('x').toString();
// "3*x**2 + cos(x)"
```

### Substitute

```javascript
const expr = se.parse('x^2 + y');
expr.subs('x', se.integer(3)).toString();
// "9 + y"
```

### Evaluate

```javascript
const expr = se.parse('1/4 + 3/4');
expr.evalFloat();
// 1.0
```

## Output Formats

```javascript
const expr = se.parse('x^2/2');

// String representation
expr.toString();   // "x**2/2"

// LaTeX format
expr.toLatex();    // "\\frac{x^{2}}{2}"
```
