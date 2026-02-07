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

// ===================== Version =====================

#[wasm_bindgen]
pub fn symengine_version_str() -> String {
    symengine::version_str()
}

// ===================== Core operations =====================

#[wasm_bindgen]
pub fn expand(expr: &str) -> String {
    symengine::Expr::parse(expr).expand().to_string()
}

#[wasm_bindgen]
pub fn differentiate(expr: &str, var: &str) -> String {
    let e = symengine::Expr::parse(expr);
    let v = symengine::Expr::symbol(var);
    e.diff(&v).to_string()
}

/// Substitute `var` → `value` in `expr`.
#[wasm_bindgen]
pub fn substitute(expr: &str, var: &str, value: &str) -> String {
    let e = symengine::Expr::parse(expr);
    let from = symengine::Expr::symbol(var);
    let to = symengine::Expr::parse(value);
    e.subs(&from, &to).to_string()
}

/// Numerical evaluation to 53-bit precision (double).
#[wasm_bindgen]
pub fn evalf(expr: &str) -> String {
    symengine::Expr::parse(expr).evalf(53).to_string()
}

/// Return free symbols in the expression, comma-separated.
#[wasm_bindgen]
pub fn free_symbols(expr: &str) -> String {
    symengine::Expr::parse(expr).free_symbols().join(", ")
}

/// Solve polynomial equation `expr = 0` for `var`. Returns solutions comma-separated.
#[wasm_bindgen]
pub fn solve_poly(expr: &str, var: &str) -> String {
    let e = symengine::Expr::parse(expr);
    let v = symengine::Expr::symbol(var);
    e.solve_poly(&v).join(", ")
}

// ===================== Arithmetic =====================

#[wasm_bindgen]
pub fn add(a: &str, b: &str) -> String {
    symengine::Expr::parse(a).add(&symengine::Expr::parse(b)).to_string()
}

#[wasm_bindgen]
pub fn sub(a: &str, b: &str) -> String {
    symengine::Expr::parse(a).sub(&symengine::Expr::parse(b)).to_string()
}

#[wasm_bindgen]
pub fn mul(a: &str, b: &str) -> String {
    symengine::Expr::parse(a).mul(&symengine::Expr::parse(b)).to_string()
}

#[wasm_bindgen]
pub fn div(a: &str, b: &str) -> String {
    symengine::Expr::parse(a).div(&symengine::Expr::parse(b)).to_string()
}

#[wasm_bindgen]
pub fn pow(base: &str, exp: &str) -> String {
    symengine::Expr::parse(base).pow(&symengine::Expr::parse(exp)).to_string()
}

#[wasm_bindgen]
pub fn neg(expr: &str) -> String {
    symengine::Expr::parse(expr).neg().to_string()
}

#[wasm_bindgen]
pub fn sym_abs(expr: &str) -> String {
    symengine::Expr::parse(expr).abs().to_string()
}

// ===================== Trigonometric =====================
// Rust fn names prefixed with `sym_` to avoid clashing with C math symbols
// in libc.a.  The `js_name` attribute keeps clean names for JavaScript.

#[wasm_bindgen]
pub fn sym_sin(expr: &str) -> String {
    symengine::Expr::parse(expr).sin().to_string()
}

#[wasm_bindgen]
pub fn sym_cos(expr: &str) -> String {
    symengine::Expr::parse(expr).cos().to_string()
}

#[wasm_bindgen]
pub fn sym_tan(expr: &str) -> String {
    symengine::Expr::parse(expr).tan().to_string()
}

#[wasm_bindgen]
pub fn sym_asin(expr: &str) -> String {
    symengine::Expr::parse(expr).asin().to_string()
}

#[wasm_bindgen]
pub fn sym_acos(expr: &str) -> String {
    symengine::Expr::parse(expr).acos().to_string()
}

#[wasm_bindgen]
pub fn sym_atan(expr: &str) -> String {
    symengine::Expr::parse(expr).atan().to_string()
}

// ===================== Hyperbolic =====================

#[wasm_bindgen]
pub fn sym_sinh(expr: &str) -> String {
    symengine::Expr::parse(expr).sinh().to_string()
}

#[wasm_bindgen]
pub fn sym_cosh(expr: &str) -> String {
    symengine::Expr::parse(expr).cosh().to_string()
}

#[wasm_bindgen]
pub fn sym_tanh(expr: &str) -> String {
    symengine::Expr::parse(expr).tanh().to_string()
}

// ===================== Exponential / Logarithmic =====================

