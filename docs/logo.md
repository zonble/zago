# `se` LOGO Command Language

`se` features an innovative **LOGO-style Macro Language Engine**, bringing the clean, readable, human-friendly syntax paradigm of LOGO (`MAKE`, `:var`, `REPEAT`, `IF`, `IFELSE`, `TO...END`, `SORT`, `MAP`, `FILTER`) to TUI text buffer editing, 2D canvas box drawing, multi-buffer management, and macro automation.

---

## 🚀 Keybindings & Triggering

| Trigger Shortcut | Context / Input Mode | Description |
| :--- | :--- | :--- |
| **`Esc`** | Normal Edit Mode | Opens the bottom command prompt |
| **`M-l` (`Alt+L` / `Option+L`)** | Normal Edit Mode | Alternate shortcut for the command prompt |
| **`M-:` (`Alt+:`)** | Normal Edit Mode | Alternate Vim-style shortcut for the command prompt |
| **`F8`** | Normal Edit Mode | Function key shortcut for the command prompt |
| **`Left / Right` (`^B` / `^F`)** | Command Prompt Active | Moves input cursor left / right inside the prompt |
| **`Home / End` (`^A` / `^E`)** | Command Prompt Active | Moves input cursor directly to prompt line start / end |
| **`Delete` / `Backspace` (`^D`)**| Command Prompt Active | Deletes character at / before input cursor |
| **`Ctrl+Backspace` (`Ctrl+BS`)**| Command Prompt Active | Clears entire prompt input line |
| **`Up / Down` Arrows** | Command Prompt Active | Navigate through previously executed commands |
| **`Enter`** | Command Prompt Active | Execute the command and save it to history |
| **`Esc` / `^C`** | Command Prompt Active | Cancel prompt mode |
| **`^Z`** | Normal Edit Mode | Atomic Undo: Reverts the entire LOGO macro execution in 1 step |

---

## 📖 Complete Command Reference & Vocabulary

### 1. Text Insertion, Deletion & Line Formatting

| Command | Aliases | Syntax | Description | Example |
| :--- | :--- | :--- | :--- | :--- |
| `TYPE` | `PRINT` | `TYPE "text"` or `TYPE expr` | Inserts string or calculated expression at cursor | `TYPE "Hello World"` |
| `SHOW` | `MSG`, `MESSAGE` | `SHOW expr` | Displays status bar message | `SHOW "Saved successfully"` |
| `DATE` | - | `DATE [format]` | Evaluates/inserts current date (e.g. `YYYY/MM/DD` or `yyyy-MM-dd`) | `DATE`, `MAKE "d" DATE "YYYY/MM/DD"` |
| `TIME` | - | `TIME [format]` | Evaluates/inserts current time (default: `HH:mm:ss`) | `TIME`, `TIME "HH:mm"` |
| `NEWLINE` | `NL`, `ENTER` | `NEWLINE [n]` | Inserts $n$ newlines at current cursor | `NL`, `NEWLINE 2` |
| `LINE` | `HR` | `LINE [len] [style]` | Draws a horizontal line with smart junction fusion (`single`, `double`, `ascii`). Without `len`, draws up to 10 columns, stopping at text and fusing into borders. | `LINE`, `LINE 80 "double"` |
| `VLINE` | `VR`, `VHR` | `VLINE [height] [style]` | Draws a vertical line with smart junction fusion (`single`, `double`, `ascii`). Without `height`, draws up to 10 rows, stopping at text and fusing into borders. | `VLINE`, `VLINE 5 "double"` |
| `DEL` | `DELETE` | `DEL [n]` | Deletes $n$ characters forward | `DEL 5` |
| `BS` | `BACKSPACE` | `BS [n]` | Deletes $n$ characters backward | `BS 3` |
| `DELETELINE` | `DELLINE`, `KILLLINE`, `DL` | `DELETELINE [n]` | Deletes $n$ current lines | `DELETELINE`, `DL 3` |
| `JUSTIFY` | - | `JUSTIFY` | Reflows and justifies current paragraph | `JUSTIFY` |

---

### 2. Common Drawing Commands: `BOX`, `LINE`, and `VLINE`

`BOX` and line drawing are the most useful LOGO commands for turning a plain text buffer into a structured terminal canvas. They are intended for fast notes, diagrams, forms, and lightweight layouts.

#### `BOX`

`BOX` draws a frame at the current cursor position. It supports three common forms:

```logo
BOX "Hello"
BOX 30 4
BOX SELECTION
```

Text boxes size themselves from the text:

```logo
BOX "Status" "center" "round"
```

```text
╭────────╮
│ Status │
╰────────╯
```

Empty boxes use explicit visual dimensions:

```logo
BOX 30 4 ROUND
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

Supported alignments for text boxes:

- `left`
- `center` / `centre`
- `right`

Supported styles:

- `single`: `┌ ┐ └ ┘ ─ │`
- `double`: `╔ ╗ ╚ ╝ ═ ║`
- `round` / `rounded`: `╭ ╮ ╰ ╯ ─ │`
- `double-round`: rounded corners with double horizontal and vertical strokes where possible
- `ascii`: `+ - |`

Box drawing is overlay-oriented: existing text at the target coordinates can be replaced by the frame. Use `GOTO` first when positioning matters.

#### `LINE` and `VLINE`

`LINE` draws horizontally from the cursor. `VLINE` draws vertically from the cursor.

```logo
LINE 20
VLINE 5
LINE 30 DOUBLE
VLINE 4 ASCII
```

With an explicit length or height, the command draws exactly that distance, up to the implementation limits:

- `LINE`: 1 to 200 columns
- `VLINE`: 1 to 100 rows

Without an explicit length, the command uses auto-connect mode:

```logo
LINE
VLINE
```

Auto-connect mode:

- scans up to 10 columns for `LINE`, or 10 rows for `VLINE`
- draws through empty space
- stops before regular text
- fuses into an existing border or junction, then stops

This makes it practical to connect boxes without counting exact distances:

```logo
BOX 10 4
GOTO 3 10
LINE
```

If the line reaches another border within 10 columns, the endpoint becomes a junction instead of overwriting the border.

`LINE` and `VLINE` use smart junction fusion with existing single-line and double-line box characters. For example:

```logo
BOX 6 3
GOTO 1 3
VLINE 3
```

```text
┌─┬──┐
│ │  │
└─┴──┘
```

Use explicit lengths when you want deterministic drawing. Use no-argument auto-connect mode when you are drawing connectors between nearby boxes.

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

### 4. Table Mode Safety

When Table Mode is active, LOGO execution is constrained to protect the current table cell structure.

Allowed behavior:

- `TYPE` / `PRINT` may insert text into the active cell.
- Text output is clipped to the editable cell area and will not shift, overwrite, or pass the right border.
- Newlines move within the active cell; output stops when it would leave the cell.
- Non-drawing expressions, variables, procedures, status messages, and data operations remain available.

Disabled while Table Mode is active:

- `BOX`
- `LINE` / `HR`
- `VLINE` / `VR` / `VHR`
- `FILL`
- Turtle drawing commands: `PD`, `PU`, `FD`, `BK`, `RT`, `LT`

This rule applies to all LOGO entry points: `^Q` eval, the interactive LOGO prompt, and `.serc` key-bound macros. It also applies when a called `TO ... END` procedure contains one of the disabled drawing commands.

---

### 5. Cursor Navigation, Selection & 2D Canvas Overlay Box Framing

| Command | Aliases | Syntax | Description | Example |
| :--- | :--- | :--- | :--- | :--- |
| `MOVE` | - | `MOVE UP / DOWN / LEFT / RIGHT / HOME / END` | Moves cursor in 2D text canvas | `MOVE DOWN`, `MOVE END` |
| `GOTO` | - | `GOTO line [column]` | Jumps directly to 1-indexed line and optional column | `GOTO 10`, `GOTO 42 5` |
| `GOTOLINE` | `SETROW` | `GOTOLINE row` | Moves cursor to 1-indexed row number | `GOTOLINE 15` |
| `GOTOCOL` | `SETCOL` | `GOTOCOL col` | Moves cursor to 1-indexed column number | `GOTOCOL 8` |
| `BOX` | - | `BOX "text" [align] [style]` | Draws 2D overlay box around text (`left`, `center`, `right`) | `BOX "Hello World" "center"` |
| `BOX` | - | `BOX width height [style]` | Draws empty 2D overlay box frame (`single`, `double`, `ascii`, `round`, `double-round`) | `BOX 20 5 "round"` |
| `BOX` | - | `BOX SELECTION [style]` | Encloses active text selection region in box frame | `BOX SELECTION "double"` |
| `MARK` | - | `MARK` | Toggles text selection mark anchor | `MARK` |
| `CUT` | - | `CUT` | Cuts selected text or current line to clipboard | `CUT` |
| `PASTE` | `UNCUT` | `PASTE` | Pastes clipboard text at current cursor | `PASTE` |
| `FIND` | `SEARCH` | `FIND "query"` | Case-insensitive forward text search | `FIND "func"` |

---

### 6. Multi-Buffer & Buffer Operations

| Command | Aliases | Syntax | Description | Example |
| :--- | :--- | :--- | :--- | :--- |
| `BUFFERS` | `BUFFERLIST` | `BUFFERS` | Returns list of open buffer names | `MAKE "b" BUFFERS` |
| `BUFFER` | `SETBUFFER` | `BUFFER [idx]` | Switches to buffer by index or returns active index | `BUFFER 2` |
| `NEXTBUFFER` | - | `NEXTBUFFER` | Switches to next open buffer tab | `NEXTBUFFER` |
| `PREVBUFFER` | - | `PREVBUFFER` | Switches to previous open buffer tab | `PREVBUFFER` |
| `OPENBUFFER` | - | `OPENBUFFER "path"` | Opens file path into a new buffer tab | `OPENBUFFER "main.swift"` |
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

### 7. Data Structures: Lists, Arrays, Words & Sorting

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

### 8. Predicates & Type Checking

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

### 9. Logical, Math & Bitwise Operations

| Command | Aliases | Syntax | Description | Example |
| :--- | :--- | :--- | :--- | :--- |
| `TRUE`, `FALSE` | - | `TRUE`, `FALSE` | Constant values `1` and `0` | `TRUE` |
| `AND`, `OR`, `XOR`, `NOT` | - | `AND a b`, `NOT a` | Boolean logical operations | `AND (LESS? 1 2) (GREATER? 5 3)` |
| `SUM` | - | `SUM a b` | Addition ($a + b$) | `SUM 10 20` |
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
| `ISEQ` | - | `ISEQ start end` | Generates integer sequence list | `ISEQ 1 5` $\rightarrow$ `[1 2 3 4 5]` |
| `RSEQ` | - | `RSEQ start end count` | Generates real number sequence list | `RSEQ 0 1 5` |
| `RANDOM` | - | `RANDOM max [min]` | Generates random integer in range | `RANDOM 100`, `RANDOM 10 20` |
| `BITAND`, `BITOR`, `BITXOR`, `BITNOT` | - | `BITAND a b` | Bitwise logic operations | `BITAND 5 3` |
| `ASHIFT`, `LSHIFT` | - | `ASHIFT val shift` | Arithmetic and logical bit shifts | `LSHIFT 1 4` |

---

### 10. Conditionals, Loops & Higher-Order Functions

| Command | Aliases | Syntax | Description | Example |
| :--- | :--- | :--- | :--- | :--- |
| `MAKE` | `VAR` | `MAKE "var" expr` | Assigns value to variable | `MAKE "i" 1` |
| `:var` | - | `:var_name` | Dereferences variable value | `TYPE :i` |
| `IF` | - | `IF cond [ block ]` | Executes block if condition is true | `IF :i > 5 [ TYPE "OK" ]` |
| `IFELSE` | - | `IFELSE cond [ t_block ] [ f_block ]` | Branching if-else execution | `IFELSE :i == 2 [ TYPE "TWO" ] [ TYPE :i ]` |
| `TEST` | - | `TEST cond` | Sets internal test flag for `IFTRUE`/`IFFALSE` | `TEST :i == 1` |
| `IFTRUE` | `IFT` | `IFTRUE [ block ]` | Executes if preceding `TEST` was true | `IFT [ TYPE "Yes" ]` |
| `IFFALSE` | `IFF` | `IFFALSE [ block ]` | Executes if preceding `TEST` was false | `IFF [ TYPE "No" ]` |
| `REPEAT` | - | `REPEAT count [ block ]` | Loops enclosed code block $n$ times | `REPEAT 3 [ TYPE "! " ]` |
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

### 11. Editor Configuration Settings (`SET`)

| Setting Command | Description | Example |
| :--- | :--- | :--- |
| `SET RULER ON / OFF` | Shows or hides column ruler line | `SET RULER ON` |
| `SET WRAP 80` | Sets line wrap column width | `SET WRAP 80` |
| `SET TAB 4` | Sets tab width spaces | `SET TAB 4` |
| `SET LINENUMBERS ON / OFF` | Shows or hides line number gutter | `SET LINENUMBERS ON` |

---

## `.serc` Integration

LOGO commands can be entered from the command prompt, evaluated from the editor, or loaded through `.serc` key bindings and startup blocks.

For configuration syntax, named scripts, startup preludes, and command ids, see [Configuration](configuration.md).

---

## 💡 Practical Real-World Macro Examples

### 1. Higher-Order Functional Data Transformation (`MAP`, `FILTER`, `SORT`)

Doubles list elements, filters elements greater than 5, and sorts them descending:

```logo
MAKE "nums" [3 1 4 1 5 9 2 6] MAKE "doubled" MAP [? * 2] :nums MAKE "filtered" FILTER [? > 5] :doubled MAKE "res" SORT "DESC :filtered
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

---

## 🧪 Atomic Undo (`^Z`) Guarantee

All operations performed by a single LOGO macro execution—regardless of how many lines or characters were inserted or modified—are grouped into a **single atomic Undo snapshot**.
