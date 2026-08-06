import Foundation

public struct MoveRightCommand: Command {
    public let id: CommandID = .moveRight
    public let name = "Forward"
    public let description = "Move forward a character"
    public let keys: [Key] = [.ctrl("F"), .arrowRight]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.isCanvasModeActive {
            editor.moveCanvasCursor(deltaLine: 0, deltaColumn: 1)
            return
        }
        editor.clearActiveMark()

        let currentLineLength = editor.buffer.lines[editor.buffer.lineIndex].count
        if editor.buffer.columnIndex < currentLineLength {
            editor.buffer.columnIndex += 1
        } else if editor.buffer.lineIndex < editor.buffer.lines.count - 1 {
            editor.buffer.lineIndex += 1
            editor.buffer.columnIndex = 0
        }
    }
}

public struct MoveLeftCommand: Command {
    public let id: CommandID = .moveLeft
    public let name = "Backward"
    public let description = "Move backward a character"
    public let keys: [Key] = [.ctrl("B"), .arrowLeft]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.isCanvasModeActive {
            editor.moveCanvasCursor(deltaLine: 0, deltaColumn: -1)
            return
        }
        editor.clearActiveMark()

        if editor.buffer.columnIndex > 0 {
            editor.buffer.columnIndex -= 1
        } else if editor.buffer.lineIndex > 0 {
            editor.buffer.lineIndex -= 1
            editor.buffer.columnIndex = editor.buffer.lines[editor.buffer.lineIndex].count
        }
    }
}

public struct MoveUpCommand: Command {
    public let id: CommandID = .moveUp
    public let name = "Previous Line"
    public let description = "Move to previous line"
    public let keys: [Key] = [.ctrl("P"), .arrowUp]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.isCanvasModeActive {
            editor.moveCanvasCursor(deltaLine: -1, deltaColumn: 0)
            return
        }
        editor.clearActiveMark()

        editor.moveCursorVirtual(deltaRow: -1)
    }
}

public struct MoveDownCommand: Command {
    public let id: CommandID = .moveDown
    public let name = "Next Line"
    public let description = "Move to next line"
    public let keys: [Key] = [.ctrl("N"), .arrowDown]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.isCanvasModeActive {
            editor.moveCanvasCursor(deltaLine: 1, deltaColumn: 0)
            return
        }
        editor.clearActiveMark()

        editor.moveCursorVirtual(deltaRow: 1)
    }
}

public struct MoveHomeCommand: Command {
    public let id: CommandID = .moveHome
    public let name = "Beginning of Line"
    public let description = "Move to beginning of line"
    public let keys: [Key] = [.ctrl("A"), .ctrl("a"), .home]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.isTableModeActive, let cell = editor.currentTableCell {
            editor.clearActiveMark()
            let line = editor.buffer.lines[editor.buffer.lineIndex]
            let (leftBorder, _) = Editor.findCellHorizontalBorders(in: line, nearCol: editor.buffer.columnIndex, cell: cell)
            editor.buffer.columnIndex = leftBorder + 1
            editor.clampTableModeCursor()
            return
        }
        if editor.isCanvasModeActive {
            editor.moveCanvasCursorToLineStart()
            return
        }
        editor.clearActiveMark()

        let vLine = editor.getVirtualLineForCursor()
        editor.buffer.columnIndex = vLine.startCol
    }
}

public struct MoveEndCommand: Command {
    public let id: CommandID = .moveEnd
    public let name = "End of Line"
    public let description = "Move to end of line"
    public let keys: [Key] = [.ctrl("E"), .ctrl("e"), .end]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.isTableModeActive, let cell = editor.currentTableCell {
            editor.clearActiveMark()
            let line = editor.buffer.lines[editor.buffer.lineIndex]
            let (leftBorder, rightBorder) = Editor.findCellHorizontalBorders(in: line, nearCol: editor.buffer.columnIndex, cell: cell)
            editor.buffer.columnIndex = max(leftBorder + 1, rightBorder - 1)
            editor.clampTableModeCursor()
            return
        }
        if editor.isCanvasModeActive {
            editor.moveCanvasCursorToLineEnd()
            return
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
            return
        }

