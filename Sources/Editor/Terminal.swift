import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(WinSDK)
import WinSDK
#endif

/// Represents key input events.
public enum Key: Equatable, Hashable, Sendable {
    case char(Character)
    case ctrl(Character)
    case alt(Character)
    case arrowUp
    case arrowDown
    case arrowLeft
    case arrowRight
    case home
    case end
    case pageUp
    case pageDown
    case backspace
    case ctrlBackspace
    case delete
    case enter
    case tab
    case mark
    case esc
    case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12
    case shiftArrowLeft
    case shiftArrowRight
    case shiftArrowUp
    case shiftArrowDown
    case unknown
}

/// Handles Terminal Raw Mode control and ANSI escape sequence parsing.
public final class Terminal {
    private var originalTermios = termios()
    private(set) public var rawModeEnabled = false

    public init() {}

    deinit {
        disableRawMode()
    }

    /// Enables terminal raw mode.
    public func enableRawMode() {
        guard !rawModeEnabled else { return }
        tcgetattr(STDIN_FILENO, &originalTermios)

        var raw = originalTermios
        // Input flags: disable IXON (Ctrl+S/Ctrl+Q), ICRNL (map CR to NL)
        raw.c_iflag &= ~tcflag_t(IXON | ICRNL)
        // Local flags: disable ECHO, ICANON (canonical mode), ISIG (Ctrl+C/Ctrl+Z), IEXTEN (Ctrl+V)
        raw.c_lflag &= ~tcflag_t(ECHO | ICANON | ISIG | IEXTEN)

        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
        rawModeEnabled = true
    }

    /// Disables raw mode and restores original termios settings.
    public func disableRawMode() {
        guard rawModeEnabled else { return }
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
        rawModeEnabled = false
    }

    /// Returns terminal window dimensions (rows, cols).
    public func getWindowSize() -> (rows: Int, cols: Int) {
        var ws = winsize()
        if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &ws) == 0 && ws.ws_col > 0 {
            return (rows: Int(ws.ws_row), cols: Int(ws.ws_col))
        }
        return (rows: 24, cols: 80) // Fallback default
    }

    /// Reads a single byte from standard input with optional timeout in milliseconds.
    private func readByte(timeoutMs: Int = 0) -> UInt8? {
        if timeoutMs > 0 {
            var fds = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
            let ret = poll(&fds, 1, Int32(timeoutMs))
            guard ret > 0 && (fds.revents & Int16(POLLIN)) != 0 else {
                return nil
            }
        }
        var byte: UInt8 = 0
        let n = read(STDIN_FILENO, &byte, 1)
        return n == 1 ? byte : nil
    }

    /// Reads the next input key (including ANSI key sequences).
    public func readKey() -> Key {
        guard let b = readByte() else { return .unknown }

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
            let scalar = UnicodeScalar(UInt32(b) + 64)! // 1 -> 'A', 15 -> 'O'
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
                guard let b3 = readByte(timeoutMs: 50) else { return .esc }
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
                        if nb == UInt8(ascii: "~") || (nb >= UInt8(ascii: "A") && nb <= UInt8(ascii: "Z")) || (nb >= UInt8(ascii: "a") && nb <= UInt8(ascii: "z")) {
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
    }

    /// Reads all currently queued pending text bytes from stdin without blocking (accelerates clipboard paste).
    public func readPendingText(firstChar: Character) -> String {
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
                if b == 13 || b == 10 { // CR or LF
                    if b == 13 && idx + 1 < bytes.count && bytes[idx + 1] == 10 {
                        idx += 1
                    }
                    result.append("\n")
                    idx += 1
                } else if b == 27 { // ESC sequence skip
                    idx += 1
                    if idx < bytes.count && bytes[idx] == UInt8(ascii: "[") {
                        idx += 1
                        while idx < bytes.count && (bytes[idx] < 64 || bytes[idx] > 126) {
                            idx += 1
                        }
                        if idx < bytes.count { idx += 1 }
                    }
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
                        idx += 1
                    }
                } else {
                    idx += 1
                }
            }
        }
        return result
    }

    /// ANSI cursor hiding and movement helper functions.
    /// Note: Uses `fflush(nil)` instead of `fflush(stdout)` to safely flush all output streams
    /// without referencing the C global mutable variable `stdout` in Swift 6 concurrency mode.
    public static func hideCursor() {
        print("\u{1B}[?25l", terminator: "")
        fflush(nil)
    }

    public static func showCursor() {
        print("\u{1B}[?25h", terminator: "")
        fflush(nil)
    }

    public static func moveCursor(row: Int, col: Int) {
        print("\u{1B}[\(row);\(col)H", terminator: "")
        fflush(nil)
    }

    public static func clearScreen() {
        print("\u{1B}[2J\u{1B}[H", terminator: "")
        fflush(nil)
    }
}

private let _localeInit: Void = {
    setlocale(LC_ALL, "")
}()

#if canImport(Glibc)
@_silgen_name("wcwidth")
private func sys_wcwidth(_ c: Int32) -> Int32
#elseif canImport(Musl)
@_silgen_name("wcwidth")
private func sys_wcwidth(_ c: Int32) -> Int32
#endif

extension Character {
    /// Returns the character display width in terminal columns (ASCII=1, CJK/Emoji=2).
    public var displayWidth: Int {
        _ = _localeInit
        for scalar in self.unicodeScalars {
            #if canImport(Darwin)
            let w = wcwidth(wchar_t(scalar.value))
            #else
            let w = sys_wcwidth(Int32(scalar.value))
            #endif
            if w > 0 { return Int(w) }
        }
        return 1
    }
}

extension String {
    /// Returns total display width of string in terminal columns.
    public var displayWidth: Int {
        return self.reduce(0) { $0 + $1.displayWidth }
    }

    /// Pads or trims string to specified terminal display column width.
    public func paddedToDisplayWidth(_ width: Int) -> String {
        let currentWidth = self.displayWidth
        if currentWidth >= width {
            var result = ""
            var w = 0
            for ch in self {
                let chW = ch.displayWidth
                if w + chW > width { break }
                result.append(ch)
                w += chW
            }
            if w < width {
                result += String(repeating: " ", count: width - w)
            }
            return result
        } else {
            return self + String(repeating: " ", count: width - currentWidth)
        }
    }
}
