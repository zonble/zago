import Foundation

// Terminal cell width is deliberately handled above libc wcwidth().
//
// There are several different models in play:
// - Swift `Character` is an extended grapheme cluster. One visible glyph such as
//   "❤️" may contain multiple Unicode scalars.
// - libc `wcwidth()` works per scalar and varies by platform / Unicode table
//   version. It can report 1 for emoji-like symbols that modern terminals draw
//   as 2 cells, such as "❌".
// - Terminal rendering is pragmatic: CJK and emoji usually occupy 2 cells,
//   combining marks / variation selectors / ZWJ occupy 0 cells, and ANSI escape
//   sequences occupy no cells at all.
//
// For editor layout, table borders, canvas drawing, softwrap, and cursor
// positioning, we need the terminal model rather than a pure Unicode model.
// The rules below therefore:
// - treat emoji grapheme clusters as 2 cells before consulting wcwidth(),
// - preserve standalone zero-width scalars as 0 cells,
// - fall back to wcwidth() plus explicit wide CJK/emoji ranges for normal text.
//
// Be careful when changing this file: returning 1 for a 2-cell emoji leaves
// later text visually shifted left; returning 2 for a zero-width scalar creates
// invisible columns that push the cursor and table borders to the right.

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
    ///
    /// This is not the same as `String.count`, Unicode scalar count, UTF-8 byte
    /// count, or raw `wcwidth()` for the first scalar. The return value is the
    /// number of terminal cells the whole Swift `Character` is expected to
    /// occupy.
    public var displayWidth: Int {
        // Emoji clusters must win before scalar wcwidth(). Some platforms still
        // report text-default emoji symbols as narrow even though terminals draw
        // their emoji presentation as wide.
        if isEmojiTerminalCluster {
            return 2
        }

        var totalWidth = 0
        for scalar in unicodeScalars {
            let width = scalar.terminalScalarWidth
            if width > 0 {
                totalWidth += width
            } else if scalar.isWideTerminalScalar {
                totalWidth += 2
            }
        }
        if totalWidth > 0 {
            return totalWidth
        }
        // A character made only of combining marks, variation selectors, or ZWJ
        // is invisible by itself and must not advance the cursor.
        return unicodeScalars.allSatisfy(\.isZeroWidthTerminalScalar) ? 0 : 1
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

    /// Repeats the string as a pattern until it reaches the requested terminal display width.
    public func repeatedToDisplayWidth(_ width: Int) -> String {
        let fillChars = Array(self)
        guard width > 0, !fillChars.isEmpty else { return "" }

        var result = ""
        var resultWidth = 0
        var idx = 0
        while resultWidth < width {
            let ch = fillChars[idx % fillChars.count]
            let chWidth = ch.displayWidth
            if resultWidth + chWidth <= width {
                result.append(ch)
                resultWidth += chWidth
            } else {
                result += String(repeating: " ", count: width - resultWidth)
                resultWidth = width
            }
            idx += 1
        }
        return result
    }

    /// Tiles the whole string as a pattern until it reaches the requested terminal display width.
    public func tiledToDisplayWidth(_ width: Int) -> String {
        guard width > 0 else { return "" }
        let patternWidth = displayWidth
        guard patternWidth > 0 else { return "" }

        var result = ""
        var resultWidth = 0
        while resultWidth < width {
            if resultWidth + patternWidth <= width {
                result += self
                resultWidth += patternWidth
            } else {
                result += String(repeating: " ", count: width - resultWidth)
                resultWidth = width
            }
        }
        return result
    }
}

extension UnicodeScalar {
    fileprivate var terminalScalarWidth: Int {
        #if canImport(Darwin)
            return Int(wcwidth(wchar_t(value)))
        #elseif canImport(Glibc) || canImport(Musl)
            return Int(sys_wcwidth(Int32(value)))
        #elseif os(Windows)
            if isZeroWidthTerminalScalar {
                return 0
            }
            if isWideTerminalScalar {
                return 2
            }
            return 1
        #else
            return 1
        #endif
    }

    fileprivate var isWideTerminalScalar: Bool {
        switch value {
        case 0x1100...0x115F, 0x2329...0x232A, 0x2E80...0xA4CF,
            0xAC00...0xD7A3, 0xF900...0xFAFF, 0xFE10...0xFE19,
            0xFE30...0xFE6F, 0xFF00...0xFF60, 0xFFE0...0xFFE6,
            0x20000...0x3FFFD,
            0x1F300...0x1FAFF:
            return true
        default:
            return false
        }
    }

    fileprivate var isZeroWidthTerminalScalar: Bool {
        switch value {
        case 0x0300...0x036F,  // Combining Diacritical Marks
            0x1AB0...0x1AFF,  // Combining Diacritical Marks Extended
            0x1DC0...0x1DFF,  // Combining Diacritical Marks Supplement
            0x200C...0x200D,  // Zero-width non-joiner/joiner
            0x20D0...0x20FF,  // Combining Diacritical Marks for Symbols
            0xFE00...0xFE0F,  // Variation Selectors
            0xFE20...0xFE2F,  // Combining Half Marks
            0xE0100...0xE01EF:  // Variation Selectors Supplement
            return true
        default:
            return false
        }
    }
}

extension Character {
    fileprivate var isEmojiTerminalCluster: Bool {
        let scalars = Array(unicodeScalars)

        // Most emoji have an emoji-presentation base scalar. Regional
        // indicators and modern emoji blocks also render as double-width
        // grapheme clusters in practical terminal UIs.
        let hasEmojiBase = scalars.contains { scalar in
            let value = scalar.value
            return scalar.properties.isEmojiPresentation
                || scalar.properties.isEmojiModifierBase
                || (0x1F1E6...0x1F1FF).contains(value)
                || (0x1F300...0x1FAFF).contains(value)
        }
        if hasEmojiBase {
            return true
        }

        let hasEmojiPresentationSelector = scalars.contains { $0.value == 0xFE0F }
        guard hasEmojiPresentationSelector else { return false }

        // Text-default symbols such as "❤" become emoji presentation when VS16
        // is present. The selector itself is zero-width, but the whole cluster
        // should be treated as a 2-cell emoji.
        return scalars.contains { scalar in
            switch scalar.value {
            case 0x2300...0x23FF,
                0x2600...0x27BF,
                0x2B00...0x2BFF:
                return true
            default:
                return false
            }
        }
    }
}
