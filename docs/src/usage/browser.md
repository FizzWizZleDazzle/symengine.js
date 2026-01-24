# Browser Usage

## Script Tag (ES6 Module)

```html
<script type="module">
import SymEngine from './symengine.js';

const se = await SymEngine();
console.log(se.version());
</script>
```

## With Bundlers

### Vite

```javascript
// vite.config.js
export default {
    optimizeDeps: {
        exclude: ['symengine']
    },
    assetsInclude: ['**/*.wasm']
};
```

```javascript
// main.js
import SymEngine from 'symengine';

const se = await SymEngine();
```

### Webpack

```javascript
// webpack.config.js
module.exports = {
    experiments: {
        asyncWebAssembly: true
    }
};
```

## CORS Considerations

WASM files require proper CORS headers:

```
Content-Type: application/wasm
Access-Control-Allow-Origin: *
```

For local development, use a server that sets these headers.

## Web Worker Usage

```javascript
// worker.js
import SymEngine from './symengine.js';

let se;

self.onmessage = async (e) => {
    if (!se) {
        se = await SymEngine();
    }

    const { expr, operation } = e.data;
    const parsed = se.parse(expr);

    let result;
    switch (operation) {
        case 'expand':
            result = parsed.expand().toString();
            break;
        case 'diff':
            result = parsed.diff('x').toString();
            break;
    }

    self.postMessage({ result });
};
```

```javascript
// main.js
const worker = new Worker('./worker.js', { type: 'module' });

worker.postMessage({ expr: '(x+1)^3', operation: 'expand' });
worker.onmessage = (e) => console.log(e.data.result);
```

## Memory Management

The WASM module uses automatic memory growth:

```javascript
const se = await SymEngine({
    // Initial memory (default: 16MB)
    INITIAL_MEMORY: 16 * 1024 * 1024,

    // Maximum memory (default: 4GB)
    MAXIMUM_MEMORY: 4 * 1024 * 1024 * 1024
});
```
