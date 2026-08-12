# Windows Console I/O & Encoding Architecture

This document details the terminal input/output architecture, Windows Console Subsystem mechanics, Code Page handling, and Cross-Platform I/O abstraction in `zago`.

---

## Executive Summary

`zago` is a cross-platform terminal editor written in Swift for macOS, Linux, and Windows. While macOS and Linux provide unified UTF-8 POSIX `stdin`/`stdout` streams, Windows presents unique architecture challenges due to legacy 30-year Win32 Console Subsystem behavior, OEM Code Pages, and asynchronous input handling in Swift PM test runners.

This document covers how `zago` handles four fundamental input/output scenarios on Windows:
1. **Interactive TTY Editor Mode** (`zago myfile.txt`)
2. **Command-Line Argument Parsing** (`zago -e "..."`)
3. **Piped Input Stream** (`cat file | zago -e ...`)
4. **Interactive Headless Logo I/O** (`zago -e 'MAKE "w RW "Prompt: '`)

---

## Input & Encoding Scenario Matrix

| Scenario | Input Channel | Windows OS Encoding | `zago` Processing & Handling |
| :--- | :--- | :--- | :--- |
| **1. Interactive TTY Editor Mode** | Windows Console Input Buffer (`CONIN$`) / VT100 Escape Sequences | Native Unicode (`WCHAR`) & VT Input | `LocalTerminal.swift` enables `ENABLE_VIRTUAL_TERMINAL_INPUT` and sets UTF-8 code page (`CP65001`). Input events are parsed via Win32 `ReadConsoleInputW` / `ReadFile`. |
| **2. Command-Line Arguments** | Process Command Line (`CommandLine.arguments`) | Native Unicode (`WCHAR` via `GetCommandLineW`) | Processed by Windows kernel as UTF-16. Swift CRT entrypoint automatically converts arguments into a 100% loss-free UTF-8 `String` array. |
| **3. Piped Input Stream** | Standard Input Pipe (`FILE_TYPE_PIPE`) | Upstream Process Encoding (UTF-8 or OEM Code Page) | Detected via `GetFileType(hInput) == FILE_TYPE_PIPE`. Evaluates stream via standard Swift `readLine()`. |
| **4. Headless Logo I/O (`RW` / `RC`)** | Windows Console Keyboard Buffer (`FILE_TYPE_CHAR`) | Native Unicode (`WCHAR`) | Detected via `GetFileType(hInput) == FILE_TYPE_CHAR`. Flushes prompt via `fflush(stderr)` and reads input directly using Win32 `ReadConsoleW` with `ENABLE_LINE_INPUT`. |

---

## Technical Deep-Dive

### 1. Command-Line Arguments (`GetCommandLineW`)
When running commands like `zago -e 'MAKE "z RW "Prompt: '`, Windows passes the process startup string as UTF-16 wide characters. Swift on Windows uses `GetCommandLineW()` to parse `CommandLine.arguments`. Argument parsing is **100% Unicode and loss-free**.

*Note for PowerShell users*: PowerShell strips unescaped double quotes (`"`) when passing raw arguments to native executables. Single quotes (`'...'`) should always be used to wrap LOGO code in PowerShell:
```powershell
zago -e 'MAKE "w RW "Enter name: TYPE ( WORD "Hello " :w )'
```

---

### 2. Standard Input (`stdin`) vs Windows Console Input Page (`GetConsoleCP`)
On Linux and macOS, `stdin` is a pure UTF-8 byte stream. On Windows (Traditional Chinese edition), the legacy Win32 Console Subsystem assigns `GetConsoleCP() = 950` (Big5) or `437` (OEM US) to standard input handles.

When a program invokes standard C `fgets(stdin)` or Swift `readLine()` on an interactive console handle (`FILE_TYPE_CHAR`):
- The console driver produces CP950/Big5 byte sequences.
- Swift 6's strict `String` decoder fails to validate non-UTF-8 bytes and returns `nil`.
- Result: Interactive prompts in headless mode received empty strings.

---

### 3. Solution: Win32 Native `ReadConsoleW` & Line Buffering
To eliminate OEM Code Page translation failures, `LocalTerminal.swift` implements `readConsoleLine()` using native Win32 APIs:

```swift
private func readConsoleLine() -> String? {
    #if os(Windows)
        let hInput = GetStdHandle(DWORD(bitPattern: -10))
        if hInput != INVALID_HANDLE_VALUE && hInput != nil && GetFileType(hInput) == FILE_TYPE_CHAR {
            var mode: DWORD = 0
            if GetConsoleMode(hInput, &mode) {
                var newMode = mode
                // Enforce canonical line buffering (wait for Enter) and character echo
                newMode |= DWORD(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT | ENABLE_PROCESSED_INPUT)
                SetConsoleMode(hInput, newMode)
            }

            var buffer = [WCHAR](repeating: 0, count: 1024)
            var charsRead: DWORD = 0
            if ReadConsoleW(hInput, &buffer, DWORD(buffer.count), &charsRead, nil) && charsRead > 0 {
                let str = String(decoding: buffer.prefix(Int(charsRead)), as: UTF16.self)
                return str.trimmingCharacters(in: .newlines)
            }
        }
    #endif
    return readLine()
}
```

#### Why `ReadConsoleW` Solves Windows Console I/O:
1. **Bypasses Code Pages Completely**: Reads native UTF-16 (`WCHAR`) directly from the kernel `CONIN$` buffer, bypassing C CRT `stdin` byte translation.
2. **Enforces Canonical Line Input**: Setting `ENABLE_LINE_INPUT` prevents prematurely returning single characters when evaluating `READWORD` (`RW`).
3. **Prompt Flushing**: Prompts written to `FileHandle.standardError` are immediately followed by `fflush(nil)` to guarantee instant display on screen before input blocking occurs.

---

## Abstract Editor I/O Architecture

To maintain clean architecture and prevent unit tests (`swift test`) from hanging on open Windows console handles:
- **`Editor` Module**: Fully platform-agnostic with zero `#if os(Windows)` or C system imports. Non-interactive input delegates to `terminal.readNonInteractiveLine(prompt:)`.
- **`EditorTerminal` Protocol**: Declares non-interactive IO methods with default extensions returning `nil`.
- **`LocalTerminal` Driver**: Implements concrete Win32 `ReadConsoleW` and POSIX `isatty()` logic inside the executable target (`zago`).
- **`TestEditorTerminal` Driver**: Used in unit tests, returning mock data without touching standard input, ensuring test runs complete in <10 seconds without blocking.
