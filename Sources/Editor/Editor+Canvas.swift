import Foundation
import TextMetrics

extension Editor {
    public func syncCanvasCursorFromBuffer() {
        guard buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count else {
            canvasVisualColumn = 0
            return
        }
        canvasVisualColumn = buffer.lines[buffer.lineIndex].visualColumn(forCharacterOffset: buffer.columnIndex)
    }

    public func syncCanvasCursorToBuffer() {
        ensureCanvasLineExists(buffer.lineIndex)
        let line = buffer.lines[buffer.lineIndex]
        buffer.columnIndex = line.characterOffset(forVisualColumn: canvasVisualColumn)
    }

    public func moveCanvasCursor(deltaLine: Int, deltaColumn: Int, extendDownward: Bool = true) {
        let targetLine = buffer.lineIndex + deltaLine
        if extendDownward && deltaLine > 0 {
            ensureCanvasLineExists(targetLine)
        }
        buffer.lineIndex = max(0, min(targetLine, buffer.lines.count - 1))
        canvasVisualColumn = max(0, canvasVisualColumn + deltaColumn)
        syncCanvasCursorToBuffer()
    }

    public func moveCanvasCursorToLineStart() {
        canvasVisualColumn = 0
        syncCanvasCursorToBuffer()
    }

    public func moveCanvasCursorToLineEnd() {
        ensureCanvasLineExists(buffer.lineIndex)
        canvasVisualColumn = buffer.lines[buffer.lineIndex].displayWidth
        syncCanvasCursorToBuffer()
    }

    public func insertCanvasCharacter(_ ch: Character) {
        ensureCanvasLineExists(buffer.lineIndex)
        let result = buffer.lines[buffer.lineIndex].writingAtVisualColumn(canvasVisualColumn, character: ch)
        buffer.lines[buffer.lineIndex] = result.text
        canvasVisualColumn = result.visualColumnAfterWrite
        buffer.columnIndex = result.characterOffsetAfterWrite
        buffer.isModified = true
    }

    public func insertCanvasString(_ text: String) {
        let startColumn = canvasVisualColumn
        let lines = text.components(separatedBy: .newlines)
        guard !lines.isEmpty else { return }

        for (lineOffset, segment) in lines.enumerated() {
            if lineOffset > 0 {
                buffer.lineIndex += 1
                ensureCanvasLineExists(buffer.lineIndex)
                canvasVisualColumn = startColumn
            }

            for ch in segment {
                insertCanvasCharacter(ch)
            }
        }
    }

    public func insertCanvasNewline() {
        let insertIndex = min(buffer.lineIndex + 1, buffer.lines.count)
        buffer.lines.insert("", at: insertIndex)
        buffer.lineIndex = insertIndex
        canvasVisualColumn = 0
        buffer.isModified = true
        syncCanvasCursorToBuffer()
    }

    public func deleteCanvasCharacter() {
        ensureCanvasLineExists(buffer.lineIndex)
        let result = buffer.lines[buffer.lineIndex].clearingAtVisualColumn(canvasVisualColumn)
        buffer.lines[buffer.lineIndex] = result.text
        buffer.columnIndex = result.characterOffsetAfterWrite
        buffer.isModified = true
        syncCanvasCursorToBuffer()
    }

    public func backspaceCanvasCharacter() {
        guard canvasVisualColumn > 0 else {
            buffer.deleteLine()
            canvasVisualColumn = 0
            syncCanvasCursorToBuffer()
            return
        }
        ensureCanvasLineExists(buffer.lineIndex)
        let line = buffer.lines[buffer.lineIndex]
        let targetColumn: Int
        if canvasVisualColumn > line.displayWidth {
            targetColumn = canvasVisualColumn - 1
        } else {
            targetColumn = line.snappedVisualColumn(canvasVisualColumn - 1, direction: .backward)
        }

        canvasVisualColumn = max(0, targetColumn)
        let result = buffer.lines[buffer.lineIndex].clearingAtVisualColumn(canvasVisualColumn)
        buffer.lines[buffer.lineIndex] = result.text
        buffer.isModified = true
        syncCanvasCursorToBuffer()
    }

    public func ensureCanvasViewport(textWidth: Int) {
        let width = max(1, textWidth)
        if canvasVisualColumn < canvasHorizontalOffset {
            canvasHorizontalOffset = (canvasVisualColumn / width) * width
        } else if canvasVisualColumn >= canvasHorizontalOffset + width {
            canvasHorizontalOffset = (canvasVisualColumn / width) * width
        }
    }

    private func ensureCanvasLineExists(_ lineIndex: Int) {
        guard lineIndex >= 0 else { return }
        while buffer.lines.count <= lineIndex {
            buffer.lines.append("")
        }
    }
}
