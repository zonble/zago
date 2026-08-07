# `zago` Documentation

This directory holds the detailed user and language documentation. The root [README](../README.md) is the short project entry point.

## Guides

- [Editor LOGO command language](logo.md): command prompt behavior, language vocabulary, drawing commands, procedures, data primitives, and examples.
- [Editor LOGO text transliteration](logo_text_transliteration.md): proposed ICU String Transform primitive for text/script conversion.
- [Command & Editor LOGO Architecture](command_architecture.md): unified division of responsibilities between Editor `Command` and `LogoEngine`.
- [Editor basics](editor.md): common editing keys and basic editor behavior.
- [Search](search.md): active search query, repeated next/previous navigation, highlighting, and regex search rules.
- [Heading navigation & outline](heading_navigation.md): document heading parsing, next/previous heading navigation, and outline picker behavior.
- [Mark, selection, and clipboard behavior](mark.md): text selection and canvas block mark rules.
- [Configuration](configuration.md): `.zagorc`, key bindings, startup Editor LOGO code, command ids, Nano syntax file loading, and single-level embedded code block highlighting.
- [Editor modes & layout](modes.md): Text Editing Mode, Canvas Mode, and Table Mode.
- [Directory mode & permissions](directory_mode.md): DirectoryBuffer architecture, command filtering matrix, and Editor LOGO execution restrictions.
- [Diagram snippets & menu rules](diagram_snippets.md): trigger conditions, code block context detection, filtering rules, and Editor LOGO `DIAGRAM` command usage.
- [Homebrew tap](homebrew_tap.md): personal tap layout, Formula template, release checksum workflow, and user install commands.
- [Spell Checker Architecture & Specification](spell_checker.md): multi-language design, platform engines (Windows COM API, Hunspell, macOS NSSpellChecker), Markdown context filtering, and `.zagorc` language directives.
- [File Encoding & Auto-Detection Architecture](encoding.md): multi-encoding auto-detection, buffer encoding state preservation, and UTF-8 fallback workflow.
- [Windows Console I/O & Encoding Architecture](windows_console_architecture.md): Windows Console Subsystem, Code Page handling (CP950/Big5 vs UTF-8), Win32 `ReadConsoleW` API integration, and Cross-Platform I/O abstraction.
- [Git Integration & Diff Gutter Specification](git_integration.md): non-Git-client design, title bar `[branch]` status, real-time diff against `HEAD`, and line number gutter colors (`+`, `~`, `-`).
- [Terminal Rendering Performance Architecture](rendering_performance.md): rendering performance architecture, double buffering engine, line diffing algorithm, and layout caching specifications (Git Diff decoupling, Syntax Caching, VT100 Double Buffering, Virtual Line Caching).
- [Release & preview builds](release.md): source install, smoke tests, release checklist, tester bug report template, and known preview limitations.
- [File System Watcher & External Modification Architecture](file_watcher.md): cross-platform FileWatcher design, kernel event monitoring (macOS kqueue, Windows Win32 FindFirstChangeNotificationW), atomic save recovery, and UI reload pipeline.
- [Cross-Platform Architecture, Pitfalls & Solutions](cross_platform.md): comprehensive guide to cross-platform terminal input, readline/pipe handling, file I/O locks, Big5/CP950 Emoji encoding gotchas, and display width calculations.
- [Testing Guidelines & Best Practices](test.md): Windows file locking rules (`Win32Error 32`), mandatory `UUID().uuidString` temporary file paths, and unit test teardown guidelines.
