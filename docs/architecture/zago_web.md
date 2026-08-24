# Web Interface & Mobile Responsive Architecture (`zago_web.md`)

This document details the user interface layout, content structure, command toolbars, mobile virtual key bar, and interactive WebAssembly terminal integration of the `zago-web` static application hosted on GitHub Pages.

For the underlying WebAssembly runtime, Web Worker execution model, and WASI shim, see [WebAssembly & Web Terminal Architecture](wasm_web_architecture.md). For toolchain setup and build pipelines, see [WebAssembly Build & Deployment](../development/wasm_build.md).

---

## 1. Overview & Architecture Goals

`zago-web` provides a browser-based, zero-install WebAssembly playground alongside documentation, enabling users on any operating system or mobile device to experience keyboard-driven ASCII/Unicode diagramming and Editor LOGO execution directly in the browser.

### Key Capabilities
1. **Side-by-Side Documentation & Playground**: Left panel provides installation scripts, value propositions, and feature guides; right panel runs an interactive terminal with full VFS support.
2. **First-Class Mobile Ergonomics**: Breakpoint-driven mobile tabs (`📖 About zago` and `💻 Live Demo`) and a dedicated touch-screen Virtual Key Bar with ANSI escape bindings.
3. **Persistent Virtual File System (VFS)**: POSIX-compatible `/workspace` mounted via MEMFS and backed by browser `IndexedDB`, supporting ZIP import/export and single-file uploads.
4. **WASM Streaming Loader**: Real-time progress bar tracking chunked downloads and WebAssembly bytecode compilation.
5. **Interactive Mini-Shell**: Gracefully transitions to a browser CLI (`zago $ `) upon editor exit, allowing reopening of files or directory browsing.

---

## 2. Desktop Layout & Page Content Structure

On screens $\ge 900\text{px}$, the page renders a two-column split layout:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│  🐢 zago                                                                                    │
├─────────────────────────────────────────────┬───────────────────────────────────────────────┤
│ [Left Panel: Documentation]                 │ [Right Panel: Interactive Workspace]          │
│                                             │ ┌───────────────────────────────────────────┐ │
│ 1. Hero Header                              │ │ Toolbar: [📁 Import][📦 Export ZIP]        │ │
│    - Title: "zago"                          │ │          [🧹 Reset VFS][❓ Help]           │ │
│    - Tagline: "A terminal editor built for  │ ├───────────────────────────────────────────┤ │
│      AI prompts."                           │ │                                           │ │
│    - GitHub Repository Link                 │ │                                           │ │
│                                             │ │             xterm.js Canvas               │ │
│ 2. Quick Install Card                       │ │            (zago.wasm + WASI)             │ │
│    - macOS (Homebrew):                      │ │        Default: /workspace/welcome.md     │ │
│      brew tap zonble/zago && brew install...│ │                                           │ │
│    - Linux (curl install.sh)                │ │                                           │ │
│    - Windows (irm install.ps1)              │ │                                           │ │
│    - Copy-to-clipboard buttons              │ │                                           │ │
│                                             │ │                                           │ │
│ 3. Why zago? Card                           │ │                                           │ │
│    - LLMs generate plain-text diagrams      │ │                                           │ │
│    - Zero-dependency Markdown portability   │ │                                           │ │
│                                             │ │                                           │ │
│ 4. How? Feature Card                        │ ├───────────────────────────────────────────┤ │
│    - Canvas Mode (2D free cursor, F8)       │ │ WASM Loading Overlay / Progress Bar       │ │
│    - Table Mode (safe cell edits, F7)       │ │ (Percentage, MB Downloaded, Status)       │ │
│    - Quick commands (BOX, LINE, VLINE)      │ └───────────────────────────────────────────┘ │
│    - CJK & Emoji width awareness            │                                               │
│    - Editor LOGO script engine              │                                               │
├─────────────────────────────────────────────┴───────────────────────────────────────────────┤
│                               2026 Weizhong Yang a.k.a zonble                               │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

### Left Panel: Content Sections

