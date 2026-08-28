import ANSITerminal
import Config
import Editor
import Foundation

#if os(Windows)
    import WinSDK

    /// Windows-specific Terminal Raw Mode control and Win32 Console Input/Output driver.
    public final class WindowsTerminal: EditorTerminal {
        public enum StartupError: Error, LocalizedError {
            case nonUTF8Console(inputCodePage: UInt32, outputCodePage: UInt32)
            case consoleModeUnavailable

            public var errorDescription: String? {
                switch self {
                case .nonUTF8Console(let inputCodePage, let outputCodePage):
                    return WindowsTerminal.utf8ConsoleRequirementMessage(
                        inputCodePage: inputCodePage,
                        outputCodePage: outputCodePage)
                case .consoleModeUnavailable:
                    return "zago requires an interactive VT-compatible terminal."
                }
            }
        }

        private var originalInputMode: DWORD = 0
        private var originalOutputMode: DWORD = 0
        private var originalInputCodePage: UINT = 0
        private var originalOutputCodePage: UINT = 0
        private var lastWindowSize: (rows: Int, cols: Int)
        private var lastReadTimedOut = false
        private var pendingResizeEvent = false
        private var pendingConsoleUTF16Units: [UInt16] = []
        private let wakeupLock = NSLock()
        private var wakeupRequested = false
        private(set) public var rawModeEnabled = false

        public init() {
            lastWindowSize = WindowsTerminal.currentWindowSize()
        }

        deinit {
            disableRawMode()
        }

        public func wakeup() {
            wakeupLock.lock()
            wakeupRequested = true
            wakeupLock.unlock()

            let hInput = GetStdHandle(DWORD(bitPattern: -10))
            guard hInput != INVALID_HANDLE_VALUE, hInput != nil else { return }

            var record = INPUT_RECORD()
            record.EventType = WORD(KEY_EVENT)
            record.Event.KeyEvent.bKeyDown = true
            record.Event.KeyEvent.wRepeatCount = 1
            record.Event.KeyEvent.wVirtualKeyCode = 0
            record.Event.KeyEvent.wVirtualScanCode = 0
            record.Event.KeyEvent.uChar.UnicodeChar = 0
            record.Event.KeyEvent.dwControlKeyState = 0

            var written: DWORD = 0
            _ = WriteConsoleInputW(hInput, &record, 1, &written)
        }

        private func consumeWakeupRequest() -> Bool {
            wakeupLock.lock()
            defer { wakeupLock.unlock() }
            guard wakeupRequested else { return false }
            wakeupRequested = false
            return true
        }

        /// Enables terminal raw mode on Windows.
        public func enableRawMode() throws {
            guard !rawModeEnabled else { return }
            let hInput = GetStdHandle(DWORD(bitPattern: -10))
            let hOutput = GetStdHandle(DWORD(bitPattern: -11))
            guard hInput != INVALID_HANDLE_VALUE, hOutput != INVALID_HANDLE_VALUE else {
                throw StartupError.consoleModeUnavailable
            }

            originalInputCodePage = GetConsoleCP()
            originalOutputCodePage = GetConsoleOutputCP()
            if WindowsTerminal.utf8ConsoleRequirementMessage(
                inputCodePage: UInt32(originalInputCodePage),
                outputCodePage: UInt32(originalOutputCodePage)
            ) != nil {
                throw StartupError.nonUTF8Console(
                    inputCodePage: UInt32(originalInputCodePage),
                    outputCodePage: UInt32(originalOutputCodePage))
            }

            if hInput != INVALID_HANDLE_VALUE {
                guard GetConsoleMode(hInput, &originalInputMode) else {
                    throw StartupError.consoleModeUnavailable
                }
                var rawInput = originalInputMode
                rawInput &= ~DWORD(ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT | ENABLE_PROCESSED_INPUT | ENABLE_QUICK_EDIT_MODE)
                rawInput |= DWORD(ENABLE_VIRTUAL_TERMINAL_INPUT | ENABLE_WINDOW_INPUT | ENABLE_EXTENDED_FLAGS)
                guard SetConsoleMode(hInput, rawInput) else {
                    throw StartupError.consoleModeUnavailable
                }
            }
            if hOutput != INVALID_HANDLE_VALUE {
                guard GetConsoleMode(hOutput, &originalOutputMode) else {
                    throw StartupError.consoleModeUnavailable
                }
                var rawOutput = originalOutputMode
                rawOutput |= DWORD(ENABLE_PROCESSED_OUTPUT | ENABLE_VIRTUAL_TERMINAL_PROCESSING)
                guard SetConsoleMode(hOutput, rawOutput) else {
                    throw StartupError.consoleModeUnavailable
                }
            }
            _ = SetConsoleCP(UINT(CP_UTF8))
            _ = SetConsoleOutputCP(UINT(CP_UTF8))
            rawModeEnabled = true
        }

        static func utf8ConsoleRequirementMessage(inputCodePage: UInt32, outputCodePage: UInt32) -> String? {
            let utf8CodePage: UInt32 = 65001
            guard outputCodePage != utf8CodePage else {
                return nil
            }

            return """
                zago requires a UTF-8 Windows terminal.
                Current console code pages: input \(inputCodePage), output \(outputCodePage).
                Use Windows Terminal or run `chcp 65001` before starting zago.
                """
        }

        /// Disables raw mode and restores original console settings.
        public func disableRawMode() {
            guard rawModeEnabled else { return }
            let hInput = GetStdHandle(DWORD(bitPattern: -10))
            let hOutput = GetStdHandle(DWORD(bitPattern: -11))
            if hInput != INVALID_HANDLE_VALUE {
                SetConsoleMode(hInput, originalInputMode | DWORD(ENABLE_EXTENDED_FLAGS))
            }
            if hOutput != INVALID_HANDLE_VALUE {
                SetConsoleMode(hOutput, originalOutputMode)
            }
            if originalInputCodePage != 0 {
                _ = SetConsoleCP(originalInputCodePage)
            }
            if originalOutputCodePage != 0 {
                _ = SetConsoleOutputCP(originalOutputCodePage)
            }
            rawModeEnabled = false
        }

        /// Returns terminal window dimensions (rows, cols).
        public func getWindowSize() -> (rows: Int, cols: Int) {
            WindowsTerminal.currentWindowSize()
        }

        private static func currentWindowSize() -> (rows: Int, cols: Int) {
            let hOutput = GetStdHandle(DWORD(bitPattern: -11))
            if hOutput != INVALID_HANDLE_VALUE {
                var csbi = CONSOLE_SCREEN_BUFFER_INFO()
                if GetConsoleScreenBufferInfo(hOutput, &csbi) {
                    let cols = Int(csbi.srWindow.Right - csbi.srWindow.Left + 1)
                    let rows = Int(csbi.srWindow.Bottom - csbi.srWindow.Top + 1)
                    if cols > 0 && rows > 0 {
                        return (rows: rows, cols: cols)
                    }
                }
            }
            return (rows: 24, cols: 80)
        }

        private func consumeWindowResizeEvent() -> Bool {
            let size = getWindowSize()
            guard size.rows != lastWindowSize.rows || size.cols != lastWindowSize.cols else {
                return false
            }
            lastWindowSize = size
            return true
        }

        /// Reads a single byte from standard input with optional timeout in milliseconds.
        private func readByte(timeoutMs: Int = 0) -> UInt8? {
            lastReadTimedOut = false
            let hInput = GetStdHandle(DWORD(bitPattern: -10))
            if timeoutMs > 0 {
                let res = WaitForSingleObject(hInput, DWORD(timeoutMs))
                if res == WAIT_TIMEOUT {
                    lastReadTimedOut = true
                    return nil
                } else if res != WAIT_OBJECT_0 {
                    return nil
                }
            }
            var byte: UInt8 = 0
            var bytesRead: DWORD = 0
            if ReadFile(hInput, &byte, 1, &bytesRead, nil) && bytesRead == 1 {
                return byte
            }
            return nil
        }

        private func consumePendingWindowsResizeInput() -> Bool {
            let hInput = GetStdHandle(DWORD(bitPattern: -10))
            guard hInput != INVALID_HANDLE_VALUE else { return false }

            while true {
                var eventCount: DWORD = 0
                guard GetNumberOfConsoleInputEvents(hInput, &eventCount), eventCount > 0 else {
                    return false
                }

                var record = INPUT_RECORD()
                var recordsRead: DWORD = 0
                guard PeekConsoleInputW(hInput, &record, 1, &recordsRead), recordsRead == 1 else {
                    return false
                }

                if record.EventType == WORD(WINDOW_BUFFER_SIZE_EVENT) {
                    _ = ReadConsoleInputW(hInput, &record, 1, &recordsRead)
                    _ = consumeWindowResizeEvent()
                    pendingResizeEvent = true
                    return true
                }

                if record.EventType == WORD(KEY_EVENT) {
                    return false
                }

                _ = ReadConsoleInputW(hInput, &record, 1, &recordsRead)
            }
        }

        private func readConsoleUTF16Unit(timeoutMs: Int = 0) -> UInt16? {
            lastReadTimedOut = false
            if !pendingConsoleUTF16Units.isEmpty {
                return pendingConsoleUTF16Units.removeFirst()
            }

            let hInput = GetStdHandle(DWORD(bitPattern: -10))

            while true {
                let waitMs = timeoutMs > 0 ? DWORD(timeoutMs) : DWORD.max
                let res = WaitForSingleObject(hInput, waitMs)
                if res == WAIT_TIMEOUT {
                    lastReadTimedOut = true
                    return nil
                } else if res != WAIT_OBJECT_0 {
                    return nil
                }

                var record = INPUT_RECORD()
                var recordsRead: DWORD = 0
                guard ReadConsoleInputW(hInput, &record, 1, &recordsRead), recordsRead == 1 else {
                    return nil
                }

                if record.EventType == WORD(WINDOW_BUFFER_SIZE_EVENT) {
                    _ = consumeWindowResizeEvent()
                    pendingResizeEvent = true
                    return nil
                }

                guard record.EventType == WORD(KEY_EVENT) else {
                    continue
                }

                let keyEvent = record.Event.KeyEvent
                guard keyEvent.bKeyDown.boolValue else {
                    continue
                }

                let unit = keyEvent.uChar.UnicodeChar
                if unit == 0, consumeWakeupRequest() {
                    return nil
                }
                guard unit != 0 else {
                    continue
                }
                let repeatCount = Int(keyEvent.wRepeatCount)
                if repeatCount > 1 {
                    pendingConsoleUTF16Units.append(contentsOf: Array(repeating: UInt16(unit), count: repeatCount - 1))
                }
                return UInt16(unit)
            }
        }

        private static func isHighSurrogate(_ unit: UInt16) -> Bool {
            (0xD800...0xDBFF).contains(unit)
        }

        private static func isLowSurrogate(_ unit: UInt16) -> Bool {
            (0xDC00...0xDFFF).contains(unit)
        }

        private func readWindowsCharacter(firstUnit: UInt16) -> Character? {
            if Self.isHighSurrogate(firstUnit), let low = readConsoleUTF16Unit(timeoutMs: 50), Self.isLowSurrogate(low)
            {
                return Self.characterFromConsoleUTF16Units([firstUnit, low])
            }
            return Self.characterFromConsoleUTF16Units([firstUnit])
        }

        /// Injects pending UTF-16 units into the input queue for testing.
        public func injectPendingUnitsForTesting(_ units: [UInt16]) {
            pendingConsoleUTF16Units.append(contentsOf: units)
        }

        /// Checks if there is additional pending input immediately available in the input stream.
        public func hasPendingInput() -> Bool {
            if !pendingConsoleUTF16Units.isEmpty {
                return true
            }
            let hInput = GetStdHandle(DWORD(bitPattern: -10))
            guard hInput != INVALID_HANDLE_VALUE, hInput != nil else { return false }
            var eventCount: DWORD = 0
            if GetNumberOfConsoleInputEvents(hInput, &eventCount), eventCount > 0 {
                return true
            }
            return false
        }

        /// Reads and returns the next key event.
        public func readKey() -> Key {
            switch readInputEvent() {
            case .key(let key): return key
            case .mouse, .openFile: return .unknown
            }
        }

        /// Reads and parses the next input event (key press or SGR mouse event).
        public func readInputEvent() -> InputEvent {
            readInputEvent(timeoutMs: nil) ?? .key(.unknown)
        }

        /// Reads and parses the next input event on Windows, including ANSI escape sequences,
        /// SGR 1006 mouse events, and console resize events.
        ///
        /// Technical Details:
        /// 1. Polls `CONIN$` for console events using `WaitForSingleObject` and
        ///    `ReadConsoleUTF16Unit`.
        /// 2. Listens for `WINDOW_BUFFER_SIZE_EVENT` and returns `.resize` when
        ///    terminal window bounds change.
        /// 3. Normalizes ASCII control codes (1...31, 127) using
        ///    `ANSIKeyMapping.resolveControlCode`.
        /// 4. Parses ANSI CSI (`ESC [`) and SS3 (`ESC O`) sequences with a 50ms
        ///    character timeout, including SGR 1006 mouse tracking (`ESC [ < ... M/m`).
        /// 5. Decodes UTF-16 surrogate pairs (high/low surrogates) into
        ///    complete Swift `Character` instances.
        public func readInputEvent(timeoutMs: Int?) -> InputEvent? {
            let firstUnit: UInt16
            let pollChunk = timeoutMs.map { min($0, 250) } ?? 250
            let start = Date()
            while true {
                if consumePendingWindowsResizeInput() || consumeWindowResizeEvent() {
                    return .key(.resize)
                }
                guard let readUnit = readConsoleUTF16Unit(timeoutMs: pollChunk) else {
                    if pendingResizeEvent {
                        pendingResizeEvent = false
                        return .key(.resize)
                    }
                    if consumeWindowResizeEvent() {
                        return .key(.resize)
                    }
                    if let t = timeoutMs {
                        let elapsedMs = Int(Date().timeIntervalSince(start) * 1000)
                        if elapsedMs >= t {
                            return nil
                        }
                    }
                    if lastReadTimedOut {
                        continue
                    }
                    return .key(.unknown)
                }
                firstUnit = readUnit
                break
            }

            if firstUnit == 8 {
                return .key(.ctrlBackspace)
            }

            if let controlKey = ANSIKeyMapping.resolveControlCode(UInt32(firstUnit)) {
                return .key(controlKey)
            }

            if firstUnit == 27 {
                guard let secondUnit = readConsoleUTF16Unit(timeoutMs: 50) else { return .key(.esc) }
                if secondUnit == 8 || secondUnit == 127 {
                    return .key(.altBackspace)
                }
                if secondUnit == 13 || secondUnit == 10 {
                    return .key(.altEnter)
                }
                if secondUnit == 9 {
                    return .key(.altTab)
                }
                switch secondUnit {
                case UInt16(UInt8(ascii: "[")):
                    guard let thirdUnit = readConsoleUTF16Unit(timeoutMs: 50) else { return .key(.alt("[")) }
                    let thirdByte = UInt8(truncatingIfNeeded: thirdUnit)
                    if thirdByte == UInt8(ascii: "<") {
                        var seqString = "<"
                        while let nextUnit = readConsoleUTF16Unit(timeoutMs: 50) {
                            guard let scalar = UnicodeScalar(UInt32(nextUnit)) else { break }
                            seqString.append(Character(scalar))
                            if nextUnit == UInt16(UInt8(ascii: "M")) || nextUnit == UInt16(UInt8(ascii: "m")) {
                                break
                            }
                        }
                        if let mouseEvent = ANSIKeyMapping.parseSGRMouseEvent(seqString) {
                            return .mouse(mouseEvent)
                        }
                        return .key(.unknown)
                    }

                    if let csiKey = ANSIKeyMapping.resolveCSISingleChar(thirdByte) {
                        return .key(csiKey)
                    }
                    if thirdByte >= UInt8(ascii: "1") && thirdByte <= UInt8(ascii: "9") {
                        var seqString = String(UnicodeScalar(UInt32(thirdUnit))!)
                        while let nextUnit = readConsoleUTF16Unit(timeoutMs: 50) {
                            if nextUnit == UInt16(UInt8(ascii: "~"))
                                || (nextUnit >= UInt16(UInt8(ascii: "A")) && nextUnit <= UInt16(UInt8(ascii: "Z")))
                                || (nextUnit >= UInt16(UInt8(ascii: "a")) && nextUnit <= UInt16(UInt8(ascii: "z")))
                            {
                                if let scalar = UnicodeScalar(UInt32(nextUnit)) {
                                    seqString.append(Character(scalar))
                                }
                                break
                            }
                            if let scalar = UnicodeScalar(UInt32(nextUnit)) {
                                seqString.append(Character(scalar))
                            }
                        }
                        return .key(ANSIKeyMapping.resolve(seqString))
                    }
                    return .key(.unknown)

                case UInt16(UInt8(ascii: "O")):
                    guard let thirdUnit = readConsoleUTF16Unit(timeoutMs: 50) else { return .key(.unknown) }
                    return .key(ANSIKeyMapping.resolveSS3Code(UInt8(truncatingIfNeeded: thirdUnit)) ?? .unknown)

                case 32...126:
                    guard let scalar = UnicodeScalar(UInt32(secondUnit)) else { return .key(.unknown) }
                    return .key(.alt(Character(scalar)))

                default:
                    return .key(.unknown)
                }
            }

            if let ch = readWindowsCharacter(firstUnit: firstUnit) {
                return .key(.char(ch))
            }
            return .key(.unknown)
        }

        /// Reads all currently queued pending text bytes from stdin without blocking (accelerates clipboard paste).
        public func readPendingText(firstChar: Character) -> String {
            var result = String(firstChar)
            var units: [UInt16] = []
            if !pendingConsoleUTF16Units.isEmpty {
                units.append(contentsOf: pendingConsoleUTF16Units)
                pendingConsoleUTF16Units.removeAll()
            }
            let hInput = GetStdHandle(DWORD(bitPattern: -10))

            while WaitForSingleObject(hInput, 0) == WAIT_OBJECT_0 {
                var record = INPUT_RECORD()
                var recordsRead: DWORD = 0
                guard ReadConsoleInputW(hInput, &record, 1, &recordsRead), recordsRead == 1 else {
                    break
                }

                if record.EventType == WORD(WINDOW_BUFFER_SIZE_EVENT) {
                    _ = consumeWindowResizeEvent()
                    pendingResizeEvent = true
                    continue
                }

                guard record.EventType == WORD(KEY_EVENT) else {
                    continue
                }

                let keyEvent = record.Event.KeyEvent
                guard keyEvent.bKeyDown.boolValue else {
                    continue
                }

                let unit = keyEvent.uChar.UnicodeChar
                guard unit != 0 else {
                    continue
                }
                units.append(contentsOf: Array(repeating: UInt16(unit), count: Int(keyEvent.wRepeatCount)))
            }

            var idx = 0
            while idx < units.count {
                let unit = units[idx]
                if unit == 13 || unit == 10 {  // CR or LF
                    if unit == 13 && idx + 1 < units.count && units[idx + 1] == 10 {
                        idx += 1
                    }
                    result.append("\n")
                    idx += 1
                } else if unit == 27 {  // ESC sequence skip
                    idx += 1
                    if idx < units.count && units[idx] == UInt16(UInt8(ascii: "[")) {
                        idx += 1
                        while idx < units.count && (units[idx] < 64 || units[idx] > 126) {
                            idx += 1
                        }
                        if idx < units.count { idx += 1 }
                    }
                } else if unit >= 32 || unit == 9 {  // Printable character or Tab
                    if Self.isHighSurrogate(unit) {
                        if idx + 1 < units.count, Self.isLowSurrogate(units[idx + 1]) {
                            if let ch = Self.characterFromConsoleUTF16Units([unit, units[idx + 1]]) {
                                result.append(ch)
                            }
                            idx += 2
                        } else {
                            idx += 1
                        }
                    } else if let ch = Self.characterFromConsoleUTF16Units([unit]) {
                        result.append(ch)
                        idx += 1
                    } else {
                        idx += 1
                    }
                } else {
                    idx += 1
                }
            }
            return result
        }

        static func consoleUTF16Units(for text: String) -> [UInt16] {
            Array(text.utf16)
        }

        static func characterFromConsoleUTF16Units(_ units: [UInt16]) -> Character? {
            String(decoding: units, as: UTF16.self).first
        }

        /// Writes output text directly to standard output or Win32 console buffer (`WriteConsoleW`).
        public func write(_ text: String) {
            guard !text.isEmpty else { return }
            let hOutput = GetStdHandle(DWORD(bitPattern: -11))
            var mode: DWORD = 0
            if hOutput != INVALID_HANDLE_VALUE && GetConsoleMode(hOutput, &mode) {
                let utf16 = Self.consoleUTF16Units(for: text)
                var written: DWORD = 0
                let ok = utf16.withUnsafeBufferPointer { buffer -> Bool in
                    guard let baseAddress = buffer.baseAddress else { return true }
                    return WriteConsoleW(hOutput, baseAddress, DWORD(buffer.count), &written, nil)
                }
                if ok {
                    return
                }
            }

            if let data = text.data(using: .utf8) {
                FileHandle.standardOutput.write(data)
            }
        }

        /// Hides the terminal cursor via ANSI escape sequence.
        public func hideCursor() {
            write("\u{1B}[?25l")
            fflush(nil)
        }

        /// Shows the terminal cursor via ANSI escape sequence.
        public func showCursor() {
            write("\u{1B}[?25h")
            fflush(nil)
        }

        /// Clears the terminal screen via ANSI escape sequence.
        public func clearScreen() {
            write("\u{1B}[2J\u{1B}[H")
            fflush(nil)
        }

        /// Reads a line from non-interactive CLI prompt mode (e.g. `-e`
        /// evaluating scripts).
        ///
        /// Flushes stderr prompt before blocking on input so prompt text
        /// renders immediately.
        public func readNonInteractiveLine(prompt: String) -> String? {
            if !prompt.isEmpty, let data = prompt.data(using: .utf8) {
                FileHandle.standardError.write(data)
                fflush(nil)
            }
            return readConsoleLine()
        }

        /// Reads a single character from non-interactive CLI prompt mode.
        ///
        /// Flushes stderr prompt before blocking on input.
        public func readNonInteractiveChar(prompt: String) -> String? {
            if !prompt.isEmpty, let data = prompt.data(using: .utf8) {
                FileHandle.standardError.write(data)
                fflush(nil)
            }
            guard let line = readConsoleLine(), let firstChar = line.first else { return nil }
            return String(firstChar)
        }

        /// Reads a line of user input directly from Win32 `ReadConsoleW`
        /// (UTF-16 API).
        ///
        /// Technical Rationale:
        /// 1. Swift `readLine()` decodes CRT `stdin` bytes using
        ///    `GetConsoleCP()` (CP950/Big5 on Traditional Chinese Windows). If
        ///    user inputs non-UTF-8 characters on CP950 Windows, Swift's strict
        ///    UTF-8 decoder returns `nil`.
        /// 2. `ReadConsoleW` bypasses OEM Code Pages entirely and reads native
        ///    UTF-16 (`WCHAR`) directly from `CONIN$`.
        /// 3. Before calling `ReadConsoleW`, `ENABLE_LINE_INPUT |
        ///    ENABLE_ECHO_INPUT | ENABLE_PROCESSED_INPUT` flags are set so the
        ///    console driver buffers line input and waits for Enter before
        ///    returning.
        private func readConsoleLine() -> String? {
            let hInput = GetStdHandle(DWORD(bitPattern: -10))

            if hInput != INVALID_HANDLE_VALUE && hInput != nil && GetFileType(hInput) == FILE_TYPE_CHAR {
                var mode: DWORD = 0
                if GetConsoleMode(hInput, &mode) {
                    var newMode = mode
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
            return readLine()
        }

        private func isStandardInputATerminal() -> Bool {
            let hInput = GetStdHandle(DWORD(bitPattern: -10))
            if hInput == INVALID_HANDLE_VALUE || hInput == nil {
                return false
            }
            return GetFileType(hInput) == FILE_TYPE_CHAR
        }
    }
#endif
