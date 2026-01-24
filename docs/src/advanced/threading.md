# Threading

## Overview

SymEngine can be built with pthread support for parallel computation.

> **Warning**: Threading in WASM is experimental and has browser restrictions.

## Building with Threads

```bash
./build_wasm.sh --mode=standalone --threads
```

## Requirements

### Browser Requirements

- SharedArrayBuffer support
- Cross-Origin-Opener-Policy: same-origin
- Cross-Origin-Embedder-Policy: require-corp

### Server Headers

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

### HTML Meta Tags (Alternative)

```html
<meta http-equiv="Cross-Origin-Opener-Policy" content="same-origin">
<meta http-equiv="Cross-Origin-Embedder-Policy" content="require-corp">
```

## Usage

Threading is transparent - operations automatically parallelize:

```javascript
const se = await SymEngine();

// Heavy computations may use multiple threads
const result = se.parse(complexExpression).expand();
```

## Thread Pool

Configure the thread pool:

```javascript
const se = await SymEngine({
    // Number of worker threads
    pthreadPoolSize: navigator.hardwareConcurrency
});
```

## Limitations

1. **Initial load slower** - thread setup overhead
2. **Larger binary** - includes pthread runtime
3. **Browser support** - not all browsers support SharedArrayBuffer
4. **Security context** - requires secure context (HTTPS)

## Checking Support

```javascript
function supportsThreads() {
    try {
        new SharedArrayBuffer(1);
        return true;
    } catch (e) {
        return false;
    }
}

if (!supportsThreads()) {
    console.log('Using single-threaded build');
    // Load non-threaded version
}
```

## When to Use

**Use threads when:**
- Processing many large expressions
- Running on desktop browsers
- Server-side Node.js with worker_threads

**Avoid threads when:**
- Mobile browsers
- Simple expressions
- Maximum compatibility needed
