# `zago` Configuration

`zago` reads configuration from two locations:

1. `~/.zagorc` for user-wide defaults.
2. `./.zagorc` for directory-local settings.

Local settings are loaded after global settings, so a project can override the user's defaults.

The format is intentionally line-oriented and Nano-like. It supports editor settings, key bindings, LOGO command bindings, and startup LOGO code.

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

To write the template somewhere else, pass the target path as the positional argument:

```bash
zago --init ./.zagorc
zago --generate-config /tmp/example.zagorc
```

The command writes the template file and exits without opening the editor.

## Settings

| Directive | Description | Example |
| :--- | :--- | :--- |
| `set wrap [col]` | Enables softwrap at the terminal boundary or a fixed column width | `set wrap 80` |
| `unset wrap` | Disables softwrap | `unset wrap` |
| `set ruler` | Shows the classic WordStar-style ruler bar | `set ruler` |
| `unset ruler` | Hides the ruler bar | `unset ruler` |
| `set linenumbers [on|off]` | Shows or hides the line number gutter | `set linenumbers off` |
| `unset linenumbers` | Hides the line number gutter for easier terminal copy/paste | `unset linenumbers` |
| `set syntax [on|off]` | Enables or disables syntax highlighting | `set syntax off` |
| `set autoreload` | Enables file auto-reload for external changes | `set autoreload` |
| `unset autoreload` | Disables file auto-reload | `unset autoreload` |
| `set lang [zh_TW|en]` | Sets the UI language explicitly | `set lang zh_TW` |

## Key Bindings

Use `bind` to map a key to a command id:

```nanorc
bind ctrl-s file.save
bind f1 help.show
```

Use `unbind` to remove a default binding:

```nanorc
unbind f1
```

LOGO commands can be bound inline:

```nanorc
bind alt-h logo: MOVE HOME TYPE "# " MOVE END
```

The older `macro:` prefix is still accepted as an alias:

```nanorc
bind alt-b macro: BOX 30 4 ROUND
```

## LOGO Startup Code

Each editor instance owns one persistent LOGO engine. Startup code loaded from `.zagorc` is evaluated into that engine, and later command-prompt input and key-bound scripts share its variables and procedures.

Use `logo-prelude` for startup variables and procedures:

```nanorc
logo-prelude
MAKE "boxWidth 30

TO FILLBOX :text
  BOX :boxWidth 4 ROUND
  GOTO 2 2
  FILL :text
END
endlogo
```

Use `logo-script` for named scripts that can be bound to keys:

```nanorc
logo-script insert-title
BOX 40 3 ROUND
GOTO 2 2
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
| `edit.delete` | Delete character | `^D`, `Delete` |
| `edit.mark` | Set or unset selection mark | `^^` |
| `edit.cut` | Cut selected text, or current line when no selection exists | `^K`, `F9` |
| `edit.uncut` | Paste last cut text | `^U`, `F10` |
| `edit.justify` | Justify paragraph | `^J` |
| `edit.undo` | Undo edit | `^Z` |
| `edit.spell` | Interactive spell checker | `^T`, `F12` |
| `edit.eval_logo` | Evaluate LOGO at current line, selection, or code block | `^Q` |
| `search.whereis` | Search text | `^W`, `F6` |
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
| `help.show` | Full-screen help | `^G` |
| `mode.text` | Switch to text editing mode | Menu |
| `mode.canvas.toggle` | Toggle canvas mode | `M+V` |
| `mode.frame.toggle` | Toggle frame mode | Menu |
| `table.toggle` | Toggle table mode | `M+T` |
| `border.style` | Cycle border style | `M+S` |

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
