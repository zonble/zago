# `zago` Configuration

`zago` reads configuration from two locations:

1. `~/.zagorc` for user-wide defaults.
2. `./.zagorc` for directory-local settings.

Local settings are loaded after global settings, so a project can override the user's defaults.

The format is intentionally line-oriented and Nano-like. It supports editor settings, key bindings, Editor LOGO command bindings, and startup Editor LOGO code.

## Generating a Config File

`zago` can generate a commented starter `.zagorc` file:

```bash
zago --init
```

The default target is `~/.zagorc`. These aliases are equivalent:
```bash
zago --init-config
zago --generate-config
```

You can also specify a path:

```bash
zago --init ./.zagorc
zago --generate-config /tmp/example.zagorc
```

If the destination file already exists, `zago` leaves it unchanged and prints a notice.

---

## Configuration Directives

- `set <option> <value>` / `unset <option>`: configure editor options.
- `bind <key> <action>`: bind a key sequence to an editor action or LOGO command.
- `unbind <key>`: remove a key binding.
- `logo-prelude ... endlogo`: evaluate startup LOGO code.
- `logo-script <name> ... endlogo`: define a named LOGO script block for key bindings.
- `include <path-glob>`: load Nano syntax definition files.

---

## Editor Options

```nanorc
set tabsize 4
set tabstospaces
unset tabstospaces
set wrap 80
unset wrap
set canvas-mode on
set canvas-mode off
set trim-trailing-whitespace on
set trim-trailing-whitespace off
set lang zh_TW
set syntax true
set mouse true
set backup true
set backupdir ~/.zagorc-backups
```

Options configured in `.zagorc` apply when the editor starts.

`canvas-mode` in `.zagorc` is a startup default for newly created buffers or
editor views. Text/Canvas/Table mode state is runtime state owned by each
buffer, so reloading configuration does not force already-open buffers to switch
back to the configured startup mode.

`trim-trailing-whitespace` is off by default. When enabled, saving removes
trailing spaces and tabs from each line before writing the file.

---

## Key Bindings

`zago` supports key bindings using Nano-style key names:

- Control keys: `^O`, `^W`, `^R`, `^K`, `^U`, `^J`
- Alt keys: `alt-w`, `alt-r`, `alt-j`, `alt-k`, `M-W`, `M-R`
- Function keys: `F1` through `F12`
- Special keys: `Esc`, `Tab`, `Enter`, `Backspace`, `Delete`, `Up`, `Down`, `Left`, `Right`

Key bindings can invoke editor commands or LOGO code:

```nanorc
# Bind Alt+W to justify paragraph
bind alt-w edit.justify

# Bind Alt+H to inline Editor LOGO code
bind alt-h logo: MOVE HOME TYPE "# " MOVE END
```

Editor commands can be specified by ID:

```nanorc
bind alt-b edit.box
```

Or by macro shorthand string:

```nanorc
bind alt-b macro: BOX 30 4 ROUND
```

## Editor LOGO Startup Code

Each editor instance owns one persistent Editor LOGO engine. Startup code loaded from `.zagorc` is evaluated into that engine, and later command-prompt input and key-bound scripts share its variables and procedures.

Use `logo-prelude` for startup variables and procedures:

```nanorc
logo-prelude
MAKE "boxWidth 30

TO FILLBOX :text
  BOX :boxWidth 4 ROUND
  MOVE LEFT (:boxWidth - 1) MOVE UP 2
  FILL :text
END
endlogo
```

Use `logo-script` for named scripts that can be bound to keys:

```nanorc
logo-script insert-title
BOX 40 3 ROUND
MOVE LEFT 38 MOVE UP 1
FILL "Title
endlogo

bind alt-t logo:insert-title
```

`logo-script` is a `.zagorc` container, not a second function syntax. Reusable LOGO logic should still be written with `TO ... END`.

## Shortcut Naming Convention

All shortcut representations across the editor, menu bar, help displays, and documentation follow a strict naming convention:
- **Control keys**: Use `^<key>` format (e.g., `^Q`, `^N`, `^W`, `^BS`).
- **Alt / Meta keys**: Use `M+<key>` format (e.g., `M+T`, `M+S`, `M+M`, `M+.`, `M+,`).

## Command IDs

