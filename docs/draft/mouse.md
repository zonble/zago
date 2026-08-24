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

---

## 4. Architecture & Data Structures

### 4.1 Type System Hierarchy (`Config` Module)

To provide strict type safety across the input pipeline, `zago` separates input events into a top-level `InputEvent` enum:

```swift
/// Top-level terminal input event
public enum InputEvent: Equatable, Hashable, Sendable {
    case key(Key)
    case mouse(MouseEvent)
}

/// Represents mouse interactions captured by the terminal driver
public struct MouseEvent: Equatable, Hashable, Sendable {
    public enum Action: Equatable, Hashable, Sendable {
        case press(Button)
        case release(Button)
        case drag(Button)
        case scrollUp
        case scrollDown
    }

    public enum Button: Equatable, Hashable, Sendable {
        case left
        case middle
        case right
    }

    public let action: Action
    public let col: Int      // Native 1-based column (1..cols) matching SGR 1006
    public let row: Int      // Native 1-based row (1..rows) matching SGR 1006
    public let shift: Bool
    public let alt: Bool
    public let ctrl: Bool

    public init(
        action: Action,
        col: Int,
        row: Int,
        shift: Bool = false,
        alt: Bool = false,
        ctrl: Bool = false
    ) {
        self.action = action
        self.col = col
        self.row = row
        self.shift = shift
        self.alt = alt
        self.ctrl = ctrl
    }
}

/// Active continuous drag auto-scroll state managed by Editor
public struct BoundaryDragScrollState: Equatable, Sendable {
    public var lastEvent: MouseEvent
    public var intervalMs: Int

    public init(lastEvent: MouseEvent, intervalMs: Int) {
        self.lastEvent = lastEvent
        self.intervalMs = intervalMs
    }
}
```

---

## 5. Terminal Driver & Protocol Implementation

### 5.1 POSIX (macOS & Linux) & WebAssembly (xterm.js)

1. **Enablement Sequences**:
   - `\e[?1000h` : Enable standard X10 mouse tracking (button press).
   - `\e[?1002h` : Enable button event tracking (button press, release, and drag motion).
   - `\e[?1006h` : Enable SGR 1006 extended mode (allows coordinates beyond 223 columns/rows without ASCII wrapping).
2. **Disabling Sequences**:
   - `\e[?1006l\e[?1002l\e[?1000l` : Sent on terminal teardown or when mouse is disabled.
3. **Sequence Decoding**:
   - Pattern: `\e[<` `button` `;` `col` `;` `row` (`M` | `m`)
   - `button` flags:
     - `0`: Left button
     - `1`: Middle button
     - `2`: Right button
     - `32`: Drag motion with button down
     - `64`: Scroll wheel Up
     - `65`: Scroll wheel Down
     - Modifier bits: `+4` (Shift), `+8` (Alt/Meta), `+16` (Ctrl)
   - Final character: `M` indicates press / drag / scroll; `m` indicates release.

### 5.2 Windows Terminal (Win32 Console)

- Enables `ENABLE_MOUSE_INPUT` via `SetConsoleMode`.
- Intercepts `MOUSE_EVENT_RECORD` inside `ReadConsoleInputW`.
- Translates `FROM_LEFT_1ST_BUTTON_PRESSED`, `RIGHTMOST_BUTTON_PRESSED`, `MOUSE_MOVED`, and `MOUSE_WHEELED` to `MouseEvent`.

---

## 6. Hit-Testing & Coordinate Mapping

### 6.1 Text Mode Mapping

Given a click at screen coordinate $(col, row)$ (1-based):

1. **Vertical Offset**: `targetVLineIndex = (row - 1 - topMargin) + topVLineIndex`.
2. **Horizontal Gutter Subtraction**: If line numbers are enabled, subtract `gutterWidth = lineNumWidth + 2`.
3. **Virtual Line Resolution**: Map `(targetVLineIndex, adjustedCol)` to buffer `(lineIndex, columnIndex)` using `LayoutEngine.getBufferPosition(fromVirtualLineIndex:column:)` with CJK fullwidth character awareness.

### 6.2 Canvas Mode 2D Coordinate Mapping

