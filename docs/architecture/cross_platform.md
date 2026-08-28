# Cross-Platform Architecture, Pitfalls & Solutions (`cross_platform.md`)

This document consolidates all cross-platform Gotchas, operating system
differences (macOS, Linux, Windows), and their architectural solutions in
`zago`.

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

- **macOS / Linux**: Handled by
  [`PosixTerminal`](../../Sources/zago/Terminal/PosixTerminal.swift). Parses
  VT100 / xterm ANSI escape sequences into unified `Key` structs (`Key.arrowUp`,
  `Key.ctrl("s")`, etc.).
- **Windows**: Handled by
  [`WindowsTerminal`](../../Sources/zago/Terminal/WindowsTerminal.swift). Maps
  Win32 console input, handles UTF-16 surrogate pairs, and decodes SGR 1006 ANSI mouse
  sequences (`\x1b[<...M/m`) directly into unified `InputEvent` structs.

### C. Windows Terminal SGR Mouse Tracking & QuickEdit Mode Interception

- **The Problem**: In Windows Terminal, when mouse tracking mode is enabled (`\x1b[?1000h\x1b[?1006h`), mouse clicks, drags, and scrolling events send SGR 1006 escape sequences (e.g. `\x1b[<0;20;10M`). If the terminal input reader only handles keystrokes and treats `\x1b` as a standalone `.esc` key, the remaining sequence characters (e.g. `0;20;10M`) are mistakenly treated as keyboard text input and inserted as garbled text into the editor buffer. Additionally, legacy Windows Console QuickEdit Mode (`ENABLE_QUICK_EDIT_MODE`) intercepts mouse clicks for text selection rather than passing them to the application.
- **Solution**:
  - `WindowsTerminal.enableRawMode()` clears `ENABLE_QUICK_EDIT_MODE` and sets `ENABLE_EXTENDED_FLAGS` along with `ENABLE_WINDOW_INPUT` and `ENABLE_MOUSE_INPUT`.
  - `WindowsTerminal.readInputEvent()` buffers incoming characters and parses SGR 1006 mouse sequences into structured `InputEvent.mouse(MouseEvent)` instances (supporting left/middle/right click, release, drag, and wheel up/down).
  - Keystroke-only readers (`readKey()`) discard orphaned mouse sequence units to prevent text buffer pollution.

---

## 2. Windows Console Virtual Terminal Processing & Window Pop Suppression

### A. Enabling Virtual Terminal Processing on Windows

- Legacy Windows `cmd.exe` does not enable ANSI escape sequence parsing by
  default.
- **Solution**: On startup, `WindowsTerminal` invokes Win32 `SetConsoleMode`
  with `ENABLE_VIRTUAL_TERMINAL_PROCESSING` (stdout) and
  `ENABLE_VIRTUAL_TERMINAL_INPUT` (stdin). If virtual terminal mode cannot be
  enabled, `zago` falls back gracefully with a `.consoleModeUnavailable` error.

### B. Git Child Process Console Window Pop Suppression (`CREATE_NO_WINDOW`)

- On Windows, spawning sub-processes (e.g. `git diff` or `git status`) via
  default `Process` can trigger intrusive black `cmd.exe` console window pops.
- **Solution**: The `Git` module sets `CREATE_NO_WINDOW` on Win32 process
  creation flags and searches `PATH` explicitly for `git.exe`.

---

## 3. Readline & Non-Interactive Input (`ReadWord` / `ReadChar` / Headless Mode)

### Pitfalls & Solutions

#### A. Interactive Console vs Redirected Pipe Detection

When a user pipes input into `zago` (e.g. `echo "hello" | zago` or `zago < input.txt`):

- **macOS / Linux**: Checked via `isatty(STDIN_FILENO)`.
- **Windows**: Win32 `GetFileType(GetStdHandle(STD_INPUT_HANDLE))` distinguishes
  `FILE_TYPE_CHAR` (interactive console) from `FILE_TYPE_PIPE` or
  `FILE_TYPE_DISK`.

#### B. Code Page & Line Ending Normalization

##### 1. Interactive Console Input (`SetConsoleCP(65001)`)

The Win32 Console Subsystem maintains two **independent** Code Pages per
process:

- `GetConsoleOutputCP()` / `SetConsoleOutputCP()` (Output rendering Code Page)
- `GetConsoleCP()` / `SetConsoleCP()` (Input keyboard/paste Code Page)

**The Gotcha**: Even if the terminal window is configured to render UTF-8
(`SetConsoleOutputCP(65001)`), if `GetConsoleCP()` remains at legacy **CP950
(Big5)** or OEM Code Pages, the OS console layer converts user keyboard entries
and pasted text into Big5 bytes before passing them to `stdin`!

- **Solution**: `zago` explicitly calls `SetConsoleCP(65001)` on startup to
  force the Win32 console subsystem to pass native UTF-8 bytes for interactive
  input.

##### 2. Redirected Pipe Input (`FILE_TYPE_PIPE`)

Data piped from another process (e.g. `cmd.exe` `type file.txt | zago` or
PowerShell `echo "中文" | zago`) is a **raw byte stream** passed directly from
the parent process.

