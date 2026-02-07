# Rust + Trunk (`wasm32-unknown-unknown`)

This guide shows how to use SymEngine from a Rust WebAssembly project that
targets **`wasm32-unknown-unknown`** — the standard target used by
[Trunk](https://trunkrs.dev/) and `wasm-bindgen`.

## How It Works

SymEngine is cross-compiled to a static library (`libsymengine.a`) using
**wasi-sdk**'s clang with `--target=wasm32-unknown-unknown`. Your Rust project
links against this `.a` at compile time. Both SymEngine and your Rust code share
the same WASM linear memory, so the C API's heap allocation
(`basic_new_heap()` / `basic_free_heap()`) works correctly.

The C wrapper API (`cwrapper.h`) provides `extern "C"` functions for symbolic
math operations: parsing expressions, differentiation, expansion, arithmetic,
and string conversion.

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| [wasi-sdk](https://github.com/WebAssembly/wasi-sdk/releases) | 20+ | Extract to `/opt/wasi-sdk` or set `WASI_SDK_PATH` |
| [Rust](https://rustup.rs/) | stable | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| wasm32-unknown-unknown target | — | `rustup target add wasm32-unknown-unknown` |
| [Trunk](https://trunkrs.dev/) | 0.17+ | `cargo install trunk` |
| CMake | 3.16+ | System package manager |

## Step 1: Build the Static Library

From the repository root:

```bash
./build_wasm.sh --arch=unknown --install-deps
```

This will:
1. Download SymEngine source and Boost headers
2. Cross-compile SymEngine with wasi-sdk
3. Install artifacts to `dist/wasm-unknown/`

Output structure:
```
dist/wasm-unknown/
├── lib/
│   └── libsymengine.a
└── include/
    └── symengine/
        ├── cwrapper.h
        ├── symengine_config.h
        └── symengine_exception.h
```

To use GMP instead of Boost.Multiprecision:
```bash
./build_wasm.sh --arch=unknown --integer=gmp --install-deps
```

### Build Options

| Flag | Description |
|------|-------------|
| `--arch=unknown` | Target `wasm32-unknown-unknown` (required) |
| `--integer=boostmp` | Use Boost.Multiprecision (default, recommended) |
| `--integer=gmp` | Use GMP (also cross-compiled for wasm) |
| `--build-type=Release` | CMake build type (Release, Debug, MinSizeRel) |
| `--clean` | Clean build directories first |
| `--wasi-sdk=/path` | Override wasi-sdk location |

## Step 2: Set Up Your Rust Project

A complete working example is provided in `examples/rust-trunk/`. The key files
are:

### `Cargo.toml`

```toml
[package]
name = "my-symengine-app"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
wasm-bindgen = "0.2"

[build-dependencies]
cc = "1"

[profile.release]
lto = true
opt-level = "s"
```

### `build.rs`

The build script tells `rustc` where to find `libsymengine.a`:

```rust
use std::env;
use std::path::PathBuf;

fn main() {
    let lib_dir = if let Ok(dir) = env::var("SYMENGINE_LIB_DIR") {
        PathBuf::from(dir)
    } else {
        let manifest = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
        manifest.join("../../dist/wasm-unknown/lib")
    };

    println!("cargo:rustc-link-search=native={}", lib_dir.display());
    println!("cargo:rustc-link-lib=static=symengine");
}
```

You can override the library path:
```bash
SYMENGINE_LIB_DIR=/path/to/dist/wasm-unknown/lib cargo build --target wasm32-unknown-unknown
```

## Step 3: FFI Bindings

Create raw `extern "C"` bindings in `src/symengine_ffi.rs`:

```rust
use std::os::raw::{c_char, c_int};

/// Mirrors CRCPBasic_C from cwrapper.h (WITH_SYMENGINE_RCP=ON).
/// On wasm32: a single pointer = 4 bytes.
#[repr(C)]
pub struct BasicStruct {
    pub data: *mut std::ffi::c_void,
}

extern "C" {
    pub fn basic_new_heap() -> *mut BasicStruct;
    pub fn basic_free_heap(s: *mut BasicStruct);
    pub fn basic_parse(b: *mut BasicStruct, str: *const c_char) -> c_int;
    pub fn symbol_set(b: *mut BasicStruct, name: *const c_char) -> c_int;
    pub fn basic_diff(
        result: *mut BasicStruct,
        expr: *const BasicStruct,
        sym: *const BasicStruct,
    ) -> c_int;
    pub fn basic_expand(result: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_str(b: *const BasicStruct) -> *mut c_char;
    pub fn basic_str_latex(b: *const BasicStruct) -> *mut c_char;
    pub fn basic_str_free(s: *mut c_char);
    pub fn symengine_version() -> *const c_char;
}
```

### Memory Model

- `BasicStruct` contains a single `void*` pointer (`WITH_SYMENGINE_RCP=ON`)
- `basic_new_heap()` allocates on the WASM linear heap
- `basic_free_heap()` frees that allocation
- Strings returned by `basic_str()` must be freed with `basic_str_free()`
- Both Rust and C++ code share the same WASM linear memory

## Step 4: Safe Wrapper

Wrap the unsafe FFI in a safe `Expr` type (see `src/symengine.rs` in the
example):

```rust
pub struct Expr { ptr: *mut BasicStruct }

impl Expr {
    pub fn parse(s: &str) -> Self { /* ... */ }
    pub fn symbol(name: &str) -> Self { /* ... */ }
    pub fn diff(&self, sym: &Expr) -> Self { /* ... */ }
    pub fn expand(&self) -> Self { /* ... */ }
    pub fn to_string(&self) -> String { /* ... */ }
    pub fn to_latex(&self) -> String { /* ... */ }
}

impl Drop for Expr {
    fn drop(&mut self) {
        unsafe { basic_free_heap(self.ptr) }
    }
}
```

## Step 5: `wasm-bindgen` Exports

In `src/lib.rs`, expose functions to JavaScript:

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn differentiate(expr: &str, var: &str) -> String {
    let e = Expr::parse(expr);
    let v = Expr::symbol(var);
    e.diff(&v).to_string()
}
```

## Step 6: Trunk Serve

```bash
cd examples/rust-trunk
trunk serve
```

This compiles your Rust code to WASM, runs `wasm-bindgen`, and serves the
`index.html` on `http://127.0.0.1:8080`.

For a production build:
```bash
trunk build --release
```

## Troubleshooting

### `wasi-sdk not found`
Set the `WASI_SDK_PATH` environment variable or pass `--wasi-sdk=/path/to/wasi-sdk`.

### `libsymengine.a: No such file or directory`
Build the library first: `./build_wasm.sh --arch=unknown --install-deps`

### `undefined symbol: basic_new_heap`
Ensure `build.rs` points to the correct `libsymengine.a` path. Check with:
```bash
ls dist/wasm-unknown/lib/libsymengine.a
```

### `-fno-exceptions` and error handling
The `wasm32-unknown-unknown` build disables C++ exceptions (`-fno-exceptions`).
If SymEngine encounters an error (e.g. invalid expression), `std::terminate()`
is called, which aborts the WASM instance. Validate inputs on the Rust/JS side
before passing them to SymEngine.

### Link errors about `__wasi_*` or WASI imports
Make sure you are using `--target=wasm32-unknown-unknown` (not `wasm32-wasi`)
everywhere. The toolchain file sets this automatically.

### Large binary size
Use `--build-type=MinSizeRel` and `opt-level = "s"` in `Cargo.toml`. Boost.Multiprecision
(`--integer=boostmp`) produces smaller output than GMP for most use cases.
