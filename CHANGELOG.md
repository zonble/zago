# Changelog

## Unreleased

## 1.0.5 - 2026-08-05

Spell checker, text encoding auto-detection, and Canvas Mode line drawing release.

### Added

- Spell checker support with platform-specific engines and configurable language settings.
- Text encoding auto-detection with UTF-8 fallback strategy.
- Command bar auto-completion with longest-common-prefix (LCP) matching and candidate suggestions.
- Command bar aliases for `diagram`, `snippets`, `border`, and `outline`.
- Windows native file watching (`FindFirstChangeNotificationW`).
- Expanded CJK Unicode scalar range to include CJK Extensions B through I (`0x20000` to `0x3FFFD`).

### Changed

- Canvas Mode line drawing (`Shift+Arrow`) now performs step-by-step line fusion when entering existing box-drawing characters, forming T-junctions or corners on initial entry before creating crossings on subsequent extension steps.
- Table Mode PageUp and PageDown navigation is now constrained within the current table cell boundaries.
- Plain text code blocks in prose formats (Markdown, Org, AsciiDoc, ReST) now highlight in bright blue.

### Fixed

- Markdown syntax highlighting regexes for inline code and emphasis no longer match across table separators or backticks.
- Line-wrapped text now preserves syntax highlighting across softwrapped segments.

## 1.0.4 - 2026-08-04

Windows terminal redraw fix release.

### Fixed

- Windows terminal resize events now trigger an automatic full-screen redraw without waiting for the next keypress.

## 1.0.3 - 2026-08-04

Windows compatibility and installation documentation release.

### Added

- Windows release packaging through `install.ps1`.
- Windows CI coverage for Swift builds and tests.
- README installation guidance for Windows, Arch Linux AUR, Mint, and Linux source builds.
- Tests for Windows UTF-8 console requirements and UTF-16 surrogate pair output.
- Page-down editor input coverage and stronger directory navigation tests.

### Changed

- Terminal raw mode, output, and window-size handling now use Windows-specific implementations where needed.
- Ruler, line-number, and wrap-column display settings are now buffer-local.
- Directory path handling now normalizes paths and expands home-directory input more consistently.
- LOGO drawing commands now accept expression-based distance and heading arguments.
- Canvas Mode page navigation keeps visual-column behavior aligned with canvas movement.

## 1.0.2 - 2026-08-02

Markdown writer workflow and per-buffer mode release.

### Added

- README positioning for zago as a lean terminal forge for Markdown writers.
- Canvas Mode section in the in-app help reference.
- Save-time `trim-trailing-whitespace` setting.
- Table Mode support for using LOGO `FILL` to fill the current table cell.

### Changed

- Text/Canvas/Table runtime mode state is now local to each buffer/editor view.
- Reloading `.zagorc` preserves existing buffer mode state while updating the startup default for new buffers.
- No-argument `BOX` and `DRAWBOX` can frame the active Canvas Mode block mark.
- Shared display-width fill helpers across canvas, table, and LOGO fill paths.

### Fixed

- Markdown syntax highlighting no longer treats list items containing `|` as compact tables.
- `FILL` status messages from delegate-driven fills are preserved after LOGO execution.

## 1.0.1 - 2026-08-02

Preview release update for Homebrew distribution and Canvas Mode safety.

### Added

- Homebrew tap installation instructions with third-party tap trust guidance.
- Linux Homebrew formula support through Homebrew's `swift` build dependency.
- VHS demo sequence assets for documentation.
- Command bar support for `set canvas-mode on`, `set canvas-mode off`, and `unset canvas-mode`.
- Command bar support for `goto row [col]` in addition to numeric `row:col` and `row,col` shorthand.
- Canvas Mode safety limits: auto-created rows and virtual columns are capped at 10,000.

### Changed

- Canvas Mode `goto row [col]` now auto-extends empty rows within the safety limits.
- Text Mode `goto` keeps clamping to the existing buffer and never auto-extends rows.

## 1.0.0 - 2026-08-02

Preview release work for early testers.

### Added

- Text Mode and Canvas Mode editing with keyboard-first navigation.
- Plain-text diagram drawing with boxes, lines, arrows, fills, and tables.
- Editor LOGO command prompt, procedures, variables, loops, and headless script execution.
- CJK-aware paragraph reflow, display width handling, and optional sub-line numbers.
- Emoji-safe display width handling for editor layout, menus, canvas, and table cells.
- Markdown, Org, reStructuredText, and AsciiDoc document link navigation.
- Heading navigation and document outline picker for supported prose formats.
- Syntax highlighting for common code, configuration, prose, and diagram formats.
- Selection-based text transforms and word-count reporting.
- `.zagorc` configuration with key bindings and startup LOGO prelude support.
- Homebrew tap Formula template and tap maintenance guide.

### Changed

- `build.sh` supports configurable install locations through `PREFIX`, `INSTALL_DIR`, and `BINARY_NAME`.

### Known Limitations

- Unicode width behavior can still vary between terminal emulators.
- Document outline support is limited to Markdown, Org, reStructuredText, and AsciiDoc.
- Embedded syntax highlighting is intentionally single-level.
