//! Safe Rust wrapper around SymEngine's C API.

use crate::symengine_ffi::*;
use std::ffi::{CStr, CString};

/// A symbolic expression backed by SymEngine.
pub struct Expr {
    ptr: *mut BasicStruct,
}

// Safety: SymEngine is compiled without thread support for wasm32-unknown-unknown,
// but WASM is single-threaded anyway.
unsafe impl Send for Expr {}

impl Expr {
    /// Parse a mathematical expression string (e.g. `"x**2 + 2*x + 1"`).
    pub fn parse(s: &str) -> Self {
        unsafe {
            let ptr = basic_new_heap();
            let c_str = CString::new(s).expect("expression contains null byte");
            basic_parse(ptr, c_str.as_ptr());
            Self { ptr }
        }
    }

    /// Create a symbolic variable.
    pub fn symbol(name: &str) -> Self {
        unsafe {
            let ptr = basic_new_heap();
            let c_name = CString::new(name).expect("symbol name contains null byte");
            symbol_set(ptr, c_name.as_ptr());
            Self { ptr }
        }
    }

    /// Differentiate with respect to a symbol.
    pub fn diff(&self, sym: &Expr) -> Self {
        unsafe {
            let result = basic_new_heap();
            basic_diff(result, self.ptr, sym.ptr);
            Self { ptr: result }
        }
    }

    /// Expand the expression.
    pub fn expand(&self) -> Self {
        unsafe {
            let result = basic_new_heap();
            basic_expand(result, self.ptr);
            Self { ptr: result }
        }
    }

    /// Add two expressions.
    pub fn add(&self, other: &Expr) -> Self {
        unsafe {
            let result = basic_new_heap();
            basic_add(result, self.ptr, other.ptr);
            Self { ptr: result }
        }
    }

    /// Convert to a string representation.
    pub fn to_string(&self) -> String {
        unsafe {
            let s = basic_str(self.ptr);
            let result = CStr::from_ptr(s).to_string_lossy().into_owned();
            basic_str_free(s);
            result
        }
    }

    /// Convert to a LaTeX string.
    pub fn to_latex(&self) -> String {
        unsafe {
            let s = basic_str_latex(self.ptr);
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

/// Return the SymEngine version string.
pub fn version_str() -> String {
    unsafe {
        let s = symengine_version();
        CStr::from_ptr(s).to_string_lossy().into_owned()
    }
}
