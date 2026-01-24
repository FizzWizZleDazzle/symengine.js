/**
 * SymEngine Embind Bindings
 * Comprehensive JavaScript API for SymEngine
 */

#include <emscripten/bind.h>
#include <symengine/symengine_config.h>
#include <symengine/basic.h>
#include <symengine/add.h>
#include <symengine/mul.h>
#include <symengine/pow.h>
#include <symengine/symbol.h>
#include <symengine/integer.h>
#include <symengine/rational.h>
#include <symengine/complex.h>
#include <symengine/complex_double.h>
#include <symengine/real_double.h>
#include <symengine/constants.h>
#include <symengine/functions.h>
#include <symengine/derivative.h>
#include <symengine/visitor.h>
#include <symengine/parser.h>
#include <symengine/printers.h>
#include <symengine/eval.h>
#include <symengine/logic.h>
#include <symengine/sets.h>
#include <symengine/ntheory.h>
#include <symengine/polys/basic_conversions.h>
#include <symengine/series.h>
#include <symengine/matrix.h>
#include <symengine/subs.h>
#include <symengine/simplify.h>

using namespace emscripten;
using namespace SymEngine;

// Forward declarations
class SymEngineExpr;

// Wrapper class for easier JavaScript interaction
class SymEngineExpr {
public:
    RCP<const Basic> expr;

    SymEngineExpr() : expr(integer(0)) {}
    SymEngineExpr(const RCP<const Basic>& e) : expr(e) {}
    SymEngineExpr(int n) : expr(integer(n)) {}
    SymEngineExpr(double d) : expr(real_double(d)) {}
    SymEngineExpr(const std::string& s) : expr(parse(s)) {}

    // String representations
    std::string toString() const {
        return expr->__str__();
    }

    std::string toLatex() const {
        return latex(*expr);
    }

    std::string toMathML() const {
        return mathml(*expr);
    }

    std::string toCCode() const {
        return ccode(*expr);
    }

    std::string toJSCode() const {
        return jscode(*expr);
    }

    // Basic arithmetic
    SymEngineExpr add(const SymEngineExpr& other) const {
        return SymEngineExpr(SymEngine::add(expr, other.expr));
    }

    SymEngineExpr sub(const SymEngineExpr& other) const {
        return SymEngineExpr(SymEngine::sub(expr, other.expr));
    }

    SymEngineExpr mul(const SymEngineExpr& other) const {
        return SymEngineExpr(SymEngine::mul(expr, other.expr));
    }

    SymEngineExpr div(const SymEngineExpr& other) const {
        return SymEngineExpr(SymEngine::div(expr, other.expr));
    }

    SymEngineExpr pow(const SymEngineExpr& exp) const {
        return SymEngineExpr(SymEngine::pow(expr, exp.expr));
    }

    SymEngineExpr neg() const {
        return SymEngineExpr(SymEngine::neg(expr));
    }

    // Calculus
    SymEngineExpr diff(const std::string& var) const {
        auto sym = symbol(var);
        return SymEngineExpr(expr->diff(sym));
    }

    SymEngineExpr diff2(const std::string& var, int n) const {
        auto sym = symbol(var);
        RCP<const Basic> result = expr;
        for (int i = 0; i < n; i++) {
            result = result->diff(sym);
        }
        return SymEngineExpr(result);
    }

    // Expansion and simplification
    SymEngineExpr expand() const {
        return SymEngineExpr(SymEngine::expand(expr));
    }

    SymEngineExpr simplify() const {
        return SymEngineExpr(SymEngine::simplify(expr));
    }

    // Substitution
    SymEngineExpr subs(const std::string& var, const SymEngineExpr& value) const {
        map_basic_basic m;
        m[symbol(var)] = value.expr;
        return SymEngineExpr(expr->subs(m));
    }

    SymEngineExpr subsExpr(const SymEngineExpr& from, const SymEngineExpr& to) const {
        map_basic_basic m;
        m[from.expr] = to.expr;
        return SymEngineExpr(expr->subs(m));
    }

    // Comparison
    bool equals(const SymEngineExpr& other) const {
        return eq(*expr, *other.expr);
    }

    bool notEquals(const SymEngineExpr& other) const {
        return neq(*expr, *other.expr);
    }

    // Evaluation
    double evalFloat() const {
        auto result = evalf(*expr, 53, EvalfDomain::Real);
        if (is_a<RealDouble>(*result)) {
            return down_cast<const RealDouble&>(*result).i;
        }
        return std::nan("");
    }

