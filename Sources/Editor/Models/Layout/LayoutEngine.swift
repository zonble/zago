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
struct VirtualLine {
    /// The 0-based index of the original raw line in the `TextBuffer`.
    let bufferLineIndex: Int

    /// The 0-based sub-line sequence index within the parent `TextBuffer` line.
    /// - `0`: The first visual sub-line of the raw buffer line.
    /// - `1+`: Subsequent softwrapped sub-lines (rendered with a `↳` softwrap
    ///   continuation indicator in the gutter).
    let subLineIndex: Int

    /// The text content substring displayed on this virtual line chunk.
    let text: String

    /// The 0-based starting character index in the parent `TextBuffer` line for
    /// this virtual chunk.
    let startCol: Int

    /// The 0-based ending character index in the parent `TextBuffer` line for
    /// this virtual chunk.
    let endCol: Int

    /// Flag indicating whether this virtual line is part of an active AI proposal box overlay.
    let isProposalOverlay: Bool

    init(
        bufferLineIndex: Int,
        subLineIndex: Int,
        text: String,
        startCol: Int,
        endCol: Int,
        isProposalOverlay: Bool = false
    ) {
        self.bufferLineIndex = bufferLineIndex
        self.subLineIndex = subLineIndex
        self.text = text
        self.startCol = startCol
        self.endCol = endCol
        self.isProposalOverlay = isProposalOverlay
    }
}

struct VirtualViewport {
    let lines: [VirtualLine]
    let startVirtualIndex: Int
    let totalVirtualLineCount: Int
    let cursorVirtualLineIndex: Int
    let cursorVirtualColumnIndex: Int

