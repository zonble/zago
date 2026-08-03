import Foundation
import TextMetrics

/// Data structure representing a single virtual display line (softwrap chunk)
/// rendered on the terminal screen.
///
/// When a raw line in the editor buffer exceeds the terminal viewport or wrap
/// column, the `LayoutEngine` splits it into one or more `VirtualLine` chunks.
/// Each `VirtualLine` tracks its relationship to the original buffer line, its
/// sub-line sequence index, the displayed substring text, and the character
/// index boundaries.
public struct VirtualLine {
    /// The 0-based index of the original raw line in the `TextBuffer`.
    public let bufferLineIndex: Int

    /// The 0-based sub-line sequence index within the parent `TextBuffer` line.
    /// - `0`: The first visual sub-line of the raw buffer line.
    /// - `1+`: Subsequent softwrapped sub-lines (rendered with a `↳` softwrap
    ///   continuation indicator in the gutter).
    public let subLineIndex: Int

    /// The text content substring displayed on this virtual line chunk.
    public let text: String

    /// The 0-based starting character index in the parent `TextBuffer` line for
    /// this virtual chunk.
    public let startCol: Int

    /// The 0-based ending character index in the parent `TextBuffer` line for
    /// this virtual chunk.
    public let endCol: Int
}

/// Handles softwrap (virtual line wrapping) calculation and real/virtual cursor
/// coordinate conversions.
public final class LayoutEngine {
    public static let minimumWrapColumn = 10
    public var wrapColumn: Int?  // nil means adapt dynamically to terminal view width

    public init(wrapColumn: Int? = nil) {
        self.wrapColumn = Self.normalizedWrapColumn(wrapColumn)
    }

    public static func normalizedWrapColumn(_ column: Int?) -> Int? {
        guard let column else { return nil }
        return max(minimumWrapColumn, column)
    }

    public func setWrapColumn(_ column: Int?) {
        wrapColumn = Self.normalizedWrapColumn(column)
    }

    /// Computes virtual display lines from raw buffer lines given available terminal view width, respecting word boundaries for Latin text.
    public func computeVirtualLines(from lines: [String], viewWidth: Int) -> [VirtualLine] {
        let effectiveWrap = max(2, min(wrapColumn ?? viewWidth, viewWidth))
        var virtualLines: [VirtualLine] = []

        for (bIndex, line) in lines.enumerated() {
            if line.isEmpty {
                virtualLines.append(
                    VirtualLine(
                        bufferLineIndex: bIndex,
                        subLineIndex: 0,
                        text: "",
                        startCol: 0,
                        endCol: 0
                    ))
                continue
            }

            if line.utf8.allSatisfy({ $0 < 0x80 }) {
                appendASCIIWrappedLines(
                    line,
                    bufferLineIndex: bIndex,
                    effectiveWrap: effectiveWrap,
                    to: &virtualLines
                )
                continue
            }

            var currentCharIndex = 0
            var subIndex = 0
            let chars = Array(line)
            let totalChars = chars.count

            // Core Softwrap Loop: Iteratively slice a raw buffer line into one or more VirtualLines
            while currentCharIndex < totalChars {
                var currentWidth = 0
                var endIndex = currentCharIndex
                var lastWordBoundary = -1

                // Inner Scan Loop: Accumulate displayWidth starting from
                // currentCharIndex
                while endIndex < totalChars {
                    let ch = chars[endIndex]
                    let w = ch.displayWidth

                    // 1. Column Limit Guard: If adding the current character's
                    //    displayWidth (ASCII=1, CJK/Emoji=2) exceeds
                    //    effectiveWrap and the current sub-line already has at
                    //    least one character, terminate the inner scan loop.
                    if currentWidth + w > effectiveWrap && endIndex > currentCharIndex {
                        break
                    }

                    // 2. Track Word Boundary: Record the last safe word
                    //    boundary position (whitespace ' ', CJK wide character
                    //    displayWidth >= 2, or punctuation). This allows
                    //    trailing Latin words to be wrapped as a whole to the
                    //    next line.
                    if ch.isWhitespace || ch.displayWidth >= 2 || ch.isPunctuation {
                        lastWordBoundary = endIndex
                    }

                    currentWidth += w
                    endIndex += 1
                }

                // 3. Smart Word-Wrap Backtracking Adjustment: If the scan
                //    didn't reach line end (endIndex < totalChars) and a valid
                //    word boundary was found (lastWordBoundary >
                //    currentCharIndex), backtrack the break point to right
                //    after the last boundary character to avoid breaking
                //    English words in the middle.
                if endIndex < totalChars && lastWordBoundary > currentCharIndex {
                    endIndex = lastWordBoundary + 1
                } else if endIndex == currentCharIndex {
                    // Fallback Guard: If a single character's displayWidth
                    // exceeds effectiveWrap, force advance by 1 char to avoid
                    // infinite loop
                    endIndex = currentCharIndex + 1
                }

                // Slice substring and character range for this virtual display chunk
                let chunkText = String(chars[currentCharIndex..<endIndex])

                virtualLines.append(
                    VirtualLine(
                        bufferLineIndex: bIndex,
                        subLineIndex: subIndex,
                        text: chunkText,
                        startCol: currentCharIndex,
                        endCol: endIndex
                    ))

                // Advance starting index for the next virtual line chunk
                currentCharIndex = endIndex
                subIndex += 1
            }
        }

        return virtualLines
    }

