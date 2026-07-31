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
- Do not create duplicate implementations of existing editor commands.

## Architecture Rules

Command bar commands are adapters, not a second editor implementation.

A command bar command may:

- Parse command bar text.
- Validate arguments.
- Convert shorthand arguments into editor-domain arguments.
- Dispatch an existing `CommandID` through the existing `CommandRegistry`.
- Call a shared `Editor` domain method when the action requires arguments.

A command bar command must not:

- Directly mutate `buffers`, `currentBufferIndex`, cursor indexes, or buffer
  text when an existing command or domain method owns that behavior.
- Reimplement save, open, close, buffer switching, goto, or editing semantics.
- Produce behavior that differs from the matching key-bound or menu command.
- Create a parallel undo, status-message, prompt, or dirty-flag policy.

The intended flow is:

```text
CommandBarCommand
  parse and validate command bar input
  -> CommandRegistry.dispatch(CommandID) for existing no-argument commands
  -> shared Editor domain method for argument-bearing commands

Existing key/menu Command
  -> same shared Editor domain method

LOGO delegate action
  -> same shared Editor domain method
```

This keeps behavior centralized. The command bar layer decides what the user
meant; the editor layer still owns what the action does.

## Command Bar Registry

The command bar dispatcher should be a registry of small matcher commands, not
a single large switch statement.

Suggested types:

```swift
enum CommandBarDispatchResult {
    case handled
    case noMatch
}

protocol CommandBarCommand {
    var name: String { get }
    var help: String { get }

    func match(_ input: CommandBarInput) -> Bool
    func execute(_ input: CommandBarInput, editor: Editor) -> CommandBarDispatchResult
}

struct CommandBarInput {
    let raw: String
    let text: String
    let tokens: [String]
    let firstToken: String?
    let rest: String
}

final class CommandBarRegistry {
    private var commands: [CommandBarCommand] = []

    func register(_ command: CommandBarCommand) {
        commands.append(command)
    }

    func dispatch(_ rawInput: String, editor: Editor) -> CommandBarDispatchResult {
        let input = CommandBarInput(rawInput)
        guard !input.text.isEmpty else { return .handled }

        for command in commands where command.match(input) {
            return command.execute(input, editor: editor)
        }

        return .noMatch
    }
}
```

Registration order defines precedence. For example, exact editor shorthand
commands should be registered before numeric goto, and LOGO should remain the
fallback outside this registry.

## Reuse Patterns

### Existing No-Argument Commands

When a command bar shorthand maps to an existing no-argument editor command,
use `CommandRegistry`.

```swift
struct CommandIDCommandBarCommand: CommandBarCommand {
    let names: Set<String>
    let commandID: CommandID

    func match(_ input: CommandBarInput) -> Bool {
        guard input.rest.isEmpty, let first = input.firstToken else { return false }
        return names.contains(first.lowercased())
    }

    func execute(_ input: CommandBarInput, editor: Editor) -> CommandBarDispatchResult {
        _ = editor.commandRegistry.dispatch(id: commandID, editor: editor)
        return .handled
    }
}
```

Examples:

- `save` -> `CommandID.fileSave`
- `new` -> `CommandID.bufferNew`
- `buffer next` -> `CommandID.bufferNext`
- `buffer prev` -> `CommandID.bufferPrev`

### Argument-Bearing Commands

When a shorthand carries arguments, the command bar command should only parse
and validate those arguments. The behavior should live in a shared editor-domain
method.

```swift
extension Editor {
    func openBuffer(path: String) {
        openNewBuffer(filePath: path)
    }

    func writeBuffer(path: String) {
        doSave(to: path)
    }

    func switchToBuffer(oneBasedIndex: Int) {
        guard oneBasedIndex > 0, oneBasedIndex <= buffers.count else {
            setStatusMessage(L10n["status.no_such_buffer"])
            return
        }
        currentBufferIndex = oneBasedIndex - 1
    }
}
```

