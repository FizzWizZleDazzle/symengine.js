/**
 * SymEngine.js Test Script
 *
 * Run with: node examples/test.mjs
 */

import { createRequire } from 'module';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { readFileSync } from 'fs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const distDir = join(__dirname, '..', 'dist');

// Dynamic import of the WASM module
async function loadSymEngine() {
    // Check if the module exists
    try {
        const wasmPath = join(distDir, 'symengine.wasm');
        const jsPath = join(distDir, 'symengine.js');

        // For Node.js, we need to handle the ES6 module
        const SymEngineFactory = (await import(jsPath)).default;

        // Initialize the module
        const SymEngine = await SymEngineFactory({
            locateFile: (path) => join(distDir, path)
        });

        return SymEngine;
    } catch (err) {
        console.error('Failed to load SymEngine:', err.message);
        console.error('Make sure you have built the WASM module first:');
        console.error('  ./build_wasm.sh --mode=standalone --with-embind');
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

    console.log('Running tests...\n');

    // Basic arithmetic
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

    test('Differentiation', () => {
        const expr = se.parse('x^3 + 2*x^2 + x');
        const deriv = expr.diff('x');
        assertEquals(deriv.toString(), '1 + 4*x + 3*x**2');
    });

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

    test('Trigonometric functions', () => {
        const x = se.symbol('x');
        const sinx = se.sin(x);
        assertEquals(sinx.toString(), 'sin(x)');
    });

    test('Constants (pi)', () => {
        const pi = se.pi();
        assertEquals(pi.toString(), 'pi');
    });

    test('Logarithm', () => {
        const x = se.symbol('x');
        const logx = se.log(x);
        assertEquals(logx.toString(), 'log(x)');
    });

    test('LaTeX output', () => {
        const expr = se.parse('x^2/2');
        const latex = expr.toLatex();
        // LaTeX output varies, just check it's non-empty
        if (!latex || latex.length === 0) {
            throw new Error('Empty LaTeX output');
        }
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
