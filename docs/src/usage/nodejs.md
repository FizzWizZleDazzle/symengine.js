# Node.js Usage

## ES Modules (Recommended)

```javascript
// package.json: "type": "module"
import SymEngine from './dist/symengine.js';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));

const se = await SymEngine({
    locateFile: (path) => join(__dirname, 'dist', path)
});

console.log(se.version());
```

## CommonJS

```javascript
const path = require('path');

async function main() {
    const SymEngine = (await import('./dist/symengine.js')).default;

    const se = await SymEngine({
        locateFile: (p) => path.join(__dirname, 'dist', p)
    });

    console.log(se.version());
}

main();
```

## File Path Resolution

Node.js needs explicit path resolution for the `.wasm` file:

```javascript
import { createRequire } from 'module';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));

const se = await SymEngine({
    locateFile: (path) => {
        // Resolve relative to your module
        return join(__dirname, 'dist', path);
    }
});
```

## Performance Tips

### Pre-compile WASM

```javascript
import { readFileSync } from 'fs';

const wasmBuffer = readFileSync('./dist/symengine.wasm');
const wasmModule = await WebAssembly.compile(wasmBuffer);

const se = await SymEngine({
    instantiateWasm: (imports, callback) => {
        WebAssembly.instantiate(wasmModule, imports)
            .then(instance => callback(instance));
        return {};
    }
});
```

### Reuse Module Instance

```javascript
// singleton.js
let instance = null;

export async function getSymEngine() {
    if (!instance) {
        const SymEngine = (await import('./symengine.js')).default;
        instance = await SymEngine();
    }
    return instance;
}
```

## CLI Example

```javascript
#!/usr/bin/env node
// calc.mjs

import SymEngine from './dist/symengine.js';

const se = await SymEngine();

const expr = process.argv[2];
if (!expr) {
    console.error('Usage: calc.mjs "<expression>"');
    process.exit(1);
}

try {
    const parsed = se.parse(expr);
    console.log('Expanded:', parsed.expand().toString());
    console.log('Derivative:', parsed.diff('x').toString());
} catch (e) {
    console.error('Error:', e.message);
}
```

```bash
chmod +x calc.mjs
./calc.mjs "(x+1)^3"
```
