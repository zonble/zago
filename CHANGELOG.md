# Changelog

## Unreleased

## [1.4.1] - 2026-08-24

Usability, rendering, and interaction release introducing full ANSI SGR 1006 terminal mouse support, directional topology overhaul for Table Cell Detection with CJK wide-character awareness, unified Editor LOGO headless execution, and WebAssembly frontend rendering upgrades.

### Added

- **Full Terminal Mouse Interaction (ANSI SGR 1006)**:
  - Added native mouse interaction across Text Mode, Canvas Mode, Table Mode, Directory Mode, Dialogs, Top Menu Bar, and WebAssembly.
  - Implemented continuous edge auto-scrolling with a two-tier edge-holding acceleration system (60ms boundary rows, 30ms outside window).
  - Implemented decoupled mouse wheel scrolling with terminal hardware cursor off-screen parking and keyboard snapback.
  - Added `set mouse on/off` configuration in `.zagorc` and `--mouse` / `--no-mouse` CLI arguments.
  - Added official [Mouse Interaction Specification](docs/features/mouse.md).
- **WebAssembly & Web Terminal Frontend Upgrades (`zago-web`)**:
  - Integrated `@xterm/addon-unicode11` to standardize CJK and punctuation character widths.
  - Integrated hardware-accelerated `@xterm/addon-webgl` with fallback to `@xterm/addon-canvas` to enforce cell grid clipping and prevent glyph overflow.
  - Added persistent `CacheStorage` caching with HTTP ETag validation for instant WASM streaming loads.
  - Made virtual key bar always visible across all viewport sizes for tablet and mobile touch support.
  - Added full English / Traditional Chinese UI localization and automated Playwright integration smoke tests.

### Changed

- **Editor LOGO & Headless Mode Alignment**:
  - Removed deprecated `APPEND` and `PREPEND` primitives in favor of standard `TYPE`, `PRINT`, `NEWLINE`, and line formatting.
  - Unified headless CLI output (`zago -s` and `zago -e`) with the live editor buffer (`Editor.headlessOutput()`), ensuring box drawings and canvas marks match final buffer state.
- **Table Cell Detection & Topological Directionality**:
  - Added directional boundary character sets (`leftBoundaryChars`, `rightBoundaryChars`, `topBoundaryChars`, `bottomBoundaryChars`) with strict corner exclusion rules.
  - Required strictly continuous horizontal borders without space gaps to prevent false-positive spanning across separated boxes.
  - Required genuine bottom boundaries in downward scanning, preventing broken intermediate rows from being substituted as cell frames.
  - Calculated boundaries using visual terminal columns (`TextMetrics.visualColumn`) rather than logical character offsets to correctly handle 2-column wide CJK characters.
  - Updated [Table Cell Detector Architecture](docs/architecture/table_detector.md).

### Fixed

- **Table Mode & Detection**:
  - Fixed false-positive cell detection when the cursor is placed in whitespace gaps between disconnected boxes.
  - Fixed Table Mode cursor navigation and border alignment when editing cells with CJK full-width characters.
- **Web Terminal**:
  - Fixed CJK corner bracket width rendering in the web terminal by adopting Unicode 11 and WebGL rendering.
- **Keymap Hints**:
  - Prioritized `Ctrl+Z` and `Ctrl+Shift+Z` in menu bar shortcut hints.

## [1.4.0] - 2026-08-21


Major feature release introducing Foundation Measurement conversions and formatters, extensible dialect localization architecture (Traditional Chinese), data detection and codec primitives, procedural docstring introspection, enhanced keymaps, dashed box drawing styles, and CJK-aware syntax highlighting.

### Added

- **Extensible Logo Dialects & Traditional Chinese Localization**:
  - Added `LogoParserPlugin` and `LogoLocalizationRegistry` architecture for registering multilingual LOGO dialects.
  - Implemented `LogoTraditionalChinesePlugin` supporting Chinese keywords for primitives, operators, headings, styles, and natural language filler tokens (`則`, `否則`, `步`, `次`, `成`, `為`, `到`, `至`).
  - Added localized keyword and filler token support in syntax highlighting with Unicode boundary detection, Tab auto-completion, and command introspection.
