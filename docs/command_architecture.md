# Command Systems Architecture & Responsibility Division

This document defines the architectural division of responsibilities among **Interactive Editor Commands (`Command`)**, **Command Bar Commands (`CommandBarCommand`)**, and the **LOGO Engine (`LogoEngine`)** in `zago`.

---

## 1. System Responsibilities Overview

```
                      ┌───────────────────────────┐
                      │  User Keyboard & Stdin    │
                      └─────────────┬─────────────┘
                                    │
           ┌────────────────────────┼────────────────────────┐
           ▼                        ▼                        ▼
┌────────────────────┐    ┌──────────────────┐    ┌────────────────────┐
│   Command (Key)    │    │ CommandBarCommand│    │    LogoEngine      │
│  (Interactive UI)  │    │  (Editor CLI)    │    │ (Language/Script)  │
└────────────────────┘    └──────────────────┘    └────────────────────┘
```

| Dimension | `Command` | `CommandBarCommand` | `LogoEngine` |
| :--- | :--- | :--- | :--- |
| **Trigger Source** | Direct Keybindings (e.g. `Ctrl+O`, `Alt+T`, `Tab`, `F1`) | Command Bar Prompt (`:` or `Esc` input string, e.g. `:open file.txt`) | LOGO code evaluation (`Ctrl+Q`, `:BOX 10 5`, script execution) |
| **Input Format** | `Key` enum events | Space-separated string tokens (`String`) | Parsed LOGO AST / Tokens |
| **Primary Focus** | Real-time interactive UI, cursor movement, selection, mode toggling | Editor configuration, CLI commands, file operations via string args | Programmable scripting, turtle diagramming, math/string data manipulation |
| **Execution Model** | Synchronous, event-driven | String dispatch via `CommandRegistry` | Lexer -> Parser -> Evaluator (`LogoScope`) |

---

## 2. Component Details

### A. Interactive Editor Commands (`Command`)
Defined under `Sources/Editor/Commands/`.

- **Role**: Handles real-time, interactive UI actions triggered directly by keyboard shortcuts.
- **Key Responsibilities**:
  - Cursor movement (`NavigateUp`, `NavigateDown`, `Home`, `End`).
  - Editing operations (`InsertTab`, `DeleteLine`, `UncutText`, `JustifyParagraph`).
  - Mode toggling & dialog triggers (`ToggleTableMode`, `ToggleCanvasMode`, `ActivateMenuBar`).
- **Design Principle**: Must be fast, synchronous, and directly bound to UI state (`Editor`).

### B. Command Bar Commands (`CommandBarCommand`)
Defined under `Sources/Editor/Commands/CommandBarCommands.swift`.

- **Role**: Text-based editor command line interface entered via the `: / Esc` prompt.
- **Key Responsibilities**:
  - File management (`open <file>`, `write [file]`, `quit`).
  - Editor settings (`set wrap <col>`, `set tabwidth <size>`).
  - Navigation (`goto <line>[,<col>]`, `buffer <index>`).
  - Fallback gateway: Unknown commands are evaluated as LOGO expressions/scripts.
- **Design Principle**: String-based command dispatch with clear argument validation and user-facing status reporting.

### C. LOGO Engine (`LogoEngine`)
Defined under `Sources/LogoEngine/`.

- **Role**: Pure, programmable LOGO language interpreter, math engine, and turtle diagram generator.
- **Key Responsibilities**:
  - Primitive evaluation (`FORWARD`, `BACK`, `RIGHT`, `LEFT`, `BOX`, `FILL`, `TABLE`).
  - Math & Data primitives (`+`, `-`, `FIRST`, `BUTFIRST`, `LIST`, `ARRAY`).
  - Control flow & procedure definitions (`TO`, `END`, `IF`, `REPEAT`, `WHILE`).
  - Diagram generating helpers (`PRINT`, `TEXT`, `DIAGRAM`).
- **Design Principle**: A clean, reproducible, side-effect-isolated programming environment.

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
- **Reason**: Configuration loading is an editor lifecycle concern handled by `ConfigLoader`. LOGO code executed from `.zagorc` should only define primitives, procedures, or variables.

---

## 4. Decision Matrix for New Features

When adding a new feature, use this matrix to decide where it belongs:

```
Is it triggered by a direct keypress?
 ├── YES ──> Implement as a `Command` (in `Commands/`)
 └── NO  ──> Is it typed as a string command like `:open` or `:goto`?
              ├── YES ──> Implement as a `CommandBarCommand` (in `CommandRegistry`)
              └── NO  ──> Is it a programmable script function or diagram generator?
                           └── YES ──> Implement as a `LogoPrimitive` (in `LogoEngine/`)
```
