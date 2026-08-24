# Web Integration Tests

This document describes the browser-level integration tests for `zago-web`.
The tests exercise the real Vite application, WebAssembly binary, Web Worker,
WASI virtual file system, xterm.js terminal, and browser IndexedDB storage.

## Prerequisites

- Node.js 18 or newer
- `web/public/zago.wasm` built with `./build-wasm.sh`
- Playwright Chromium, installed with:

```bash
cd web
npm install
npx playwright install chromium
```

## Running the tests

Run the complete Chromium suite from the `web/` directory:

```bash
npm test
```

Useful variants:

```bash
npm run test:headed  # Show the browser window
npm run test:ui      # Open the Playwright test UI
npx playwright test tests/smoke.spec.ts -g "workspace"
```

Playwright starts Vite automatically at `http://127.0.0.1:5173`. The Vite
server must keep the cross-origin isolation headers configured in
`vite.config.ts`; otherwise `SharedArrayBuffer` and the editor Worker cannot
start.

## Current coverage

`web/tests/smoke.spec.ts` currently verifies:

- WebAssembly editor startup and the default tutorial document
- Keyboard input through the xterm.js terminal
- Workspace file import and IndexedDB persistence
- Resetting the IndexedDB workspace to the default files

Each test uses a separate Playwright browser context, so IndexedDB state is not
shared between tests. File import tests wait for the reload triggered by the
import handler before making assertions; this avoids racing the application
navigation.

## Test design notes

- Wait for `#wasm-loading-overlay` to receive the `hidden` class instead of
  using a fixed startup delay. The Wasm download and compilation time varies by
  machine and cache state.
- Read terminal output from `.xterm-rows` only for user-visible assertions.
  Avoid depending on xterm.js's internal DOM structure for keyboard behavior.
- IndexedDB assertions use the same `keyval-store` and `zago_vfs:` key format as
  `idb-keyval` and `VirtualOSStorage`.
- Reset must terminate the current Worker before clearing IndexedDB. The Worker
  performs periodic VFS flushes, and an active Worker could otherwise recreate
  files immediately after reset.

## Adding new tests

Prefer stable IDs already present in `web/index.html`, such as
`#terminal-container`, `#file-input`, `#btn-clear-storage`, and
`#wasm-loading-overlay`. Add a dedicated stable ID when a new control does not
have one. Keep tests focused on observable behavior and use unique marker text
when modifying a workspace.

The next useful coverage areas are ZIP import/export, mobile virtual key bar
interactions, locale selection, resize handling, and Worker error recovery.
