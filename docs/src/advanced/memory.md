# Memory Management

## WASM Memory Model

WebAssembly uses a linear memory model:

```
┌─────────────────────────────────────┐
│            Stack                    │ ← grows down
├─────────────────────────────────────┤
│            Heap                     │ ← grows up
├─────────────────────────────────────┤
│         Static Data                 │
├─────────────────────────────────────┤
│            Code                     │
└─────────────────────────────────────┘
```

## Memory Growth

By default, memory grows automatically:

```javascript
const se = await SymEngine({
    // Default settings
    INITIAL_MEMORY: 16 * 1024 * 1024,  // 16MB
    MAXIMUM_MEMORY: 4 * 1024 * 1024 * 1024  // 4GB
});
```

## Monitoring Memory

```javascript
// Get current memory usage
const pages = se.HEAP8.buffer.byteLength / 65536;
console.log(`Memory pages: ${pages}`);
console.log(`Memory used: ${pages * 64}KB`);
```

## Memory Limits

### Browser Limits

| Browser | Maximum Memory |
|---------|---------------|
| Chrome  | ~4GB |
| Firefox | ~4GB |
| Safari  | ~4GB |
| Mobile  | ~1-2GB |

### 32-bit Constraint

WASM currently uses 32-bit pointers:
- Maximum addressable: 4GB
- Practical limit: ~3.5GB

## Preventing Leaks

SymEngine uses RAII in C++, so most memory is managed automatically.

For explicit cleanup:

```javascript
// Create expressions
const x = se.symbol('x');
const expr = se.parse('x^2');

// Expressions are garbage collected when no longer referenced
// No explicit delete needed
```

## Large Expressions

For very large expressions:

```javascript
// Process in chunks
function processLargeExpression(terms) {
    let result = se.integer(0);

    for (const term of terms) {
        const parsed = se.parse(term);
        result = result.add(parsed);
        // Intermediate results are GC'd
    }

    return result;
}
```

## Out of Memory

Handle memory errors:

```javascript
try {
    const huge = se.parse(veryLargeExpression);
} catch (e) {
    if (e.message.includes('memory')) {
        console.error('Out of memory');
        // Reload the module or reduce input size
    }
}
```
