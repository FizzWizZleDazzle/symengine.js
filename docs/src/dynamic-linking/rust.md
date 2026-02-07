# Rust Integration

Link SymEngine WASM with your Rust WebAssembly project.

> **Tip**: If you are using **Trunk** and `wasm-bindgen` with the
> `wasm32-unknown-unknown` target, see the dedicated
> [Rust + Trunk (wasm32-unknown-unknown)](../rust-wasm-unknown.md) guide instead.
> This page covers the Emscripten-based approach.

## Important Notes

> **Warning**: Rust's WASM target has limited dynamic linking support.
> The `wasm32-unknown-emscripten` target works best for SymEngine integration.

## Project Structure

```
my-rust-wasm/
├── Cargo.toml
├── build.rs
├── src/
│   ├── lib.rs
│   └── symengine.rs
└── deps/
    └── symengine.wasm
```

## Cargo.toml

```toml
[package]
name = "my-rust-wasm"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
# For wasm-bindgen approach (simpler but less integration)
wasm-bindgen = "0.2"

[profile.release]
lto = true
opt-level = "s"
```

## FFI Bindings (symengine.rs)

```rust
//! Raw FFI bindings to SymEngine C API

use std::ffi::{c_char, c_int, c_void, CStr, CString};

#[repr(C)]
pub struct CBasic {
    _data: [u8; 0],
    _marker: std::marker::PhantomData<(*mut u8, std::marker::PhantomPinned)>,
}

extern "C" {
    pub fn basic_new_heap() -> *mut CBasic;
    pub fn basic_free_heap(b: *mut CBasic);
    pub fn basic_str(b: *const CBasic) -> *mut c_char;
    pub fn basic_str_free(s: *mut c_char);
    pub fn symbol_set(b: *mut CBasic, name: *const c_char) -> c_int;
    pub fn basic_parse(b: *mut CBasic, s: *const c_char) -> c_int;
    pub fn basic_diff(
        result: *mut CBasic,
        expr: *const CBasic,
        sym: *const CBasic,
    ) -> c_int;
    pub fn basic_expand(result: *mut CBasic, expr: *const CBasic) -> c_int;
}
```

## Safe Wrapper (lib.rs)

```rust
mod symengine;

use std::ffi::{CStr, CString};
use symengine::*;

pub struct Expr {
    ptr: *mut CBasic,
}

impl Expr {
    pub fn symbol(name: &str) -> Self {
        unsafe {
            let ptr = basic_new_heap();
            let c_name = CString::new(name).unwrap();
            symbol_set(ptr, c_name.as_ptr());
            Self { ptr }
        }
    }

    pub fn parse(s: &str) -> Self {
        unsafe {
            let ptr = basic_new_heap();
            let c_str = CString::new(s).unwrap();
            basic_parse(ptr, c_str.as_ptr());
            Self { ptr }
        }
    }

    pub fn diff(&self, sym: &Expr) -> Self {
        unsafe {
            let result = basic_new_heap();
            basic_diff(result, self.ptr, sym.ptr);
            Self { ptr: result }
        }
    }

    pub fn expand(&self) -> Self {
        unsafe {
            let result = basic_new_heap();
            basic_expand(result, self.ptr);
            Self { ptr: result }
        }
    }

    pub fn to_string(&self) -> String {
        unsafe {
            let s = basic_str(self.ptr);
            let result = CStr::from_ptr(s).to_string_lossy().into_owned();
            basic_str_free(s);
            result
        }
    }
}

impl Drop for Expr {
    fn drop(&mut self) {
        unsafe { basic_free_heap(self.ptr) }
    }
}

// Export to JavaScript
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn differentiate(expr: &str, var: &str) -> String {
    let e = Expr::parse(expr);
    let v = Expr::symbol(var);
    e.diff(&v).to_string()
}
```

## Build Script (build.rs)

```rust
fn main() {
    // Link SymEngine
    println!("cargo:rustc-link-search=native=deps");
    println!("cargo:rustc-link-lib=static=symengine");

    // For Emscripten target
    if std::env::var("TARGET").unwrap().contains("emscripten") {
        println!("cargo:rustc-link-arg=-sMAIN_MODULE=1");
        println!("cargo:rustc-link-arg=-sALLOW_MEMORY_GROWTH=1");
    }
}
```

## Building

```bash
# Use Emscripten target
rustup target add wasm32-unknown-emscripten

# Set Emscripten environment
source /path/to/emsdk/emsdk_env.sh

# Build
cargo build --target wasm32-unknown-emscripten --release
```

## Alternative: Static Library

For simpler integration, build SymEngine as a static library:

```bash
./build_wasm.sh --mode=static
```

Then link in `build.rs`:

```rust
println!("cargo:rustc-link-lib=static=symengine_wasm");
```
