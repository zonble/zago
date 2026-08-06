import Config
import Editor
import Foundation

#if !os(Windows)
    #if canImport(Darwin)
        import Darwin
    #elseif canImport(Glibc)
        import Glibc
    #elseif canImport(Musl)
        import Musl
    #endif

    /// POSIX (macOS / Linux) Terminal Raw Mode control and ANSI escape sequence driver.
    public final class PosixTerminal: EditorTerminal {
        public enum StartupError: Error, LocalizedError {
            case consoleModeUnavailable

            public var errorDescription: String? {
                switch self {
                case .consoleModeUnavailable:
                    return "zago requires an interactive VT-compatible terminal."
                }
            }
        }

        private var originalTermios = termios()
        private var lastWindowSize: (rows: Int, cols: Int)
        private var lastReadTimedOut = false
        private(set) public var rawModeEnabled = false

        public init() {
            lastWindowSize = PosixTerminal.currentWindowSize()
        }

        deinit {
            disableRawMode()
        }

        /// Enables terminal raw mode on POSIX systems.
        public func enableRawMode() throws {
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
            PosixTerminal.currentWindowSize()
        }

        private static func currentWindowSize() -> (rows: Int, cols: Int) {
            var ws = winsize()
            if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &ws) == 0 && ws.ws_col > 0 {
                return (rows: Int(ws.ws_row), cols: Int(ws.ws_col))
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
        }

        /// Reads the next input key on POSIX systems (macOS/Linux), including
        /// ANSI escape sequences.
        ///
        /// Technical Details:
        ///
        /// 1. Polls `STDIN_FILENO` using POSIX `poll(2)` with a 250ms polling
        ///    loop to detect window resize events (`SIGWINCH`/`TIOCGWINSZ`).
        /// 2. Normalizes ASCII control codes (1...31, 127) using
        ///    `ANSIKeyMapping.resolveControlCode`.
        /// 3. Parses ANSI CSI (`ESC [`) and SS3 (`ESC O`) sequences with a 50ms
        ///    escape sequence byte timeout.
        /// 4. Decodes multi-byte UTF-8 character sequences based on leading
        ///    byte headers (`0x80`, `0xC0`, `0xE0`, `0xF0`).
        public func readKey() -> Key {
            let firstByte: UInt8
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
                firstByte = byte
                break
            }

            if let controlKey = ANSIKeyMapping.resolveControlCode(UInt32(firstByte)) {
                return controlKey
            }

            if firstByte == 27 {
                guard let secondByte = readByte(timeoutMs: 50) else { return .esc }
                if secondByte == 8 || secondByte == 127 {
                    return .ctrlBackspace
                }
                switch secondByte {
                case UInt8(ascii: "["):
                    guard let thirdByte = readByte(timeoutMs: 50) else { return .alt("[") }
                    if let csiKey = ANSIKeyMapping.resolveCSISingleChar(thirdByte) {
                        return csiKey
                    }
                    if thirdByte >= UInt8(ascii: "1") && thirdByte <= UInt8(ascii: "9") {
                        var seqString = String(UnicodeScalar(thirdByte))
                        while let nextByte = readByte(timeoutMs: 50) {
                            if nextByte == UInt8(ascii: "~") || (nextByte >= UInt8(ascii: "A") && nextByte <= UInt8(ascii: "Z"))
                                || (nextByte >= UInt8(ascii: "a") && nextByte <= UInt8(ascii: "z"))
                            {
                                seqString.append(Character(UnicodeScalar(nextByte)))
                                break
                            }
                            seqString.append(Character(UnicodeScalar(nextByte)))
                        }
                        return ANSIKeyMapping.resolve(seqString)
                    }
                    return .esc

                case UInt8(ascii: "O"):
                    guard let thirdByte = readByte(timeoutMs: 50) else { return .esc }
                    return ANSIKeyMapping.resolveSS3Code(thirdByte)

                case 32...126:
                    let ch = Character(UnicodeScalar(secondByte))
                    return .alt(ch)

                default:
                    return .esc
                }
            }

            var bytes: [UInt8] = [firstByte]
            let neededBytes: Int
            switch firstByte {
            case 0..<0x80:
                neededBytes = 1
            case 0xC0..<0xE0:
                neededBytes = 2
            case 0xE0..<0xF0:
                neededBytes = 3
            case 0xF0..<0xF8:
                neededBytes = 4
            default:
                neededBytes = 1
            }

            while bytes.count < neededBytes {
                if let nextByte = readByte() {
                    bytes.append(nextByte)
                } else {
                    break
                }
            }

            if let str = String(bytes: bytes, encoding: .utf8), let ch = str.first {
                return .char(ch)
            }

            return .unknown
        }

        /// Reads all currently queued pending text bytes from stdin without
        /// blocking (accelerates clipboard paste).
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
        }

        /// Writes UTF-8 output text directly to standard output.
        public func write(_ text: String) {
            guard !text.isEmpty else { return }
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
        /// Technical Details: Flushes `stderr` prompt text via `fflush(nil)`
        /// before calling `readLine()` so prompt text renders immediately.
        public func readNonInteractiveLine(prompt: String) -> String? {
            if !prompt.isEmpty, let data = prompt.data(using: .utf8) {
                FileHandle.standardError.write(data)
                fflush(nil)
            }
            return readLine()
        }

        /// Reads a single character from non-interactive CLI prompt mode.
        ///
        /// Technical Details:
        /// - Flushes `stderr` prompt text via `fflush(nil)` before blocking on
        ///   `readLine()`.
        public func readNonInteractiveChar(prompt: String) -> String? {
            if !prompt.isEmpty, let data = prompt.data(using: .utf8) {
                FileHandle.standardError.write(data)
                fflush(nil)
            }
            guard let line = readLine(), let firstChar = line.first else { return nil }
            return String(firstChar)
        }
    }
#endif
