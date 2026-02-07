mod symengine;
mod symengine_ffi;

use wasm_bindgen::prelude::*;

/// Differentiate `expr` with respect to `var` and return the result as a string.
///
/// Example: `differentiate("x**3 + 2*x", "x")` returns `"3*x**2 + 2"`.
#[wasm_bindgen]
pub fn differentiate(expr: &str, var: &str) -> String {
    let e = symengine::Expr::parse(expr);
    let v = symengine::Expr::symbol(var);
    e.diff(&v).to_string()
}

/// Expand an expression and return the result as a string.
///
/// Example: `expand("(x+1)**3")` returns `"1 + 3*x + 3*x**2 + x**3"`.
#[wasm_bindgen]
pub fn expand(expr: &str) -> String {
    let e = symengine::Expr::parse(expr);
    e.expand().to_string()
}

/// Return the LaTeX representation of an expression.
#[wasm_bindgen]
pub fn to_latex(expr: &str) -> String {
    let e = symengine::Expr::parse(expr);
    e.to_latex()
}

/// Return the SymEngine library version.
#[wasm_bindgen]
pub fn symengine_version_str() -> String {
    symengine::version_str()
}
