/**
 * SymEngine Embind Bindings
 * Exposes SymEngine C++ API to JavaScript
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
#include <symengine/real_double.h>
#include <symengine/constants.h>
#include <symengine/functions.h>
#include <symengine/derivative.h>
#include <symengine/visitor.h>
#include <symengine/parser.h>
#include <symengine/printers.h>
#include <symengine/eval.h>

using namespace emscripten;
using namespace SymEngine;

// Wrapper class for easier JavaScript interaction
class SymEngineExpr {
public:
    RCP<const Basic> expr;

    SymEngineExpr() : expr(integer(0)) {}
    SymEngineExpr(const RCP<const Basic>& e) : expr(e) {}
    SymEngineExpr(int n) : expr(integer(n)) {}
    SymEngineExpr(double d) : expr(real_double(d)) {}
    SymEngineExpr(const std::string& s) : expr(parse(s)) {}

    std::string toString() const {
        return expr->__str__();
    }

    std::string toLatex() const {
        return latex(*expr);
    }

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

    SymEngineExpr diff(const std::string& var) const {
        auto sym = symbol(var);
        return SymEngineExpr(expr->diff(sym));
    }

    SymEngineExpr expand() const {
        return SymEngineExpr(SymEngine::expand(expr));
    }

    SymEngineExpr subs(const std::string& var, const SymEngineExpr& value) const {
        map_basic_basic m;
        m[symbol(var)] = value.expr;
        return SymEngineExpr(expr->subs(m));
    }

    bool equals(const SymEngineExpr& other) const {
        return eq(*expr, *other.expr);
    }

    double evalFloat() const {
        // Try to evaluate to a double
        auto result = evalf(*expr, 53, EvalfDomain::Real);
        if (is_a<RealDouble>(*result)) {
            return down_cast<const RealDouble&>(*result).i;
        }
        return std::nan("");
    }
};

// Factory functions
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

SymEngineExpr parse_expr(const std::string& s) {
    return SymEngineExpr(parse(s));
}

// Constants
SymEngineExpr getPi() { return SymEngineExpr(pi); }
SymEngineExpr getE() { return SymEngineExpr(E); }
SymEngineExpr getI() { return SymEngineExpr(I); }

// Functions
SymEngineExpr symSin(const SymEngineExpr& x) { return SymEngineExpr(sin(x.expr)); }
SymEngineExpr symCos(const SymEngineExpr& x) { return SymEngineExpr(cos(x.expr)); }
SymEngineExpr symTan(const SymEngineExpr& x) { return SymEngineExpr(tan(x.expr)); }
SymEngineExpr symLog(const SymEngineExpr& x) { return SymEngineExpr(log(x.expr)); }
SymEngineExpr symExp(const SymEngineExpr& x) { return SymEngineExpr(exp(x.expr)); }
SymEngineExpr symSqrt(const SymEngineExpr& x) { return SymEngineExpr(sqrt(x.expr)); }
SymEngineExpr symAbs(const SymEngineExpr& x) { return SymEngineExpr(abs(x.expr)); }

std::string getVersion() {
    return SYMENGINE_VERSION;
}

EMSCRIPTEN_BINDINGS(symengine) {
    class_<SymEngineExpr>("Expr")
        .constructor<>()
        .constructor<const std::string&>()
        .function("toString", &SymEngineExpr::toString)
        .function("toLatex", &SymEngineExpr::toLatex)
        .function("add", &SymEngineExpr::add)
        .function("sub", &SymEngineExpr::sub)
        .function("mul", &SymEngineExpr::mul)
        .function("div", &SymEngineExpr::div)
        .function("pow", &SymEngineExpr::pow)
        .function("neg", &SymEngineExpr::neg)
        .function("diff", &SymEngineExpr::diff)
        .function("expand", &SymEngineExpr::expand)
        .function("subs", &SymEngineExpr::subs)
        .function("equals", &SymEngineExpr::equals)
        .function("evalFloat", &SymEngineExpr::evalFloat);

    function("symbol", &createSymbol);
    function("integer", &createInteger);
    function("rational", &createRational);
    function("float", &createFloat);
    function("parse", &parse_expr);
    function("version", &getVersion);

    // Constants
    function("pi", &getPi);
    function("e", &getE);
    function("i", &getI);

    // Functions
    function("sin", &symSin);
    function("cos", &symCos);
    function("tan", &symTan);
    function("log", &symLog);
    function("exp", &symExp);
    function("sqrt", &symSqrt);
    function("abs", &symAbs);
}
