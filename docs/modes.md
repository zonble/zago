# Editor Modes

This document describes the planned editing modes for `zago`. The goal is to
keep ordinary text editing fast while also supporting fixed-position diagram
editing, table cell editing, and keyboard-driven box/arrow drawing in Canvas
Mode.

`zago` should remain simple from the user's point of view: most editing happens
in Text Editing Mode, while specialized modes temporarily change cursor
movement, wrapping, and insertion behavior.

## Mode Model

The editor has two kinds of modes:

1. **Base modes** define the coordinate system and default typing behavior.
   - Text Editing Mode
   - Canvas Mode
2. **Overlay modes** add constraints on top of the current base mode.
   - Table Mode

Only one base mode is active at a time. Overlay modes may be active only when
their requirements are satisfied.

When an overlay mode exits, the editor should return to the base mode that was
active before the overlay was entered.

## Mode Summary

| Mode | Type | Main Purpose | Wrapping | Typing Behavior |
| :--- | :--- | :--- | :--- | :--- |
| Text Editing Mode | Base | Normal prose and source editing | Soft wrap | Insert text |
| Canvas Mode | Base | Fixed-position diagrams and layouts | No wrap | Replace or pad text at cursor |
| Table Mode | Overlay | Edit inside one detected table cell | Inherits base mode where possible | Insert only within cell bounds |

## Menu Bar Entrypoints

All editor modes must be reachable from the menu bar, not only through
keyboard shortcuts or LOGO commands.

Suggested menu placement:

| Menu | Item | Action | Checked State |
| :--- | :--- | :--- | :--- |
| Edit | Text Editing Mode | Switch base mode to Text | checked when base mode is Text |
| Edit | Canvas Mode | Toggle or switch base mode to Canvas | checked when base mode is Canvas |
| Edit | Table Mode | Toggle Table Mode | checked when Table Mode is active |

Menu behavior rules:

- Text Editing Mode and Canvas Mode are mutually exclusive base-mode choices.
- Table Mode is an overlay choice and should show checked state independently
  from the base mode.
- Selecting Table Mode from the menu follows the same behavior as `M+T`.
- Selecting Canvas Mode from the menu follows the same behavior as `M+V`.
- Menu items that cannot run in the current state should either be disabled or
  show a short status message explaining the conflict.

## Text Editing Mode

Text Editing Mode is the default mode for normal documents, notes, and source
files.

### Behavior

- Soft wrap is enabled according to the current wrap configuration.
- Cursor movement follows the logical text buffer and visual wrapped lines.
- The cursor may move to any valid line in the buffer and to any character
  position within that line.
- Typing inserts text at the cursor and shifts following text to the right.
- Backspace and delete behave like normal text editing operations.
- The ruler is anchored to the visible text width of the screen.
- Horizontal scrolling should be avoided when soft wrap is active.

### Cursor Rules

- Moving left or right crosses line boundaries using normal text-editor
  behavior.
- Moving up or down should preserve the preferred visual column when possible.
- The editor should distinguish between buffer coordinates and visual wrapped
  coordinates so navigation remains predictable on long lines.

### Ruler Rules

- The ruler starts at the first editable text column after the gutter.
- The ruler width tracks the current screen text width or configured wrap
  column.
- Wrapped visual lines do not reset the ruler; the ruler represents the
  document column system, not the current visual fragment.

## Canvas Mode

Canvas Mode is for editing diagrams, ASCII/Unicode layouts, forms, and other
fixed-position content where every `(x, y)` coordinate matters.

### Activation

- `M+V` toggles between Text Editing Mode and Canvas Mode.
- When Canvas Mode is turned off, the editor returns to Text Editing Mode.
- Entering Canvas Mode should preserve the current cursor's logical buffer
  location as closely as possible.

### Behavior

