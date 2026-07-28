# 🐢 `se` LOGO Macro Language Guide & Specification

`se` features an innovative **LOGO-style Macro Language Engine**, bringing the clean, readable, human-friendly syntax paradigm of LOGO (`MAKE`, `:var`, `REPEAT`, `IF`, `IFELSE`, `TO...END`) to TUI text buffer editing and automation.

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
| **`Ctrl+Backspace` (`Ctrl+BS`)**| LOGO Prompt Active | Clears entire prompt input line |
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
| `DATE` | `DATE [format]` | Evaluates/inserts current date (format: `YYYY/MM/DD` or `yyyy-MM-dd`) | `DATE`, `MAKE "d" DATE "YYYY/MM/DD"` |
| `TIME` | `TIME [format]` | Evaluates/inserts current time (default: `HH:mm:ss`) | `TIME`, `TIME "HH:mm"` |
| `NEWLINE` / `NL` | `NL [count]` or `ENTER [count]` | Inserts one or $n$ newlines at current cursor | `NL`, `NEWLINE 2` |
| `LINE` / `HR` | `LINE [len] [style]` | Draws a horizontal separator line with Smart Junction Fusion | `LINE 40`, `LINE 80 "double"` |
| `VLINE` / `VHR` | `VLINE [height] [style]` | Draws a vertical separator line with Smart Junction Fusion | `VLINE 10`, `VLINE 5 "double"` |
| `DEL` / `DELETE` | `DEL [n]` | Deletes $n$ characters forward (Delete key) | `DEL 5` |
| `BS` / `BACKSPACE` | `BS [n]` | Deletes $n$ characters backward (Backspace key) | `BS 3` |

### 2. Classical Turtle Graphics & Motion

| Command | Syntax | Description | Example |
| :--- | :--- | :--- | :--- |
| `PD` / `PENDOWN` | `PD` | Pen Down: activates drawing mode while moving turtle | `PD` |
| `PU` / `PENUP` | `PU` | Pen Up: deactivates drawing mode (moves without drawing) | `PU` |
| `FD` / `FORWARD` | `FD [dist]` | Move turtle forward $n$ steps in current heading | `FD 5`, `FD 10` |
| `BK` / `BACK` | `BK [dist]` | Move turtle backward $n$ steps in opposite heading | `BK 3` |
| `RT` / `RIGHT` | `RT [angle]` | Turn turtle right 90° (or specified angle) | `RT`, `RT 90` |
| `LT` / `LEFT` | `LT [angle]` | Turn turtle left 90° (or specified angle) | `LT`, `LT 90` |

### 3. Cursor Navigation, Selection & 2D Canvas Overlay Box Framing

| Command | Syntax | Description | Example |
| :--- | :--- | :--- | :--- |
| `MOVE` | `MOVE UP / DOWN / LEFT / RIGHT / HOME / END` | Moves cursor in 2D virtual lines | `MOVE DOWN` |
| `GOTO` | `GOTO line [column]` | Jumps directly to specified 1-indexed line and column | `GOTO 10`, `GOTO 42 5`, `GOTO :line` |
| `BOX` | `BOX "text" [style]` | 2D Canvas Overlay box around text (preserves line indents) | `BOX "Hello World"`, `BOX DATE "YYYY/MM/DD"` |
| `BOX` | `BOX width height [style]` | 2D Canvas Overlay empty box (preserves background text) | `BOX 20 5 "round"`, `BOX 10 4 "ascii"` |
| `BOX` | `BOX SELECTION [style]` | Encloses active text selection region in box frame | `BOX SELECTION "double"` |
| `MARK` | `MARK` | Toggles text selection mark | `MARK` |
| `CUT` | `CUT` | Cuts selected text or current line to clipboard | `CUT` |
| `PASTE` / `UNCUT` | `PASTE` | Pastes clipboard text at current cursor | `PASTE` |
| `JUSTIFY` | `JUSTIFY` | Reflows and justifies current paragraph | `JUSTIFY` |
| `FIND` / `SEARCH` | `FIND "query"` | Case-insensitive forward text search | `FIND "func"` |

