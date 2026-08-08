# Editor LOGO Diagramming & Editing Commands: Guide & Reference

`zago` provides a simple set of direct editing commands for drawing boxes, connector lines, tables, and laying out structured text directly inside your terminal buffer.

Commands read like natural editing gestures: press `Esc`, type `BOX "Title"`, `LINE ARROW`, or `TABLE`, and shape your plain text instantly without leaving your text editor.
The command prompt also recognizes editor shorthand such as `42`, `save`,
`open notes.txt`, and `buffer next` before falling back to LOGO syntax.

You do not need any programming background to use these commands—ordinary drawing and layout actions work right out of the box. As your editing tasks grow, optional variables, loops, and macro procedures are available whenever you want to automate repetitive work.

This document is divided into two main parts:

1. **The Step-by-Step Guide**: From basic box diagramming to optional automation like variables, loops, and procedures.
2. **The Complete Command Reference**: An exhaustive dictionary of all commands, math operations, data structures, and buffer settings.

---

## 🚀 Keybindings & Triggering

| Trigger Shortcut | Context / Input Mode | Description |
| :--- | :--- | :--- |
| **`Esc`** | Normal Edit Mode | Opens the bottom command prompt |
| **`Left / Right` (`^B` / `^F`)** | Command Prompt Active | Moves input cursor left / right inside the prompt |
| **`Home / End` (`^A` / `^E`)** | Command Prompt Active | Moves input cursor directly to prompt line start / end |
| **`Delete` / `Backspace` (`^D`)**| Command Prompt Active | Deletes character at / before input cursor |
| **`^BS` (`Ctrl+Backspace`)**| Command Prompt Active | Clears entire prompt input line |
| **`Up / Down` Arrows** | Command Prompt Active | Navigate through previously executed commands |
| **`Enter`** | Command Prompt Active | Execute the command and save it to history |
| **`Esc` / `^C`** | Command Prompt Active | Cancel prompt mode |
| **`^Z`** | Normal Edit Mode | Atomic Undo: Reverts the entire command execution in 1 step |

---

## Command Prompt Dispatch

The command prompt is shared by editor shorthand and LOGO.

Dispatch order:

1. Editor command shorthand
2. Numeric goto shorthand
3. LOGO script or expression

Examples handled before LOGO:

| Input | Action |
| :--- | :--- |
| `42` | Go to line 42 |
| `42:7` / `42,7` | Go to line 42, column 7 |
| `goto 42 7` | Go to line 42, column 7 |
| `save` | Save the current buffer |
| `write path` | Save the current buffer to `path` |
| `open path` / `edit path` | Open `path` in a new buffer |
| `new` | Open a new empty buffer |
| `buffer next` / `buffer prev` | Switch buffers |
| `buffer N` | Switch to 1-based buffer index `N` |

Inputs that do not match shorthand are evaluated by LOGO. For compatibility,
file and multi-buffer actions such as `save`, `open`, and `buffer 2` are handled
by the command prompt before LOGO evaluation.

# 📚 PART 1: Quick Start & Essential Diagramming Guide

Most of the time in `se`, you only need a handful of essential commands to shape structured text: **`BOX`**, **`DRAWBOX`**, **`LINE`**, **`VLINE`**, **`TABLE`**, **`TYPE`**, and **`SHOW`**.

---

### How Editor LOGO Differs from Turtle Graphics

Classic LOGO turtle graphics draws into a graphics window: the turtle has a heading, moves through a coordinate plane, and leaves a geometric trail when the pen is down.

`zago` uses LOGO as an editor macro language. Commands act on the current text buffer, cursor, selection, and status bar. Some commands are turtle-like (`PD`, `PU`, `FD`, `BK`, `RT`, `LT`), but their output is plain text: lines, corners, arrows, boxes, and tables made from terminal characters.

This means:

- The canvas is the editor buffer, not a separate graphics screen.
- Positions are text rows and columns, starting from the cursor.
- Drawing commands modify text and participate in editor undo.
- Automation features such as variables, loops, expressions, and procedures are used to repeat editing operations, not only to move a turtle.

---

### Step 1: Drawing Framed Boxes (`BOX` and `DRAWBOX`)

`BOX` draws framed text containers. It turns a plain text buffer into a structured terminal canvas.

#### `BOX` (Line-Oriented Frame)

Inserts a frame into each affected line and pushes trailing text to the right.

```logo
BOX "Hello"
```

Text boxes size themselves automatically from the text:

```logo
BOX "Status" "center" "round"
```

```text
╭────────╮
│ Status │
╰────────╯
```

Empty boxes use explicit dimensions (width & height):

```logo
BOX 30 4 ROUND
```

```text
╭────────────────────────────╮
│                            │
│                            │
╰────────────────────────────╯
```

In Canvas Mode, if a rectangular canvas block mark is active, `BOX` with no
arguments draws a frame that matches the marked block. Without a canvas block
mark, no-argument `BOX` keeps the default frame size.

`BOX` and `DRAWBOX` clamp explicit dimensions to a visible, bounded range. Widths
below `3` become `3`, heights below `2` become `2`, widths above `200` become
`200`, and heights above `100` become `100`. For example, `BOX 0`,
`BOX 1 0`, and `BOX -100 -100` all draw the smallest valid frame instead of
failing or drawing nothing.

#### `DRAWBOX` (Canvas Overlay Frame)

`DRAWBOX` accepts the same arguments as `BOX`, but draws as a canvas overlay without pushing surrounding text. Use it when composing multi-box diagrams against fixed coordinates:

```logo
DRAWBOX 30 4 ROUND
GOTO 2 2
FILL "hi
```

In Table Mode, `FILL text` fills the current table cell only. It repeats the
fill text across every editable row in the cell, clips to each row's display
width, and preserves the table borders.

Like `BOX`, no-argument `DRAWBOX` uses the active Canvas Mode block mark as its
target frame when one is present.

```text
╭────────────────────────────╮
│hihihihihihihihihihihihihihi│
│hihihihihihihihihihihihihihi│
╰────────────────────────────╯
```

`BOX SELECTION` frames the current selected region:

```logo
MARK
MOVE DOWN
BOX SELECTION DOUBLE
```

#### Supported Alignments & Styles

Supported text alignments:

- `left`
- `center` / `centre`
- `right`

Supported border styles:

- `single`: `┌ ┐ └ ┘ ─ │`
- `double`: `╔ ╗ ╚ ╝ ═ ║`
- `round` / `rounded`: `╭ ╮ ╰ ╯ ─ │`
- `double-round`: rounded corners with double horizontal/vertical strokes
- `ascii`: `+ - |`

---

### Step 2: Connector Lines & Arrow Snapping (`LINE` and `VLINE`)

`LINE` draws horizontal lines; `VLINE` draws vertical lines.

```logo
LINE 20
VLINE 5
LINE 30 DOUBLE
VLINE 4 ASCII
```

Explicit `LINE` lengths are clamped to `1...200`, and explicit `VLINE` heights
are clamped to `1...100`. This means `LINE 0`, `LINE -2`, and `LINE -100`
draw a one-cell line, while `LINE 8000000` draws 200 cells.

#### Auto-Connect Mode (No Length Specified)

When no length or height is specified (e.g., `LINE`, `VLINE`, `LINE ARROW`, `VLINE ARROW`):

- Scans forward through empty space.
- **Without `ARROW`**: Scans until it reaches an existing box border or line, then fuses into a junction (e.g., `├`, `┬`, `┼`).
- **With `ARROW`**: Scans until it reaches an existing box border, stops 1 cell before it, and places an arrowhead (`→` or `↓`) touching the border without altering the border.