1. **Hero Header (`.hero-section`)**:
   - **Title**: `zago`
   - **GitHub Link**: Link button directing to `https://github.com/zonble/zago`.
   - **Tagline**: *"A terminal editor built for AI prompts."*

2. **Quick Install Card (`.install-card`)**:
   - One-click copy buttons for CLI package installation:
     - **macOS (Homebrew)**: `brew tap zonble/zago && brew install zago`
     - **Linux (x86_64 / arm64)**: `curl -fsSL https://raw.githubusercontent.com/zonble/zago/main/install.sh | sh`
     - **Windows (PowerShell)**: `irm https://raw.githubusercontent.com/zonble/zago/main/install.ps1 | iex`

3. **"Why zago?" Card**:
   - Outlines why ASCII/Unicode text diagrams produced by AI agents are difficult to maintain in standard text editors without breaking alignment, and why Markdown text diagrams are prompt-friendly and version-controllable.

4. **"How?" Feature Card**:
   - **Canvas mode editing**: Move the cursor freely anywhere in 2D space without manual indentation or newline padding.
   - **Table mode**: Modify text inside tables and boxes without shifting surrounding border frames.
   - **Quick drawing commands**: `BOX`, `LINE`, `VLINE`, `FILL`, and `INSET`.
   - **CJK & Emoji Aware**: Accurate 2-column display width calculation preserving box boundaries.
   - **Editor LOGO Engine**: Embedded Logo interpreter for procedural diagram generation and text transformations.

5. **Mobile CTA Section (`.mobile-cta`)**:
   - Button `💻 Launch Live Demo in Browser` (`#btn-jump-demo`), allowing mobile visitors on the documentation tab to immediately jump into the editor tab.

---

### Right Panel: Interactive Terminal & Toolbars

The right panel hosts the interactive terminal session initialized to `/workspace/welcome.md`.

#### Top Toolbar (`.toolbar`)
Located directly above the terminal canvas:

| Button / UI Element | ID | Icon | Purpose & Action |
| :--- | :--- | :--- | :--- |
| **Status Indicator** | `.status-dot` | 🟢 | Visual pulse indicator showing `/workspace` mounting state. |
| **Import** | `#btn-import` | 📁 | Opens hidden file picker (`#file-input`). Supports `.zip`, `.md`, `.txt`, `.logo`, `.conf`, `.json`, `.swift`, `.c`, `.h`, `.py`, `.js`, `.ts`. Automatically extracts ZIP archives into `/workspace/` or saves single files into IndexedDB VFS and reloads. |
| **Export ZIP** | `#btn-export-zip` | 📦 | Prompts worker to flush in-memory Inode cache, bundles entire `/workspace` directory via `JSZip`, and triggers download of `zago-workspace-YYYY-MM-DD.zip`. |
| **Reset VFS** | `#btn-clear-storage` | 🧹 | Confirms with user, wipes `zago_vfs:*` keys in IndexedDB, and restores stock tutorial files (`welcome.md`, `demo.logo`, `examples/diagram.txt`). |
| **Help** | `#btn-help` | ❓ | Opens native modal dialog (`#help-dialog`) displaying essential keyboard shortcuts (`:dir`, `Ctrl+O`, `Ctrl+Q`, `F8`, `F7`, `Ctrl+G`). |

---

## 3. Mobile Layout & Virtual Key Bar Specification

On screens with viewport width $< 900\text{px}$, the page adapts into a tabbed layout to ensure the terminal gets maximum screen space:

```
+──────────────────────────────────────────────────────────────+
|  🐢 zago          [ 📖 About zago ]  [ 💻 Live Demo ] (Tabs) |
+──────────────────────────────────────────────────────────────+
|                                                              |
|  [Tab: About zago]                     [Tab: Live Demo]      |
|  - Hero & Quick Install                +───────────────────+ |
|  - Why zago? & How?                    | [📁][📦][🧹][❓]   | |
|  - [👉 Launch Live Demo CTA]           |                   | |
|                                        | Terminal (xterm)  | |
|                                        | (12px Mono Font)  | |
|                                        +───────────────────+ |
|                                        | Virtual Key Bar:  | |
|                                        | [ESC][F8][F7][⇧]  | |
|                                        | [◀][▲][▼][▶]      | |
|                                        | [^O][^Q][^G]      | |
+──────────────────────────────────────────────────────────────+
|                2026 Weizhong Yang a.k.a zonble               |
+──────────────────────────────────────────────────────────────+
```

