# `se` Diagramming & Editing Commands: Guide & Reference

`se` provides a simple set of direct editing commands for drawing boxes, connector lines, tables, and laying out structured text directly inside your terminal buffer.

Commands read like natural editing gestures: press `Esc`, type `BOX "Title"`, `LINE ARROW`, or `TABLE`, and shape your plain text instantly without leaving your text editor.

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

# 📚 PART 1: Quick Start & Essential Diagramming Guide

Most of the time in `se`, you only need a handful of essential commands to shape structured text: **`BOX`**, **`DRAWBOX`**, **`LINE`**, **`VLINE`**, **`TABLE`**, **`TYPE`**, and **`SHOW`**.

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

#### `DRAWBOX` (Canvas Overlay Frame)

`DRAWBOX` accepts the same arguments as `BOX`, but draws as a canvas overlay without pushing surrounding text. Use it when composing multi-box diagrams against fixed coordinates:

```logo
DRAWBOX 30 4 ROUND
GOTO 2 2
FILL "hi
```

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

### Step 3: Creating Grid Tables (`TABLE`)

`TABLE` inserts plain-text grid tables at the cursor position.

```logo
TABLE BORDER ROUND
TABLE 2 2
```

```text
╭────────────────┬────────────────╮
│                │                │
├────────────────┼────────────────┤
│                │                │
╰────────────────┴────────────────╯
```

After creating a table, move the cursor inside it and press **`M+T`** to activate cell-by-cell Table Mode.

---

### Step 4: Text Output & Message Display (`TYPE` and `SHOW`)

- **`TYPE "text"`** (or `PRINT`): Inserts text or calculated expressions directly at the cursor.
- **`SHOW "message"`**: Displays a status bar notification message at the bottom of the screen.
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

### 2. Loops (`REPEAT`, `:#`, `:repcount`, `FOREACH`, `ISEQ`)

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
| `DATE` | - | `DATE [format]` | Evaluates/inserts current date (e.g. `YYYY/MM/DD` or `yyyy-MM-dd`) | `DATE`, `MAKE "d" DATE "YYYY/MM/DD"` |
| `TIME` | - | `TIME [format]` | Evaluates/inserts current time (default: `HH:mm:ss`) | `TIME`, `TIME "HH:mm"` |
| `NEWLINE` | `NL`, `ENTER` | `NEWLINE [n]` | Inserts $n$ newlines at current cursor | `NL`, `NEWLINE 2` |
| `LINE` | `HR` | `LINE [len] [style]` | Draws a horizontal line with smart junction fusion (`single`, `double`, `ascii`). Without `len`, auto-connects to next border or stops before text. | `LINE`, `LINE 80 "double"` |
| `VLINE` | `VR`, `VHR` | `VLINE [height] [style]` | Draws a vertical line with smart junction fusion (`single`, `double`, `ascii`). Without `height`, auto-connects to next border or stops before text. | `VLINE`, `VLINE 5 "double"` |
| `DEL` | `DELETE` | `DEL [n]` | Deletes $n$ characters forward | `DEL 5` |
| `BS` | `BACKSPACE` | `BS [n]` | Deletes $n$ characters backward | `BS 3` |
| `DELETELINE` | `DELLINE`, `KILLLINE`, `DL` | `DELETELINE [n]` | Deletes $n$ current lines | `DELETELINE`, `DL 3` |
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
| `GOTO` | - | `GOTO line [column]` | Jumps directly to 1-indexed line and optional column | `GOTO 10`, `GOTO 42 5` |
| `GOTOLINE` | `SETROW` | `GOTOLINE row` | Moves cursor to 1-indexed row number | `GOTOLINE 15` |
| `GOTOCOL` | `SETCOL` | `GOTOCOL col` | Moves cursor to 1-indexed column number | `GOTOCOL 8` |
| `BOX` | - | `BOX "text" [align] [style]` | Inserts a box around text and pushes trailing text right (`left`, `center`, `right`) | `BOX "Hello World" "center"` |
| `BOX` | - | `BOX width height [style]` | Inserts an empty box frame (`single`, `double`, `ascii`, `round`, `double-round`) | `BOX 20 5 "round"` |
| `BOX` | - | `BOX SELECTION [style]` | Encloses active text selection region in box frame | `BOX SELECTION "double"` |
| `DRAWBOX` | - | `DRAWBOX "text" [align] [style]` | Draws an overlay box around text | `DRAWBOX "Hello World" "center"` |
| `DRAWBOX` | - | `DRAWBOX width height [style]` | Draws an empty overlay box frame | `DRAWBOX 20 5 "round"` |
| `LINE` | `HR` | `LINE [length] [style] [arrow]` | Draws a horizontal line, optionally with arrowheads | `LINE ARROW`, `LINE 20 ASCII BOTHARROW` |
| `VLINE` | `VR`, `VHR` | `VLINE [height] [style] [arrow]` | Draws a vertical line, optionally with arrowheads | `VLINE ARROW`, `VLINE 5 BOTHARROW` |
| `MARK` | - | `MARK` | Toggles text selection mark anchor | `MARK` |
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
| `FD` | `FORWARD` | `FD [dist]` | Move turtle/pen forward $n$ steps in current heading | `FD 5`, `FD 10` |
| `BK` | `BACK`, `BACKWARD` | `BK [dist]` | Move turtle/pen backward $n$ steps in opposite heading | `BK 3` |
| `RT` | `RIGHT` | `RT [angle]` | Turn turtle right 90° (or specified angle) | `RT`, `RT 90` |
| `LT` | `LEFT` | `LT [angle]` | Turn turtle left 90° (or specified angle) | `LT`, `LT 90` |

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
| `LISTTOARRAY` | - | `LISTTOARRAY list` | Converts list to array | `LISTTOARRAY [1 2 3]` |
| `ARRAYTOLIST` | - | `ARRAYTOLIST array` | Converts array to list | `ARRAYTOLIST :arr` |
| `COMBINE` | - | `COMBINE a b` | Combines two lists or words | `COMBINE "a" "b"` |
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
| `COUNT` | - | `COUNT list\|array\|word` | Returns length count of items or characters | `COUNT [1 2 3]` |
| `ASCII` | - | `ASCII char` | Returns ASCII code integer of character | `ASCII "A"` |
| `CHAR` | - | `CHAR code` | Returns character string for ASCII code | `CHAR 65` |
| `UPPERCASE` | - | `UPPERCASE str` | Converts string to uppercase | `UPPERCASE "hello"` |
| `LOWERCASE` | - | `LOWERCASE str` | Converts string to lowercase | `LOWERCASE "HELLO"` |

