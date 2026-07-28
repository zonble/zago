import Foundation

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
    @_silgen_name("wcwidth")
    private func sys_wcwidth(_ c: Int32) -> Int32
#elseif canImport(Musl)
    import Musl
    @_silgen_name("wcwidth")
    private func sys_wcwidth(_ c: Int32) -> Int32
#endif

extension Character {
    /// Returns the terminal display width in columns.
    public var displayWidth: Int {
        for scalar in unicodeScalars {
            #if canImport(Darwin)
                let width = wcwidth(wchar_t(scalar.value))
            #elseif canImport(Glibc) || canImport(Musl)
                let width = sys_wcwidth(Int32(scalar.value))
            #else
                let width = 1
            #endif

            if width > 0 { return Int(width) }
            if scalar.isWideTerminalScalar { return 2 }
        }
        return 1
    }
}

extension String {
    /// Returns the total terminal display width in columns.
    public var displayWidth: Int {
        reduce(0) { $0 + $1.displayWidth }
    }

    /// Pads or trims the string to the requested terminal display width.
    public func paddedToDisplayWidth(_ width: Int) -> String {
        let currentWidth = displayWidth
        if currentWidth < width {
            return self + String(repeating: " ", count: width - currentWidth)
        }

        var result = ""
        var visualWidth = 0
        for ch in self {
            let chWidth = ch.displayWidth
            if visualWidth + chWidth > width { break }
            result.append(ch)
            visualWidth += chWidth
        }
        if visualWidth < width {
            result += String(repeating: " ", count: width - visualWidth)
        }
        return result
    }
}

private extension UnicodeScalar {
    var isWideTerminalScalar: Bool {
        switch value {
        case 0x1100...0x115F, 0x2329...0x232A, 0x2E80...0xA4CF,
             0xAC00...0xD7A3, 0xF900...0xFAFF, 0xFE10...0xFE19,
             0xFE30...0xFE6F, 0xFF00...0xFF60, 0xFFE0...0xFFE6,
             0x1F300...0x1FAFF:
            return true
        default:
            return false
        }
    }
}
