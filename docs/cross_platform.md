# Cross-Platform Architecture, Pitfalls & Solutions (`cross_platform.md`)

This document consolidates all cross-platform Gotchas, operating system differences (macOS, Linux, Windows), and their architectural solutions in `zago`.

---

## 1. Terminal Input Handling Across Platforms

### The Problem
Terminal input behavior varies drastically between UNIX-like systems (POSIX `termios`) and Windows (`Win32 Console API`).

| Feature | macOS / Linux (POSIX) | Windows (Win32) |
| :--- | :--- | :--- |
| **Console Mode** | `termios` (`tcgetattr` / `tcsetattr`) | `GetStdHandle(STD_INPUT_HANDLE)` & `SetConsoleMode` |
| **Raw Mode Flags** | `c_lflag &= ~(ICANON \| ECHO \| ISIG)` | Disable `ENABLE_LINE_INPUT \| ENABLE_ECHO_INPUT` |
| **Virtual Sequences**| ANSI Escape Sequences (`\x1b[A`, `\x1b[1;5A`) | Win32 `KEY_EVENT_RECORD` / `wVirtualKeyCode` |
| **Input Reading** | POSIX `read(STDIN_FILENO)` with `VMIN=0` | `ReadConsoleInputW` / `ReadConsoleW` |

