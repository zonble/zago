# WebAssembly Build & Web Deployment (`wasm_build.md`)

This guide covers building `zago` for WebAssembly (`wasm32-unknown-wasi`), running the local web terminal development server, and deploying to GitHub Pages.

---

## 1. Prerequisites & Toolchain Setup

### Swift 6.3+ WebAssembly SDK
Swift 6.3 includes official support for Swift SDKs targeting WebAssembly (`wasm32-unknown-wasip1`).

To install the official Swift Wasm 6.3 SDK:
```bash
# Check installed SDKs
swift sdk list

# Install Swift SDK for WebAssembly (Swift 6.3)
swift sdk install https://github.com/swiftwasm/swift/releases/download/swift-wasm-6.3-RELEASE/swift-wasm-6.3-RELEASE-wasm32-unknown-wasip1.artifactbundle.zip --checksum 6704d137e532f1ac31eafedd80658f9ee61239f2b6291216a02da32361ea9dcb
```

### Node.js & Package Manager
Ensure Node.js (>= 18.0.0) is installed for the `web/` frontend tooling.
```bash
node -v
npm -v
```

---

## 2. Building the WebAssembly Binary

The repository provides a helper script `build-wasm.sh` to compile `zago` to Wasm and copy output artifacts into `web/public/`:

```bash
# Make script executable
chmod +x build-wasm.sh

# Run compilation
./build-wasm.sh
```

### Manual Build Command
Under the hood, `build-wasm.sh` runs:
```bash
swift build \
  --configuration release \
  --swift-sdk wasm32-unknown-wasip1 \
  --product zago-wasm

# Output binary location:
# .build/wasm32-unknown-wasip1/release/zago-wasm.wasm -> web/public/zago.wasm
```

---

## 3. Running the Web Development Server

Once `zago.wasm` is placed in `web/public/`, start the Vite dev server:

```bash
cd web
npm install
npm run dev
```

Open `http://localhost:5173` in your browser to launch `zago` in the web terminal.

---

## 4. Frontend Structure (`web/`)

```
web/
├── index.html              # Main HTML entry point with terminal container & toolbar
├── package.json            # Vite, TypeScript, xterm, @bjorn3/browser_wasi_shim
├── tsconfig.json
├── vite.config.ts
├── public/
│   └── zago.wasm           # Compiled WebAssembly binary
└── src/
    ├── main.ts             # Initializes xterm.js, UI toolbar, and Worker bridge
    ├── worker.ts           # Web Worker running WASI shim and zago.wasm
    ├── storage.ts          # IndexedDB / LocalStorage workspace manager
    └── styles.css          # Modern dark-mode styling for terminal & UI
```

---

## 5. Automated CI/CD (GitHub Pages)

The GitHub Actions workflow at `.github/workflows/deploy-pages.yml` automatically builds and publishes the web version on push to `main`:

```yaml
name: Deploy Web Edition to GitHub Pages

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: true

jobs:
  build-and-deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7

      - name: Set up Swift with Wasm SDK
        uses: bytecodealliance/actions/setup-wasmtime@v1
        with:
          version: "v24.0.0"

      - name: Install Swift & Wasm SDK
        run: |
          ./build-wasm.sh

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
          cache-dependency-path: web/package-lock.json

      - name: Build Web App
        run: |
          cd web
          npm ci
          npm run build

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Upload Artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: 'web/dist'

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

---

## 6. Troubleshooting & Tips

- **SharedArrayBuffer / Cross-Origin Isolation**:
  If using multithreading or high-resolution timers, Vite includes headers:
  `Cross-Origin-Opener-Policy: same-origin`
  `Cross-Origin-Embedder-Policy: require-corp`
- **Memory Limits**:
  If complex Logo recursions run out of memory, increase initial Wasm memory allocation in `worker.ts`.
- **Wasm Stripping / Optimization**:
  Use `wasm-opt -O3 web/public/zago.wasm -o web/public/zago.min.wasm` to reduce binary size for production.
