import Config
import Editor
import Foundation

#if canImport(WASILibc)
    import WASILibc
#elseif os(Windows)
    import WinSDK
#endif

/// WebAssembly (WASI) Terminal driver connecting standard I/O streams with xterm.js.
public final class WasiTerminal: EditorTerminal {
    private var currentRows: Int = 24
    private var currentCols: Int = 80
    private var pendingResize = false
    private(set) public var rawModeEnabled = false

    public init() {
        if let envRows = ProcessInfo.processInfo.environment["LINES"], let r = Int(envRows), r > 0 {
            currentRows = r
        }
        if let envCols = ProcessInfo.processInfo.environment["COLUMNS"], let c = Int(envCols), c > 0 {
            currentCols = c
        }
    }

    public func enableRawMode() throws {
        rawModeEnabled = true
    }

    public func disableRawMode() {
        rawModeEnabled = false
    }

    public func getWindowSize() -> (rows: Int, cols: Int) {
        return (rows: currentRows, cols: currentCols)
    }

    private var pendingBytes: [UInt8] = []

    public func hasPendingInput() -> Bool {
        !pendingBytes.isEmpty
    }

    private func readByte() -> UInt8? {
        if !pendingBytes.isEmpty {
            return pendingBytes.removeFirst()
        }
        var buf = [UInt8](repeating: 0, count: 512)
        #if os(WASI) && canImport(WASILibc)
            let n = WASILibc.read(0, &buf, buf.count)
        #elseif os(Windows)
            let n = _read(0, &buf, UInt32(buf.count))
        #else
            let n = read(0, &buf, buf.count)
        #endif
        if n > 0 {
            let first = buf[0]
            if n > 1 {
                pendingBytes.append(contentsOf: buf[1..<n])
            }
            return first
        }
        return nil
    }

    public func readKey() -> Key {
        switch readInputEvent() {
        case .key(let key): return key
        case .mouse: return .unknown
        }
    }

    public func readInputEvent() -> InputEvent {
        var firstByte: UInt8? = nil
        while firstByte == nil {
            if pendingResize {
                pendingResize = false
                return .key(.resize)
            }
            firstByte = readByte()
        }

        guard let first = firstByte else {
            return .key(.unknown)
        }

        if first == 8 {
            return .key(.ctrlBackspace)
        }

        if let controlKey = ANSIKeyMapping.resolveControlCode(UInt32(first)) {
            return .key(controlKey)
        }

        if first == 27 {
            guard let secondByte = readByte() else {
                return .key(.esc)
            }

            if secondByte == 8 || secondByte == 127 { return .key(.altBackspace) }
            if secondByte == 13 || secondByte == 10 { return .key(.altEnter) }
            if secondByte == 9 { return .key(.altTab) }

            switch secondByte {
            case UInt8(ascii: "["):
                return parseCSIInputEvent()
            case UInt8(ascii: "O"):
                guard let third = readByte() else { return .key(.esc) }
                return .key(ANSIKeyMapping.resolveSS3Code(third) ?? .esc)
            default:
                let scalar = UnicodeScalar(secondByte)
                if scalar.value >= 32 && scalar.value < 127 {
                    let char = Character(scalar)
                    if char.isLetter {
                        return .key(.alt(Character(char.lowercased())))
                    }
                    return .key(.alt(char))
                }
                return .key(.esc)
            }
        }

        return .key(decodeUTF8Key(firstByte: first))
    }

    private func parseCSIInputEvent() -> InputEvent {
        guard let first = readByte() else { return .key(.esc) }

        if first == UInt8(ascii: "<") {
            var sequence = "<"
            while sequence.count < 32 {
                guard let next = readByte() else { break }
                let char = Character(UnicodeScalar(next))
                sequence.append(char)
                if next == UInt8(ascii: "M") || next == UInt8(ascii: "m") {
                    break
                }
            }
            if let mouseEvent = ANSIKeyMapping.parseSGRMouseEvent(sequence) {
                return .mouse(mouseEvent)
            }
            return .key(.unknown)
        }

        if let single = ANSIKeyMapping.resolveCSISingleChar(first) {
            return .key(single)
        }

        var sequence = String(UnicodeScalar(first))
        while sequence.count < 32 {
            guard let next = readByte() else { break }
            let char = Character(UnicodeScalar(next))
            sequence.append(char)

            if sequence.hasPrefix("8;") && char == "t" {
                let params = sequence.dropFirst(2).dropLast(1).split(separator: ";")
                if params.count == 2,
                   let r = Int(params[0]),
                   let c = Int(params[1]),
                   r > 0, c > 0 {
                    currentRows = r
                    currentCols = c
                    return .key(.resize)
                }
            }

            if (next >= 0x40 && next <= 0x7E) || next == UInt8(ascii: "~") || next == UInt8(ascii: "u") {
                break
            }
        }

        return .key(ANSIKeyMapping.resolve(sequence))
    }

    private func resolveControlCode(_ code: UInt32) -> Key? {
        switch code {
        case 13: return .enter
        case 9: return .tab
        case 127: return .backspace
        case 30: return .mark
        case 31: return .ctrl("/")
        case 1...26:
            if let scalar = UnicodeScalar(code + 64) {
                return .ctrl(Character(scalar))
            }
            return nil
        default:
            return nil
        }
    }

    private func decodeUTF8Key(firstByte: UInt8) -> Key {
        var bytes = [firstByte]
        let expectedLength: Int
        if firstByte & 0x80 == 0 { expectedLength = 1 }
        else if firstByte & 0xE0 == 0xC0 { expectedLength = 2 }
        else if firstByte & 0xF0 == 0xE0 { expectedLength = 3 }
        else if firstByte & 0xF8 == 0xF0 { expectedLength = 4 }
        else { return .unknown }

        while bytes.count < expectedLength {
            guard let nextByte = readByte() else { return .unknown }
            bytes.append(nextByte)
        }

        var generator = bytes.makeIterator()
        var utf8Decoder = UTF8()
        switch utf8Decoder.decode(&generator) {
        case .scalarValue(let scalar):
            return .char(Character(scalar))
        default:
            return .unknown
        }
    }

    public func readPendingText(firstChar: Character) -> String {
        String(firstChar)
    }

    public func write(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        data.withUnsafeBytes { ptr in
            if let base = ptr.baseAddress {
                #if os(WASI) && canImport(WASILibc)
                    _ = WASILibc.write(1, base, ptr.count)
                #else
                    Foundation.FileHandle.standardOutput.write(data)
                #endif
            }
        }
    }

    public func hideCursor() { write("\u{001B}[?25l") }
    public func showCursor() { write("\u{001B}[?25h") }
    public func clearScreen() { write("\u{001B}[2J\u{001B}[H") }
}
