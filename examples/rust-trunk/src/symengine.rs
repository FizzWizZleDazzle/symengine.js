//! Safe Rust wrapper around SymEngine's C API.

use crate::symengine_ffi::*;
use std::ffi::{CStr, CString};
use std::os::raw::c_int;

/// A symbolic expression backed by SymEngine.
pub struct Expr {
    ptr: *mut BasicStruct,
}

unsafe impl Send for Expr {}

// ---------------------------------------------------------------------------
// Helper: call an FFI function that takes (*mut result, *const a) → c_int
// ---------------------------------------------------------------------------
macro_rules! unary_op {
    ($name:ident, $ffi:ident) => {
        pub fn $name(&self) -> Self {
            unsafe {
                let r = basic_new_heap();
                $ffi(r, self.ptr);
                Self { ptr: r }
            }
        }
    };
}

macro_rules! binary_op {
    ($name:ident, $ffi:ident) => {
        pub fn $name(&self, other: &Expr) -> Self {
            unsafe {
                let r = basic_new_heap();
                $ffi(r, self.ptr, other.ptr);
                Self { ptr: r }
            }
        }
    };
}

macro_rules! const_fn {
    ($name:ident, $ffi:ident) => {
        pub fn $name() -> Self {
            unsafe {
                let ptr = basic_new_heap();
                $ffi(ptr);
                Self { ptr }
            }
        }
    };
}

impl Expr {
    // =====================================================================
    // Construction
    // =====================================================================

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

    /// Create an integer from i32.
    pub fn integer(i: i32) -> Self {
        unsafe {
            let ptr = basic_new_heap();
            integer_set_si(ptr, i as _);
            Self { ptr }
        }
    }

    /// Create an integer from a decimal string.
    pub fn integer_from_str(s: &str) -> Self {
        unsafe {
            let ptr = basic_new_heap();
            let c = CString::new(s).expect("integer string contains null byte");
            integer_set_str(ptr, c.as_ptr());
            Self { ptr }
        }
    }

    /// Create a rational p/q.
    pub fn rational(p: i32, q: i32) -> Self {
        unsafe {
            let ptr = basic_new_heap();
            rational_set_si(ptr, p as _, q as _);
            Self { ptr }
        }
    }

    /// Create a real double.
    pub fn real_double(d: f64) -> Self {
        unsafe {
            let ptr = basic_new_heap();
            real_double_set_d(ptr, d);
            Self { ptr }
        }
    }

    // =====================================================================
    // Constants
    // =====================================================================
    const_fn!(zero, basic_const_zero);
    const_fn!(one, basic_const_one);
    const_fn!(minus_one, basic_const_minus_one);
    const_fn!(imaginary_unit, basic_const_I);
    const_fn!(pi, basic_const_pi);
    const_fn!(e_constant, basic_const_E);
    const_fn!(euler_gamma, basic_const_EulerGamma);
    const_fn!(catalan, basic_const_Catalan);
    const_fn!(golden_ratio, basic_const_GoldenRatio);
    const_fn!(infinity, basic_const_infinity);
    const_fn!(neg_infinity, basic_const_neginfinity);
    const_fn!(complex_infinity, basic_const_complex_infinity);
    const_fn!(nan, basic_const_nan);

    // =====================================================================
    // Arithmetic
    // =====================================================================
    binary_op!(add, basic_add);
    binary_op!(sub, basic_sub);
    binary_op!(mul, basic_mul);
    binary_op!(div, basic_div);
    binary_op!(pow, basic_pow);
    unary_op!(neg, basic_neg);
    unary_op!(abs, basic_abs);
    unary_op!(expand, basic_expand);

    // =====================================================================
    // Trigonometric
    // =====================================================================
    unary_op!(sin, basic_sin);
    unary_op!(cos, basic_cos);
    unary_op!(tan, basic_tan);
    unary_op!(asin, basic_asin);
    unary_op!(acos, basic_acos);
    unary_op!(atan, basic_atan);
    unary_op!(csc, basic_csc);
    unary_op!(sec, basic_sec);
    unary_op!(cot, basic_cot);

    // =====================================================================
    // Hyperbolic
    // =====================================================================
    unary_op!(sinh, basic_sinh);
    unary_op!(cosh, basic_cosh);
    unary_op!(tanh, basic_tanh);
    unary_op!(asinh, basic_asinh);
    unary_op!(acosh, basic_acosh);
    unary_op!(atanh, basic_atanh);

