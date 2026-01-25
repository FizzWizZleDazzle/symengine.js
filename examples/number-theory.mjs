/**
 * Number Theory Examples
 *
 * Run with: node examples/number-theory.mjs
 */

import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SymEngine = (await import(join(__dirname, '..', 'dist', 'symengine.js'))).default;

const se = await SymEngine();
console.log('SymEngine.js Number Theory Examples\n');

// Factorials
console.log('=== Factorials ===\n');

for (const n of [5, 10, 20, 50]) {
    console.log(`${n}! = ${se.factorial(n)}`);
}

// Binomial coefficients
console.log('\n=== Binomial Coefficients (Pascal\'s Triangle) ===\n');

for (let n = 0; n <= 6; n++) {
    const row = [];
    for (let k = 0; k <= n; k++) {
        row.push(se.binomial(n, k).toString());
    }
    console.log(`n=${n}: ${row.join(' ')}`);
}

// Fibonacci sequence
console.log('\n=== Fibonacci Sequence ===\n');

const fibs = [];
for (let i = 0; i <= 15; i++) {
    fibs.push(se.fibonacci(i).toString());
}
console.log(`F(0..15): ${fibs.join(', ')}`);

// Large Fibonacci
console.log(`\nF(100) = ${se.fibonacci(100)}`);
console.log(`F(200) = ${se.fibonacci(200)}`);

// Lucas numbers
console.log('\n=== Lucas Numbers ===\n');

const lucas = [];
for (let i = 0; i <= 15; i++) {
    lucas.push(se.lucas(i).toString());
}
console.log(`L(0..15): ${lucas.join(', ')}`);

// GCD and LCM
console.log('\n=== GCD and LCM ===\n');

const pairs = [[48, 18], [100, 35], [144, 60], [1001, 91]];
for (const [a, b] of pairs) {
    const ai = se.integer(a);
    const bi = se.integer(b);
    console.log(`gcd(${a}, ${b}) = ${se.gcd(ai, bi)}, lcm(${a}, ${b}) = ${se.lcm(ai, bi)}`);
}

// Prime numbers
console.log('\n=== Prime Numbers ===\n');

const testPrimes = [2, 3, 4, 17, 18, 97, 100, 101, 1009];
for (const n of testPrimes) {
    console.log(`${n} is ${se.isPrime(n) ? 'prime' : 'composite'}`);
}

// Next prime
console.log('\n=== Next Prime ===\n');

for (const n of [10, 100, 1000, 10000]) {
    console.log(`Next prime after ${n}: ${se.nextPrime(n)}`);
}

// Bernoulli numbers
console.log('\n=== Bernoulli Numbers ===\n');

for (let n = 0; n <= 10; n++) {
    console.log(`B(${n}) = ${se.bernoulli(n)}`);
}

// Harmonic numbers
console.log('\n=== Harmonic Numbers ===\n');

for (let n = 1; n <= 8; n++) {
    console.log(`H(${n}) = ${se.harmonic(n)}`);
}

// Modular arithmetic
console.log('\n=== Modular Arithmetic ===\n');

const modPairs = [[17, 5], [100, 7], [123, 11]];
for (const [a, m] of modPairs) {
    const ai = se.integer(a);
    const mi = se.integer(m);
    console.log(`${a} mod ${m} = ${se.mod(ai, mi)}`);
    console.log(`${a} ÷ ${m} = ${se.quotient(ai, mi)} remainder ${se.mod(ai, mi)}`);
}
