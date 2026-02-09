/**
 * SymEngine WebAssembly TypeScript Declarations
 */

export interface Expr {
    // String representations
    toString(): string;
    toLatex(): string;
    toMathML(): string;
    toCCode(): string;
    toJSCode(): string;

    // Arithmetic
    add(other: Expr): Expr;
    sub(other: Expr): Expr;
    mul(other: Expr): Expr;
    div(other: Expr): Expr;
    pow(exp: Expr): Expr;
    neg(): Expr;

    // Calculus
    diff(variable: string): Expr;
    diff2(variable: string, n: number): Expr;

    // Transformation
    expand(): Expr;
    simplify(): Expr;
    subs(variable: string, value: Expr): Expr;
    subsExpr(from: Expr, to: Expr): Expr;

    // Comparison
    equals(other: Expr): boolean;
    notEquals(other: Expr): boolean;

    // Evaluation
    evalFloat(): number;
    evalComplex(): string;

    // Type checking
    isNumber(): boolean;
    isInteger(): boolean;
    isRational(): boolean;
    isSymbol(): boolean;
    isAdd(): boolean;
    isMul(): boolean;
    isPow(): boolean;
    isFunction(): boolean;
    isZero(): boolean;
    isOne(): boolean;
    isNegative(): boolean;
    isPositive(): boolean;
    getType(): string;
    hash(): number;

    // Structure
    getArgs(): Expr[];
    getFreeSymbols(): string[];
    coeff(variable: string, n: number): Expr;

    // Series
    series(variable: string, order: number): Expr;

    // Rewrite
    rewriteAsExp(): Expr;
    rewriteAsSin(): Expr;
    rewriteAsCos(): Expr;
}

export interface SymEngineModule {
    Expr: {
        new(): Expr;
        new(expression: string): Expr;
    };

    // Factory functions
    symbol(name: string): Expr;
    integer(n: number): Expr;
    rational(numerator: number, denominator: number): Expr;
    float(value: number): Expr;
    complex(real: number, imag: number): Expr;
    parse(expression: string): Expr;
    version(): string;

    // Constants
    pi(): Expr;
    e(): Expr;
    i(): Expr;
    oo(): Expr;
    inf(): Expr;
    negInf(): Expr;
    complexInf(): Expr;
    nan(): Expr;
    eulerGamma(): Expr;
    catalan(): Expr;
    goldenRatio(): Expr;
    zero(): Expr;
    one(): Expr;

    // Trigonometric
    sin(x: Expr): Expr;
    cos(x: Expr): Expr;
    tan(x: Expr): Expr;
    cot(x: Expr): Expr;
    sec(x: Expr): Expr;
    csc(x: Expr): Expr;
    asin(x: Expr): Expr;
    acos(x: Expr): Expr;
    atan(x: Expr): Expr;
    acot(x: Expr): Expr;
    asec(x: Expr): Expr;
    acsc(x: Expr): Expr;
    atan2(y: Expr, x: Expr): Expr;

    // Hyperbolic
    sinh(x: Expr): Expr;
    cosh(x: Expr): Expr;
    tanh(x: Expr): Expr;
    coth(x: Expr): Expr;
    sech(x: Expr): Expr;
    csch(x: Expr): Expr;
    asinh(x: Expr): Expr;
    acosh(x: Expr): Expr;
    atanh(x: Expr): Expr;
    acoth(x: Expr): Expr;
    asech(x: Expr): Expr;
    acsch(x: Expr): Expr;

    // Exponential/Logarithmic
    exp(x: Expr): Expr;
    log(x: Expr): Expr;
    ln(x: Expr): Expr;
    logBase(x: Expr, base: Expr): Expr;
    lambertW(x: Expr): Expr;

    // Power/Root
    sqrt(x: Expr): Expr;
    cbrt(x: Expr): Expr;
    root(x: Expr, n: Expr): Expr;

    // Special functions
    abs(x: Expr): Expr;
    sign(x: Expr): Expr;
    floor(x: Expr): Expr;
    ceiling(x: Expr): Expr;
    ceil(x: Expr): Expr;
    truncate(x: Expr): Expr;
    trunc(x: Expr): Expr;
    gamma(x: Expr): Expr;
    loggamma(x: Expr): Expr;
    digamma(x: Expr): Expr;
    trigamma(x: Expr): Expr;
    beta(x: Expr, y: Expr): Expr;
    erf(x: Expr): Expr;
    erfc(x: Expr): Expr;
    zeta(x: Expr): Expr;
    dirichletEta(x: Expr): Expr;

    // Number theory
    factorial(n: number): Expr;
    binomial(n: number, k: number): Expr;
    gcd(a: Expr, b: Expr): Expr;
    lcm(a: Expr, b: Expr): Expr;
    mod(a: Expr, b: Expr): Expr;
    quotient(a: Expr, b: Expr): Expr;
    isPrime(n: number): boolean;
    nextPrime(n: number): number;
    fibonacci(n: number): Expr;
    lucas(n: number): Expr;
    bernoulli(n: number): Expr;
    harmonic(n: number): Expr;

    // Min/Max
    min(a: Expr, b: Expr): Expr;
    max(a: Expr, b: Expr): Expr;

    // Piecewise
    piecewise(expr1: Expr, cond1: Expr, otherwise: Expr): Expr;

    // Comparison (symbolic)
    Lt(a: Expr, b: Expr): Expr;
    Le(a: Expr, b: Expr): Expr;
    Gt(a: Expr, b: Expr): Expr;
    Ge(a: Expr, b: Expr): Expr;
    Eq(a: Expr, b: Expr): Expr;
    Ne(a: Expr, b: Expr): Expr;
}

declare function SymEngine(options?: {
    locateFile?: (path: string, prefix: string) => string;
    wasmBinary?: ArrayBuffer;
    onRuntimeInitialized?: () => void;
}): Promise<SymEngineModule>;

export default SymEngine;
