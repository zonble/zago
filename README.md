# `zago`: Terminal Text Editor & Diagramming

![Swift 6](https://img.shields.io/badge/Swift-6-orange)
![macOS + Linux](https://img.shields.io/badge/macOS%20%2B%20Linux-supported-blue)
![Terminal UI](https://img.shields.io/badge/Terminal-UI-334155)
![CJK aware](https://img.shields.io/badge/CJK-aware-16a34a)
![Emoji safe](https://img.shields.io/badge/Emoji-safe-f59e0b)
![Text + Canvas](https://img.shields.io/badge/Text%20%2B%20Canvas-editor-9333ea)
![LOGO macros](https://img.shields.io/badge/LOGO-macros-ec4899)

- a small terminal text editor.
- draw boxes and lines in your Markdown file.
- handles CJK and emoji alignment.

## Who is zago for?

- **Text diagrams over images**: Clean, diffable diagrams in your Markdown.
- **No GUI context-switching**: No need to open Monodraw or ASCIIFlow just to draw boxes.
- **Keyboard-first**: Stay in the typing flow without reaching for a mouse.
- **CJK & Emoji perfectionists**: Precise alignment that never breaks box borders.
- **Terminal natives**: Fast documentation for local and SSH workflows.

![zago editing a Markdown document with a plain-text diagram and LOGO command output](zago.gif)

- [`zago`: Terminal Text Editor \& Diagramming](#zago-terminal-text-editor--diagramming)
  - [Who is zago for?](#who-is-zago-for)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Quick Start](#quick-start)
  - [Homebrew Tap](#homebrew-tap)
  - [Preview Builds](#preview-builds)
  - [Text Mode \& 2D Canvas Mode](#text-mode--2d-canvas-mode)
  - [Text Processing](#text-processing)
  - [Command Examples](#command-examples)
  - [CLI Usage \& Headless Scripting](#cli-usage--headless-scripting)
    - [1. Interactive Editor Mode](#1-interactive-editor-mode)
    - [2. Headless Scripting Mode](#2-headless-scripting-mode)
    - [Command-Line Options](#command-line-options)
  - [Documentation](#documentation)
  - [Tests](#tests)
  - [License](#license)


## Features

- Plain-text diagramming: draw boxes, arrow connector lines, fills, and table layouts directly in the buffer.
- Unicode-aware layout: CJK and emoji keep boxes, tables, fills, and connector lines aligned.
- Modeless typing & dual spatial modes: Ordinary typing always inserts text directly. Press `M+V` to toggle between standard text stream mode and 2D Canvas Mode for freeform grid navigation and block editing.
- Nano-compatible controls: `^O` save, `^X` exit, `^W` search, `M+W` copy, `^K` cut, `^U` paste, `^J` justify, `^Z` undo.
- Dynamic softwrap, visual paragraph reflow, syntax highlighting, and Nano `.nanorc` syntax loading.
- Multi-buffer editing, file auto-reload.
- Natural command prompt: press `Esc` and run editing commands such as `BOX 30 4`, `LINE`, `FILL "hi`, or `REPEAT 5 [...]`.
- Lightweight automation: reuse command sequences with variables, loops, and procedures when editing becomes repetitive.

## Requirements

- macOS 14.0+ or Linux
- Swift 6.0+
- VT100 / ANSI-compatible terminal

## Quick Start

Install from the Homebrew tap:

```bash
brew tap zonble/zago
brew tap --trust zonble/zago  # allow this third-party tap
brew install zago
zago notes.txt
```

If Homebrew refuses to install from an untrusted third-party tap, run the `brew tap --trust zonble/zago` line and install again.

Install with [Mint](https://github.com/yonaskolb/Mint):

```bash
mint install zonble/zago
zago notes.txt
```

Or run without installing:

```bash
mint run zonble/zago notes.txt
```

Build from source:

```bash
git clone https://github.com/zonble/zago.git
cd zago
swift build -c release
.build/release/zago notes.txt
.build/release/zago notes.txt --wrap 80
.build/release/zago notes.txt --ruler
.build/release/zago --init        # optional: create a starter ~/.zagorc
```

## Homebrew Tap

The tap repository is `zonble/homebrew-zago`, which users access as:

```bash
brew tap zonble/zago
brew tap --trust zonble/zago  # allow this third-party tap
brew install zago
```

Formula maintenance notes live in [Homebrew Tap](docs/homebrew_tap.md).

## Preview Builds

For early testers, the simplest source install path is:

```bash
git clone https://github.com/zonble/zago.git
cd zago
./build.sh
zago --version
```

This installs `zago` to `/usr/local/bin/zago` by default. To install under your home directory:

```bash
PREFIX="$HOME/.local" ./build.sh
export PATH="$HOME/.local/bin:$PATH"
```

See [Release & Preview Builds](docs/release.md) for smoke tests, known limitations, and what to include in bug reports.

## Text Mode & 2D Canvas Mode

`zago` provides two complementary spatial editing modes. In both modes, typing remains modeless and inserts characters directly:

- **Text Mode** (Default): Standard linear text editing for prose and code. Selections follow linear text streams.
- **Canvas Mode** (`M+V`): Unlocks 2D virtual space navigation beyond line ends. Supports 2D rectangular block selection (`Shift+Arrows`), block copy (`M+W`), block cut (`^K`), and block paste (`^U`) without distorting surrounding text layout.

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

The command language is Editor LOGO. Commands read like direct editing actions, but they can still be combined with variables, loops, and procedures when the work becomes repetitive.

```logo
BOX 30 5
```

```logo
MOVE HOME
TYPE "# "
MOVE END
```

The same language is available from the command prompt, key bindings, and startup configuration. Variables and procedures stay available throughout your editing session, so they can live for the lifetime of the buffer session.

Create a numbered list:

```logo
REPEAT 5 [ TYPE :# ". List item" NL]
```

or

```logo
FOREACH (ISEQ 1 5) [TYPE ? ". List item" NL]
```

or

```logo
MAKE "i" 1 REPEAT 5 [ TYPE :i TYPE ". List item" MOVE DOWN MOVE HOME MAKE "i" (:i + 1) ]
```

Define and reuse an editor-local procedure:

```logo
TO TITLE :text
  BOX :text CENTER ROUND
END

TITLE "Release Notes"
```

Draw and fill a canvas box:

```logo
DRAWBOX 30 4 ROUND
GOTO 2 2
FILL "hi
```

```text
╭────────────────────────────╮
│hihihihihihihihihihihihihihi│
│hihihihihihihihihihihihihihi│
╰────────────────────────────╯
```

Draw a small plain-text architecture diagram:

```logo
DRAWBOX 18 3 "client" CENTER
GOTO 3 11
VLINE 3
GOTO 5 1
DRAWBOX 18 5
GOTO 6 2
TYPE "     server     "
GOTO 7 1
LINE 18
GOTO 8 2
TYPE "    database    "
```

```text
┌────────────────┐
│     client     │
└─────────┬──────┘
          │
┌─────────┴──────┐
│     server     │
├────────────────┤
│    database    │
└────────────────┘
```

## CLI Usage & Headless Scripting

`zago` operates both as an interactive TUI editor and as a headless CLI diagram/table generator.

### 1. Interactive Editor Mode

Open one or more files in the terminal TUI editor:

```bash
zago notes.txt
zago file1.txt file2.txt --wrap 80 --ruler
```

### 2. Headless Scripting Mode

Execute LOGO scripts or inline LOGO code from the command line, render the canvas to a text buffer, and print the resulting ASCII output directly to stdout:

```bash
# Execute inline LOGO code and print output
zago -e "BOX 20 4; MOVE DOWN MOVE RIGHT; FILL \"Hello World\""

# Execute a LOGO script file and redirect output to a file
zago -s myscript.logo > diagram.txt

# Pipe generated diagram directly to clipboard
zago --run generate_architecture.logo | pbcopy
```

### Command-Line Options

| Option | Flag | Description |
| :--- | :--- | :--- |
| `files` | | File(s) to open in interactive editor mode. |
| `-w`, `--wrap <col>` | | Specify softwrap column width (e.g. 80). |
| `-r`, `--ruler` | | Display WordStar-style ruler bar above viewport. |
| `-e`, `--eval <code>` | | Execute inline LOGO code in headless mode and print to stdout. |
| `-s`, `--run`, `--script <file>` | | Execute a LOGO script file in headless mode and print to stdout. |
| `--init` | | Generate default `~/.zagorc` configuration file. |
| `--syntax <true/false>` | | Enable or disable syntax highlighting. |
| `--lang <en/zh_TW>` | | Set interface language. |

## Documentation

- [Editor basics](docs/editor.md)
- [Search behavior](docs/search.md)
- [Mark, selection, and canvas behavior](docs/mark.md)
- [Editor LOGO command language](docs/logo.md)
- [Configuration and key bindings](docs/configuration.md)
- [Pen mode and turtle drawing](docs/logo_pen_mode.md)
- [Diagram snippets & menu rules](docs/diagram_snippets.md)
- [Homebrew tap](docs/homebrew_tap.md)
- [Release & preview builds](docs/release.md)
- [Changelog](CHANGELOG.md)

## Tests

Run `swift test`.

## License

MIT License. Copyright (c) 2026 Weizhong Yang a.k.a. zonble.

*Note: The name `zago` stands for "zonble's nano + LOGO".*
