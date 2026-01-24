# Runtime Loading

Load SymEngine WASM dynamically at runtime using `dlopen`.

## When to Use Runtime Loading

- Load on-demand to reduce initial page load
- Plugin architectures
- Optional features

## JavaScript: Using dynamicLibraries

```javascript
import MainModuleFactory from './main_module.js';

// Load at initialization
const app = await MainModuleFactory({
    dynamicLibraries: ['./symengine.wasm']
});
```

## JavaScript: Using dlopen

```javascript
const app = await MainModuleFactory();

// Fetch and store the WASM file
const wasmData = await fetch('./symengine.wasm')
    .then(r => r.arrayBuffer())
    .then(buf => new Uint8Array(buf));

// Create file in virtual filesystem
app.FS.writeFile('/symengine.wasm', wasmData);

// Open the library
const handle = app._dlopen(
    app.stringToNewUTF8('/symengine.wasm'),
    0  // RTLD_LAZY
);

if (handle === 0) {
    throw new Error('Failed to load symengine.wasm');
}

// Get function pointer
const symPtr = app._dlsym(
    handle,
    app.stringToNewUTF8('symengine_version')
);

// Call the function
const version = app.ccall(
    'symengine_version',
    'string',
    [],
    []
);

console.log('Loaded SymEngine:', version);
```

## Async Loading (Recommended)

For modules larger than 4MB, use async loading:

```javascript
// Avoid synchronous compilation limits
app.emscripten_dlopen_async(
    '/symengine.wasm',
    0,  // flags
    null,  // user data
    (handle) => {
        if (handle === 0) {
            console.error('Load failed');
            return;
        }
        console.log('SymEngine loaded successfully');
    }
);
```

## C++ Runtime Loading

```cpp
#include <dlfcn.h>
#include <iostream>

typedef const char* (*VersionFunc)();

int main() {
    // Load the library
    void* handle = dlopen("symengine.wasm", RTLD_LAZY);
    if (!handle) {
        std::cerr << "Failed to load: " << dlerror() << std::endl;
        return 1;
    }

    // Get function
    VersionFunc version = (VersionFunc)dlsym(handle, "symengine_version");
    if (!version) {
        std::cerr << "Symbol not found: " << dlerror() << std::endl;
        dlclose(handle);
        return 1;
    }

    std::cout << "SymEngine version: " << version() << std::endl;

    dlclose(handle);
    return 0;
}
```

## Error Handling

```javascript
function loadSymEngine(app) {
    return new Promise((resolve, reject) => {
        const wasmPath = '/symengine.wasm';

        // Check if already loaded
        if (app._symengine_loaded) {
            resolve();
            return;
        }

        try {
            const handle = app._dlopen(
                app.stringToNewUTF8(wasmPath),
                0
            );

            if (handle === 0) {
                const error = app.UTF8ToString(app._dlerror());
                reject(new Error(`dlopen failed: ${error}`));
                return;
            }

            app._symengine_loaded = true;
            app._symengine_handle = handle;
            resolve();

        } catch (e) {
            reject(e);
        }
    });
}
```

## Unloading

```javascript
function unloadSymEngine(app) {
    if (app._symengine_handle) {
        app._dlclose(app._symengine_handle);
        app._symengine_handle = null;
        app._symengine_loaded = false;
    }
}
```
