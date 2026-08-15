import Foundation

public struct MoveRightCommand: Command {
    public let id: CommandID = .moveRight
    public let name = "Forward"
    public let description = "Move forward a character"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
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

public struct MoveLeftCommand: Command {
    public let id: CommandID = .moveLeft
    public let name = "Backward"
    public let description = "Move backward a character"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
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

public struct MoveUpCommand: Command {
    public let id: CommandID = .moveUp
    public let name = "Previous Line"
    public let description = "Move to previous line"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        if editor.isCanvasModeActive {
            editor.moveCanvasCursor(deltaLine: -1, deltaColumn: 0)
            return .succeeded
        }
        editor.clearActiveMark()

        editor.moveCursorVirtual(deltaRow: -1)
        return .succeeded
    }
}

public struct MoveDownCommand: Command {
    public let id: CommandID = .moveDown
    public let name = "Next Line"
    public let description = "Move to next line"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        if editor.isCanvasModeActive {
            editor.moveCanvasCursor(deltaLine: 1, deltaColumn: 0)
            return .succeeded
        }
        editor.clearActiveMark()

        editor.moveCursorVirtual(deltaRow: 1)
        return .succeeded
    }
}

public struct MoveHomeCommand: Command {
    public let id: CommandID = .moveHome
    public let name = "Beginning of Line"
    public let description = "Move to beginning of line"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
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

public struct MoveEndCommand: Command {
    public let id: CommandID = .moveEnd
    public let name = "End of Line"
    public let description = "Move to end of line"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
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

public struct GoToEndOfFileCommand: Command {
    public let id: CommandID = .cursorGotoEOF
    public let name = "Go To End of File"
    public let description = "Move to the end of the buffer"
    public let commandBarAliases = ["eof", "end-of-file", ":eof", ":end-of-file"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.buffer.lines.isEmpty else { return .noOp }
        editor.clearActiveMark()
        editor.buffer.lineIndex = editor.buffer.lines.count - 1
        editor.buffer.columnIndex = editor.buffer.lines[editor.buffer.lineIndex].count
        editor.buffer.clampCursor()
        return .succeeded
    }
}

public struct MovePgdnCommand: Command {
    public let id: CommandID = .movePgdn
    public let name = "Next Page"
    public let description = "Move forward one page"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
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
        let (rows, _) = editor.terminal.getWindowSize()
        let showRuler = editor.displayConfig.showRuler && !editor.buffer.isDirectoryBuffer
        let mainAreaHeight = max(1, rows - (showRuler ? 5 : 4))
        if editor.isCanvasModeActive {
            editor.moveCanvasCursor(deltaLine: mainAreaHeight, deltaColumn: 0, extendDownward: true)
            return .succeeded
        }
        editor.clearActiveMark()
        editor.moveCursorVirtual(deltaRow: mainAreaHeight)
        return .succeeded
    }
}

public struct MovePgupCommand: Command {
    public let id: CommandID = .movePgup
    public let name = "Previous Page"
    public let description = "Move backward one page"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
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
        let (rows, _) = editor.terminal.getWindowSize()
        let showRuler = editor.displayConfig.showRuler && !editor.buffer.isDirectoryBuffer
        let mainAreaHeight = max(1, rows - (showRuler ? 5 : 4))
        if editor.isCanvasModeActive {
            editor.moveCanvasCursor(deltaLine: -mainAreaHeight, deltaColumn: 0)
            return .succeeded
        }
        editor.clearActiveMark()
        editor.moveCursorVirtual(deltaRow: -mainAreaHeight)
        return .succeeded
    }
}

public struct MoveWordForwardCommand: Command {
    public let id: CommandID = .moveWordForward
    public let name = "Forward Word"
    public let description = "Move forward one word"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        if !editor.isCanvasModeActive {
            editor.clearActiveMark()
        }
        editor.buffer.moveWordForward()
        return .succeeded
    }
}

public struct MoveWordBackwardCommand: Command {
    public let id: CommandID = .moveWordBackward
    public let name = "Backward Word"
    public let description = "Move backward one word"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        if !editor.isCanvasModeActive {
            editor.clearActiveMark()
        }
        editor.buffer.moveWordBackward()
        return .succeeded
    }
}
