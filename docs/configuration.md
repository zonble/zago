# `se` Configuration

`se` reads configuration from two locations:

1. `~/.serc` for user-wide defaults.
2. `./.serc` for directory-local settings.

Local settings are loaded after global settings, so a project can override the user's defaults.

The format is intentionally line-oriented and Nano-like. It supports editor settings, key bindings, LOGO command bindings, and startup LOGO code.

## Generating a Config File

`se` can generate a commented starter `.serc` file:

```bash
se --init
```

The default target is `~/.serc`. These aliases are equivalent:

```bash
se --init-config
se --generate-config
```

To write the template somewhere else, pass the target path as the positional argument:

```bash
se --init ./.serc
se --generate-config /tmp/example.serc
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

Each editor instance owns one persistent LOGO engine. Startup code loaded from `.serc` is evaluated into that engine, and later command-prompt input and key-bound scripts share its variables and procedures.

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

`logo-script` is a `.serc` container, not a second function syntax. Reusable LOGO logic should still be written with `TO ... END`.

## Command IDs

| Command ID | Description | Default Keys |
| :--- | :--- | :--- |
| `move.left` | Move cursor left | `Ctrl+B`, `Left Arrow` |
| `move.right` | Move cursor right | `Ctrl+F`, `Right Arrow` |
| `move.up` | Move cursor up | `Ctrl+P`, `Up Arrow` |
| `move.down` | Move cursor down | `Ctrl+N`, `Down Arrow` |
| `move.home` | Move to line start | `Ctrl+A`, `Home` |
| `move.end` | Move to line end | `Ctrl+E`, `End` |
| `move.pgdn` | Page down | `Ctrl+V`, `F8`, `PageDown` |
| `move.pgup` | Page up | `Ctrl+Y`, `F7`, `PageUp` |
| `edit.delete` | Delete character | `Ctrl+D`, `Delete` |
| `edit.mark` | Set or unset selection mark | `Ctrl+^` |
| `edit.cut` | Cut selected text, or current line when no selection exists | `Ctrl+K`, `F9` |
| `edit.uncut` | Paste last cut text | `Ctrl+U`, `F10` |
| `edit.justify` | Justify paragraph | `Ctrl+J` |
| `edit.undo` | Undo edit | `Ctrl+Z` |
| `edit.spell` | Interactive spell checker | `Ctrl+T`, `F12` |
| `edit.eval_logo` | Evaluate LOGO at current line, selection, or code block | `Ctrl+Q` |
| `search.whereis` | Search text | `Ctrl+W`, `F6` |
| `cursor.goto_line` | Go to line or line,column | `Ctrl+/`, `Ctrl+_`, `Alt+G` |
| `cursor.position` | Show cursor position | `Ctrl+C`, `F11` |
| `file.save` | Save file | `Ctrl+O`, `Ctrl+S`, `F3` |
| `file.insert` | Insert external file | `Ctrl+R`, `F5` |
| `file.exit` | Exit buffer/editor | `Ctrl+X`, `F2` |
| `file.save_exit` | Save and exit | `F4` |
| `buffer.next` | Next buffer | `Alt+.`, `Alt+>` |
| `buffer.prev` | Previous buffer | `Alt+,`, `Alt+<` |
| `buffer.new` | New buffer | `Ctrl+N` |
| `macro.logo` | Open command prompt | `Esc`, `Alt+L`, `Alt+:`, `F8` |
| `menu.show` | Toggle menu bar | `F1`, `Ctrl+M`, `Alt+M` |
| `help.show` | Full-screen help | `Ctrl+G` |
| `table.toggle` | Toggle table mode | `Alt+T` |
| `table.style` | Cycle table style | `Alt+S` |

## Nano Syntax Files

`se` can load GNU Nano `.nanorc` syntax definitions from common locations:

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
