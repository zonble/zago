import Config
import Editor
import Foundation

#if os(Windows)
    import WinSDK
#elseif canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#endif

/// Handles Terminal Raw Mode control and ANSI escape sequence parsing.
public final class LocalTerminal: EditorTerminal {
    public enum StartupError: Error, LocalizedError {
        case nonUTF8Console(inputCodePage: UInt32, outputCodePage: UInt32)
        case consoleModeUnavailable

        public var errorDescription: String? {
            switch self {
            case .nonUTF8Console(let inputCodePage, let outputCodePage):
                return LocalTerminal.utf8ConsoleRequirementMessage(
                    inputCodePage: inputCodePage,
                    outputCodePage: outputCodePage)
            case .consoleModeUnavailable:
                return "zago requires an interactive VT-compatible terminal."
            }
        }
    }

    #if os(Windows)
        private var originalInputMode: DWORD = 0
        private var originalOutputMode: DWORD = 0
        private var originalInputCodePage: UINT = 0
        private var originalOutputCodePage: UINT = 0
    #else
        private var originalTermios = termios()
    #endif
    private var lastWindowSize: (rows: Int, cols: Int)
    private var lastReadTimedOut = false
    #if os(Windows)
        private var pendingResizeEvent = false
    #endif
    private(set) public var rawModeEnabled = false

    public init() {
        lastWindowSize = LocalTerminal.currentWindowSize()
    }

    deinit {
        disableRawMode()
    }

