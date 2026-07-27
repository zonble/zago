import Foundation

/// Data structure representing a virtual display line (softwrap chunk).
public struct VirtualLine {
    public let bufferLineIndex: Int
    public let subLineIndex: Int
    public let text: String
    public let startCol: Int
    public let endCol: Int
}

/// Handles softwrap (virtual line wrapping) calculation and real/virtual cursor coordinate conversions.
public final class LayoutEngine {
    public var wrapColumn: Int? // nil means adapt dynamically to terminal view width
    
    public init(wrapColumn: Int? = nil) {
        self.wrapColumn = wrapColumn
    }

    /// Computes virtual display lines from raw buffer lines given available terminal view width.
    public func computeVirtualLines(from lines: [String], viewWidth: Int) -> [VirtualLine] {
        let effectiveWrap = max(2, min(wrapColumn ?? viewWidth, viewWidth))
        var virtualLines: [VirtualLine] = []

        for (bIndex, line) in lines.enumerated() {
            if line.isEmpty {
                virtualLines.append(VirtualLine(
                    bufferLineIndex: bIndex,
                    subLineIndex: 0,
                    text: "",
                    startCol: 0,
                    endCol: 0
                ))
                continue
            }

            var currentCharIndex = 0
            var subIndex = 0
            let chars = Array(line)
            let totalChars = chars.count

            while currentCharIndex < totalChars {
                var currentWidth = 0
                var endIndex = currentCharIndex

                while endIndex < totalChars {
                    let w = chars[endIndex].displayWidth
                    if currentWidth + w > effectiveWrap && endIndex > currentCharIndex {
                        break
                    }
                    currentWidth += w
                    endIndex += 1
                }

                let chunkText = String(chars[currentCharIndex..<endIndex])
                
                virtualLines.append(VirtualLine(
                    bufferLineIndex: bIndex,
                    subLineIndex: subIndex,
                    text: chunkText,
                    startCol: currentCharIndex,
                    endCol: endIndex
                ))

                currentCharIndex = endIndex
                subIndex += 1
            }
        }

        return virtualLines
    }

    /// Maps buffer real cursor position (lineIndex, columnIndex) to virtual line index and virtual column.
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

    /// Maps virtual screen cursor position (vLineIndex, vColIndex) back to real buffer cursor (lineIndex, columnIndex).
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
