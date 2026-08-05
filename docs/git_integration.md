# Git Integration & Diff Gutter Specification

This document details the architectural specification and design for Git integration in `zago`.

## Scope & Core Principles

1. **Not a Git Client**: `zago` intentionally does not attempt to be a full-fledged Git GUI (no `commit`, `pull`, `push`, or interactive staging dialogs).
2. **Writer & Developer Focus**: The integration focuses strictly on line-level visual feedback during writing and editing—showing which lines are added, modified, or deleted relative to `HEAD`.
3. **Repository Context**: When a file is opened inside a Git working tree, `zago` displays the active Git branch in the title bar and enables real-time Git diff line number gutter status.

---

## 1. Title Bar Branch Indicator

When `zago` detects that an open file is part of a Git repository, the active branch name is displayed on the right side of the Title Bar next to the modified status indicator.

### Display Rules

- **Modified File with Active Branch**: `[Modified] [branch-name]`
- **Unmodified File with Active Branch**: `[branch-name]`
- **Non-Git File / Unmodified**: `[Modified]` or blank space

### Styling

- The branch name is wrapped in brackets `[branch]` and styled with a distinct ANSI cyan/gray highlight (`\u{1B}[1;36m` / `\u{1B}[90m`) to distinguish it from the modified state badge.
- When switching between open buffers, the title bar instantly updates to reflect that specific file's repository and branch context.

---

## 2. Line Number Gutter (Git Diff Gutter)

The left-hand line number column (Gutter) provides line-by-line visual feedback relative to the file's Git `HEAD` commit.

### Visual Specification & Alignment Rules

1. **Conditional Gutter Width**:
   - **Non-Git File / Disabled Git Diff**: The gutter maintains standard 5-character width (`   42 `), adding zero extra column overhead.
   - **Active Git Diff**: When Git diff status is active, the gutter expands by 1 column to 6 characters (`  +42 `) to accommodate status markers.

2. **Strict Fixed Alignment**:
   - Every single line in the view (unmodified, added, modified, deleted) uses the **exact same fixed gutter width (6 characters)**.
   - Unmodified lines insert a leading space (`  45 `) so that line numbers and text content across all rows remain perfectly aligned vertically without any horizontal jitter.

| Line Status | Line Number Text Color | Marker Symbol | Gutter Text Format | Total Width |
| :--- | :--- | :--- | :--- | :--- |
| **Added Line** | Green (`\u{1B}[32m` / `\u{1B}[92m`) | `+` (Green Plus) | `  +42 ` (Green text) | 6 chars |
| **Modified Line** | Yellow / Amber (`\u{1B}[33m` / `\u{1B}[93m`) | `~` (Yellow Tilde) | `  ~43 ` (Yellow text) | 6 chars |
| **Deleted Line** | Red Indicator (`\u{1B}[31m` / `\u{1B}[91m`) | `-` (Red Minus) | `  -44 ` (Red marker) | 6 chars |
| **Unmodified Line** | Dim Gray (`\u{1B}[90m`) | Space | `   45 ` (Dim Gray text) | 6 chars |

### Real-Time In-Memory Diffing

- **Live Comparison Against HEAD**: The line status is computed in real-time by comparing the editor's live in-memory buffer (including unsaved typing) against the `HEAD` snapshot.
- **Instant Feedback**: Newly typed lines instantly turn green (`+`), modified lines instantly turn yellow (`~`), and deletions show a red marker without requiring a save (`:w`).

---

## 3. Git Engine Architecture

`zago` introduces a decoupled `GitService` module:

```text
Sources/
  Git/
    GitService.swift             # Main Git provider & background worker
    GitDiffEngine.swift           # Line-by-line diff calculator
    GitRepositoryInfo.swift      # Repository path & branch metadata
```

### 1. Repository & Branch Detection
- Searches parent directories for `.git` or executes `git rev-parse --show-toplevel`.
- Resolves current branch name asynchronously via `git branch --show-current` or by reading `.git/HEAD`.

### 2. Base Version Fetching (`HEAD`)
- Asynchronously reads the `HEAD` blob using `git show HEAD:<relative_path>`.
- Caches base lines for fast in-memory comparison during active editing sessions.

### 3. Line Diff Calculation
- Uses an efficient Myers/Patience diff algorithm to match live buffer lines against base `HEAD` lines.
- Produces a map of `[bufferLineIndex: LineStatus]`.

---

## 4. Configuration & User Control

Git integration is enabled automatically when opening files inside a Git repository and can be configured via `.zagorc`:

### `.zagorc` Directives

```nanorc
# Enable or disable Git diff line gutter coloring
set git-diff on
set git-diff off
```

### Command Bar & Menu Bar Toggles

- **Command Bar**: `set git-diff on`, `set git-diff off`, or `toggle git-diff`.
- **Menu Bar**: Toggleable under the View/Display menu category.

---

## 5. Testing & Validation Strategy

1. **Unit Tests**:
   - `GitDiffEngineTests`: Verify line status mapping for added, modified, deleted, and unmodified lines.
   - `TitleBarGitTests`: Verify `[Modified] [branch]` title bar formatting.
   - `GutterRenderTests`: Verify ANSI color codes and marker symbols in `renderLineNumberGutter`.
2. **Performance Validation**:
   - Ensure diff computation runs asynchronously so editing 10,000-line files remains smooth without UI latency.
