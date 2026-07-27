# 🐢 `se` LOGO Macro Language Guide & Specification

`se` features an innovative **LOGO-style Macro Language Engine**, bringing the clean, readable, human-friendly syntax paradigm of LOGO (`MAKE`, `:var`, `REPEAT`, `TO...END`) to TUI text buffer editing and automation.

---

## 🚀 Keybindings & Triggering

| Trigger Shortcut | Context / Input Mode | Description |
| :--- | :--- | :--- |
| **`M-l` (`Alt+L` / `Option+L`)** | Normal Edit Mode | Opens bottom LOGO Macro Prompt |
| **`M-:` (`Alt+:`)** | Normal Edit Mode | Opens bottom LOGO Macro Prompt (Vim-style `:`) |
| **`F8`** | Normal Edit Mode | Function Key shortcut to open LOGO Macro Prompt |
| **`Left / Right` (`^B` / `^F`)** | LOGO Prompt Active | Moves input cursor left / right inside the prompt |
| **`Home / End` (`^A` / `^E`)** | LOGO Prompt Active | Moves input cursor directly to prompt line start / end |
| **`Delete` / `Backspace` (`^D`)**| LOGO Prompt Active | Deletes character at / before input cursor |
| **`Up / Down` Arrows** | LOGO Prompt Active | Navigate through previously executed LOGO command history |
| **`Enter`** | LOGO Prompt Active | Execute LOGO script and save to command history |
| **`Esc` / `^C`** | LOGO Prompt Active | Cancel prompt mode |
| **`^Z`** | Normal Edit Mode | Atomic Undo: Reverts the entire LOGO macro execution in 1 step |

---

## 📖 Command Reference & Vocabulary

### 1. Text Insertion, Deletion & Line Formatting

| Command | Syntax | Description | Example |
| :--- | :--- | :--- | :--- |
| `TYPE` / `PRINT` | `TYPE "string"` or `TYPE expr` | Inserts string or calculated expression at cursor | `TYPE "Hello World"` |
| `DATE` | `DATE [format]` | Inserts current date (default: `yyyy-MM-dd`) | `DATE`, `DATE "yyyy/MM/dd"` |
| `TIME` | `TIME [format]` | Inserts current time (default: `HH:mm:ss`) | `TIME`, `TIME "HH:mm"` |
| `NEWLINE` / `NL` | `NL [count]` or `ENTER [count]` | Inserts one or $n$ newlines at current cursor | `NL`, `NEWLINE 2` |
| `LINE` / `HR` | `LINE [len] [style]` | Draws a horizontal separator line of length $n$ | `LINE 40`, `LINE 80 "double"` |
| `VLINE` / `VHR` | `VLINE [height] [style]` | Draws a vertical separator line of specified height | `VLINE 10`, `VLINE 5 "double"` |
| `DEL` / `DELETE` | `DEL [n]` | Deletes $n$ characters forward (Delete key) | `DEL 5` |
| `BS` / `BACKSPACE` | `BS [n]` | Deletes $n$ characters backward (Backspace key) | `BS 3` |

### 2. Cursor Navigation, Selection & Box Framing

| Command | Syntax | Description | Example |
| :--- | :--- | :--- | :--- |
| `MOVE` | `MOVE UP / DOWN / LEFT / RIGHT / HOME / END` | Moves cursor in 2D virtual lines | `MOVE DOWN` |
| `GOTO` | `GOTO line [column]` | Jumps directly to specified 1-indexed line and column | `GOTO 10`, `GOTO 42 5`, `GOTO :line` |
| `BOX` | `BOX "text" [style]` | Draws box frame around specified multi-line text | `BOX "Hello World"`, `BOX "Hi" "double"` |
| `BOX` | `BOX width height [style]` | Draws empty box frame of specified width and height | `BOX 20 5 "round"`, `BOX 10 4 "ascii"` |
| `BOX` | `BOX SELECTION [style]` | Encloses active text selection region in box frame | `BOX SELECTION "double"` |
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

Generates `1.`, `2.`, `3.`, `4.`, `5.` lines automatically:

```logo
MAKE "i" 1 REPEAT 5 [ TYPE :i TYPE ". List item" MOVE DOWN MOVE HOME MAKE "i" (:i + 1) ]
```

### 2. Batch Commenting Code Block

Adds `// TODO:` prefix to 3 consecutive lines:

```logo
REPEAT 3 [ MOVE HOME TYPE "// TODO: " MOVE DOWN ]
```

### 3. Multiplication Calculation & Insertion

Calculates $4 \times 25$ and inserts result directly into the buffer:

```logo
TYPE "Total: $" TYPE ( 4 * 25 )
```

### 4. Framed Announcement Box Generator (`BOX`)

Generates a double-line framed warning box automatically around text:

```logo
BOX "WARNING: Disk Space Low" "double"
```

*Output:*

```text
╔═════════════════════════╗
║ WARNING: Disk Space Low ║
╚═════════════════════════╝
```

### 5. Document Section Separator Line (`LINE` & `NEWLINE`)

Inserts section title, blank lines, and an 80-column double separator line:

```logo
TYPE "SECTION 1: INTRODUCTION" NL 2 LINE 80 "double" NL TYPE "Body content starts here..."
```

### 6. Multi-Column Layout Generator (`VLINE` & `GOTO`)

Draws a 2-column layout with vertical separator line (`║`) and header line:

```logo
TYPE "Col A" GOTO 1 10 TYPE "Col B" GOTO 2 8 VLINE 4 "double" GOTO 2 1 LINE 20
```

*Output:*

```text
Col A   ║ Col B
────────║───────────
        ║
        ║
        ║
```

### 7. Selection Enclosing Box (`BOX SELECTION`)

Highlight any block of code or text in `se` using `Shift+Arrows` and execute:

```logo
BOX SELECTION "round"
```

### 8. Automatic Timestamped Log Header (`DATE`, `TIME` & `LINE`)

Generates an automatic timestamped log header with current date and time:

```logo
TYPE "LOG ENTRY - " DATE "yyyy/MM/dd" TYPE " " TIME "HH:mm:ss" NL LINE 50 "double"
```

*Output:*

```text
LOG ENTRY - 2026/07/28 02:24:45
══════════════════════════════════════════════════
```

### 9. Smart Line Junction Fusion (`BOX` + `VLINE` / `LINE`)
When drawing horizontal (`LINE`) or vertical (`VLINE`) lines that cross existing boxes or lines, `se` automatically calculates 4-directional connection masks ($\uparrow\rightarrow\downarrow\leftarrow$) and fuses intersections into seamless T-junctions (`┬`, `┴`, `├`, `┤`) or 4-way Crosses (`┼`, `╬`):

```logo
BOX 6 3 GOTO 1 3 VLINE 3
```

*Output (automatically fused T-junctions at top and bottom borders):*
```text
┌─┬──┐
│ │  │
└─┴──┘
```

---

## 🧪 Atomic Undo (`^Z`) Guarantee

All operations performed by a single LOGO macro execution—regardless of how many lines or characters were inserted or modified—are grouped into a **single atomic Undo snapshot**.

Pressing **`^Z`** once after running a macro will completely revert the text buffer and cursor position to its exact state before the macro was triggered.
