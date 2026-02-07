# Rust Integration

Use SymEngine from Rust WebAssembly projects.

## Recommended: `wasm32-unknown-unknown` + Trunk

The recommended approach uses `wasm32-unknown-unknown` — the standard Rust WASM
target used by [Trunk](https://trunkrs.dev/) and `wasm-bindgen`. SymEngine is
cross-compiled to a static library (`libsymengine.a`) using wasi-sdk, and your
Rust project links against it at compile time.

**See the full guide: [Rust + Trunk (wasm32-unknown-unknown)](../rust-wasm-unknown.md)**

A complete working example is provided in `examples/rust-trunk/`.

### Quick Start

```bash
# 1. Build the static library
./build_wasm.sh --arch=unknown --install-deps

# 2. Run the example
cd examples/rust-trunk
trunk serve
```

## Alternative: Emscripten Target

Rust also supports `wasm32-unknown-emscripten`, which can dynamically link with
Emscripten-built WASM modules. This approach is more complex and less
well-tested than the `wasm32-unknown-unknown` path above.

```bash
rustup target add wasm32-unknown-emscripten
source /path/to/emsdk/emsdk_env.sh
cargo build --target wasm32-unknown-emscripten --release
```

The Emscripten approach requires `MAIN_MODULE=1` linker flags and has limited
dynamic linking support in Rust. For most use cases, the static library
approach via `wasm32-unknown-unknown` is simpler and more reliable.
