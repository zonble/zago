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

public struct VirtualViewport {
    public let lines: [VirtualLine]
    public let startVirtualIndex: Int
    public let totalVirtualLineCount: Int
    public let cursorVirtualLineIndex: Int
    public let cursorVirtualColumnIndex: Int

    public init(
        lines: [VirtualLine],
        startVirtualIndex: Int,
        totalVirtualLineCount: Int,
        cursorVirtualLineIndex: Int,
        cursorVirtualColumnIndex: Int
    ) {
        self.lines = lines
        self.startVirtualIndex = startVirtualIndex
        self.totalVirtualLineCount = totalVirtualLineCount
        self.cursorVirtualLineIndex = cursorVirtualLineIndex
        self.cursorVirtualColumnIndex = cursorVirtualColumnIndex
    }
}

public struct CachedVirtualChunk {
    public let subLineIndex: Int
    public let text: String
    public let startCol: Int
    public let endCol: Int

    public init(subLineIndex: Int, text: String, startCol: Int, endCol: Int) {
        self.subLineIndex = subLineIndex
        self.text = text
        self.startCol = startCol
        self.endCol = endCol
    }
}

/// Handles softwrap (virtual line wrapping) calculation and real/virtual cursor
/// coordinate conversions.
public final class LayoutEngine {
    public static let minimumWrapColumn = 10
    public var wrapColumn: Int?  // nil means adapt dynamically to terminal view width

    private struct LineCacheKey: Hashable {
        let line: String
        let effectiveWrap: Int
    }

    private var lineCache: [LineCacheKey: [CachedVirtualChunk]] = [:]
    private let cacheLock = NSLock()
    public private(set) var lineCacheHitCount: Int = 0

    public init(wrapColumn: Int? = nil) {
        self.wrapColumn = Self.normalizedWrapColumn(wrapColumn)
    }

    public static func normalizedWrapColumn(_ column: Int?) -> Int? {
        guard let column else { return nil }
        return max(minimumWrapColumn, column)
    }

    public func setWrapColumn(_ column: Int?) {
        wrapColumn = Self.normalizedWrapColumn(column)
        invalidateCache()
    }

