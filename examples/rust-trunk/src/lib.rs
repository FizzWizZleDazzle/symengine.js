#[allow(dead_code)]
mod symengine;
mod symengine_ffi;

use wasm_bindgen::prelude::*;

// ---------------------------------------------------------------------------
// C-compatible allocator bridge
// ---------------------------------------------------------------------------
// wasi-libc's dlmalloc is stripped from the shipped libc.a to avoid a
// dual-allocator conflict with Rust's own dlmalloc.  The C/C++ code
// (SymEngine, libc++, libc) calls malloc/free/calloc/realloc which we
// provide here, delegating to Rust's built-in allocator.
//
// We store the usable size just before the returned pointer so that
// free() can reconstruct the Layout.
// ---------------------------------------------------------------------------

const HEADER: usize = 16; // enough room for a usize, keeps 16-byte alignment

#[no_mangle]
pub unsafe extern "C" fn malloc(size: usize) -> *mut u8 {
    if size == 0 {
        return core::ptr::null_mut();
    }
    let total = size + HEADER;
    let layout = core::alloc::Layout::from_size_align_unchecked(total, HEADER);
    let raw = std::alloc::alloc(layout);
    if raw.is_null() {
        return raw;
    }
    *(raw as *mut usize) = size;
    raw.add(HEADER)
}

#[no_mangle]
pub unsafe extern "C" fn free(ptr: *mut u8) {
    if ptr.is_null() {
        return;
    }
    let raw = ptr.sub(HEADER);
    let size = *(raw as *mut usize);
    let total = size + HEADER;
    let layout = core::alloc::Layout::from_size_align_unchecked(total, HEADER);
    std::alloc::dealloc(raw, layout);
}

#[no_mangle]
pub unsafe extern "C" fn calloc(nmemb: usize, size: usize) -> *mut u8 {
    let total_size = match nmemb.checked_mul(size) {
        Some(s) => s,
        None => return core::ptr::null_mut(),
    };
    if total_size == 0 {
        return core::ptr::null_mut();
    }
    let total = total_size + HEADER;
    let layout = core::alloc::Layout::from_size_align_unchecked(total, HEADER);
    let raw = std::alloc::alloc_zeroed(layout);
    if raw.is_null() {
        return raw;
    }
    *(raw as *mut usize) = total_size;
    raw.add(HEADER)
}

#[no_mangle]
pub unsafe extern "C" fn realloc(ptr: *mut u8, new_size: usize) -> *mut u8 {
    if ptr.is_null() {
        return malloc(new_size);
    }
    if new_size == 0 {
        free(ptr);
        return core::ptr::null_mut();
    }
    let raw = ptr.sub(HEADER);
    let old_size = *(raw as *mut usize);
    let old_total = old_size + HEADER;
    let new_total = new_size + HEADER;
    let layout = core::alloc::Layout::from_size_align_unchecked(old_total, HEADER);
    let new_raw = std::alloc::realloc(raw, layout, new_total);
    if new_raw.is_null() {
        return new_raw;
    }
    *(new_raw as *mut usize) = new_size;
    new_raw.add(HEADER)
}

// Internal libc aliases used by wasi-libc internals
#[no_mangle]
pub unsafe extern "C" fn __libc_malloc(size: usize) -> *mut u8 {
    malloc(size)
}
#[no_mangle]
pub unsafe extern "C" fn __libc_free(ptr: *mut u8) {
    free(ptr)
}
#[no_mangle]
pub unsafe extern "C" fn __libc_calloc(nmemb: usize, size: usize) -> *mut u8 {
    calloc(nmemb, size)
}

// ---------------------------------------------------------------------------
// wasm-bindgen exports
// ---------------------------------------------------------------------------

/// Generate a #[wasm_bindgen] unary export: parse expr, call method, return string.
macro_rules! wasm_unary {
    ($name:ident, $method:ident) => {
        #[wasm_bindgen]
        pub fn $name(expr: &str) -> String {
            symengine::Expr::parse(expr).$method().to_string()
        }
    };
}

/// Generate a #[wasm_bindgen] binary export: parse both args, call method, return string.
macro_rules! wasm_binary {
    ($name:ident, $method:ident) => {
        #[wasm_bindgen]
        pub fn $name(a: &str, b: &str) -> String {
            symengine::Expr::parse(a)
                .$method(&symengine::Expr::parse(b))
                .to_string()
        }
    };
}

/// Parse comma-separated expressions into a Matrix.
fn parse_matrix(rows: u32, cols: u32, csv: &str) -> symengine::Matrix {
    let elems: Vec<symengine::Expr> = csv
        .split(',')
        .map(|s| symengine::Expr::parse(s.trim()))
        .collect();
    symengine::Matrix::from_vec(rows, cols, &elems)
}

// ===================== Version =====================

#[wasm_bindgen]
pub fn symengine_version_str() -> String {
    symengine::version_str()
}

// ===================== Core operations =====================

wasm_unary!(expand, expand);

#[wasm_bindgen]
pub fn differentiate(expr: &str, var: &str) -> String {
    let e = symengine::Expr::parse(expr);
    let v = symengine::Expr::symbol(var);
    e.diff(&v).to_string()
}