- **Foundation Measurement & Unit Primitives**:
  - Added `CONVERT.MEASURE` and `FORMAT.MEASURE` supporting 22 measurement dimensions with natural scaling, custom units, and localized dictionary options.
  - Added measurement arithmetic and comparisons: `MEASURE.ADD`, `MEASURE.SUB`, `MEASURE.SCALE`, `MEASURE.EQUAL?`, `MEASURE.LESS?`, `MEASURE.GREATER?`, `MEASURE.MIN`, `MEASURE.MAX`.
- **Foundation Date & Formatting Suite**:
  - Added `DATEFORMAT`, `DATEADD`, `DATEDIFF`, and consolidated formatters (`FORMAT.NUMBER`, `FORMAT.LIST`, `FORMAT.RELATIVETIME`, `FORMAT.BYTES`, `FORMAT.NAME`).
- **Data Detection & Codec Primitives**:
  - Added data detection primitives: `DETECT.URL`, `DETECT.EMAIL`, `DETECT.PHONE`, `DETECT.DATE`, `DETECT.ADDRESS`.
  - Added Base64/Hex/URL codec, UUID operations, and SHA-256/SHA-1/MD5 hashing primitives.
- **Introspection & Help Modal**:
  - Added `DESCRIBE` (`help-command`) and `Describe Key` interactive modal dialog views with Tab auto-completion, scrolling, and primitive metadata inspection.
  - Added procedural docstrings (`TO ... "docstring" ... END`), `DOC`, `ARITY`, `PRIMITIVE?`, and `PROCEDURE?` reporters.
- **Drawing & Canvas Enhancements**:
  - Added dashed border styles (`triple-dash`, `heavy-triple-dash`, `quadruple-dash`, `heavy-quadruple-dash`, `double-dash`, `heavy-double-dash`).
  - Added table mode border style switching and enhanced arrow connectors.
- **Keymap System**:
  - Implemented layered mode-aware `KeymapManager` supporting Classic and Modern presets.
- **Editing & Formatting**:
  - Added paragraph reflow/justify, fill column configuration, and platform-aware line endings.

### Changed

- **Syntax Highlighting Engine**: Upgraded `LogoSyntaxDefinition` and `SyntaxHighlighter` with dynamic dialect registration and Unicode character class boundaries.
- **Primitive Metadata**: Centralized primitive parameter metadata and cross-platform compatibility guards.

## [1.3.1] - 2026-08-14

Linux release build compatibility fix.

### Fixed

- **Linux Release Build**: Updated the release workflow to Swift 6.3.3 and removed a trailing parameter comma that older Linux Swift parsers rejected.

## [1.3.0] - 2026-08-14

Core editor reliability, typed command workflows, and terminal UI improvements.

### Added

- **Command Bar Editing**: Added cut, copy, paste, selection with Shift+Arrow, and Ctrl+X exit behavior.
- **Menu Shortcuts**: Added underlined menu shortcuts and shortcut labels for second-level menu items.
- **IPC Validation**: Added a live IPC roundtrip test for CI.
- **NanoRC Includes**: Added wildcard includes such as `include "/opt/homebrew/share/nano/*.nanorc"`.
- **Homebrew Distribution**: Updated the `zonble/zago` tap formula to build and install `v1.3.0`.

### Changed

- **Editor Architecture**: Split editor models and tests by domain, centralized ANSI styling, and routed command, file, and prompt workflows through typed results.
- **Table Mode**: Restricted navigation, search, replacement, comments, and cursor operations to the active cell.
- **Help Bar**: Added localization and support for rendering beyond 80 columns.

### Fixed

- **File Permissions**: Handled files without read or write permission through the editor file workflow.
- **Terminal Layout**: Fixed tab display widths, directory buffer alignment, and directory buffer cursor positioning when the ruler is enabled.

## [1.2.5] - 2026-08-09

Fix CJK Markdown list softwrap hanging indent terminal cursor positioning and bundle missing `_FoundationICU.dll` in Windows release package.

### Fixed

- **CJK Markdown List Softwrap Cursor (`Renderer.swift`)**: Fixed terminal ANSI cursor positioning for softwrapped Markdown list sublines when `listWrapIndent` is enabled. Correctly added `hangingIndent` width to subline display width calculation so the cursor lands right after line-ending CJK characters.
- **Windows Release Packaging (`release.yml`)**: Added `_Foundation*.dll` and `*icu*.dll` pattern matching to bundle `_FoundationICU.dll` into `zago-windows-x64.zip` release archives.

## [1.2.4] - 2026-08-09