- Soft wrap is disabled.
- The cursor moves in a two-dimensional grid: line `y`, column `x`.
- The cursor may move beyond the current end of line.
- Moving beyond existing text does not immediately change the buffer.
- Typing at a virtual position pads the line with spaces up to the cursor
  column, then writes the typed character.
- Typing replaces the character at the cursor instead of inserting before it.
- New lines may be created when the cursor moves below the current buffer end
  and then writes content.
- The editor horizontally scrolls by pages when the cursor moves outside the
  visible text area.

### Coordinate Rules

- The first editable column is `x = 0`, independent of the line number gutter.
- The first buffer line is `y = 0`.
- Display width, not Unicode scalar count, should be used for column movement.
  CJK full-width characters and box-drawing characters must keep stable visual
  alignment.
- If the cursor lands inside a multi-column character, it should snap to the
  nearest valid character boundary.

### Ruler Rules

- The ruler is tied to the current horizontal canvas page.
- When horizontally scrolled, the ruler starts from that page's left margin
  instead of always starting at column `1`.
- Example: if the viewport shows document columns `80...159`, the ruler should
  label that visible range rather than the screen-local `1...80` range.

### Editing Rules

- Printable input replaces the current cell.
- Backspace should clear the previous visible cell and move left.
- Delete should clear the current visible cell without shifting following
  content.
- Enter should move to the beginning of the next line, preserving Canvas Mode.
- Paste should write fixed-position text without reflowing paragraphs.

### Keyboard Drawing Rules

Canvas Mode owns keyboard-driven line, box, and arrow drawing. There will be no
separate Frame Mode.

- `Shift+Arrow` draws one box-line step in the requested direction and moves
  the canvas cursor to the new endpoint.
- `Ctrl+Arrow` draws one arrow-line step in the requested direction and moves
  the canvas cursor to the arrow endpoint.
- Horizontal movement writes the horizontal line character from the current
  border style.
- Vertical movement writes the vertical line character from the current border
  style.
- Arrow-line movement uses the same horizontal/vertical line characters, then
  places an arrowhead at the endpoint for the requested direction.
- Corners, crossings, and T-junctions should be fused automatically when a
  drawn segment meets an existing compatible box-drawing character.
- Arrowheads should be fused or replaced carefully so the final endpoint remains
  visually directional while the traversed segment still joins existing lines.
- New drawing uses the same current/default border style used by LOGO `BOX`,
  `DRAWBOX`, and table drawing commands.
- Existing non-line text should not be overwritten unless a future explicit
  overwrite policy is added.
- Drawing must use display-cell coordinates, so CJK full-width characters,
  emoji, combining marks, and tabs follow the same snapping rules as normal
  Canvas Mode cursor movement.
- Drawing is disabled while Table Mode is active, because Table Mode owns table
  borders and adjacent cell geometry.

## Justification Rules

Justification is the paragraph reflow command exposed by `^J` and the LOGO
`JUSTIFY` command. It is a text-formatting operation, not a drawing operation.

### Scope

- If there is an active text selection, justification should operate on the
  selected text only.
- If there is no active selection, justification operates on the paragraph at
  the cursor.
- A paragraph is a contiguous run of non-empty lines.
- Empty or whitespace-only lines are paragraph boundaries and must be preserved.
- Justification should not cross table borders, fenced diagram blocks, or other
  protected structured regions.

### Target Width

- If a fixed wrap column is configured, that value is the target width.
- Otherwise the target width is derived from the visible text area.
- The target width should never be smaller than the editor's minimum practical
  formatting width.
- In Table Mode, the target width is the active cell's editable width, not the
  full screen or global wrap column.
- In Canvas Mode, justification is disabled by default because Canvas Mode
  preserves fixed coordinates. A future explicit command may allow selection
  reflow in Canvas Mode, but it must be opt-in.

### Text Reflow