        let vLine = virtualLines[cursorVLineIdx]
        let hasNextWrappedChunk =
            cursorVLineIdx + 1 < virtualLines.count
            && virtualLines[cursorVLineIdx + 1].bufferLineIndex == vLine.bufferLineIndex
        editor.buffer.columnIndex = hasNextWrappedChunk ? max(vLine.startCol, vLine.endCol - 1) : vLine.endCol
    }
}

public struct MovePgdnCommand: Command {
    public let id: CommandID = .movePgdn
    public let name = "Next Page"
    public let description = "Move forward one page"
    public let keys: [Key] = [.ctrl("V"), .ctrl("v"), .pageDown]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.isTableModeActive, let cell = editor.currentTableCell {
            editor.clearActiveMark()
            let vCol = editor.getVisualColumn(in: editor.buffer.lines[editor.buffer.lineIndex], col: editor.buffer.columnIndex)
            editor.buffer.lineIndex = cell.innerMaxLine
            editor.buffer.columnIndex = editor.getCharIndexForVisualColumn(
                in: editor.buffer.lines[editor.buffer.lineIndex], targetVisualCol: vCol)
            editor.clampTableModeCursor()
            return
        }
        let (rows, _) = editor.terminal.getWindowSize()
        let mainAreaHeight = max(1, rows - (editor.displayConfig.showRuler ? 5 : 4))
        if editor.isCanvasModeActive {
            editor.moveCanvasCursor(deltaLine: mainAreaHeight, deltaColumn: 0, extendDownward: true)
            return
        }
        editor.clearActiveMark()
        editor.moveCursorVirtual(deltaRow: mainAreaHeight)
    }
}

public struct MovePgupCommand: Command {
    public let id: CommandID = .movePgup
    public let name = "Previous Page"
    public let description = "Move backward one page"
    public let keys: [Key] = [.ctrl("Y"), .ctrl("y"), .pageUp]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.isTableModeActive, let cell = editor.currentTableCell {
            editor.clearActiveMark()
            let vCol = editor.getVisualColumn(in: editor.buffer.lines[editor.buffer.lineIndex], col: editor.buffer.columnIndex)
            editor.buffer.lineIndex = cell.innerMinLine
            editor.buffer.columnIndex = editor.getCharIndexForVisualColumn(
                in: editor.buffer.lines[editor.buffer.lineIndex], targetVisualCol: vCol)
            editor.clampTableModeCursor()
            return
        }
        let (rows, _) = editor.terminal.getWindowSize()
        let mainAreaHeight = max(1, rows - (editor.displayConfig.showRuler ? 5 : 4))
        if editor.isCanvasModeActive {
            editor.moveCanvasCursor(deltaLine: -mainAreaHeight, deltaColumn: 0)
            return
        }
        editor.clearActiveMark()
        editor.moveCursorVirtual(deltaRow: -mainAreaHeight)
    }
}

public struct MoveWordForwardCommand: Command {
    public let id: CommandID = .moveWordForward
    public let name = "Forward Word"
    public let description = "Move forward one word"
    public let keys: [Key] = [.ctrlShift("f"), .ctrlShift("F")]

    public init() {}

    public func execute(on editor: Editor) {
        if !editor.isCanvasModeActive {
            editor.clearActiveMark()
        }
        editor.buffer.moveWordForward()
    }
}

public struct MoveWordBackwardCommand: Command {
    public let id: CommandID = .moveWordBackward
    public let name = "Backward Word"
    public let description = "Move backward one word"
    public let keys: [Key] = [.ctrlShift("b"), .ctrlShift("B")]

    public init() {}

    public func execute(on editor: Editor) {
        if !editor.isCanvasModeActive {
            editor.clearActiveMark()
        }
        editor.buffer.moveWordBackward()
    }
}