Windows release DLL bundling fix, cross-platform AI skill installer, Canvas mode Ctrl+Arrow arrow line drawing, and outline title truncation.

### Added

- **AI Agent Skill & Installer (`SKILL.md` & `zago --install-skill`)**: Added `zago --install-skill` CLI command to automatically install Editor LOGO AI skill definitions into local user AI directories (`.gemini/config/skills`, `.agents/skills`, `.claude/skills`). Added `.agents/skills/zago/SKILL.md` in repository root.

### Fixed

- **Windows Standalone Packaging & Release DLL Fix (`release.yml`)**: Bundled essential `swift_Concurrency.dll`, `Foundation.dll`, `FoundationEssentials.dll`, `swiftDispatch.dll`, `icudt*.dll`, `icuin*.dll`, `icuuc*.dll`, `vcruntime140.dll`, `vcruntime140_1.dll`, and `msvcp140.dll` into release ZIP archive so `zago.exe` runs seamlessly on clean Windows environments without Swift installed.
- **Canvas Mode (`CanvasModeController.swift`)**: Mapped `Ctrl + Arrow` keys (`Ctrl+Left`, `Ctrl+Right`, `Ctrl+Up`, `Ctrl+Down` and `Ctrl+b/f/p/n`) to draw arrow lines in Canvas mode for Linux and terminal environments.
- **Document Outline View (`DocumentOutlineView.swift`)**: Added automatic ellipsis truncation (`…`) for long heading titles exceeding terminal width, and ensured ESC key exits cleanly without screen artifacts.
- **Markdown Pipe Table Formatting (`PipeTableFormatter.swift`)**: Ignored `+` as border column separator and supported escaped pipes (`\|`).

## [1.2.3] - 2026-08-09

Optimized Windows release archive size by filtering only essential Swift Runtime DLLs.

### Fixed

- **Windows Release Size Optimization (`release.yml`)**: Filtered Windows `.zip` archive to bundle strictly essential Swift Runtime DLLs (`swiftCore`, `swiftFoundation`, `swiftDispatch`, `swiftWinSDK`, `swiftCRT`, `blocksRuntime`), reducing release zip size from ~300MB down to ~12MB by excluding toolchain/compiler binaries.
- **Windows Installer Script (`install.ps1`)**: Ensured all runtime DLLs are copied to `$installDir` and the executable is copied and renamed to `$targetExe` (`zago.exe`).

## [1.2.2] - 2026-08-09

Standalone Windows distribution bundling Swift Runtime DLLs and installer script enhancements.

### Fixed

- **Windows Standalone Packaging (`release.yml`)**: Automated bundling of Swift Runtime DLLs (`swiftCore.dll`, `swiftFoundation.dll`, `swiftDispatch.dll`, etc.) into `zago-windows-x64.zip` for standalone execution on Windows environments without Swift installed.
- **Windows Installer Script (`install.ps1`)**: Updated installer script to copy all bundled DLLs to `$installDir` alongside `zago.exe` and ensure the binary is always renamed to `zago.exe`.

## [1.2.1] - 2026-08-09

On-demand LOGO Output logging and automatic buffer list removal on toggle off.

### Changed

- **On-Demand LOGO Output Buffer**: Running LOGO scripts or commands now logs output history silently in the background without automatically adding `*LOGO Output*` buffer to the active buffer tab list.
- **Auto-Remove on Toggle Off**: Toggling off `*LOGO Output*` (`Alt+L` / `M+L`) switches back to the primary file and removes `*LOGO Output*` from the buffer list, preventing tab bar clutter and exit prompt friction (`^X`).

## [1.2.0] - 2026-08-09

Interactive TUI Markdown Symbol Picker, Logo string manipulation primitives, dedicated Logo Run Menu, and Views directory architecture refactoring.

### Added