    // =====================================================================
    // Exponential / Logarithmic
    // =====================================================================
    unary_op!(exp, basic_exp);
    unary_op!(log, basic_log);
    unary_op!(sqrt, basic_sqrt);
    unary_op!(cbrt, basic_cbrt);

    // =====================================================================
    // Special functions
    // =====================================================================
    unary_op!(gamma, basic_gamma);
    unary_op!(loggamma, basic_loggamma);
    unary_op!(zeta, basic_zeta);
    unary_op!(dirichlet_eta, basic_dirichlet_eta);
    unary_op!(erf, basic_erf);
    unary_op!(erfc, basic_erfc);
    unary_op!(lambertw, basic_lambertw);
    binary_op!(beta, basic_beta);

    // =====================================================================
    // Rounding / sign
    // =====================================================================
    unary_op!(floor, basic_floor);
    unary_op!(ceiling, basic_ceiling);
    unary_op!(sign, basic_sign);

    // =====================================================================
    // Calculus
    // =====================================================================
    pub fn diff(&self, sym: &Expr) -> Self {
        unsafe {
            let r = basic_new_heap();
            basic_diff(r, self.ptr, sym.ptr);
            Self { ptr: r }
        }
    }

    // =====================================================================
    // Substitution & evaluation
    // =====================================================================

    /// Substitute `from` → `to` in the expression.
    pub fn subs(&self, from: &Expr, to: &Expr) -> Self {
        unsafe {
            let r = basic_new_heap();
            basic_subs2(r, self.ptr, from.ptr, to.ptr);
            Self { ptr: r }
        }
    }

    /// Multi-substitution: pairs is [(from1, to1), (from2, to2), ...].
    pub fn subs_map(&self, pairs: &[(&Expr, &Expr)]) -> Self {
        unsafe {
            let map = mapbasicbasic_new();
            for (k, v) in pairs {
                mapbasicbasic_insert(map, k.ptr, v.ptr);
            }
            let r = basic_new_heap();
            basic_subs(r, self.ptr, map);
            mapbasicbasic_free(map);
            Self { ptr: r }
        }
    }

    /// Numerical evaluation to `bits` bits of precision.
    pub fn evalf(&self, bits: u32) -> Self {
        unsafe {
            let r = basic_new_heap();
            basic_evalf(r, self.ptr, bits as _, 0);
            Self { ptr: r }
        }
    }

    // =====================================================================
    // Comparison & type checking
    // =====================================================================

    pub fn eq(&self, other: &Expr) -> bool {
        unsafe { basic_eq(self.ptr, other.ptr) != 0 }
    }

    pub fn neq(&self, other: &Expr) -> bool {
        unsafe { basic_neq(self.ptr, other.ptr) != 0 }
    }

    pub fn is_zero(&self) -> bool {
        unsafe { number_is_zero(self.ptr) != 0 }
    }
    pub fn is_negative(&self) -> bool {
        unsafe { number_is_negative(self.ptr) != 0 }
    }
    pub fn is_positive(&self) -> bool {
        unsafe { number_is_positive(self.ptr) != 0 }
    }
    pub fn is_complex(&self) -> bool {
        unsafe { number_is_complex(self.ptr) != 0 }
    }
    pub fn has_symbol(&self, sym: &Expr) -> bool {
        unsafe { basic_has_symbol(self.ptr, sym.ptr) != 0 }
    }
    pub fn is_number(&self) -> bool {
        unsafe { is_a_Number(self.ptr) != 0 }
    }
    pub fn is_integer(&self) -> bool {
        unsafe { is_a_Integer(self.ptr) != 0 }
    }
    pub fn is_rational(&self) -> bool {
        unsafe { is_a_Rational(self.ptr) != 0 }
    }
    pub fn is_symbol(&self) -> bool {
        unsafe { is_a_Symbol(self.ptr) != 0 }
    }

    // =====================================================================
    // Algebraic
    // =====================================================================

    /// Return (numerator, denominator) of the expression.
    pub fn numer_denom(&self) -> (Self, Self) {
        unsafe {
            let n = basic_new_heap();
            let d = basic_new_heap();
            basic_as_numer_denom(n, d, self.ptr);
            (Self { ptr: n }, Self { ptr: d })
        }
    }

