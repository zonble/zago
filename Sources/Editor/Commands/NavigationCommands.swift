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

        editor.moveCursorVirtual(deltaRow: 1)
    }
}

public struct MoveHomeCommand: Command {
    public let id: CommandID = .moveHome
    public let name = "Beginning of Line"
    public let description = "Move to beginning of line"
    public let keys: [Key] = [.ctrl("A"), .home]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.isCanvasModeActive {
            editor.moveCanvasCursorToLineStart()
            return
        }

        let vLine = editor.getVirtualLineForCursor()
        editor.buffer.columnIndex = vLine.startCol
    }
}

public struct MoveEndCommand: Command {
    public let id: CommandID = .moveEnd
    public let name = "End of Line"
    public let description = "Move to end of line"
    public let keys: [Key] = [.ctrl("E"), .end]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.isCanvasModeActive {
            editor.moveCanvasCursorToLineEnd()
            return
        }

        let vLine = editor.getVirtualLineForCursor()
        editor.buffer.columnIndex = vLine.endCol
    }
}

public struct MovePgdnCommand: Command {
    public let id: CommandID = .movePgdn
    public let name = "Next Page"
    public let description = "Move forward one page"
    public let keys: [Key] = [.ctrl("V"), .f8, .pageDown]

    public init() {}

    public func execute(on editor: Editor) {
        let (rows, _) = editor.terminal.getWindowSize()
        let mainAreaHeight = max(1, rows - (editor.displayConfig.showRuler ? 5 : 4))
        if editor.isCanvasModeActive {
            editor.moveCanvasCursor(deltaLine: mainAreaHeight, deltaColumn: 0)
            return
        }
        editor.moveCursorVirtual(deltaRow: mainAreaHeight)
    }
}

public struct MovePgupCommand: Command {
    public let id: CommandID = .movePgup
    public let name = "Previous Page"
    public let description = "Move backward one page"
    public let keys: [Key] = [.ctrl("Y"), .f7, .pageUp]

    public init() {}

    public func execute(on editor: Editor) {
        let (rows, _) = editor.terminal.getWindowSize()
        let mainAreaHeight = max(1, rows - (editor.displayConfig.showRuler ? 5 : 4))
        if editor.isCanvasModeActive {
            editor.moveCanvasCursor(deltaLine: -mainAreaHeight, deltaColumn: 0)
            return
        }
        editor.moveCursorVirtual(deltaRow: -mainAreaHeight)
    }
}
