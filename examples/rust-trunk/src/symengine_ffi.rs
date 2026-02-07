//! Raw FFI bindings to SymEngine's C wrapper API (cwrapper.h).
//!
//! These bindings target the `wasm32-unknown-unknown` static library
//! produced by `build_wasm.sh --arch=unknown`.

use std::os::raw::{c_char, c_int};

/// Mirrors `CRCPBasic_C` from cwrapper.h (WITH_SYMENGINE_RCP=ON).
/// On wasm32 this is a single pointer (4 bytes).
#[repr(C)]
pub struct BasicStruct {
    pub data: *mut std::ffi::c_void,
}

/// The C API uses `basic` = `basic_struct[1]`, which is passed by pointer.
/// In Rust we always work with `*mut BasicStruct`.

extern "C" {
    // Lifecycle
    pub fn basic_new_heap() -> *mut BasicStruct;
    pub fn basic_free_heap(s: *mut BasicStruct);

    // Version
    pub fn symengine_version() -> *const c_char;

    // Construction
    pub fn basic_parse(b: *mut BasicStruct, str: *const c_char) -> c_int;
    pub fn symbol_set(b: *mut BasicStruct, name: *const c_char) -> c_int;
    pub fn integer_set_si(b: *mut BasicStruct, i: i32) -> c_int;

    // Arithmetic
    pub fn basic_add(
        s: *mut BasicStruct,
        a: *const BasicStruct,
        b: *const BasicStruct,
    ) -> c_int;
    pub fn basic_sub(
        s: *mut BasicStruct,
        a: *const BasicStruct,
        b: *const BasicStruct,
    ) -> c_int;
    pub fn basic_mul(
        s: *mut BasicStruct,
        a: *const BasicStruct,
        b: *const BasicStruct,
    ) -> c_int;
    pub fn basic_div(
        s: *mut BasicStruct,
        a: *const BasicStruct,
        b: *const BasicStruct,
    ) -> c_int;
    pub fn basic_pow(
        s: *mut BasicStruct,
        a: *const BasicStruct,
        b: *const BasicStruct,
    ) -> c_int;

    // Calculus
    pub fn basic_diff(
        result: *mut BasicStruct,
        expr: *const BasicStruct,
        sym: *const BasicStruct,
    ) -> c_int;

    // Transformation
    pub fn basic_expand(result: *mut BasicStruct, a: *const BasicStruct) -> c_int;

    // String representations
    pub fn basic_str(b: *const BasicStruct) -> *mut c_char;
    pub fn basic_str_latex(b: *const BasicStruct) -> *mut c_char;
    pub fn basic_str_free(s: *mut c_char);
}