### Mobile Virtual Touch Key Bar (`#mobile-keybar`)

Because mobile software keyboards lack essential modifier and function keys, a touch key bar (`.mobile-keybar`) is positioned immediately below the terminal.

#### Key Mapping & Escape Sequences

| Key Label | `data-key` | CSS Class | Target Action | Sent Sequence / Stdin Code |
| :--- | :--- | :--- | :--- | :--- |
| **`ESC`** | `esc` | `.key-btn` | Open/close command prompt, cancel | `\x1b` (ASCII ESC) |
| **`F8`** | `f8` | `.key-btn.accent` | Toggle 2D Canvas Mode | `\x1b[19~` (VT220 F8) |
| **`F7`** | `f7` | `.key-btn.accent` | Toggle Table Mode | `\x1b[18~` (VT220 F7) |
| **`⇧`** | `shift` | `.key-btn.modifier` | Toggle sticky selection modifier | Toggles internal `shiftActive` boolean state and `aria-pressed` |
| **`◀`** | `arrow-left` | `.key-btn` | Cursor left / extend line left | Normal: `\x1b[D`<br>Shifted: `\x1b[1;2D` |
| **`▲`** | `arrow-up` | `.key-btn` | Cursor up / extend line up | Normal: `\x1b[A`<br>Shifted: `\x1b[1;2A` |
| **`▼`** | `arrow-down` | `.key-btn` | Cursor down / extend line down | Normal: `\x1b[B`<br>Shifted: `\x1b[1;2B` |
| **`▶`** | `arrow-right` | `.key-btn` | Cursor right / extend line right | Normal: `\x1b[C`<br>Shifted: `\x1b[1;2C` |
| **`^O`** | `save` | `.key-btn` | Save buffer to VFS / IndexedDB | `\x0f` (`Ctrl+O`) |
| **`^Q`** | `quit` | `.key-btn` | Exit editor to mini-shell | `\x11` (`Ctrl+Q`) |
| **`^G`** | `help` | `.key-btn` | Open built-in interactive help | `\x07` (`Ctrl+G`) |

#### Touch Handling Details
- Buttons listen to `touchstart` with `{ passive: false }` calling `preventDefault()` to eliminate mobile tap latency (avoiding 300ms delay) and prevent unintentional double-tap page zoom.
- After every touch action, `term.focus()` is automatically called to maintain keyboard focus on the terminal.

---

## 4. WASM Streaming Loader & State Transition

```
┌──────────────────────────────────────────────────────────┐
│                   Starting zago Virtual OS               │
│                                                          │
│  [==========================>                     ] 65%  │
│                                                          │
│     Downloading zago.wasm (30.5 MB / 47.0 MB)            │
│     65% completed                                        │
└──────────────────────────────────────────────────────────┘
```

1. **Chunked Stream Fetching**:
   - `fetchWasmWithProgress("zago.wasm")` consumes chunks via `ReadableStreamDefaultReader`.
   - Accommodates gzip/brotli compressed HTTP transfers where `Content-Length` (~15–18 MB) differs from raw uncompressed stream (~47 MB) by dynamically scaling `estimatedTotalBytes`.
2. **Progress Stages**:
   - `5%`: Connecting to server.
   - `1% – 95%`: Downloading byte stream with real-time MB and percentage indicator.
   - `98%`: Compiling WebAssembly bytecode & instantiating WASI runtime with IndexedDB nodes.
   - `100%`: Editor ready; hides loading overlay and triggers terminal focus.

---

## 5. Terminal Geometry & Resize Handling

- **Font Size Scaling**:
  - Desktop / Tablet ($\ge 600\text{px}$): `14px` monospace (`Menlo, Monaco, "Courier New", "Noto Sans Mono CJK TC"`).
  - Mobile ($< 600\text{px}$): Automatically downscales to `12px` to maximize column capacity.
