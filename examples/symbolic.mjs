/**
 * Symbolic Manipulation Examples
 *
 * Run with: node examples/symbolic.mjs
 */

import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SymEngine = (await import(join(__dirname, '..', 'dist', 'symengine.js'))).default;

const se = await SymEngine();
console.log('SymEngine.js Symbolic Manipulation Examples\n');

// Expression expansion
console.log('=== Expansion ===\n');

const expansions = [
    '(x + 1)^2',
    '(x + y)^3',
    '(a + b)*(a - b)',
    '(x + 1)*(x + 2)*(x + 3)',
];

for (const expr of expansions) {
    const e = se.parse(expr);
    console.log(`${expr} = ${e.expand()}`);
}

// Substitution
console.log('\n=== Substitution ===\n');

const expr = se.parse('x^2 + 2*x*y + y^2');
console.log(`Original: ${expr}`);
console.log(`x=2: ${expr.subs('x', se.integer(2))}`);
console.log(`y=3: ${expr.subs('y', se.integer(3))}`);
console.log(`x=2, y=3: ${expr.subs('x', se.integer(2)).subs('y', se.integer(3))}`);

// Symbolic substitution
const x = se.symbol('x');
const a = se.symbol('a');
console.log(`\nx → a+1: ${expr.subsExpr(x, se.parse('a + 1'))}`);

// Simplification
console.log('\n=== Simplification ===\n');

const simplifications = [
    'x + x + x',
    'x*x*x',
    '(x^2*y)/(x*y)',
    'sin(x)^2 + cos(x)^2',
];

for (const s of simplifications) {
    const e = se.parse(s);
    console.log(`${s} → ${e.simplify()}`);
}

// Numerical evaluation
console.log('\n=== Numerical Evaluation ===\n');

const numericals = [
    ['pi', se.pi()],
    ['e', se.e()],
    ['sqrt(2)', se.sqrt(se.integer(2))],
    ['log(10)', se.log(se.integer(10))],
    ['sin(pi/4)', se.sin(se.parse('pi/4'))],
    ['cos(pi/3)', se.cos(se.parse('pi/3'))],
];

for (const [name, val] of numericals) {
    console.log(`${name} = ${val.evalFloat().toFixed(10)}`);
}

// Complex numbers
console.log('\n=== Complex Numbers ===\n');

const i = se.i();
console.log(`i = ${i}`);
console.log(`i^2 = ${i.mul(i)}`);

const z = se.complex(3, 4);
console.log(`z = 3 + 4i = ${z}`);

// Code generation
console.log('\n=== Code Generation ===\n');

const codeExpr = se.parse('x^2 + sin(y) + exp(z)');
console.log(`Expression: ${codeExpr}`);
console.log(`C code:    ${codeExpr.toCCode()}`);
console.log(`JS code:   ${codeExpr.toJSCode()}`);
console.log(`LaTeX:     ${codeExpr.toLatex()}`);

// Expression inspection
console.log('\n=== Expression Inspection ===\n');

const inspect = se.parse('x^2 + 2*x + 1');
console.log(`Expression: ${inspect}`);
console.log(`Type: ${inspect.getType()}`);
console.log(`Free symbols: ${inspect.getFreeSymbols().join(', ')}`);
console.log(`Arguments: ${inspect.getArgs().map(a => a.toString()).join(', ')}`);
console.log(`Hash: ${inspect.hash()}`);

// Type checking
console.log('\n=== Type Checking ===\n');

const values = [
    ['x', se.symbol('x')],
    ['42', se.integer(42)],
    ['1/2', se.rational(1, 2)],
    ['3.14', se.float(3.14)],
    ['pi', se.pi()],
    ['x + y', se.parse('x + y')],
    ['x * y', se.parse('x * y')],
    ['x^2', se.parse('x^2')],
    ['sin(x)', se.sin(se.symbol('x'))],
];

for (const [name, val] of values) {
    const types = [];
    if (val.isSymbol()) types.push('Symbol');
    if (val.isInteger()) types.push('Integer');
    if (val.isRational()) types.push('Rational');
    if (val.isNumber()) types.push('Number');
    if (val.isAdd()) types.push('Add');
    if (val.isMul()) types.push('Mul');
    if (val.isPow()) types.push('Pow');
    if (val.isFunction()) types.push('Function');
    console.log(`${name}: ${types.join(', ') || val.getType()}`);
}

// Constants
console.log('\n=== Mathematical Constants ===\n');

const constants = [
    ['pi (π)', se.pi()],
    ['e (Euler\'s number)', se.e()],
    ['i (imaginary unit)', se.i()],
    ['∞ (infinity)', se.oo()],
    ['-∞ (negative infinity)', se.negInf()],
    ['γ (Euler-Mascheroni)', se.eulerGamma()],
    ['C (Catalan)', se.catalan()],
    ['φ (Golden ratio)', se.goldenRatio()],
];

for (const [name, val] of constants) {
    console.log(`${name}: ${val}`);
}