#[wasm_bindgen]
pub fn sym_exp(expr: &str) -> String {
    symengine::Expr::parse(expr).exp().to_string()
}

#[wasm_bindgen]
pub fn sym_log(expr: &str) -> String {
    symengine::Expr::parse(expr).log().to_string()
}

#[wasm_bindgen]
pub fn sym_sqrt(expr: &str) -> String {
    symengine::Expr::parse(expr).sqrt().to_string()
}

// ===================== Special functions =====================

#[wasm_bindgen]
pub fn sym_gamma(expr: &str) -> String {
    symengine::Expr::parse(expr).gamma().to_string()
}

#[wasm_bindgen]
pub fn sym_zeta(expr: &str) -> String {
    symengine::Expr::parse(expr).zeta().to_string()
}

#[wasm_bindgen]
pub fn sym_erf(expr: &str) -> String {
    symengine::Expr::parse(expr).erf().to_string()
}

#[wasm_bindgen]
pub fn sym_lambertw(expr: &str) -> String {
    symengine::Expr::parse(expr).lambertw().to_string()
}

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

/// Return "numerator | denominator" of the expression.
#[wasm_bindgen]
pub fn numer_denom(expr: &str) -> String {
    let (n, d) = symengine::Expr::parse(expr).numer_denom();
    format!("{} | {}", n.to_string(), d.to_string())
}

/// Coefficient of var^n in expr.
#[wasm_bindgen]
pub fn coeff(expr: &str, var: &str, n: i32) -> String {
    let e = symengine::Expr::parse(expr);
    let x = symengine::Expr::symbol(var);
    let ni = symengine::Expr::integer(n);
    e.coeff(&x, &ni).to_string()
}

// ===================== String representations =====================

#[wasm_bindgen]
pub fn to_latex(expr: &str) -> String {
    symengine::Expr::parse(expr).to_latex()
}

#[wasm_bindgen]
pub fn to_mathml(expr: &str) -> String {
    symengine::Expr::parse(expr).to_mathml()
}

#[wasm_bindgen]
pub fn to_ccode(expr: &str) -> String {
    symengine::Expr::parse(expr).to_ccode()
}

#[wasm_bindgen]
pub fn to_jscode(expr: &str) -> String {
    symengine::Expr::parse(expr).to_jscode()
}

// ===================== Matrix operations =====================

/// Compute the determinant of a symbolic matrix.
/// Elements are given as comma-separated expressions, row-major.
/// Example: matrix_det(2, 2, "a, b, c, d") → "a*d - b*c"
#[wasm_bindgen]
pub fn matrix_det(rows: u32, cols: u32, elements_csv: &str) -> String {
    let elems: Vec<symengine::Expr> = elements_csv
        .split(',')
        .map(|s| symengine::Expr::parse(s.trim()))
        .collect();
    let m = symengine::Matrix::from_vec(rows, cols, &elems);
    m.det().to_string()
}

/// Multiply two matrices. Elements are comma-separated, row-major.
/// Returns the result matrix as a string.
#[wasm_bindgen]
pub fn matrix_mul(
    rows_a: u32, cols_a: u32, a_csv: &str,
    rows_b: u32, cols_b: u32, b_csv: &str,
) -> String {
    let ea: Vec<symengine::Expr> = a_csv.split(',').map(|s| symengine::Expr::parse(s.trim())).collect();
    let eb: Vec<symengine::Expr> = b_csv.split(',').map(|s| symengine::Expr::parse(s.trim())).collect();
    let ma = symengine::Matrix::from_vec(rows_a, cols_a, &ea);
    let mb = symengine::Matrix::from_vec(rows_b, cols_b, &eb);
    ma.mul(&mb).to_string()
}

/// Invert a square matrix. Elements are comma-separated, row-major.
#[wasm_bindgen]
pub fn matrix_inv(rows: u32, cols: u32, elements_csv: &str) -> String {
    let elems: Vec<symengine::Expr> = elements_csv
        .split(',')
        .map(|s| symengine::Expr::parse(s.trim()))
        .collect();
    let m = symengine::Matrix::from_vec(rows, cols, &elems);
    m.inv().to_string()
}

/// Transpose a matrix. Elements are comma-separated, row-major.
#[wasm_bindgen]
pub fn matrix_transpose(rows: u32, cols: u32, elements_csv: &str) -> String {
    let elems: Vec<symengine::Expr> = elements_csv
        .split(',')
        .map(|s| symengine::Expr::parse(s.trim()))
        .collect();
    let m = symengine::Matrix::from_vec(rows, cols, &elems);
    m.transpose().to_string()
}