### Architectural Solution
`zago` abstracts terminal I/O behind the `EditorTerminal` protocol:
- **macOS / Linux**: Handled by [`PosixTerminal`](file:///Users/zonble/Work/zago/Sources/zago/PosixTerminal.swift). Parses VT100 / xterm ANSI escape sequences into unified `Key` structs (`Key.arrowUp`, `Key.ctrl("s")`, etc.).
- **Windows**: Handled by `WindowsTerminal`. Maps Win32 `VK_*` codes (`VK_LEFT`, `VK_F1`-`VK_F12`, `VK_PRIOR`, `VK_NEXT`) and handles UTF-16 surrogate pairs directly into unified `Key` structs.

---

## 2. Readline & Non-Interactive Input (`ReadWord` / `ReadChar` / Headless Mode)

### Pitfalls & Solutions

#### A. Interactive Console vs Redirected Pipe Detection
When a user pipes input into `zago` (e.g. `echo "hello" | zago` or `zago < input.txt`):
- **macOS / Linux**: Checked via `isatty(STDIN_FILENO)`.
- **Windows**: Win32 `GetFileType(GetStdHandle(STD_INPUT_HANDLE))` distinguishes `FILE_TYPE_CHAR` (interactive console) from `FILE_TYPE_PIPE` or `FILE_TYPE_DISK`.

#### B. Code Page & Line Ending Normalization

##### 1. Interactive Console Input (`SetConsoleCP(65001)`)
The Win32 Console Subsystem maintains two **independent** Code Pages per process:
- `GetConsoleOutputCP()` / `SetConsoleOutputCP()` (Output rendering Code Page)
- `GetConsoleCP()` / `SetConsoleCP()` (Input keyboard/paste Code Page)

**The Gotcha**: Even if the terminal window is configured to render UTF-8 (`SetConsoleOutputCP(65001)`), if `GetConsoleCP()` remains at legacy **CP950 (Big5)** or OEM Code Pages, the OS console layer converts user keyboard entries and pasted text into Big5 bytes before passing them to `stdin`!
- **Solution**: `zago` explicitly calls `SetConsoleCP(65001)` on startup to force the Win32 console subsystem to pass native UTF-8 bytes for interactive input.

##### 2. Redirected Pipe Input (`FILE_TYPE_PIPE`)
Data piped from another process (e.g. `cmd.exe` `type file.txt | zago` or PowerShell `echo "中文" | zago`) is a **raw byte stream** passed directly from the parent process.
- Setting `SetConsoleCP` does **NOT** modify bytes emitted by external parent processes.
- Legacy CMD (`type`) outputs raw Big5 bytes on Traditional Chinese Windows.
- PowerShell 5.1 outputs text encoded in `$OutputEncoding` (often UTF-16 / OEM CP950).
- PowerShell Core 7+ and Git Bash output UTF-8.
- **Solution**: `zago` passes redirected pipe input through its **Multi-Encoding Auto-Detector** ([`encoding.md`](file:///Users/zonble/Work/zago/docs/encoding.md)). It inspects byte signatures (BOM, UTF-8 validity, CP950 double-byte sequences), auto-detects the exact stream encoding, and normalizes line endings (`\r\n` CRLF -> `\n` LF) when building the `TextBuffer`.

#### C. Windows CRLF (`\r\n`) in LOGO Script Parsing (`Int("2\r")` Gotcha)
On Windows, Git checkouts use `core.autocrlf = true` by default, writing `\r\n` line endings to text files and LOGO example scripts (`examples/*.logo`).
- **The Pitfall**: Naive token splitting on whitespace alone can leave trailing `\r` carriage return characters attached to numerical tokens (e.g., `"2\r"`). In Swift, `Int("2\r")` returns `nil`! When fallback `Int(...) ?? 0` is used in arithmetic or bitwise primitives (such as `BIT.XOR`), `nil` becomes `0`, silently corrupting calculation results on Windows!
- **Solution**:
  - `LogoValue.parse` trims `.whitespacesAndNewlines` when tokenizing list items.
  - `parseIntegerArg` in `LogoEngine+MathPrimitives.swift` strips `.whitespacesAndNewlines` before parsing integer values, guaranteeing numeric parsing succeeds consistently across macOS, Linux, and Windows.

---

## 3. File I/O & File Watching Pitfalls

### Gotcha A: Windows File Sharing Restrictions (`Win32Error 32 / ERROR_SHARING_VIOLATION`)
- **Pitfall**: On Windows, Foundation's `data.write(to: url, options: .atomic)` writes to a hidden temporary file and attempts a file handle swap. If an antivirus scanner, indexer, or file watcher holds an open file handle, Windows returns `Win32Error(code: 32)` (`ERROR_SHARING_VIOLATION`).
- **Solution**:
  - In [`LocalEditorFileIOStrategy`](file:///Users/zonble/Work/zago/Sources/zago/LocalEditorFileIOStrategy.swift), non-atomic writes (`options: []`) are used on Windows (`#if os(Windows)`).
  - In Unit Tests, **all temporary files MUST incorporate a `UUID().uuidString`** to prevent path collisions between parallel Swift Testing runners.

### Gotcha B: macOS Atomic Save Inode Unlinking (`kqueue` / `O_EVTONLY`)
- **Pitfall**: Modern macOS text editors (VS Code, Vim, Xcode, TextEdit) save files by **Atomic Replace** (`write temp -> rename temp over target`).
  In macOS `kqueue` (`open(path, O_EVTONLY)`), atomic `rename` unlinks the open file descriptor, emitting `.rename` / `.delete` events to the old inode.
- **Solution**:
  [`FileWatcher`](file:///Users/zonble/Work/zago/Sources/zago/FileWatcher.swift) intercepts `.rename` / `.delete` events and invokes `reopenWatchedFile(at:)`. After a `0.05s` settling delay, it re-opens the file path (binding to the new inode) and triggers the reload prompt.

### Gotcha C: Linux Filesystem Timestamp Resolution (1-Second `mtime` Limit)
- **Pitfall**: On Linux (ext4 / tmpfs in Linux Docker & CI), Foundation's `FileManager.default.attributesOfItem(atPath:)[.modificationDate]` returns `mtime` with **1-second `time_t` integer resolution**. Fast consecutive writes in unit tests occur within milliseconds, resulting in identical `mtime` values.
- **Solution**:
  - `TestLocalEditorFileIOStrategy` monitors a composite snapshot: `(exists, mtime, size)`.
  - Unit tests vary written string lengths (`"v1"`, `"v2 - modified content"`) so file size changes trigger change detection immediately without requiring artificial `Thread.sleep` delays.

### Gotcha D: Windows NTFS Directory Attribute Flush Delay & Self-Save Suppression
- **Pitfall**: On Windows NTFS, writing data to a file updates the file stream immediately, but the OS directory entry metadata (such as `.size` and `.modificationDate` returned by `attributesOfItem(atPath:)`) can have a slight flush delay of a few milliseconds in Win32 directory indices.
  If an editor saves a buffer and restarts file watching, the watcher's background thread (polling 50ms later) reads the newly flushed directory index and misinterprets the editor's **own save** as an "external modification", causing false-alarm reload prompts!
- **Solution**:
  Both [`LocalEditorFileIOStrategy`](file:///Users/zonble/Work/zago/Sources/zago/LocalEditorFileIOStrategy.swift) and `TestLocalEditorFileIOStrategy` invoke `recordCurrentModificationDate()` immediately upon completing `writeTextFile`. This updates the watcher's baseline snapshot `(exists, mtime, size)` to match the post-write state, suppressing self-save false positives consistently across Windows, macOS, and Linux.

---

## 4. Encoding Pitfalls: Big5 / CP950, Emojis, and Silent Data Loss

### The Silent Corruption Gotcha
When attempting to save Unicode text containing modern Emojis (e.g. 🚀, 🇹🇼, ◊, ▲) to legacy double-byte encodings (such as **Big5 / CP950**):
- Big5 contains ZERO mappings for Emojis or modern Unicode symbols.
- **The Bug**: Default C runtime / Win32 `WideCharToMultiByte` and naive String conversion replace unmappable Unicode characters with ASCII `?` (`0x3F`) **without throwing an exception**!
- If left unchecked, saving a file to Big5 silently corrupts all Emojis into `????`!

### Architectural Solution: Strict Roundtrip Validation
In [`LocalEditorFileIOStrategy`](file:///Users/zonble/Work/zago/Sources/zago/LocalEditorFileIOStrategy.swift), `writeTextFile` enforces strict roundtrip verification before touching disk:

```swift
// 1. Encode text string to data
guard let data = contents.data(using: encoding) else {
    throw EncodingError.unsupportedCharacters
}

// 2. Decode data back to string
let roundtrip = String(data: data, encoding: encoding)

// 3. Strict Roundtrip Equality Check
guard roundtrip == contents else {
    // If any character turned into '?' or was lost during encoding conversion, throw error!
    throw EncodingError.unsupportedCharacters
}

// 4. Safe to write
try data.write(to: URL(fileURLWithPath: normalized))
```

If `roundtrip != contents`, `zago` aborts the save and prompts the user with an encoding fallback modal (offering UTF-8 conversion or cancellation).

---

## 5. Line Endings & Path Normalization

### A. Line Endings (`\n` LF vs `\r\n` CRLF)
- **macOS / Linux**: Uses `\n` (LF).
- **Windows**: Files and console stdout/stdin historically use `\r\n` (CRLF).
- **Solution**:
  - `TextBuffer` normalizes all line endings to `\n` in memory (`lines: [String]`).
  - Upon opening a file, `zago` detects `buffer.fileLineEnding` (`.lf` or `.crlf`).
  - Upon saving (`saveFile`), if `fileLineEnding == .crlf`, `zago` joins lines with `\r\n` to preserve original project formatting.

### B. Path Separators (`/` POSIX vs `\` Windows)
- **macOS / Linux**: Uses `/`.
- **Windows**: Uses `\` (e.g., `C:\Users\foo\bar.txt`) or `\\?\` UNC long paths.
- **Solution**:
  - All internal buffer paths and prompt completions standardize on `/`.
  - Disk operations normalize paths using `(path as NSString).standardizingPath`, supporting both `/` and `\` seamlessly on Windows.

---

## 6. Windows Console Virtual Terminal Processing & Window Pop Suppression

### A. Enabling Virtual Terminal Processing on Windows
- Legacy Windows `cmd.exe` does not enable ANSI escape sequence parsing by default.
- **Solution**: On startup, `WindowsTerminal` invokes Win32 `SetConsoleMode` with `ENABLE_VIRTUAL_TERMINAL_PROCESSING` (stdout) and `ENABLE_VIRTUAL_TERMINAL_INPUT` (stdin). If virtual terminal mode cannot be enabled, `zago` falls back gracefully with a `.consoleModeUnavailable` error.

### B. Git Child Process Console Window Pop Suppression (`CREATE_NO_WINDOW`)
- On Windows, spawning sub-processes (e.g. `git diff` or `git status`) via default `Process` can trigger intrusive black `cmd.exe` console window pops.
- **Solution**: The `Git` module sets `CREATE_NO_WINDOW` on Win32 process creation flags and searches `PATH` explicitly for `git.exe`.

---

## 7. Spell Check Engines Across Platforms

Spell checking is abstracted behind the `SpellChecker` protocol:
- **macOS**: Utilizes AppKit / Objective-C runtime `NSSpellChecker`.
- **Windows**: Utilizes native Win32 COM API (`ISpellCheckerFactory` / `ISpellChecker` via `WinSDK`).
- **Linux**: Dynamically links `Hunspell` (C API) or falls back to POSIX word lists (`/usr/share/dict/words`).

---

## 8. Executable Permissions & CJK Display Width

### A. Executable File Permission Detection
- **macOS / Linux**: Reads POSIX permission bits (`S_IXUSR`, `S_IXGRP`, `S_IXOTH`) via `stat()`.
- **Windows**: Windows lacks POSIX `chmod +x` semantics. Execution capability is determined by file extension (`.exe`, `.bat`, `.cmd`, `.ps1`).

### B. CJK & Emoji Display Width Calculation (`wcwidth`)
- **macOS / Linux**: Calls `wcwidth()` from `Darwin` or `Glibc`/`Musl`.
- **Windows**: Win32 C runtime lacks `wcwidth()`. `TextMetrics` calculates display widths based on Unicode East Asian Width (EAW) properties (Wide/Fullwidth = 2 columns, Narrow/Halfwidth = 1 column) and handles Emoji surrogate pair sequences.
