# `zago` Documentation

This directory holds the detailed user, language, architecture, and development documentation. The root [README](../README.md) is the short project entry point.

## User Guides

- [Editor basics](user/editor.md): common editing keys and basic editor behavior.
- [Editor modes & layout](user/modes.md): Text Editing Mode, Canvas Mode, and Table Mode.
- [Mark, selection, and clipboard behavior](user/mark.md): text selection and canvas block mark rules.
- [Search](user/search.md): active search query, repeated next/previous navigation, highlighting, and regex search rules.
- [Heading navigation & outline](user/heading_navigation.md): document heading parsing, next/previous heading navigation, and outline picker behavior.
- [Sub line numbers](user/sub_line_numbers.md): wrapped-line numbering behavior.
- [Daily journal shortcut](user/daily_journal.md): planned shortcut for opening today's journal; not a separate editor mode.
- [Directory mode & permissions](user/directory_mode.md): DirectoryBuffer architecture, command filtering matrix, and Editor LOGO execution restrictions.
- [Configuration](user/configuration.md): `.zagorc`, key bindings, startup Editor LOGO code, command ids, Nano syntax file loading, and embedded code block highlighting.

## Editor LOGO

- [Editor LOGO command language](logo/reference.md): command prompt behavior, language vocabulary, drawing commands, procedures, data primitives, and examples.
- [Editor LOGO debugger](logo/debugger.md): debugger commands and buffer behavior.
- [Editor LOGO error handling & ASSERT](logo/error_handling.md): error categories, status/console reporting, atomic undo, and `ASSERT` primitive specification.
- [Editor LOGO pen mode](logo/pen_mode.md): `PD` / `PU` line drawing mode.
- [Editor LOGO string primitives](logo/string_primitives.md): proposed string primitive expansion.
- [Editor LOGO text transliteration](logo/text_transliteration.md): ICU String Transform primitive for text/script conversion.

## Features

- [Diagram snippets & menu rules](features/diagram_snippets.md): trigger conditions, code block context detection, filtering rules, and Editor LOGO `DIAGRAM` command usage.
- [Git Integration & Diff Gutter Specification](features/git_integration.md): title bar branch status, real-time diff against `HEAD`, and line number gutter colors.
- [Spell Checker Architecture & Specification](features/spell_checker.md): platform engines, Markdown context filtering, and `.zagorc` language directives.
- [File Encoding & Auto-Detection Architecture](features/encoding.md): multi-encoding auto-detection, buffer encoding state preservation, and UTF-8 fallback workflow.
- [File System Watcher & External Modification Architecture](features/file_watcher.md): cross-platform watcher design, atomic save recovery, and UI reload pipeline.

## Architecture

- [MVC & architectural layering](architecture/mvc.md): editor layering and module boundaries.
- [Command & Editor LOGO architecture](architecture/command_system.md): division of responsibilities between Editor `Command` and `LogoEngine`.
- [Terminal rendering performance](architecture/rendering_performance.md): double buffering, line diffing, layout caching, and rendering performance.
- [Cross-platform architecture](architecture/cross_platform.md): terminal input, pipe handling, file I/O locks, encoding gotchas, and display width calculations.
- [Windows console I/O & encoding](architecture/windows_console.md): Windows Console Subsystem, code page handling, and Win32 `ReadConsoleW` API integration.
- [WebAssembly & Web Terminal architecture](architecture/wasm_web_architecture.md): Web Worker execution model, WASI shim, xterm.js integration, and MEMFS/IndexedDB persistence.
- [Editor wakeup and external request dispatch](architecture/editor_wakeup.md): how IPC worker threads wake the editor loop without mutating editor state directly.
- [Threading model & concurrency architecture](architecture/threading_model.md): single-writer editor loop, IPC worker threads, wakeup bridges, and shutdown safety.

## Reviews

- [Refactoring review](reviews/refactoring_review.md): current structural review through the lens of Fowler's *Refactoring*, with prioritized findings and suggested extraction boundaries.

## AI & IPC

- [AI editor operation protocol](ai-ipc/protocol.md): JSON-RPC 2.0 API methods, buffer queries, ghost overlay previews, Editor LOGO execution, and permission matrix.
- [AI & IPC architecture and milestone summary](ai-ipc/plan.md): completed architecture, capabilities, ghost overlays, MCP integration, and design boundaries.

## Development

- [Testing Guidelines & Best Practices](development/test.md): Windows file locking rules, unique temporary paths, and unit test teardown guidelines.
- [Windows Swift debugging](development/windows_swift_debugging.md): VS Code Swift debugging, Visual Studio/WinDbg attach, dump analysis, and trace-based hang diagnosis.
- [WebAssembly build & deployment](development/wasm_build.md): Swift SDK for WebAssembly, local Vite dev server, and GitHub Pages deployment.
- [Release & preview builds](development/release.md): source install, smoke tests, release checklist, tester bug report template, and known preview limitations.
- [Homebrew tap](development/homebrew_tap.md): tap layout, Formula template, release checksum workflow, and user install commands.

## Examples & Assets

- [Example editor document](examples/zago_editor.md)
- [Example LOGO eval document](examples/test_eval.md)
- [VHS tapes and generated assets](assets/vhs/)
