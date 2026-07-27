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
public enum Key: Equatable {
    case char(Character)
    case ctrl(Character)
    case arrowUp
    case arrowDown
    case arrowLeft
    case arrowRight
    case home
    case end
    case pageUp
    case pageDown
    case backspace
    case delete
    case enter
    case tab
    case mark
    case esc
    case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12
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

        // Disable Echo, Canonical Mode, Extended Input, Signals (SIGINT, SIGTSTP)
        raw.c_lflag &= ~tcflag_t(ECHO | ICANON | IEXTEN | ISIG)
        // Disable Software Flow Control (Ctrl+S, Ctrl+Q), CR-to-NL conversion
        raw.c_iflag &= ~tcflag_t(IXON | ICRNL | BRKINT | INPCK | ISTRIP)
        // Disable Post-processing (NL to CR+NL)
        raw.c_oflag &= ~tcflag_t(OPOST)
        // Set 8-bit characters
        raw.c_cflag |= tcflag_t(CS8)

        // Read timeout & minimum characters (VMIN, VTIME cross-platform safety)
        withUnsafeMutableBytes(of: &raw.c_cc) { ptr in
            ptr[Int(VMIN)] = 0
            ptr[Int(VTIME)] = 1
        }

        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
        rawModeEnabled = true
    }

    /// Restores original terminal settings.
    public func disableRawMode() {
        guard rawModeEnabled else { return }
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
        rawModeEnabled = false
    }

    /// Gets terminal window size (rows, cols).
    public func getWindowSize() -> (rows: Int, cols: Int) {
        var w = winsize()
        // Explicitly cast TIOCGWINSZ to UInt for Linux Glibc / Darwin cross-platform compatibility
        if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w) == 0 && w.ws_col > 0 {
            return (rows: Int(w.ws_row), cols: Int(w.ws_col))
        }
        return (rows: 24, cols: 80) // Fallback default
    }

    /// Reads a single byte from standard input.
    private func readByte() -> UInt8? {
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

        case 8, 127:
            // Backspace (ASCII 8 or 127)
            return .backspace

        case 30:
            // Mark key: Ctrl+^ (ASCII 30 / 0x1E)
            return .mark

        case 1...26:
            // Ctrl keys (1 ~ 26 -> Ctrl+A ~ Ctrl+Z)
            let scalar = UnicodeScalar(UInt32(b) + 64)! // 1 -> 'A', 15 -> 'O'
            return .ctrl(Character(scalar))

        case 27:
            // Escape Sequences
            guard let b2 = readByte() else { return .esc }
            switch b2 {
            case UInt8(ascii: "["):
                guard let b3 = readByte() else { return .esc }
                switch b3 {
                case UInt8(ascii: "A"): return .arrowUp
                case UInt8(ascii: "B"): return .arrowDown
                case UInt8(ascii: "C"): return .arrowRight
                case UInt8(ascii: "D"): return .arrowLeft
                case UInt8(ascii: "H"): return .home
                case UInt8(ascii: "F"): return .end
                case UInt8(ascii: "1")...UInt8(ascii: "9"):
                    var seqString = String(UnicodeScalar(b3))
                    while let nb = readByte() {
                        if nb == UInt8(ascii: "~") { break }
                        seqString.append(Character(UnicodeScalar(nb)))
                    }
                    switch seqString {
                    case "3": return .delete
                    case "5": return .pageUp
                    case "6": return .pageDown
                    case "11": return .f1
                    case "12": return .f2
                    case "13": return .f3
                    case "14": return .f4
                    case "15": return .f5
                    case "17": return .f6
                    case "18": return .f7
                    case "19": return .f8
                    case "20": return .f9
                    case "21": return .f10
                    case "23": return .f11
                    case "24": return .f12
                    default: return .unknown
                    }
                default:
                    return .esc
                }

            case UInt8(ascii: "O"):
                guard let b3 = readByte() else { return .esc }
                switch b3 {
                case UInt8(ascii: "H"): return .home
                case UInt8(ascii: "F"): return .end
                case UInt8(ascii: "P"): return .f1
                case UInt8(ascii: "Q"): return .f2
                case UInt8(ascii: "R"): return .f3
                case UInt8(ascii: "S"): return .f4
                default: return .esc
                }

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
