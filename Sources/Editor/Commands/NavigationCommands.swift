import Foundation

struct MoveRightCommand: Command {
    let id: CommandID = .moveRight
    let name = "Forward"
    let description = "Move forward a character"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        if editor.isCanvasModeActive {
            editor.moveCanvasCursor(deltaLine: 0, deltaColumn: 1)
            return .succeeded
        }
        editor.clearActiveMark()

        let currentLineLength = editor.buffer.lines[editor.buffer.lineIndex].count
        if editor.buffer.columnIndex < currentLineLength {
            editor.buffer.columnIndex += 1
        } else if editor.buffer.lineIndex < editor.buffer.lines.count - 1 {
            editor.buffer.lineIndex += 1
            editor.buffer.columnIndex = 0
        }
        return .succeeded
    }
}

struct MoveLeftCommand: Command {
    let id: CommandID = .moveLeft
    let name = "Backward"
    let description = "Move backward a character"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        if editor.isCanvasModeActive {
            editor.moveCanvasCursor(deltaLine: 0, deltaColumn: -1)
            return .succeeded
        }
        editor.clearActiveMark()

        if editor.buffer.columnIndex > 0 {
            editor.buffer.columnIndex -= 1
        } else if editor.buffer.lineIndex > 0 {
            editor.buffer.lineIndex -= 1
            editor.buffer.columnIndex = editor.buffer.lines[editor.buffer.lineIndex].count
        }
        return .succeeded
    }
}

struct MoveUpCommand: Command {
    let id: CommandID = .moveUp
    let name = "Previous Line"
    let description = "Move to previous line"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        if editor.isCanvasModeActive {
            editor.moveCanvasCursor(deltaLine: -1, deltaColumn: 0)
            return .succeeded
        }
        editor.clearActiveMark()

        editor.moveCursorVirtual(deltaRow: -1)
        return .succeeded
    }
}

struct MoveDownCommand: Command {
    let id: CommandID = .moveDown
    let name = "Next Line"
    let description = "Move to next line"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        if editor.isCanvasModeActive {
            editor.moveCanvasCursor(deltaLine: 1, deltaColumn: 0)
            return .succeeded
        }
        editor.clearActiveMark()

        editor.moveCursorVirtual(deltaRow: 1)
        return .succeeded
    }
}

struct MoveHomeCommand: Command {
    let id: CommandID = .moveHome
    let name = "Beginning of Line"
    let description = "Move to beginning of line"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        if editor.isTableModeActive, let cell = editor.currentTableCell {
            editor.clearActiveMark()
            let line = editor.buffer.lines[editor.buffer.lineIndex]
            let (leftBorder, _) = TableModeController.findCellHorizontalBorders(
                in: line, nearCol: editor.buffer.columnIndex, cell: cell)
            editor.buffer.columnIndex = leftBorder + 1
            editor.tableModeController.clampTableModeCursor()
            return .succeeded
        }
        if editor.isCanvasModeActive {
            editor.moveCanvasCursorToLineStart()
            return .succeeded
        }
        editor.clearActiveMark()

        let vLine = editor.getVirtualLineForCursor()
        editor.buffer.columnIndex = vLine.startCol
        return .succeeded
    }
}

struct MoveEndCommand: Command {
    let id: CommandID = .moveEnd
    let name = "End of Line"
    let description = "Move to end of line"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        if editor.isTableModeActive, let cell = editor.currentTableCell {
            editor.clearActiveMark()
            let line = editor.buffer.lines[editor.buffer.lineIndex]
            let (leftBorder, rightBorder) = TableModeController.findCellHorizontalBorders(
                in: line, nearCol: editor.buffer.columnIndex, cell: cell)
            editor.buffer.columnIndex = max(leftBorder + 1, rightBorder - 1)
            editor.tableModeController.clampTableModeCursor()
            return .succeeded
        }
        if editor.isCanvasModeActive {
            editor.moveCanvasCursorToLineEnd()
            return .succeeded
        }
        editor.clearActiveMark()

        let (_, cols) = editor.terminal.getWindowSize()
        let textWidth = max(10, cols - 5)
        let virtualLines = editor.layoutEngine.computeVirtualLines(from: editor.buffer.lines, viewWidth: textWidth)
        let (cursorVLineIdx, _) = editor.layoutEngine.getVirtualCursor(
            lineIndex: editor.buffer.lineIndex,
            columnIndex: editor.buffer.columnIndex,
            virtualLines: virtualLines
        )

