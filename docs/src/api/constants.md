# Constants API

## Mathematical Constants

### pi(): Expr

The mathematical constant π.

```javascript
const pi = se.pi();
console.log(pi.toString());  // "pi"

// Use in expressions
const area = se.pi().mul(r.pow(se.integer(2)));
```

### e(): Expr

Euler's number e ≈ 2.71828.

```javascript
const e = se.e();
console.log(e.toString());  // "E"

// Natural exponential
const exp_x = se.e().pow(x);
// Equivalent to se.exp(x)
```

### i(): Expr

The imaginary unit i = √(-1).

```javascript
const i = se.i();
console.log(i.toString());  // "I"

// Complex number
const complex = se.integer(3).add(se.integer(4).mul(se.i()));
console.log(complex.toString());  // "3 + 4*I"
```

## Numerical Evaluation

Constants can be evaluated numerically:

```javascript
se.pi().evalFloat()  // 3.141592653589793
se.e().evalFloat()   // 2.718281828459045
```

## Using Constants in Expressions

```javascript
// Euler's identity: e^(i*π) + 1 = 0
const euler = se.e()
    .pow(se.i().mul(se.pi()))
    .add(se.integer(1));

// Area of circle
const r = se.symbol('r');
const area = se.pi().mul(r.pow(se.integer(2)));
console.log(area.toString());  // "pi*r**2"

// Derivative of x*e^x
const x = se.symbol('x');
const expr = x.mul(se.exp(x));
console.log(expr.diff('x').toString());
// "exp(x) + x*exp(x)"
```
