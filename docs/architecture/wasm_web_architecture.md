# WebAssembly & Web Terminal Architecture (`wasm_web_architecture.md`)

This document describes the design, execution model, I/O bridging, and module degradation strategy for running `zago` in modern web browsers via WebAssembly (Wasm) and `xterm.js`.

---

## 1. Overview & Goals

The Web edition brings the full text editing, ASCII/Unicode diagramming, and Editor LOGO capabilities of `zago` to modern browsers without requiring local Swift installation.

### Key Design Pillars
1. **Zero UI Freezing**: The synchronous editor event loop runs inside a dedicated Web Worker, preventing terminal I/O or rendering calculations from blocking main thread browser animations and UI responsiveness.
2. **Minimal Wasm Target**: Exclude platform-specific dependencies (such as POSIX/Win32 IPC sockets, inotify/kqueue file watchers, and OS spell check services) while retaining core editing, drawing, and LOGO execution.
3. **Full ANSI/VT100 Terminal Emulation**: Use `xterm.js` with ANSI OSC 52 clipboard sequences and dynamic resize handling.
4. **Persistent Virtual File System**: Provide in-memory storage (MEMFS) backed by browser `IndexedDB` with file import/export toolbars.

---

## 2. System Architecture

```
+-------------------------------------------------------------------------+
|                              Main Thread                                |
|                                                                         |
|  +--------------------+   +-------------------+   +------------------+  |
|  |   Toolbar & UI     |   |     xterm.js      |   | IndexedDB /      |  |
|  | (Import/Export/Doc)|   | (Terminal Canvas) |   | File Storage     |  |
|  +---------+----------+   +---------+---------+   +--------+---------+  |
|            |                        |                      |            |
|            +------------------------+----------------------+            |
|                                     |                                   |
|                        postMessage / SharedArrayBuffer                  |
+-------------------------------------|-----------------------------------+
                                      |
+-------------------------------------v-----------------------------------+
|                           Web Worker (Background)                       |
|                                                                         |
|  +-------------------------------------------------------------------+  |
|  |                     WASI Shim Runtime                             |  |
|  |     (stdin FIFO queue, stdout batching, preopened MEMFS)          |  |
|  +-----------------------------------+-------------------------------+  |
|                                      |                                  |
|  +-----------------------------------v-------------------------------+  |
|  |                       zago.wasm (Swift Core)                      |  |
|  |                                                                   |  |
|  |  +---------------+  +---------------+  +-----------------------+  |  |
|  |  |    Editor     |  |  LogoEngine   |  |   Drawing & Diagram   |  |  |
|  |  +---------------+  +---------------+  +-----------------------+  |  |
|  |  |    Syntax     |  |  TextMetrics  |  |     Config (MEMFS)    |  |  |
|  |  +---------------+  +---------------+  +-----------------------+  |  |
|  +-------------------------------------------------------------------+  |
+-------------------------------------------------------------------------+
```

---

## 3. Threading & Execution Model

### The Blocking I/O Challenge in Browsers
In native builds, `zago` uses a synchronous event loop:
```swift
while isRunning {
    let key = terminal.readKey() // Blocking POSIX read or Win32 ReadConsoleInput
    processKey(key)
    render()
}
```
In a web browser's main thread, synchronous blocking calls freeze the DOM, prevent keyboard events from firing, and crash the browser tab.

### Solution: Web Worker + WASI Shim
- The compiled `zago.wasm` binary runs inside a dedicated Web Worker.
- Standard I/O streams are connected to a WASI Shim (e.g. `@bjorn3/browser_wasi_shim`):
  - **`stdin`**: User keystrokes received by `xterm.js` are forwarded via `worker.postMessage({ type: 'input', data: '...' })`. A lock-free ring buffer or asynchronous worker queue provides bytes to WASI `fd_read(0)`.
  - **`stdout` / `stderr`**: VT100 ANSI sequences emitted by `zago` are flushed through WASI `fd_write(1)` and posted back to the main thread: `self.postMessage({ type: 'output', data: '...' })`, where `terminal.write(...)` renders them onto the canvas.

