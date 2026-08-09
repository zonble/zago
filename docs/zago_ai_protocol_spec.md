# Specification: `zago` AI Editor Operation Protocol (JSON-RPC 2.0)

## 1. User Experience & Interaction Flow

The protocol is designed around a single core user experience principle: **The AI proposes live ghost previews, and the human user stays in control with dedicated non-typing modifier keybindings.**

```
 Line 14 │ # System Architecture
 Line 15 │ ┌───────────────┐     ┌───────────────┐     ┌───────────────┐  ◄─── 2. Dim Gray Ghost Text
 Line 16 │ │  Client App   │ ──► │  Auth Server  │ ──► │ Payment Gate  │
 Line 17 │ └───────────────┘     └───────────────┘     └───────────────┘
 Line 18 │                       ▲
         │                       └─── 1. Ghost Cursor [AI]
         ├────────────────────────────────────────────────────────────────────────
 Status  │ [IPC] [AI Proposal] Alt+Y/Ctrl+Y: Accept | Alt+N/Esc: Reject | Alt+R: Refine   ◄─── 3. Shortcut Hints
```

---

## 2. Text Manipulation Paradigms: 1D Stream vs. 2D Canvas & Insert vs. Overwrite

`zago` protocol methods explicitly support two insertion modes across 1D Stream Mode and 2D Canvas Mode:

### Insertion Modes: Insert vs. Overwrite vs. Transparent

| Insertion Mode | Behaviour | Primary Use Cases |
| :--- | :--- | :--- |
| **`"insert"`** *(Stream Insert)* | Inserts new text/lines at target line and column. Existing text and lines **shift right and downward**. | New paragraphs, Markdown bullet lists, code blocks. |
| **`"overwrite"`** *(Visual Overwrite)* | Overwrites characters in the visual X-Y matrix at target line/col without shifting line lengths or breaking document structure. | ASCII flowcharts, box diagrams, card boundaries. |
| **`"transparent"`** *(Transparent Overlay)* | Overwrites non-whitespace characters; spaces in the block are transparent and preserve underlying text. | Diagram labels, annotations, text stamps. |
| **`"fuse_corners"`** *(Corner Fusing Overwrite)* | Overwrites matrix and automatically fuses overlapping box corners (`┌` + `│` $\rightarrow$ `├`). | Connected ASCII flowcharts and multi-box diagrams. |

---

## 3. Protocol Method Specifications

### Domain 1: Buffer Queries (Read-Only Inspection)

#### 1.1 `zago.buffer.getText`
Returns full text or a specified line range from the active buffer.

#### 1.2 `zago.buffer.getSelection`
Returns currently selected text and block selection coordinates.

#### 1.3 `zago.buffer.getCursor`
Returns current cursor position, visual canvas column, and active editor mode (`"text"`, `"canvas"`, `"table"`).

---

### Domain 2: Ghost Text Overviews (Transient Previews)

#### 2.1 `zago.overlay.showPreview`
Renders transient **Dim Gray Ghost Text** and a virtual AI cursor (`[AI]`) on the canvas without mutating `TextBuffer`.
- **Parameters**:
  - `lines` *(Array<String>)*: Proposed ASCII flowchart, table, or diff lines.
  - `targetLine` *(Int)*: 1-based target line index.
  - `targetCol` *(Int)*: 1-based target column index.
  - `insertMode` *(String)*: `"insert"` | `"overwrite"` | `"transparent"` | `"fuse_corners"`.
- **Result**:
  ```json
  { "success": true, "previewActive": true }
  ```

#### 2.2 `zago.overlay.clearPreview`
Clears active ghost text preview.

---

### Domain 3: Text & Canvas Mutations

#### 3.1 `zago.buffer.executeLogo`
Executes sandboxed Editor LOGO script on active buffer.

#### 3.2 `zago.canvas.drawBlock`
Draws a 2D matrix block at target line and visual column.
- **Parameters**:
  - `targetLine` *(Int)*: 1-based line index.
  - `targetCol` *(Int)*: 1-based visual column index.
  - `lines` *(Array<String>)*: Block lines.
  - `insertMode` *(String)*: `"overwrite"` | `"insert"` | `"transparent"` | `"fuse_corners"`.

#### 3.3 `zago.buffer.insertText`
Inserts text sequentially at target line and column (1D Stream Insert).

---

### Domain 4: AI History & Audit Trail

#### 4.1 `zago.history.getEntries`
Queries recent AI proposal history entries and user decisions.

#### 4.2 `zago.history.reapplyEntry`
Re-applies a previously rejected or past proposal from history as a Ghost Overlay preview.

---

## 4. Permission Matrix & Security Policy

| Method | Insertion Mode | Permission Level | Default Behavior | Human Approval Required |
| :--- | :--- | :--- | :--- | :--- |
| `zago.buffer.getText` | N/A | `Read` | Allowed | No |
| `zago.buffer.getCursor` | N/A | `Read` | Allowed | No |
| `zago.overlay.showPreview` | `"insert"` / `"overwrite"` | `Transient` | Allowed (Dim Gray Ghost Text) | No |
| `zago.canvas.drawBlock` | `"overwrite"` / `"fuse"` | `Mutate` | Sandboxed | **Yes (Pushes Ghost Text; Press Alt+Y to Accept)** |
| `zago.buffer.insertText` | `"insert"` | `Mutate` | Sandboxed | **Yes (Pushes Ghost Text; Press Alt+Y to Accept)** |
| `zago.buffer.executeLogo` | Unified | `Mutate` | Sandboxed | **Yes (Pushes Ghost Text; Press Alt+Y to Accept)** |
