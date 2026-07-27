import Foundation
import Darwin

/// 代表輸入按鍵枚舉
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
    case esc
    case unknown
}

/// 負責處理 Terminal Raw Mode 控制與 ANSI Sequence 解析
public final class Terminal {
    private var originalTermios = termios()
    private(set) public var rawModeEnabled = false

    public init() {}

    deinit {
        disableRawMode()
    }

    /// 啟用 Raw Mode
    public func enableRawMode() {
        guard !rawModeEnabled else { return }
        
        tcgetattr(STDIN_FILENO, &originalTermios)
        var raw = originalTermios

        // 關閉 Echo, Canonical Mode, Extended Input, Signals (SIGINT, SIGTSTP)
        raw.c_lflag &= ~UInt(ECHO | ICANON | IEXTEN | ISIG)
        // 關閉 Software Flow Control (Ctrl+S, Ctrl+Q), CR-to-NL 轉換
        raw.c_iflag &= ~UInt(IXON | ICRNL | BRKINT | INPCK | ISTRIP)
        // 關閉 Post-processing (NL to CR+NL)
        raw.c_oflag &= ~UInt(OPOST)
        // 設定 8-bit characters
        raw.c_cflag |= UInt(CS8)

        // Read timeout & minimum characters
        raw.c_cc.16 = 0 // VMIN
        raw.c_cc.17 = 1 // VTIME (100ms timeout for non-blocking read)

        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
        rawModeEnabled = true
    }

    /// 恢復原始 Terminal 設定
    public func disableRawMode() {
        guard rawModeEnabled else { return }
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
        rawModeEnabled = false
    }

    /// 取得 Terminal 視窗大小 (rows, cols)
    public func getWindowSize() -> (rows: Int, cols: Int) {
        var w = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 && w.ws_col > 0 {
            return (rows: Int(w.ws_row), cols: Int(w.ws_col))
        }
        return (rows: 24, cols: 80) // Fallback 預設值
    }

    /// 從標準輸入讀取單一 Byte
    private func readByte() -> UInt8? {
        var byte: UInt8 = 0
        let n = read(STDIN_FILENO, &byte, 1)
        return n == 1 ? byte : nil
    }

    /// 讀取下一個按鍵 (含 ANSI Key 解析)
    public func readKey() -> Key {
        guard let b = readByte() else { return .unknown }

        // Enter (CR: ASCII 13)
        if b == 13 {
            return .enter
        }

        // Backspace (ASCII 127 or 8)
        if b == 127 || b == 8 {
            return .backspace
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
                case UInt8(ascii: "1"), UInt8(ascii: "7"): return .home
                case UInt8(ascii: "4"), UInt8(ascii: "8"): return .end
                case UInt8(ascii: "3"):
                    _ = readByte() // consume '~'
                    return .delete
                case UInt8(ascii: "5"):
                    _ = readByte() // consume '~'
                    return .pageUp
                case UInt8(ascii: "6"):
                    _ = readByte() // consume '~'
                    return .pageDown
                default:
                    return .esc
                }
            } else if b2 == UInt8(ascii: "O") {
                guard let b3 = readByte() else { return .esc }
                if b3 == UInt8(ascii: "H") { return .home }
                if b3 == UInt8(ascii: "F") { return .end }
            }
            return .esc
        }

        // 一般 UTF-8 字元 (包含 1 ~ 4 Bytes 多位元組字元，如中文、Emoji)
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

    /// 清屏與移動游標 ANSI 輔助函式
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
    /// 取得字元在 Terminal 中的顯示欄數 (ASCII=1, 全形/中文/Emoji=2)
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
    /// 取得字串在 Terminal 中的顯示總欄數
    public var displayWidth: Int {
        return self.reduce(0) { $0 + $1.displayWidth }
    }

    /// 補齊或截斷至指定 Terminal 顯示寬度 (對齊全形與中文)
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