- Setting `SetConsoleCP` does **NOT** modify bytes emitted by external parent
  processes.
- Legacy CMD (`type`) outputs raw Big5 bytes on Traditional Chinese Windows.
- PowerShell 5.1 outputs text encoded in `$OutputEncoding` (often UTF-16 / OEM
  CP950).
- PowerShell Core 7+ and Git Bash output UTF-8.
- **Solution**: `zago` passes redirected pipe input through its **Multi-Encoding
  Auto-Detector** ([`encoding.md`](../features/encoding.md)). It inspects byte
  signatures (BOM, UTF-8 validity, CP950 double-byte sequences), auto-detects
  the exact stream encoding, and normalizes line endings (`\r\n` CRLF -> `\n`
  LF) when building the `TextBuffer`.

#### C. Windows CRLF (`\r\n`) in LOGO Script Parsing (`Int("2\r")` Gotcha)

On Windows, Git checkouts use `core.autocrlf = true` by default, writing `\r\n`
line endings to text files and LOGO example scripts (`examples/logo/*.logo`).

- **The Pitfall**: Naive token splitting on whitespace alone can leave trailing
  `\r` carriage return characters attached to numerical tokens (e.g., `"2\r"`).
  In Swift, `Int("2\r")` returns `nil`! When fallback `Int(...) ?? 0` is used in
  arithmetic or bitwise primitives (such as `BIT.XOR`), `nil` becomes `0`,
  silently corrupting calculation results on Windows!
- **Solution**:
    - `LogoValue.parse` trims `.whitespacesAndNewlines` when tokenizing list
      items.
    - `parseIntegerArg` in `LogoEngine+MathPrimitives.swift` strips
      `.whitespacesAndNewlines` before parsing integer values, guaranteeing
      numeric parsing succeeds consistently across macOS, Linux, and Windows.

---

## 4. File I/O & File Watching Pitfalls

### Gotcha A: Windows File Sharing Restrictions (`Win32Error 32 / ERROR_SHARING_VIOLATION`)

- **Pitfall**: On Windows, Foundation's `data.write(to: url, options: .atomic)`
  writes to a hidden temporary file and attempts a file handle swap. If an
  antivirus scanner, indexer, or file watcher holds an open file handle, Windows
  returns `Win32Error(code: 32)` (`ERROR_SHARING_VIOLATION`).
- **Solution**:
    - In
      [`LocalEditorFileIOStrategy`](../../Sources/zago/FileSystem/LocalEditorFileIOStrategy.swift),
      non-atomic writes (`options: []`) are used on Windows (`#if os(Windows)`).
    - In Unit Tests, **all temporary files MUST incorporate a
      `UUID().uuidString`** to prevent path collisions between parallel Swift
      Testing runners.

### Gotcha B: macOS Atomic Save Inode Unlinking (`kqueue` / `O_EVTONLY`)

- **Pitfall**: Modern macOS text editors (VS Code, Vim, Xcode, TextEdit) save
  files by **Atomic Replace** (`write temp -> rename temp over target`). In
  macOS `kqueue` (`open(path, O_EVTONLY)`), atomic `rename` unlinks the open
  file descriptor, emitting `.rename` / `.delete` events to the old inode.
- **Solution**:
  [`DarwinFileWatcher`](../../Sources/FileWatcher/FileWatcher+Darwin.swift)
  intercepts `.rename` / `.delete` events and invokes `reopenWatchedFile(at:)`.
  After a `0.05s` settling delay, it re-opens the file path (binding to the new
  inode) and triggers the reload prompt.

### Gotcha C: Linux Filesystem Timestamp Resolution (1-Second `mtime` Limit)

- **Pitfall**: On Linux (ext4 / tmpfs in Linux Docker & CI), Foundation's
  `FileManager.default.attributesOfItem(atPath:)[.modificationDate]` returns
  `mtime` with **1-second `time_t` integer resolution**. Fast consecutive writes
  in unit tests occur within milliseconds, resulting in identical `mtime`
  values.
- **Solution**:
    - `TestLocalEditorFileIOStrategy` monitors a composite snapshot: `(exists,
      mtime, size)`.
    - Unit tests vary written string lengths (`"v1"`, `"v2 - modified content"`)
      so file size changes trigger change detection immediately without
      requiring artificial `Thread.sleep` delays.

### Gotcha D: Windows NTFS Directory Attribute Flush Delay & Self-Save Race Suppression

- **Pitfall**: On Windows NTFS, writing data to a file updates the file stream
  immediately, but the OS directory entry metadata (such as `.size` and
  `.modificationDate` returned by `attributesOfItem(atPath:)`) can have a slight
  flush delay of a few milliseconds in Win32 directory indices. Furthermore, if
  `recordCurrentModificationDate()` runs asynchronously without thread
  synchronization, a background file watcher thread (polling every 50ms) can
  inspect `attributesOfItem(atPath:)` after `data.write` creates or modifies the
  file on disk, but *before* `recordCurrentModificationDate()` updates the
  baseline snapshot on the main thread. This race condition misinterprets the
  editor's **own save** as an "external modification", causing false-alarm
  reload prompts (`.confirmExternalReload`) on Windows!
