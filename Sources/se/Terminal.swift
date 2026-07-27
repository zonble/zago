import Foundation
import Darwin

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
        raw.c_lflag &= ~UInt(ECHO | ICANON | IEXTEN | ISIG)
        // Disable Software Flow Control (Ctrl+S, Ctrl+Q), CR-to-NL conversion
        raw.c_iflag &= ~UInt(IXON | ICRNL | BRKINT | INPCK | ISTRIP)
        // Disable Post-processing (NL to CR+NL)
        raw.c_oflag &= ~UInt(OPOST)
        // Set 8-bit characters
        raw.c_cflag |= UInt(CS8)

        // Read timeout & minimum characters
        raw.c_cc.16 = 0 // VMIN
        raw.c_cc.17 = 1 // VTIME (100ms timeout for non-blocking read)

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
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 && w.ws_col > 0 {
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

        // Enter (CR: ASCII 13)
        if b == 13 {
            return .enter
        }

        // Tab (ASCII 9)
        if b == 9 {
            return .tab
        }

        // Backspace (ASCII 127 or 8)
        if b == 127 || b == 8 {
            return .backspace
        }

        // Mark key: Ctrl+^ (ASCII 30 / 0x1E)
        if b == 30 {
            return .mark
        }

        // Ctrl keys (1 ~ 26 -> Ctrl+A ~ Ctrl+Z)
        if b >= 1 && b <= 26 {
            let scalar = UnicodeScalar(UInt32(b) + 64)! // 1 -> 'A', 15 -> 'O'
            return .ctrl(Character(scalar))
        }

        // Escape Sequences
        if b == 27 { // ESC
            guard let b2 = readByte() else { return .esc }
            if b2 == UInt8(ascii: "[") {
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
            } else if b2 == UInt8(ascii: "O") {
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
            }
            return .esc
        }

        // UTF-8 multi-byte characters (1 ~ 4 Bytes, e.g. CJK, Emoji)
        var bytes: [UInt8] = [b]
        let neededBytes: Int
        if (b & 0x80) == 0 {
            neededBytes = 1
        } else if (b & 0xE0) == 0xC0 {
            neededBytes = 2
        } else if (b & 0xF0) == 0xE0 {
            neededBytes = 3
        } else if (b & 0xF8) == 0xF0 {
            neededBytes = 4
        } else {
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

    /// ANSI cursor hiding and movement helper functions.
    public static func hideCursor() {
        print("\u{1B}[?25l", terminator: "")
        fflush(stdout)
    }

    public static func showCursor() {
        print("\u{1B}[?25h", terminator: "")
        fflush(stdout)
    }

    public static func moveCursor(row: Int, col: Int) {
        print("\u{1B}[\(row);\(col)H", terminator: "")
        fflush(stdout)
    }

    public static func clearScreen() {
        print("\u{1B}[2J\u{1B}[H", terminator: "")
        fflush(stdout)
    }
}

private let _localeInit: Void = {
    setlocale(LC_ALL, "")
}()

extension Character {
    /// Returns the character display width in terminal columns (ASCII=1, CJK/Emoji=2).
    public var displayWidth: Int {
        _ = _localeInit
        for scalar in self.unicodeScalars {
            let w = wcwidth(wchar_t(scalar.value))
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