    private func appendASCIIWrappedLines(
        _ line: String,
        bufferLineIndex: Int,
        effectiveWrap: Int,
        to virtualLines: inout [VirtualLine]
    ) {
        let bytes = Array(line.utf8)
        var currentIndex = 0
        var subIndex = 0

        while currentIndex < bytes.count {
            var endIndex = currentIndex
            var lastWordBoundary = -1

            while endIndex < bytes.count {
                if endIndex - currentIndex + 1 > effectiveWrap && endIndex > currentIndex {
                    break
                }

                if Self.isASCIIWordBoundary(bytes[endIndex]) {
                    lastWordBoundary = endIndex
                }

                endIndex += 1
            }

            if endIndex < bytes.count && lastWordBoundary > currentIndex {
                endIndex = lastWordBoundary + 1
            } else if endIndex == currentIndex {
                endIndex = currentIndex + 1
            }

            let text = String(decoding: bytes[currentIndex..<endIndex], as: UTF8.self)
            virtualLines.append(
                VirtualLine(
                    bufferLineIndex: bufferLineIndex,
                    subLineIndex: subIndex,
                    text: text,
                    startCol: currentIndex,
                    endCol: endIndex
                ))

            currentIndex = endIndex
            subIndex += 1
        }
    }

    private static func isASCIIWordBoundary(_ byte: UInt8) -> Bool {
        if byte == 9 || byte == 10 || byte == 11 || byte == 12 || byte == 13 || byte == 32 {
            return true
        }
        switch byte {
        case 33...47, 58...64, 91...96, 123...126:
            return true
        default:
            return false
        }
    }

    public func computeCanvasLines(from lines: [String]) -> [VirtualLine] {
        if lines.isEmpty {
            return [VirtualLine(bufferLineIndex: 0, subLineIndex: 0, text: "", startCol: 0, endCol: 0)]
        }

        return lines.enumerated().map { index, line in
            VirtualLine(
                bufferLineIndex: index,
                subLineIndex: 0,
                text: line,
                startCol: 0,
                endCol: line.count)
        }
    }

    /// Maps buffer real cursor position (lineIndex, columnIndex) to virtual
    /// line index and virtual column.
    public func getVirtualCursor(
        lineIndex: Int,
        columnIndex: Int,
        virtualLines: [VirtualLine]
    ) -> (vLineIndex: Int, vColIndex: Int) {
        // Find all virtual lines corresponding to bufferLineIndex
        let matching = virtualLines.enumerated().filter { $0.element.bufferLineIndex == lineIndex }

        if matching.isEmpty {
            return (0, 0)
        }

        for (i, item) in matching.enumerated() {
            let vIdx = item.offset
            let vLine = item.element
            let isLastSubline = (i == matching.count - 1)

            if isLastSubline {
                if columnIndex >= vLine.startCol && columnIndex <= vLine.endCol {
                    let colInVLine = columnIndex - vLine.startCol
                    return (vIdx, colInVLine)
                }
            } else {
                if columnIndex >= vLine.startCol && columnIndex < vLine.endCol {
                    let colInVLine = columnIndex - vLine.startCol
                    return (vIdx, colInVLine)
                }
            }
        }

        // Default to last virtual line of the buffer line
        if let lastMatch = matching.last {
            return (lastMatch.offset, lastMatch.element.text.count)
        }

        return (0, 0)
    }

    /// Maps virtual screen cursor position (vLineIndex, vColIndex) back to real
    /// buffer cursor (lineIndex, columnIndex).
    public func getBufferCursor(
        vLineIndex: Int,
        vColIndex: Int,
        virtualLines: [VirtualLine]
    ) -> (lineIndex: Int, columnIndex: Int) {
        guard !virtualLines.isEmpty else { return (0, 0) }
        let clampedVLineIndex = max(0, min(vLineIndex, virtualLines.count - 1))
        let vLine = virtualLines[clampedVLineIndex]

        let clampedVCol = max(0, min(vColIndex, vLine.text.count))
        let realCol = vLine.startCol + clampedVCol

        return (vLine.bufferLineIndex, realCol)
    }
}