    /// Coefficient of x^n in the expression.
    pub fn coeff(&self, x: &Expr, n: &Expr) -> Self {
        unsafe {
            let r = basic_new_heap();
            basic_coeff(r, self.ptr, x.ptr, n.ptr);
            Self { ptr: r }
        }
    }

    // =====================================================================
    // Free symbols
    // =====================================================================

    /// Return the set of free symbols as a Vec<String>.
    pub fn free_symbols(&self) -> Vec<String> {
        unsafe {
            let set = setbasic_new();
            basic_free_symbols(self.ptr, set);
            let n = setbasic_size(set);
            let mut result = Vec::with_capacity(n);
            let tmp = basic_new_heap();
            for i in 0..n {
                setbasic_get(set, i as c_int, tmp);
                let s = basic_str(tmp);
                result.push(CStr::from_ptr(s).to_string_lossy().into_owned());
                basic_str_free(s);
            }
            basic_free_heap(tmp);
            setbasic_free(set);
            result
        }
    }

    // =====================================================================
    // Solve polynomial
    // =====================================================================

    /// Solve a polynomial equation (self = 0) for the given symbol.
    /// Returns solutions as Vec<String>.
    pub fn solve_poly(&self, sym: &Expr) -> Vec<String> {
        unsafe {
            let set = setbasic_new();
            basic_solve_poly(set, self.ptr, sym.ptr);
            let n = setbasic_size(set);
            let mut result = Vec::with_capacity(n);
            let tmp = basic_new_heap();
            for i in 0..n {
                setbasic_get(set, i as c_int, tmp);
                let s = basic_str(tmp);
                result.push(CStr::from_ptr(s).to_string_lossy().into_owned());
                basic_str_free(s);
            }
            basic_free_heap(tmp);
            setbasic_free(set);
            result
        }
    }

    // =====================================================================
    // String representations
    // =====================================================================

    pub fn to_string(&self) -> String {
        unsafe {
            let s = basic_str(self.ptr);
            let result = CStr::from_ptr(s).to_string_lossy().into_owned();
            basic_str_free(s);
            result
        }
    }

    pub fn to_latex(&self) -> String {
        unsafe {
            let s = basic_str_latex(self.ptr);
            let result = CStr::from_ptr(s).to_string_lossy().into_owned();
            basic_str_free(s);
            result
        }
    }

    pub fn to_mathml(&self) -> String {
        unsafe {
            let s = basic_str_mathml(self.ptr);
            let result = CStr::from_ptr(s).to_string_lossy().into_owned();
            basic_str_free(s);
            result
        }
    }

    pub fn to_ccode(&self) -> String {
        unsafe {
            let s = basic_str_ccode(self.ptr);
            let result = CStr::from_ptr(s).to_string_lossy().into_owned();
            basic_str_free(s);
            result
        }
    }

    pub fn to_jscode(&self) -> String {
        unsafe {
            // basic_str_jscode takes *mut because of C API quirk
            let s = basic_str_jscode(self.ptr);
            let result = CStr::from_ptr(s).to_string_lossy().into_owned();
            basic_str_free(s);
            result
        }
    }

    pub fn to_julia(&self) -> String {
        unsafe {
            let s = basic_str_julia(self.ptr);
            let result = CStr::from_ptr(s).to_string_lossy().into_owned();
            basic_str_free(s);
            result
        }
    }

    /// Internal: get raw pointer (for matrix operations).
    pub(crate) fn as_ptr(&self) -> *mut BasicStruct {
        self.ptr
    }
}

impl Drop for Expr {
    fn drop(&mut self) {
        unsafe { basic_free_heap(self.ptr) }
    }
}

impl Clone for Expr {
    fn clone(&self) -> Self {
        unsafe {
            let ptr = basic_new_heap();
            basic_assign(ptr, self.ptr);
            Self { ptr }
        }
    }
}

// =========================================================================
// Number theory (free functions)
// =========================================================================

pub fn gcd(a: &Expr, b: &Expr) -> Expr {
    unsafe {
        let r = basic_new_heap();
        ntheory_gcd(r, a.as_ptr(), b.as_ptr());
        Expr { ptr: r }
    }
}

