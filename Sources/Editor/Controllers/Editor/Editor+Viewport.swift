import Foundation
import TextMetrics

extension Editor {
    /// Computes virtual lines including AI proposal overlays once for viewport adjustment and rendering.
    func prepareVirtualLines(textWidth: Int) -> [VirtualLine] {
        if isCanvasModeActive {
            let baseCanvasLines = layoutEngine.computeCanvasLines(from: buffer.lines)
            return renderer.expandVirtualLinesWithProposal(
                virtualLines: baseCanvasLines, editor: self, textWidth: textWidth)
        } else {
            let baseVLines = layoutEngine.computeVirtualLines(from: buffer.lines, viewWidth: textWidth)
            return renderer.expandVirtualLinesWithProposal(
                virtualLines: baseVLines, editor: self, textWidth: textWidth)
        }
    }

    /// Refreshes screen rendering directly using centralized Renderer with Double Buffering / Screen Line Diffing.
    func refreshScreen() {
        let (rows, cols) = terminal.getWindowSize()
        let geometry = ScreenGeometry(rows: rows, cols: cols, editor: self)

        let virtualLines = prepareVirtualLines(textWidth: geometry.textWidth)
        adjustViewport(mainAreaHeight: geometry.mainAreaHeight, textWidth: geometry.textWidth, virtualLines: virtualLines)

        let output = renderer.renderDiff(editor: self, geometry: geometry, precomputedVirtualLines: virtualLines)
        terminal.write(output)
        fflush(nil)
    }

    /// Adjusts topVLineIndex and canvasHorizontalOffset viewport scrolling bounds based on terminal dimensions.
    func adjustViewport(mainAreaHeight: Int, textWidth: Int, virtualLines: [VirtualLine]? = nil) {
        updateGitDiffIfNeeded()

        let vLines = virtualLines ?? prepareVirtualLines(textWidth: textWidth)

        if isCanvasModeActive {
            ensureCanvasViewport(textWidth: textWidth)
            let cursorVLineIdx = max(0, min(buffer.lineIndex, max(0, vLines.count - 1)))

            if cursorVLineIdx < topVLineIndex {
                topVLineIndex = cursorVLineIdx
            } else if cursorVLineIdx >= topVLineIndex + max(1, mainAreaHeight - 1) {
                topVLineIndex = cursorVLineIdx - max(0, mainAreaHeight - 2)
            }
            let maxCanvasTop = max(0, vLines.count - max(1, mainAreaHeight - 1))
            topVLineIndex = max(0, min(topVLineIndex, maxCanvasTop))
        } else {
            let (cursorVLineIdx, _) = layoutEngine.getVirtualCursor(
                lineIndex: buffer.lineIndex,
                columnIndex: buffer.columnIndex,
                virtualLines: vLines
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
    func moveCursorVirtual(deltaRow: Int) {
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
        let line = buffer.lines[targetVLine.bufferLineIndex]
        let hangingIndent =
            (targetVLine.subLineIndex > 0 && displayConfig.listWrapIndent)
            ? LayoutEngine.calculateListHangingIndent(in: line) : 0
        let adjustedVisualCol = max(0, visualCol - hangingIndent)

        let chars = Array(targetVLine.text)
        var curW = 0
        var charIdx = 0

        for (idx, ch) in chars.enumerated() {
            let w = ch.displayWidth
            if curW + w > adjustedVisualCol {
                break
            }
            curW += w
            charIdx = idx + 1
        }

        let realCol = min(targetVLine.startCol + charIdx, targetVLine.endCol)
        return (targetVLine.bufferLineIndex, realCol)
    }
}
