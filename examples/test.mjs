/**
 * SymEngine.js Test Script
 *
 * Run with: node examples/test.mjs
 */

import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const distDir = join(__dirname, '..', 'dist');

// Dynamic import of the WASM module
async function loadSymEngine() {
    try {
        const jsPath = join(distDir, 'symengine.js');
        const SymEngineFactory = (await import(jsPath)).default;
        return await SymEngineFactory();
    } catch (err) {
        console.error('Failed to load SymEngine:', err.message);
        console.error('Make sure you have built the WASM module first:');
        console.error('  ./build_wasm.sh --mode=standalone --with-embind --single-file');
        process.exit(1);
    }
}

async function runTests() {
    console.log('Loading SymEngine WASM module...\n');
    const se = await loadSymEngine();

    console.log(`SymEngine version: ${se.version()}\n`);

    let passed = 0;
    let failed = 0;

    function test(name, fn) {
        try {
            fn();
            console.log(`✓ ${name}`);
            passed++;
        } catch (err) {
            console.error(`✗ ${name}`);
            console.error(`  Error: ${err.message}`);
            failed++;
        }
    }

    function assertEquals(actual, expected, msg) {
        if (actual !== expected) {
            throw new Error(`${msg || 'Assertion failed'}: expected "${expected}", got "${actual}"`);
        }
    }

    function assertIncludes(actual, expected, msg) {
        if (!actual.includes(expected)) {
            throw new Error(`${msg || 'Assertion failed'}: expected "${actual}" to include "${expected}"`);
        }
    }

    console.log('=== Basic Operations ===\n');

    test('Create symbol', () => {
        const x = se.symbol('x');
        assertEquals(x.toString(), 'x');
    });

    test('Create integer', () => {
        const n = se.integer(42);
        assertEquals(n.toString(), '42');
    });

    test('Create rational', () => {
        const r = se.rational(1, 2);
        assertEquals(r.toString(), '1/2');
    });

    test('Addition', () => {
        const x = se.symbol('x');
        const y = se.symbol('y');
        const sum = x.add(y);
        assertEquals(sum.toString(), 'x + y');
    });

    test('Multiplication', () => {
        const x = se.symbol('x');
        const two = se.integer(2);
        const prod = x.mul(two);
        assertEquals(prod.toString(), '2*x');
    });

    test('Power', () => {
        const x = se.symbol('x');
        const two = se.integer(2);
        const pow = x.pow(two);
        assertEquals(pow.toString(), 'x**2');
    });

    test('Parse expression', () => {
        const expr = se.parse('x^2 + 2*x + 1');
        assertEquals(expr.toString(), '1 + 2*x + x**2');
    });

    test('Expand expression', () => {
        const expr = se.parse('(x + 1)^2');
        const expanded = expr.expand();
        assertEquals(expanded.toString(), '1 + 2*x + x**2');
    });

    console.log('\n=== Calculus ===\n');

    test('Differentiation', () => {
        const expr = se.parse('x^3 + 2*x^2 + x');
        const deriv = expr.diff('x');
        assertEquals(deriv.toString(), '1 + 4*x + 3*x**2');
    });

    test('Second derivative', () => {
        const expr = se.parse('x^4');
        const deriv2 = expr.diff2('x', 2);
        assertEquals(deriv2.toString(), '12*x**2');
    });

    test('Partial derivative', () => {
        const expr = se.parse('x^2*y + y^3');
        const dx = expr.diff('x');
        assertEquals(dx.toString(), '2*x*y');
    });

    console.log('\n=== Substitution & Evaluation ===\n');

    test('Substitution', () => {
        const expr = se.parse('x^2 + y');
        const result = expr.subs('x', se.integer(2));
        assertEquals(result.toString(), '4 + y');
    });

    test('Numerical evaluation', () => {
        const expr = se.parse('1/4 + 1/4');
        const result = expr.evalFloat();
        assertEquals(result, 0.5);
    });

    test('Evaluate pi', () => {
        const pi = se.pi();
        const val = pi.evalFloat();
        if (Math.abs(val - Math.PI) > 1e-10) {
            throw new Error(`Expected PI, got ${val}`);
        }
    });

    console.log('\n=== Trigonometric Functions ===\n');

    test('sin(x)', () => {
        const x = se.symbol('x');
        assertEquals(se.sin(x).toString(), 'sin(x)');
    });

    test('cos(x)', () => {
        const x = se.symbol('x');
        assertEquals(se.cos(x).toString(), 'cos(x)');
    });

    test('tan(x)', () => {
        const x = se.symbol('x');
        assertEquals(se.tan(x).toString(), 'tan(x)');
    });

    test('sin(0) = 0', () => {
        const zero = se.integer(0);
        assertEquals(se.sin(zero).toString(), '0');
    });

    test('cos(0) = 1', () => {
        const zero = se.integer(0);
        assertEquals(se.cos(zero).toString(), '1');
    });

    console.log('\n=== Special Functions ===\n');

    test('exp(x)', () => {
        const x = se.symbol('x');
        assertEquals(se.exp(x).toString(), 'exp(x)');
    });

    test('log(x)', () => {
        const x = se.symbol('x');
        assertEquals(se.log(x).toString(), 'log(x)');
    });

    test('sqrt(x)', () => {
        const x = se.symbol('x');
        assertIncludes(se.sqrt(x).toString(), 'x');
    });

    test('gamma function', () => {
        const x = se.symbol('x');
        assertEquals(se.gamma(x).toString(), 'gamma(x)');
    });

    console.log('\n=== Number Theory ===\n');

    test('factorial(5) = 120', () => {
        const f = se.factorial(5);
        assertEquals(f.toString(), '120');
    });

    test('fibonacci(10) = 55', () => {
        const f = se.fibonacci(10);
        assertEquals(f.toString(), '55');
    });

    test('binomial(10, 3) = 120', () => {
        const b = se.binomial(10, 3);
        assertEquals(b.toString(), '120');
    });

    test('gcd(12, 8) = 4', () => {
        const a = se.integer(12);
        const b = se.integer(8);
        assertEquals(se.gcd(a, b).toString(), '4');
    });

    test('isPrime(17) = true', () => {
        assertEquals(se.isPrime(17), true);
    });

    test('isPrime(18) = false', () => {
        assertEquals(se.isPrime(18), false);
    });

    console.log('\n=== Constants ===\n');

    test('pi', () => {
        assertEquals(se.pi().toString(), 'pi');
    });

    test('e (Euler)', () => {
        assertEquals(se.e().toString(), 'E');
    });

    test('i (imaginary)', () => {
        assertEquals(se.i().toString(), 'I');
    });

    test('Euler-Mascheroni gamma', () => {
        assertEquals(se.eulerGamma().toString(), 'EulerGamma');
    });

    console.log('\n=== Output Formats ===\n');

    test('LaTeX output', () => {
        const expr = se.parse('x^2/2');
        const latex = expr.toLatex();
        if (!latex || latex.length === 0) {
            throw new Error('Empty LaTeX output');
        }
    });

    test('C code output', () => {
        const expr = se.parse('sin(x) + cos(y)');
        const code = expr.toCCode();
        assertIncludes(code, 'sin');
        assertIncludes(code, 'cos');
    });

    test('JavaScript code output', () => {
        const expr = se.parse('x^2 + 1');
        const code = expr.toJSCode();
        assertIncludes(code, 'Math.pow');
    });

    // Summary
    console.log(`\n${'─'.repeat(40)}`);
    console.log(`Tests: ${passed} passed, ${failed} failed`);

    if (failed > 0) {
        process.exit(1);
    }
}

runTests().catch(err => {
    console.error('Test runner error:', err);
    process.exit(1);
});