Example: Connecting two boxes with `LINE ARROW`:

```logo
DRAWBOX 6 3 GOTO 2 1 LINE ARROW
```

```text
┌──────┐        ┌──────┐
│  A   ├───────>│  B   │
└──────┘        └──────┘
```

Arrow modifiers:

| Modifier | Horizontal | Vertical |
| :--- | :--- | :--- |
| `ARROW` | forward arrow at the right end: `────→` | forward arrow at the bottom end: `│` ... `↓` |
| `BACKARROW` | backward arrow at the left end: `←────` | backward arrow at the top end: `↑` ... `│` |
| `BOTHARROW` | arrows at both ends: `←──→` | arrows at both ends: `↑` ... `↓` |

Aliases:

- `RIGHTARROW` / `DOWNARROW`: same as `ARROW`
- `LEFTARROW` / `UPARROW`: same as `BACKARROW`
- `BOTH` / `BIDIR`: same as `BOTHARROW`

---

### Cursor Movement Rules for Drawing Primitives

All drawing commands start drawing at the **current cursor position** `(startLine, startCol)` and automatically update the cursor after drawing:

| Command | Width / Length | Height | Cursor Position After Execution |
| :--- | :--- | :--- | :--- |
| **`BOX` / `DRAWBOX`** | $W$ | $H$ | `(startLine, startCol + W)` *(Default: `NE` / `AT:NE` top-right alignment)* |
| **`LINE`** | $L$ | 1 | `(startLine, startCol + L)` *(On the same line, immediately past the right end of the line)* |
| **`VLINE`** | 1 | $H$ | `(startLine + H, startCol)` *(One line below the bottom end of the vertical line, at the same column)* |
| **`TABLE`** | $C \times (W + 1) + 1$ | $2R + 1$ | `(startLine + totalHeight - 1, startCol + totalWidth)` *(On the table's bottom line, immediately past the right border)* |

#### Box Exit Position Modifiers (`AT:NE`, `AT:SE`, `AT:NW`, `AT:SW`, `AT:DOWN`)

`BOX` and `DRAWBOX` accept optional exit position modifiers to control where the cursor lands after drawing:

| Modifier | Alias | Target Cursor Location |
| :--- | :--- | :--- |
| `NE` | `AT:NE`, `TOPRIGHT` | `(startLine, startCol + W)` *(Default: Top-right, for side-by-side box placement)* |
| `SE` | `AT:SE`, `BOTTOMRIGHT` | `(startLine + H - 1, startCol + W)` *(Bottom-right corner)* |
| `NW` | `AT:NW`, `TOPLEFT` | `(startLine, startCol)` *(Top-left corner / start position)* |
| `SW` | `AT:SW`, `BOTTOMLEFT` | `(startLine + H - 1, startCol)` *(Bottom-left corner)* |
| `DOWN` | `AT:DOWN`, `BOTTOM`, `S` | `(startLine + H, startCol)` *(Line immediately below the box, for stacked boxes or text)* |

*Note: Unquoted tokens like `SE` or `AT:SE` are parsed as exit positions. To draw a box containing the literal text "SE", quote it: `BOX 20 5 "SE"`.*

#### Example Flow
If cursor is at `(0, 0)`:
1. `BOX 10 3 NE` draws a $10 \times 3$ box and leaves the cursor at `(0, 10)` (top-aligned for side-by-side placement).
2. `BOX 10 3 AT:DOWN` draws a second box at `(0, 10)` and leaves the cursor at `(3, 10)` (below the box).

---

### Step 3: Creating Grid Tables (`TABLE`)

`TABLE` inserts plain-text grid tables at the cursor position.

```logo
TABLE BORDER ROUND
TABLE 2 2 16
```

`TABLE rows cols cellWidth` accepts optional numeric expressions. Rows are clamped to `1...50`, columns to `1...20`, and cell width to `1...40`.

```text
╭────────────────┬────────────────╮
│                │                │
├────────────────┼────────────────┤
│                │                │
╰────────────────┴────────────────╯
```

After creating a table, move the cursor inside it and press **`M+T`** to activate cell-by-cell Table Mode.

---

### Step 4: Text Output & Interactive Input (`TYPE`, `SHOW`, `READWORD`, `READCHAR`)

- **`TYPE "text"`** (or `PRINT`): Inserts text or calculated expressions directly at the cursor.
- **`SHOW "message"`**: Displays a status bar notification message at the bottom of the screen.
- **`READWORD "prompt"`** (or `RW`): Prompts the user for a line of text input (or reads from stdin in CLI mode).
- **`READCHAR "prompt"`** (or `RC`): Prompts the user for a single keypress (or reads from stdin in CLI mode).
- **`DATE "YYYY/MM/DD"`**: Inserts current date.
- **`TIME "HH:mm"`**: Inserts current time.

---

# 🎓 PART 2: Growing from Diagramming into Automation

Once you are comfortable drawing boxes and lines, you can optionally use variables, loops, and procedures to automate repetitive layout tasks.

---

### 1. Variables (`MAKE` and `:var`)

Assign values with `MAKE "name" value` and read them with `:name`:

```logo
MAKE "w" 20
BOX :w 4 ROUND
```

You can also compute expressions dynamically:

```logo
MAKE "title" "Release Notes"
BOX :title CENTER ROUND
```

---

### 2. Loops (`REPEAT`, `WHILE`, `:#`, `:repcount`, `FOREACH`, `ISEQ`)

LOGO code runs inside an interactive editor, so loops are intentionally bounded. Each loop invocation can execute at most 10,000 iterations. When a loop exceeds that limit, execution stops and the editor reports:

```text
[LOGO loop iteration limit exceeded: WHILE (10000 iterations)]
```

This applies to `REPEAT`, `FOR`, `DOTIMES`, `WHILE`, `UNTIL`, `DO.WHILE`, and `DO.UNTIL`. The limit is a safety guard for editor macros; write long-running transformations as explicit batches instead of relying on open-ended loops.

#### `REPEAT`

Repeats a block $n$ times. `REPEAT` automatically provides built-in loop counter variables `:#` and `:repcount` (1-indexed):

```logo
REPEAT 5 [ TYPE :# TYPE ". Item" MOVE DOWN MOVE HOME ]
```

```text
1. Item
2. Item
3. Item
4. Item
5. Item
```

#### `WHILE`

Runs a block while a condition remains true. Prefer the bracketed condition form:

```logo
MAKE "i 0
WHILE [ :i < 5 ] [
  TYPE :i
  MAKE "i :i + 1
]
```

For compatibility, `WHILE :i < 5 [ ... ]` is also accepted.

#### `FOREACH` and `ISEQ` (`RANGE`)

`ISEQ 1 5` (or `RANGE 1 5`) generates a sequence list `[1 2 3 4 5]`. Use `FOREACH` to iterate over lists with `?` as the current item:

```logo
FOREACH (ISEQ 1 5) [ TYPE ? TYPE " " ]
```

```text
1 2 3 4 5 
```

---

### 3. Conditionals (`IF` and `IFELSE`)

Branch based on conditions:

```logo
IF :count > 5 [ SHOW "Large batch" ]
```

```logo
IFELSE MODIFIED? [ SHOW "Unsaved changes!" ] [ SHOW "Buffer clean" ]
```

---

### 4. Custom Procedures (`TO ... END`)

Define reusable macro procedures for frequent layout operations:

```logo
TO TITLE :text
  BOX :text CENTER ROUND
END

TITLE "Architecture Overview"
```

Once defined, procedures live for the duration of the editor session.

---

### 5. Pen Mode & Turtle Graphics (`PD`, `PU`, `FD`, `BK`, `RT`, `LT`)

Use Pen Down (`PD`) mode to turn cursor movement into line drawing. Moving the turtle draws lines and automatically fuses corners:

```logo
PD REPEAT 4 [ FD 5 RT 90 ] PU
```

```text
┌────┐
│    │
│    │
│    │
└────┘
```

The turtle canvas has a minimum row and column of `1` in LOGO commands
(`0` internally). Moving up or left past that minimum boundary stops at the
edge. A move that starts at the top edge and heads up, or starts at the left
edge and heads left, draws nothing; a move that starts inside the canvas draws
up to the edge and then stops. Moving down or right can extend the buffer.

> For a complete guide on using `PD` and `PU` for ASCII flowcharts, see [logo_pen_mode.md](logo_pen_mode.md).

---

# 📖 PART 3: Complete Command Reference & Dictionary

### Comments

Use `;` for LOGO comments. A semicolon outside quoted text ignores the rest of the line:

```logo
; setup
MAKE "n" 3
REPEAT :n [ TYPE # ] ; prints 123
TYPE ";"
TYPE "hello;world"
```

`#` is not a comment marker in LOGO. It remains available as the `REPEAT` counter and as ordinary text.

---

### 1. Text Insertion, Deletion & Line Formatting

| Command | Aliases | Syntax | Description | Example |
| :--- | :--- | :--- | :--- | :--- |
| `TYPE` | `PRINT`, `INSERT` | `TYPE "text"` or `INSERT "text"` | Inserts string or calculated expression at cursor | `INSERT "Hello World"` |
| `APPEND` | - | `APPEND "text"` | Moves to current line end, then inserts text | `APPEND "."` |
| `PREPEND` | - | `PREPEND "text"` | Moves to current line start, then inserts text | `PREPEND "# "` |
| `SHOW` | `MSG`, `MESSAGE` | `SHOW expr` | Displays status bar message | `SHOW "Saved successfully"` |
| `READWORD` | `RW`, `READLINE`, `READ` | `READWORD [prompt]` | Reads a line of text input from user or stdin | `MAKE "name READWORD "Enter name: "` |
| `READCHAR` | `RC`, `READKEY`, `RK` | `READCHAR [prompt]` | Reads a single keypress from user or stdin | `IF READCHAR "Confirm (y/n)? " = "y" [ DELETE ]` |
| `DATE` | - | `DATE [format]` | Evaluates/inserts current date (e.g. `YYYY/MM/DD` or `yyyy-MM-dd`) | `DATE`, `MAKE "d" DATE "YYYY/MM/DD"` |
| `TIME` | - | `TIME [format]` | Evaluates/inserts current time (default: `HH:mm:ss`) | `TIME`, `TIME "HH:mm"` |
| `NEWLINE` | `NL`, `ENTER` | `NEWLINE [n]` | Inserts $n$ newlines at current cursor | `NL`, `NEWLINE (1 + 1)` |
| `LINE` | `HR` | `LINE [len] [style]` | Draws a horizontal line with smart junction fusion (`single`, `double`, `ascii`). Without length, auto-connects to next border or stops before text. | `LINE`, `LINE (40 * 2) "double"` |
| `VLINE` | `VR`, `VHR` | `VLINE [height] [style]` | Draws a vertical line with smart junction fusion (`single`, `double`, `ascii`). Without height, auto-connects to next border or stops before text. | `VLINE`, `VLINE (2 + 3) "double"` |
| `DEL` | `DELETE` | `DEL [n]` | Deletes $n$ characters forward | `DEL (2 + 3)` |
| `BS` | `BACKSPACE` | `BS [n]` | Deletes $n$ characters backward | `BS 3` |
| `DELETELINE` | `DELLINE`, `KILLLINE`, `DL` | `DELETELINE [n]` | Deletes $n$ current lines | `DELETELINE`, `DL (1 + 2)` |
| `CHANGE` | - | `CHANGE old new` | Replaces text in current line, or selected lines when a selection is active | `CHANGE "foo" "bar"` |
| `JOIN` | - | `JOIN [separator]` | Joins the next line into the current line | `JOIN " "` |
| `SPLITLINE` | - | `SPLITLINE` | Splits the current line at the cursor | `SPLITLINE` |
| `INDENT` | - | `INDENT [n]` | Indents current line or selected lines by n tab units | `INDENT`, `INDENT 2` |
| `OUTDENT` | - | `OUTDENT [n]` | Outdents current line or selected lines by n tab units | `OUTDENT` |
| `JUSTIFY` | - | `JUSTIFY` | Reflows and justifies current paragraph | `JUSTIFY` |

---

### 2. Cursor Navigation, Selection & Canvas Positioning

| Command | Aliases | Syntax | Description | Example |
| :--- | :--- | :--- | :--- | :--- |
| `MOVE` | - | `MOVE UP / DOWN / LEFT / RIGHT / HOME / END` | Moves cursor in 2D text canvas | `MOVE DOWN`, `MOVE END` |
| `TOP` | - | `TOP` | Moves cursor to the start of the file | `TOP` |
| `BOTTOM` | - | `BOTTOM` | Moves cursor to the end of the file | `BOTTOM` |
| `LINESTART` | - | `LINESTART` | Moves cursor to current line start | `LINESTART` |
| `LINEEND` | - | `LINEEND` | Moves cursor to current line end | `LINEEND` |
| `GOTO` | - | `GOTO row [column]` | Jumps directly to 1-indexed line and optional column | `GOTO 10`, `GOTO (40 + 2) 5` |
| `GOTOLINE` | `SETROW` | `GOTOLINE row` | Moves cursor to 1-indexed row number | `GOTOLINE (:row + 1)` |
| `GOTOCOL` | `SETCOL` | `GOTOCOL col` | Moves cursor to 1-indexed column number | `GOTOCOL (4 * 2)` |

In LOGO Text Mode, `GOTO` clamps the row to the existing buffer but allows the
column to point past the current line end. Drawing and layout commands then
fill the intervening space as needed. In Canvas Mode, `GOTO` auto-extends empty
rows within the canvas safety limits: up to `10,000` auto-created rows and
`10,000` virtual columns.

Numeric value arguments in editor and drawing commands may be integer
expressions, such as `GOTO (:row + 1) 1`, `BOX (:w + 2) 4`, or
`LINE (10 * 2) DOUBLE`. Name arguments, option tokens, and block arguments keep
their own syntax and are not treated as general expressions.

| `BOX` | - | `BOX "text" [align] [style]` | Inserts a box around text and pushes trailing text right (`left`, `center`, `right`) | `BOX "Hello World" "center"` |
| `BOX` | - | `BOX width height [style]` | Inserts an empty box frame; dimensions clamp to width `3...200` and height `2...100` | `BOX (10 * 2) 5 "round"` |
| `BOX` | - | `BOX` | In Canvas Mode with a block mark, frames the marked block; otherwise inserts the default empty frame | `BOX` |
| `BOX` | - | `BOX SELECTION [style]` | Encloses active text selection region in box frame | `BOX SELECTION "double"` |
| `DRAWBOX` | - | `DRAWBOX "text" [align] [style]` | Draws an overlay box around text | `DRAWBOX "Hello World" "center"` |
| `DRAWBOX` | - | `DRAWBOX width height [style]` | Draws an empty overlay box frame; dimensions clamp like `BOX` | `DRAWBOX 20 (2 + 3) "round"` |
| `DRAWBOX` | - | `DRAWBOX` | In Canvas Mode with a block mark, overlays a frame on the marked block; otherwise draws the default overlay frame | `DRAWBOX` |
| `LINE` | `HR` | `LINE [length] [style] [arrow]` | Draws a horizontal line; explicit lengths clamp to `1...200` | `LINE ARROW`, `LINE (10 * 2) ASCII BOTHARROW` |
| `VLINE` | `VR`, `VHR` | `VLINE [height] [style] [arrow]` | Draws a vertical line; explicit heights clamp to `1...100` | `VLINE ARROW`, `VLINE (2 + 3) BOTHARROW` |
| `MARK` | - | `MARK` | Toggles the rectangular canvas block mark in canvas mode | `MARK` |
| `CUT` | - | `CUT` | Cuts selected text or current line to clipboard | `CUT` |
| `PASTE` | `UNCUT` | `PASTE` | Pastes clipboard text at current cursor | `PASTE` |
| `FIND` | `SEARCH` | `FIND "query"` | Case-insensitive forward text search | `FIND "func"` |

---

### 3. Classical Turtle Graphics & ASCII Diagram Pen Mode

> For a complete guide on using `PD` and `PU` for ASCII flowcharts and multi-box diagrams, see [logo_pen_mode.md](logo_pen_mode.md).

| Command | Aliases | Syntax | Description | Example |
| :--- | :--- | :--- | :--- | :--- |
| `PD` | `PENDOWN` | `PD` | Pen Down: activates ASCII line & junction drawing mode during cursor movement | `PD` |
| `PU` | `PENUP` | `PU` | Pen Up (Default): deactivates drawing mode to move cursor without altering text | `PU` |
| `FD` | `FORWARD` | `FD [expr]` | Move turtle/pen forward by an integer expression in current heading; stops at top/left minimum boundaries | `FD 5`, `FD (10 - :#)` |
| `BK` | `BACK`, `BACKWARD` | `BK [expr]` | Move turtle/pen backward by an integer expression in opposite heading; stops at top/left minimum boundaries | `BK 3` |
| `RT` | `RIGHT` | `RT` | Turn turtle right 90° | `RT` |
| `LT` | `LEFT` | `LT` | Turn turtle left 90° | `LT` |
| `SETHEADING` | `SETH` | `SETHEADING direction` | Set turtle heading by direction (`UP`, `RIGHT`, `DOWN`, `LEFT`; quoted forms also work) | `SETH RIGHT`, `SETH "DOWN` |
| `HEADING` | - | `HEADING` | Evaluates/returns current turtle heading (0, 90, 180, 270) | `SHOW HEADING`, `TYPE HEADING` |

---

### 4. Data Structures: Lists, Arrays, Words & Sorting

LOGO values are intentionally small and visible. The common types are words, numbers, lists, and arrays.

#### Words / Strings

A quoted word starts with `"`. It is the most common way to pass text to commands:

```logo
TYPE "hello
SHOW "Saved
MAKE "name" "se
TYPE :name
```

Use `WORD` to combine words:

```logo
MAKE "prefix" "# "
MAKE "title" "TODO
TYPE WORD :prefix :title
```

#### Numbers

Numbers can be used directly in movement, drawing, loops, and expressions:

```logo
MAKE "width" 30
BOX :width 4 ROUND
GOTO 2 2
TYPE PRODUCT 6 7
```

In infix-style expressions, variables use the `:name` form:

```logo
MAKE "i" 3
IF :i > 2 [ SHOW "large ]
```

#### Lists

Lists use square brackets. They are convenient for repeated commands and data transformations:

```logo
MAKE "items" ["alpha "beta "gamma]
FOREACH :items [ TYPE ? NL ]
MAKE "long" FILTER [COUNT ? > 4] :items
```

#### Arrays

Arrays are mutable indexed storage. Indexes are 1-based:

```logo
MAKE "cells" ARRAY 3
SETITEM 1 :cells "name
SETITEM 2 :cells "status
SETITEM 3 :cells "owner
TYPE ITEM 2 :cells
```

#### Differences Between Lists and Arrays

| Property | List (`[...]`) | Array (`{...}`) |
| :--- | :--- | :--- |
| **Syntax** | Enclosed in square brackets `[1 2 3]` | Enclosed in curly braces `{1 2 3}` |
| **Mutability** | Immutable structural sharing (modifications like `FPUT`/`LPUT` return new lists) | Mutable in-place (updated using `SETITEM`) |
| **Access Time** | $O(N)$ sequential traversal | $O(1)$ constant random access |
| **Sizing** | Dynamic length | Fixed size allocated with `ARRAY` or `MDARRAY` |
| **Dimensions** | Nested lists `[[1 2] [3 4]]` | Multi-dimensional arrays allocated with `MDARRAY` |

| Command | Aliases | Syntax | Description | Example |
| :--- | :--- | :--- | :--- | :--- |
| `SORT` | - | `SORT [ASC\|DESC] data [template]` | Sorts list, array, or word (smart numeric/text detection, or custom predicate) | `SORT [3 12 2]`, `SORT "DESC "cba`, `SORT :list [?1 > ?2]` |
| `WORD` | - | `WORD w1 w2 ...` | Concatenates inputs into a single word string | `WORD "hello" "world"` |
| `LIST` | - | `LIST item1 item2 ...` | Constructs a list from arguments | `LIST 1 2 3` |
| `SENTENCE` | `SE` | `SENTENCE a b` | Combines elements or lists into a flat sentence list | `SE [1 2] [3 4]` |
| `FPUT` | - | `FPUT item list` | Prepends item to front of list | `FPUT 0 [1 2]` |
| `LPUT` | `QUEUE` | `LPUT item list` | Appends item to end of list | `LPUT 3 [1 2]` |
| `ARRAY` | - | `ARRAY size` | Allocates array of specified size | `MAKE "a" ARRAY 5` |
| `MDARRAY` | - | `MDARRAY dimsList` | Allocates multi-dimensional array with specified dimension bounds | `MAKE "m MDARRAY [3 3]` |
| `MDITEM` | - | `MDITEM idxList mdarray` | Retrieves 1-indexed element from multi-dimensional array | `MDITEM [2 1] :m` |
| `MDSETITEM` | - | `MDSETITEM idxList mdarray val` | Sets 1-indexed element in multi-dimensional array in-place | `MDSETITEM [2 1] "m "Z` |
| `LISTTOARRAY` | - | `LISTTOARRAY list` | Converts list to array | `LISTTOARRAY [1 2 3]` |
| `ARRAYTOLIST` | - | `ARRAYTOLIST array` | Converts array to list | `ARRAYTOLIST :arr` |
| `COMBINE` | - | `COMBINE a b` | Combines two lists or words | `COMBINE "a" "b"` |
| `GENSYM` | - | `GENSYM` | Generates a unique, non-clashing symbol name | `GENSYM` $\rightarrow$ `"G1"` |
| `REVERSE` | - | `REVERSE list\|word` | Reverses order of list or word | `REVERSE [1 2 3]` |
| `FIRST` | - | `FIRST list\|word` | Returns first element or character | `FIRST [10 20 30]` |
| `LAST` | - | `LAST list\|word` | Returns last element or character | `LAST "hello"` |
| `FIRSTS` | - | `FIRSTS list_of_lists` | Returns list of first elements | `FIRSTS [[1 2] [3 4]]` |
| `BUTFIRST` | `BF` | `BUTFIRST list\|word` | Returns list or word without first element | `BF [1 2 3]` |
| `BUTLAST` | `BL` | `BUTLAST list\|word` | Returns list or word without last element | `BL "hello"` |
| `BUTFIRSTS` | `BFS` | `BUTFIRSTS list_of_lists` | Returns list of lists without first elements | `BFS [[1 2] [3 4]]` |
| `ITEM` | - | `ITEM index data` | Returns 1-indexed item from list, array, or word | `ITEM 2 [10 20 30]` |
| `PICK` | - | `PICK list\|array` | Randomly picks an element from list or array | `PICK ["a" "b" "c"]` |
| `REMOVE` | - | `REMOVE item list` | Removes all occurrences of item from list | `REMOVE 2 [1 2 2 3]` |
| `REMDUP` | - | `REMDUP list` | Removes duplicate elements from list | `REMDUP [1 2 2 3 1]` |
| `SPLIT` | - | `SPLIT str delimiter` | Splits string into list by delimiter | `SPLIT "a,b,c" ","` |
| `SETITEM` | - | `SETITEM idx array val` | Sets 1-indexed element in array | `SETITEM 1 :arr "val"` |
| `PUSH` | - | `PUSH val list` | Pushes element to list variable | `PUSH 1 "myList"` |
| `POP` | - | `POP list` | Pops element from list variable | `POP "myList"` |
| `DEQUEUE` | - | `DEQUEUE list` | Removes and returns first element from list variable | `DEQUEUE "myQueue"` |
| `PPROP` | `PUTPROP` | `PPROP name prop val` | Associates property key-value with object symbol | `PPROP "car "color "red` |
| `GPROP` | `GETPROP` | `GPROP name prop` | Retrieves property value associated with object symbol | `GPROP "car "color` $\rightarrow$ `"red"` |
| `REMPROP` | `ERASEPROP` | `REMPROP name prop` | Removes property key-value from object symbol | `REMPROP "car "color` |
| `PLIST` | `PROPLIST` | `PLIST name` | Returns flat list of key-value pairs for object symbol | `PLIST "car` $\rightarrow$ `[color red year 2026]` |
| `PLISTS` | `PROPLISTS` | `PLISTS` | Returns list of all object symbol names having property lists | `PLISTS` $\rightarrow$ `[car]` |
| `NAMES` | - | `NAMES` | Returns list of all defined variable names | `NAMES` $\rightarrow$ `[x y]` |
| `PROCEDURES` | `PROCS` | `PROCEDURES` | Returns list of all user-defined procedure names | `PROCEDURES` $\rightarrow$ `[ADD MULTIPLY]` |
| `PRIMITIVES` | `PRIMS` | `PRIMITIVES` | Returns list of all built-in primitive keyword aliases | `PRIMITIVES` |
| `CONTENTS` | - | `CONTENTS` | Returns workspace contents list `[[procedures] [names] [plists]]` | `CONTENTS` |
| `TEXT` | `FULLTEXT` | `TEXT name` | Returns AST representation list of specified procedure | `TEXT "add` $\rightarrow$ `[[:a :b] [OUTPUT :a + :b]]` |
| `DEFINE` | - | `DEFINE name specList` | Dynamically defines procedure from AST list structure | `DEFINE "add [[:a :b] [OUTPUT :a + :b]]` |
| `ARITY` | - | `ARITY name` | Returns required parameter count of procedure | `ARITY "add` $\rightarrow$ `2` |
| `ERASE` | `ER` | `ERASE name` | Erases specified variable, procedure, or property list | `ERASE "x` |
| `ERALL` | - | `ERALL` | Erases all variables, user procedures, and property lists | `ERALL` |
| `COUNT` | - | `COUNT list\|array\|word` | Returns length count of items or characters | `COUNT [1 2 3]` |
| `CHARCOUNT` | - | `CHARCOUNT text` | Counts Unicode grapheme characters in text | `CHARCOUNT "a👍中` |
| `CHARCOUNT.CJK` | - | `CHARCOUNT.CJK text` | Counts CJK scripts and CJK/fullwidth punctuation, excluding ASCII words and spaces | `CHARCOUNT.CJK "中文，API。` |
| `CHARCOUNT.WORDS` | - | `CHARCOUNT.WORDS text` | Counts alphanumeric word runs | `CHARCOUNT.WORDS "Hello, world!` |
| `CHARCOUNT.EMOJI` | - | `CHARCOUNT.EMOJI text` | Counts emoji grapheme clusters | `CHARCOUNT.EMOJI "A👍🏽🇹🇼` |
| `CHARCOUNT.LINES` | - | `CHARCOUNT.LINES text` | Counts logical newline-separated text lines | `CHARCOUNT.LINES :text` |
| `ASCII` / `ORD` | `ORD` | `ASCII char` \| `ORD char` | Returns Unicode/ASCII scalar code integer of character | `ASCII "A"`, `ORD "字"` |
| `CHAR` / `CHR` | `CHR` | `CHAR code` \| `CHR code` | Returns character string for Unicode/ASCII code integer | `CHAR 65`, `CHR 23383` |
| `UPPERCASE` | - | `UPPERCASE str` | Converts string to uppercase | `UPPERCASE "hello"` |
| `LOWERCASE` | - | `LOWERCASE str` | Converts string to lowercase | `LOWERCASE "HELLO"` |
| `BIT.AND` | - | `BIT.AND a b` | Bitwise AND operator | `BIT.AND 6 3` |
| `BIT.OR` | - | `BIT.OR a b` | Bitwise OR operator | `BIT.OR 6 3` |
| `BIT.XOR` | - | `BIT.XOR a b` | Bitwise XOR operator | `BIT.XOR 6 3` |
| `BIT.NOT` | - | `BIT.NOT a` | Bitwise NOT (bitwise complement) operator | `BIT.NOT 0` |
| `BIT.SHL` | - | `BIT.SHL a shift` | Bitwise Shift Left operator | `BIT.SHL 1 4` |
| `BIT.SHR` | - | `BIT.SHR a shift` | Bitwise Shift Right operator | `BIT.SHR 16 2` |
| `INDEXOF` | `INDEX_OF` | `INDEXOF needle haystack [startFrom]` | Returns 1-based index of first occurrence of `needle` in `haystack` (0 if not found) | `INDEXOF "a "banana` |
| `LASTINDEXOF` | `LAST_INDEX_OF` | `LASTINDEXOF needle haystack` | Returns 1-based index of last occurrence of `needle` in `haystack` (0 if not found) | `LASTINDEXOF "a "banana` |
| `INDEXESOF` | `INDICESOF`, `ALL_INDEXES` | `INDEXESOF needle haystack` | Returns a list of all 1-based match indices of `needle` in `haystack` | `INDEXESOF "a "banana` |
| `CONTAINS?` | `CONTAINSP`, `INCLUDES?` | `CONTAINS? needle haystack` | Returns true if `haystack` contains `needle` | `CONTAINS? "world "hello_world` |
| `STARTSWITH?` | `STARTSP`, `HAS_PREFIX?` | `STARTSWITH? prefix string` | Returns true if `string` starts with `prefix` | `STARTSWITH? "# "#_Title` |
| `ENDSWITH?` | `ENDSP`, `HAS_SUFFIX?` | `ENDSWITH? suffix string` | Returns true if `string` ends with `suffix` | `ENDSWITH? ".md "file.md` |
| `SUBSTRING` | `SUBSTR`, `SLICE` | `SUBSTRING string start [length]` | Extracts substring starting at 1-based `start` position | `SUBSTRING "Hello_World 1 5` |
| `SEARCH` | - | `SEARCH haystack needle` | Searches string or list for occurrence of needle | `SEARCH "banana "an` |
| `REPLACE` | `SUBSTITUTE` | `REPLACE old new string` | Replaces all occurrences of `old` with `new` in `string` | `REPLACE "foo "bar "foo_text` |
| `TRIM` | `STRIP` | `TRIM string` | Removes leading and trailing whitespace from string | `TRIM "  hello  ` |
| `REPEATSTR` | `STR_REPEAT` | `REPEATSTR count string` | Repeats string for `count` times | `REPEATSTR 5 "=` |
| `IMPLODE` | `JOINSTR`, `JOIN_LIST` | `IMPLODE delimiter list` | Joins a list of values into a single string separated by `delimiter` | `IMPLODE ", " [apple banana]` |
| `LINES` | `TO_LINES` | `LINES string` | Splits multiline string into a list of individual lines | `LINES :multilineText` |
| `UNLINES` | `FROM_LINES` | `UNLINES list` | Joins a list of lines into a multiline string with newlines | `UNLINES :lineList` |
| `FORMAT` | `SPRINTF` | `FORMAT pattern argList` | Formats string pattern with placeholders (`%s`, `%d`, `%f`, `%x`, `%0Nd`, `%-Ns`, `%1`) | `FORMAT "Line_%d:_%s [42 "Text]` |
| `PADLEFT` | `RJUST` | `PADLEFT width [padChar] string` | Left-pads string to specified display width | `PADLEFT 5 "0 "42` |
| `PADRIGHT` | `LJUST` | `PADRIGHT width [padChar] string` | Right-pads string to specified display width | `PADRIGHT 10 ". "item` |
| `REGEX_MATCH?` | `REGEX_MATCH`, `REMATCH?` | `REGEX_MATCH? pattern string` | Returns true if `string` matches regex `pattern` | `REGEX_MATCH? "^#+ "#_Title` |
| `REGEX_REPLACE` | `RREPLACE`, `RSUBSTITUTE` | `REGEX_REPLACE pattern replacement string` | Replaces all regex matches in `string` with `replacement` | `REGEX_REPLACE "\s+ "_ "a   b` |
| `REGEX_FIND` | `RFIND`, `RFINDALL` | `REGEX_FIND pattern string` | Returns a list of all substrings matching regex `pattern` | `REGEX_FIND "\d+ "Item_42_and_100` |
| `TRANSLIT` | `TRANSFORM` | `TRANSLIT transform-id text` | Applies an ICU String Transform or zago `Zago-*` writing transform | `TRANSLIT "Any-Hiragana "Sakura`, `TRANSLIT "Zago-CJK-Punctuation "Hello,` |
| `SPACING.CJK` | - | `SPACING.CJK text` | Normalizes spacing between CJK script characters and ASCII words/numbers without changing punctuation | `SPACING.CJK "中文API測試` |
| `TOHANS` | `TRANSFORM.TOHANS` | `TOHANS text` | Converts Traditional Chinese text to Simplified Chinese via `Hant-Hans` | `TOHANS "繁體中文` |
| `TOHANT` | `TRANSFORM.TOHANT` | `TOHANT text` | Converts Simplified Chinese text to Traditional Chinese via `Hans-Hant` | `TOHANT "简体中文` |
| `TOLATIN` | `TRANSFORM.TOLATIN` | `TOLATIN text` | Romanizes text via `Any-Latin` | `TOLATIN "你好嗎？` |
| `TOHIRAGANA` | `TRANSFORM.TOHIRAGANA` | `TOHIRAGANA text` | Converts text to Hiragana via `Any-Hiragana` | `TOHIRAGANA "Sakura` |
| `TOKATAKANA` | `TRANSFORM.TOKATAKANA` | `TOKATAKANA text` | Converts text to Katakana via `Any-Katakana` | `TOKATAKANA "Sakura` |
| `TOROMAJI` | `TRANSFORM.TOROMAJI` | `TOROMAJI text` | Romanizes Japanese text via `Any-Latin` | `TOROMAJI "さくら` |

---

### 5. Predicates & Type Checking

| Command | Aliases | Syntax | Description | Example |
| :--- | :--- | :--- | :--- | :--- |
| `WORD?` | `WORDP` | `WORD? val` | Returns `true` if input is a word/string, `false` otherwise | `WORD? "hello"` |
| `LIST?` | `LISTP` | `LIST? val` | Returns `true` if input is a list, `false` otherwise | `LIST? [1 2]` |
| `ARRAY?` | `ARRAYP` | `ARRAY? val` | Returns `true` if input is an array, `false` otherwise | `ARRAY? :a` |
| `NUMBER?` | `NUMBERP` | `NUMBER? val` | Returns `true` if input is numeric, `false` otherwise | `NUMBER? 42` |
| `EMPTY?` | `EMPTYP` | `EMPTY? val` | Returns `true` if input is empty list or string, `false` otherwise | `EMPTY? []` |
| `EQUAL?` | `EQUALP`, `.EQ` | `EQUAL? a b` | Returns `true` if $a == b$, `false` otherwise | `EQUAL? :i 5` |
| `NOTEQUAL?` | `NOTEQUALP` | `NOTEQUAL? a b` | Returns `true` if $a \neq b$, `false` otherwise | `NOTEQUAL? :i 0` |
| `BEFORE?` | `BEFOREP` | `BEFORE? str1 str2` | Returns `true` if `str1` precedes `str2` alphabetically | `BEFORE? "apple" "banana"` |
| `MEMBER?` | `MEMBERP` | `MEMBER? item list` | Returns `true` if item exists in list | `MEMBER? 2 [1 2 3]` |
| `SUBSTRING?` | `SUBSTRINGP` | `SUBSTRING? sub str` | Returns `true` if substring is contained in string | `SUBSTRING? "cat" "caterpillar"` |
| `PROCEDURE?` | `PROCEDUREP` | `PROCEDURE? name` | Returns `true` if name is a built-in or user-defined procedure | `PROCEDURE? "SUM` |
| `PRIMITIVE?` | `PRIMITIVEP` | `PRIMITIVE? name` | Returns `true` if name is a built-in primitive | `PRIMITIVE? "SUM` |
| `DEFINED?` | `DEFINEDP` | `DEFINED? name` | Returns `true` if name is a user-defined procedure | `DEFINED? "FOO` |
| `NAME?` | `NAMEP` | `NAME? name` | Returns `true` if a variable with that name exists | `NAME? "x` |
| `LESS?` | `LESSP` | `LESS? a b` | Returns `1` if $a < b$ | `LESS? 3 5` |
| `GREATER?` | `GREATERP` | `GREATER? a b` | Returns `1` if $a > b$ | `GREATER? 10 2` |
| `LESSEQUAL?` | `LESSEQUALP` | `LESSEQUAL? a b` | Returns `1` if $a \le b$ | `LESSEQUAL? 5 5` |
| `GREATEREQUAL?` | `GREATEREQUALP` | `GREATEREQUAL? a b` | Returns `1` if $a \ge b$ | `GREATEREQUAL? 5 3` |

---

### 6. Logical, Math & Bitwise Operations

| Command | Aliases | Syntax | Description | Example |
| :--- | :--- | :--- | :--- | :--- |
| `TRUE`, `FALSE` | - | `TRUE`, `FALSE` | Constant values `1` and `0` | `TRUE` |
| `AND`, `OR`, `XOR`, `NOT` | - | `AND a b`, `NOT a` | Boolean logical operations | `AND (LESS? 1 2) (GREATER? 5 3)` |
| `SUM` | - | `SUM expr expr`, `(SUM expr ...)`, or `SUM list` | Addition; parenthesized form accepts multiple values | `SUM 10 20`, `(SUM 1 2 3)`, `SUM [1 2 3]` |
| `MIN` | - | `MIN expr expr`, `(MIN expr ...)`, or `MIN list` | Minimum numeric value | `MIN 10 20`, `(MIN 3 1 4)`, `MIN [3 1 4]` |
| `MAX` | - | `MAX expr expr`, `(MAX expr ...)`, or `MAX list` | Maximum numeric value | `MAX 10 20`, `(MAX 3 1 4)`, `MAX [3 1 4]` |
| `DIFFERENCE` | - | `DIFFERENCE a b` | Subtraction ($a - b$) | `DIFFERENCE 50 20` |
| `PRODUCT` | - | `PRODUCT a b` | Multiplication ($a \times b$) | `PRODUCT 4 5` |
| `QUOTIENT` | `QUOTED` | `QUOTIENT a b` | Division ($a / b$) | `QUOTIENT 20 4` |
| `POWER` | - | `POWER base exp` | Exponentiation ($a^b$) | `POWER 2 3` |
| `REMAINDER` | - | `REMAINDER a b` | Integer remainder ($a \bmod b$) | `REMAINDER 10 3` |
| `MODULO` | - | `MODULO a b` | Mathematical modulo | `MODULO -1 5` |
| `MINUS`, `ABS` | - | `MINUS a [b]`, `ABS a` | Negation, or subtraction when `b` is present | `MINUS 9 5`, `ABS -15` |
| `INT`, `ROUND` | - | `INT a`, `ROUND a` | Truncate integer and round | `ROUND 3.7` |
| `SQRT`, `EXP` | - | `SQRT a`, `EXP a` | Square root and exponential $e^a$ | `SQRT 16` |
| `LOG10`, `LN` | - | `LOG10 a`, `LN a` | Logarithm base 10 and natural log | `LOG10 100` |
| `SIN`, `COS`, `TAN` | - | `SIN deg`, `COS deg` | Trigonometric functions (degrees) | `SIN 90` |
| `RADSIN`, `RADCOS`, `RADTAN` | - | `RADSIN rad`, `RADCOS rad`, `RADTAN rad` | Trigonometric functions (radians) | `RADSIN 1.570796` |
| `ARCTAN`, `RADARCTAN` | - | `ARCTAN num`, `(ARCTAN x y)` | Arctangent in degrees or radians; two-input form uses `atan2(y, x)` | `(ARCTAN 0 1)` |
| `FORM` | - | `FORM val width precision` | Formats number into string with width and decimal precision | `FORM 3.14159 8 4` |
| `RANGE` | `ISEQ` | `RANGE start end [step]` | Generates inclusive integer sequence list | `RANGE 1 5` $\rightarrow$ `[1 2 3 4 5]`, `RANGE 1 10 2` |
| `RSEQ` | - | `RSEQ start end count` | Generates real number sequence list | `RSEQ 0 1 5` |
| `RANDOM` | - | `RANDOM max [min]` | Generates random integer in range | `RANDOM 100`, `RANDOM 10 20` |
| `RERANDOM` | - | `RERANDOM seed` | Resets pseudo-random number generator seed for reproducibility | `RERANDOM 42` |
| `BITAND`, `BITOR`, `BITXOR`, `BITNOT` | - | `BITAND a b` | Bitwise logic operations | `BITAND 5 3` |
| `ASHIFT`, `LSHIFT` | - | `ASHIFT val shift` | Arithmetic and logical bit shifts | `LSHIFT 1 4` |

---

### 7. Conditionals, Loops & Higher-Order Functions

| Command | Aliases | Syntax | Description | Example |
| :--- | :--- | :--- | :--- | :--- |
| `MAKE` | `VAR` | `MAKE "var" expr` | Assigns value to variable | `MAKE "i" 1` |
| `:var` | - | `:var_name` | Dereferences variable value | `TYPE :i` |
| `NAME` | - | `NAME value name` | LOGO-compatible variable assignment, with value first | `NAME 30 "width` |
| `THING` | - | `THING name` | LOGO-compatible variable lookup; useful for dynamic names | `THING "width`, `THING :varname` |
| `IF` | - | `IF cond [ block ]` | Executes block if condition is true | `IF :i > 5 [ TYPE "OK" ]` |
| `IFELSE` | - | `IFELSE cond [ t_block ] [ f_block ]` | Branching if-else execution | `IFELSE :i == 2 [ TYPE "TWO" ] [ TYPE :i ]` |
| `TEST` | - | `TEST cond` | Sets internal test flag for `IFTRUE`/`IFFALSE` | `TEST :i == 1` |
| `IFTRUE` | `IFT` | `IFTRUE [ block ]` | Executes if preceding `TEST` was true | `IFT [ TYPE "Yes" ]` |
| `IFFALSE` | `IFF` | `IFFALSE [ block ]` | Executes if preceding `TEST` was false | `IFF [ TYPE "No" ]` |
| `REPEAT` | - | `REPEAT count [ block ]` | Loops enclosed code block $n$ times (built-in `:#` / `:repcount`) | `REPEAT 3 [ TYPE "! " ]` |
| `FOR` | - | `FOR [var start end step] [ block ]` | For loop over range | `FOR [i 1 5 1] [ TYPE :i ]` |
| `DOTIMES` | - | `DOTIMES [var count] [ block ]` | Loops counter from 0 to count-1 | `DOTIMES [i 5] [ TYPE :i ]` |
| `WHILE` | - | `WHILE [ cond ] [ block ]` | Executes block while condition is true | `WHILE [ :i < 5 ] [ ... ]` |
| `UNTIL` | - | `UNTIL [ cond ] [ block ]` | Executes block until condition becomes true | `UNTIL [ :i >= 5 ] [ ... ]` |
| `TO ... END` | - | `TO name ... END` | Defines custom reusable macro procedure | `TO HDR TYPE "# " END` |
| `EXEC` | - | `EXEC proc_name` or `proc_name` | Executes custom procedure | `EXEC HDR` |
| `FOREACH` | - | `FOREACH list [ template ]` | Iterates over list elements with template (`?`) | `FOREACH [1 2 3] [ TYPE ? ]` |
| `MAP` | - | `MAP template list` | Maps list elements using template (`?` or `?1`) | `MAP [? * 2] [1 2 3]` $\rightarrow$ `[2 4 6]` |
| `FILTER` | - | `FILTER template list` | Filters list elements matching template predicate | `FILTER [? > 2] [1 2 3 4]` $\rightarrow$ `[3 4]` |
| `REDUCE` | - | `REDUCE template list` | Reduces list to single value using template (`?1`, `?2`) | `REDUCE [?1 + ?2] [1 2 3 4]` $\rightarrow$ `10` |
| `CROSSMAP` | - | `CROSSMAP template lists` | Cartesian product map over multiple lists | `CROSSMAP [WORD ?1 ?2] [["a" "b"] ["1" "2"]]` |
| `STOP` | - | `STOP` | Immediately exits active macro procedure or loop | `IF :err [ STOP ]` |
| `WAIT` | - | `WAIT ms` | Pauses macro execution for specified milliseconds | `WAIT 500` |

---

### 8. Multi-Buffer & Buffer Operations

| Command | Aliases | Syntax | Description | Example |
| :--- | :--- | :--- | :--- | :--- |
| `BUFFERS` | `BUFFERLIST` | `BUFFERS` | Returns list of open buffer names | `MAKE "b" BUFFERS` |
| `BUFFER` | - | `BUFFER` | Returns active 1-based buffer index | `SHOW BUFFER` |
| `CLEARBUFFER` | `ERASEBUFFER` | `CLEARBUFFER` | Clears all text in active buffer | `CLEARBUFFER` |
| `GETLINE` | - | `GETLINE [row]` | Returns text content of specified line (or current line) | `MAKE "l" GETLINE (1 + 1)` |
| `SETLINE` | - | `SETLINE [row] "text"` | Replaces text of specified line (or current line) | `SETLINE (1 + 1) "Title"` |
| `ROW` | `LINE.NO` | `ROW` | Returns current 1-indexed row number | `SHOW ROW` |
| `COL` | `COL.NO` | `COL` | Returns current 1-indexed column number | `SHOW COL` |
| `LINECOUNT` | `LINES` | `LINECOUNT` | Returns total line count of active buffer | `SHOW LINECOUNT` |
| `BUFFERTEXT` | - | `BUFFERTEXT` | Returns full string text of active buffer | `MAKE "t" BUFFERTEXT` |
| `SELECTION` | `SELECTEDTEXT` | `SELECTION` | Returns currently selected text string | `MAKE "s" SELECTION` |
| `MODIFIED?` | `CHANGED?` | `MODIFIED?` | Returns `1` if buffer has unsaved changes, `0` otherwise | `IF MODIFIED? [ SHOW "Unsaved" ]` |
| `FILENAME` | `BUFFERNAME` | `FILENAME` | Returns filename of active buffer | `SHOW FILENAME` |

---

### 9. Editor Settings

Editor/session settings are command prompt and configuration directives, not
LOGO primitives. Use command prompt shorthand such as `set wrap 80`,
`set tab 4`, `set canvas-mode on`, `set trim-trailing-whitespace on`,
`set linenumbers off`, `set ruler on`, and `unset wrap`.

---

### 10. Table Mode Safety

When Table Mode is active, LOGO execution is constrained to protect the current table cell structure.

Allowed behavior:

- `TYPE` / `PRINT` may insert text into the active cell.
- Text output is clipped to the editable cell area and will not shift, overwrite, or pass the right border.
- Newlines move within the active cell; output stops when it would leave the cell.
- Non-drawing expressions, variables, procedures, status messages, and data operations remain available.

Disabled while Table Mode is active:

- `BOX`
- `DRAWBOX`
- `LINE` / `HR`
- `VLINE` / `VR` / `VHR`
- `TABLE`
- Turtle drawing commands: `PD`, `PU`, `FD`, `BK`, `RT`, `LT`

---

## ⚙️ `.zagorc` Integration

LOGO commands can be entered from the command prompt, evaluated from the editor, or loaded through `.zagorc` key bindings and startup blocks.

For configuration syntax, named scripts, startup preludes, and command ids, see [Configuration](configuration.md).

---

## 💡 Practical Real-World Macro Examples

### 1. Iterating and Transforming Data (`FOREACH`, `MAP`, `REDUCE`, `SORT`)

`FOREACH` is for actions. It runs a template once for each item:

```logo
FOREACH ["alpha "beta "gamma] [
  TYPE "- "
  TYPE ?
  NL
]
```

*Output:*

```text
- alpha
- beta
- gamma
```

Use `RANGE` / `ISEQ` when you want to iterate over numbers:

```logo
FOREACH RANGE 1 3 [
  TYPE ?
  NL
]
```

*Output:*

```text
1
2
3
```

`MAP` is for transformations. It returns a new list:

```logo
MAKE "nums" [1 2 3 4]
MAKE "squares" MAP [? * ?] :nums
SHOW :squares
```

*Result:*

```text
[1 4 9 16]
```

`REDUCE` combines a list into one value. Use `?1` for the accumulated value and `?2` for the next item:

```logo
MAKE "nums" [1 2 3 4 5]
MAKE "total" REDUCE [?1 + ?2] :nums
SHOW :total
```

*Result:*

```text
15
```

`SORT` orders words, numbers, lists, or arrays. It can also take `ASC` or `DESC`:

```logo
MAKE "nums" [3 1 4 1 5 9 2 6]
MAKE "ordered" SORT "DESC :nums
SHOW :ordered
```

*Result:*

```text
[9 6 5 4 3 2 1 1]
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

### 3. Multi-Column Layout Generator (`VLINE` & `GOTO`)

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

### 4. Classical Turtle Graphics Square Box (`FD`, `RT`, `PD`)

Draws a 5x5 square frame using classic LOGO Turtle Graphics with Pen Down and 90° right turns:

```logo
PD REPEAT 4 [ FD 5 RT 90 ] PU
```

*Output (automatically fused corner junctions):*

```text
┌────┐
│    │
│    │
│    │
└────┘
```

### 5. Loop Drawing: Christmas Tree

Loops are useful for small generated diagrams. This example draws a centered tree with stars and a trunk:

```logo
MAKE "height" 6
FOR [row 1 :height 1] [
  MAKE "spaces" :height - :row
  MAKE "stars" :row * 2 - 1
  REPEAT :spaces [ TYPE " " ]
  REPEAT :stars [ TYPE "*" ]
  NL
]
MAKE "trunkSpaces" :height - 1
REPEAT :trunkSpaces [ TYPE " " ]
TYPE "|"
```

*Output:*

```text
     *
    ***
   *****
  *******
 *********
***********
     |
```

---

## 🧪 Atomic Undo (`^Z`) Guarantee

All operations performed by a single command execution—regardless of how many lines or characters were inserted or modified—are grouped into a **single atomic Undo snapshot**.

---

## 📜 History & Origins of Editor LOGO

**Editor LOGO** in `zago` is a specialized, text-oriented dialect of the LOGO programming language designed specifically for text buffer manipulation and terminal diagramming:

- **UCBLogo Heritage**: Built upon the foundational syntax and functional design of **UCBLogo** (Berkeley LOGO), preserving classic Lisp-like list processing, prefix evaluation, and procedure definitions (`TO ... END`).
- **Safety & Loop Protection**: Removed legacy GUI turtle graphics windows and unconstrained control structures like `FOREVER` that could freeze the editor UI. All loop execution in Editor LOGO is strictly bounded (up to 10,000 iterations).
- **Editor & Diagram Control Primitives**: Introduced native text editor control commands, including direct cursor movement (`MOVE UP|DOWN|LEFT|RIGHT`, `GOTO`), text insertion (`TYPE`, `PRINT`, `SHOW`), framed box layout (`BOX`, `DRAWBOX`), line drawing (`LINE`, `VLINE`), region filling (`FILL`), and structured tables (`TABLE`).
- **Text Transforms & Information Keywords**: Added specialized string manipulation, ICU String Transforms (`TRANSLIT`), CJK writing normalization (`Zago-CJK-Punctuation`), and date/time metadata inspection primitives tailored for prose editing and documentation.
