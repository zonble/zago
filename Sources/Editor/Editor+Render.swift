import Foundation
import TextMetrics

extension Editor {
    /// Refreshes screen rendering directly using centralized Renderer with Double Buffering / Screen Line Diffing.
    func refreshScreen() {
        let (rows, cols) = terminal.getWindowSize()
        let output = renderer.renderDiff(editor: self, rows: rows, cols: cols)
        terminal.write(output)
        fflush(nil)
    }

    /// Adjusts topVLineIndex and canvasHorizontalOffset viewport scrolling bounds based on terminal dimensions.
    public func adjustViewport(mainAreaHeight: Int, textWidth: Int) {
        updateGitDiffIfNeeded()

        if isCanvasModeActive {
            ensureCanvasViewport(textWidth: textWidth)
            let virtualLines = layoutEngine.computeCanvasLines(from: buffer.lines)
            let cursorVLineIdx = max(0, min(buffer.lineIndex, max(0, virtualLines.count - 1)))

            if cursorVLineIdx < topVLineIndex {
                topVLineIndex = cursorVLineIdx
            } else if cursorVLineIdx >= topVLineIndex + max(1, mainAreaHeight - 1) {
                topVLineIndex = cursorVLineIdx - max(0, mainAreaHeight - 2)
            }
            let maxCanvasTop = max(0, virtualLines.count - max(1, mainAreaHeight - 1))
            topVLineIndex = max(0, min(topVLineIndex, maxCanvasTop))
        } else {
            let virtualLines = layoutEngine.computeVirtualLines(from: buffer.lines, viewWidth: textWidth)
            let (cursorVLineIdx, _) = layoutEngine.getVirtualCursor(
                lineIndex: buffer.lineIndex,
                columnIndex: buffer.columnIndex,
                virtualLines: virtualLines
            )

            if cursorVLineIdx < topVLineIndex {
                topVLineIndex = cursorVLineIdx
            } else if cursorVLineIdx >= topVLineIndex + mainAreaHeight {
                topVLineIndex = cursorVLineIdx - mainAreaHeight + 1
            }
        }
    }

    /// Returns the VirtualLine structure containing current cursor.
    func getVirtualLineForCursor() -> VirtualLine {
        let (_, cols) = terminal.getWindowSize()
        let textWidth = max(10, cols - 5)
        let viewport = layoutEngine.computeVirtualViewport(
            from: buffer.lines,
            viewWidth: textWidth,
            topVirtualLineIndex: 0,
            height: 0,
            cursorLineIndex: buffer.lineIndex,
            cursorColumnIndex: buffer.columnIndex,
            computeTotalLineCount: false
        )

        if let vLine = layoutEngine.computeVirtualLine(
            at: viewport.cursorVirtualLineIndex,
            from: buffer.lines,
            viewWidth: textWidth
        ) {
            return vLine
        }

        return VirtualLine(
            bufferLineIndex: buffer.lineIndex,
            subLineIndex: 0,
            text: buffer.lines[buffer.lineIndex],
            startCol: 0,
            endCol: buffer.lines[buffer.lineIndex].count
        )
    }

    /// Maps virtual line index and target visual display column width to real buffer cursor.
    func getBufferCursorForVisualColumn(
        vLineIndex: Int,
        visualCol: Int
    ) -> (lineIndex: Int, columnIndex: Int) {
        let (_, cols) = terminal.getWindowSize()
        let textWidth = max(10, cols - 5)
        guard
            let targetVLine = layoutEngine.computeVirtualLine(at: vLineIndex, from: buffer.lines, viewWidth: textWidth)
        else {
            return (buffer.lineIndex, buffer.columnIndex)
        }

        return bufferCursor(in: targetVLine, visualCol: visualCol)
    }

    /// Moves cursor by virtual line rows (sub-lines), supporting Home/End/Arrow key navigation.
    public func moveCursorVirtual(deltaRow: Int) {
        let (_, cols) = terminal.getWindowSize()
        let textWidth = max(10, cols - 5)
        let cursorViewport = layoutEngine.computeVirtualViewport(
            from: buffer.lines,
            viewWidth: textWidth,
            topVirtualLineIndex: 0,
            height: 0,
            cursorLineIndex: buffer.lineIndex,
            cursorColumnIndex: buffer.columnIndex,
            computeTotalLineCount: false
        )
        let cursorVLineIdx = cursorViewport.cursorVirtualLineIndex

        let targetVLineIdx = max(0, cursorVLineIdx + deltaRow)
        guard
            let currentVLine = layoutEngine.computeVirtualLine(
                at: cursorVLineIdx,
                from: buffer.lines,
                viewWidth: textWidth
            )
        else {
            return
        }
        let vLineChars = Array(currentVLine.text)
        let clampedCol = max(0, min(buffer.columnIndex - currentVLine.startCol, vLineChars.count))
        let visualCol = vLineChars[..<clampedCol].reduce(0) { $0 + $1.displayWidth }

        guard
            let targetVLine = layoutEngine.computeVirtualLine(
                at: targetVLineIdx,
                from: buffer.lines,
                viewWidth: textWidth
            )
        else {
            if deltaRow > 0 {
                buffer.lineIndex = max(0, buffer.lines.count - 1)
                buffer.columnIndex = buffer.lines.last?.count ?? 0
            }
            return
        }

        let (newLineIdx, newColIdx) = bufferCursor(in: targetVLine, visualCol: visualCol)

        buffer.lineIndex = newLineIdx
        buffer.columnIndex = newColIdx
    }

    private func bufferCursor(in targetVLine: VirtualLine, visualCol: Int) -> (lineIndex: Int, columnIndex: Int) {
        let chars = Array(targetVLine.text)
        var curW = 0
        var charIdx = 0

        for (idx, ch) in chars.enumerated() {
            let w = ch.displayWidth
            if curW + w > visualCol {
                break
            }
            curW += w
            charIdx = idx + 1
        }

        let realCol = min(targetVLine.startCol + charIdx, targetVLine.endCol)
        return (targetVLine.bufferLineIndex, realCol)
    }
}
