# Release & Preview Builds

This document is the practical release checklist for sharing zago with early users.

## Audience

The current builds are preview builds for friends and early testers who are comfortable with terminal tools and can build Swift packages locally.

Good first testers:

- write Markdown, Org, reStructuredText, or AsciiDoc notes
- care about CJK and emoji terminal alignment
- are comfortable reporting exact terminal, OS, and reproduction steps
- can tolerate rough edges while the editor stabilizes

## Supported Platforms

- macOS 14.0 or later
- Linux with Swift 6.0 or later
- VT100 / ANSI-compatible terminal
- On Windows, prefer Windows Terminal or another VT-enabled console, and verify the console is using UTF-8 input/output

Known-good terminal behavior should be checked on:

- macOS Terminal.app
- iTerm2
- kitty
- WezTerm
- common Linux terminal emulators

Unicode display width can vary by terminal. Test CJK, emoji, menu overlays, tables, and canvas blocks before calling a build ready.

## Install From Source

Clone and build:

```sh
git clone https://github.com/zonble/zago.git
cd zago
./build.sh
zago --version
```

By default this installs to:

```text
/usr/local/bin/zago
```

Install somewhere else:

```sh
PREFIX="$HOME/.local" ./build.sh
```

Then make sure the install path is in `PATH`:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Build without installing:

```sh
swift build -c release
.build/release/zago notes.md
```

On macOS, `build.sh` builds a universal release binary and applies ad-hoc code signing. To skip signing:

```sh
SIGN=0 ./build.sh
```

## Install From Homebrew Tap

Users can install with:

```sh
brew tap zonble/zago
brew tap --trust zonble/zago  # allow this third-party tap
brew install zago
zago --version
```

If Homebrew refuses to use the third-party tap, run:

```sh
brew tap-info zonble/zago
brew tap --trust zonble/zago  # allow this third-party tap
brew install zago
```

Tap maintenance is documented in [Homebrew Tap](homebrew_tap.md).

On Linux, the Homebrew formula depends on Homebrew's `swift` package at build time. For non-Homebrew Linux installs, use Swift 6 from the distribution or Swift.org and build from source.

## Smoke Test

Before sharing a build, run:

```sh
swift test
./build.sh
zago --version
zago --init
```

Then manually check:

- open, edit, save, and reopen a Markdown file
- paste CJK text and emoji such as `❌❌❌❌❌`
- open the menu over lines containing wide characters
- toggle Canvas Mode with `M+V`
- create and edit a simple table
- run a small LOGO command from the prompt
- run a headless command such as `zago -e 'BOX 20 4'`

## Release Checklist

1. Update `Sources/Config/ZagoVersion.swift`.
2. Update `CHANGELOG.md`.
3. Run `swift test`.
4. Run `./build.sh`.
5. Verify `zago --version`.
6. Smoke-test CJK and emoji alignment in a real terminal.
7. Create and push a git tag:

```sh
git tag vX.Y.Z
git push origin vX.Y.Z
```

8. Update the Homebrew tap Formula with the tag URL and SHA-256 checksum.
9. Share install instructions and known limitations with testers.


## Tester Bug Reports

Ask testers to include:

- zago version: `zago --version`
- install method: Mint, source build, or copied binary
- OS and terminal app
- shell and locale: `echo $SHELL`, `locale`
- whether line numbers, ruler, syntax highlighting, or sub-line numbers were enabled
- exact text sample, especially for Unicode alignment bugs
- screenshot or short terminal recording when layout is involved

Useful Unicode layout samples:

```text
中文中文中文
❌❌❌❌❌
❤️❤️❤️
A❌B
│❌  │
```

## Current Preview Limitations

- Terminal Unicode width is pragmatic, not mathematically universal. Some terminals may render specific emoji differently.
- Mouse support is not a release goal.
- The document outline supports Markdown, Org, reStructuredText, and AsciiDoc only.
- Embedded syntax highlighting is intentionally single-level.
- The editor is still optimized for technical writers who are comfortable with keyboard-driven terminal workflows.