#[wasm_bindgen]
pub fn substitute(expr: &str, var: &str, value: &str) -> String {
    let e = symengine::Expr::parse(expr);
    let from = symengine::Expr::symbol(var);
    let to = symengine::Expr::parse(value);
    e.subs(&from, &to).to_string()
}

#[wasm_bindgen]
pub fn evalf(expr: &str) -> String {
    symengine::Expr::parse(expr).evalf(53).to_string()
}

#[wasm_bindgen]
pub fn free_symbols(expr: &str) -> String {
    symengine::Expr::parse(expr).free_symbols().join(", ")
}

#[wasm_bindgen]
pub fn solve_poly(expr: &str, var: &str) -> String {
    let e = symengine::Expr::parse(expr);
    let v = symengine::Expr::symbol(var);
    e.solve_poly(&v).join(", ")
}

// ===================== Arithmetic =====================

wasm_binary!(add, add);
wasm_binary!(sub, sub);
wasm_binary!(mul, mul);
wasm_binary!(div, div);
wasm_binary!(pow, pow);
wasm_unary!(neg, neg);
wasm_unary!(sym_abs, abs);

// ===================== Trigonometric =====================
// Rust fn names prefixed with `sym_` to avoid clashing with C math symbols
// in libc.a.

wasm_unary!(sym_sin, sin);
wasm_unary!(sym_cos, cos);
wasm_unary!(sym_tan, tan);
wasm_unary!(sym_asin, asin);
wasm_unary!(sym_acos, acos);
wasm_unary!(sym_atan, atan);

// ===================== Hyperbolic =====================

wasm_unary!(sym_sinh, sinh);
wasm_unary!(sym_cosh, cosh);
wasm_unary!(sym_tanh, tanh);

// ===================== Exponential / Logarithmic =====================

wasm_unary!(sym_exp, exp);
wasm_unary!(sym_log, log);
wasm_unary!(sym_sqrt, sqrt);

// ===================== Special functions =====================

wasm_unary!(sym_gamma, gamma);
wasm_unary!(sym_zeta, zeta);
wasm_unary!(sym_erf, erf);
wasm_unary!(sym_lambertw, lambertw);

// ===================== Number theory =====================

#[wasm_bindgen]
pub fn factorial(n: u32) -> String {
    symengine::factorial(n).to_string()
}

#[wasm_bindgen]
pub fn fibonacci(n: u32) -> String {
    symengine::fibonacci(n).to_string()
}

#[wasm_bindgen]
pub fn gcd(a: &str, b: &str) -> String {
    symengine::gcd(&symengine::Expr::parse(a), &symengine::Expr::parse(b)).to_string()
}

#[wasm_bindgen]
pub fn lcm(a: &str, b: &str) -> String {
    symengine::lcm(&symengine::Expr::parse(a), &symengine::Expr::parse(b)).to_string()
}

#[wasm_bindgen]
pub fn nextprime(n: &str) -> String {
    symengine::nextprime(&symengine::Expr::parse(n)).to_string()
}

#[wasm_bindgen]
pub fn binomial(n: &str, k: u32) -> String {
    symengine::binomial(&symengine::Expr::parse(n), k).to_string()
}

// ===================== Algebraic =====================

#[wasm_bindgen]
pub fn numer_denom(expr: &str) -> String {
    let (n, d) = symengine::Expr::parse(expr).numer_denom();
    format!("{} | {}", n.to_string(), d.to_string())
}

#[wasm_bindgen]
pub fn coeff(expr: &str, var: &str, n: i32) -> String {
    let e = symengine::Expr::parse(expr);
    let x = symengine::Expr::symbol(var);
    let ni = symengine::Expr::integer(n);
    e.coeff(&x, &ni).to_string()
}

// ===================== String representations =====================

wasm_unary!(to_latex, to_latex);
wasm_unary!(to_mathml, to_mathml);
wasm_unary!(to_ccode, to_ccode);
wasm_unary!(to_jscode, to_jscode);

// ===================== Matrix operations =====================

/// Determinant. Elements as CSV, row-major. E.g. matrix_det(2, 2, "a, b, c, d")
#[wasm_bindgen]
pub fn matrix_det(rows: u32, cols: u32, elements_csv: &str) -> String {
    parse_matrix(rows, cols, elements_csv).det().to_string()
}

/// Multiply two matrices (CSV, row-major).
#[wasm_bindgen]
pub fn matrix_mul(
    rows_a: u32, cols_a: u32, a_csv: &str,
    rows_b: u32, cols_b: u32, b_csv: &str,
) -> String {
    let ma = parse_matrix(rows_a, cols_a, a_csv);
    let mb = parse_matrix(rows_b, cols_b, b_csv);
    ma.mul(&mb).to_string()
}

/// Invert a square matrix (CSV, row-major).
#[wasm_bindgen]
pub fn matrix_inv(rows: u32, cols: u32, elements_csv: &str) -> String {
    parse_matrix(rows, cols, elements_csv).inv().to_string()
}

/// Transpose a matrix (CSV, row-major).
#[wasm_bindgen]
pub fn matrix_transpose(rows: u32, cols: u32, elements_csv: &str) -> String {
    parse_matrix(rows, cols, elements_csv).transpose().to_string()
}
