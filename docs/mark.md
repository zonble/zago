# Mark, Selection, and Clipboard Behavior

This document defines the intended selection behavior for text edit mode and
canvas mode. The two modes use different selection models because they edit
different shapes of data.

## Design Goals

- Text edit mode selects linear text.
- Table mode uses the same linear selection model as text edit mode.
- Canvas mode marks rectangular cell blocks.
- Text selection and canvas block mark do not interoperate.
- Text clipboard and canvas block clipboard do not interoperate.
- Switching modes always clears the active selection or mark.
- Selections never extend past the end of file.

## Text Edit Mode

Text edit mode follows a conventional editor selection model.

### Selection

- `Shift+Left`, `Shift+Right`, `Shift+Up`, and `Shift+Down` create or extend
  a linear text selection.
- The old nano-like `^^` / `Ctrl+^` mark shortcut is not used in text edit
  mode.
- Non-shift cursor movement clears the selection.
- Typing text while a selection is active replaces the selected text.
- Editing commands that do not operate on a selection clear the selection.
- `Esc` may be used as an explicit selection cancel command if it is not
  already opening another prompt in that context.

### Empty-Line Rendering

If a text selection includes an empty line, that empty line is rendered as a
full-width highlighted line so the selected line is visible.

### Cut and Paste

- `^K` cuts the selected linear text into the text clipboard.
- If no selection is active, `^K` cuts the current line.
- `^U` pastes from the text clipboard as normal linear text insertion.
- Text clipboard content is not available to canvas block paste.

## Table Mode

Table mode uses the same selection and clipboard model as text edit mode.

- `Shift+Left`, `Shift+Right`, `Shift+Up`, and `Shift+Down` create or extend
  a linear text selection.
- Selection is limited to the current table cell.
- The old nano-like `^^` / `Ctrl+^` mark shortcut is not used in table mode.
- Non-shift cursor movement clears the selection.
- Typing text while a selection is active replaces the selected text, subject
  to table cell constraints.
- `^K` cuts the selected linear text into the text clipboard.
- If no selection is active, `^K` follows the table-mode line/cell cut rules.
- `^U` pastes from the text clipboard using normal table-mode paste behavior.
- Table mode does not use canvas block mark or canvas block clipboard.

## Canvas Mode

Canvas mode follows a PE2-style rectangular block mark model.

### Block Mark

- `^^` / `Ctrl+^` sets or updates the canvas block mark.
- The active block is the rectangle between the mark anchor and the current
  cursor position.
- Block bounds are visual-cell based and inclusive.
- The block may include empty cells and trailing blank space.
- Canvas block mark is independent from text edit mode selection.
- Block edges snap to whole character boundaries. A block operation must not
  split a wide character such as CJK text or emoji.

### Cancel Mark

Canvas mode needs an explicit cancel-mark key. The exact key is still open.
Candidates:

- `Esc`
- `^G`
- a dedicated command exposed through the menu and configurable key bindings

The chosen cancel command clears only the active canvas block mark. It does
not alter either clipboard.

### Cut Block

With an active block mark, `^K` cuts a rectangular block into the canvas block
clipboard.

For each affected row:

- The cells inside the block are removed.
- Cells to the right of the block shift left by the block width.
- The copied clipboard data preserves the rectangular shape, including spaces
  inside the block.
- Trailing spaces are not preserved in the buffer after the row is rewritten.

After `^K`, the cursor moves to the block top-left corner and the canvas block
mark is cleared.

Without an active block mark, `^K` does not cut the current row. It reports
that no block is marked.

Example:

```text
Before:
abcdef
123456

Marked block: rows 1...2, columns 2...4

After ^K:
aef
156

Canvas block clipboard:
bcd
234
```

### Paste Block

`^U` pastes from the canvas block clipboard as a rectangular block.

For each pasted row:

- The row receives the corresponding clipboard row.
- Existing cells at and to the right of the cursor shift right by the block
  width.
- Missing target rows are created as needed.
- The cursor stays at the paste top-left corner.

Example:

```text
Before:
xxYY
zzWW

Cursor: row 1, column 3
Canvas block clipboard:
bcd
234

After ^U:
xxbcdYY
zz234WW
```

### Fill Marked Block

When canvas mode has an active block mark, the LOGO `FILL` command fills the
marked rectangular block.

- `FILL text` repeats `text` across each marked row.
- Empty `FILL` arguments are not allowed.
- The result is clipped to the marked block width.
- Filling uses visual cells, not raw string indices.
- Wide characters must respect terminal display width.
- If the remaining width is too small for the next wide character, the
  remaining cell is filled with a space.
- `FILL " "` is supported and clears the block without shifting surrounding
  content.
- After a successful fill, the cursor stays in place and the canvas block mark
  is cleared.

Example:

```text
Before:
abcdef
123456
uvwxyz

Marked block: rows 1...2, columns 2...4
FILL "x"

After:
axxxef
1xxx56
uvwxyz
```

## Open Decisions

- Choose the final canvas cancel-mark key.
