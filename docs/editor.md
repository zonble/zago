# `zago` Editor Basics

`zago` is modeless: ordinary typing inserts text, and editor actions are available through control keys, function keys, the menu bar, and the command prompt.

## Common Keys

| Key | Action |
| :--- | :--- |
| `Esc` | Open command prompt |
| `^O` / `^S` | Save |
| `^X` | Exit buffer/editor |
| `^W` | Search |
| `M+W` | Copy selected text or canvas block |
| `^K` | Cut selected text, or cut current line |
| `^U` | Paste last cut text |
| `^J` | Justify paragraph |
| `^Z` | Undo |
| `^G` | Cancel active selection or canvas mark |
| `F1` | Open menu bar |
| `M+O` | Open Markdown, Org, reStructuredText, or AsciiDoc document link at cursor |
| `M+V` | Toggle canvas mode |
| `M+T` | Toggle table mode |

## Command Prompt Shorthand

The `Esc` command prompt first tries editor command shorthand. If no shorthand
matches, the input is evaluated as LOGO.

| Input | Action |
| :--- | :--- |
| `42` | Go to line 42 |
| `42:7` / `42,7` | Go to line 42, column 7 |
| `save` | Save the current buffer |
| `save-exit` / `saveexit` / `file` / `wq` | Save the current buffer, then close it |
| `write path` | Save the current buffer to `path` |
| `open path` / `edit path` | Open `path` in a new buffer |
| `new` | Open a new empty buffer |
| `close` / `exit` / `quit` | Close the current buffer using normal editor close rules |
| `buffer` | Show the active buffer position |
| `buffer next` | Switch to the next buffer |
| `buffer prev` / `buffer previous` | Switch to the previous buffer |
| `buffer N` | Switch to 1-based buffer index `N` |
| `set ` + `Tab` | Show available editor settings |
| command prefix + `Tab` | Complete command bar commands and LOGO keywords |

Expressions and LOGO programs still fall through to LOGO. For example, `1 + 1`
evaluates as a LOGO expression. File and multi-buffer actions such as `save`,
`open`, and `buffer 2` are command prompt shorthand, not LOGO primitives.
