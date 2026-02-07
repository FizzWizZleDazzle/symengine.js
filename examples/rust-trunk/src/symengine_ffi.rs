//! Raw FFI bindings to SymEngine's C wrapper API (cwrapper.h).
//!
//! These bindings target the `wasm32-unknown-unknown` static library
//! produced by `build_wasm.sh --arch=unknown`.

use std::os::raw::{c_char, c_int, c_long, c_ulong, c_void};

/// Mirrors `CRCPBasic_C` from cwrapper.h (WITH_SYMENGINE_RCP=ON).
/// On wasm32 this is a single pointer (4 bytes).
#[repr(C)]
pub struct BasicStruct {
    pub data: *mut c_void,
}

/// Opaque vector of basics.
#[repr(C)]
pub struct CVecBasic {
    _opaque: [u8; 0],
}

/// Opaque set of basics.
#[repr(C)]
pub struct CSetBasic {
    _opaque: [u8; 0],
}

/// Opaque map basic→basic.
#[repr(C)]
pub struct CMapBasicBasic {
    _opaque: [u8; 0],
}

/// Opaque dense matrix.
#[repr(C)]
pub struct CDenseMatrix {
    _opaque: [u8; 0],
}

#[allow(dead_code)]
extern "C" {
    // =========================================================================
    // Lifecycle
    // =========================================================================
    pub fn basic_new_heap() -> *mut BasicStruct;
    pub fn basic_free_heap(s: *mut BasicStruct);
    pub fn basic_assign(a: *mut BasicStruct, b: *const BasicStruct) -> c_int;

    // =========================================================================
    // Version
    // =========================================================================
    pub fn symengine_version() -> *const c_char;

    // =========================================================================
    // Construction — parsing & symbols
    // =========================================================================
    pub fn basic_parse(b: *mut BasicStruct, str: *const c_char) -> c_int;
    pub fn symbol_set(b: *mut BasicStruct, name: *const c_char) -> c_int;
    pub fn integer_set_si(b: *mut BasicStruct, i: c_long) -> c_int;
    pub fn integer_set_str(b: *mut BasicStruct, c: *const c_char) -> c_int;
    pub fn integer_get_si(b: *const BasicStruct) -> c_long;
    pub fn real_double_set_d(b: *mut BasicStruct, d: f64) -> c_int;
    pub fn real_double_get_d(b: *const BasicStruct) -> f64;
    pub fn rational_set_si(b: *mut BasicStruct, i: c_long, j: c_long) -> c_int;

    // =========================================================================
    // Constants
    // =========================================================================
    pub fn basic_const_zero(s: *mut BasicStruct);
    pub fn basic_const_one(s: *mut BasicStruct);
    pub fn basic_const_minus_one(s: *mut BasicStruct);
    pub fn basic_const_I(s: *mut BasicStruct);
    pub fn basic_const_pi(s: *mut BasicStruct);
    pub fn basic_const_E(s: *mut BasicStruct);
    pub fn basic_const_EulerGamma(s: *mut BasicStruct);
    pub fn basic_const_Catalan(s: *mut BasicStruct);
    pub fn basic_const_GoldenRatio(s: *mut BasicStruct);
    pub fn basic_const_infinity(s: *mut BasicStruct);
    pub fn basic_const_neginfinity(s: *mut BasicStruct);
    pub fn basic_const_complex_infinity(s: *mut BasicStruct);
    pub fn basic_const_nan(s: *mut BasicStruct);

    // =========================================================================
    // Arithmetic
    // =========================================================================
    pub fn basic_add(s: *mut BasicStruct, a: *const BasicStruct, b: *const BasicStruct) -> c_int;
    pub fn basic_sub(s: *mut BasicStruct, a: *const BasicStruct, b: *const BasicStruct) -> c_int;
    pub fn basic_mul(s: *mut BasicStruct, a: *const BasicStruct, b: *const BasicStruct) -> c_int;
    pub fn basic_div(s: *mut BasicStruct, a: *const BasicStruct, b: *const BasicStruct) -> c_int;
    pub fn basic_pow(s: *mut BasicStruct, a: *const BasicStruct, b: *const BasicStruct) -> c_int;
    pub fn basic_neg(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_abs(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_expand(result: *mut BasicStruct, a: *const BasicStruct) -> c_int;

    // =========================================================================
    // Trigonometric
    // =========================================================================
    pub fn basic_sin(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_cos(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_tan(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_asin(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_acos(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_atan(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_csc(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_sec(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_cot(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;

    // =========================================================================
    // Hyperbolic
    // =========================================================================
    pub fn basic_sinh(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_cosh(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_tanh(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_asinh(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_acosh(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_atanh(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;

    // =========================================================================
    // Exponential / Logarithmic
    // =========================================================================
    pub fn basic_exp(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_log(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_sqrt(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_cbrt(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;

    // =========================================================================
    // Special functions
    // =========================================================================
    pub fn basic_gamma(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_loggamma(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_zeta(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_dirichlet_eta(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_erf(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_erfc(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_lambertw(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_beta(s: *mut BasicStruct, a: *const BasicStruct, b: *const BasicStruct) -> c_int;
    pub fn basic_polygamma(s: *mut BasicStruct, a: *const BasicStruct, b: *const BasicStruct) -> c_int;

    // =========================================================================
    // Rounding / sign
    // =========================================================================
    pub fn basic_floor(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_ceiling(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn basic_sign(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;

    // =========================================================================
    // Calculus
    // =========================================================================
    pub fn basic_diff(result: *mut BasicStruct, expr: *const BasicStruct, sym: *const BasicStruct) -> c_int;

    // =========================================================================
    // Substitution & evaluation
    // =========================================================================
    pub fn basic_subs2(s: *mut BasicStruct, e: *const BasicStruct, a: *const BasicStruct, b: *const BasicStruct) -> c_int;
    pub fn basic_evalf(s: *mut BasicStruct, b: *const BasicStruct, bits: c_ulong, real: c_int) -> c_int;

    // =========================================================================
    // Comparison & type checking
    // =========================================================================
    pub fn basic_eq(a: *const BasicStruct, b: *const BasicStruct) -> c_int;
    pub fn basic_neq(a: *const BasicStruct, b: *const BasicStruct) -> c_int;
    pub fn number_is_zero(s: *const BasicStruct) -> c_int;
    pub fn number_is_negative(s: *const BasicStruct) -> c_int;
    pub fn number_is_positive(s: *const BasicStruct) -> c_int;
    pub fn number_is_complex(s: *const BasicStruct) -> c_int;
    pub fn basic_has_symbol(e: *const BasicStruct, s: *const BasicStruct) -> c_int;
    pub fn is_a_Number(s: *const BasicStruct) -> c_int;
    pub fn is_a_Integer(s: *const BasicStruct) -> c_int;
    pub fn is_a_Rational(s: *const BasicStruct) -> c_int;
    pub fn is_a_Symbol(s: *const BasicStruct) -> c_int;
    pub fn is_a_Complex(s: *const BasicStruct) -> c_int;
    pub fn is_a_RealDouble(s: *const BasicStruct) -> c_int;

    // =========================================================================
    // Algebraic
    // =========================================================================
    pub fn basic_as_numer_denom(numer: *mut BasicStruct, denom: *mut BasicStruct, x: *const BasicStruct) -> c_int;
    pub fn basic_coeff(c: *mut BasicStruct, b: *const BasicStruct, x: *const BasicStruct, n: *const BasicStruct) -> c_int;

    // =========================================================================
    // String representations
    // =========================================================================
    pub fn basic_str(b: *const BasicStruct) -> *mut c_char;
    pub fn basic_str_latex(b: *const BasicStruct) -> *mut c_char;
    pub fn basic_str_mathml(b: *const BasicStruct) -> *mut c_char;
    pub fn basic_str_ccode(b: *const BasicStruct) -> *mut c_char;
    pub fn basic_str_jscode(b: *mut BasicStruct) -> *mut c_char;
    pub fn basic_str_julia(b: *const BasicStruct) -> *mut c_char;
    pub fn basic_str_free(s: *mut c_char);

    // =========================================================================
    // Number theory
    // =========================================================================
    pub fn ntheory_gcd(s: *mut BasicStruct, a: *const BasicStruct, b: *const BasicStruct) -> c_int;
    pub fn ntheory_lcm(s: *mut BasicStruct, a: *const BasicStruct, b: *const BasicStruct) -> c_int;
    pub fn ntheory_nextprime(s: *mut BasicStruct, a: *const BasicStruct) -> c_int;
    pub fn ntheory_mod(s: *mut BasicStruct, n: *const BasicStruct, d: *const BasicStruct) -> c_int;
    pub fn ntheory_quotient(s: *mut BasicStruct, n: *const BasicStruct, d: *const BasicStruct) -> c_int;
    pub fn ntheory_fibonacci(s: *mut BasicStruct, a: c_ulong) -> c_int;
    pub fn ntheory_lucas(s: *mut BasicStruct, a: c_ulong) -> c_int;
    pub fn ntheory_binomial(s: *mut BasicStruct, a: *const BasicStruct, b: c_ulong) -> c_int;
    pub fn ntheory_factorial(s: *mut BasicStruct, n: c_ulong) -> c_int;
    pub fn ntheory_mod_inverse(b: *mut BasicStruct, a: *const BasicStruct, m: *const BasicStruct) -> c_int;

    // =========================================================================
    // Containers — CVecBasic
    // =========================================================================
    pub fn vecbasic_new() -> *mut CVecBasic;
    pub fn vecbasic_free(self_: *mut CVecBasic);
    pub fn vecbasic_push_back(self_: *mut CVecBasic, value: *const BasicStruct) -> c_int;
    pub fn vecbasic_get(self_: *mut CVecBasic, n: usize, result: *mut BasicStruct) -> c_int;
    pub fn vecbasic_size(self_: *mut CVecBasic) -> usize;

    // =========================================================================
    // Containers — CSetBasic
    // =========================================================================
    pub fn setbasic_new() -> *mut CSetBasic;
    pub fn setbasic_free(self_: *mut CSetBasic);
    pub fn setbasic_insert(self_: *mut CSetBasic, value: *const BasicStruct) -> c_int;
    pub fn setbasic_get(self_: *mut CSetBasic, n: c_int, result: *mut BasicStruct);
    pub fn setbasic_size(self_: *mut CSetBasic) -> usize;

    // =========================================================================
    // Containers — CMapBasicBasic
    // =========================================================================
    pub fn mapbasicbasic_new() -> *mut CMapBasicBasic;
    pub fn mapbasicbasic_free(self_: *mut CMapBasicBasic);
    pub fn mapbasicbasic_insert(self_: *mut CMapBasicBasic, key: *const BasicStruct, mapped: *const BasicStruct);

    // =========================================================================
    // Free symbols & solving
    // =========================================================================
    pub fn basic_free_symbols(self_: *const BasicStruct, symbols: *mut CSetBasic) -> c_int;
    pub fn basic_solve_poly(r: *mut CSetBasic, f: *const BasicStruct, s: *const BasicStruct) -> c_int;

    // =========================================================================
    // Vector reductions
    // =========================================================================
    pub fn basic_add_vec(s: *mut BasicStruct, d: *const CVecBasic) -> c_int;
    pub fn basic_mul_vec(s: *mut BasicStruct, d: *const CVecBasic) -> c_int;

    // =========================================================================
    // Substitution with map
    // =========================================================================
    pub fn basic_subs(s: *mut BasicStruct, e: *const BasicStruct, mapbb: *const CMapBasicBasic) -> c_int;

    // =========================================================================
    // Equation solving (linear)
    // =========================================================================
    pub fn vecbasic_linsolve(sol: *mut CVecBasic, sys: *const CVecBasic, sym: *const CVecBasic) -> c_int;

    // =========================================================================
    // Dense matrix
    // =========================================================================
    pub fn dense_matrix_new() -> *mut CDenseMatrix;
    pub fn dense_matrix_new_rows_cols(r: c_ulong, c: c_ulong) -> *mut CDenseMatrix;
    pub fn dense_matrix_free(self_: *mut CDenseMatrix);
    pub fn dense_matrix_set_basic(mat: *mut CDenseMatrix, r: c_ulong, c: c_ulong, s: *mut BasicStruct) -> c_int;
    pub fn dense_matrix_get_basic(s: *mut BasicStruct, mat: *const CDenseMatrix, r: c_ulong, c: c_ulong) -> c_int;
    pub fn dense_matrix_rows(s: *const CDenseMatrix) -> c_ulong;
    pub fn dense_matrix_cols(s: *const CDenseMatrix) -> c_ulong;
    pub fn dense_matrix_det(s: *mut BasicStruct, mat: *const CDenseMatrix) -> c_int;
    pub fn dense_matrix_inv(s: *mut CDenseMatrix, mat: *const CDenseMatrix) -> c_int;
    pub fn dense_matrix_transpose(s: *mut CDenseMatrix, mat: *const CDenseMatrix) -> c_int;
    pub fn dense_matrix_add_matrix(s: *mut CDenseMatrix, a: *const CDenseMatrix, b: *const CDenseMatrix) -> c_int;
    pub fn dense_matrix_mul_matrix(s: *mut CDenseMatrix, a: *const CDenseMatrix, b: *const CDenseMatrix) -> c_int;
    pub fn dense_matrix_mul_scalar(s: *mut CDenseMatrix, a: *const CDenseMatrix, b: *const BasicStruct) -> c_int;
    pub fn dense_matrix_str(s: *const CDenseMatrix) -> *mut c_char;
}
