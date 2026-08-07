# `zago`: A Lean Terminal Forge for Markdown Writers

[繁體中文 README](README.zh_TW.md) | [User Manual (繁體中文手冊)](https://github.com/zonble/zago/wiki/zago-help-zh-tw)

![Swift 6](https://img.shields.io/badge/Swift-6-orange)
![macOS + Linux + Windows](https://img.shields.io/badge/macOS%20%2B%20Linux%20%2B%20Windows-supported-blue)
![Terminal UI](https://img.shields.io/badge/Terminal-UI-334155)
![Markdown first](https://img.shields.io/badge/Markdown-first-2563eb)
![Tables](https://img.shields.io/badge/Pipe%20Tables-editable-0f766e)
![Diagrams](https://img.shields.io/badge/Text%20Diagrams-inline-7c3aed)
![CJK aware](https://img.shields.io/badge/CJK-aware-16a34a)
![Emoji safe](https://img.shields.io/badge/Emoji-safe-f59e0b)

In the AI-agent era, Markdown is becoming the control surface for software
work: instructions, specs, review notes, implementation plans, and context that
guide agent CLIs.

But Markdown editing still breaks the terminal flow. GUI editors pull you out
of the shell. Terminal editors usually lack table and diagram tools. A quick
plain-text diagram often means opening a browser-based ASCII diagrammer or a
dedicated diagram drawing app.

`zago` is built for that shift: a lean terminal Markdown forge that keeps prose
editing, pipe tables, local document links, headings, text diagrams, CJK-aware
text tools, and small automation macros in the same plain-text flow, whether
the file is on your laptop or on a server over SSH.

## Who is zago for?

- **AI-agent users** who write Markdown instructions, specs, notes, and review
  context from the terminal.
- **Markdown writers** who want prose, headings, links, tables, and diagrams in
  one terminal tool.
- **Technical writers** who prefer plain-text documents that remain readable in
  Git diffs, SSH sessions, pull requests, and README files.
- **People drawing text diagrams** who do not want to leave the document just to
  open a diagramming app.
- **CJK and emoji perfectionists** who need terminal display width to be correct
  when boxes, status-icon tables, rulers, and wrapped prose are involved.
- **Keyboard-first document builders** who like nano-style editing, but want a
  sharper toolbox for Markdown-era writing.

![zago editing a Markdown document with a plain-text diagram and LOGO command output](zago.gif)

- [`zago`: A Lean Terminal Forge for Markdown Writers](#zago-a-lean-terminal-forge-for-markdown-writers)
  - [Who is zago for?](#who-is-zago-for)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Quick Start](#quick-start)
    - [Install on macOS / Linux from Homebrew tap](#install-on-macos--linux-from-homebrew-tap)
    - [Install with Mint](#install-with-mint)
    - [Install on Linux (x86\_64 / arm64)](#install-on-linux-x86_64--arm64)
    - [Install on Arch Linux](#install-on-arch-linux)
    - [Install on Windows (PowerShell)](#install-on-windows-powershell)
  - [Build](#build)
    - [macOS](#macos)
    - [Linux](#linux)
    - [Windows / Developers](#windows--developers)
  - [Text Mode \& 2D Canvas Mode](#text-mode--2d-canvas-mode)
  - [Text Processing](#text-processing)
  - [Command Examples](#command-examples)
  - [CLI Usage \& Headless Scripting](#cli-usage--headless-scripting)
    - [1. Interactive Editor Mode](#1-interactive-editor-mode)
    - [2. Headless Scripting Mode](#2-headless-scripting-mode)
    - [Command-Line Options](#command-line-options)
  - [FAQ, Sort Of](#faq-sort-of)
    - [How do I preview rendered HTML?](#how-do-i-preview-rendered-html)
    - [Why a TUI app when Electron apps exist?](#why-a-tui-app-when-electron-apps-exist)
    - [Why not Vim or Emacs?](#why-not-vim-or-emacs)
    - [Why not Rust?](#why-not-rust)
    - [Isn't LOGO for 80s kids?](#isnt-logo-for-80s-kids)
    - [How do I erase a wrong line or box in Canvas Mode?](#how-do-i-erase-a-wrong-line-or-box-in-canvas-mode)
  - [Documentation](#documentation)
  - [Tests](#tests)
  - [License](#license)

## Features

- Markdown-first editing: write prose, jump through local document links,
  navigate headings, and keep README-style documents close to their final form.
- Table-aware editing: format Markdown pipe tables, move between table cells,
  and edit table content without breaking borders.
- Plain-text diagramming: draw boxes, arrow connector lines, fills, and table
  layouts directly in the buffer.
- Text processing for writers: count chars, words, lines, CJK chars, and
  emojis; normalize CJK/ASCII spacing; transform selected text between scripts.
- Unicode-aware layout: CJK and emoji such as ✅, ❌, and ⚠️ keep boxes,
  tables, fills, rulers, and connector lines aligned.
- Modeless typing & dual spatial modes: Ordinary typing always inserts text
  directly. Press `M+V` to toggle between standard text stream mode and 2D
  Canvas Mode for freeform grid navigation and block editing.
- Nano-compatible controls: `^O` save, `^X` exit, `^W` search, `M+W` copy, `^K` cut, `^U` paste, `^J` justify, `^Z` undo.
- Dynamic softwrap, visual paragraph reflow, syntax highlighting, and Nano `.nanorc` syntax loading.
- Multi-buffer editing, file auto-reload.
- Natural command prompt: press `Esc` and run editing commands such as `BOX 30 4`, `LINE`, `FILL "hi`, or `REPEAT 5 [...]`.
- Lightweight automation: reuse command sequences with variables, loops, and procedures when editing becomes repetitive.

## Requirements

- macOS 14.0+, Linux, or Windows
- On Windows, use Windows Terminal or another VT-enabled console with UTF-8 input enabled *(Note: `Ctrl+Shift+Up` and `Ctrl+Shift+Down` may be intercepted by Windows Terminal's default hotkeys; disable them in **Settings -> Actions** to avoid conflicts with Canvas Mode arrow drawing)*
- Swift 6.0+
- VT100 / ANSI-compatible terminal

## Quick Start

### Install on macOS / Linux from Homebrew tap

```bash
brew tap zonble/zago
brew tap --trust zonble/zago  # allow this third-party tap
brew install zago
zago notes.txt
```

If Homebrew refuses to install from an untrusted third-party tap, run the `brew tap --trust zonble/zago` line and install again.

On Linux, the Homebrew formula builds zago with Homebrew's `swift` package. Without Homebrew, install Swift 6 from your distribution or Swift.org and use the source build commands below.

### Install with [Mint](https://github.com/yonaskolb/Mint)

```bash
mint install zonble/zago
zago notes.txt
```

Or run without installing:

```bash
mint run zonble/zago notes.txt
```

### Install on Linux (x86\_64 / arm64)

```bash
curl -fsSL https://raw.githubusercontent.com/zonble/zago/main/install.sh | sh
zago notes.txt
```

This downloads the pre-built static binary for your architecture (`x86_64` or `aarch64`) to `~/.local/bin`. No Swift toolchain required.

To install to a custom path, set `INSTALL_DIR`:

```bash
INSTALL_DIR=/usr/local/bin curl -fsSL https://raw.githubusercontent.com/zonble/zago/main/install.sh | sh
```

### Install on Arch Linux

You can install the package by cloning the packaging source and building it locally:

```bash
git clone https://github.com/cawa0505/aur-zago.git zago-bin
cd zago-bin
makepkg -si
```

This package installs a precompiled static binary. It is maintained and automatically updated to track upstream releases via GitHub Actions at [cawa0505/aur-zago](https://github.com/cawa0505/aur-zago).

### Install on Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/zonble/zago/main/install.ps1 | iex
```

This downloads the pre-built `zago.exe` to `%LOCALAPPDATA%\Programs\zago` and configures your User PATH automatically. No Swift SDK required.

## Build

### macOS

```bash
git clone https://github.com/zonble/zago.git
cd zago
swift build -c release
.build/release/zago notes.txt
.build/release/zago notes.txt --wrap 80
.build/release/zago notes.txt --ruler
.build/release/zago --init        # optional: create a starter ~/.zagorc
```

### Linux

1. Install Swift 6.0+ toolchain using your distribution package manager, [swiftly](https://swiftlang.github.io/swiftly/), or from [Swift.org](https://www.swift.org/download/):

   ```bash
   # On Linux with Homebrew:
   brew install swift

   # Or install via swiftly:
   curl -O https://swiftlang.github.io/swiftly/swiftly-installer.sh
   bash swiftly-installer.sh
   swiftly install 6.0
   ```

2. Clone and build:

   ```bash
   git clone https://github.com/zonble/zago.git
   cd zago
   swift build -c release
   ```

3. Run the binary or install using `build.sh`:

   ```bash
   .build/release/zago notes.txt

   # Or install to ~/.local/bin (or /usr/local/bin):
   PREFIX="$HOME/.local" ./build.sh
   ```

### Windows / Developers

*(Note: End users do not need to build from source or install Swift SDK. Use the PowerShell `irm` command above to install the pre-built binary.)*

1. Install the Swift SDK using `winget`:

   ```powershell
   winget install Swift.Toolchain
   ```

2. Run PowerShell or Command Prompt as **Administrator** (required because dependencies such as `swift-argument-parser` create symbolic links on Windows during the build process).

3. Clone and build:

   ```powershell
   git clone https://github.com/zonble/zago.git
   cd zago
   swift build
   ```

   To build a release version:

   ```powershell
   swift build -c release
   ```

   Then run the executable:

   ```powershell
   .build\release\zago.exe notes.txt
   ```

## Text Mode & 2D Canvas Mode

`zago` provides two complementary spatial editing modes. In both modes, typing remains modeless and inserts characters directly:

- **Text Mode** (Default): Standard linear text editing for prose and code. Selections follow linear text streams.
- **Canvas Mode** (`M+V`): Unlocks 2D virtual space navigation beyond line ends. Supports 2D rectangular block selection (`Shift+Arrows`), block copy (`M+W`), block cut (`^K`), and block paste (`^U`) without distorting surrounding text layout.

> [!TIP]
> **Windows Terminal Shortcut Tip**: In Windows Terminal, `Ctrl+Shift+Up` and `Ctrl+Shift+Down` are bound by default to terminal actions (such as scrolling). To use these shortcuts for drawing vertical arrows in Canvas Mode, disable or unbind them in Windows Terminal via **Settings -> Actions**.

For details on selection rules and clipboard separation, see [Mark, selection, and canvas behavior](docs/mark.md).

## Text Processing

`zago` is still a text editor. The diagram tools sit on top of ordinary prose editing rather than replacing it:

- Linear text selection in Text Mode and Table Mode, including `Shift+Arrow` and `Shift+Home` / `Shift+End`, with selected text replaced by typing.
- Paragraph justification (`^J`) for mixed CJK and Latin prose, using display width instead of byte or scalar counts.
- Selection-based text transforms from the Tools menu: Traditional/Simplified Chinese conversion, Latin/Hiragana/Katakana/Romaji transliteration, and CJK/ASCII spacing normalization.
- Text counts from the Tools menu. With a selection, `Word Count` reports that selection; without a selection, it reports the whole document. The status includes chars, words, lines, and only shows CJK chars or emojis when present.
- Optional sub line numbers for fixed-width prose drafting: when a wrap column is set, long physical lines can show visual-row numbers and paragraph character counts.
- Document link navigation with `M+O` for local Markdown, Org, reStructuredText, and AsciiDoc links.
- Heading navigation and outline picker for Markdown, Org, reStructuredText, and AsciiDoc documents.

## Command Examples

Press `Esc` to enter the command prompt. Commands use Editor LOGO syntax for editing actions, shape generation, and turtle graphics:

- **Movement & Text Insertion**:
  ```logo
  MOVE HOME; TYPE "# "; MOVE END
  ```

- **Box & Fill**:
  ```logo
  BOX 30 5 CENTER ROUND
  DRAWBOX 30 4 ROUND; GOTO 2 2; FILL "hi
  ```

- **Loops & Lists**:
  ```logo
  REPEAT 5 [ TYPE :# ". List item" NL ]
  ```

- **Procedures**:
  ```logo
  TO TITLE :text
    BOX :text CENTER ROUND
  END
  ```

- **ASCII Architecture Diagram**:
  ```logo
  DRAWBOX 18 3 "client" CENTER; GOTO 3 11; VLINE 3
  GOTO 5 1; DRAWBOX 18 5; GOTO 6 2; TYPE "     server     "
  ```
  ```text
  ┌────────────────┐
  │     client     │
  └─────────┬──────┘
            │
  ┌─────────┴──────┐
  │     server     │
  └────────────────┘
  ```

For the complete command reference, see [Editor LOGO Documentation](docs/logo.md) and the [User Manual (繁體中文手冊)](https://github.com/zonble/zago/wiki/zago-help-zh-tw).

## CLI Usage & Headless Scripting

`zago` operates as an interactive TUI editor, a system `$EDITOR`, and a headless Unix pipe filter.

### 1. Interactive Editor & System `$EDITOR` Mode

Open files, jump to specific lines, edit piped stdin streams, or use `zago` as `export EDITOR=zago`:

```bash
# Open one or more files in the terminal TUI editor
zago notes.txt file2.txt --wrap 80 --ruler

# Open file and jump directly to line 42, column 10
zago +42:10 notes.txt

# Pipe stdin stream directly into interactive TUI editor
cat server.log | zago

# Open files in read-only mode
zago -R /var/log/syslog
```

### 2. Headless Scripting & Unix Pipe Filter

Execute LOGO scripts or inline LOGO code on stdin piped text or files without opening a TUI window, printing the resulting ASCII output directly to `stdout`:

```bash
# Pipe stdin text into LOGO filter and wrap it in an ASCII box
uptime | zago -e "box buffertext"

# Execute inline LOGO code and print output
zago -e "BOX 20 4; MOVE DOWN MOVE RIGHT; FILL \"Hello World\""

# Process input file with a LOGO script and redirect output
cat data.txt | zago -s format_report.logo > diagram.txt

# Pipe generated diagram directly to clipboard
zago --run generate_architecture.logo | pbcopy
```

### Command-Line Options

| Option | Flag | Description |
| :--- | :--- | :--- |
| `files` | | File(s) to open, `-` for stdin pipe, or `+LINE[:COL]` cursor jump. |
| `-w`, `--wrap <col>` | | Specify softwrap column width (e.g. 80). |
| `-r`, `--ruler` | | Display WordStar-style ruler bar above viewport. |
| `-R`, `--readonly` | | Open file(s) in read-only mode. |
| `-e`, `--eval <code>` | | Execute inline LOGO code in headless mode (supports Unix stdin pipe). |
| `-s`, `--run`, `--script <file>` | | Execute a LOGO script file in headless mode (supports Unix stdin pipe). |
| `--init` | | Generate default `~/.zagorc` configuration file. |
| `--syntax <true/false>` | | Enable or disable syntax highlighting. |
| `--lang <en/zh_TW>` | | Set interface language. |
| `--spell-lang <lang>` | | Set spell checker language (e.g. en_US, de_DE, fr_FR). |

## FAQ, Sort Of

### How do I preview rendered HTML?

You probably don't.

In agent-facing Markdown, the source is the interface. AI agents read the
Markdown itself; they do not need a rendered HTML preview. `zago` focuses on
making that source easier to write, shape, and maintain.

### Why a TUI app when Electron apps exist?

For the same reason AI agent CLIs exist: the terminal is still the shortest path
between code, files, tools, and remote machines.

### Why not Vim or Emacs?

The features I want are not just Markdown syntax helpers. They touch the
editor's interaction model: Text Mode and Canvas Mode, table-cell editing,
rectangular canvas blocks, LOGO commands, selection-based text tools, status
lines, menus, and key bindings.

In a powerful plugin ecosystem, that kind of opinionated workflow can easily
fight the host editor, existing user habits, and other plugins. `zago` keeps the
surface smaller so these pieces can be designed as one coherent Markdown writing
flow.

### Why not Rust?

因為我不會。

### Isn't LOGO for 80s kids?

Yes. BTW, I am an 80s kid. :p

Also, LOGO is still a pretty good little language for movement, repetition,
shapes, and text macros.

### How do I erase a wrong line or box in Canvas Mode?

Type spaces over it, or use Canvas Mode block cut when the shape is rectangular.

## Documentation

- [User Manual / 繁體中文使用手冊](https://github.com/zonble/zago/wiki/zago-help-zh-tw)
- [Editor basics](docs/editor.md)
- [Search behavior](docs/search.md)
- [Mark, selection, and canvas behavior](docs/mark.md)
- [Editor LOGO command language](docs/logo.md)
- [Configuration and key bindings](docs/configuration.md)
- [Pen mode and turtle drawing](docs/logo_pen_mode.md)
- [Diagram snippets & menu rules](docs/diagram_snippets.md)
- [Spell checker architecture & plan](docs/spell_checker.md)
- [File encoding & auto-detection](docs/encoding.md)
- [Homebrew tap](docs/homebrew_tap.md)
- [Release & preview builds](docs/release.md)
- [Changelog](CHANGELOG.md)

## Tests

Run `swift test`.

## License

MIT License. Copyright (c) 2026 Weizhong Yang a.k.a. zonble.

*Note: The name `zago` stands for "zonble's nano + LOGO".*