        guard cursorVLineIdx >= 0 && cursorVLineIdx < virtualLines.count else {
            editor.buffer.columnIndex = editor.buffer.lines[editor.buffer.lineIndex].count
            return .succeeded
        }

        let vLine = virtualLines[cursorVLineIdx]
        let hasNextWrappedChunk =
            cursorVLineIdx + 1 < virtualLines.count
            && virtualLines[cursorVLineIdx + 1].bufferLineIndex == vLine.bufferLineIndex
        editor.buffer.columnIndex = hasNextWrappedChunk ? max(vLine.startCol, vLine.endCol - 1) : vLine.endCol
        return .succeeded
    }
}

struct GoToEndOfFileCommand: Command {
    let id: CommandID = .cursorGotoEOF
    let name = "Go To End of File"
    let description = "Move to the end of the buffer"
    let commandBarAliases = ["eof", "end-of-file", ":eof", ":end-of-file"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.buffer.lines.isEmpty else { return .noOp }
        if !editor.isCanvasModeActive {
            editor.clearActiveMark()
        }
        editor.buffer.lineIndex = editor.buffer.lines.count - 1
        editor.buffer.columnIndex = editor.buffer.lines[editor.buffer.lineIndex].count
        editor.buffer.clampCursor()
        return .succeeded
    }
}

struct MovePgdnCommand: Command {
    let id: CommandID = .movePgdn
    let name = "Next Page"
    let description = "Move forward one page"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        if editor.isTableModeActive, let cell = editor.currentTableCell {
            editor.clearActiveMark()
            let vCol = editor.tableModeController.getVisualColumn(
                in: editor.buffer.lines[editor.buffer.lineIndex], col: editor.buffer.columnIndex)
            editor.buffer.lineIndex = cell.innerMaxLine
            editor.buffer.columnIndex = editor.tableModeController.getCharIndexForVisualColumn(
                in: editor.buffer.lines[editor.buffer.lineIndex], targetVisualCol: vCol)
            editor.tableModeController.clampTableModeCursor()
            return .succeeded
        }
        let (rows, cols) = editor.terminal.getWindowSize()
        let mainAreaHeight = ScreenGeometry(rows: rows, cols: cols, editor: editor).mainAreaHeight
        if editor.isCanvasModeActive {
            let targetLine = min(
                editor.buffer.lines.count - 1,
                editor.buffer.lineIndex + mainAreaHeight
            )
            editor.buffer.lineIndex = max(0, targetLine)
            editor.syncCanvasCursorToBuffer()
            return .succeeded
        }
        editor.clearActiveMark()
        editor.moveCursorVirtual(deltaRow: mainAreaHeight)
        return .succeeded
    }
}

struct MovePgupCommand: Command {
    let id: CommandID = .movePgup
    let name = "Previous Page"
    let description = "Move backward one page"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        if editor.isTableModeActive, let cell = editor.currentTableCell {
            editor.clearActiveMark()
            let vCol = editor.tableModeController.getVisualColumn(
                in: editor.buffer.lines[editor.buffer.lineIndex], col: editor.buffer.columnIndex)
            editor.buffer.lineIndex = cell.innerMinLine
            editor.buffer.columnIndex = editor.tableModeController.getCharIndexForVisualColumn(
                in: editor.buffer.lines[editor.buffer.lineIndex], targetVisualCol: vCol)
            editor.tableModeController.clampTableModeCursor()
            return .succeeded
        }
        let (rows, cols) = editor.terminal.getWindowSize()
        let mainAreaHeight = ScreenGeometry(rows: rows, cols: cols, editor: editor).mainAreaHeight
        if editor.isCanvasModeActive {
            editor.buffer.lineIndex = max(0, editor.buffer.lineIndex - mainAreaHeight)
            editor.syncCanvasCursorToBuffer()
            return .succeeded
        }
        editor.clearActiveMark()
        editor.moveCursorVirtual(deltaRow: -mainAreaHeight)
        return .succeeded
    }
}

struct MoveWordForwardCommand: Command {
    let id: CommandID = .moveWordForward
    let name = "Forward Word"
    let description = "Move forward one word"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        if !editor.isCanvasModeActive {
            editor.clearActiveMark()
        }
        editor.buffer.moveWordForward()
        return .succeeded
    }
}

struct MoveWordBackwardCommand: Command {
    let id: CommandID = .moveWordBackward
    let name = "Backward Word"
    let description = "Move backward one word"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        if !editor.isCanvasModeActive {
            editor.clearActiveMark()
        }
        editor.buffer.moveWordBackward()
        return .succeeded
    }
}