    /// Enables terminal raw mode.
    public func enableRawMode() throws {
        guard !rawModeEnabled else { return }
        #if os(Windows)
            let hInput = GetStdHandle(DWORD(bitPattern: -10))
            let hOutput = GetStdHandle(DWORD(bitPattern: -11))
            guard hInput != INVALID_HANDLE_VALUE, hOutput != INVALID_HANDLE_VALUE else {
                throw StartupError.consoleModeUnavailable
            }

            originalInputCodePage = GetConsoleCP()
            originalOutputCodePage = GetConsoleOutputCP()
            if LocalTerminal.utf8ConsoleRequirementMessage(
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
        #else
            tcgetattr(STDIN_FILENO, &originalTermios)

            var raw = originalTermios
            // Input flags: disable IXON (Ctrl+S/Ctrl+Q), ICRNL (map CR to NL)
            raw.c_iflag &= ~tcflag_t(IXON | ICRNL)
            // Local flags: disable ECHO, ICANON (canonical mode), ISIG (Ctrl+C/Ctrl+Z), IEXTEN (Ctrl+V)
            raw.c_lflag &= ~tcflag_t(ECHO | ICANON | ISIG | IEXTEN)

            tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
            rawModeEnabled = true
        #endif
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

    /// Disables raw mode and restores original termios settings.
    public func disableRawMode() {
        guard rawModeEnabled else { return }
        #if os(Windows)
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
        #else
            tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
            rawModeEnabled = false
        #endif
    }

    /// Returns terminal window dimensions (rows, cols).
    public func getWindowSize() -> (rows: Int, cols: Int) {
        LocalTerminal.currentWindowSize()
    }

    private static func currentWindowSize() -> (rows: Int, cols: Int) {
        #if os(Windows)
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
        #else
            var ws = winsize()
            if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &ws) == 0 && ws.ws_col > 0 {
                return (rows: Int(ws.ws_row), cols: Int(ws.ws_col))
            }
            return (rows: 24, cols: 80)  // Fallback default
        #endif
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
        #if os(Windows)
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
        #else
            if timeoutMs > 0 {
                var fds = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
                let ret = poll(&fds, 1, Int32(timeoutMs))
                guard ret > 0 && (fds.revents & Int16(POLLIN)) != 0 else {
                    lastReadTimedOut = ret == 0
                    return nil
                }
            }
            var byte: UInt8 = 0
            let n = read(STDIN_FILENO, &byte, 1)
            return n == 1 ? byte : nil
        #endif
    }

    #if os(Windows)
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
            // Windows console input is fundamentally UTF-16. Reading it through
            // the byte-oriented `ReadFile` path can split non-BMP emoji into
            // surrogate halves, which then show up in the editor as two
            // mojibake characters. Use `ReadConsoleW` and combine surrogate
            // pairs before creating Swift `Character` values.
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

        private func readWindowsKey() -> Key {
            let unit: UInt16
            while true {
                if consumePendingWindowsResizeInput() || consumeWindowResizeEvent() {
                    return .resize
                }
                guard let nextUnit = readConsoleUTF16Unit(timeoutMs: 250) else {
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
                unit = nextUnit
                break
            }

            switch unit {
            case 13:
                return .enter
            case 9:
                return .tab
            case 8:
                return .ctrlBackspace
            case 127:
                return .backspace
            case 30:
                return .mark
            case 31:
                return .ctrl("/")
            case 1...26:
                let scalar = UnicodeScalar(UInt32(unit) + 64)!
                return .ctrl(Character(scalar))
            case 27:
                guard let unit2 = readConsoleUTF16Unit(timeoutMs: 50) else { return .esc }
                if unit2 == 8 || unit2 == 127 {
                    return .ctrlBackspace
                }
                switch unit2 {
                case UInt16(UInt8(ascii: "[")):
                    guard let unit3 = readConsoleUTF16Unit(timeoutMs: 50) else { return .alt("[") }
                    switch unit3 {
                    case UInt16(UInt8(ascii: "A")): return .arrowUp
                    case UInt16(UInt8(ascii: "B")): return .arrowDown
                    case UInt16(UInt8(ascii: "C")): return .arrowRight
                    case UInt16(UInt8(ascii: "D")): return .arrowLeft
                    case UInt16(UInt8(ascii: "a")): return .shiftArrowUp
                    case UInt16(UInt8(ascii: "b")): return .shiftArrowDown
                    case UInt16(UInt8(ascii: "c")): return .shiftArrowRight
                    case UInt16(UInt8(ascii: "d")): return .shiftArrowLeft
                    case UInt16(UInt8(ascii: "H")): return .home
                    case UInt16(UInt8(ascii: "F")): return .end
                    case UInt16(UInt8(ascii: "1"))...UInt16(UInt8(ascii: "9")):
                        var seqString = String(UnicodeScalar(UInt32(unit3))!)
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
                        switch seqString {
                        case "3", "3~": return .delete
                        case "5", "5~": return .pageUp
                        case "6", "6~": return .pageDown
                        case "11", "11~": return .f1
                        case "12", "12~": return .f2
                        case "13", "13~": return .f3
                        case "14", "14~": return .f4
                        case "15", "15~": return .f5
                        case "17", "17~": return .f6
                        case "18", "18~": return .f7
                        case "19", "19~": return .f8
                        case "20", "20~": return .f9
                        case "21", "21~": return .f10
                        case "23", "23~": return .f11
                        case "24", "24~": return .f12
                        case "1;2D", "2D": return .shiftArrowLeft
                        case "1;2C", "2C": return .shiftArrowRight
                        case "1;2A", "2A": return .shiftArrowUp
                        case "1;2B", "2B": return .shiftArrowDown
                        case "1;2H", "2H", "1;2~", "2~": return .shiftHome
                        case "1;2F", "2F", "4;2~": return .shiftEnd
                        case "1;6D", "6D": return .ctrlShiftArrowLeft
                        case "1;6C", "6C": return .ctrlShiftArrowRight
                        case "1;6A", "6A": return .ctrlShiftArrowUp
                        case "1;6B", "6B": return .ctrlShiftArrowDown
                        case "1;5D", "5D": return .ctrl("B")
                        case "1;5C", "5C": return .ctrl("F")
                        default: return .unknown
                        }
                    default:
                        return .esc
                    }
                case UInt16(UInt8(ascii: "O")):
                    guard let unit3 = readConsoleUTF16Unit(timeoutMs: 50) else { return .esc }
                    switch unit3 {
                    case UInt16(UInt8(ascii: "H")): return .home
                    case UInt16(UInt8(ascii: "F")): return .end
                    case UInt16(UInt8(ascii: "P")): return .f1
                    case UInt16(UInt8(ascii: "Q")): return .f2
                    case UInt16(UInt8(ascii: "R")): return .f3
                    case UInt16(UInt8(ascii: "S")): return .f4
                    default: return .esc
                    }
                case 32...126:
                    return .alt(Character(UnicodeScalar(UInt32(unit2))!))
                default:
                    return .esc
                }
            default:
                if let ch = readWindowsCharacter(firstUnit: unit) {
                    return .char(ch)
                }
                return .unknown
            }
        }
    #endif

    /// Reads the next input key (including ANSI key sequences).
    public func readKey() -> Key {
        #if os(Windows)
            return readWindowsKey()
        #else
            let b: UInt8
            while true {
                if consumeWindowResizeEvent() {
                    return .resize
                }
                guard let byte = readByte(timeoutMs: 250) else {
                    if consumeWindowResizeEvent() {
                        return .resize
                    }
                    return .unknown
                }
                b = byte
                break
            }

            switch b {
            case 13:
                // Enter (CR: ASCII 13)
                return .enter

            case 9:
                // Tab (ASCII 9)
                return .tab

            case 8:
                // Ctrl+Backspace / Ctrl+H (ASCII 8)
                return .ctrlBackspace

            case 127:
                // Backspace (ASCII 127)
                return .backspace

            case 30:
                // Mark key: Ctrl+^ (ASCII 30 / 0x1E)
                return .mark

            case 31:
                // Goto Line key: Ctrl+/ or Ctrl+_ (ASCII 31 / 0x1F)
                return .ctrl("/")

            case 1...26:
                // Ctrl keys (1 ~ 26 -> Ctrl+A ~ Ctrl+Z)
                let scalar = UnicodeScalar(UInt32(b) + 64)!  // 1 -> 'A', 15 -> 'O'
                return .ctrl(Character(scalar))

            case 27:
                // Escape Sequences (50ms timeout to detect standalone ESC key vs ANSI sequence)
                guard let b2 = readByte(timeoutMs: 50) else { return .esc }
                if b2 == 8 || b2 == 127 {
                    // ESC + Backspace / Alt+Backspace / Ctrl+Backspace
                    return .ctrlBackspace
                }
                switch b2 {
                case UInt8(ascii: "["):
                    guard let b3 = readByte(timeoutMs: 50) else { return .alt("[") }
                    switch b3 {
                    case UInt8(ascii: "A"): return .arrowUp
                    case UInt8(ascii: "B"): return .arrowDown
                    case UInt8(ascii: "C"): return .arrowRight
                    case UInt8(ascii: "D"): return .arrowLeft
                    case UInt8(ascii: "a"): return .shiftArrowUp
                    case UInt8(ascii: "b"): return .shiftArrowDown
                    case UInt8(ascii: "c"): return .shiftArrowRight
                    case UInt8(ascii: "d"): return .shiftArrowLeft
                    case UInt8(ascii: "H"): return .home
                    case UInt8(ascii: "F"): return .end
                    case UInt8(ascii: "1")...UInt8(ascii: "9"):
                        var seqString = String(UnicodeScalar(b3))
                        while let nb = readByte(timeoutMs: 50) {
                            if nb == UInt8(ascii: "~") || (nb >= UInt8(ascii: "A") && nb <= UInt8(ascii: "Z"))
                                || (nb >= UInt8(ascii: "a") && nb <= UInt8(ascii: "z"))
                            {
                                seqString.append(Character(UnicodeScalar(nb)))
                                break
                            }
                            seqString.append(Character(UnicodeScalar(nb)))
                        }
                        switch seqString {
                        case "3", "3~": return .delete
                        case "5", "5~": return .pageUp
                        case "6", "6~": return .pageDown
                        case "11", "11~": return .f1
                        case "12", "12~": return .f2
                        case "13", "13~": return .f3
                        case "14", "14~": return .f4
                        case "15", "15~": return .f5
                        case "17", "17~": return .f6
                        case "18", "18~": return .f7
                        case "19", "19~": return .f8
                        case "20", "20~": return .f9
                        case "21", "21~": return .f10
                        case "23", "23~": return .f11
                        case "24", "24~": return .f12
                        case "1;2D", "2D": return .shiftArrowLeft
                        case "1;2C", "2C": return .shiftArrowRight
                        case "1;2A", "2A": return .shiftArrowUp
                        case "1;2B", "2B": return .shiftArrowDown
                        case "1;2H", "2H", "1;2~", "2~": return .shiftHome
                        case "1;2F", "2F", "4;2~": return .shiftEnd
                        case "1;6D", "6D": return .ctrlShiftArrowLeft
                        case "1;6C", "6C": return .ctrlShiftArrowRight
                        case "1;6A", "6A": return .ctrlShiftArrowUp
                        case "1;6B", "6B": return .ctrlShiftArrowDown
                        case "1;5D", "5D": return .ctrl("B")
                        case "1;5C", "5C": return .ctrl("F")
                        default: return .unknown
                        }
                    default:
                        return .esc
                    }

                case UInt8(ascii: "O"):
                    guard let b3 = readByte(timeoutMs: 50) else { return .esc }
                    switch b3 {
                    case UInt8(ascii: "H"): return .home
                    case UInt8(ascii: "F"): return .end
                    case UInt8(ascii: "P"): return .f1
                    case UInt8(ascii: "Q"): return .f2
                    case UInt8(ascii: "R"): return .f3
                    case UInt8(ascii: "S"): return .f4
                    default: return .esc
                    }

                case 32...126:
                    let ch = Character(UnicodeScalar(b2))
                    return .alt(ch)

                default:
                    return .esc
                }

            default:
                // Process UTF-8 multi-byte sequence (determining required byte count based on UTF-8 leading byte header)
                var bytes: [UInt8] = [b]
                let neededBytes: Int
                switch b {
                case 0..<0x80:
                    // 1-byte ASCII character (0xxxxxxx)
                    neededBytes = 1
                case 0xC0..<0xE0:
                    // 2-byte UTF-8 character (110xxxxx 10xxxxxx)
                    neededBytes = 2
                case 0xE0..<0xF0:
                    // 3-byte UTF-8 character (1110xxxx 10xxxxxx 10xxxxxx, e.g. CJK Chinese)
                    neededBytes = 3
                case 0xF0..<0xF8:
                    // 4-byte UTF-8 character (11110xxx 10xxxxxx 10xxxxxx 10xxxxxx, e.g. Emoji)
                    neededBytes = 4
                default:
                    neededBytes = 1
                }

                while bytes.count < neededBytes {
                    if let nb = readByte() {
                        bytes.append(nb)
                    } else {
                        break
                    }
                }

                if let str = String(bytes: bytes, encoding: .utf8), let ch = str.first {
                    return .char(ch)
                }

                return .unknown
            }
        #endif
    }

    /// Reads all currently queued pending text bytes from stdin without blocking (accelerates clipboard paste).
    public func readPendingText(firstChar: Character) -> String {
        #if os(Windows)
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
        #else
            let flags = fcntl(STDIN_FILENO, F_GETFL, 0)
            _ = fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK)
            defer { _ = fcntl(STDIN_FILENO, F_SETFL, flags) }

            var result = String(firstChar)
            var rawBuffer = [UInt8](repeating: 0, count: 65536)

            while true {
                let n = read(STDIN_FILENO, &rawBuffer, rawBuffer.count)
                if n <= 0 { break }

                let bytes = Array(rawBuffer[..<n])
                var idx = 0
                while idx < bytes.count {
                    let b = bytes[idx]
                    if b == 13 || b == 10 {  // CR or LF
                        if b == 13 && idx + 1 < bytes.count && bytes[idx + 1] == 10 {
                            idx += 1
                        }
                        result.append("\n")
                        idx += 1
                    } else if b == 27 {  // ESC sequence skip
                        idx += 1
                        if idx < bytes.count && bytes[idx] == UInt8(ascii: "[") {
                            idx += 1
                            while idx < bytes.count && (bytes[idx] < 64 || bytes[idx] > 126) {
                                idx += 1
                            }
                            if idx < bytes.count { idx += 1 }
                        }
                    } else if b >= 32 || b == 9 {  // Printable character or Tab
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
                            idx += 1
                        }
                    } else {
                        idx += 1
                    }
                }
            }
            return result
        #endif
    }

