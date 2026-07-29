import Foundation
import TextMetrics

extension Editor {
    /// Refreshes screen rendering directly using centralized Renderer.
    func refreshScreen() {
        let (rows, cols) = terminal.getWindowSize()
        let output = renderer.render(editor: self, rows: rows, cols: cols)
        print(output, terminator: "")
        fflush(nil)
    }

    /// Returns the VirtualLine structure containing current cursor.
    func getVirtualLineForCursor() -> VirtualLine {
        let (_, cols) = terminal.getWindowSize()
        let textWidth = max(10, cols - 5)
        let virtualLines = layoutEngine.computeVirtualLines(from: buffer.lines, viewWidth: textWidth)

        let (cursorVLineIdx, _) = layoutEngine.getVirtualCursor(
            lineIndex: buffer.lineIndex,
            columnIndex: buffer.columnIndex,
            virtualLines: virtualLines
        )

        if cursorVLineIdx >= 0 && cursorVLineIdx < virtualLines.count {
            return virtualLines[cursorVLineIdx]
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
        let virtualLines = layoutEngine.computeVirtualLines(from: buffer.lines, viewWidth: textWidth)

        guard vLineIndex >= 0 && vLineIndex < virtualLines.count else {
            return (buffer.lineIndex, buffer.columnIndex)
        }

        let targetVLine = virtualLines[vLineIndex]
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

    /// Moves cursor by virtual line rows (sub-lines), supporting Home/End/Arrow key navigation.
    public func moveCursorVirtual(deltaRow: Int) {
        let (_, cols) = terminal.getWindowSize()
        let textWidth = max(10, cols - 5)
        let virtualLines = layoutEngine.computeVirtualLines(from: buffer.lines, viewWidth: textWidth)

        let (cursorVLineIdx, _) = layoutEngine.getVirtualCursor(
            lineIndex: buffer.lineIndex,
            columnIndex: buffer.columnIndex,
            virtualLines: virtualLines
        )

        if deltaRow > 0 && cursorVLineIdx == virtualLines.count - 1 {
            let lastLineText = buffer.lines[buffer.lineIndex]
            buffer.columnIndex = lastLineText.count
            return
        }

        let targetVLineIdx = max(0, min(cursorVLineIdx + deltaRow, virtualLines.count - 1))
        let currentVLine = virtualLines[cursorVLineIdx]
        let vLineChars = Array(currentVLine.text)
        let clampedCol = max(0, min(buffer.columnIndex - currentVLine.startCol, vLineChars.count))
        let visualCol = vLineChars[..<clampedCol].reduce(0) { $0 + $1.displayWidth }

        let (newLineIdx, newColIdx) = getBufferCursorForVisualColumn(
            vLineIndex: targetVLineIdx,
            visualCol: visualCol
        )

        buffer.lineIndex = newLineIdx
        buffer.columnIndex = newColIdx
    }
}