---

## 4. Module Inclusion & Fallback Matrix

To ensure clean compilation against `wasm32-unknown-wasi` without platform-specific SDK linker errors, modules are partitioned as follows:

| Module | Native (macOS/Win/Linux) | WebAssembly (WASI) | Strategy & Alternative |
| :--- | :--- | :--- | :--- |
| **`Editor`** | Included | **Included** | Core buffer, editing commands, modal rendering |
| **`Drawing`** | Included | **Included** | ANSI box drawing, canvas, borders |
| **`LogoEngine`** | Included | **Included** | Full Logo interpreter & evaluator |
| **`LogoLocalization`** | Included | **Included** | Multi-language Logo command aliases |
| **`Syntax`** | Included | **Included** | Syntax highlighting engine |
| **`Diagram`** | Included | **Included** | Diagram conversion & snippet generator |
| **`TextMetrics`** | Included | **Included** | CJK/emoji display width calculations |
| **`TextTransform`** | Included | **Included** | Half-width / full-width conversions |
| **`TextEncoding`** | Included | **Included** | UTF-8, UTF-16, Big5 fallback decoders |
| **`Config`** | Included | **Included** | `.zagorc` parsing over MEMFS |
| **`DocumentOutline`** | Included | **Included** | Markdown heading extraction |
| **`ANSIStyle`** | Included | **Included** | Terminal color & text styling |
| **`NumberHelpers`** | Included | **Included** | Coordinate & numeric utilities |
| **`SystemClipboard`** | AppKit / Win32 | **ANSI OSC 52** | Clipboard requests emit ANSI OSC 52 sequences or bridge to Web Clipboard API |
| **`IPCServer`** | Unix Domain / Named Pipe | **Disabled / Stub** | Sockets unavailable in WASI; bypassed |
| **`Git`** | `Process` execution | **Disabled / Stub** | Subprocesses unavailable in WASI; returns clean no-op |
| **`FileWatcher`** | FSEvents / inotify | **Disabled / Stub** | FS notifications not supported in WASI |
| **`SpellChecker`** | NSSpellServer / ole32 | **Disabled / Stub** | Native spell check libraries bypassed |

---

## 5. Terminal & Browser Integration

### A. Window Sizing & Resize Events (`SIGWINCH`)
- `xterm.js` handles DOM container size changes via `@xterm/addon-fit`.
- On window resize:
  1. Main thread calculates new rows/cols: `const { rows, cols } = fitAddon.proposeDimensions()`.
  2. Main thread posts message: `worker.postMessage({ type: 'resize', rows, cols })`.
  3. The WASI terminal driver updates its internal terminal size cache and triggers a redraw pass.

### B. Clipboard Integration (OSC 52)
- When the user triggers Copy or Cut inside `zago`, the editor writes the standard ANSI OSC 52 sequence:
  ```
  \x1b]52;c;<Base64-Encoded-Data>\x07
  ```
- `xterm.js` intercepts OSC 52 and calls `navigator.clipboard.writeText(...)`.
- Standard browser paste (Ctrl+V / Cmd+V) sends the pasted text directly into the `stdin` stream.

---

## 6. File System & Data Persistence

1. **Preopened MEMFS Virtual Directory**:
   - The WASI runtime mounts `/workspace` as the current working directory.
   - Initial demo files (e.g. `/workspace/demo.zago`, `/workspace/README.md`) are preloaded into memory upon initialization.
2. **IndexedDB Sync**:
   - Whenever files are written (`:w`, `Ctrl+S`), the WASI MEMFS writes persist to IndexedDB in the browser.
   - On subsequent visits, the user's saved workspace and `.zagorc` configurations are restored from IndexedDB.
3. **Web Toolbar Actions**:
   - **Upload / Import**: Reads a local file via `<input type="file">` and writes its contents to `/workspace/<filename>`.
   - **Download / Export**: Reads the currently focused file from `/workspace/` and triggers a browser file download (`<a>` download blob).
