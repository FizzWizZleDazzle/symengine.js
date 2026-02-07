# Installation

## Prerequisites

- **Emscripten SDK** (3.0+) - [Installation guide](https://emscripten.org/docs/getting_started/downloads.html)
- **CMake** (3.16+)
- **curl** and **tar** (for downloading dependencies)

### Installing Emscripten

```bash
# Clone emsdk
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk

# Install and activate latest version
./emsdk install latest
./emsdk activate latest

# Add to your shell profile
source ./emsdk_env.sh
```

## Quick Install

```bash
# Clone this repository
git clone https://github.com/FizzWizZleDazzle/symengine.js
cd symengine.js

# Build (downloads dependencies automatically)
make

# Output is in dist/
ls dist/
# symengine.js  symengine.wasm  symengine.d.ts
```

## Using Pre-built Binaries

Pre-built WASM modules are available from [GitHub Releases](https://github.com/FizzWizZleDazzle/symengine.js/releases):

```bash
# Download latest release
curl -LO https://github.com/FizzWizZleDazzle/symengine.js/releases/latest/download/symengine-wasm.tar.gz
tar xzf symengine-wasm.tar.gz
```
