# Mouse Interaction Specification

This document defines the mouse input handling specification for the `zago` terminal editor across different editing modes, views, menus, and prompt states.

---

## 1. Overview & Terminal Protocol

- **Protocol**: `zago` utilizes ANSI / VT100 Extended SGR 1006 Mouse Tracking (`\e[?1000h`, `\e[?1002h`, `\e[?1006h`) to capture click, drag, right-click, and scroll events.
- **Platform Parity**: Mouse handling behaves consistently across native terminals (macOS, Linux, Windows Terminal) and WebAssembly (xterm.js).

### Enablement & Configuration

- **Default State**: Mouse interaction is enabled by default.
- **Configuration (`~/.zagorc`)**:
  ```ini
  set mouse on     ; default
  set mouse off    ; disable terminal mouse reporting
  ```
- **Command-Line Arguments**:
  - `--mouse` : Force enable mouse tracking.
  - `--no-mouse` : Disable mouse tracking (leaves terminal mouse selection to the native terminal emulator).

---

## 2. Mode-Specific Mouse Behaviors

### 2.1 Text Mode (Normal Editing)

| Action | Target | Result |
| :--- | :--- | :--- |
| **Left Click** | Text Area | Repositions the cursor within the text flow (clamped to line length and grapheme cluster boundaries). |
| **Left Drag** (Press + Move) | Text Area | Selects a continuous range of text flow. |
| **Right Click** | Text Area | Activates and displays the Top Menu Bar. |
| **Scroll Wheel (Up / Down)** | Viewport | Scrolls the viewport vertically. |
| **Left Click** | Bottom Help Bar | Triggers the action associated with the clicked shortcut key. |
| *Modal Active* | Any | Normal mode mouse events are suspended while prompts, dialogs, or menus are open. |

---

### 2.2 Canvas Mode (<kbd>F8</kbd>)

| Action | Target | Result |
| :--- | :--- | :--- |
| **Left Click** | Canvas Area | Freely positions the cursor at the exact 2D $(x, y)$ coordinate on the canvas grid. |
| **Left Drag** (Press + Move) | Canvas Area | Defines and resizes a rectangular 2D marked region. |
| **Right Click** | Marked Region Present | Cancels and clears the current 2D marked region. |
| **Right Click** | No Marked Region | Activates and displays the Top Menu Bar. |
| **Scroll Wheel (Up / Down)** | Viewport | Scrolls the 2D canvas viewport vertically. |
| **Left Click** | Bottom Help Bar | Executes the clicked Canvas Mode action / shortcut. |

---

### 2.3 Table Mode (<kbd>F7</kbd>)

| Action | Target | Result |
| :--- | :--- | :--- |
| **Left Click** | Text Area | Constrained within the active cell; moves the cursor within the current cell's text flow. |
| **Left Drag** (Press + Move) | Active Cell | Selects text strictly within the active cell without affecting table borders. |
| **Right Click** | Table Area | Activates and displays the Top Menu Bar. |
| **Scroll Wheel (Up / Down)** | Viewport | Scrolls the viewport vertically. |
| **Left Click** | Bottom Help Bar | Triggers the clicked table navigation/action item. |

---

### 2.4 Directory Browser Buffer (`:dir`)

| Action | Target | Result |
| :--- | :--- | :--- |
| **Left Click** | Entry Line | Moves focus/cursor to the targeted file or directory item. |
| **Scroll Wheel (Up / Down)** | Buffer View | Scrolls the directory listing vertically. |
| **Right Click** | Buffer Area | No-op. |

---

### 2.5 Read-Only Text Buffers (Help & Reference)

| Action | Target | Result |
| :--- | :--- | :--- |
| **Scroll Wheel (Up / Down)** | Viewport | Scrolls the documentation buffer vertically. |
| **Left / Right Click** | Buffer Area | No-op. |

---

## 3. UI Component & Overlay Interactions

### 3.1 Top Menu Bar

When the dropdown menu bar is active:

- **Click Menu Category Header**: Switches the currently active dropdown category.
- **Click Menu Item**: Executes the selected command and automatically dismisses the menu.
- **Click Outside Menu Bar**: Dismisses and closes the menu bar, returning focus to the active buffer.
- **Click Empty Header Space**: No-op (retains the active menu state).

---

### 3.2 ESC Command Prompt & Input Dialogs

When the interactive `ESC` command prompt is visible:

- **Left Click**: Repositions the text cursor within the command input buffer.
- **Left Drag**: Selects a text span within the command input.
- **Left Click on Help Bar**: Appends or inserts the clicked Editor LOGO command primitive into the prompt buffer.

### 3.3 Single-Key Prompts & Confirmations (e.g., Save/Quit Prompts)

- Clicking a Bottom Help Bar item executes the corresponding key shortcut (e.g., `Y`, `N`, `Enter`, `ESC`).
- Clicking outside prompt controls is ignored to prevent unintended dismissals.