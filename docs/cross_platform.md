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
- **Windows Console Default Code Page**: Traditional Chinese Windows defaults to **CP950 (Big5)** or OEM Code Pages. Reading `stdin` directly yields garbled text if input is UTF-8.
  - **Solution**: Explicitly set console CP to UTF-8 (`SetConsoleCP(65001)`) and normalize `\r\n` (CRLF) to `\n` (LF) upon reading into `TextBuffer`.

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

## 5. CJK & Emoji Display Width Calculation (`wcwidth`)

### Pitfall
Terminal cell alignment (e.g., Table Mode borders, Canvas Mode cursor placement) depends on accurately calculating character display widths:
- ASCII characters = 1 cell.
- East Asian Fullwidth / CJK characters = 2 cells.
- Emojis / Combining Sequences = 2 cells or 1 cell depending on Unicode standard.

### Solution
- **macOS / Linux**: Calls `wcwidth()` from `Darwin` or `Glibc`/`Musl`.
- **Windows**: `wcwidth()` is unavailable in Win32 C runtime. `TextMetrics` implements custom East Asian Width (EAW) rules and handles Emoji surrogate pairs to return exact terminal cell widths across all platforms.
