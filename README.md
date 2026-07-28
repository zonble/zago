# `se`

`se` is a LOGO-powered lightweight terminal text editor.

It keeps the directness of Pico/Nano-style editing, then adds a small command language for the work that is awkward to repeat by hand: inserting structured text, drawing boxes and lines, filling regions, moving through buffers, and shaping plain text into terminal-native layouts.

LOGO is intentionally simple. Commands read like actions:

```logo
MOVE HOME
TYPE "# "
MOVE END
```

That same language is available from the editor command prompt, from key bindings, and from startup configuration. Each editor instance owns one persistent LOGO runtime, so variables and procedures can live for the lifetime of the buffer session.

`se` treats automation as an editing gesture, not as a plugin system. You can open a command prompt, type a readable command, bind it later, and eventually turn it into a reusable procedure.

```logo
BOX 30 4 ROUND
GOTO 2 2
FILL "hi
```

```text
╭────────────────────────────╮
│hihihihihihihihihihihihihihi│
│hihihihihihihihihihihihihihi│
╰────────────────────────────╯
```

## Features

- LOGO-style editor commands: `TYPE`, `MOVE`, `MARK`, `CUT`, `PASTE`, `JUSTIFY`, `BOX`, `LINE`, `VLINE`, `FILL`, `REPEAT`, `MAKE`, and `TO ... END`.
- Natural command prompt: press `Esc` and enter an editor command.
- Nano/Pico-like modeless editing: `^O` save, `^X` exit, `^W` search, `^K` cut, `^U` paste, `^J` justify, `^Z` undo, `^G` help.
- Terminal drawing tools for boxes, connector lines, fills, and table-oriented editing.
- Correct CJK and multi-byte UTF-8 display-width handling through a shared text metrics module.
- Dynamic softwrap, visual paragraph reflow, syntax highlighting, and Nano `.nanorc` syntax loading.
- Multi-buffer editing, file auto-reload, English and Traditional Chinese UI.

## Quick Start

```bash
git clone https://github.com/zonble/se.git
cd se
swift build -c release
.build/release/se notes.txt
.build/release/se notes.txt --wrap 80
.build/release/se notes.txt --ruler
.build/release/se --init        # optional: create a starter ~/.serc
```

## Command Examples

Create a numbered list:

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

## Documentation

- [Editor basics](docs/editor.md)
- [LOGO command language](docs/logo.md)
- [Configuration and key bindings](docs/configuration.md)
- [Pen mode and turtle drawing](docs/logo_pen_mode.md)

## Requirements

- macOS 14.0+ or Linux
- Swift 6.0+
- VT100 / ANSI-compatible terminal

## Tests

Run `swift test`.

## License

This project is licensed under the [MIT License](LICENSE).