- **FitAddon Visibility Guard**:
  - Hidden DOM containers (`display: none` when on the "About" tab) report `0×0` client dimensions.
  - `fitAndNotifyEditor()` checks `clientWidth > 0 && clientHeight > 0` before fitting.
  - When visible, sends terminal resize sequence `\x1b[8;<rows>;<cols>t` into `sharedStdin` to ensure `zago` renders to exact dimensions.

---

## 6. Restricted In-App Browsers & Cross-Origin Isolation Fallback

### Problem in Mobile In-App WebViews
When users open `zago-web` links from within social media apps on iOS or Android (such as **X / Twitter**, **LINE**, **Facebook**, or **Instagram**), the embedded `WKWebView` or In-App Browser typically disables or strictly limits:
1. `navigator.serviceWorker` registration.
2. Cross-Origin Opener Policy (`COOP`) and Cross-Origin Embedder Policy (`COEP`) header manipulation via Service Workers (`coi-serviceworker.js`).
3. `SharedArrayBuffer` memory allocation.

As a result, `window.crossOriginIsolated` remains `false`, preventing the background Web Worker and `SharedStdin` ring buffer from initializing.

---

### Detection & Fallback Strategy

Rather than hanging indefinitely or cycling page reloads, `zago-web` employs a feature-detection timeout mechanism:

```
┌──────────────────────────────────────────────────────────┐
│              ⚠️ Browser Not Supported                   │
│                                                          │
│  In-app browsers (such as X/Twitter, LINE, or Facebook) │
│  do not support WebAssembly cross-origin isolation       │
│  (SharedArrayBuffer).                                    │
│                                                          │
│  Please open this page in Safari, Chrome, or your        │
│  default browser to run the live terminal.               │
│                                                          │
│     [ 📋 Copy Page Link ]    [ 📖 View Documentation ]   │
└──────────────────────────────────────────────────────────┘
```

1. **Feature Detection Timer (2.5 Seconds)**:
   - If `typeof SharedArrayBuffer === "undefined"` or `!window.crossOriginIsolated`, a 2.5-second fallback timer starts.
   - If `coi-serviceworker.js` successfully activates and reloads the page within 2.5 seconds, the normal loading workflow proceeds.
   - If the timer expires without isolation, the UI transitions the `#wasm-loading-overlay` into an unsupported browser card.
2. **Fallback Card Elements**:
   - **Warning Icon & Title**: `⚠️ Browser Not Supported`.
   - **Guidance Text**: Explains that in-app WebViews lack `SharedArrayBuffer` support and instructs the user to switch to Safari or Chrome.
   - **Action Buttons**:
     - `📋 Copy Page Link`: Copies `window.location.href` to the clipboard with immediate visual feedback (`Copied!`).
     - `📖 View Documentation`: Switches mobile users back to the `About zago` documentation tab (`switchToDocs()`).

---

## 7. Mini-Shell & Editor Lifecycle

```
[zago exited. Type "zago" to start]
zago $ zago /workspace/demo.logo
```

When exiting the editor session (`Ctrl+Q` or `Ctrl+X`):
1. The Web Worker terminates cleanly, flushing changes to IndexedDB.
2. The UI enters a browser mini-shell mode (`zago $ `).
3. The mini-shell supports:
   - `zago`: Reopens `/workspace/welcome.md`.
   - `zago <filename>`: Opens specified file in `/workspace/`.
   - `clear`: Clears the terminal screen.
   - `Ctrl+C`: Clears the current input line.
   - `Ctrl+L`: Clears screen and reprints current input.

---

## 8. Related Documents

- [WebAssembly & Web Terminal Architecture](wasm_web_architecture.md)
- [WebAssembly Build & Deployment](../development/wasm_build.md)
- [Editor Modes & Layout](../user/modes.md)
- [Directory Mode & Permissions](../user/directory_mode.md)
- [Editor LOGO Command Reference](../logo/reference.md)
- [Diagram Snippets & Menu Rules](../features/diagram_snippets.md)