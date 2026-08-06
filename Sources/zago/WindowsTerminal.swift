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
        private(set) public var rawModeEnabled = false

        public init() {
            lastWindowSize = WindowsTerminal.currentWindowSize()
        }

        deinit {
            disableRawMode()
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
                rawInput &= ~DWORD(ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT | ENABLE_PROCESSED_INPUT)
                rawInput |= DWORD(ENABLE_VIRTUAL_TERMINAL_INPUT | ENABLE_WINDOW_INPUT)
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
                SetConsoleMode(hInput, originalInputMode)
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
            let hInput = GetStdHandle(DWORD(bitPattern: -10))
            if consumePendingWindowsResizeInput() {
                return nil
            }
            if timeoutMs > 0 {
                let res = WaitForSingleObject(hInput, DWORD(timeoutMs))
                if res == WAIT_TIMEOUT {
                    lastReadTimedOut = true
                    return nil
                } else if res != WAIT_OBJECT_0 {
                    return nil
                }
                if consumePendingWindowsResizeInput() {
                    return nil
                }
            }

            var unit: UInt16 = 0
            var unitsRead: DWORD = 0
            if ReadConsoleW(hInput, &unit, 1, &unitsRead, nil) && unitsRead == 1 {
                return unit
            }
            return nil
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

        /// Reads the next input key on Windows, including ANSI escape sequences
        /// and console resize events.
        ///
        /// Technical Details:
        /// 1. Polls `CONIN$` for console events using `WaitForSingleObject` and
        ///    `ReadConsoleUTF16Unit`.
        /// 2. Listens for `WINDOW_BUFFER_SIZE_EVENT` and returns `.resize` when
        ///    terminal window bounds change.
        /// 3. Normalizes ASCII control codes (1...31, 127) using
        ///    `ANSIKeyMapping.resolveControlCode`.
        /// 4. Parses ANSI CSI (`ESC [`) and SS3 (`ESC O`) sequences with a 50ms
        ///    character timeout.
        /// 5. Decodes UTF-16 surrogate pairs (high/low surrogates) into
        ///    complete Swift `Character` instances.
        private func readWindowsKey() -> Key {
            let firstUnit: UInt16
            while true {
                if consumePendingWindowsResizeInput() || consumeWindowResizeEvent() {
                    return .resize
                }
                guard let readUnit = readConsoleUTF16Unit(timeoutMs: 250) else {
                    if pendingResizeEvent {
                        pendingResizeEvent = false
                        return .resize
                    }
                    if consumeWindowResizeEvent() {
                        return .resize
                    }
                    if lastReadTimedOut {
                        continue
                    }
                    return .unknown
                }
                firstUnit = readUnit
                break
            }

            if let controlKey = ANSIKeyMapping.resolveControlCode(UInt32(firstUnit)) {
                return controlKey
            }

            if firstUnit == 27 {
                guard let secondUnit = readConsoleUTF16Unit(timeoutMs: 50) else { return .esc }
                if secondUnit == 8 || secondUnit == 127 {
                    return .ctrlBackspace
                }
                switch secondUnit {
                case UInt16(UInt8(ascii: "[")):
                    guard let thirdUnit = readConsoleUTF16Unit(timeoutMs: 50) else { return .alt("[") }
                    let thirdByte = UInt8(truncatingIfNeeded: thirdUnit)
                    if let csiKey = ANSIKeyMapping.resolveCSISingleChar(thirdByte) {
                        return csiKey
                    }
                    if thirdByte >= UInt8(ascii: "1") && thirdByte <= UInt8(ascii: "9") {
                        var seqString = String(UnicodeScalar(UInt32(thirdUnit))!)
                        while let nextUnit = readConsoleUTF16Unit(timeoutMs: 50) {
                            if nextUnit == UInt16(UInt8(ascii: "~"))
                                || (nextUnit >= UInt16(UInt8(ascii: "A")) && nextUnit <= UInt16(UInt8(ascii: "Z")))
                                || (nextUnit >= UInt16(UInt8(ascii: "a")) && nextUnit <= UInt16(UInt8(ascii: "z")))
                            {
                                seqString.append(Character(UnicodeScalar(UInt32(nextUnit))!))
                                break
                            }
                            seqString.append(Character(UnicodeScalar(UInt32(nextUnit))!))
                        }
                        return ANSIKeyMapping.resolve(seqString)
                    }
                    return .esc

                case UInt16(UInt8(ascii: "O")):
                    guard let thirdUnit = readConsoleUTF16Unit(timeoutMs: 50) else { return .esc }
                    return ANSIKeyMapping.resolveSS3Code(UInt8(truncatingIfNeeded: thirdUnit))

                case 32...126:
                    return .alt(Character(UnicodeScalar(UInt32(secondUnit))!))

                default:
                    return .esc
                }
            }

            if let ch = readWindowsCharacter(firstUnit: firstUnit) {
                return .char(ch)
            }
            return .unknown
        }

        /// Reads the next input key on Windows.
        public func readKey() -> Key {
            return readWindowsKey()
        }

        /// Reads all currently queued pending text bytes from stdin without blocking (accelerates clipboard paste).
        public func readPendingText(firstChar: Character) -> String {
            var result = String(firstChar)
            var rawBuffer = [UInt16](repeating: 0, count: 32768)
            let hInput = GetStdHandle(DWORD(bitPattern: -10))

            while WaitForSingleObject(hInput, 0) == WAIT_OBJECT_0 {
                var unitsRead: DWORD = 0
                if ReadConsoleW(hInput, &rawBuffer, DWORD(rawBuffer.count), &unitsRead, nil) && unitsRead > 0 {
                    let units = Array(rawBuffer[..<Int(unitsRead)])
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
                                } else if let low = readConsoleUTF16Unit(timeoutMs: 50), Self.isLowSurrogate(low) {
                                    if let ch = Self.characterFromConsoleUTF16Units([unit, low]) {
                                        result.append(ch)
                                    }
                                    idx += 1
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
                } else {
                    break
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
