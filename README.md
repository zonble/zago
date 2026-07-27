# `se` - Swift TUI Text Editor

`se` is a lightweight, high-performance Terminal User Interface (TUI) text editor written in pure Swift 6. Designed with classic Pico/Nano-style keybindings, `se` provides modeless text editing, full UTF-8 / CJK multi-byte character support, dynamic softwrap, visual paragraph justification, syntax highlighting, GNU Nano `.nanorc` compatibility, and multi-platform support across macOS and Linux.

---

## Features & Purpose

- **Modeless Keybindings**: Intuitive Nano/Pico control shortcuts (`^O` Save, `^X` Exit, `^W` Search, `^K` Cut, `^U` Uncut/Paste, `^J` Justify, `^Z` Undo, `^T` Spell Check, `^G` Help).
- **Undo Capability (`^Z`)**: Revert edit operations up to 100 snapshot levels.
- **Interactive Spell Checker (`^T` / `F12`)**: System dictionary lookup with CJK filtering and interactive TUI word replacement.
- **Full-Screen Help Viewer (`^G` / `F1`)**: Dedicated full-page TUI command reference.
- **Shift-Selection**: Automatically start and adjust selection mark using `Shift + Arrow Keys` or `^^`.
- **Syntax Highlighting & GNU Nano `.nanorc` Compatibility**: Built-in 5-token ANSI color rules for **Swift**, **Python**, **C/C++**, **JSON**, **Markdown**, and **Shell** with native GNU Nano `.nanorc` configuration parsing (`~/.nanorc`, `/opt/homebrew/share/nano/*.nanorc`, `/usr/share/nano/*.nanorc`).
- **Internationalization (i18n)**: Dual English and Traditional Chinese (`zh_TW`) support with automatic POSIX locale detection (`$LC_ALL`, `$LANG`), `~/.serc` (`set lang zh_TW`), and CLI `--lang zh_TW`.
- **User Configuration File (`~/.serc`)**: Nano/Vim-style directives for `set wrap`, `set ruler`, `set syntax`, `set lang`, `bind <key> <cmd_id>`, and `unbind <key>`.
- **Classic WordStar Ruler (`-r` / `--ruler`)**: Retro `----!----1----!----2` ruler bar for precise character column alignment.
- **Function Keys Support**: Native mapping for function keys `F1` through `F12`.
- **CJK & Multi-byte UTF-8 Support**: Seamless Chinese, Japanese, Korean, and multi-byte UTF-8 character input with accurate `displayWidth` column alignment.
- **Dynamic Softwrap**: Automatic line wrapping at viewport boundary or configurable column width (`-w` / `--wrap`) without altering raw line buffer data.
- **Visual Reflow Engine**: Paragraph justification (`^J`) powered by a visual column display width algorithm for mixed CJK and Latin text.

---

## 🎨 Syntax Highlighting & GNU Nano Compatibility

`se` comes with built-in syntax rules and seamlessly reads GNU Nano `.nanorc` syntax definitions, allowing developers to reuse existing Nano syntax color themes without configuration.

### Built-in Languages

- **Swift** (`.swift`)
- **Python** (`.py`)
- **C / C++** (`.c`, `.cpp`, `.h`, `.hpp`)
- **JSON** (`.json`)
- **Markdown** (`.md`, `.markdown`)
- **Shell Scripts** (`.sh`, `.bash`, `.zsh`)

### GNU Nano `.nanorc` Compatibility

`se` automatically searches for and loads `.nanorc` syntax files from standard locations:

1. `~/.nanorc` (User home configuration)
2. `/opt/homebrew/share/nano/*.nanorc` (Homebrew macOS installation)
3. `/usr/local/share/nano/*.nanorc` (Local system installation)
4. `/usr/share/nano/*.nanorc` (Linux system installation)
5. `/etc/nanorc` (System global configuration)

#### Supported `.nanorc` Directives

- `syntax "name" "regex_pattern"`: Defines a language and matching filename extensions.
- `color color_name "regex_pattern"`: Maps regex patterns to ANSI terminal colors (`red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`, `brightblack`, `brightred`, etc.).
- `icolor color_name "regex_pattern"`: Case-insensitive color regex rule.
- `include "/path/to/*.nanorc"`: Glob inclusion for modular `.nanorc` rules.

---