1. `canvasY = (row - 1 - topMargin) + topVLineIndex`.
2. `canvasX = (col - 1 - gutterWidth) + canvasHorizontalOffset`.
3. Cursor or mark boundary is updated directly to $(canvasX, canvasY)$.

### 6.3 Bottom Help Bar Hit-Testing

- When rendering the Help Bar, compute the exact `[startCol, endCol]` character range for each shortcut item.
- Clicking inside an item's bounding box executes that item's key action immediately.

---

## 7. Drag Selection Auto-Scrolling

When dragging to select text or 2D canvas blocks beyond the visible viewport boundaries, `zago` automatically scrolls the viewport and extends the selection:

### 7.1 Trigger Zones & Boundary Detection

1. **Top Overflow (`row <= topMargin`)**:
   - When the drag position reaches or moves above the top margin (e.g. Title Bar, Ruler, or above screen), the viewport automatically scrolls up by 1 line (`topVLineIndex = max(0, topVLineIndex - 1)`).
   - The selection cursor extends upward to the newly visible top line.
2. **Bottom Overflow (`row > topMargin + mainAreaHeight`)**:
   - When the drag position reaches or moves below the bottom margin (e.g. Status line, Help bar, or below screen), the viewport automatically scrolls down by 1 line (`topVLineIndex += 1` if within buffer bounds).
   - The selection cursor extends downward to the newly visible bottom line.
3. **Canvas Horizontal Overflow (Canvas Mode <kbd>F8</kbd>)**:
   - Left overflow (`col <= 1 + gutterWidth`): scrolls horizontally left (`canvasHorizontalOffset = max(0, canvasHorizontalOffset - 2)`).
   - Right overflow (`col > cols`): scrolls horizontally right (`canvasHorizontalOffset += 2`).
   - The 2D selection rectangle (`canvasBlockMarkEnd`) updates to the newly scrolled coordinate.

### 7.2 Selection Anchor & Clamping

- The selection anchor (`selectionMark` or `canvasBlockMark`) remains fixed at the initial click origin.
- The active cursor (`lineIndex`, `columnIndex` or `canvasBlockMarkEnd`) advances continuously with every scroll tick.
- In **Text Mode** and **Table Mode**, scrolling and selection are strictly clamped to existing buffer lines and cell bounds without auto-inserting extra lines.

### 7.3 Continuous Edge-Holding Auto-Scroll

When holding the mouse button down at or beyond the screen boundaries without moving the physical mouse, the terminal emulator stops sending motion events. `zago` uses a non-blocking event-loop poll timeout (`readInputEvent(timeoutMs:)`) to maintain smooth, continuous scrolling:

```text
       ┌────────────────────────────────────────────────────────┐
       │   Tier 2: Outside Window Top (row <= 0) → 30ms/tick    │
       ├────────────────────────────────────────────────────────┤
       │   Tier 1: Top Margin / Title Bar (row 1..2) → 60ms     │
       ├────────────────────────────────────────────────────────┤
       │                                                        │
       │                   Normal Editing Area                  │
       │              (Drag selects without scroll)             │
       │                                                        │
       ├────────────────────────────────────────────────────────┤
       │   Tier 1: Bottom Margin / Help Bar (row 23..24) → 60ms │
       ├────────────────────────────────────────────────────────┤
       │   Tier 2: Outside Window Bottom (row > 24) → 30ms/tick │
       └────────────────────────────────────────────────────────┘
```

1. **Two-Tier Dynamic Speed**:
   - **Boundary Rows (Tier 1)**: When hovering on the edge UI rows (Title Bar `row <= topMargin` or Help Bar `row > topMargin + mainAreaHeight`, or Canvas Gutter / Right margin), scrolls at **60 ms per tick** (1 line or 2 columns) for steady, precise positioning.
   - **Outside Window (Tier 2)**: When dragging outside the terminal bounds (`row <= 0`, `row > rows`, `col <= 0`, `col > cols`), automatically accelerates to **30 ms per tick** for rapid scrolling through long documents.
2. **State Lifecycle**:
   - **Activated**: Entering boundary zones during `.drag(.left)`.
   - **Deactivated**: Releasing the button (`.release(.left)`), dragging back inside the normal text area, or pressing any key. Returns to zero-overhead blocking I/O immediately.