# Command Bar Dispatch Plan

This document defines the planned split between the interactive editor command
bar and the LOGO command language.

## Goal

The command bar should feel like an editor command line for common interactive
tasks, while LOGO should remain the programmable macro language.

Today, the command bar sends non-empty input directly to the LOGO engine. That
keeps the implementation simple, but it makes some editor actions awkward:

- Typing `42` should normally jump to line 42, not evaluate a numeric literal.
- `1 + 1` should still evaluate as a LOGO expression.
- Buffer actions such as `save`, `open foo.txt`, or `buffer next` should not
  require users to think in LOGO syntax.
- Existing LOGO primitives must remain available for scripts, procedures,
  startup configuration, and custom key bindings.

## Non-Goals

- Do not remove existing LOGO buffer primitives.
- Do not break `.zagorc` `logo-prelude` or `logo-script` behavior.
- Do not make the command bar a second general-purpose scripting language.
- Do not make shorthand parsing clever enough to conflict with normal LOGO
  programs.

## Dispatch Order

The command bar should dispatch input in this order:

1. Editor command shorthand
2. Numeric goto shorthand
3. LOGO script or expression

This keeps common editor commands direct while preserving LOGO as the fallback
language.

## Editor Command Shorthand

Editor shorthand is for interactive editor operations. These commands should be
handled before LOGO and should not enter the LOGO engine.

Initial command set:

| Input | Behavior |
| :--- | :--- |
| `save` | Save the current buffer using the current file path, or prompt for a path |
| `write path` | Save the current buffer to `path` |
| `open path` | Open `path` in a new buffer |
| `edit path` | Alias for `open path` in the command bar |
| `buffer` | Show the active buffer index or buffer list status |
| `buffer next` | Switch to the next buffer |
| `buffer prev` | Switch to the previous buffer |
| `buffer previous` | Switch to the previous buffer |
| `buffer N` | Switch to 1-based buffer index `N` |
| `new` | Open a new empty buffer |
| `close` | Close the current buffer using editor close rules |

These lowercase forms are command bar conveniences. The uppercase LOGO
primitives remain valid LOGO code.

## Numeric Goto Shorthand

Numeric shorthand is for navigation and should be parsed conservatively.

| Input | Behavior |
| :--- | :--- |
| `42` | Go to line 42 |
| `42:7` | Go to line 42, column 7 |
| `42,7` | Go to line 42, column 7 |

Only positive integer forms should match this shorthand. Invalid line or column
values should report an editor-level range error instead of falling through to
LOGO.

Examples that must not be treated as numeric goto:

| Input | Reason |
| :--- | :--- |
| `1 + 1` | LOGO expression |
| `SUM 1 1` | LOGO expression |
| `:x + 1` | LOGO expression |
| `-1` | Invalid editor goto input |
| `0` | Invalid editor goto input |

## LOGO Responsibilities

LOGO should remain the programmable layer. The existing buffer primitives should
stay in LOGO because they are useful inside procedures, control flow, startup
configuration, and custom key bindings.

Keep these as LOGO primitives:

- `BUFFERS` / `BUFFERLIST`
- `BUFFER` / `SETBUFFER`
- `NEXTBUFFER`
- `PREVBUFFER`
- `OPENBUFFER` / `EDIT`
- `SAVE`
- `FILE`
- `CLOSEBUFFER`
- `CLEARBUFFER` / `ERASEBUFFER`
- `GETLINE`
- `SETLINE`
- `GOTOLINE` / `SETROW`
- `GOTOCOL` / `SETCOL`
- `ROW` / `LINE.NO`
- `COL` / `COL.NO`
- `LINECOUNT` / `LINES`
- `BUFFERTEXT`
- `SELECTION` / `SELECTEDTEXT`
- `MODIFIED?` / `CHANGED?`
- `FILENAME` / `BUFFERNAME`

These commands should keep their current uppercase LOGO spelling and current
macro behavior.

## Ambiguous Buffer Primitives

Some LOGO buffer primitives are also natural editor commands. They should stay
in LOGO for compatibility, but command bar shorthand should prefer the editor
layer.

### `BUFFER`

LOGO currently has mixed behavior:

- `BUFFER` returns the current 1-based buffer index.
- `BUFFER 2` switches to buffer 2 and returns the active index.

This is acceptable for LOGO compatibility, but the command bar should treat
`buffer 2` as an editor command shorthand.

### `SAVE` and `FILE`

`SAVE "path"` and `FILE "path"` are scriptable and should stay in LOGO.

Bare `SAVE` and `FILE` may invoke editor-specific behavior such as prompting
for a path when the buffer has no file path. That behavior is useful in the
interactive command bar, but it is less clean inside LOGO procedures.

For compatibility, keep bare `SAVE` and `FILE` in LOGO for now. Document them
as editor-dependent operations. New command bar shorthand should call editor
commands directly.

## Case Rules

The initial shorthand parser should be case-insensitive for editor commands:

- `save`
- `SAVE`
- `Save`

However, dispatch precedence must avoid breaking existing LOGO workflows. If a
user enters a full LOGO program such as `SAVE "file.txt"` or `BUFFER 2`, it can
still be handled by LOGO if the shorthand parser does not explicitly claim it.

Recommended first implementation:

- Claim lowercase and mixed-case editor shorthand forms.
- Keep all-uppercase LOGO primitive forms available as LOGO.
- Revisit case handling only after tests cover real command bar use.

## Error Handling

Editor shorthand errors should use editor-style status messages:

- unknown shorthand arguments
- missing required path
- invalid numeric goto
- buffer index out of range

These errors should not be LOGO parser errors.

Inputs that are not recognized as editor shorthand or numeric goto should fall
through to LOGO and keep LOGO's current result and error behavior.

## Testing Plan

Add command bar dispatch tests for:

- `42` jumps to line 42.
- `42:7` and `42,7` jump to the expected line and column.
- `1 + 1` is evaluated by LOGO and reports `2`.
- `save` dispatches through editor save behavior.
- `write path` writes the active buffer to the requested path.
- `open path` opens a new buffer without requiring LOGO quoting.
- `buffer next`, `buffer prev`, and `buffer N` switch buffers.
- Existing LOGO `BUFFER`, `BUFFER 2`, `SAVE "path"`, `OPENBUFFER "path"`,
  `GETLINE`, and `SETLINE` continue to work.
- `.zagorc` `logo-prelude` and `logo-script` continue to execute through LOGO.

## Migration Strategy

1. Add a command bar dispatch function in the editor layer.
2. Route LOGO prompt completion through that dispatcher.
3. Implement numeric goto shorthand.
4. Implement buffer and file shorthand commands.
5. Keep LOGO as the fallback path.
6. Update `docs/logo.md`, `docs/editor.md`, and `docs/configuration.md` after
   behavior is implemented.

## Final Rule

Use the editor command layer for interactive convenience. Use LOGO for
programmable composition.

