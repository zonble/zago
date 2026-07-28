# 🖊️ `PD` / `PU` (Pen Down / Pen Up) Diagram Drawing Mode Guide

In `se`, the classical LOGO commands `PD` (**Pen Down**) and `PU` (**Pen Up**) are repurposed into an intuitive **ASCII & Unicode Diagram Drawing Mode** for text files.

Instead of controlling a graphical canvas, `PD` and `PU` toggle how cursor navigation (`FD`, `BK`, `MOVE`, `GOTO`) interacts with the text editor buffer.

---

## 💡 Concept & Core Purpose

In a text editor, drawing diagrams, ASCII flowcharts, box frames, or table structures often requires moving the cursor while leaving character trails, followed by repositioning the cursor to another location *without* overwriting existing text.

| Command | Full Name | Status | Description in `se` Text Editor |
| :--- | :--- | :--- | :--- |
| **`PD`** | **Pen Down** | Active Drawing Mode | Lowers the pen onto the text buffer. As the cursor moves (`FD`, `BK`, `MOVE`), it automatically inserts line-drawing characters (`─`, `│`) and fuses junction corners (`┌`, `┐`, `└`, `┘`, `┼`, `├`, `┤`, `┬`, `┴`). |
| **`PU`** | **Pen Up** | Navigation Mode (Default) | Lifts the pen off the text buffer. The cursor can move freely (`GOTO`, `MOVE`, `FD`) without drawing any lines or altering existing text. |

---

## 🛡️ Default Safety Rule

To ensure that general text navigation and macro execution do not accidentally overwrite or corrupt document text:

> **Default State**: Every LOGO macro execution starts with **`PU` (Pen Up)** mode active by default.

If you write a macro to navigate lines or insert text (`MOVE DOWN`, `GOTO 10 5`), no lines will be drawn unless you explicitly issue a `PD` command.

---

## 🎨 How `PD` Automatic Line & Junction Fusion Works

When `PD` is active, moving the cursor automatically analyzes neighboring characters and fuses intersecting lines into appropriate Unicode box-drawing characters:

```text
       PD FD 5              RT 90 FD 5              RT 90 FD 5
      (Draw Top Line)     (Draw Right Edge)     (Draw Bottom Edge)

Line 1: ───────             Line 1: ───────┐       Line 1: ───────┐
Line 2:                     Line 2:        │       Line 2:        │
Line 3:                     Line 3:        │       Line 3: ───────┘
```

1. **Horizontal Movement** (`FD` when facing East/West, or `MOVE RIGHT`): Inserts `─` (or `═` / `-` depending on style).
2. **Vertical Movement** (`FD` when facing North/South, or `MOVE DOWN`): Inserts `│` (or `║` / `|`).
3. **Corner Junctions**: When directions change (e.g. `FD 5 RT 90 FD 5`), the intersection character automatically fuses into `┐`, `┘`, `└`, or `┌`.
4. **Crossings & T-Junctions**: Crossing an existing line automatically upgrades the character to `┼`, `├`, `┤`, `┬`, or `┴`.

---

## 📖 Practical Code Examples

### Example 1: Drawing a Single Square Box Frame

```logo
PD REPEAT 4 [ FD 5 RT 90 ] PU
```

**Output:**

```text
┌────┐
│    │
│    │
│    │
└────┘
```

---

### Example 2: Drawing Two Disjoint Boxes (`PU` Repositioning)

Use `PU` to lift the pen, jump to a new coordinate with `GOTO`, and use `PD` to draw the second box:

```logo
; Draw Box 1 at top left
PD REPEAT 4 [ FD 4 RT 90 ] PU

; Move pen safely to Column 15, Line 1 without drawing
GOTO 1 15

; Draw Box 2 at top right
PD REPEAT 4 [ FD 4 RT 90 ] PU
```

**Output:**

```text
┌───┐         ┌───┐
│   │         │   │
│   │         │   │
└───┘         └───┘
```

---

### Example 3: Drawing a Flowchart with Connecting Arrows

```logo
; Box 1: Start Node
PD REPEAT 4 [ FD 4 RT 90 ] PU

; Move to middle of right edge of Box 1 (Line 2, Col 5)
GOTO 2 5

; Drop pen and draw connector line to the right
PD MOVE RIGHT 6 PU

; Lift pen and move to start position for Box 2 (Line 1, Col 12)
GOTO 1 12

; Box 2: Next Node
PD REPEAT 4 [ FD 4 RT 90 ] PU
```

**Output:**

```text
┌───┐───────┌───┐
│   │       │   │
│   │       │   │
└───┘       └───┘
```

---

## summary

- **`PD` (Pen Down)**: Turn on ASCII/Unicode line & box drawing mode during cursor movement.
- **`PU` (Pen Up)**: Turn off drawing mode to move the cursor safely across the document.
- **Best Practice**: Always pair `PD` with a trailing `PU` when your drawing sequence finishes.