## ⚙️ User Configuration File (`~/.serc` / `./.serc`)

`se` reads configuration settings from **`~/.serc`** (global settings) and **`./.serc`** (directory-specific local settings). Local configurations override global settings.

### Configuration Directives

| Directive | Description | Example |
| :--- | :--- | :--- |
| `set wrap [col]` | Enables softwrap at terminal boundary or specified column width | `set wrap 80` |
| `unset wrap` | Disables softwrap | `unset wrap` |
| `set ruler` | Enables classic WordStar-style ruler bar | `set ruler` |
| `unset ruler` | Hides WordStar ruler bar | `unset ruler` |
| `set syntax [on\|off]` | Enables or disables syntax highlighting engine | `set syntax off` |
| `set lang [zh_TW\|en]` | Sets UI language explicitly | `set lang zh_TW` |
| `bind <key> <command_id>` | Binds custom key to editor command | `bind ctrl-f move.right` |
| `unbind <key>` | Unbinds existing key | `unbind f1` |

### Sample `~/.serc` File

```nanorc
# Sample ~/.serc configuration for se editor

# Set default UI language to Traditional Chinese
set lang zh_TW

# Enable WordStar ruler bar
set ruler

# Set softwrap column to 80 characters
set wrap 80

# Enable syntax highlighting
set syntax on

# Custom keybindings
bind ctrl-s file.save
bind f1 help.show
```

### Available Command IDs for `bind`

| Command ID | Description | Default Keys |
| :--- | :--- | :--- |
| `move.left` | Move cursor left | `Ctrl+B`, `Left Arrow` |
| `move.right` | Move cursor right | `Ctrl+F`, `Right Arrow` |
| `move.up` | Move cursor up | `Ctrl+P`, `Up Arrow` |
| `move.down` | Move cursor down | `Ctrl+N`, `Down Arrow` |
| `move.home` | Move to line start | `Ctrl+A`, `Home` |
| `move.end` | Move to line end | `Ctrl+E`, `End` |
| `move.pgdn` | Page down | `Ctrl+V`, `F8`, `PgDn` |
| `move.pgup` | Page up | `Ctrl+Y`, `F7`, `PgUp` |
| `edit.delete` | Delete character | `Ctrl+D`, `Delete` |
| `edit.mark` | Set/unset selection mark | `Ctrl+^` |
| `edit.cut` | Cut text/line | `Ctrl+K`, `F9` |
| `edit.uncut` | Paste cut text | `Ctrl+U`, `F10` |
| `edit.justify` | Justify paragraph | `Ctrl+J`, `F4` |
| `edit.undo` | Undo edit | `Ctrl+Z` |
| `edit.spell` | Interactive spell checker | `Ctrl+T`, `F12` |
| `search.whereis` | Text search | `Ctrl+W`, `F6` |
| `file.save` | Save file (WriteOut) | `Ctrl+O`, `Ctrl+S`, `F3` |
| `file.insert` | Insert external file | `Ctrl+R`, `F5` |
| `file.exit` | Exit editor | `Ctrl+X`, `F2` |
| `help.show` | Full-screen help viewer | `Ctrl+G`, `F1` |

---

## System Requirements

- **Operating Systems**: macOS 14.0+ or Linux (Ubuntu, Debian, Fedora, Arch Linux).
- **Swift Toolchain**: Swift 6.0 or higher.
- **Terminal Emulator**: Any VT100 / ANSI-compatible terminal emulator (e.g., Terminal.app, iTerm2, Ghostty, Alacritty, Kitty, Windows Terminal / WSL).

---

## Installation & Building

### 1. Build from Source

Clone the repository and build the release binary using Swift Package Manager:

```bash
git clone https://github.com/zonble/se.git
cd se
swift build -c release
```

The compiled binary will be located at:

```bash
.build/release/se
```

### 2. Usage

```bash
# Open or create a file for editing
se filename.txt

# Specify custom softwrap column width (e.g., 80 columns)
se filename.txt --wrap 80

# Display classic WordStar-style ruler bar (----!----1----!----2) above viewport
se filename.txt -r

# Specify language explicitly (zh_TW or en)
se filename.txt --lang zh_TW

# Display CLI options and help
se --help
```

---

## Running Tests

Run the automated unit test suite with SwiftPM:

```bash
swift test
```