    std::string evalComplex() const {
        auto result = evalf(*expr, 53, EvalfDomain::Complex);
        return result->__str__();
    }

    // Type checking
    bool isNumber() const { return is_a_Number(*expr); }
    bool isInteger() const { return is_a<Integer>(*expr); }
    bool isRational() const { return is_a<Rational>(*expr); }
    bool isSymbol() const { return is_a<Symbol>(*expr); }
    bool isAdd() const { return is_a<Add>(*expr); }
    bool isMul() const { return is_a<Mul>(*expr); }
    bool isPow() const { return is_a<Pow>(*expr); }
    bool isFunction() const { return is_a_sub<Function>(*expr); }
    bool isZero() const { return eq(*expr, *integer(0)); }
    bool isOne() const { return eq(*expr, *integer(1)); }
    bool isNegative() const {
        if (is_a_Number(*expr)) {
            return down_cast<const Number&>(*expr).is_negative();
        }
        return false;
    }
    bool isPositive() const {
        if (is_a_Number(*expr)) {
            return down_cast<const Number&>(*expr).is_positive();
        }
        return false;
    }

    // Get type name
    std::string getType() const {
        return type_code_name(expr->get_type_code());
    }

    // Hash for comparison
    size_t hash() const {
        return expr->hash();
    }

    // Get arguments (for composite expressions)
    std::vector<SymEngineExpr> getArgs() const {
        std::vector<SymEngineExpr> result;
        for (const auto& arg : expr->get_args()) {
            result.push_back(SymEngineExpr(arg));
        }
        return result;
    }

    // Get free symbols
    std::vector<std::string> getFreeSymbols() const {
        set_basic symbols = free_symbols(*expr);
        std::vector<std::string> result;
        for (const auto& sym : symbols) {
            result.push_back(sym->__str__());
        }
        return result;
    }

    // Coefficient extraction
    SymEngineExpr coeff(const std::string& var, int n) const {
        auto sym = symbol(var);
        return SymEngineExpr(SymEngine::coeff(*expr, *sym, *integer(n)));
    }

    // Series expansion
    SymEngineExpr series(const std::string& var, int n) const {
        auto sym = symbol(var);
        auto result = SymEngine::series(expr, sym, static_cast<unsigned int>(n));
        return SymEngineExpr(result->as_basic());
    }

    // Rewrite in terms of other functions
    SymEngineExpr rewriteAsExp() const {
        return SymEngineExpr(SymEngine::rewrite_as_exp(expr));
    }

    SymEngineExpr rewriteAsSin() const {
        return SymEngineExpr(SymEngine::rewrite_as_sin(expr));
    }

    SymEngineExpr rewriteAsCos() const {
        return SymEngineExpr(SymEngine::rewrite_as_cos(expr));
    }
};

// ============================================================================
// Factory Functions
// ============================================================================

SymEngineExpr createSymbol(const std::string& name) {
    return SymEngineExpr(symbol(name));
}

SymEngineExpr createInteger(int n) {
    return SymEngineExpr(integer(n));
}

SymEngineExpr createRational(int num, int den) {
    return SymEngineExpr(Rational::from_two_ints(*integer(num), *integer(den)));
}

SymEngineExpr createFloat(double d) {
    return SymEngineExpr(real_double(d));
}

SymEngineExpr createComplex(double real, double imag) {
    return SymEngineExpr(complex_double(std::complex<double>(real, imag)));
}

SymEngineExpr parse_expr(const std::string& s) {
    return SymEngineExpr(parse(s));
}

// ============================================================================
// Constants
// ============================================================================

SymEngineExpr getPi() { return SymEngineExpr(pi); }
SymEngineExpr getE() { return SymEngineExpr(E); }
SymEngineExpr getI() { return SymEngineExpr(I); }
SymEngineExpr getInfinity() { return SymEngineExpr(Inf); }
SymEngineExpr getNegInfinity() { return SymEngineExpr(NegInf); }
SymEngineExpr getComplexInfinity() { return SymEngineExpr(ComplexInf); }
SymEngineExpr getNan() { return SymEngineExpr(Nan); }
SymEngineExpr getEulerGamma() { return SymEngineExpr(EulerGamma); }
SymEngineExpr getCatalan() { return SymEngineExpr(Catalan); }
SymEngineExpr getGoldenRatio() { return SymEngineExpr(GoldenRatio); }
SymEngineExpr getZero() { return SymEngineExpr(integer(0)); }
SymEngineExpr getOne() { return SymEngineExpr(integer(1)); }