- Leading and trailing whitespace on each source line is trimmed before reflow.
- Source lines in the paragraph are joined with a single separating space.
- Latin words are wrapped at word boundaries when possible.
- CJK text may wrap between characters when needed.
- Mixed CJK and Latin text must use display width, not Unicode scalar count.
- The result should not add full-justification spacing between words; this
  command reflows text to the target width while preserving natural spacing.
- The cursor moves to the start of the reflowed paragraph after the operation.

### Mode Interaction

In Text Editing Mode:

- `^J` and `JUSTIFY` reflow the current paragraph or active selection.
- The operation saves one undo snapshot.
- The status line reports that the paragraph was justified.

In Canvas Mode:

- `^J` should be ignored or rejected with a status message.
- The buffer must not be reflowed implicitly because that would shift fixed
  diagram coordinates.

In Table Mode:

- Justification is allowed only for the active cell content.
- Reflow must stay within the cell's editable bounds.
- Borders and adjacent cells are read-only.
- If the reflowed text would exceed the available cell height, the editor should
  either clip with a status message or reject the operation; it must not expand
  or rewrite the table geometry implicitly.

## Table Mode

Table Mode is an overlay mode for editing the content of a table cell without
damaging table borders or adjacent cells.

The current implementation already exposes `M+T` for toggling table mode. This
plan clarifies the intended behavior when Table Mode is combined with Text
Editing Mode or Canvas Mode.

### Activation

- `M+T` toggles Table Mode.
- If the cursor is inside a recognized table cell, the editor enters Table Mode
  and stores the current base mode.
- If no table cell is detected, the editor may prompt to create a new table.
- When Table Mode exits, the editor returns to the remembered base mode.

### Supported Table Forms

Table detection should support at least:

- Unicode box-drawing tables.
- ASCII box tables using `+`, `-`, and `|`.
- Markdown pipe tables.

### Behavior

- Only cell content is editable.
- Borders are read-only while Table Mode is active.
- Cursor movement is constrained to the current cell unless the user uses table
  navigation commands.
- `Tab` moves to the next editable cell.
- `Shift+Tab` should move to the previous editable cell.
- `Enter` moves to the next line within the current cell when space is
  available; otherwise it moves to the next row or next cell according to the
  table navigation policy.
- Typing must not overflow into the border or the next cell.
- CJK and other wide characters count by display width when checking available
  cell space.

### Interaction With Base Modes

In Text Editing Mode:

- Text insertion inside a cell may shift content only within that cell's
  editable bounds.
- Soft wrap and justification should not wrap across cell borders.
- Paragraph tools such as justify should operate only on the active cell
  content and use the cell's editable width.

In Canvas Mode:

- Cell editing is fixed-position.
- Printable characters replace the current cell position.
- Backspace and delete clear characters without shifting table borders.

### Disabled Commands

Table Mode must block commands that can rewrite table geometry or draw outside
the current cell. Examples:

- `LINE`
- `BOX`
- `DRAWBOX`
- `TABLE`
- commands or procedures that expand to the same geometry-changing primitives

When blocked, the editor should show a short status message explaining which
command is disabled in Table Mode.

### Exit Rules

- Toggling `M+T` exits Table Mode.
- If the table structure becomes invalid while editing, Table Mode should exit
  gracefully and keep the buffer content unchanged except for accepted edits.
- Exiting Table Mode clears the active cell highlight and active cell metadata.

## Mode Stack And State

The editor should track:

- Active base mode: `text` or `canvas`.
- Active overlay mode: none or `table`.
- Previous base mode for overlays that temporarily force a different base mode.
- Cursor position in buffer coordinates.
- Preferred visual column for vertical movement.
- Horizontal canvas page offset.
- Table cell bounds when Table Mode is active.
- Current/default border style shared with LOGO boxes, tables, and Canvas Mode
  keyboard drawing.

Suggested state transitions:

| Current State | Input | Next State |
| :--- | :--- | :--- |
| Text | `M+V` | Canvas |
| Text | Menu: Canvas Mode | Canvas |
| Canvas | `M+V` | Text |
| Canvas | Menu: Text Editing Mode | Text |
| Text inside table | `M+T` | Text + Table |
| Canvas inside table | `M+T` | Canvas + Table |
| Any inside table | Menu: Table Mode | remembered base mode or base + Table |
| Any + Table | `M+T` | remembered base mode |

## Conflict Rules

- Table Mode has priority over ordinary text insertion because it protects table
  geometry.
- In Canvas Mode, `Shift+Arrow` and `Ctrl+Arrow` have priority over selection
  extension and word-wise movement because they are drawing gestures.
- Table Mode has priority over Canvas Mode keyboard drawing. `Shift+Arrow`
  should extend table selection or follow the table-mode rule, not draw over
  borders; `Ctrl+Arrow` should follow the table-mode rule or be rejected with a
  status message.
- Command prompt, search prompt, save prompt, and confirmation prompts are not
  editor modes. They temporarily capture input and then return to the previous
  editor mode.
- Undo snapshots should be mode-aware: a single drawing gesture or table edit
  should undo as one coherent operation when possible.

## Rendering Requirements

- The line immediately above the two-line help bar is the status/prompt line.
  When no prompt is active, it should show the active mode indicators there.
- Mode indicators should include Canvas Mode and Table Mode when active. Text
  Editing Mode may be omitted because it is the default.
- Suggested compact labels: `CANVAS`, `TABLE`.
- When multiple mode states are relevant, show them together, for example:
  `CANVAS | TABLE`.
- A transient status message may temporarily replace or share space with the
  mode indicators, but the user should be able to see the active mode state
  while editing.
- Table Mode should highlight the active editable cell without coloring table
  borders.
- Canvas Mode should render the cursor correctly on virtual columns beyond the
  current line end.
- Canvas Mode should provide immediate visual feedback after each
  `Shift+Arrow` box-drawing step or `Ctrl+Arrow` arrow-drawing step.
- Ruler rendering must account for soft wrap in Text Editing Mode and
  horizontal page offset in Canvas Mode.

### Help Bar Rules

The help bar must reflect the active editing semantics. Canvas Mode should not
reuse the Text Editing Mode help set because several modifier keys have
different meanings there.

- Text Editing Mode shows the normal text-editing help set.
- Canvas Mode shows a dedicated Canvas help set.
- Canvas help uses both help-bar rows:
  - Row 1: `^O Save`, `^X Exit`, `M+V Text`, `Arrows Move`,
    `Shift+Arrow Box`, `Ctrl+Arrow Arrow`.
  - Row 2: `Type Replace`, `BS/Del Clear`, `Enter New Line`, `M+T Table`,
    `Esc Command`.
- Table Mode help takes priority when Table Mode is active. If the base mode is
  Canvas, the status/prompt line should still indicate `CANVAS | TABLE`, but
  the help bar should describe table-safe editing.
- Prompt and menu help bars take priority over all editor-mode help bars while
  a prompt or menu is active.
- Narrow terminal widths may abbreviate labels, but must not show Text Editing
  Mode shortcuts that conflict with Canvas Mode drawing gestures.

## Implementation Notes

The codebase already has useful foundations for Canvas Mode:

- `Character.displayWidth` and `String.displayWidth` centralize terminal cell
  width handling.
- Softwrap already measures lines by display width.
- Renderer cursor placement already converts character offsets to terminal
  display columns.

Because of that, Canvas Mode does not need a new wide-character detection
system. The main missing layer is a display-cell coordinate adapter. The current
buffer cursor column is a `Character` offset, while Canvas Mode needs `x` to be
a terminal display-cell column.

Add a small set of shared helpers before implementing Canvas Mode behavior:

```swift
characterIndexToVisualColumn(line, charOffset) -> Int
visualColumnToCharacterIndex(line, visualColumn) -> String.Index / charOffset
snapVisualColumn(line, visualColumn) -> valid cell boundary
writingAtVisualColumn(line, visualColumn, character, policy) -> result
clearingAtVisualColumn(line, visualColumn) -> result
```