### 4. Variables, Arithmetic Expressions & Settings

| Command | Syntax | Description | Example |
| :--- | :--- | :--- | :--- |
| `MAKE` / `VAR` | `MAKE "var" expr` | Assigns expression, date, or calculation to variable | `MAKE "i" 1`, `MAKE "d" DATE "YYYY/MM/DD"` |
| `:var` | `:var_name` | Dereferences variable value | `TYPE :i`, `BOX :d` |
| `MSG` / `SHOW` | `MSG expr` | Displays text, variable, or calculation in status bar | `MSG "Today: " + DATE "YYYY/MM/DD"` |
| Math Operators | `+ - * / %` | Evaluates arithmetic expressions and parentheses | `TYPE ( 10 + 20 )` |
| `SET` | `SET setting [arg]` | Dynamically updates editor configuration settings | `SET RULER ON`, `SET WRAP 80` |

### 5. Conditionals, Control Flow & Procedures

| Command | Syntax | Description | Example |
| :--- | :--- | :--- | :--- |
| `IF` | `IF condition [ ... ]` | Executes block if condition (`==`, `!=`, `<`, `<=`, `>`, `>=`) is true | `IF :i > 5 [ TYPE "OK" ]` |
| `IFELSE` | `IFELSE cond [ true_block ] [ false_block ]` | Executes first block if true, second block if false | `IFELSE :i == 2 [ TYPE "TWO" ] [ TYPE :i ]` |
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

### 1. Conditional Formatting & Loop (`IFELSE` & `REPEAT`)

Iterates 3 times, checking if loop counter `:i == 2` to output `"TWO"` or the number itself:

```logo
MAKE "i" 1 REPEAT 3 [ IFELSE :i == 2 [ TYPE "TWO " ] [ TYPE :i TYPE " " ] MAKE "i" ( :i + 1 ) ]
```

*Output:*

```text
1 TWO 3 
```

### 2. Variable Date Assignment & Box Framing (`DATE` & `BOX`)

Stores formatted current date into variable `:d` and wraps it inside a framed box:

```logo
MAKE "d" DATE "YYYY/MM/DD" BOX :d "double"
```

*Output:*

```text
╔════════════╗
║ 2026/07/28 ║
╚════════════╝
```

### 3. Automatic Numbered List Generator

Generates `1.`, `2.`, `3.`, `4.`, `5.` lines automatically:

```logo
MAKE "i" 1 REPEAT 5 [ TYPE :i TYPE ". List item" MOVE DOWN MOVE HOME MAKE "i" (:i + 1) ]
```

### 4. 2D Canvas Overlay Box Framing (`BOX`)

Inserts a box frame over existing background text starting at column 3, preserving leading text before column 3 and pushing trailing text to the right:

```logo
BOX 5 3 "ascii"
```

*Output on background text `AAAAAA` / `BBBBBB` / `CCCCCC`:*

```text
AAA+---+AAA
BBB|   |BBB
CCC+---+CCC
```

### 5. Multi-Column Layout Generator (`VLINE` & `GOTO`)

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

### 6. Classical Turtle Graphics Square Box (`FD`, `RT`, `PD`)

Draws a 5x5 square frame using classic LOGO Turtle Graphics with Pen Down and 90° right turns:

```logo
PD REPEAT 4 [ FD 5 RT 90 ]
```

*Output (automatically fused corner junctions):*

```text
┌────┐
│    │
│    │
│    │
└────┘
```

---

## 🧪 Atomic Undo (`^Z`) Guarantee

All operations performed by a single LOGO macro execution—regardless of how many lines or characters were inserted or modified—are grouped into a **single atomic Undo snapshot**.

Pressing **`^Z`** once after running a macro will completely revert the text buffer and cursor position to its exact state before the macro was triggered.