    static func consoleUTF16Units(for text: String) -> [UInt16] {
        Array(text.utf16)
    }

    static func characterFromConsoleUTF16Units(_ units: [UInt16]) -> Character? {
        String(decoding: units, as: UTF16.self).first
    }

    public func write(_ text: String) {
        Self.write(text)
    }

    public func hideCursor() {
        Self.hideCursor()
    }

    public func showCursor() {
        Self.showCursor()
    }

    public func clearScreen() {
        Self.clearScreen()
    }

    public static func write(_ text: String) {
        guard !text.isEmpty else { return }
        #if os(Windows)
            // Windows console output must use the wide-character API. Swift's
            // `print`/narrow stdout path can still mojibake non-BMP emoji
            // surrogate pairs even when the output code page is UTF-8.
            let hOutput = GetStdHandle(DWORD(bitPattern: -11))
            var mode: DWORD = 0
            if hOutput != INVALID_HANDLE_VALUE && GetConsoleMode(hOutput, &mode) {
                let utf16 = consoleUTF16Units(for: text)
                var written: DWORD = 0
                let ok = utf16.withUnsafeBufferPointer { buffer -> Bool in
                    guard let baseAddress = buffer.baseAddress else { return true }
                    return WriteConsoleW(hOutput, baseAddress, DWORD(buffer.count), &written, nil)
                }
                if ok {
                    return
                }
            }
        #endif

        if let data = text.data(using: .utf8) {
            FileHandle.standardOutput.write(data)
        }
    }

    /// ANSI cursor hiding and movement helper functions.
    /// Note: Uses `fflush(nil)` instead of `fflush(stdout)` to safely flush all output streams
    /// without referencing the C global mutable variable `stdout` in Swift 6 concurrency mode.
    public static func hideCursor() {
        write("\u{1B}[?25l")
        fflush(nil)
    }

    public static func showCursor() {
        write("\u{1B}[?25h")
        fflush(nil)
    }

    public static func moveCursor(row: Int, col: Int) {
        write("\u{1B}[\(row);\(col)H")
        fflush(nil)
    }

    public static func clearScreen() {
        write("\u{1B}[2J\u{1B}[H")
        fflush(nil)
    }
}
