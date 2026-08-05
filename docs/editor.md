# `zago` Editor Basics

`zago` is a modeless terminal text editor with built-in 2D diagramming capabilities, combining classic `nano` modeless typing and Emacs/WordStar keybindings with Editor LOGO macro drawing and structured table editing.

---

## Table of Contents

- [`zago` Editor Basics](#zago-editor-basics)
  - [Table of Contents](#table-of-contents)
  - [Overview \& Architecture](#overview--architecture)
  - [Editor Modes](#editor-modes)
  - [Keybindings Reference](#keybindings-reference)
    - [Navigation \& Movement](#navigation--movement)
    - [Text Selection \& Clipboard](#text-selection--clipboard)
    - [Editing \& Formatting](#editing--formatting)
    - [Search \& Substitution](#search--substitution)
    - [Document Links \& Navigation](#document-links--navigation)
    - [File \& Buffer Operations](#file--buffer-operations)
    - [Interface \& Menus](#interface--menus)
  - [Command Prompt \& Shorthand](#command-prompt--shorthand)
    - [Shorthand Commands](#shorthand-commands)
    - [Tab Completion](#tab-completion)
    - [LOGO Fallthrough](#logo-fallthrough)
  - [Multi-Buffer Workflow](#multi-buffer-workflow)
  - [Diagram Snippets](#diagram-snippets)
  - [Related Documentation](#related-documentation)

---

## Overview & Architecture

`zago` operates modelessly: typing normal keys inserts text directly at the cursor without requiring an "insert mode". Advanced functions—such as file saving, text searching, canvas block operations, and Editor LOGO script execution—are accessible via:

- **Control & Meta Keybindings** (e.g. `^O`, `^K`, `^U`, `M+W`, `M+V`)
- **Function Keys** (e.g. `F1` for Menu Bar)
- **Interactive Menu Bar** (`F1`)
- **Command Prompt / Command Bar** (`Esc` or `Alt+:`)
- **VT100 ANSI Double Buffering & Line Diffing Algorithm**: Flicker-free terminal rendering with line-level diffing, CJK layout caching, and hardware scroll avoidance.

---

## Editor Modes

`zago` features three dedicated operational modes designed for different editing tasks:

| Mode | Shortcut | Description |
| :--- | :--- | :--- |
| **Text Editing Mode** | *(Default)* | Modeless text editing with soft wrapping, syntax highlighting, paragraph justification (`^J`), and word-level selection. |
| **Canvas Mode** | `M+V` / Menu | 2D freehand ASCII/Unicode diagram drawing with rectangular block selection, arrow key line drawing, and LOGO turtle graphics. |

Canvas Mode automatically creates empty rows when moving or using `goto` below
the current buffer, up to `10,000` rows. Virtual columns are limited to
`10,000` columns so accidental commands cannot create extremely wide sparse
lines.
| **Table Mode** | `M+T` / Menu | Structural grid editing for ASCII/Unicode tables with automatic border preservation, cell text wrapping, centering (`^J`), and row/column resizing. |
| **Directory Mode** | Command `dir` / `ls` | Interactive file browser buffer for exploring directories, inspecting files, and opening documents safely without corrupting binary files. |

> For detailed mode rules, see [Editor Modes & Layout](modes.md) and [Directory Mode](directory_mode.md).

---

## Keybindings Reference

### Navigation & Movement

| Key | Action |
| :--- | :--- |
| `←` / `→` / `↑` / `↓` | Move cursor character/line-wise |
| `Home` / `End` | Jump to beginning/end of visual line |
| `PgUp` (`^Y`) | Page Up |
| `PgDn` (`^V`) | Page Down |
| `M+<` / `M+>` | Jump to beginning / end of buffer |
| `M+[` / `M+]` | Jump to previous / next document heading |
| `M+\` | Open current document outline picker |
| `^C` | Display current line, column, character count, and visual position info |

### Text Selection & Clipboard

| Key | Action |
| :--- | :--- |
| `Shift` + `Arrow` | Start and extend text selection (Text Mode) or draw lines (Canvas Mode) |
| `Shift` + `Home` / `End` | Extend selection to beginning / end of visual line |
| `^^` (Ctrl+^) / `M+B` | Set block mark (Canvas Mode) |
| `M+W` | Copy selected text or active canvas block to clipboard |
| `^K` | Cut selected text, active canvas block, or cut current line |
| `^U` | Paste (uncut) last copied/cut text or canvas block |
| `^G` | Cancel active text selection or canvas mark (Emacs `keyboard-quit`) |

> For detailed selection and clipboard mechanics, see [Mark & Clipboard Behavior](mark.md).

### Editing & Formatting

| Key | Action |
| :--- | :--- |
| `Tab` (`^I`) | Insert tab character or indent selection |
| `Shift` + `Tab` | Outdent / navigate previous table cell |
| `^Z` | Undo last operation |
| `^J` | Justify paragraph (Text Mode) or center text inside current table cell (Table Mode) |
| `^T` | Open interactive spell checker |
| Menu → Transform | Convert CJK spacing, convert case (UPPER, lower, Title), or transliterate scripts |

### Search & Substitution

| Key | Action |
| :--- | :--- |
| `^W` | Open search prompt (supports plain text and regex) |
| `Esc` → `:s/foo/bar/g` | Substitute text using Vim-style regex substitution on current line, selection, or entire buffer (`%s/...`) |

### Document Links & Navigation

| Key | Action |
| :--- | :--- |
| `M+O` | Open relative document link under cursor (supports Markdown `[text](path)`, Org-mode `[[path]]`, reST `:doc:` / `` `title <path>` ``, and AsciiDoc `link:path[]`) |
| `M+[` / `M+]` | Navigate previous / next heading in Markdown, Org, reStructuredText, or AsciiDoc documents |
| `M+\` | Open outline picker for headings in the current document |

### File & Buffer Operations

| Key | Action |
| :--- | :--- |
| `^O` / `^S` | Save current buffer |
| `^R` | Read and insert file into current buffer (or open Directory Buffer if directory) |
| `^X` | Close current buffer (prompts to save modified changes; exits `zago` if last buffer) |
| `^N` / `^P` | Switch to next / previous buffer |
| `^F` | Open a new empty buffer |

### Interface & Menus

| Key | Action |
| :--- | :--- |
| `F1` | Toggle top drop-down Menu Bar |
| `ruler` command | Toggle WordStar-style column ruler bar (`----!----1----!----2...`) |
| `linenumbers` command | Toggle line numbers gutter |
| `sublinenumbers` command | Toggle soft-wrap sub-line indicator numbers |

---

## Command Prompt & Shorthand

Pressing `Esc` or `Alt+:` opens the bottom Command Prompt line. It parses inputs in two steps:

1. **Shorthand Execution**: First checks if input matches built-in command shorthands (e.g. line numbers, file paths, buffer actions).
2. **LOGO Fallthrough**: If no shorthand matches, the input is evaluated directly as a LOGO expression or command script.

### Shorthand Commands

| Input Pattern | Action |
| :--- | :--- |
| `42` | Jump to line 42 |
| `42:7` / `42,7` | Jump to line 42, column 7 |
| `save` | Save current buffer |
| `save-exit` / `saveexit` / `file` / `wq` | Save current buffer and close it |
| `write <path>` | Save current buffer to specified `<path>` |
| `open <path>` / `edit <path>` | Open file at `<path>` in a new buffer |
| `new` | Create a new empty buffer |
| `close` / `exit` / `quit` / `q` | Close current buffer (with modification prompt) |
| `buffer` | Show active buffer info and count |
| `buffer next` / `bnext` | Switch to next buffer |
| `buffer prev` / `bprev` | Switch to previous buffer |
| `buffer N` | Jump to 1-based buffer index `N` |
| `dir` / `ls` | Open Directory Buffer browser for current working directory |
| `set <option> <value>` | Modify editor configuration setting (e.g., `set wrap 80`, `set ruler on`, `set canvas-mode on`) |

`set canvas-mode on/off` in the command prompt switches only the current buffer
or editor view. It is runtime mode state, not a global preference and not
document metadata.

### Tab Completion

The command prompt features intelligent context-aware `Tab` completion:

- **Command Shorthands**: Completes `save`, `open`, `write`, `buffer`, `exit`, etc.
- **Settings & Options**: Typing `set` + `Tab` lists all configurable settings (`wrap`, `ruler`, `linenumbers`, `sublinenumbers`, `canvas-mode`, `trim-trailing-whitespace`, `syntax`, `language`, `border`).
- **Save Cleanup**: `set trim-trailing-whitespace on` removes trailing spaces and tabs from each line before saving. It is off by default.
- **File Paths**: Completes relative/absolute file system paths for `open` and `write`.
- **LOGO Keywords & Macros**: Completes LOGO primitives (`BOX`, `TABLE`, `LINE`, `DRAWBOX`, `FILL`, `FD`, `RT`, `REPEAT`, etc.).

### LOGO Fallthrough

Any input that does not match a shorthand command is evaluated by the embedded LOGO engine. For example:

```logo
; Evaluate simple arithmetic (printed to status bar)
1 + 2 * 3

; Draw a box on canvas mode
BOX "Hello World" 20 5 "double"

; Run turtle graphics loop
REPEAT 4 [ FD 10 RT 90 ]
```

> For full LOGO language reference, see [LOGO Command Language](logo.md).

---

## Multi-Buffer Workflow

`zago` supports managing multiple files concurrently in tabbed/indexed buffers:

- **Opening Multiple Files**: Run `zago file1.txt file2.md` from terminal to load all files into separate buffers.
- **Creating & Opening Buffers**: Use `^F` or `open <path>` from command prompt.
- **Switching Buffers**: Use `^N` / `^P` shortcuts or `buffer next` / `buffer <N>` commands.
- **Buffer Overview**: Status bar and title bar show buffer counts (e.g., `[2/5] filename.md`).

---

## Diagram Snippets

In Markdown, AsciiDoc, Graphviz DOT, PlantUML, or Mermaid documents, `zago` provides diagram template insertion snippets:

- Trigger snippet menu via `M+D` or **Menu → Tools → Insert Diagram Snippet**.
- Automatically detects diagram code block context under cursor and inserts tailored template structures (e.g., Mermaid flowcharts, PlantUML sequence diagrams, Graphviz DOT graphs, or LOGO macro blocks).

> For detailed snippet rules and context conditions, see [Diagram Snippets & Menu Rules](diagram_snippets.md).

---

## Related Documentation

- 📐 [Editor Modes & Layout](modes.md): In-depth guide to Text, Canvas, and Table modes.
- 📋 [Mark & Clipboard Behavior](mark.md): Text selection vs 2D canvas block mark rules.
- 🐢 [LOGO Command Language](logo.md): LOGO macro drawing, turtle graphics, data types, and procedure definitions.
- ⚙️ [Configuration](configuration.md): Customizing `.zagorc`, key bindings, startup scripts, and Nano syntax definitions.
- 📂 [Directory Mode](directory_mode.md): DirectoryBuffer browsing and binary safety matrix.
- 📊 [Diagram Snippets](diagram_snippets.md): Pre-built diagram template insertion guide.
- 🧭 [Heading Navigation & Outline](heading_navigation.md): Planned document heading navigation and outline picker behavior.
