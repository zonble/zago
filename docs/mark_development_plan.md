# Mark and Selection Development Plan

This plan tracks the implementation work for the mark, selection, and clipboard
model defined in [mark.md](mark.md).

## Target Behavior Summary

- Text edit mode uses normal linear selection with `Shift+Arrow`.
- Table mode uses the same linear selection model, limited to the current cell.
- Canvas mode uses PE2-style rectangular block mark with `^^` / `Ctrl+^`.
- Switching modes always clears the active selection or mark.
- Text/table share one text clipboard.
- Canvas mode uses a separate rectangular block clipboard.
- `^G` becomes Cancel Selection / Cancel Mark.
- Help moves off `^G`; `F1` opens the menu bar, and the Help menu remains the help entry point.

## Phase 1: State Model

- Replace the single shared `selectionMark` concept with mode-specific state:
  - text/table linear selection anchor
  - canvas block mark anchor
- Add a canvas block clipboard type that stores:
  - visual width
  - ordered rows
  - spaces inside the block
- Keep the existing text clipboard for text/table operations.
- Ensure mode transitions clear the active selection/mark regardless of source
  and destination mode.
- Ensure clipboard contents survive mode switches.

## Phase 2: Key Bindings and Help

- Remove `^^` / `Ctrl+^` as a text/table mark command.
- Keep `^^` / `Ctrl+^` only for canvas block mark.
- Add or verify `Shift+Left`, `Shift+Right`, `Shift+Up`, and `Shift+Down`
  dispatch paths for text/table linear selection.
- Redefine `^G` as Cancel Selection / Cancel Mark:
  - text mode: clear active selection, otherwise show no-selection status
  - table mode: clear active selection, otherwise show no-selection status
  - canvas mode: clear active block mark, otherwise show no-block status
- Keep Help available through the Help menu.
- Keep `F1` as the menu bar entry point.
- Update the bottom help bar:
  - remove `^G Help`
  - show `^G Cancel` or equivalent wording
- Update full-screen help and command descriptions:
  - text/table selection uses `Shift+Arrow`
  - canvas block mark uses `^^`
  - `^G` cancels selection/mark
  - the Help menu opens help
  - `F1` opens the menu bar
- Update configuration docs so the default command id for `^G` is no longer
  help.

## Phase 3: Text Edit Selection

- Implement linear selection creation and extension with `Shift+Arrow`.
- Selection must never extend past EOF.
- Selection rendering must handle:
  - single-line selections
  - multi-line selections
  - empty lines highlighted as full-width selected rows
  - selection ending at EOF
- Non-shift cursor movement clears selection.
- Typing with active selection replaces selected text.
- Editing commands that do not operate on selection clear selection.
- `^K` cuts selected linear text into the text clipboard.
- `^K` with no selection cuts the current line.
- `^U` pastes text clipboard content as normal text insertion.

## Phase 4: Table Mode Selection

- Reuse the text/table linear selection model.
- Limit selection to the current table cell.
- Prevent `Shift+Arrow` selection from crossing table cell boundaries.
- Preserve table borders and cell layout during selection cut/paste.
- `^K` with active selection cuts selected cell text into the text clipboard.
- `^K` with no selection follows existing table-mode line/cell cut rules.
- `^U` pastes text clipboard content using table-mode paste constraints.
- Ensure table mode never reads or writes the canvas block clipboard.

## Phase 5: Canvas Block Mark

- Implement canvas block mark with `^^` / `Ctrl+^`.
- Compute the active block as the normalized rectangle between anchor and
  cursor.
- Use visual-cell coordinates for all block operations.
- Snap block edges to whole character boundaries.
- Do not split CJK, emoji, combining sequences, or tabs.
- Render active block marks as rectangular highlighted regions, including
  empty cells and short-line padding.
- `^G` clears the active canvas block mark.
- `^K` with no active block mark reports no-block status and does not cut.

## Phase 6: Canvas Block Cut and Paste

- Implement `^K` with active block mark:
  - copy rectangular cells into canvas block clipboard
  - remove the marked width from each affected row
  - shift right-side content left by block width
  - trim trailing spaces from rewritten buffer rows
  - move cursor to block top-left
  - clear block mark
- Implement `^U` canvas block paste:
  - insert block at cursor top-left
  - push existing cells at and to the right of cursor right by block width
  - create missing target rows
  - preserve spaces inside the block
  - leave cursor at paste top-left
- Keep canvas block clipboard independent from text clipboard.

## Phase 7: LOGO FILL Integration

- In canvas mode, if a block mark is active, `FILL text` fills the marked
  block before using box/interior detection.
- Reject empty `FILL` arguments.
- Repeat fill text across each marked row and clip to block width.
- Use visual-cell width, not raw string indices.
- Do not split wide characters; if the remaining width cannot fit the next
  wide character, fill the remaining cell with a space.
- Support `FILL " "` as clear-block-without-shift.
- Leave cursor in place and clear block mark after successful fill.

## Phase 8: Tests

Add focused tests before each implementation step.

- Text mode:
  - `Shift+Arrow` creates selection
  - non-shift movement clears selection
  - typing replaces selection
  - `^K` cuts selection
  - `^K` with no selection cuts current line
  - empty selected line renders full-width highlight
  - selection cannot pass EOF
- Table mode:
  - selection is limited to current cell
  - `^K` selection cut preserves borders
  - paste respects cell constraints
  - mode does not use canvas clipboard
- Canvas mode:
  - `^^` sets block mark
  - reverse-direction block marks normalize correctly
  - `^G` clears block mark
  - `^K` without mark reports no-block
  - `^K` with mark cuts block and shifts right-side cells left
  - `^U` inserts block and shifts right-side cells right
  - cursor positions after `^K`, `^U`, and `FILL`
  - CJK/emoji block edges snap to whole characters
  - trailing spaces are trimmed after block cut
  - short lines and missing rows are handled
- Mode switching:
  - every mode switch clears active selection/mark
  - text clipboard survives mode switches
  - canvas block clipboard survives mode switches
  - text/table clipboard and canvas clipboard remain isolated
- Help and key bindings:
  - `^G` dispatches cancel, not help
  - the Help menu opens help
  - `F1` opens the menu bar
  - help text and help bar show the new bindings

## Phase 9: Documentation Updates

- Keep [mark.md](mark.md) synchronized with implementation behavior.
- Update [editor.md](editor.md) common key table.
- Update [configuration.md](configuration.md) command ids and default bindings.
- Update in-app localized help strings in English and Traditional Chinese.
- Update README if it still describes nano-like `^G` help or `^^` text mark.

## Suggested Implementation Order

1. Key model and command ids for cancel/help separation.
2. Text/table selection state and rendering.
3. Text/table cut, paste, and replacement behavior.
4. Canvas block mark rendering.
5. Canvas block clipboard, `^K`, and `^U`.
6. Canvas `FILL` mark integration.
7. Documentation and localization pass.
8. Full `swift test` verification.