// ============================================================================
// Trigonometric Functions
// ============================================================================

SymEngineExpr symSin(const SymEngineExpr& x) { return SymEngineExpr(sin(x.expr)); }
SymEngineExpr symCos(const SymEngineExpr& x) { return SymEngineExpr(cos(x.expr)); }
SymEngineExpr symTan(const SymEngineExpr& x) { return SymEngineExpr(tan(x.expr)); }
SymEngineExpr symCot(const SymEngineExpr& x) { return SymEngineExpr(cot(x.expr)); }
SymEngineExpr symSec(const SymEngineExpr& x) { return SymEngineExpr(sec(x.expr)); }
SymEngineExpr symCsc(const SymEngineExpr& x) { return SymEngineExpr(csc(x.expr)); }

// Inverse trigonometric
SymEngineExpr symAsin(const SymEngineExpr& x) { return SymEngineExpr(asin(x.expr)); }
SymEngineExpr symAcos(const SymEngineExpr& x) { return SymEngineExpr(acos(x.expr)); }
SymEngineExpr symAtan(const SymEngineExpr& x) { return SymEngineExpr(atan(x.expr)); }
SymEngineExpr symAcot(const SymEngineExpr& x) { return SymEngineExpr(acot(x.expr)); }
SymEngineExpr symAsec(const SymEngineExpr& x) { return SymEngineExpr(asec(x.expr)); }
SymEngineExpr symAcsc(const SymEngineExpr& x) { return SymEngineExpr(acsc(x.expr)); }
SymEngineExpr symAtan2(const SymEngineExpr& y, const SymEngineExpr& x) {
    return SymEngineExpr(atan2(y.expr, x.expr));
}

// ============================================================================
// Hyperbolic Functions
// ============================================================================

SymEngineExpr symSinh(const SymEngineExpr& x) { return SymEngineExpr(sinh(x.expr)); }
SymEngineExpr symCosh(const SymEngineExpr& x) { return SymEngineExpr(cosh(x.expr)); }
SymEngineExpr symTanh(const SymEngineExpr& x) { return SymEngineExpr(tanh(x.expr)); }
SymEngineExpr symCoth(const SymEngineExpr& x) { return SymEngineExpr(coth(x.expr)); }
SymEngineExpr symSech(const SymEngineExpr& x) { return SymEngineExpr(sech(x.expr)); }
SymEngineExpr symCsch(const SymEngineExpr& x) { return SymEngineExpr(csch(x.expr)); }

// Inverse hyperbolic
SymEngineExpr symAsinh(const SymEngineExpr& x) { return SymEngineExpr(asinh(x.expr)); }
SymEngineExpr symAcosh(const SymEngineExpr& x) { return SymEngineExpr(acosh(x.expr)); }
SymEngineExpr symAtanh(const SymEngineExpr& x) { return SymEngineExpr(atanh(x.expr)); }
SymEngineExpr symAcoth(const SymEngineExpr& x) { return SymEngineExpr(acoth(x.expr)); }
SymEngineExpr symAsech(const SymEngineExpr& x) { return SymEngineExpr(asech(x.expr)); }
SymEngineExpr symAcsch(const SymEngineExpr& x) { return SymEngineExpr(acsch(x.expr)); }

// ============================================================================
// Exponential and Logarithmic Functions
// ============================================================================

SymEngineExpr symExp(const SymEngineExpr& x) { return SymEngineExpr(exp(x.expr)); }
SymEngineExpr symLog(const SymEngineExpr& x) { return SymEngineExpr(log(x.expr)); }
SymEngineExpr symLogBase(const SymEngineExpr& x, const SymEngineExpr& base) {
    return SymEngineExpr(log(x.expr, base.expr));
}
SymEngineExpr symLambertW(const SymEngineExpr& x) { return SymEngineExpr(lambertw(x.expr)); }

// ============================================================================
// Power and Root Functions
// ============================================================================

SymEngineExpr symSqrt(const SymEngineExpr& x) { return SymEngineExpr(sqrt(x.expr)); }
SymEngineExpr symCbrt(const SymEngineExpr& x) { return SymEngineExpr(cbrt(x.expr)); }
SymEngineExpr symRoot(const SymEngineExpr& x, const SymEngineExpr& n) {
    return SymEngineExpr(SymEngine::pow(x.expr, SymEngine::div(integer(1), n.expr)));
}

