# Changelog

## Unreleased

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