Then command bar and LOGO delegate code should call the same methods instead of
editing buffer state independently.

### Pure Shorthand

Some command bar forms do not correspond to an existing `CommandID`. Numeric
goto is the main example.

Even then, the command bar command should call a shared editor method:

```swift
extension Editor {
    func goToLocation(line oneBasedLine: Int, column oneBasedColumn: Int? = nil) {
        // Owns range checks, cursor updates, canvas/text column handling, and status messages.
    }
}
```

The numeric command bar command, the goto prompt, and LOGO `GOTOLINE` /
`GOTOCOL` should all reuse this method.

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

LOGO should remain the programmable layer. It should keep value reporters and
buffer-content macro operations, but interactive editor/file/multi-buffer
actions belong to the command prompt layer.

Keep these as LOGO primitives:

- `BUFFERS` / `BUFFERLIST`
- `BUFFER`
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

Move these out of LOGO and handle them only as command prompt shorthand or
key/menu editor commands:

- `OPENBUFFER` / `EDIT`
- `SAVE`
- `FILE`
- `CLOSEBUFFER`
- `NEXTBUFFER`
- `PREVBUFFER`
- `SETBUFFER`

These actions are editor/session operations, not document-transforming LOGO
programs. Keeping them out of LOGO prevents macros from depending on prompt
state, file-system prompts, or tab-management side effects.

## Ambiguous Buffer Primitives

Some command prompt inputs use words that are also natural LOGO reporters. The
dispatcher resolves this with explicit command prompt matching before LOGO
fallback.

### `BUFFER`

LOGO behavior:

- `BUFFER` returns the current 1-based buffer index.

Command prompt behavior:

- `buffer` reports the current buffer position in the status bar.
- `buffer 2` switches to buffer 2.
- `buffer next` and `buffer prev` switch between open buffers.

Uppercase `BUFFER` falls through to LOGO so reporter use remains available.
`BUFFER 2` does not switch buffers because LOGO `BUFFER` is a reporter only.

### `SAVE`, `FILE`, `OPEN`, and `EDIT`

Saving, closing, and opening buffers are command prompt/editor operations. They
should call shared `Editor` domain methods, not LOGO delegate actions.

## Case Rules

The shorthand parser is case-insensitive for editor commands that are not LOGO
reporters:

- `save`
- `SAVE`
- `Save`

For `BUFFER`, all-uppercase input remains LOGO reporter syntax. Lowercase and
mixed-case `buffer` input is command prompt shorthand.

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
- LOGO `BUFFER` reports the active buffer index.
- LOGO `BUFFER 2` does not switch buffers.
- `SAVE`, `FILE`, `OPENBUFFER`, `EDIT`, `NEXTBUFFER`, `PREVBUFFER`,
  `CLOSEBUFFER`, and `SETBUFFER` are not LOGO primitives.
- Existing LOGO `GETLINE` and `SETLINE` continue to work.
- `.zagorc` `logo-prelude` and `logo-script` continue to execute through LOGO.
- Key/menu commands, LOGO delegate actions, and command bar shorthand produce
  the same editor state for shared operations.

## Migration Strategy

1. Extract shared `Editor` domain methods for open, write, buffer switching,
   and goto behavior where direct mutations currently exist.
2. Update existing key/menu commands and LOGO delegate actions to call those
   shared domain methods.
3. Add a `CommandBarRegistry` in the editor layer.
4. Implement command bar commands as parse/validate adapters only.
5. Route LOGO prompt completion through the command bar registry.
6. Implement numeric goto shorthand.
7. Implement buffer and file shorthand commands.
8. Keep LOGO as the fallback path.
9. Update `docs/logo.md`, `docs/editor.md`, and `docs/configuration.md` after
   behavior is implemented.

## Final Rule

Use the editor command layer for interactive convenience. Use LOGO for
programmable composition.
