# Expressions API

## Expr Class

The main class for symbolic expressions.

### Constructors

```javascript
// Empty (zero)
new se.Expr()

// From integer
new se.Expr(42)

// From float
new se.Expr(3.14159)

// From string (parsed)
new se.Expr('x^2 + 1')
```

### Methods

#### toString(): string

Returns string representation.

```javascript
se.parse('x^2').toString()  // "x**2"
```

#### toLatex(): string

Returns LaTeX representation.

```javascript
se.parse('x^2/2').toLatex()  // "\\frac{x^{2}}{2}"
```

#### add(other: Expr): Expr

Addition.

```javascript
x.add(y)  // x + y
```

#### sub(other: Expr): Expr

Subtraction.

```javascript
x.sub(y)  // x - y
```

#### mul(other: Expr): Expr

Multiplication.

```javascript
x.mul(y)  // x*y
```

#### div(other: Expr): Expr

Division.

```javascript
x.div(y)  // x/y
```

#### pow(exp: Expr): Expr

Exponentiation.

```javascript
x.pow(se.integer(2))  // x^2
```

#### neg(): Expr

Negation.

```javascript
x.neg()  // -x
```

#### diff(variable: string): Expr

Differentiation with respect to a variable.

```javascript
se.parse('x^3').diff('x')  // 3*x^2
```

#### expand(): Expr

Expands the expression.

```javascript
se.parse('(x+1)^2').expand()  // 1 + 2*x + x^2
```

#### subs(variable: string, value: Expr): Expr

Substitutes a variable with a value.

```javascript
se.parse('x^2 + y').subs('x', se.integer(2))  // 4 + y
```

#### equals(other: Expr): boolean

Symbolic equality check.

```javascript
se.parse('x+1').equals(se.parse('1+x'))  // true
```

#### evalFloat(): number

Evaluates to a floating-point number.

```javascript
se.parse('1/4 + 1/2').evalFloat()  // 0.75
```

Returns `NaN` if the expression contains symbols.
