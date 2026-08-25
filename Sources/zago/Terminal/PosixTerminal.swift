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

        private var wakeupPipe: [Int32] = [-1, -1]

        public init() {
            lastWindowSize = PosixTerminal.currentWindowSize()
            var fds: [Int32] = [-1, -1]
            if pipe(&fds) == 0 {
                wakeupPipe = fds
                _ = fcntl(wakeupPipe[0], F_SETFL, O_NONBLOCK)
                _ = fcntl(wakeupPipe[1], F_SETFL, O_NONBLOCK)
            }
        }

        public func wakeup() {
            guard wakeupPipe[1] >= 0 else { return }
            var dummy: UInt8 = 1
            #if canImport(Darwin)
                _ = Darwin.write(wakeupPipe[1], &dummy, 1)
            #elseif canImport(Glibc)
                _ = Glibc.write(wakeupPipe[1], &dummy, 1)
            #elseif canImport(Musl)
                _ = Musl.write(wakeupPipe[1], &dummy, 1)
            #endif
        }

        deinit {
            disableRawMode()
            if wakeupPipe[0] >= 0 { close(wakeupPipe[0]) }
            if wakeupPipe[1] >= 0 { close(wakeupPipe[1]) }
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
            var pollFds: [pollfd] = [
                pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
            ]
            if wakeupPipe[0] >= 0 {
                pollFds.append(pollfd(fd: wakeupPipe[0], events: Int16(POLLIN), revents: 0))
            }

            let timeout = timeoutMs > 0 ? Int32(timeoutMs) : -1
            let ret = poll(&pollFds, nfds_t(pollFds.count), timeout)

            if ret > 0 {
                if pollFds.count > 1 && (pollFds[1].revents & Int16(POLLIN)) != 0 {
                    var dummy: UInt8 = 0
                    #if canImport(Darwin)
                        _ = Darwin.read(wakeupPipe[0], &dummy, 1)
                    #elseif canImport(Glibc)
                        _ = Glibc.read(wakeupPipe[0], &dummy, 1)
                    #elseif canImport(Musl)
                        _ = Musl.read(wakeupPipe[0], &dummy, 1)
                    #endif
                    lastWindowSize = (rows: 0, cols: 0)  // Force consumeWindowResizeEvent to return true!
                    return nil
                }

                if (pollFds[0].revents & Int16(POLLIN)) != 0 {
                    var byte: UInt8 = 0
                    #if canImport(Darwin)
                        let n = Darwin.read(STDIN_FILENO, &byte, 1)
                    #elseif canImport(Glibc)
                        let n = Glibc.read(STDIN_FILENO, &byte, 1)
                    #elseif canImport(Musl)
                        let n = Musl.read(STDIN_FILENO, &byte, 1)
                    #else
                        let n = read(STDIN_FILENO, &byte, 1)
                    #endif
                    return n == 1 ? byte : nil
                }
            }

            lastReadTimedOut = ret == 0
            return nil
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

        /// Reads and parses the next input event with an optional timeout in milliseconds.
        public func readInputEvent(timeoutMs: Int?) -> InputEvent? {
            let firstByte: UInt8
            let pollChunk = timeoutMs.map { min($0, 250) } ?? 250
            let start = Date()
            while true {
                if consumeWindowResizeEvent() {
                    return .key(.resize)
                }
                guard let byte = readByte(timeoutMs: pollChunk) else {
                    if consumeWindowResizeEvent() {
                        return .key(.resize)
                    }
                    if let t = timeoutMs {
                        let elapsedMs = Int(Date().timeIntervalSince(start) * 1000)
                        if elapsedMs >= t {
                            return nil
                        }
                    }
                    continue
                }
                firstByte = byte
                break
            }

            if firstByte == 8 {
                return .key(.ctrlBackspace)
            }

            if let controlKey = ANSIKeyMapping.resolveControlCode(UInt32(firstByte)) {
                return .key(controlKey)
            }

            if firstByte == 27 {
                guard let secondByte = readByte(timeoutMs: 50) else { return .key(.esc) }
                if secondByte == 8 || secondByte == 127 {
                    return .key(.altBackspace)
                }
                if secondByte == 13 || secondByte == 10 {
                    return .key(.altEnter)
                }
                if secondByte == 9 {
                    return .key(.altTab)
                }
                switch secondByte {
                case UInt8(ascii: "["):
                    guard let thirdByte = readByte(timeoutMs: 50) else { return .key(.alt("[")) }
                    if thirdByte == UInt8(ascii: "<") {
                        var seqString = "<"
                        while let nextByte = readByte(timeoutMs: 50) {
                            seqString.append(Character(UnicodeScalar(nextByte)))
                            if nextByte == UInt8(ascii: "M") || nextByte == UInt8(ascii: "m") {
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
                        var seqString = String(UnicodeScalar(thirdByte))
                        while let nextByte = readByte(timeoutMs: 50) {
                            if nextByte == UInt8(ascii: "~")
                                || (nextByte >= UInt8(ascii: "A") && nextByte <= UInt8(ascii: "Z"))
                                || (nextByte >= UInt8(ascii: "a") && nextByte <= UInt8(ascii: "z"))
                            {
                                seqString.append(Character(UnicodeScalar(nextByte)))
                                break
                            }
                            seqString.append(Character(UnicodeScalar(nextByte)))
                        }
                        return .key(ANSIKeyMapping.resolve(seqString))
                    }
                    return .key(.unknown)

                case UInt8(ascii: "O"):
                    guard let thirdByte = readByte(timeoutMs: 50) else { return .key(.unknown) }
                    return .key(ANSIKeyMapping.resolveSS3Code(thirdByte) ?? .unknown)

                case 32...126:
                    let ch = Character(UnicodeScalar(secondByte))
                    return .key(.alt(ch))

                default:
                    return .key(.unknown)
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
                return .key(.char(ch))
            }

            return .key(.unknown)
        }

        public func hasPendingInput() -> Bool {
            var pfd = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
            return poll(&pfd, 1, 0) > 0 && (pfd.revents & Int16(POLLIN)) != 0
        }

        /// Reads all currently queued pending text bytes from stdin without
        /// blocking (accelerates clipboard paste).
        public func readPendingText(firstChar: Character) -> String {
            guard hasPendingInput() else {
                return String(firstChar)
            }
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
            if isatty(STDIN_FILENO) != 0 {
                let flags = fcntl(STDIN_FILENO, F_GETFL, 0)
                if flags >= 0 {
                    _ = fcntl(STDIN_FILENO, F_SETFL, flags & ~O_NONBLOCK)
                }
                defer {
                    if flags >= 0 {
                        _ = fcntl(STDIN_FILENO, F_SETFL, flags)
                    }
                }
                return readLine()
            }
            return readLine()
        }

        /// Reads a single character from non-interactive CLI prompt mode.
        ///
        /// Technical Details:
        /// - Flushes `stderr` prompt text via `fflush(nil)` before blocking on
        ///   `read()`.
        public func readNonInteractiveChar(prompt: String) -> String? {
            if !prompt.isEmpty, let data = prompt.data(using: .utf8) {
                FileHandle.standardError.write(data)
                fflush(nil)
            }
            if isatty(STDIN_FILENO) != 0 {
                let flags = fcntl(STDIN_FILENO, F_GETFL, 0)
                if flags >= 0 {
                    _ = fcntl(STDIN_FILENO, F_SETFL, flags & ~O_NONBLOCK)
                }
                defer {
                    if flags >= 0 {
                        _ = fcntl(STDIN_FILENO, F_SETFL, flags)
                    }
                }

                var oldt = termios()
                tcgetattr(STDIN_FILENO, &oldt)
                var newt = oldt
                newt.c_lflag &= ~tcflag_t(ECHO | ICANON)
                withUnsafeMutableBytes(of: &newt.c_cc) { ptr in
                    ptr[Int(VMIN)] = 1
                    ptr[Int(VTIME)] = 0
                }
                tcsetattr(STDIN_FILENO, TCSANOW, &newt)
                defer { tcsetattr(STDIN_FILENO, TCSANOW, &oldt) }

                var buf: UInt8 = 0
                while true {
                    let n = read(STDIN_FILENO, &buf, 1)
                    if n > 0 {
                        return String(UnicodeScalar(buf))
                    } else if n == 0 {
                        return nil
                    } else {
                        let err = errno
                        if err == EINTR || err == EAGAIN || err == EWOULDBLOCK {
                            continue
                        }
                        return nil
                    }
                }
            } else {
                guard let line = readLine(), let firstChar = line.first else { return nil }
                return String(firstChar)
            }
        }
    }
#endif
