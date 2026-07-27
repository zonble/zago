# 🐢 `se` LOGO Macro Language Guide & Specification

`se` features an innovative **LOGO-style Macro Language Engine**, bringing the clean, readable, human-friendly syntax paradigm of LOGO (`MAKE`, `:var`, `REPEAT`, `TO...END`) to TUI text buffer editing and automation.

---

## 🚀 Keybindings & Triggering

| Trigger Shortcut | Context / Input Mode | Description |
| :--- | :--- | :--- |
| **`M-l` (`Alt+L` / `Option+L`)** | Normal Edit Mode | Opens bottom LOGO Macro Prompt |
| **`M-:` (`Alt+:`)** | Normal Edit Mode | Opens bottom LOGO Macro Prompt (Vim-style `:`) |
| **`F8`** | Normal Edit Mode | Function Key shortcut to open LOGO Macro Prompt |
| **`Up / Down` Arrows** | LOGO Prompt Active | Navigate through previously executed LOGO command history |
| **`Enter`** | LOGO Prompt Active | Execute LOGO script and save to command history |
| **`Esc` / `^C`** | LOGO Prompt Active | Cancel prompt mode |
| **`^Z`** | Normal Edit Mode | Atomic Undo: Reverts the entire LOGO macro execution in 1 step |

---

## 📖 Command Reference & Vocabulary

### 1. Text Insertion & Deletion

| Command | Syntax | Description | Example |
| :--- | :--- | :--- | :--- |
| `TYPE` / `PRINT` | `TYPE "string"` or `TYPE expr` | Inserts string or calculated expression at cursor | `TYPE "Hello World"` |
| `DEL` / `DELETE` | `DEL [n]` | Deletes $n$ characters forward (Delete key) | `DEL 5` |
| `BS` / `BACKSPACE` | `BS [n]` | Deletes $n$ characters backward (Backspace key) | `BS 3` |

### 2. Cursor Navigation & Text Selection

| Command | Syntax | Description | Example |
| :--- | :--- | :--- | :--- |
| `MOVE` | `MOVE UP / DOWN / LEFT / RIGHT / HOME / END` | Moves cursor in 2D virtual lines | `MOVE DOWN` |
| `GOTO` | `GOTO line [column]` | Jumps directly to specified 1-indexed line and column | `GOTO 10`, `GOTO 42 5`, `GOTO :line` |
| `MARK` | `MARK` | Toggles text selection mark | `MARK` |
| `CUT` | `CUT` | Cuts selected text or current line to clipboard | `CUT` |
| `PASTE` / `UNCUT` | `PASTE` | Pastes clipboard text at current cursor | `PASTE` |
| `JUSTIFY` | `JUSTIFY` | Reflows and justifies current paragraph | `JUSTIFY` |
| `FIND` / `SEARCH` | `FIND "query"` | Case-insensitive forward text search | `FIND "func"` |

### 3. Variables, Arithmetic & Editor Settings

| Command | Syntax | Description | Example |
| :--- | :--- | :--- | :--- |
| `MAKE` / `VAR` | `MAKE "var" expr` | Assigns calculated expression or string to variable | `MAKE "i" 1` |
| `:var` | `:var_name` | Dereferences variable value | `TYPE :i` |
| `MSG` / `SHOW` | `MSG expr` | Displays text, variable, or calculation in status bar | `MSG "Total: " + :total` |
| Math Operators | `+ - * / %` | Evaluates arithmetic expressions and parentheses | `TYPE ( 10 + 20 )` |
| `SET` | `SET setting [arg]` | Dynamically updates editor configuration settings | `SET RULER ON`, `SET WRAP 80` |

### 4. Control Flow & Procedures

| Command | Syntax | Description | Example |
| :--- | :--- | :--- | :--- |
| `REPEAT` | `REPEAT expr [ ... ]` | Loops enclosed code block $n$ times | `REPEAT 3 [ TYPE "! " ]` |
| `TO ... END` | `TO name ... END` | Defines custom reusable macro procedure | `TO HDR TYPE "# " END` |
| `EXEC` / Proc Call | `EXEC name` or `name` | Executes defined procedure | `EXEC HDR` |

---

## 🛠️ `~/.serc` Keybinding Integration

You can bind LOGO macro scripts directly to custom keyboard shortcuts in `~/.serc`:

```nanorc
# ~/.serc configuration file

# Bind Alt+B to generate 5 numbered list items automatically
bind alt-b "macro: MAKE 'i' 1 REPEAT 5 [ TYPE :i TYPE '. Item\n' MAKE 'i' (:i + 1) ]"

# Bind Alt+H to insert Markdown Level 1 header prefix
bind alt-h "macro: MOVE HOME TYPE '# ' MOVE END"
```

---

## 💡 Practical Real-World Macro Examples

### 1. Automatic Numbered List Generator
Generates `1. `, `2. `, `3. `, `4. `, `5. ` lines automatically:

```logo
MAKE "i" 1 REPEAT 5 [ TYPE :i TYPE ". List item" MOVE DOWN MOVE HOME MAKE "i" (:i + 1) ]
```

### 2. Batch Commenting Code Block
Adds `// TODO: ` prefix to 3 consecutive lines:

```logo
REPEAT 3 [ MOVE HOME TYPE "// TODO: " MOVE DOWN ]
```

### 3. Multiplication Calculation & Insertion
Calculates $4 \times 25$ and inserts result directly into the buffer:

```logo
TYPE "Total: $" TYPE ( 4 * 25 )
```

---

## 🧪 Atomic Undo (`^Z`) Guarantee

All operations performed by a single LOGO macro execution—regardless of how many lines or characters were inserted or modified—are grouped into a **single atomic Undo snapshot**.

Pressing **`^Z`** once after running a macro will completely revert the text buffer and cursor position to its exact state before the macro was triggered.