// ============================================================================
// Special Functions
// ============================================================================

SymEngineExpr symAbs(const SymEngineExpr& x) { return SymEngineExpr(abs(x.expr)); }
SymEngineExpr symSign(const SymEngineExpr& x) { return SymEngineExpr(sign(x.expr)); }
SymEngineExpr symFloor(const SymEngineExpr& x) { return SymEngineExpr(floor(x.expr)); }
SymEngineExpr symCeiling(const SymEngineExpr& x) { return SymEngineExpr(ceiling(x.expr)); }
SymEngineExpr symTruncate(const SymEngineExpr& x) { return SymEngineExpr(truncate(x.expr)); }

// Gamma and related
SymEngineExpr symGamma(const SymEngineExpr& x) { return SymEngineExpr(gamma(x.expr)); }
SymEngineExpr symLogGamma(const SymEngineExpr& x) { return SymEngineExpr(loggamma(x.expr)); }
SymEngineExpr symDigamma(const SymEngineExpr& x) { return SymEngineExpr(digamma(x.expr)); }
SymEngineExpr symTrigamma(const SymEngineExpr& x) { return SymEngineExpr(trigamma(x.expr)); }
SymEngineExpr symBeta(const SymEngineExpr& x, const SymEngineExpr& y) {
    return SymEngineExpr(beta(x.expr, y.expr));
}

// Error functions
SymEngineExpr symErf(const SymEngineExpr& x) { return SymEngineExpr(erf(x.expr)); }
SymEngineExpr symErfc(const SymEngineExpr& x) { return SymEngineExpr(erfc(x.expr)); }

// Zeta and related
SymEngineExpr symZeta(const SymEngineExpr& x) { return SymEngineExpr(zeta(x.expr)); }
SymEngineExpr symDirichletEta(const SymEngineExpr& x) { return SymEngineExpr(dirichlet_eta(x.expr)); }


// ============================================================================
// Number Theory Functions
// ============================================================================

SymEngineExpr symFactorial(int n) {
    return SymEngineExpr(factorial(static_cast<unsigned>(n)));
}

SymEngineExpr symBinomial(int n, int k) {
    return SymEngineExpr(binomial(*integer(n), static_cast<unsigned long>(k)));
}

SymEngineExpr symGcd(const SymEngineExpr& a, const SymEngineExpr& b) {
    if (is_a<Integer>(*a.expr) && is_a<Integer>(*b.expr)) {
        return SymEngineExpr(gcd(
            down_cast<const Integer&>(*a.expr),
            down_cast<const Integer&>(*b.expr)));
    }
    return SymEngineExpr(integer(0));
}

SymEngineExpr symLcm(const SymEngineExpr& a, const SymEngineExpr& b) {
    if (is_a<Integer>(*a.expr) && is_a<Integer>(*b.expr)) {
        return SymEngineExpr(lcm(
            down_cast<const Integer&>(*a.expr),
            down_cast<const Integer&>(*b.expr)));
    }
    return SymEngineExpr(integer(0));
}

SymEngineExpr symMod(const SymEngineExpr& a, const SymEngineExpr& b) {
    if (is_a<Integer>(*a.expr) && is_a<Integer>(*b.expr)) {
        return SymEngineExpr(mod(
            down_cast<const Integer&>(*a.expr),
            down_cast<const Integer&>(*b.expr)));
    }
    return SymEngineExpr(integer(0));
}

SymEngineExpr symQuotient(const SymEngineExpr& a, const SymEngineExpr& b) {
    if (is_a<Integer>(*a.expr) && is_a<Integer>(*b.expr)) {
        return SymEngineExpr(quotient(
            down_cast<const Integer&>(*a.expr),
            down_cast<const Integer&>(*b.expr)));
    }
    return SymEngineExpr(integer(0));
}

bool symIsPrime(int n) {
    return probab_prime_p(*integer(n)) >= 1;
}

int symNextPrime(int n) {
    return static_cast<int>(mp_get_si(nextprime(*integer(n))->as_integer_class()));
}

SymEngineExpr symFibonacci(int n) {
    return SymEngineExpr(fibonacci(static_cast<unsigned>(n)));
}

SymEngineExpr symLucas(int n) {
    return SymEngineExpr(lucas(static_cast<unsigned>(n)));
}

