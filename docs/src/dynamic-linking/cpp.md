# C++ Integration

Link SymEngine WASM with your C++ WebAssembly project.

## Project Structure

```
my-wasm-project/
├── CMakeLists.txt
├── src/
│   └── main.cpp
├── deps/
│   └── symengine.wasm
└── build/
```

## CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.16)
project(my_wasm_app CXX)

set(CMAKE_CXX_STANDARD 17)

# Your source files
add_executable(my_app src/main.cpp)

# Configure as MAIN_MODULE
set_target_properties(my_app PROPERTIES
    SUFFIX ".js"
    LINK_FLAGS "\
        -sMAIN_MODULE=1 \
        -sMODULARIZE=1 \
        -sEXPORT_NAME=MyApp \
        -sALLOW_MEMORY_GROWTH=1 \
        -sALLOW_TABLE_GROWTH=1"
)

# Link SymEngine side module
target_link_libraries(my_app PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/deps/symengine.wasm
)

# Include SymEngine headers
target_include_directories(my_app PRIVATE
    ${SYMENGINE_INCLUDE_DIR}
)
```

## main.cpp

```cpp
#include <iostream>
#include <symengine/basic.h>
#include <symengine/symbol.h>
#include <symengine/parser.h>
#include <symengine/derivative.h>

using namespace SymEngine;

extern "C" {

const char* compute_derivative(const char* expr_str, const char* var) {
    static std::string result;

    auto expr = parse(expr_str);
    auto sym = symbol(var);
    auto deriv = expr->diff(sym);

    result = deriv->__str__();
    return result.c_str();
}

}

int main() {
    auto x = symbol("x");
    auto expr = parse("x^3 + 2*x^2 + x");
    auto deriv = expr->diff(x);

    std::cout << "d/dx(" << expr->__str__() << ") = "
              << deriv->__str__() << std::endl;

    return 0;
}
```

## Build Commands

```bash
# Create build directory
mkdir build && cd build

# Configure with Emscripten
emcmake cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DSYMENGINE_INCLUDE_DIR=/path/to/symengine

# Build
emmake make
```

## JavaScript Usage

```javascript
import MyAppFactory from './my_app.js';

const app = await MyAppFactory({
    dynamicLibraries: ['./symengine.wasm']
});

// Call your exported function
const result = app.ccall(
    'compute_derivative',
    'string',
    ['string', 'string'],
    ['x^3 + sin(x)', 'x']
);

console.log(result);  // "3*x**2 + cos(x)"
```

## Static Linking Alternative

If dynamic linking is problematic, use static linking:

```cmake
# Build SymEngine as static library first
# Then link directly
target_link_libraries(my_app PRIVATE
    ${SYMENGINE_LIB_DIR}/libsymengine.a
)
```
