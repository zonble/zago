# Command Systems Architecture & Responsibility Division

This document defines the architectural division of responsibilities between **Editor Commands (`Command`)** (handling both interactive keybindings and CommandBar string prompt dispatch) and the **Editor LOGO Engine (`LogoEngine`)** in `zago`.

---

## 1. System Responsibilities Overview

```
                      ┌───────────────────────────┐
                      │  User Keyboard & Stdin    │
                      └─────────────┬─────────────┘
                                    │
           ┌────────────────────────┴────────────────────────┐
           ▼                                                 ▼
┌─────────────────────────────────────────┐       ┌────────────────────┐
│          Command (Unified)              │       │     LogoEngine     │
│  (Keybindings & CommandBar CLI Prompt)  │       │ (Language/Script)  │
└─────────────────────────────────────────┘       └────────────────────┘
```

| Dimension | `Command` (Keybinding Mode) | `Command` (CommandBar Prompt Mode) | `LogoEngine` |
| :--- | :--- | :--- | :--- |
| **Trigger Source** | Direct Keybindings (e.g. `^O`, `Alt+T`, `Tab`, `F1`) | CommandBar Prompt (`:` or `Esc` input string, e.g. `save`, `open file.txt`) | Editor LOGO code evaluation (`Ctrl+Q`, `:BOX 10 5`, script execution) |
| **Input Format** | `Key` enum events | Space-separated string tokens (`CommandBarInput`) | Parsed Editor LOGO AST / Tokens |
| **Primary Focus** | Real-time interactive UI, cursor movement, selection, mode toggling | Editor configuration, CLI commands, file operations via string args | Programmable scripting, turtle diagramming, math/string data manipulation |
| **Execution Model** | Key lookup via `CommandRegistry` -> `execute(on:)` | String match via `CommandRegistry` -> `execute(with:on:)` | Lexer -> Parser -> Evaluator (`LogoScope`) |

---

## 2. Component Details

### A. Unified Editor Commands (`Command`)
Defined under `Sources/Editor/Commands/` (organized by domain into `FileCommands.swift`, `SearchCommands.swift`, `NavigationCommands.swift`, `BufferCommands.swift`, `SettingCommands.swift`, `EditingCommands.swift`, `SelectionCommands.swift`, `TableModeCommands.swift`, `UICommands.swift`).

- **Role**: Single protocol defining all editor actions, supporting both keybindings (`keys: [Key]`) and CommandBar text aliases (`commandBarAliases: [String]`).
- **Key Responsibilities**:
  - **Interactive UI**: Cursor movement (`MoveUp`, `MoveDown`, `MoveHome`, `MoveEnd`), selection, mode toggling (`ToggleTableMode`, `ToggleCanvasMode`, `ToggleMenuBarCommand`).
  - **Text-based CLI Commands**: File management (`open <file>`, `write [file]`, `quit`), editor settings (`set wrap <col>`, `set tabsize <size>`), navigation (`goto <line>[,<col>]`, `buffer <index>`).
  - **Tab Completion**: Automatically exposes `completionNames` derived from `commandBarAliases` for context-aware Tab completion in CommandBar.
- **Design Principle**: Single Source of Truth for each command's name, description, keybindings, and CommandBar aliases.

### B. Editor LOGO Engine (`LogoEngine`)
Defined under `Sources/LogoEngine/`.

- **Role**: Pure, programmable Editor LOGO language interpreter, math engine, and turtle diagram generator.
- **Key Responsibilities**:
  - Primitive evaluation (`FORWARD`, `BACK`, `RIGHT`, `LEFT`, `BOX`, `FILL`, `TABLE`).
  - Math & Data primitives (`+`, `-`, `FIRST`, `BUTFIRST`, `LIST`, `ARRAY`).
  - Control flow & procedure definitions (`TO`, `END`, `IF`, `REPEAT`, `WHILE`).
  - Diagram generating helpers (`PRINT`, `TEXT`, `DIAGRAM`).
- **Design Principle**: A clean, reproducible, side-effect-isolated programming environment. Unknown CommandBar entries automatically fall through to `LogoEngine`.

---

## 3. Boundary Rules: What MUST NOT be put into `LogoEngine`

To maintain language purity, safety, and decoupling, the following rules **MUST** be strictly enforced:

### ❌ 1. No Interactive UI State Toggles in LOGO Primitives
- **Do NOT put**: `TOGGLE_TABLE_MODE`, `OPEN_MENU`, `SHOW_HELP_BAR`, `SWITCH_BUFFER` into LOGO primitives.
- **Reason**: LOGO code is a programmable scripting language. Scripts should produce data or canvas output, not randomly open menus or hijack terminal modal states during script execution.

### ❌ 2. No Raw ANSI Terminal I/O or Hardware Key Capture
- **Do NOT put**: Raw terminal key event listeners or terminal screen clears (`CLEAR_SCREEN_ANSI`) into LOGO primitives.
- **Reason**: LOGO operates on `TextBuffer` and `LogoEngineState`, decoupled from the actual terminal rendering engine (`Terminal.swift` / `Renderer.swift`).

### ❌ 3. No Config File Parsing or Editor Setting Mutations
- **Do NOT put**: Editor configuration parsing logic (`.zagorc` loading) inside `LogoEngine`.
- **Reason**: Configuration loading is handled by `ConfigLoader` in `Config` target. LOGO code executed from `.zagorc` should only define primitives, procedures, or variables.

---

## 4. Decision Matrix for New Features

When adding a new editor feature, use this decision matrix:

```
Is it an editor action (triggered by keypress or typed in CommandBar)?
 ├── YES ──> Implement as a `Command` (in `Sources/Editor/Commands/`)
 │            ├── Add keybindings (`keys: [...]`) for shortcut execution
 │            └── Add CommandBar aliases (`commandBarAliases: [...]`) for text execution
 └── NO  ──> Is it a programmable script function, procedure, or diagram generator?
              └── YES ──> Implement as a `LogoPrimitive` (in `Sources/LogoEngine/`)
```