- **Solution**: Both
  [`LocalEditorFileIOStrategy`](../../Sources/zago/FileSystem/LocalEditorFileIOStrategy.swift)
  and `TestLocalEditorFileIOStrategy` invoke `recordCurrentModificationDate()`
  immediately upon completing `writeTextFile`. Windows uses a separate
  `stateLock` for snapshot updates because its watcher worker owns a
  long-running background loop; using `queue.sync` from the editor thread would
  deadlock while that loop is active.

### Gotcha E: Swift Foundation Relative Path URL Resolution on Windows (`file:///filename` Root Fallback)

- **Pitfall**: In Swift Foundation on Windows, calling `URL(fileURLWithPath: "filename")` does **NOT** resolve against the current working directory (`FileManager.default.currentDirectoryPath`). Instead, Foundation treats `"filename"` as a relative URL whose absolute path component is `/filename`, mapping directly to the **root of the drive** (e.g. `C:\filename`).
  - When a user ran `zago filename`, the editor searched for `C:\filename` and failed to find the file in the current terminal directory.
  - When creating a new file (`zago newfile.txt`), saving attempted to write to `C:\newfile.txt`. Since drive roots require Administrator privileges, the write failed and triggered the safe fallback prompt, redirecting the save to the user's home directory (`~\`).
