# Dynamic Linking Overview

SymEngine can be built as a **side module** for dynamic linking with other WebAssembly projects.

## What is Dynamic Linking?

WebAssembly supports two types of modules:

| Type | Description |
|------|-------------|
| **Main Module** | Contains runtime, libc, and can load side modules |
| **Side Module** | Pure WASM, no runtime, loaded by main module |

## When to Use Dynamic Linking

- **Multiple WASM libraries**: Share SymEngine across your own WASM code
- **Plugin systems**: Load SymEngine on-demand
- **Rust/C++ projects**: Link SymEngine with your compiled code
- **Code splitting**: Reduce initial load time

## Building for Dynamic Linking

```bash
# Build side module
./build_wasm.sh --mode=side

# Output: dist/symengine.wasm (no .js file)
```

## Architecture

```
┌─────────────────────────────────────┐
│          JavaScript Host            │
├─────────────────────────────────────┤
│         Main Module (.js)           │
│  - Runtime environment              │
│  - Memory management                │
│  - libc / libcxx                    │
├──────────────┬──────────────────────┤
│ Side Module  │    Side Module       │
│ (your code)  │   (symengine.wasm)   │
└──────────────┴──────────────────────┘
```

## Key Concepts

### Shared Memory

All modules share a single `WebAssembly.Memory`:

```javascript
const memory = new WebAssembly.Memory({
    initial: 256,  // 16MB
    maximum: 65536 // 4GB
});
```

### Symbol Resolution

Side modules export symbols that main modules can call:

```javascript
// After loading
const symengine_version = mainModule._symengine_version;
```

### Loading Methods

1. **Build-time**: Link `.wasm` file during compilation
2. **Load-time**: Specify in `dynamicLibraries` array
3. **Runtime**: Use `dlopen()` to load after initialization
