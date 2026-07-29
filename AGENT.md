# AGENT.md - AI Agent Development & Architecture Guide for `zago`

Welcome to `zago` (zonble's nano + LOGO), a lightweight, high-performance GNU Nano-compatible Terminal Text Editor written in Swift.

This document serves as the authoritative guide for AI Coding Agents (such as Antigravity, Codex, GitHub Copilot, and Claude Code) when modifying, refactoring, or extending the `zago` codebase.

---

## 1. Executive Summary & Design Philosophy

`zago` is designed to be a fast, zero-dependency command-line text editor with complete GNU Nano keybinding compatibility, rich syntax highlighting, CJK double-width character support, dual-language localization (English and Traditional Chinese), and a user configuration system (`~/.zagorc`).

### Core Design Principles
1. **Command-Driven Architecture**: All user actions are encapsulated into discrete `Command` objects managed by `CommandRegistry`. Key processing dispatches through commands rather than monolithic `switch` blocks.
2. **CJK & Multi-Byte Visual Alignment**: Line wrapping, gutter alignment, status bar centering, and terminal cursor coordinates calculate visual display width (`displayWidth`) rather than byte/character counts.
3. **Modular File Extension Design**: Large controllers (such as `Editor.swift`) are partitioned into focused, single-responsibility Swift extensions (`Editor+Commands.swift`, `Editor+Render.swift`, `Editor+Prompts.swift`, `Editor+Undo.swift`).
4. **Protocol-Oriented Extensions**: Syntax definitions conform to `SyntaxDefinition`, allowing clean template inheritance for language rules alongside GNU Nano `.nanorc` parser support.
5. **Swift 6 Concurrency Compliance**: State variables, enums, and static tables conform to `Sendable` and adhere to Swift 6 strict concurrency isolation rules.
6. **Test-Driven Development (TDD)**: All bug fixes, rendering changes, and new features MUST follow Test-Driven Development (TDD). Write unit tests first to verify expected behavior or reproduce failures before modifying implementation code.

---

## 2. Directory & Module Structure Map

```text
zago/
├── Package.swift                             # Swift Package Manager manifest
├── README.md                                  # Short user-facing project entry point
├── AGENT.md                                   # AI Agent technical specification (this file)
├── docs/
│   ├── README.md                              # Documentation index
│   ├── logo.md                                # LOGO command language guide
│   ├── configuration.md                       # .zagorc, key bindings, and Nano syntax loading
│   └── logo_pen_mode.md                       # Turtle/pen mode drawing guide
├── Sources/
│   ├── zago/
│   │   └── zago.swift                         # Main CLI entry point (swift-argument-parser)
│   ├── TextMetrics/
│   │   └── DisplayWidth.swift                  # Single source of truth for terminal display width
│   └── Editor/
│       ├── Terminal.swift                     # POSIX termios raw mode & ANSI escape sequences
│       ├── TextBuffer.swift                   # Core line buffer, string insertion, range cutting
│       ├── LayoutEngine.swift                 # Softwrap computation & VirtualLine coordinate mapping
│       ├── Command.swift                      # Command & CommandRegistry key dispatch system
│       ├── ConfigLoader.swift                 # Parser for ~/.zagorc and ./.zagorc configuration directives
│       ├── SpellChecker.swift                 # Misspelled word identification & location scanning
│       ├── Editor.swift                       # Core Editor lifecycle, state properties, & run loop
│       ├── Editor+Commands.swift              # Default keybindings & command registrations
│       ├── Editor+Render.swift                # Screen refresh, title bar, WordStar ruler, 2D help bar
│       ├── Editor+Prompts.swift               # Bottom prompt input modes (save, exit, search, insert, spell)
│       ├── Editor+Undo.swift                  # UndoSnapshot stack management & restore
│       ├── HelpView.swift                     # Full-screen ^G / F1 interactive help viewer
│       ├── SyntaxHighlighter.swift            # Highlighting engine & GNU .nanorc parser
│       ├── Syntax/
│       │   ├── SyntaxDefinition.swift         # Protocol-oriented language syntax template base
│       │   ├── SwiftSyntax.swift              # Swift syntax rules
│       │   ├── PythonSyntax.swift             # Python syntax rules
│       │   ├── CSyntax.swift                  # C/C++ syntax rules
│       │   ├── JSONSyntax.swift               # JSON syntax rules
│       │   ├── MarkdownSyntax.swift           # Markdown syntax rules
│       │   └── ShellSyntax.swift              # Shell script syntax rules
│       └── Localization/
│           ├── Localization.swift             # L10n manager & system POSIX locale detector
│           ├── EnglishStrings.swift           # English translation table (en)
│           └── TraditionalChineseStrings.swift # Traditional Chinese translation table (zh_TW)
└── Tests/
    └── seTests/
        └── seTests.swift                      # 20+ automated unit tests covering all subsystems
```

---

## 3. Build, Verification, and Test Commands

When working on `se`, AI agents **MUST** execute the build and test suite after making code modifications to ensure non-breaking changes:

### Build Debug Target
```bash
swift build
```

### Build Production Release Target
```bash
swift build -c release
```

### Run Full Automated Unit Test Suite
```bash
swift test
```

> [!IMPORTANT]
> Never declare success or report completion without verifying that `swift test` passes with **0 failures**.

---

## 4. Key Subsystem Specifications

### A. Command, Key Dispatch & Shortcut Naming Convention ([`Command.swift`](Sources/Editor/Command.swift))
- Every key sequence (including Ctrl keys, Function keys F1–F12, Arrow keys, Shift+Arrows, Alt/Esc sequences) maps to a `Key` enum.
- **Shortcut Naming Convention in UI & Documentation**:
  - Control key combinations MUST be represented in `^<key>` format (e.g., `^Q`, `^N`, `^W`, `^BS`).
  - Alt / Meta key combinations MUST be represented in `M+<key>` format (e.g., `M+T`, `M+S`, `M+L`, `M+.`, `M+,`).
- To add a new editor feature, register a new `Command` instance in [`Editor+Commands.swift`](Sources/Editor/Editor+Commands.swift):
  ```swift
  commandRegistry.register(Command(
      id: "feature.id",
      name: "Feature Name",
      description: "Feature Description",
      keys: [.ctrl("KEY"), .f1]
  ) { editor in
      // Feature execution logic
  })
  ```

### B. Softwrap Layout & Terminal Display Width ([`DisplayWidth.swift`](Sources/TextMetrics/DisplayWidth.swift))
- Standard ASCII characters have a display width of `1`. Full-width CJK characters (Kanji/Hanzi, Hiragana, Katakana, Full-width Punctuation, Emoji) have a display width of `2`.
- [`TextMetrics`](Sources/TextMetrics) is the single source of truth for terminal column width. Terminal positioning, line padding, softwrap, table layout, LOGO box/fill rendering, and tests MUST use `String.displayWidth`, `Character.displayWidth`, or `paddedToDisplayWidth(_:)` from this module.
- Do **not** add new `wcwidth`, Unicode scalar range checks, `logoDisplayWidth`, CJK width helpers, or local display-width extensions in `Editor`, `LogoEngine`, tests, or feature files. If display width behavior must change, update [`Sources/TextMetrics/DisplayWidth.swift`](Sources/TextMetrics/DisplayWidth.swift) and its focused tests.
- Tokenization helpers may classify text for reflow, but they must derive wide-character decisions from `Character.displayWidth >= 2`; they must not maintain independent CJK/wide Unicode tables.
- Never use `String.count` for calculating visual layout bounds in the UI title bar, help bar, or screen cursor placement.

### C. Editor File Modularization Guidelines
Keep `Editor.swift` clean and compact (under 200 lines). When adding new features to `Editor`, place them in the corresponding extension file:
- **`Editor+Commands.swift`**: Adding or modifying keybindings and command registration logic.
- **`Editor+Render.swift`**: Adjusting screen rendering, title bar, gutter, help bar, or ruler.
- **`Editor+Prompts.swift`**: Adding new prompt modes, dialog inputs, or interactive queries.
- **`Editor+Undo.swift`**: Modifying snapshot capture, undo/redo stacks, or buffer state restoration.

### D. Localization (i18n) Engine ([`Localization/`](Sources/Editor/Localization/))
- All user-facing strings (status bar messages, prompts, title bar labels, help bar items, full-screen help view lines) MUST be localized through `L10n`.
- To add a new string key:
  1. Add the string key to [`EnglishStrings.swift`](Sources/Editor/Localization/EnglishStrings.swift).
  2. Add the corresponding translation to [`TraditionalChineseStrings.swift`](Sources/Editor/Localization/TraditionalChineseStrings.swift).
  3. Reference it via `L10n["your.key"]` or a strongly typed accessor in [`Localization.swift`](Sources/Editor/Localization/Localization.swift).

---

## 5. Coding Standards & Agent Constraints

1. **Preserve Documentation & Comments**: Do not remove existing docstrings or explanatory inline comments.
2. **No Hardcoded User Strings**: Never pass raw English string literals directly to `setStatusMessage` or `PromptMode`. Always use `L10n[...]`.
3. **Swift 6 Safety**: Avoid nonisolated global state mutations unless explicitly marked as thread-safe or `@MainActor` isolated.
4. **Sanity Check Terminal Output**: Output ANSI escape sequences using buffer concatenation and flush output efficiently with `fflush(nil)`.
5. **No File Overcrowding**: If an extension file grows beyond 300 lines, evaluate splitting it into a dedicated helper module.
6. **Strict Test-Driven Development (TDD)**: AI agents MUST follow TDD. Before fixing a bug or adding features, write automated unit tests first in `Tests/seTests/seTests.swift` to assert the contract/behavior, run `swift test` to observe failure if applicable, implement the code fix, and verify zero test failures.

---

## 6. Common Development Tasks Checklist

- [ ] **Adding a syntax language**: Create a new class under `Sources/Editor/Syntax/` inheriting from `SyntaxDefinition`, and register it in `SyntaxHighlighter.swift`.
- [ ] **Adding a new keybinding**: Register the command in `Editor+Commands.swift`, add help bar label in `Localization/`, and update `HelpView.swift`.
- [ ] **Adding a user configuration flag**: Add property to `EditorConfig` in `ConfigLoader.swift`, update parser directives, and connect in `Editor.init`.
