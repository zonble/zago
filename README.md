# `se` - Swift TUI Text Editor

`se` is a lightweight, full-featured Terminal User Interface (TUI) text editor written in pure Swift 6. Designed with classic Pico/Nano-style keybindings, `se` provides modeless text editing, full UTF-8 / CJK multi-byte character support, dynamic softwrap, visual paragraph justification, and multi-platform support across macOS and Linux.

---

## Features & Purpose

- **Modeless Keybindings**: Intuitive Nano/Pico control shortcuts (`^O` Save, `^X` Exit, `^W` Search, `^K` Cut, `^U` Uncut/Paste, `^J` Justify, `^Z` Undo, `^T` Spell Check, `^G` Help).
- **Undo Capability (`^Z`)**: Revert edit operations up to 100 snapshot levels.
- **Interactive Spell Checker (`^T` / `F12`)**: System dictionary lookup with CJK filtering and interactive TUI word replacement.
- **Full-Screen Help Viewer (`^G` / `F1`)**: Dedicated full-page TUI command reference.
- **Shift-Selection**: Automatically start and adjust selection mark using `Shift + Arrow Keys` or `^^`.
- **Non-Blocking Batch Paste**: Sub-millisecond clipboard paste processing via POSIX non-blocking I/O.
- **Function Keys Support**: Native mapping for function keys `F1` through `F12`.
- **CJK & Multi-byte UTF-8 Support**: Seamless Chinese, Japanese, Korean, and multi-byte UTF-8 character input with accurate `wcwidth` display column alignment.
- **Dynamic Softwrap**: Automatic line wrapping at viewport boundary or configurable column width (`-w` / `--wrap`) without altering raw line buffer data.
- **Visual Reflow Engine**: Paragraph justification (`^J`) powered by a visual column display width algorithm for mixed CJK and Latin text.

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

### 2. Install via Mint

If you use [Mint](https://github.com/yonaskolb/Mint), a package manager for Swift command line tools, you can install `se` directly:

```bash
mint install zonble/se
```

Or run `se` without installing:

```bash
mint run zonble/se filename.txt
```

### 3. Install Executable System-Wide

Copy the built executable into a folder in your `$PATH` (e.g., `/usr/local/bin`):

```bash
cp .build/release/se /usr/local/bin/
```

### 4. Usage

```bash
# Open or create a file for editing
se filename.txt

# Specify custom softwrap column width (e.g., 80 columns)
se filename.txt --wrap 80

# Display CLI options and help
se --help
```

---

## Running Tests & Code Coverage

Run the automated unit test suite with SwiftPM:

```bash
swift test
```

To generate and view test code coverage statistics:

```bash
# Run tests with code coverage enabled
swift test --enable-code-coverage

# Export coverage report on macOS using xcrun llvm-cov
xcrun llvm-cov report .build/arm64-apple-macosx/debug/sePackageTests.xctest/Contents/MacOS/sePackageTests \
  -instr-profile=.build/arm64-apple-macosx/debug/codecov/default.profdata \
  -ignore-filename-regex="Tests/|.build/"
```
