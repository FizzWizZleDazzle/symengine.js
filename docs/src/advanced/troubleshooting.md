# Troubleshooting

## Common Issues

### Module fails to load

**Error:** `Failed to load symengine.wasm`

**Solutions:**
1. Check file path is correct
2. Ensure server has correct MIME type for `.wasm`
3. Check CORS headers

```javascript
// Debug loading
const se = await SymEngine({
    locateFile: (path, prefix) => {
        console.log('Loading:', path, 'from:', prefix);
        return prefix + path;
    }
});
```

### "Out of memory"

**Solutions:**
1. Increase maximum memory
2. Process expressions in smaller chunks
3. Check for memory leaks in your code

```javascript
const se = await SymEngine({
    MAXIMUM_MEMORY: 512 * 1024 * 1024  // 512MB limit
});
```

### "SharedArrayBuffer not available"

**Cause:** Threading requires secure context.

**Solutions:**
1. Use HTTPS
2. Add required headers (see Threading section)
3. Use non-threaded build

### Parse errors

**Error:** `Invalid expression`

**Solutions:**
1. Check syntax (use `^` or `**` for power)
2. Ensure all parentheses match
3. Escape special characters

```javascript
// Correct
se.parse('x^2 + 1')
se.parse('x**2 + 1')

// Incorrect
se.parse('x² + 1')  // Unicode not supported
```

### Side module linking fails

**Error:** `Unresolved symbol`

**Solutions:**
1. Use `MAIN_MODULE=1` (not `=2`)
2. Check all dependencies are linked
3. Verify symbol names match

## Debug Build

Build with debug info:

```bash
./build_wasm.sh --build-type=Debug
```

Enable assertions:

```javascript
const se = await SymEngine({
    ASSERTIONS: 1
});
```

## Browser DevTools

### Memory profiling

1. Open DevTools → Memory tab
2. Take heap snapshot
3. Look for detached WASM objects

### Performance profiling

1. Open DevTools → Performance tab
2. Record while running computations
3. Look for long WASM frames

## `wasm32-unknown-unknown` Issues

### `RuntimeError: memory access out of bounds` (allocator conflict)

**Cause:** Both wasi-libc and Rust ship their own dlmalloc. Two allocators
managing the same heap corrupt memory.

**Solution:** The build script strips dlmalloc from libc.a and the Rust example
provides malloc/free/calloc/realloc from Rust's allocator. If you are writing
your own project, see `examples/rust-trunk/src/lib.rs` for the allocator bridge.

### `RuntimeError: unreachable` in `__wasm_call_dtors`

**Cause:** wasm-bindgen's "command" pattern calls `__wasm_call_ctors` /
`__wasm_call_dtors` around every export invocation. C++ global destructors
destroy SymEngine's static constants, then subsequent calls crash.

**Solution:** Stub `__cxa_atexit` as a no-op to prevent destructor registration.
See `examples/rust-trunk/wasi_stub.c`.

### Duplicate symbol `erf` (or `sin`, `cos`, etc.)

**Cause:** wasm-bindgen export names conflict with C library math functions in
libc.a.

**Solution:** Prefix Rust function names with `sym_` (e.g., `sym_sin`,
`sym_erf`). Do not use `#[wasm_bindgen(js_name = "...")]` — it still creates
conflicting wasm export names.

### `-fno-exceptions` and error handling

The `wasm32-unknown-unknown` build disables C++ exceptions. If SymEngine
encounters an error (e.g., invalid expression), `std::terminate()` is called,
which traps the WASM instance. Validate inputs on the Rust/JS side before
passing them to SymEngine.

## Reporting Issues

Include:
1. Browser/Node version
2. Build configuration
3. Minimal reproduction code
4. Error message with stack trace

```javascript
try {
    // Your code
} catch (e) {
    console.error('Error:', e.message);
    console.error('Stack:', e.stack);
}
```
