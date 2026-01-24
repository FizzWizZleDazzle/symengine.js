# Functions API

## Factory Functions

### symbol(name: string): Expr

Creates a symbolic variable.

```javascript
const x = se.symbol('x');
const y = se.symbol('y');
```

### integer(n: number): Expr

Creates an integer.

```javascript
const n = se.integer(42);
const neg = se.integer(-10);
```

### rational(num: number, den: number): Expr

Creates a rational number.

```javascript
const half = se.rational(1, 2);
const third = se.rational(1, 3);
```

### float(value: number): Expr

Creates a floating-point number.

```javascript
const pi_approx = se.float(3.14159);
```

### parse(expression: string): Expr

Parses a string expression.

```javascript
const expr = se.parse('x^2 + 2*x + 1');
```

Supported syntax:
- `+`, `-`, `*`, `/` - arithmetic
- `^` or `**` - exponentiation
- `()` - grouping
- Function calls: `sin(x)`, `log(x)`, etc.

### version(): string

Returns SymEngine version string.

```javascript
console.log(se.version());  // "0.12.0"
```

## Mathematical Functions

### Trigonometric

```javascript
se.sin(x)   // sin(x)
se.cos(x)   // cos(x)
se.tan(x)   // tan(x)
```

### Exponential and Logarithmic

```javascript
se.exp(x)   // e^x
se.log(x)   // ln(x) - natural logarithm
```

### Other

```javascript
se.sqrt(x)  // √x
se.abs(x)   // |x|
```

## Function Examples

```javascript
const x = se.symbol('x');

// Trigonometric identity
const identity = se.sin(x).pow(se.integer(2))
    .add(se.cos(x).pow(se.integer(2)));
console.log(identity.toString());  // sin(x)^2 + cos(x)^2

// Derivative of exp
const deriv = se.exp(x).diff('x');
console.log(deriv.toString());  // exp(x)

// Chain rule
const composed = se.sin(se.exp(x));
console.log(composed.diff('x').toString());
// cos(exp(x))*exp(x)
```