    /// Invalidates the line layout cache.
    public func invalidateCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        lineCache.removeAll()
        lineCacheHitCount = 0
    }

    private func effectiveWrap(for viewWidth: Int) -> Int {
        max(2, min(wrapColumn ?? viewWidth, viewWidth))
    }

    /// Computes virtual display lines from raw buffer lines given available terminal view width, respecting word boundaries for Latin text.
    public func computeVirtualLines(from lines: [String], viewWidth: Int) -> [VirtualLine] {
        let effectiveWrap = effectiveWrap(for: viewWidth)
        var virtualLines: [VirtualLine] = []

        for (bIndex, line) in lines.enumerated() {
            virtualLines.append(contentsOf: wrapLine(line, bufferLineIndex: bIndex, effectiveWrap: effectiveWrap))
        }

        return virtualLines
    }

    public func computeVirtualViewport(
        from lines: [String],
        viewWidth: Int,
        topVirtualLineIndex: Int,
        height: Int,
        cursorLineIndex: Int,
        cursorColumnIndex: Int,
        computeTotalLineCount: Bool = true
    ) -> VirtualViewport {
        let effectiveWrap = effectiveWrap(for: viewWidth)
        let targetTop = max(0, topVirtualLineIndex)
        let targetEnd = targetTop + max(0, height)
        let cursorLineIndex = max(0, min(cursorLineIndex, max(0, lines.count - 1)))

        var viewportLines: [VirtualLine] = []
        var virtualIndex = 0
        var cursorVirtualLineIndex = 0
        var cursorVirtualColumnIndex = 0
        var cursorResolved = false

        for (bIndex, line) in lines.enumerated() {
            var cursorFallback: (vLineIndex: Int, vColIndex: Int)?
            let completedLine = visitWrappedLine(line, bufferLineIndex: bIndex, effectiveWrap: effectiveWrap) { vLine in
                if bIndex == cursorLineIndex {
                    let isAtLineEnd = vLine.endCol == line.count
                    let cursorIsInChunk =
                        cursorColumnIndex >= vLine.startCol
                        && (cursorColumnIndex < vLine.endCol || (isAtLineEnd && cursorColumnIndex <= vLine.endCol))

                    cursorFallback = (virtualIndex, vLine.text.count)
                    if cursorIsInChunk {
                        cursorVirtualLineIndex = virtualIndex
                        cursorVirtualColumnIndex = cursorColumnIndex - vLine.startCol
                        cursorResolved = true
                    }
                }

                if virtualIndex >= targetTop && virtualIndex < targetEnd {
                    viewportLines.append(vLine)
                }
                virtualIndex += 1

                let stillNeedsCursor =
                    bIndex < cursorLineIndex || (bIndex == cursorLineIndex && !cursorResolved)
                return computeTotalLineCount || virtualIndex < targetEnd || stillNeedsCursor
            }

            if bIndex == cursorLineIndex && !cursorResolved, let cursorFallback {
                cursorVirtualLineIndex = cursorFallback.vLineIndex
                cursorVirtualColumnIndex = cursorFallback.vColIndex
                cursorResolved = true
            }

            if !completedLine || (!computeTotalLineCount && virtualIndex >= targetEnd && bIndex >= cursorLineIndex) {
                break
            }
        }

        return VirtualViewport(
            lines: viewportLines,
            startVirtualIndex: targetTop,
            totalVirtualLineCount: virtualIndex,
            cursorVirtualLineIndex: cursorVirtualLineIndex,
            cursorVirtualColumnIndex: cursorVirtualColumnIndex
        )
    }

    public func computeVirtualLine(at virtualLineIndex: Int, from lines: [String], viewWidth: Int) -> VirtualLine? {
        let effectiveWrap = effectiveWrap(for: viewWidth)
        let targetIndex = max(0, virtualLineIndex)
        var virtualIndex = 0
        var result: VirtualLine?

        for (bIndex, line) in lines.enumerated() {
            let completedLine = visitWrappedLine(line, bufferLineIndex: bIndex, effectiveWrap: effectiveWrap) { vLine in
                if virtualIndex == targetIndex {
                    result = vLine
                    return false
                }
                virtualIndex += 1
                return true
            }
            if !completedLine {
                break
            }
        }

        return result
    }

    private func wrapLine(_ line: String, bufferLineIndex: Int, effectiveWrap: Int) -> [VirtualLine] {
        let key = LineCacheKey(line: line, effectiveWrap: effectiveWrap)

        cacheLock.lock()
        if let cachedChunks = lineCache[key] {
            lineCacheHitCount += 1
            cacheLock.unlock()
            return cachedChunks.map { chunk in
                VirtualLine(
                    bufferLineIndex: bufferLineIndex,
                    subLineIndex: chunk.subLineIndex,
                    text: chunk.text,
                    startCol: chunk.startCol,
                    endCol: chunk.endCol
                )
            }
        }
        cacheLock.unlock()

        let chunks = computeLineChunks(line, effectiveWrap: effectiveWrap)

        cacheLock.lock()
        if lineCache.count > 2000 {
            lineCache.removeAll()
        }
        lineCache[key] = chunks
        cacheLock.unlock()

        return chunks.map { chunk in
            VirtualLine(
                bufferLineIndex: bufferLineIndex,
                subLineIndex: chunk.subLineIndex,
                text: chunk.text,
                startCol: chunk.startCol,
                endCol: chunk.endCol
            )
        }
    }

    private func computeLineChunks(_ line: String, effectiveWrap: Int) -> [CachedVirtualChunk] {
        if line.isEmpty {
            return [CachedVirtualChunk(subLineIndex: 0, text: "", startCol: 0, endCol: 0)]
        }

        if line.utf8.allSatisfy({ $0 < 0x80 }) {
            return asciiLineChunks(line, effectiveWrap: effectiveWrap)
        }

        var chunks: [CachedVirtualChunk] = []
        var currentCharIndex = 0
        var subIndex = 0
        let chars = Array(line)
        let totalChars = chars.count

        while currentCharIndex < totalChars {
            var currentWidth = 0
            var endIndex = currentCharIndex
            var lastWordBoundary = -1

            while endIndex < totalChars {
                let ch = chars[endIndex]
                let w = ch.displayWidth

                if currentWidth + w > effectiveWrap && endIndex > currentCharIndex {
                    break
                }

                if ch.isWhitespace || ch.displayWidth >= 2 || ch.isPunctuation {
                    lastWordBoundary = endIndex
                }

                currentWidth += w
                endIndex += 1
            }

            if endIndex < totalChars && lastWordBoundary > currentCharIndex {
                endIndex = lastWordBoundary + 1
            } else if endIndex == currentCharIndex {
                endIndex = currentCharIndex + 1
            }

            chunks.append(
                CachedVirtualChunk(
                    subLineIndex: subIndex,
                    text: String(chars[currentCharIndex..<endIndex]),
                    startCol: currentCharIndex,
                    endCol: endIndex
                )
            )

            currentCharIndex = endIndex
            subIndex += 1
        }
        return chunks
    }

    @discardableResult
    private func visitWrappedLine(
        _ line: String,
        bufferLineIndex: Int,
        effectiveWrap: Int,
        _ body: (VirtualLine) -> Bool
    ) -> Bool {
        if line.isEmpty {
            return body(
                VirtualLine(
                    bufferLineIndex: bufferLineIndex,
                    subLineIndex: 0,
                    text: "",
                    startCol: 0,
                    endCol: 0)
            )
        }

        if line.utf8.allSatisfy({ $0 < 0x80 }) {
            return visitASCIIWrappedLine(line, bufferLineIndex: bufferLineIndex, effectiveWrap: effectiveWrap, body)
        }

        var currentCharIndex = 0
        var subIndex = 0
        let chars = Array(line)
        let totalChars = chars.count

        while currentCharIndex < totalChars {
            var currentWidth = 0
            var endIndex = currentCharIndex
            var lastWordBoundary = -1

            while endIndex < totalChars {
                let ch = chars[endIndex]
                let w = ch.displayWidth

                if currentWidth + w > effectiveWrap && endIndex > currentCharIndex {
                    break
                }

                if ch.isWhitespace || ch.displayWidth >= 2 || ch.isPunctuation {
                    lastWordBoundary = endIndex
                }

                currentWidth += w
                endIndex += 1
            }

            if endIndex < totalChars && lastWordBoundary > currentCharIndex {
                endIndex = lastWordBoundary + 1
            } else if endIndex == currentCharIndex {
                endIndex = currentCharIndex + 1
            }

            let shouldContinue = body(
                VirtualLine(
                    bufferLineIndex: bufferLineIndex,
                    subLineIndex: subIndex,
                    text: String(chars[currentCharIndex..<endIndex]),
                    startCol: currentCharIndex,
                    endCol: endIndex
                ))
            if !shouldContinue {
                return false
            }

            currentCharIndex = endIndex
            subIndex += 1
        }
        return true
    }

    @discardableResult
    private func visitASCIIWrappedLine(
        _ line: String,
        bufferLineIndex: Int,
        effectiveWrap: Int,
        _ body: (VirtualLine) -> Bool
    ) -> Bool {
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
            let shouldContinue = body(
                VirtualLine(
                    bufferLineIndex: bufferLineIndex,
                    subLineIndex: subIndex,
                    text: text,
                    startCol: currentIndex,
                    endCol: endIndex
                ))
            if !shouldContinue {
                return false
            }

            currentIndex = endIndex
            subIndex += 1
        }
        return true
    }

    private func asciiLineChunks(_ line: String, effectiveWrap: Int) -> [CachedVirtualChunk] {
        let bytes = Array(line.utf8)
        var chunks: [CachedVirtualChunk] = []
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
            chunks.append(
                CachedVirtualChunk(
                    subLineIndex: subIndex,
                    text: text,
                    startCol: currentIndex,
                    endCol: endIndex
                )
            )

            currentIndex = endIndex
            subIndex += 1
        }
        return chunks
    }

    private func virtualCursorInWrappedLine(
        lineIndex: Int,
        columnIndex: Int,
        wrappedLine: [VirtualLine]
    ) -> (vLineOffset: Int, vColIndex: Int) {
        for (offset, vLine) in wrappedLine.enumerated() {
            let isLastSubline = offset == wrappedLine.count - 1
            if isLastSubline {
                if columnIndex >= vLine.startCol && columnIndex <= vLine.endCol {
                    return (offset, columnIndex - vLine.startCol)
                }
            } else if columnIndex >= vLine.startCol && columnIndex < vLine.endCol {
                return (offset, columnIndex - vLine.startCol)
            }
        }

        if let last = wrappedLine.last {
            return (max(0, wrappedLine.count - 1), last.text.count)
        }
        return (0, 0)
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