These helpers should define how the editor behaves when a target visual column
falls inside a wide character, combining sequence, emoji, or tab expansion.
Canvas Mode, keyboard drawing, Table Mode cell editing, and cursor rendering
should all reuse the same conversion rules.

## Implementation Checklist

### Phase 1: Mode State, Menu, And Indicators

This phase should be the first implementation step. It establishes visible mode
state without changing Canvas editing semantics yet.

- [x] Add explicit editor mode state:
  `baseMode: text | canvas` and `overlayMode: none | table`.
- [x] Keep Text Editing Mode as the default base mode.
- [x] Add mode transition helpers instead of scattering mode changes across
  key handlers, menu actions, and LOGO actions.
- [x] Add menu bar entries for Text Editing Mode, Canvas Mode, and Table Mode.
- [x] Render checked state for active mode menu items.
- [x] Add status/prompt-line indicators above the help bar for active
  `CANVAS` and `TABLE` states.
- [x] Ensure transient status messages do not permanently hide active mode
  indicators.
- [x] Wire `M+V` and `M+T` behavior through the same transition helpers used by
  the menu bar.
- [x] Add tests for mode state transitions, menu checked states, and
  status/prompt-line mode indicators.

### Phase 2: Display-Cell Coordinate Adapter

This phase is the technical prerequisite for Canvas Mode. Do not treat the
existing buffer `columnIndex` as the Canvas `x` coordinate.

- [x] Add `characterIndexToVisualColumn` for converting a buffer character
  offset into a terminal display-cell column.
- [x] Add `visualColumnToCharacterIndex` for converting a terminal display-cell
  column back into a buffer insertion/replacement position.
- [x] Add `snapVisualColumn` for targets that land inside a wide character,
  combining sequence, emoji, or tab expansion.
- [x] Add `writingAtVisualColumn` and `clearingAtVisualColumn` for
  fixed-position write, replace, clear, and pad behavior.
- [x] Reuse these helpers in existing Table Mode visual-column navigation.
- [ ] Reuse these helpers in Canvas Mode keyboard drawing and cursor rendering
  as those phases are implemented.
- [x] Add focused tests for ASCII, CJK, emoji, combining marks, tabs, and
  out-of-line padding.

### Phase 3: Canvas Mode

- [x] Add Canvas Mode cursor state using `(line, visualColumn)`.
- [x] Render Canvas Mode without softwrap: each buffer line maps to one visual
  row.
- [x] Add horizontal canvas page offset and viewport scrolling.
- [x] Update the ruler to start from the current canvas page offset.
- [x] Make printable input pad to virtual columns and replace at the target
  visual column.
- [x] Make Backspace and Delete clear cells without shifting fixed-position
  layout.
- [x] Make paste write fixed-position text without paragraph reflow.
- [x] Disable or reject implicit justification in Canvas Mode.
- [x] Add Canvas Mode tests for cursor movement, write/clear behavior,
  horizontal scrolling, ruler offset, and CJK alignment.

### Phase 4: Canvas Mode Keyboard Drawing

- [ ] Implement `Shift+Arrow` box-line drawing in Canvas Mode.
- [ ] Implement `Ctrl+Arrow` arrow-line drawing in Canvas Mode.
- [ ] Draw from the current canvas cursor position and move the cursor to the
  endpoint.
- [ ] Use the current/default border style shared with LOGO `BOX`, `DRAWBOX`,
  line, and table drawing commands.
- [ ] Fuse same-style corners, crossings, and T-junctions for box-line drawing.
- [ ] Preserve arrowheads at `Ctrl+Arrow` endpoints while fusing the traversed
  line segment with existing compatible lines.
- [ ] Treat mixed-style junction fusion as best effort.
- [ ] Do not overwrite existing non-line text unless a future explicit
  overwrite policy is added.