---

### 5. Predicates & Type Checking

| Command | Aliases | Syntax | Description | Example |
| :--- | :--- | :--- | :--- | :--- |
| `WORD?` | `WORDP` | `WORD? val` | Returns `1` if input is a word/string, `0` otherwise | `WORD? "hello"` |
| `LIST?` | `LISTP` | `LIST? val` | Returns `1` if input is a list, `0` otherwise | `LIST? [1 2]` |
| `ARRAY?` | `ARRAYP` | `ARRAY? val` | Returns `1` if input is an array, `0` otherwise | `ARRAY? :a` |
| `NUMBER?` | `NUMBERP` | `NUMBER? val` | Returns `1` if input is numeric, `0` otherwise | `NUMBER? 42` |
| `EMPTY?` | `EMPTYP` | `EMPTY? val` | Returns `1` if input is empty list or string, `0` otherwise | `EMPTY? []` |
| `EQUAL?` | `EQUALP`, `.EQ` | `EQUAL? a b` | Returns `1` if $a == b$, `0` otherwise | `EQUAL? :i 5` |
| `NOTEQUAL?` | `NOTEQUALP` | `NOTEQUAL? a b` | Returns `1` if $a \neq b$, `0` otherwise | `NOTEQUAL? :i 0` |
| `BEFORE?` | `BEFOREP` | `BEFORE? str1 str2` | Returns `1` if `str1` precedes `str2` alphabetically | `BEFORE? "apple" "banana"` |
| `MEMBER?` | `MEMBERP` | `MEMBER? item list` | Returns `1` if item exists in list | `MEMBER? 2 [1 2 3]` |
| `SUBSTRING?` | `SUBSTRINGP` | `SUBSTRING? sub str` | Returns `1` if substring is contained in string | `SUBSTRING? "cat" "caterpillar"` |
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
| `MINUS`, `ABS` | - | `MINUS a`, `ABS a` | Negation and absolute value | `ABS -15` |
| `INT`, `ROUND` | - | `INT a`, `ROUND a` | Truncate integer and round | `ROUND 3.7` |
| `SQRT`, `EXP` | - | `SQRT a`, `EXP a` | Square root and exponential $e^a$ | `SQRT 16` |
| `LOG10`, `LN` | - | `LOG10 a`, `LN a` | Logarithm base 10 and natural log | `LOG10 100` |
| `SIN`, `COS`, `TAN` | - | `SIN deg`, `COS deg` | Trigonometric functions (degrees) | `SIN 90` |
| `RANGE` | `ISEQ` | `RANGE start end [step]` | Generates inclusive integer sequence list | `RANGE 1 5` $\rightarrow$ `[1 2 3 4 5]`, `RANGE 1 10 2` |
| `RSEQ` | - | `RSEQ start end count` | Generates real number sequence list | `RSEQ 0 1 5` |
| `RANDOM` | - | `RANDOM max [min]` | Generates random integer in range | `RANDOM 100`, `RANDOM 10 20` |
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
| `FOREVER` | - | `FOREVER [ block ]` | Infinite loop until `STOP` | `FOREVER [ ... IF :x [ STOP ] ]` |
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
| `BUFFER` | `SETBUFFER` | `BUFFER [idx]` | Switches to buffer by index or returns active index | `BUFFER 2` |
| `NEXTBUFFER` | - | `NEXTBUFFER` | Switches to next open buffer tab | `NEXTBUFFER` |
| `PREVBUFFER` | - | `PREVBUFFER` | Switches to previous open buffer tab | `PREVBUFFER` |
| `OPENBUFFER` | `EDIT` | `EDIT "path"` | Opens file path into a new buffer tab | `EDIT "main.swift"` |
| `SAVE` | - | `SAVE ["path"]` | Saves the active buffer, optionally to a new path | `SAVE`, `SAVE "notes.txt"` |
| `FILE` | - | `FILE ["path"]` | Saves the active buffer, then closes it | `FILE`, `FILE "notes.txt"` |
| `CLOSEBUFFER` | - | `CLOSEBUFFER` | Closes active buffer tab | `CLOSEBUFFER` |
| `CLEARBUFFER` | `ERASEBUFFER` | `CLEARBUFFER` | Clears all text in active buffer | `CLEARBUFFER` |
| `GETLINE` | - | `GETLINE [row]` | Returns text content of specified line (or current line) | `MAKE "l" GETLINE 1` |
| `SETLINE` | - | `SETLINE [row] "text"` | Replaces text of specified line (or current line) | `SETLINE 1 "Title"` |
| `ROW` | `LINE.NO` | `ROW` | Returns current 1-indexed row number | `SHOW ROW` |
| `COL` | `COL.NO` | `COL` | Returns current 1-indexed column number | `SHOW COL` |
| `LINECOUNT` | `LINES` | `LINECOUNT` | Returns total line count of active buffer | `SHOW LINECOUNT` |
| `BUFFERTEXT` | - | `BUFFERTEXT` | Returns full string text of active buffer | `MAKE "t" BUFFERTEXT` |
| `SELECTION` | `SELECTEDTEXT` | `SELECTION` | Returns currently selected text string | `MAKE "s" SELECTION` |
| `MODIFIED?` | `CHANGED?` | `MODIFIED?` | Returns `1` if buffer has unsaved changes, `0` otherwise | `IF MODIFIED? [ SHOW "Unsaved" ]` |
| `FILENAME` | `BUFFERNAME` | `FILENAME` | Returns filename of active buffer | `SHOW FILENAME` |

---

### 9. Editor Configuration Settings (`SET`)

| Setting Command | Description | Example |
| :--- | :--- | :--- |
| `SET RULER ON / OFF` | Shows or hides column ruler line | `SET RULER ON` |
| `SET WRAP 80` | Sets line wrap column width | `SET WRAP 80` |
| `SET TAB 4` | Sets tab width spaces | `SET TAB 4` |
| `SET LINENUMBERS ON / OFF` | Shows or hides line number gutter; hiding it makes terminal copy/paste cleaner | `SET LINENUMBERS OFF` |

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
- `FILL`
- `TABLE`
- Turtle drawing commands: `PD`, `PU`, `FD`, `BK`, `RT`, `LT`

---

## ⚙️ `.serc` Integration

LOGO commands can be entered from the command prompt, evaluated from the editor, or loaded through `.serc` key bindings and startup blocks.

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