pub fn lcm(a: &Expr, b: &Expr) -> Expr {
    unsafe {
        let r = basic_new_heap();
        ntheory_lcm(r, a.as_ptr(), b.as_ptr());
        Expr { ptr: r }
    }
}

pub fn nextprime(a: &Expr) -> Expr {
    unsafe {
        let r = basic_new_heap();
        ntheory_nextprime(r, a.as_ptr());
        Expr { ptr: r }
    }
}

pub fn fibonacci(n: u32) -> Expr {
    unsafe {
        let r = basic_new_heap();
        ntheory_fibonacci(r, n as _);
        Expr { ptr: r }
    }
}

pub fn lucas(n: u32) -> Expr {
    unsafe {
        let r = basic_new_heap();
        ntheory_lucas(r, n as _);
        Expr { ptr: r }
    }
}

pub fn factorial(n: u32) -> Expr {
    unsafe {
        let r = basic_new_heap();
        ntheory_factorial(r, n as _);
        Expr { ptr: r }
    }
}

pub fn binomial(n: &Expr, k: u32) -> Expr {
    unsafe {
        let r = basic_new_heap();
        ntheory_binomial(r, n.as_ptr(), k as _);
        Expr { ptr: r }
    }
}

// =========================================================================
// Dense matrix wrapper
// =========================================================================

pub struct Matrix {
    ptr: *mut CDenseMatrix,
}

impl Matrix {
    /// Create a matrix from a flat vector of expressions, given rows × cols.
    pub fn from_vec(rows: u32, cols: u32, elements: &[Expr]) -> Self {
        unsafe {
            let mat = dense_matrix_new_rows_cols(rows as _, cols as _);
            for (i, e) in elements.iter().enumerate() {
                let r = (i as u32) / cols;
                let c = (i as u32) % cols;
                dense_matrix_set_basic(mat, r as _, c as _, e.as_ptr());
            }
            Self { ptr: mat }
        }
    }

    pub fn rows(&self) -> u32 {
        unsafe { dense_matrix_rows(self.ptr) as u32 }
    }

    pub fn cols(&self) -> u32 {
        unsafe { dense_matrix_cols(self.ptr) as u32 }
    }

    pub fn get(&self, r: u32, c: u32) -> Expr {
        unsafe {
            let e = basic_new_heap();
            dense_matrix_get_basic(e, self.ptr, r as _, c as _);
            Expr { ptr: e }
        }
    }

    pub fn det(&self) -> Expr {
        unsafe {
            let r = basic_new_heap();
            dense_matrix_det(r, self.ptr);
            Expr { ptr: r }
        }
    }

    pub fn inv(&self) -> Self {
        unsafe {
            let r = dense_matrix_new();
            dense_matrix_inv(r, self.ptr);
            Self { ptr: r }
        }
    }

    pub fn transpose(&self) -> Self {
        unsafe {
            let r = dense_matrix_new();
            dense_matrix_transpose(r, self.ptr);
            Self { ptr: r }
        }
    }

    pub fn add(&self, other: &Matrix) -> Self {
        unsafe {
            let r = dense_matrix_new();
            dense_matrix_add_matrix(r, self.ptr, other.ptr);
            Self { ptr: r }
        }
    }

    pub fn mul(&self, other: &Matrix) -> Self {
        unsafe {
            let r = dense_matrix_new();
            dense_matrix_mul_matrix(r, self.ptr, other.ptr);
            Self { ptr: r }
        }
    }

    pub fn mul_scalar(&self, s: &Expr) -> Self {
        unsafe {
            let r = dense_matrix_new();
            dense_matrix_mul_scalar(r, self.ptr, s.as_ptr());
            Self { ptr: r }
        }
    }

    pub fn to_string(&self) -> String {
        unsafe {
            let s = dense_matrix_str(self.ptr);
            let result = CStr::from_ptr(s).to_string_lossy().into_owned();
            basic_str_free(s);
            result
        }
    }
}

impl Drop for Matrix {
    fn drop(&mut self) {
        unsafe { dense_matrix_free(self.ptr) }
    }
}

/// Return the SymEngine version string.
pub fn version_str() -> String {
    unsafe {
        let s = symengine_version();
        CStr::from_ptr(s).to_string_lossy().into_owned()
    }
}