- **Markdown Symbol Picker (`SymbolPickerView`)**: Interactive TUI modal dialog window for inserting modern Markdown symbols and GFM callout blocks under Shapes menu (`Insert Symbol...` / `Alt+S` or `symbol` prompt command).
- 4 symbol categories: GFM Callouts (`[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`), Step Indicators (circled numbers/letters, pointers), Status Badges (checkmarks, emojis, rocket, package, inbox, books, team, handshake), Math & UI Keys (`±`, `≠`, `⌘`, `⌥`, `⇧`, `⌃`).
- Quick selection via `a`-`z` direct keyboard shortcuts and uniform selection bar highlight rendering.
- **Logo Engine String Primitives**: `STRING.LEN`, `STRING.SUB`, `STRING.UPPER`, `STRING.LOWER`, `STRING.TITLE`, `STRING.REPLACE`, `STRING.SPLIT`, `STRING.JOIN`, `STRING.TRIM`, `STRING.INDEXOF`, `STRING.CONCAT`.
- **Dedicated Logo Run Menu**: Added `Run` menu bar item for `.logo` files (`Run Script`, `Eval`, `Output Buffer`, `Canvas Buffer`, `Clear`).

### Changed

- Top menu bar automatically deactivates/collapses before presenting modal dialog windows or prompt inputs.
- Refactored modal views directory structure into `Sources/Editor/Views/Dialogs/`.
- Complete internationalization (`L10n`) for all symbol descriptions, dialog labels, categories, and titles in English and Traditional Chinese.

### Fixed

- Fixed file watcher self-save race condition on Windows by synchronizing baseline modification date snapshot updates on serial queues (`queue.sync`).
- Cleaned up documentation, updated `AGENT.md`, and enforced relative markdown links across all documentation files.

## [1.1.1] - 2026-08-07

Extracted `Drawing` & `DocumentOutline` SPM targets, added customizable `ArrowStyle` for Unicode arrows, decoupled `Config` dependencies, and enhanced help documentation.

### Added

- Dedicated SPM targets: `Drawing` (for box/arrow drawing algorithms, junction blending, border styles) and `DocumentOutline` (for heading parsing across Markdown, OrgMode, ReST, AsciiDoc).
- Customizable `ArrowStyle` (`solid` ▲▼◀▶, `stemmed` ↑↓←→, `hollow` △▽◁▷, `small` ▴▾◂▸) for Unicode arrows with `.zagorc` directive (`set arrow <style>`), LOGO DSL integration (`SETARROWSTYLE`, `DEFAULTARROWSTYLE`, `ARROW`), and Menu Bar checkmarks.
- New "CONFIGURABLE SETTINGS VIA 'set / unset' COMMANDS" section in Help Viewer listing all 14 configurable editor options.

### Changed

- Decoupled `Config` target from `LogoEngine` dependency, achieving a clean single-directional DAG architecture.
- Refactored switch/case statements across the codebase to modern Swift 5.9+ switch expressions.
- Updated Traditional Chinese localization to use "畫布模式" (Canvas Mode).
- Cancel Selection menu item (`menu.edit.cancel_selection`) is now visible only when an active selection mark or canvas block mark exists.

## [1.1.0] - 2026-08-07

MVC controller architecture refactoring, per-buffer undo isolation, and automated Debian (.deb) release packaging.

### Added

- Automated Debian (`.deb`) package building and GitHub Release workflow (`build_deb.sh`) for x86_64 and aarch64 Linux targets.
- Unit test for independent per-buffer undo history isolation (`testIndependentBufferUndoStack` and `testSwitchingBufferPreservesPerBufferUndoHistory`).

### Changed

- Refactored all 6 editor controllers (`DocumentOutlineController`, `CanvasModeController`, `SearchController`, `TableModeController`, `PromptController`, `MenuBarController`) to hold weak `editor` references initialized at `Editor.init()`, eliminating redundant `editor` parameter passing.
- `DocumentOutlineController` and `SearchController` now conform to `KeyInputHandler` for keyboard event handling.
- Split `TableModeController` into focused modular files (`TableModeController.swift`, `TableModeController+Navigation.swift`, `TableModeController+Operations.swift`).
- Renamed `Editor+Render.swift` to `Editor+Viewport.swift` and `Editor+DomainCommands.swift` to `Editor+Actions.swift`.

### Fixed

- Moved `undoStack` from global `Editor` state into `TextBuffer`, ensuring each open buffer maintains its own isolated undo history without cross-buffer interference when switching tabs.

## [1.0.5] - 2026-08-05

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

## [1.0.4] - 2026-08-04

Windows terminal redraw fix release.

### Fixed

- Windows terminal resize events now trigger an automatic full-screen redraw without waiting for the next keypress.

## [1.0.3] - 2026-08-04

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

## [1.0.2] - 2026-08-02

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

## [1.0.1] - 2026-08-02

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

## [1.0.0] - 2026-08-02

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