- **Solution**: In [`LocalEditorFileIOStrategy`](../../Sources/zago/FileSystem/LocalEditorFileIOStrategy.swift), `normalizePath` verifies if a path is absolute (checking for Windows drive letters `C:\`, UNC `\\`, rooted `/` or `\`, and POSIX `/`). All relative paths are explicitly joined with `currentDirectoryPath()` before passing to `URL(fileURLWithPath:).standardizedFileURL.path`.

### Gotcha F: Cloud Sync & Virtual Drives (Google Drive, OneDrive) Atomic Write Failure

- **Pitfall**: Foundation's `data.write(to: url, options: .atomic)` writes to a temporary file and uses Win32 `ReplaceFileW` / `MoveFileExW` to atomically replace the destination file. Cloud storage virtual file systems (such as Google Drive for Desktop `G:\My Drive` using Dokany / WinFsp, OneDrive Files On-Demand, and SMB network shares) do **NOT** support atomic file replacement semantics, returning `ERROR_ACCESS_DENIED` (5) or `ERROR_INVALID_FUNCTION` (1). This caused saving any file in `G:\My Drive\...` to fail and prompt the user to save to `~\`.
- **Solution**: On Windows (`#if os(Windows)`), `LocalEditorFileIOStrategy.writeTextFile` uses direct file writing (`options: []`). If direct writing encounters temporary handle constraints, it safely attempts direct stream writes without auxiliary atomic swaps.

### Gotcha G: `WindowsFileWatcher` Synchronous Directory Handle Release (`queue.sync`)

- **Pitfall**: When saving a file, `LocalEditorFileIOStrategy` invokes `fileWatcher.stop()` followed by `writeTextFile(...)`. On Windows, `WindowsFileWatcher` monitors directories using `FindFirstChangeNotificationW`. If `stop()` only signals the cancel event asynchronously without waiting for the background queue to exit, the directory handle remains open momentarily, causing subsequent file write or rename operations to fail with `ERROR_SHARING_VIOLATION` (32).
- **Solution**: `WindowsFileWatcher.stop()` performs `queue.sync {}` after signaling `stopEventHandle`, ensuring that `FindCloseChangeNotification` and `CloseHandle` have completed synchronously before any subsequent file write begins.

---

## 5. Line Endings & Path Normalization

### A. Line Endings (`\n` LF vs `\r\n` CRLF)

- **macOS / Linux**: Uses `\n` (LF).
- **Windows**: Files and console stdout/stdin historically use `\r\n` (CRLF).
- **Solution**:
    - `TextBuffer` normalizes all line endings to `\n` in memory (`lines: [String]`).
    - Upon opening a file, `zago` detects `buffer.fileLineEnding` (`.lf` or `.crlf`).
    - Upon saving (`saveFile`), if `fileLineEnding == .crlf`, `zago` joins lines
      with `\r\n` to preserve original project formatting.

### B. Path Separators (`/` POSIX vs `\` Windows)

- **macOS / Linux**: Uses `/`.
- **Windows**: Uses `\` (e.g., `C:\Users\foo\bar.txt`, `G:\My Drive\Blog\test.md`) or `\\?\` UNC long paths.
- **Solution**:
    - Swift Foundation's `URL.path` normalizes paths with forward slashes `/` across platforms.
    - On Windows, `LocalEditorFileIOStrategy` normalizes paths to native backslashes (`\`) for all buffer file paths (`buffer.filePath`), title bars, status bars, and directory helpers (`childPath`, `parentDirectory`). Disk operations normalize paths seamlessly regardless of separator format.

---

## 6. Encoding Pitfalls: Big5 / CP950, Emojis, and Silent Data Loss

### The Silent Corruption Gotcha

When attempting to save Unicode text containing modern Emojis (e.g. 🚀, 🇹🇼, ◊,
▲) to legacy double-byte encodings (such as **Big5 / CP950**):

- Big5 contains ZERO mappings for Emojis or modern Unicode symbols.
- **The Bug**: Default C runtime / Win32 `WideCharToMultiByte` and naive String conversion replace unmappable Unicode characters with ASCII `?` (`0x3F`) **without throwing an exception**!
- If left unchecked, saving a file to Big5 silently corrupts all Emojis into `????`!

### Architectural Solution: Strict Roundtrip Validation

In [`LocalEditorFileIOStrategy`](../../Sources/zago/FileSystem/LocalEditorFileIOStrategy.swift), `writeTextFile` enforces strict roundtrip verification before touching disk:

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

If `roundtrip != contents`, `zago` aborts the save and prompts the user with an
encoding fallback modal (offering UTF-8 conversion or cancellation).

---

## 7. Executable Permissions & CJK Display Width

### A. Executable File Permission Detection

- **macOS / Linux**: Reads POSIX permission bits (`S_IXUSR`, `S_IXGRP`,
  `S_IXOTH`) via `stat()`.
- **Windows**: Windows lacks POSIX `chmod +x` semantics. Execution capability is
  determined by file extension (`.exe`, `.bat`, `.cmd`, `.ps1`).

### B. CJK & Emoji Display Width Calculation (`wcwidth`)

- **macOS / Linux**: Calls `wcwidth()` from `Darwin` or `Glibc`/`Musl`.
- **Windows**: Win32 C runtime lacks `wcwidth()`. `TextMetrics` calculates
  display widths based on Unicode East Asian Width (EAW) properties
  (Wide/Fullwidth = 2 columns, Narrow/Halfwidth = 1 column) and handles Emoji
  surrogate pair sequences.

---

## 8. Spell Check Engines Across Platforms

Spell checking is abstracted behind the `SpellChecker` protocol:

- **macOS**: Utilizes AppKit / Objective-C runtime `NSSpellChecker`.
- **Windows**: Utilizes native Win32 COM API (`ISpellCheckerFactory` /
  `ISpellChecker` via `WinSDK`).
- **Linux**: Dynamically links `Hunspell` (C API) or falls back to POSIX word
  lists (`/usr/share/dict/words`).

---

## 9. Platform-Specific Foundation APIs

### Unavailable Formatters & Detectors

`RelativeDateTimeFormatter` is available in the Apple Foundation implementations
used by macOS, but is not available in the Foundation implementations used by
Linux or Windows. The relative-time formatter entry points in
[`LogoFormatters.swift`](../../Sources/LogoEngine/Formatting/LogoFormatters.swift)
are therefore compiled as disabled stubs on Linux and Windows. The keyword and
metadata remain available for scripts and documentation, but execution reports a
platform-not-supported Logo error. The Apple implementation keeps Foundation's
locale-aware behavior for all supported locales.

`ListFormatter` has the same platform limitation. `FORMAT.LIST` remains present
in the keyword and metadata, but execution reports a platform-not-supported Logo
error on Linux and Windows.

`NSDataDetector` is also unavailable in the Foundation implementations used by
Linux and Windows. The `DETECT.URL`, `DETECT.EMAIL`, `DETECT.PHONE`,
`DETECT.DATE`, and `DETECT.ADDRESS` keywords remain available for completion and
metadata, but execution reports a platform-not-supported Logo error on those
platforms. Apple platforms use the system detector and return the original
matched substrings as a Logo list.

`MeasurementFormatter` is explicitly marked unavailable in `swift-corelibs-foundation`
on Linux and Windows (`@available(*, unavailable, message: "Not supported in swift-corelibs-foundation")`).
The `FORMAT.MEASURE` primitive remains present in the keywords and metadata for
documentation and completions, but execution reports a platform-not-supported Logo error on
Linux and Windows while performing full locale-aware unit formatting on Apple platforms.

`PersonNameComponentsFormatter` is also unavailable in `swift-corelibs-foundation`
on Linux and Windows (`@available(*, unavailable, message: "Person name components formatting isn't available in swift-corelibs-foundation")`).
The `FORMAT.NAME` (and alias `FORMATNAME`) primitive remains present in the keywords
and metadata for documentation and completions, but execution reports a
platform-not-supported Logo error on Linux and Windows while performing full
locale-aware name formatting on macOS.

### Foundation `Measurement` (Unit Conversion) & `swift-corelibs-foundation` Discrepancies

`Measurement<UnitType: Dimension>` (unit conversion via `CONVERT.MEASURE`) is supported across macOS,
Linux, and Windows, but developers should be aware of the following differences:

1. **Unit Constant Precision Differences**:
   - `UnitLength.miles`: Apple Foundation uses the exact International Mile
     coefficient ($1609.344\text{ m}$), yielding exactly $5280\text{ ft}$ per
     mile. `swift-corelibs-foundation` on Linux/Windows historically used
     $1609.34\text{ m}$, yielding $5279.98687664\text{ ft}$.
   - `UnitArea.squareFeet`: Apple Foundation uses International Foot squared
     ($0.09290304\text{ m}^2$, giving $10.763910417\text{ sqft/m}^2$).
     `swift-corelibs-foundation` used US Survey Foot squared
     ($0.0929034116\text{ m}^2$, giving $10.763915051\text{ sqft/m}^2$).
   - **Testing Rule**: When asserting unit conversion results in unit tests
     (e.g.
     [`LogoMeasurementTests.swift`](../../Tests/LogoMeasurementTests.swift)),
     never use hard-coded full-precision string equality across platforms. Use
     floating-point delta checks (`abs(val - expected) < tolerance`) or prefix
     matching.

2. **Missing Static Properties in Linux Foundation (Commit `747bd57`)**:
   - `UnitFrequency.framesPerSecond` is defined on Apple platforms (macOS
     10.15+) but omitted from `swift-corelibs-foundation`.
   - Directly referencing `.framesPerSecond` causes Linux/Windows CI build
     failures: `error: type 'UnitFrequency' has no member 'framesPerSecond'`.
   - **Solution**: Avoid relying on Apple-specific static property extensions.
     Instantiate portable unit instances using `UnitConverterLinear`:

     ```swift
     reg(
         UnitFrequency(symbol: "fps", converter: UnitConverterLinear(coefficient: 1.0)),
         ["fps", "framespersecond"]
     )
     ```

3. **C Library Functions vs Swift Standard Library (Commit `d2d98ba`)**:
   - Do not call `Darwin.round()` directly as the `Darwin` module does not exist
     on Linux or Windows (`error: cannot find 'Darwin' in scope`).
   - **Solution**: Use portable Swift Standard Library `Double.rounded()`, or
     wrap platform-specific C calls in `#if canImport(Darwin)` / `#if
     canImport(Glibc)` guards.

When adding Foundation-backed Logo primitives, check API availability on every
CI target before sharing the implementation across platforms. Do not replace a
platform formatter with a hand-maintained language list just to make it compile.

---

## 10. C Socket API Types: Linux Glibc vs Darwin (`SOCK_STREAM`)

### Pitfall & Solution

#### The Gotcha: C Header Binding Type Mismatch

In C socket header bindings:

- **macOS (Darwin)**: `SOCK_STREAM` is defined as a C macro constant of type
  `Int32` (value `1`). Calling `socket(AF_UNIX, SOCK_STREAM, 0)` accepts `Int32`
  arguments directly.
- **Linux (Glibc)**: In Swift's `Glibc` module bindings, `SOCK_STREAM` is
  imported as a C enum of type `__socket_type`. Passing `SOCK_STREAM` directly
  to C's `socket(Int32, Int32, Int32)` on Linux triggers a compiler error:
  `error: cannot convert value of type '__socket_type' to expected argument type
  'Int32'`.

#### Architectural Solution

In [`ZagoIPCServer.swift`](../../Sources/IPCServer/ZagoIPCServer.swift),
conditional compilation converts `SOCK_STREAM` portably across platforms:

```swift
#if canImport(Glibc)
let sockType = Int32(SOCK_STREAM.rawValue)
#else
let sockType = Int32(SOCK_STREAM)
#endif
let fd = socket(Int32(AF_UNIX), sockType, 0)
```

This guarantees strict type safety when compiling C socket code under Swift 6 on
macOS, Linux (Glibc), and Musl environments.

---

## 11. Natural Language Word Breaking & CJK Segmentation (`byWords` vs Non-Darwin Fallback)

### The Problem

Terminal word navigation (`Alt+F` / `Alt+B`, `moveWordForward()` / `moveWordBackward()`) and word metrics rely on finding word boundaries in text containing mixed Latin and CJK prose:

1. **`NSString.EnumerationOptions.byWords` Unavailable on Linux / Windows**:
   `byWords` is explicitly marked unavailable in `swift-corelibs-foundation` (`@available(*, unavailable, message: "Enumeration by words isn't supported in swift-corelibs-foundation")`). Calling it on Linux or Windows fails at compile time.
2. **Dictionary vs Rule-Based Segmentation**:
   - **macOS (Darwin)**: `enumerateSubstrings(options: .byWords)` delegates to Apple's CoreFoundation / ICU dictionary lexicon, segmenting CJK compounds into semantic words (e.g. `"「你好世界」"` is segmented into `"你"`, `"好"`, `"世界"`).
   - **Linux / Windows**: Lacks the Apple proprietary CJK lexicon dictionary in open-source Foundation.

### Architectural Solution

In [`TextAnalyzer.swift`](../../Sources/TextTransform/TextAnalyzer.swift), `TextAnalyzer.wordRanges(in:)` branches by platform:

```swift
#if canImport(Darwin)
// Darwin: Uses native ICU dictionary-backed word enumeration
text.enumerateSubstrings(in: text.startIndex..., options: [.byWords, .substringNotRequired]) { _, range, _, _ in
    ...
}
#else
// Non-Darwin: Portable unicode boundary scanning
// - Latin / ASCII words: continuous word character sequences ([a-zA-Z0-9_]+)
// - CJK Ideographs: each discrete CJK character is an individual word boundary
for character in text {
    if TextUnicodeClassifier.isCJKScriptCharacter(character) {
        if let start = wordStart {
            ranges.append(start..<index)
            wordStart = nil
        }
        ranges.append(index..<(index + 1))
    } else if TextUnicodeClassifier.isUnicodeWordCharacter(character) {
        if wordStart == nil { wordStart = index }
    } else {
        if let start = wordStart {
            ranges.append(start..<index)
            wordStart = nil
        }
    }
    index += 1
}
#endif
```

### Testing Strategy

In [`TextBufferTests.swift`](../../Tests/TextBufferTests.swift), `testCJKWordNavigation` uses `#if canImport(Darwin)` to verify dictionary-segmented stops (`2 -> 3 -> 5`) on macOS and `#else` to verify per-character discrete stops (`2 -> 3 -> 4 -> 5`) on Linux and Windows.

---

## 12. Non-Darwin Foundation `Locale` & `NumberFormatter` (`Locale.autoupdatingCurrent` Crash)

### The Pitfall: `NSAutoLocale` Lacks `_cfObject` in `swift-corelibs-foundation`

When configuring Foundation formatters (such as `NumberFormatter`, `DateFormatter`, `ListFormatter`):

- **Darwin (macOS)**: `Locale.autoupdatingCurrent` returns an `NSLocale` instance with a fully backed CoreFoundation `CFLocaleRef` (`_cfObject`).
- **Linux / Windows (`swift-corelibs-foundation`)**: `Locale.autoupdatingCurrent` returns an `NSAutoLocale` proxy object. This proxy object **does not implement a backing `_cfObject` pointer**.

When passing `formatter.locale = Locale.autoupdatingCurrent` and subsequently calling `formatter.string(from: number)`:
1. `NumberFormatter.State.formatter()` attempts to obtain `(formatter.locale as NSLocale)._cfObject`.
2. Accessing `_cfObject` on `NSAutoLocale` in `libFoundation.so` hits an illegal instruction (`UD2` / Signal 4 / SIGILL on Linux, Access Violation `0xC0000005` on Windows).
3. The test runner or editor process terminates abruptly (`exit code 1`).

### Architectural Solution: Always Use `Locale.current`

In [`LogoDateTimeExtensions.swift`](../../Sources/LogoEngine/Types/Formatting/LogoDateTimeExtensions.swift) and [`LogoEngine+TemplatePrimitives.swift`](../../Sources/LogoEngine/Primitives/LogoEngine+TemplatePrimitives.swift):

- Never use `Locale.autoupdatingCurrent` for formatter configuration or localized sorting.
- Always instantiate concrete, fully backed locales via **`Locale.current`** or `Locale(identifier: "...")`.

```swift
public init(logoLocaleSpec raw: String?) {
    guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
        self = .current // NOT .autoupdatingCurrent
        return
    }
    let clean = raw.hasPrefix(":") ? String(raw.dropFirst()) : raw
    let lower = clean.lowercased()
    if lower == "system" || lower == "current" {
        self = .current // NOT .autoupdatingCurrent
        return
    }
    ...
}
```

---

## 13. WebAssembly (WASI / SwiftWasm) Legacy Text Encodings & Memory Traps

### The Pitfall: `RuntimeError: memory access out of bounds` on Legacy Encodings

In `zago`'s multi-encoding auto-detector ([`TextEncodingDetector.swift`](../../Sources/TextEncoding/TextEncodingDetector.swift)), non-UTF-8 byte streams are tested against candidate encodings (such as `.big5`, `.gb18030`, `.gbk`, `.shiftJISCustom`, `.eucJPCustom`, and `.windowsCP1252`).

- **macOS / Linux / Windows**: CoreFoundation / ICU conversion tables are present in the host C runtime, and `String(data: data, encoding: .big5)` successfully decodes valid Big5 byte sequences or returns `nil` on invalid sequences.
- **WebAssembly (`wasm32-unknown-wasi` / SwiftWasm)**: Embedded WASI libc and `swift-corelibs-foundation` for WebAssembly do **NOT** include legacy ICU codepage tables. Calling `String(data: data, encoding: .big5)` (or any custom `String.Encoding` raw value) on WASI hits an unmapped conversion routine or null pointer dereference in the WebAssembly linear memory runtime, triggering an immediate WebAssembly trap:
  ```text
  RuntimeError: memory access out of bounds
  ```

### Architectural Solution: Conditional WASI Encoding Fallback

In [`TextEncodingDetector.swift`](../../Sources/TextEncoding/TextEncodingDetector.swift), legacy multi-byte and single-byte candidate checks are guarded by `#if !os(WASI)`:

```swift
// 1. Check Byte Order Mark (BOM)
if let bomResult = detectBOM(data) {
    return bomResult
}

// 2. Strict UTF-8 validation (without BOM)
if let utf8String = String(data: data, encoding: .utf8) {
    return TextReadResult(content: utf8String, encoding: .utf8)
}

#if !os(WASI)
// 3. Multi-byte candidate encodings (Native platforms only)
let candidateEncodings: [String.Encoding] = [
    .big5,
    .gb18030,
    .gbk,
    .shiftJISCustom,
    .utf16,
    .eucJPCustom,
]

for encoding in candidateEncodings {
    if let decoded = String(data: data, encoding: encoding) {
        return TextReadResult(content: decoded, encoding: encoding)
    }
}

// 4. Single-byte 8-bit fallback (e.g. Windows-1252 / ISO-8859-1)
if let fallbackString = String(data: data, encoding: .windowsCP1252)
    ?? String(data: data, encoding: .isoLatin1)
{
    let actualEncoding: String.Encoding =
        String(data: data, encoding: .windowsCP1252) != nil ? .windowsCP1252 : .isoLatin1
    return TextReadResult(content: fallbackString, encoding: actualEncoding)
}
return nil
#else
// WebAssembly (WASI) fallback: Lenient UTF-8 decoding with replacement characters
return TextReadResult(content: String(decoding: data, as: UTF8.self), encoding: .utf8)
#endif
```

This guarantees that on WebAssembly, files loaded or dragged into the virtual filesystem decode safely without crashing the WASI runtime instance.

---

## 14. WebAssembly (WASI / SwiftWasm) Directory Traversal & `struct dirent` Alignment

### The Pitfall: Hard-Coded Byte Offsets in `WASILibc.readdir`

In WASI libc (`__struct_dirent.h`), `struct dirent` memory layout differs between C compilers and WASI runtimes (`@bjorn3/browser_wasi_shim` vs native WASI runtimes):

- Attempting raw pointer arithmetic (e.g. `entryPtr.advanced(by: 9).assumingMemoryBound(to: CChar.self)`) to read `d_name` offsets leads to out-of-bounds memory reads or reading non-null-terminated memory, causing WebAssembly linear memory traps (`RuntimeError: memory access out of bounds`) when listing `/workspace` directories.

### Architectural Solution: Use `FileManager.contentsOfDirectory`

In [`WasiFileIOStrategy.swift`](../../Sources/zagoweb/WasiFileIOStrategy.swift), directory listings avoid direct C struct pointer manipulation and instead delegate to `FileManager.default.contentsOfDirectory(atPath:)`, which is safely implemented and bounds-checked by `swift-corelibs-foundation` for WebAssembly.

---

## 15. Web WASI Shim UTF-16 Character Count vs UTF-8 Byte Length Heap Buffer Overflow

### The Pitfall: `args_sizes_get` / `environ_sizes_get` Underestimating Buffer Size

In `@bjorn3/browser_wasi_shim`'s implementation of WASI snapshot preview 1:

- When calculating total argument and environment buffer sizes, the shim naively looped through strings using JavaScript's `arg.length` (`buf_size += arg.length + 1`).
- In JavaScript, `arg.length` returns the **UTF-16 code unit count**, NOT the encoded **UTF-8 byte length**.
- For pure ASCII strings (e.g. `welcome.md`), `arg.length == UTF-8 byte length`.
- When passing command-line arguments containing CJK characters or emojis (e.g. `["zago", "/workspace/PRD變更到落地-完整流程.md"]`), `arg.length` was 28, whereas UTF-8 encoded bytes were 50!
- WASI libc in Swift allocated a 29-byte buffer based on `args_sizes_get`. Then `args_get` wrote 50 bytes into the 29-byte buffer, overflowing the heap buffer, corrupting WebAssembly linear memory, and crashing the Swift runtime with `RuntimeError: memory access out of bounds`.

### Architectural Solution: Monkey-Patching `args_sizes_get` & `environ_sizes_get`

In [`web/src/worker.ts`](../../web/src/worker.ts), `wasiInstance.wasiImport.args_sizes_get` and `environ_sizes_get` are monkey-patched to compute exact byte lengths using `new TextEncoder().encode(arg).length`:

```typescript
const textEncoder = new TextEncoder();
wasiInstance.wasiImport.args_sizes_get = (argc: number, argv_buf_size: number): number => {
  const memory = (wasiInstance as any).inst.exports.memory;
  const buffer = new DataView(memory.buffer);
  buffer.setUint32(argc, rawArgs.length, true);
  let buf_size = 0;
  for (const arg of rawArgs) {
    buf_size += textEncoder.encode(arg).length + 1;
  }
  buffer.setUint32(argv_buf_size, buf_size, true);
  return 0;
};
```

---

## 16. WebAssembly (WASI) CJK IME & Multi-Byte Input Batching (`readPendingText`)

### The Pitfall: IME Burst Inputs, Double Dispatch, and Redraw Hitches

In browser environments connecting `xterm.js` to `zagoweb` via WASI standard input:

1. **IME Burst Commit**: When typing Chinese / CJK text using an Input Method Editor (such as Zhuyin, Pinyin, or Cangjie), confirming a long phrase or sentence commits multiple multi-byte UTF-8 characters simultaneously (e.g. 20 CJK characters = 60 UTF-8 bytes) into standard input.
2. **Double Insertion in Frontend / Shim Integrations**:
   - If the web frontend listens to `term.onData(...)` while simultaneously handling DOM `<textarea>` `compositionend` or `input` events and writing them to `wasi.stdin`, the text is sent twice.
   - If `WasiTerminal` only returned `String(firstChar)` from `readPendingText`, the editor processed the input as 20 separate keystrokes with 20 consecutive full screen redrawing passes. In asynchronous Web Worker environments, this caused severe latency and race conditions.

### Architectural Solution: Batch Draining in `WasiTerminal.readPendingText`

In [`WasiTerminal.swift`](../../Sources/zagoweb/WasiTerminal.swift), `readPendingText(firstChar:)` drains all consecutive valid UTF-8 characters, printable text, and newlines from `pendingBytes` in a single pass:

```swift
public func readPendingText(firstChar: Character) -> String {
    guard !pendingBytes.isEmpty else {
        return String(firstChar)
    }

    var result = String(firstChar)
    var idx = 0
    let bytes = pendingBytes

    while idx < bytes.count {
        let b = bytes[idx]
        if b == 27 { // Stop at ESC to preserve escape/arrow sequences
            break
        } else if b == 13 || b == 10 { // CR / LF
            if b == 13 && idx + 1 < bytes.count && bytes[idx + 1] == 10 {
                idx += 1
            }
            result.append("\n")
            idx += 1
        } else if b >= 32 || b == 9 { // Printable character or Tab
            let charLen: Int
            switch b {
            case 0..<0x80: charLen = 1
            case 0xC0..<0xE0: charLen = 2
            case 0xE0..<0xF0: charLen = 3
            case 0xF0..<0xF8: charLen = 4
            default: charLen = 1
            }

            if idx + charLen <= bytes.count {
                let charBytes = bytes[idx..<(idx + charLen)]
                if let str = String(bytes: charBytes, encoding: .utf8) {
                    result.append(str)
                }
                idx += charLen
            } else {
                break
            }
        } else {
            break
        }
    }

    if idx > 0 {
        pendingBytes.removeFirst(idx)
    }
    return result
}
```

### Frontend Guidelines for Web Integrations

1. Only pipe input from `term.onData((data) => wasiStdin.write(data))`. Do not add manual `stdin.write` calls inside `compositionend` or `oninput`.
2. Guard any custom `keydown` listeners against active IME composition:
   ```javascript
   if (e.isComposing || e.keyCode === 229) {
       return;
   }
   ```

---

## 17. WebAssembly (WASI) Single-Threaded Execution & LOGO Debugger Synchronization Safety

### The Pitfall: `NSCondition.wait()` Deadlock on Single-Threaded Event Loops

On native operating systems (macOS, Linux, Windows), `LogoEngine` executes scripts on a dedicated background `Thread` with an expanded 8MB stack size. The main editor thread communicates with the interpreter thread via `NSCondition` (Monitor pattern):
- When a breakpoint is hit or step execution is enabled, the worker thread enters `pauseExecution()` and calls `debuggerCondition.wait()`.
- The main thread continues running the editor event loop, allowing the user to press stepping keys (`F8`), evaluate expressions in the prompt (`:logo eval ...`), or resume execution (`:logo continue`), which signals `debuggerCondition.broadcast()`.

However, on WebAssembly (`wasm32-unknown-wasi` in browsers):
- **WebAssembly runtime is strictly single-threaded**: The entire editor event loop and `LogoEngine` execute on the main JavaScript execution context.
- **Calling `NSCondition.wait()` on WASI blocks the entire browser tab / Web Worker synchronously**.
- Because no secondary thread exists to process user keystrokes or broadcast the condition, calling `wait()` results in an **immediate, unrecoverable deadlock (UI freeze)**.

### Architectural Solution: Conditional WASI Execution & UI Feedback

1. **Synchronous Execution Model on WASI**:
   In [`LogoEngine.swift`](../../Sources/LogoEngine/Core/LogoEngine.swift), `execute(_:)` runs directly and synchronously without spawning worker threads:
   ```swift
   #if os(WASI)
       abortRequested = false
       byeFlag = false
       executionState = .running
       executeScript(script)
       executionState = .completed
   #endif
   ```

2. **Non-Blocking Breakpoint Pass-Through**:
   In `LogoEngine.pauseExecution()`, interactive breakpoints and pausing are completely bypassed under `#if os(WASI)` by immediately returning `true`, preventing `debuggerCondition.wait()` from ever blocking the runtime:
   ```swift
   private func pauseExecution(at frame: LogoExecutionFrame) -> Bool {
       #if os(WASI)
           // WebAssembly runs on a single thread without background event handling;
           // bypass interactive pause/breakpoints to prevent deadlocking the event loop.
           return true
       #else
           debuggerCondition.lock()
           // ... interactive wait/broadcast loop ...
       #endif
   }
   ```

3. **User-Facing UI Guard in Command Bar**:
   In [`LogoOutputCommands.swift`](../../Sources/Editor/Commands/LogoOutputCommands.swift), interactive debugging commands (`:logo break`, `:logo step`, `:logo continue`, `:logo abort`) notify the user directly with a localized warning:
   ```
   [LOGO Debug] Interactive debugger is disabled in WebAssembly single-threaded runtime.
   ```
   This provides clear discoverability and prevents confusion when running `zago` in WebAssembly environments.