SymEngineExpr symBernoulli(int n) {
    return SymEngineExpr(bernoulli(static_cast<unsigned>(n)));
}

SymEngineExpr symHarmonic(int n) {
    return SymEngineExpr(harmonic(static_cast<unsigned>(n)));
}

// ============================================================================
// Min/Max
// ============================================================================

SymEngineExpr symMin(const SymEngineExpr& a, const SymEngineExpr& b) {
    return SymEngineExpr(min({a.expr, b.expr}));
}

SymEngineExpr symMax(const SymEngineExpr& a, const SymEngineExpr& b) {
    return SymEngineExpr(max({a.expr, b.expr}));
}

// ============================================================================
// Piecewise
// ============================================================================

SymEngineExpr symPiecewise(const SymEngineExpr& expr1, const SymEngineExpr& cond1,
                           const SymEngineExpr& otherwise) {
    PiecewiseVec vec;
    vec.push_back({expr1.expr, rcp_static_cast<const Boolean>(cond1.expr)});
    vec.push_back({otherwise.expr, boolTrue});
    return SymEngineExpr(piecewise(std::move(vec)));
}

// ============================================================================
// Comparison (returns Boolean expressions)
// ============================================================================

SymEngineExpr symLt(const SymEngineExpr& a, const SymEngineExpr& b) {
    return SymEngineExpr(Lt(a.expr, b.expr));
}

SymEngineExpr symLe(const SymEngineExpr& a, const SymEngineExpr& b) {
    return SymEngineExpr(Le(a.expr, b.expr));
}

SymEngineExpr symGt(const SymEngineExpr& a, const SymEngineExpr& b) {
    return SymEngineExpr(Gt(a.expr, b.expr));
}

SymEngineExpr symGe(const SymEngineExpr& a, const SymEngineExpr& b) {
    return SymEngineExpr(Ge(a.expr, b.expr));
}

SymEngineExpr symEq(const SymEngineExpr& a, const SymEngineExpr& b) {
    return SymEngineExpr(Eq(a.expr, b.expr));
}

SymEngineExpr symNe(const SymEngineExpr& a, const SymEngineExpr& b) {
    return SymEngineExpr(Ne(a.expr, b.expr));
}

// ============================================================================
// Version
// ============================================================================

std::string getVersion() {
    return SYMENGINE_VERSION;
}

// ============================================================================
// Embind Registration
// ============================================================================

