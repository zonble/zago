# WebAssembly Build & Web Deployment (`wasm_build.md`)

This guide covers building `zago` for WebAssembly, running the local web terminal development server, and deploying to GitHub Pages.

The WebAssembly executable target is `zagoweb` (defined in `Package.swift`). The
build script copies the resulting binary to `web/public/zago.wasm`, which is the
filename loaded by the browser application.

---

## 1. Prerequisites & Toolchain Setup

### Local Swift WebAssembly SDK
The local build path currently requires the exact Swift SDK identifier
`6.3-RELEASE-wasm32-unknown-wasip1`. The version is pinned in
`build-wasm.sh` so that machines with multiple Wasm SDKs do not build with
different toolchains.

To install the official Swift Wasm 6.3 SDK:
```bash
# Check installed SDKs
swift sdk list

# Install the pinned Swift 6.3 WebAssembly SDK
swift sdk install https://github.com/swiftwasm/swift/releases/download/swift-wasm-6.3-RELEASE/swift-wasm-6.3-RELEASE-wasm32-unknown-wasip1.artifactbundle.zip --checksum 6704d137e532f1ac31eafedd80658f9ee61239f2b6291216a02da32361ea9dcb
```

The repository also provides a Docker fallback for CI and environments where
the local SDK is unavailable. The Docker image currently uses Swift 6.0 and
the `wasm32-unknown-wasi` SDK; it is a separate, legacy toolchain and should
not be mixed with the local Swift 6.3 SDK in the same build environment. See
`Dockerfile_wasm` for the pinned image and SDK checksum.

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

### Manual Build Command (local SDK)
For the local SDK path, the equivalent command is:
```bash
swift build \
  --configuration release \
  --swift-sdk 6.3-RELEASE-wasm32-unknown-wasip1 \
  --product zagoweb

# Output binary location:
# .build/6.3-RELEASE-wasm32-unknown-wasip1/release/zagoweb.wasm
```

In normal development, prefer `./build-wasm.sh`. It first uses an already
built `zago-wasm-builder` Docker image when available; otherwise it uses the
pinned local SDK. It then copies the release binary to
`web/public/zago.wasm` and optionally runs `wasm-opt -O3` (or the npm fallback)
to reduce its size.

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
    ├── vfs.ts              # IndexedDB-backed WASI virtual file system
    ├── shared-stdin.ts     # SharedArrayBuffer stdin ring buffer
    ├── i18n.ts             # Browser locale detection and translations
    └── styles.css          # Modern dark-mode styling for terminal & UI
```

---

## 5. Automated CI/CD (GitHub Pages)

The GitHub Actions workflow at `.github/workflows/deploy-pages.yml` builds and
publishes the web version on push to `main`. CI deliberately builds the
`zago-wasm-builder` image first, so the GitHub runner follows the Docker Swift
6.0/WASI path from `Dockerfile_wasm` rather than relying on a preinstalled
local SDK:

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

      - name: Build Swift Wasm Docker Image
        run: |
          docker build -t zago-wasm-builder -f Dockerfile_wasm .

      - name: Build WebAssembly Binary
        run: |
          chmod +x build-wasm.sh
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
          npm install
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
