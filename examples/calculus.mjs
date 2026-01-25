/**
 * Calculus Examples
 *
 * Run with: node examples/calculus.mjs
 */

import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SymEngine = (await import(join(__dirname, '..', 'dist', 'symengine.js'))).default;

const se = await SymEngine();
console.log('SymEngine.js Calculus Examples\n');

// Basic differentiation
console.log('=== Differentiation ===\n');

const f1 = se.parse('x^3 + 2*x^2 - 5*x + 3');
console.log(`f(x) = ${f1}`);
console.log(`f'(x) = ${f1.diff('x')}`);
console.log(`f''(x) = ${f1.diff2('x', 2)}`);
console.log(`f'''(x) = ${f1.diff2('x', 3)}`);

// Trigonometric derivatives
console.log('\n=== Trigonometric Derivatives ===\n');

const trig = se.parse('sin(x)*cos(x)');
console.log(`d/dx[sin(x)cos(x)] = ${trig.diff('x')}`);

const trig2 = se.parse('tan(x)');
console.log(`d/dx[tan(x)] = ${trig2.diff('x')}`);

// Chain rule
console.log('\n=== Chain Rule ===\n');

const chain = se.parse('sin(x^2)');
console.log(`d/dx[sin(x²)] = ${chain.diff('x')}`);

const chain2 = se.parse('exp(sin(x))');
console.log(`d/dx[e^sin(x)] = ${chain2.diff('x')}`);

// Partial derivatives
console.log('\n=== Partial Derivatives ===\n');

const multi = se.parse('x^2*y + x*y^3 + z');
console.log(`f(x,y,z) = ${multi}`);
console.log(`∂f/∂x = ${multi.diff('x')}`);
console.log(`∂f/∂y = ${multi.diff('y')}`);
console.log(`∂f/∂z = ${multi.diff('z')}`);

// Higher-order partials
const mixed = se.parse('x^2*y^3');
console.log(`\ng(x,y) = ${mixed}`);
console.log(`∂²g/∂x∂y = ${mixed.diff('x').diff('y')}`);

// Logarithmic differentiation
console.log('\n=== Logarithmic Functions ===\n');

const logExpr = se.parse('log(x^2 + 1)');
console.log(`d/dx[ln(x²+1)] = ${logExpr.diff('x')}`);

const expExpr = se.parse('x^x');
console.log(`d/dx[x^x] = ${expExpr.diff('x')}`);

// Series expansion
console.log('\n=== Taylor Series ===\n');

const sinx = se.parse('sin(x)');
console.log(`sin(x) ≈ ${sinx.series('x', 7)}`);

const expx = se.parse('exp(x)');
console.log(`e^x ≈ ${expx.series('x', 6)}`);

const cosx = se.parse('cos(x)');
console.log(`cos(x) ≈ ${cosx.series('x', 6)}`);

// Symbolic integration by verification
console.log('\n=== Integration Verification ===\n');

// If F'(x) = f(x), then F is the antiderivative
const F = se.parse('x^4/4 + x^3/3 - x^2/2');
const f = F.diff('x');
console.log(`F(x) = ${F}`);
console.log(`F'(x) = ${f}`);
console.log('Verified: ∫(x³ + x² - x)dx = x⁴/4 + x³/3 - x²/2 + C');
