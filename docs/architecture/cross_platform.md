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
  Win32 console input and handles UTF-16 surrogate pairs directly into unified
  `Key` structs.

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
  [`DarwinFileWatcher`](../../Sources/zago/FileWatcher/FileWatcher+Darwin.swift)
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
- **Windows**: Uses `\` (e.g., `C:\Users\foo\bar.txt`) or `\\?\` UNC long paths.
- **Solution**:
    - All internal buffer paths and prompt completions standardize on `/`.
    - Disk operations normalize paths using `(path as
      NSString).standardizingPath`, supporting both `/` and `\` seamlessly on
      Windows.

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