| Command ID | Description | Default Keys |
| :--- | :--- | :--- |
| `move.left` | Move cursor left | `^B`, `Left Arrow` |
| `move.right` | Move cursor right | `^F`, `Right Arrow` |
| `move.up` | Move cursor up | `^P`, `Up Arrow` |
| `move.down` | Move cursor down | `^N`, `Down Arrow` |
| `move.home` | Move to line start | `^A`, `Home` |
| `move.end` | Move to line end | `^E`, `End` |
| `move.pgdn` | Page down | `^V`, `F8`, `PageDown` |
| `move.pgup` | Page up | `^Y`, `F7`, `PageUp` |
| `select.left` | Extend selection left | `Shift+Left` |
| `select.right` | Extend selection right | `Shift+Right` |
| `select.up` | Extend selection up | `Shift+Up` |
| `select.down` | Extend selection down | `Shift+Down` |
| `select.home` | Extend selection to line start | `Shift+Home` |
| `select.end` | Extend selection to line end | `Shift+End` |
| `edit.delete` | Delete character | `^D`, `Delete` |
| `edit.mark` | Set or unset canvas block mark | `^^` in canvas mode |
| `edit.cancel_selection` | Cancel active selection or canvas mark | `^G` |
| `edit.copy` | Copy selected text or canvas block | `M+W` |
| `edit.cut` | Cut selected text, or current line when no selection exists | `^K`, `F9` |
| `edit.uncut` | Paste last cut text | `^U`, `F10` |
| `edit.justify` | Justify paragraph | `^J` |
| `edit.undo` | Undo edit | `^Z` |
| `edit.spell` | Interactive spell checker | `^T`, `F12` |
| `edit.eval_logo` | Evaluate LOGO at current line, selection, or code block | `^Q` |
| `search.whereis` | Search text | `^W`, `F6` |
| `search.next` | Find next active search match | `M+N` |
| `search.previous` | Find previous active search match | `M+P` |
| `document.open_link` | Open Markdown, Org, reStructuredText, or AsciiDoc document link at cursor | `M+O` |
| `document.heading_next` | Jump to next document heading | `M+]` |
| `document.heading_previous` | Jump to previous document heading | `M+[` |
| `document.outline` | Open current document outline picker | `M+\` |
| `cursor.goto_line` | Go to line or line,column | `^/`, `^_`, `M+G` |
| `cursor.position` | Show cursor position | `^C`, `F11` |
| `file.save` | Save file | `^O`, `^S`, `F3` |
| `file.insert` | Insert external file | `^R`, `F5` |
| `file.exit` | Exit buffer/editor | `^X`, `F2` |
| `file.save_exit` | Save and exit | `F4` |
| `buffer.next` | Next buffer | `M+.`, `M+>` |
| `buffer.prev` | Previous buffer | `M+,`, `M+<` |
| `buffer.new` | New buffer | `^N` |
| `macro.logo` | Open command prompt | `Esc`, `M+:` |
| `logo.reference` | Show LOGO reference | Menu |
| `logo.workspace` | Show LOGO procedures and variables | Menu |
| `menu.show` | Toggle menu bar | `F1`, `^M`, `M+M` |
| `help.show` | Full-screen help | Menu |
| `mode.text` | Switch to text editing mode | Menu |
| `mode.canvas.toggle` | Toggle canvas mode | `M+V` |
| `mode.frame.toggle` | Toggle frame mode | Menu |
| `table.toggle` | Toggle table mode | `M+T` |
| `border.style` | Cycle border style | `M+S` |

## Command Prompt Shorthand

The `macro.logo` prompt first dispatches editor shorthand, then numeric goto,
then LOGO. Command bar shorthand is not represented as `CommandID` values
because it is parsed text with optional arguments.

Examples:

| Input | Action |
| :--- | :--- |
| `save` | Dispatches `file.save` |
| `new` | Dispatches `buffer.new` |
| `close` | Dispatches `file.exit` |
| `write path` | Saves to `path` |
| `open path` / `edit path` | Opens `path` in a new buffer |
| `buffer next` | Dispatches `buffer.next` |
| `buffer prev` / `buffer previous` | Dispatches `buffer.prev` |
| `buffer N` | Switches to 1-based buffer index `N` |
| `42` | Goes to line 42 |
| `42:7` / `42,7` | Goes to line 42, column 7 |

## Nano Syntax Files

`zago` can load GNU Nano `.nanorc` syntax definitions from common locations:

1. `~/.nanorc`
2. `/opt/homebrew/share/nano/*.nanorc`
3. `/usr/local/share/nano/*.nanorc`
4. `/usr/share/nano/*.nanorc`
5. `/etc/nanorc`

Supported directives:

- `syntax "name" "regex_pattern"`
- `color color_name "regex_pattern"`
- `icolor color_name "regex_pattern"`
- `include "/path/to/*.nanorc"`

## Embedded Code Blocks

Built-in markup syntaxes can detect one embedded code language inside document code blocks:

- Markdown fenced code blocks, such as ```` ```swift ```` or `~~~logo`
- Org-mode source blocks, such as `#+BEGIN_SRC logo`
- reStructuredText code directives, such as `.. code-block:: c`
- AsciiDoc source blocks, such as `[source,swift]` followed by `----`

Embedded syntax detection is intentionally single-level. `zago` detects the outer file syntax, asks that syntax whether the current line is inside an embedded code block, and then highlights the line using the detected embedded language. It does not recursively inspect the embedded language for another embedded language.

For example, a Markdown file containing an Org source block can be highlighted as Org while the cursor is inside that block, but `zago` will not then inspect that Org block for a nested Markdown or Swift block. This keeps syntax highlighting predictable and cheap in interactive editing.
