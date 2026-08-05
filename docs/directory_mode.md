# Directory Mode & Buffer Permission Architecture

This document defines the architecture, capability permissions, and command filtering rules for **Directory Mode (`DirectoryBuffer`)** in `zago`.

---

## 1. Overview & Architecture

`zago` provides a Vim `netrw`-style directory browser whenever a directory is opened (e.g. `zago .`, `open /path/to/dir`, `:e .`, `dir`, or `ls`).

Rather than adding scattered `if isDirectoryMode` checks throughout the editor engine, Directory Mode is implemented via **Buffer Polymorphism**:

```
                       ┌────────────────────────────┐
                       │     open class TextBuffer  │
                       └──────────────┬─────────────┘
                                      │
                 ┌────────────────────┴────────────────────┐
                 ▼                                         ▼
      ┌────────────────────┐                    ┌────────────────────┐
      │  ContentTextBuffer │                    │  DirectoryBuffer   │
      │  (Editable Text)   │                    │  (Read-Only Dir)   │
      └────────────────────┘                    └────────────────────┘
```

### Key Capabilities (`TextBuffer` Properties)

| Property | Default `TextBuffer` | `DirectoryBuffer` | Description |
| :--- | :--- | :--- | :--- |
| `isReadOnly` | `false` | `true` | Prevents text mutation and accidental saves |
| `allowsLogoExecution` | `true` | `false` | **Strictly blocks LOGO drawing/evaluation** |
| `isDirectoryBuffer` | `false` | `true` | Identifies directory listing buffer |

---

## 2. Directory Buffer Key Navigation Rules

In Directory Mode:

- **`Enter`**:
    - On `.. (up a dir)`: Navigates up to parent directory.
    - On `▸ folder/`: Navigates into child directory.
    - On `filename`: Opens the file as a standard editable `TextBuffer`.
    - On empty or header lines: **Consumes key without modifying text** (never inserts a newline).
- **`Backspace` / `u` / `b`**: Navigates up to parent directory.
- **`arrowUp` / `arrowDown` / `j` / `k`**: Navigates cursor through directory entries.
- **Text Editing Keys**: Blocked with status message `"Directory buffer is read-only"`.

---

## 3. Command Bar Permission Matrix (`Esc` Prompt)

The Command Bar validates commands against `CommandBarCommand.isAvailable(in: editor)` and blocks unauthorized fallthrough to `LogoEngine`.

| Command / Category | Example | Status in Dir Mode | Handling / Reason |
| :--- | :--- | :--- | :--- |
| **Directory Navigation** | `dir [path]`, `ls [path]` | 🟢 **Allowed** | Refreshes or opens target directory listing |
| **File Opening** | `open <path>`, `:e <path>`, `new` | 🟢 **Allowed** | Opens file/directory or creates new buffer |
| **Buffer Management** | `buffer <idx>`, `bnext`, `bp` | 🟢 **Allowed** | Switches between open buffers |
| **Exit & Close** | `q`, `:q`, `q!`, `:wq`, `:x` | 🟢 **Allowed** | Closes directory buffer or exits editor |
| **Save As** | `w <path>`, `write <path>` | 🟢 **Allowed** | Saves current directory listing text to a new file |
| **Navigation & Search** | `:123`, `/query` | 🟢 **Allowed** | Jumps line or searches text in listing |
| **Settings** | `set <setting>`, `unset <setting>` | 🟢 **Allowed** | Modifies display settings (e.g. ruler, wrap) |
| **No-path Save** | `w`, `:w` | 🔴 **Blocked** | Protected by `isReadOnly` |
| **String Substitution** | `s/old/new/`, `%s/old/new/g` | 🔴 **Blocked** | Protected by `isReadOnly` |
| **LOGO Drawing / Code** | `BOX 30 4`, `LINE`, `FILL`, `REPEAT ...` | 🔴 **Strictly Blocked** | **Blocked by `allowsLogoExecution`** |

### Fallthrough LOGO Guard Rule

When a user types an unmapped command into the Command Bar:

```swift
guard editor.buffer.allowsLogoExecution else {
    editor.setStatusMessage(L10n["status.directory_buffer_readonly"])
    return .handled // 100% blocked before calling LogoEngine
}
```

---

## 4. Menu Bar Visibility & Enablement Matrix

Menu categories and items use declarative capability predicates (`isVisible`, `isEnabled`) based on `TextBuffer` capability properties.

| Menu Category | Item | Predicate Rule | Behavior in Directory Mode |
| :--- | :--- | :--- | :--- |
| **File (檔案)** | New, Open, Exit, Config | Always visible | 🟢 **Visible & Active** |
| | Save (`.fileSave`) | `isEnabled: { !$0.buffer.isReadOnly }` | 🔴 **Disabled / Blocked** |
| **Edit (編輯)** | Search, Goto Line | Always visible | 🟢 **Visible & Active** |
| | Undo, Cut, Paste, Delete Line, Justify, Spell | `isEnabled: { !$0.buffer.isReadOnly }` | 🔴 **Disabled / Blocked** |
| | Text Mode, Canvas Mode, Table Mode | `isEnabled: { !$0.buffer.isDirectoryBuffer }` | 🔴 **Disabled / Blocked** |
| **Buffer (緩衝區)** | Next Buffer, Prev Buffer | Always visible | 🟢 **Visible & Active** |
| **Shapes (圖形)** | Box, DrawBox, Line, Table, Fill, Frame | `isVisible: { $0.buffer.allowsLogoExecution }` | 🔴 **Category Hidden** |
| **Borders (邊框)** | Border Style Presets | Always visible | 🟢 **Visible & Active** |
| **Tools (工具)** | Line Numbers, Ruler, Wrap Column | Always visible | 🟢 **Visible & Active** |
| | LOGO Prompt (`:logo`), Eval LOGO (`Ctrl+Q`) | `isVisible: { $0.buffer.allowsLogoExecution }` | 🔴 **Hidden / Blocked** |
| **Diagrams (圖表)** | Snippet Menu Categories | `isVisible: { $0.buffer.allowsLogoExecution }` | 🔴 **Category Hidden** |

---

## 5. Architectural Benefits

1. **Declarative & Data-Driven**: Visibility and execution rules are declared alongside commands and menu items rather than scattered throughout `Editor.swift`.
2. **Buffer Agnostic**: Menu and Command Bar systems query capability properties (`allowsLogoExecution`, `isReadOnly`) rather than checking concrete types, enabling seamless addition of future specialized buffer types (e.g. Help buffers, Diff buffers).
3. **Zero LOGO Leakage**: No LOGO commands or turtle graphics can ever execute in Directory Mode.