- [ ] Disable keyboard drawing while Table Mode is active.
- [ ] Add a dedicated Canvas Mode help bar set.
- [ ] Render Canvas Mode help as two explicit rows:
  row 1 shows save/exit/mode/move/drawing shortcuts; row 2 shows
  replace/clear/new-line/table/command shortcuts.
- [ ] Keep prompt, menu, and Table Mode help bars higher priority than Canvas
  Mode help.
- [ ] Add undo grouping for keyboard drawing gestures.
- [ ] Add tests for `Shift+Arrow` box lines, `Ctrl+Arrow` arrows, active border
  style, CJK/display-column alignment, table-mode conflicts, Canvas help bar
  content/priority, and undo behavior.

### Phase 5: Table Mode Integration

- [ ] Keep Table Mode as an overlay and record the active base mode on entry.
- [ ] Return to the remembered base mode when Table Mode exits.
- [ ] Keep active cell highlighting above the table cell only, without coloring
  borders.
- [ ] Make Table Mode justification operate only within the active cell width.
- [ ] Reject cell justification when the result cannot fit without changing
  table geometry.
- [ ] Keep blocking geometry-changing commands in Table Mode.
- [ ] Add tests for Text + Table, Canvas + Table, cell-width justification, and
  command blocking.

### Phase 6: Undo And Polish

- [ ] Group Canvas write gestures into coherent undo snapshots.
- [ ] Group Canvas keyboard drawing gestures into coherent undo snapshots.
- [ ] Group Table Mode edits into coherent undo snapshots.
- [ ] Preserve mode state through prompt open/close flows.
- [ ] Verify help bar, status/prompt line, and menu rendering at narrow terminal
  widths.
- [ ] Add regression tests for prompt interactions, transient status messages,
  and mode indicator visibility.

Risk areas:

- Low risk: ASCII, Unicode box drawing, CJK coordinate movement, padding, and
  cursor rendering.
- Medium risk: emoji, combining marks, tabs, and snapping when the cursor lands
  inside a multi-column character.
- Medium-high risk: Canvas Mode backspace, delete, and paste behavior because
  they must preserve fixed-position layout.
- Higher risk but deferrable: mixed-style keyboard drawing junction fusion and
  full Table Mode plus Canvas Mode interaction.

## Test Checklist

- Text Editing Mode inserts text and soft-wraps long lines.
- Canvas Mode replaces characters without shifting the rest of the line.
- Canvas Mode can write at a column beyond the current line end by padding with
  spaces.
- The ruler reflects the horizontal canvas page after scrolling.
- `M+V` switches between Text Editing Mode and Canvas Mode.
- Menu Bar can switch between Text Editing Mode and Canvas Mode.
- `M+T` enters Table Mode from both base modes and returns to the remembered
  mode on exit.
- Menu Bar can toggle Table Mode and shows checked state when active.
- The status/prompt line above the help bar displays active `CANVAS` and
  `TABLE` indicators.
- Table Mode blocks geometry-changing LOGO commands.
- Table Mode prevents CJK text from overflowing cell bounds.
- `^J` reflows only the current paragraph or active selection in Text Editing
  Mode.
- `^J` in Table Mode uses the active cell width and does not rewrite borders.
- `^J` in Canvas Mode leaves fixed-position content unchanged.
- Canvas Mode `Shift+Arrow` draws horizontal and vertical box lines.
- Canvas Mode `Ctrl+Arrow` draws horizontal and vertical arrow lines.
- Canvas Mode keyboard drawing uses the current border style for new drawing
  steps.
- Canvas Mode keyboard drawing fuses corners, crossings, and T-junctions.
- Canvas Mode shows a dedicated two-row help bar set that documents
  fixed-position editing plus `Shift+Arrow` and `Ctrl+Arrow` drawing gestures.
- Prompt, menu, and Table Mode help bars take priority over Canvas help.