EMSCRIPTEN_BINDINGS(symengine) {
    // Register vector types
    register_vector<SymEngineExpr>("VectorExpr");
    register_vector<std::string>("VectorString");

    // Main expression class
    class_<SymEngineExpr>("Expr")
        .constructor<>()
        .constructor<const std::string&>()
        // String representations
        .function("toString", &SymEngineExpr::toString)
        .function("toLatex", &SymEngineExpr::toLatex)
        .function("toMathML", &SymEngineExpr::toMathML)
        .function("toCCode", &SymEngineExpr::toCCode)
        .function("toJSCode", &SymEngineExpr::toJSCode)
        // Arithmetic
        .function("add", &SymEngineExpr::add)
        .function("sub", &SymEngineExpr::sub)
        .function("mul", &SymEngineExpr::mul)
        .function("div", &SymEngineExpr::div)
        .function("pow", &SymEngineExpr::pow)
        .function("neg", &SymEngineExpr::neg)
        // Calculus
        .function("diff", &SymEngineExpr::diff)
        .function("diff2", &SymEngineExpr::diff2)
        // Transformation
        .function("expand", &SymEngineExpr::expand)
        .function("simplify", &SymEngineExpr::simplify)
        .function("subs", &SymEngineExpr::subs)
        .function("subsExpr", &SymEngineExpr::subsExpr)
        // Comparison
        .function("equals", &SymEngineExpr::equals)
        .function("notEquals", &SymEngineExpr::notEquals)
        // Evaluation
        .function("evalFloat", &SymEngineExpr::evalFloat)
        .function("evalComplex", &SymEngineExpr::evalComplex)
        // Type checking
        .function("isNumber", &SymEngineExpr::isNumber)
        .function("isInteger", &SymEngineExpr::isInteger)
        .function("isRational", &SymEngineExpr::isRational)
        .function("isSymbol", &SymEngineExpr::isSymbol)
        .function("isAdd", &SymEngineExpr::isAdd)
        .function("isMul", &SymEngineExpr::isMul)
        .function("isPow", &SymEngineExpr::isPow)
        .function("isFunction", &SymEngineExpr::isFunction)
        .function("isZero", &SymEngineExpr::isZero)
        .function("isOne", &SymEngineExpr::isOne)
        .function("isNegative", &SymEngineExpr::isNegative)
        .function("isPositive", &SymEngineExpr::isPositive)
        .function("getType", &SymEngineExpr::getType)
        .function("hash", &SymEngineExpr::hash)
        // Structure
        .function("getArgs", &SymEngineExpr::getArgs)
        .function("getFreeSymbols", &SymEngineExpr::getFreeSymbols)
        .function("coeff", &SymEngineExpr::coeff)
        // Series
        .function("series", &SymEngineExpr::series)
        // Rewrite
        .function("rewriteAsExp", &SymEngineExpr::rewriteAsExp)
        .function("rewriteAsSin", &SymEngineExpr::rewriteAsSin)
        .function("rewriteAsCos", &SymEngineExpr::rewriteAsCos);

    // Factory functions
    function("symbol", &createSymbol);
    function("integer", &createInteger);
    function("rational", &createRational);
    function("float", &createFloat);
    function("complex", &createComplex);
    function("parse", &parse_expr);
    function("version", &getVersion);

    // Constants
    function("pi", &getPi);
    function("e", &getE);
    function("i", &getI);
    function("oo", &getInfinity);
    function("inf", &getInfinity);
    function("negInf", &getNegInfinity);
    function("complexInf", &getComplexInfinity);
    function("nan", &getNan);
    function("eulerGamma", &getEulerGamma);
    function("catalan", &getCatalan);
    function("goldenRatio", &getGoldenRatio);
    function("zero", &getZero);
    function("one", &getOne);

    // Trigonometric
    function("sin", &symSin);
    function("cos", &symCos);
    function("tan", &symTan);
    function("cot", &symCot);
    function("sec", &symSec);
    function("csc", &symCsc);
    function("asin", &symAsin);
    function("acos", &symAcos);
    function("atan", &symAtan);
    function("acot", &symAcot);
    function("asec", &symAsec);
    function("acsc", &symAcsc);
    function("atan2", &symAtan2);

    // Hyperbolic
    function("sinh", &symSinh);
    function("cosh", &symCosh);
    function("tanh", &symTanh);
    function("coth", &symCoth);
    function("sech", &symSech);
    function("csch", &symCsch);
    function("asinh", &symAsinh);
    function("acosh", &symAcosh);
    function("atanh", &symAtanh);
    function("acoth", &symAcoth);
    function("asech", &symAsech);
    function("acsch", &symAcsch);

    // Exponential/Logarithmic
    function("exp", &symExp);
    function("log", &symLog);
    function("ln", &symLog);
    function("logBase", &symLogBase);
    function("lambertW", &symLambertW);

    // Power/Root
    function("sqrt", &symSqrt);
    function("cbrt", &symCbrt);
    function("root", &symRoot);

    // Special functions
    function("abs", &symAbs);
    function("sign", &symSign);
    function("floor", &symFloor);
    function("ceiling", &symCeiling);
    function("ceil", &symCeiling);
    function("truncate", &symTruncate);
    function("trunc", &symTruncate);
    function("gamma", &symGamma);
    function("loggamma", &symLogGamma);
    function("digamma", &symDigamma);
    function("trigamma", &symTrigamma);
    function("beta", &symBeta);
    function("erf", &symErf);
    function("erfc", &symErfc);
    function("zeta", &symZeta);
    function("dirichletEta", &symDirichletEta);

    // Number theory
    function("factorial", &symFactorial);
    function("binomial", &symBinomial);
    function("gcd", &symGcd);
    function("lcm", &symLcm);
    function("mod", &symMod);
    function("quotient", &symQuotient);
    function("isPrime", &symIsPrime);
    function("nextPrime", &symNextPrime);
    function("fibonacci", &symFibonacci);
    function("lucas", &symLucas);
    function("bernoulli", &symBernoulli);
    function("harmonic", &symHarmonic);

    // Min/Max
    function("min", &symMin);
    function("max", &symMax);

    // Piecewise
    function("piecewise", &symPiecewise);

    // Comparison (symbolic)
    function("Lt", &symLt);
    function("Le", &symLe);
    function("Gt", &symGt);
    function("Ge", &symGe);
    function("Eq", &symEq);
    function("Ne", &symNe);
}