    init(
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

struct CachedVirtualChunk {
    let subLineIndex: Int
    let text: String
    let startCol: Int
    let endCol: Int

    init(subLineIndex: Int, text: String, startCol: Int, endCol: Int) {
        self.subLineIndex = subLineIndex
        self.text = text
        self.startCol = startCol
        self.endCol = endCol
    }
}

/// Handles softwrap (virtual line wrapping) calculation and real/virtual cursor
/// coordinate conversions.
final class LayoutEngine {
    static let minimumWrapColumn = 10
    var wrapColumn: Int?  // nil means adapt dynamically to terminal view width
    var listWrapIndent: Bool = true

    private struct LineCacheEntry {
        var line: String
        var chunks: [CachedVirtualChunk]
    }

    private var lineEntries: [LineCacheEntry?] = []
    private var cachedEffectiveWrap: Int?
    private var cachedListWrapIndent: Bool?
    private(set) var lineOffsets: [Int] = []
    private let cacheLock = NSLock()
    private(set) var lineCacheHitCount: Int = 0

    init(wrapColumn: Int? = nil, listWrapIndent: Bool = true) {
        self.wrapColumn = Self.normalizedWrapColumn(wrapColumn)
        self.listWrapIndent = listWrapIndent
    }

    static func calculateListHangingIndent(in line: String) -> Int {
        let leadingSpaces = line.prefix(while: { $0 == " " || $0 == "\t" }).count
        let trimmed = line.dropFirst(leadingSpaces)
        if trimmed.isEmpty { return 0 }

        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") || trimmed.hasPrefix(". ")
            || trimmed.hasPrefix(".. ")
        {
            let firstSpaceOffset = trimmed.firstIndex(of: " ") ?? trimmed.endIndex
            let markerLen = trimmed.distance(from: trimmed.startIndex, to: firstSpaceOffset) + 1
            return leadingSpaces + markerLen
        }

        if let firstSpaceIndex = trimmed.firstIndex(of: " ") {
            let firstWord = String(trimmed[..<firstSpaceIndex])
            if firstWord.range(of: #"^(\d+[\.\)]|[a-zA-Z][\.\)]|#\.|::)$"#, options: .regularExpression) != nil {
                return leadingSpaces + firstWord.count + 1
            }
        }
        return 0
    }

    static func normalizedWrapColumn(_ column: Int?) -> Int? {
        guard let column else { return nil }
        return max(minimumWrapColumn, column)
    }

    func setWrapColumn(_ column: Int?) {
        wrapColumn = Self.normalizedWrapColumn(column)
        invalidateCache()
    }

    /// Invalidates the line layout cache.
    func invalidateCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        lineEntries.removeAll()
        lineOffsets.removeAll()
        cachedEffectiveWrap = nil
        cachedListWrapIndent = nil
        lineCacheHitCount = 0
    }

    private func effectiveWrap(for viewWidth: Int) -> Int {
        max(2, min(wrapColumn ?? viewWidth, viewWidth))
    }

    /// Computes virtual display lines from raw buffer lines given available terminal view width, respecting word boundaries for Latin text.
    func computeVirtualLines(from lines: [String], viewWidth: Int) -> [VirtualLine] {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        let wrap = effectiveWrap(for: viewWidth)
        if cachedEffectiveWrap != wrap || cachedListWrapIndent != listWrapIndent || lineEntries.count != lines.count {
            if cachedEffectiveWrap != wrap || cachedListWrapIndent != listWrapIndent {
                lineEntries = Array(repeating: nil, count: lines.count)
            } else if lineEntries.count < lines.count {
                lineEntries.append(contentsOf: Array(repeating: nil, count: lines.count - lineEntries.count))
            } else {
                lineEntries.removeLast(lineEntries.count - lines.count)
            }
            cachedEffectiveWrap = wrap
            cachedListWrapIndent = listWrapIndent
        }

        var virtualLines: [VirtualLine] = []
        var offsets: [Int] = []
        offsets.reserveCapacity(lines.count)
        var currentVIndex = 0

        for (bIndex, line) in lines.enumerated() {
            offsets.append(currentVIndex)
            let chunks: [CachedVirtualChunk]
            if let entry = lineEntries[bIndex], entry.line == line {
                chunks = entry.chunks
                lineCacheHitCount += 1
            } else {
                chunks = computeLineChunks(line, effectiveWrap: wrap)
                lineEntries[bIndex] = LineCacheEntry(line: line, chunks: chunks)
            }

            for chunk in chunks {
                virtualLines.append(
                    VirtualLine(
                        bufferLineIndex: bIndex,
                        subLineIndex: chunk.subLineIndex,
                        text: chunk.text,
                        startCol: chunk.startCol,
                        endCol: chunk.endCol
                    )
                )
            }
            currentVIndex += chunks.count
        }

        self.lineOffsets = offsets
        return virtualLines
    }

    func computeVirtualViewport(
        from lines: [String],
        viewWidth: Int,
        topVirtualLineIndex: Int,
        height: Int,
        cursorLineIndex: Int,
        cursorColumnIndex: Int,
        computeTotalLineCount: Bool = true
    ) -> VirtualViewport {
        let allVLines = computeVirtualLines(from: lines, viewWidth: viewWidth)
        let targetTop = max(0, min(topVirtualLineIndex, max(0, allVLines.count - 1)))
        let targetEnd = min(allVLines.count, targetTop + max(0, height))
        let viewportLines = Array(allVLines[targetTop..<targetEnd])

        let (cursorVLineIdx, cursorVColIdx) = getVirtualCursor(
            lineIndex: cursorLineIndex,
            columnIndex: cursorColumnIndex,
            virtualLines: allVLines
        )

        return VirtualViewport(
            lines: viewportLines,
            startVirtualIndex: targetTop,
            totalVirtualLineCount: computeTotalLineCount ? allVLines.count : min(targetEnd, allVLines.count),
            cursorVirtualLineIndex: cursorVLineIdx,
            cursorVirtualColumnIndex: cursorVColIdx
        )
    }

    func computeVirtualLine(at virtualLineIndex: Int, from lines: [String], viewWidth: Int) -> VirtualLine? {
        let allVLines = computeVirtualLines(from: lines, viewWidth: viewWidth)
        guard virtualLineIndex >= 0 && virtualLineIndex < allVLines.count else { return nil }
        return allVLines[virtualLineIndex]
    }

    private func wrapLine(_ line: String, bufferLineIndex: Int, effectiveWrap: Int) -> [VirtualLine] {
        let chunks = computeLineChunks(line, effectiveWrap: effectiveWrap)
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

        let hangingIndent = listWrapIndent ? Self.calculateListHangingIndent(in: line) : 0

        if line.utf8.allSatisfy({ $0 < 0x80 }) {
            return asciiLineChunks(line, effectiveWrap: effectiveWrap, hangingIndent: hangingIndent)
        }

        return unicodeLineChunks(line, effectiveWrap: effectiveWrap, hangingIndent: hangingIndent)
    }

    private func unicodeLineChunks(_ line: String, effectiveWrap: Int, hangingIndent: Int) -> [CachedVirtualChunk] {
        var chunks: [CachedVirtualChunk] = []
        var currentCharIndex = 0
        var subIndex = 0
        let chars = Array(line)
        let totalChars = chars.count

        while currentCharIndex < totalChars {
            var currentWidth = 0
            var endIndex = currentCharIndex
            var lastWordBoundary = -1
            let chunkLimit =
                (subIndex > 0 && hangingIndent > 0) ? max(10, effectiveWrap - hangingIndent) : effectiveWrap

            while endIndex < totalChars {
                let ch = chars[endIndex]
                let w = ch.displayWidth

                if currentWidth + w > chunkLimit && endIndex > currentCharIndex {
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

    private func asciiLineChunks(_ line: String, effectiveWrap: Int, hangingIndent: Int) -> [CachedVirtualChunk] {
        let bytes = Array(line.utf8)
        var chunks: [CachedVirtualChunk] = []
        var currentIndex = 0
        var subIndex = 0

        while currentIndex < bytes.count {
            var endIndex = currentIndex
            var lastWordBoundary = -1
            let chunkLimit =
                (subIndex > 0 && hangingIndent > 0) ? max(10, effectiveWrap - hangingIndent) : effectiveWrap

            while endIndex < bytes.count {
                if endIndex - currentIndex + 1 > chunkLimit && endIndex > currentIndex {
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

    @discardableResult
    private func visitWrappedLine(
        _ line: String,
        bufferLineIndex: Int,
        effectiveWrap: Int,
        _ body: (VirtualLine) -> Bool
    ) -> Bool {
        let vLines = wrapLine(line, bufferLineIndex: bufferLineIndex, effectiveWrap: effectiveWrap)
        for vLine in vLines {
            if !body(vLine) {
                return false
            }
        }
        return true
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

    func computeCanvasLines(from lines: [String]) -> [VirtualLine] {
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
    func getVirtualCursor(
        lineIndex: Int,
        columnIndex: Int,
        virtualLines: [VirtualLine]
    ) -> (vLineIndex: Int, vColIndex: Int) {
        guard !virtualLines.isEmpty else { return (0, 0) }
        let targetLine = max(0, lineIndex)

        // Fast path: find starting index in virtualLines using cached lineOffsets
        var startIdx = 0
        cacheLock.lock()
        if targetLine < lineOffsets.count {
            startIdx = min(lineOffsets[targetLine], virtualLines.count - 1)
        }
        cacheLock.unlock()

        // Adjust startIdx in case proposal overlays shifted the offsets or lineOffsets wasn't exact
        if startIdx < virtualLines.count && virtualLines[startIdx].bufferLineIndex < targetLine {
            while startIdx < virtualLines.count && virtualLines[startIdx].bufferLineIndex < targetLine {
                startIdx += 1
            }
        } else if startIdx > 0 && startIdx < virtualLines.count && virtualLines[startIdx].bufferLineIndex > targetLine {
            while startIdx > 0 && virtualLines[startIdx - 1].bufferLineIndex >= targetLine {
                startIdx -= 1
            }
        }

        var matching: [(offset: Int, element: VirtualLine)] = []
        var idx = startIdx
        while idx < virtualLines.count && virtualLines[idx].bufferLineIndex == targetLine {
            if !virtualLines[idx].isProposalOverlay {
                matching.append((idx, virtualLines[idx]))
            }
            idx += 1
        }

        if matching.isEmpty {
            // Fallback to searching without non-proposal filter if only proposal exists
            idx = startIdx
            while idx < virtualLines.count && virtualLines[idx].bufferLineIndex == targetLine {
                matching.append((idx, virtualLines[idx]))
                idx += 1
            }
            if let first = matching.first {
                return (first.offset, 0)
            }
            return (0, 0)
        }

        for (i, item) in matching.enumerated() {
            let vIdx = item.offset
            let vLine = item.element
            let isLastSubline = (i == matching.count - 1)

            if isLastSubline {
                if columnIndex >= vLine.startCol && columnIndex <= vLine.endCol {
                    return (vIdx, columnIndex - vLine.startCol)
                }
            } else {
                if columnIndex >= vLine.startCol && columnIndex < vLine.endCol {
                    return (vIdx, columnIndex - vLine.startCol)
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
    func getBufferCursor(
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
