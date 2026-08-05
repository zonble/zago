# Spell Checker Architecture & Specification

This document defines the architecture, cross-platform engine design, and configuration specifications for `zago`'s spell checking system.

---

## Overview

`zago` is a multi-platform terminal Markdown editor for writers, technical documentation authors, and AI agent CLI workflows across macOS, Linux, and Windows.

The spell check system (`^T` / `F12` / Menu) provides real-time and interactive spelling verification without assuming English-only documents or relying on Unix-specific `/usr/share/dict/words` file paths.

---

## Core Principles & Goals

1. **Multi-Language Support**:
   - Support user-configurable document languages (e.g. `en_US`, `en_GB`, `de_DE`, `fr_FR`, `es_ES`).
   - Automatically ignore non-Latin / CJK (Chinese, Japanese, Korean) characters without false positives.

2. **Native Platform Engines**:
   - **Windows**: Use native **Windows Spell Checking COM API** (`ISpellCheckerFactory` / `ISpellChecker`), leveraging Windows system dictionaries and suggestion engines without requiring external dependencies.
   - **macOS & Linux**: Use **Hunspell** dictionaries (`/usr/share/hunspell`, `/usr/share/myspell`, `~/.hunspell`) or macOS native `NSSpellChecker`.
   - **Fallback**: Configurable embedded wordlist engine when no OS dictionary is installed.

3. **Markdown & Code Context Filtering**:
   - Skip fenced code blocks (``` ... ```), inline code (`...`), URLs, Markdown link targets, and Editor LOGO commands (`DRAWBOX`, `GOTO`, etc.) to eliminate false positives in technical writing.

4. **Iterative Interactive Check Flow**:
   - Continuously prompt misspelled words sequentially (`[Replace]`, `[Skip]`, `[Ignore All]`, `[Add to User Dict]`) until the document is checked, rather than stopping after the first occurrence.

5. **Configuration Directives (`.zagorc`)**:
   - Configurable via `set spell-language <lang>` (or `set spell-lang <lang>`).

---

## Architecture Design

### `SpellCheckerEngine` Protocol

```swift
public struct MisspelledMatch {
    public let line: Int
    public let col: Int
    public let word: String
}

public protocol SpellCheckerEngine {
    /// Active language tag (e.g. "en_US", "de_DE", "fr_FR")
    var language: String { get set }

    /// Checks whether a clean word is spelled correctly
    func isCorrect(_ word: String) -> Bool

    /// Generates suggestion candidates for a misspelled word
    func suggestions(for word: String) -> [String]

    /// Temporarily ignores a word for the current editing session (Ignore All)
    func ignoreWord(_ word: String)

    /// Adds a word to the user dictionary
    func addWordToDictionary(_ word: String)

    /// Scans the buffer starting at (line, col) to find the next misspelled word
    func findNextMisspelled(
        in buffer: TextBuffer,
        startingAt line: Int,
        col: Int
    ) -> MisspelledMatch?
}
```

---

## Engine Implementations

### 1. `WindowsSpellCheckerEngine` (Windows 8 / 10 / 11)
- Uses Win32 COM `CoCreateInstance(CLSID_SpellCheckerFactory, ...)` to instantiate `ISpellChecker`.
- Leverages OS-installed language packages and system dictionaries.
- Supports native `Suggest()` for correction candidates.

### 2. `HunspellCheckerEngine` (Linux / macOS)
- Scans system Hunspell paths (`/usr/share/hunspell/<lang>.dic`, `~/.hunspell/<lang>.dic`).
- Parses `.dic` / `.aff` files or binds `libhunspell`.

### 3. `FallbackCheckerEngine` (Cross-platform Fallback)
- Embedded wordlist for basic offline spell checking when no OS dictionary is available.

---

## Configuration Directives (`.zagorc`)

```nanorc
# Set document spell checker language (e.g. en_US, de_DE, fr_FR, es_ES)
set spell-language en_US
# Short alias:
# set spell-lang de_DE

# Enable or disable spell checking (on / off)
set spellcheck on
```

---

## Development Milestones

| Milestone | Target |
| :--- | :--- |
| **Phase 1: Architecture Abstraction** | Define `SpellCheckerEngine` protocol, update `ConfigLoader` with `spell-language` directive. |
| **Phase 2: Windows Native Engine** | Implement `WindowsSpellCheckerEngine` via Win32 COM API on Windows. |
| **Phase 3: Hunspell & macOS Engine** | Implement `HunspellCheckerEngine` and macOS `NSSpellChecker` integration. |
| **Phase 4: Markdown Context Filtering** | Add context parser to skip code blocks, inline code, URLs, and LOGO code. |
| **Phase 5: Interactive UX & Session List** | Implement continuous loop with `Replace`, `Skip`, `Ignore All`, and `Add to Dictionary`. |
