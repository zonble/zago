The following diagram represents the layout the zago web, a static web
site hosted on GitHub pages.

The web is composed by two parts. In the left, there are text to
describe what is zago, what it does and other basic infofrmation. In the
right, there is a web editor running wasm of zago to let the users to
exprience how it works - an interactive tutorial will be the placeholder
in the editor.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                            ┌────────────────────────────────────────────────┐│
│ zago                       │     [Import files][Exprt Workspace][Reset VFS] ││
│                            ├────────────────────────────────────────────────┤│
│ - Terminal Editor to       │                                                ││
│   work with AI generated   │                                                ││
│   text diagrams, using     │                                                ││
│   purely keyboard          │                                                ││
│                            │                                                ││
│                            │                                                ││
│ Why zago?                  │                                                ││
│                            │                                                ││
│ - AI brings text diagrams  │                                                ││
│   to you for planning,     │                                                ││
│   system design and so on  │                                                ││
│   but they are hard to be  │                                                ││
│   edited again.            │                                                ││
│ - Text diagrams in         │                                                ││
│   Markdown files are       │                                                ││
│   already a part of AI     │                                                ││
│   prompts.                 │                                                ││
│                            │                                                ││
│ How?                       │                                                ││
│                            │                                                ││
│ - Canvas mode editing      │                                                ││
│   allows you to move the   │                Main Editor Area                ││
│   cursor freely to edit    │                                                ││
│   anywhere in a text file  │            (need a loading progress)           ││
│ - Table mode lets you      │            (since wasm is about 6xmb)          ││
│   edit content in ascii/   │                                                ││
│   unicode tables/boxes     │                                                ││
│   without effecting the    │                                                ││
│   frames                   │                                                ││
│ - Quick drawing commands   │                                                ││
│   like "BOX", "LINE" and   │                                                ││
│   "VLINE" let you complete │                                                ││
│   a diagram in seconds.    │                                                ││
│ - CJK characters aware.    │                                                ││
│   They are layed perfectly │                                                ││
│   in boxes.                │                                                ││
│ - And more!                │                                                ││
│                            │                                                ││
│                            │                                                ││
│ Support                    │                                                ││
│                            │                                                ││
│ - macOS/Linux/Windows      │                                                ││
│ - UTF8 Terminals           │                                                ││
│                            │                                                ││
│                            └────────────────────────────────────────────────┘│
├──────────────────────────────────────────────────────────────────────────────┤
│                       2026 Weizhong Yang a.k.a zonble                        │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Mobile Adaptation & Responsive Design Strategy

### 1. Challenges on Mobile Devices
1. **Screen Width & Column Capacity**:
   - A standard 80×24 monospace terminal needs ~600px+ width to be legible. On small phone screens (375px–430px), standard layout side-by-side split is impossible, and font size must adapt to preserve diagram readability.
2. **Missing Modifier Keys & Arrow Navigation**:
   - Mobile on-screen keyboards lack physical `Ctrl`, `ESC`, `Alt`, `Tab`, and Arrow keys (`▲▼◀▶`), which are essential for GNU Nano shortcuts (`^O`, `^X`, `^G`) and zago Canvas Mode (`ESC ESC`).
3. **Viewport Height Occlusion**:
   - When the software keyboard is active, viewport height shrinks significantly, obscuring status bars and key menus.

---

### 2. Mobile Layout & Navigation Architecture

```
+──────────────────────────────────────────────────────────────+
|  🐢 zago          [ 📖 About zago ]  [ 💻 Live Demo ] (Tabs) |
+──────────────────────────────────────────────────────────────+
|                                                              |
|  [Tab: About zago]                     [Tab: Live Demo]      |
|  - What is zago?                       +───────────────────+ |
|  - Why zago? (AI text diagrams)        | Toolbar: Import / | |
|  - Canvas & Table Mode features        | Export / Reset    | |
|  - CJK spacing & alignment             |                   | |
|  - Installation instructions           | Terminal (xterm)  | |
|                                        |                   | |
|  [👉 Switch to Live Demo Button]       |                   | |
|                                        +───────────────────+ |
|                                        | Virtual Key Bar:  | |
|                                        | [ESC][Canvas][Tab]| |
|                                        | [◀][▲][▼][▶][^O]  | |
+──────────────────────────────────────────────────────────────+
|                2026 Weizhong Yang a.k.a zonble               |
+──────────────────────────────────────────────────────────────+
```

1. **Responsive Viewport Breakpoint (`< 900px`)**:
   - **Desktop (≥ 900px)**: Two-column split layout (Left: Scrollable Documentation / Right: Interactive Terminal & VFS Toolbar).
   - **Mobile (< 900px)**: Top Tab Switcher allows users to toggle seamlessly between **"📖 About zago"** (full-width readable documentation) and **"💻 Live Demo"** (full-screen terminal workspace).
   - The "About zago" tab includes a prominent call-to-action button to jump directly to the "Live Demo" tab.

2. **Mobile Virtual Key Bar**:
   - Placed directly beneath or floating with the terminal on touch devices.
   - Provides quick-touch buttons for:
     - `ESC` (`\x1b`)
     - `Canvas` (sends `\x1b\x1b` to toggle 2D Canvas Mode)
     - `Tab` (`\t`)
     - Arrow Keys: `▲` (`\x1b[A`), `▼` (`\x1b[B`), `◀` (`\x1b[D`), `▶` (`\x1b[C`)
     - `^O Save` (`\x0f`)
     - `^X Exit` (`\x18`)
     - `^G Help` (`\x07`)
   - Allows full diagram navigation and editing on mobile without requiring an external physical keyboard.

3. **WASM Streaming Download & Visual Progress Bar**:
   - Because `zago.wasm` is ~6.x MB, a visual loading overlay with real-time percentage and downloaded byte indicator (`Downloading zago.wasm 4.2 MB / 6.5 MB (65%)`) displays while fetching.
   - Smoothly fades out into the interactive editor once WebAssembly compilation and WASI instantiation are ready.

4. **Dynamic Font Scaling & Viewport Fit**:
   - Automatically adjusts xterm font size on mobile (11px–12px) and triggers `@xterm/addon-fit` recalculation on tab switch, orientation change, or window resize.