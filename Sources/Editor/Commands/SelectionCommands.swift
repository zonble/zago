import Foundation

public struct SelectLeftCommand: Command {
    public let id: CommandID = .selectLeft
    public let name = "Select Left"
    public let description = "Extend selection left"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        var message: String?
        if editor.buffer.selectionMark == nil {
            editor.buffer.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            message = editor.l10n["status.mark_set"]
        }
        if editor.buffer.columnIndex > 0 {
            editor.buffer.columnIndex -= 1
        } else if editor.buffer.lineIndex > 0 {
            editor.buffer.lineIndex -= 1
            editor.buffer.columnIndex = editor.buffer.lines[editor.buffer.lineIndex].count
        }
        return .succeeded(message: message)
    }
}

public struct SelectRightCommand: Command {
    public let id: CommandID = .selectRight
    public let name = "Select Right"
    public let description = "Extend selection right"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        var message: String?
        if editor.buffer.selectionMark == nil {
            editor.buffer.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            message = editor.l10n["status.mark_set"]
        }
        let currentLineLength = editor.buffer.lines[editor.buffer.lineIndex].count
        if editor.buffer.columnIndex < currentLineLength {
            editor.buffer.columnIndex += 1
        } else if editor.buffer.lineIndex < editor.buffer.lines.count - 1 {
            editor.buffer.lineIndex += 1
            editor.buffer.columnIndex = 0
        }
        return .succeeded(message: message)
    }
}

public struct SelectUpCommand: Command {
    public let id: CommandID = .selectUp
    public let name = "Select Up"
    public let description = "Extend selection up"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        var message: String?
        if editor.buffer.selectionMark == nil {
            editor.buffer.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            message = editor.l10n["status.mark_set"]
        }
        editor.moveCursorVirtual(deltaRow: -1)
        return .succeeded(message: message)
    }
}

public struct SelectDownCommand: Command {
    public let id: CommandID = .selectDown
    public let name = "Select Down"
    public let description = "Extend selection down"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        var message: String?
        if editor.buffer.selectionMark == nil {
            editor.buffer.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            message = editor.l10n["status.mark_set"]
        }
        editor.moveCursorVirtual(deltaRow: 1)
        return .succeeded(message: message)
    }
}

public struct SelectHomeCommand: Command {
    public let id: CommandID = .selectHome
    public let name = "Select Home"
    public let description = "Extend selection to line start"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.isCanvasModeActive, !editor.isTableModeActive else { return .noOp }
        var message: String?
        if editor.buffer.selectionMark == nil {
            editor.buffer.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            message = editor.l10n["status.mark_set"]
        }
        editor.buffer.columnIndex = 0
        return .succeeded(message: message)
    }
}

public struct SelectEndCommand: Command {
    public let id: CommandID = .selectEnd
    public let name = "Select End"
    public let description = "Extend selection to line end"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.isCanvasModeActive, !editor.isTableModeActive else { return .noOp }
        var message: String?
        if editor.buffer.selectionMark == nil {
            editor.buffer.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            message = editor.l10n["status.mark_set"]
        }
        editor.buffer.columnIndex = editor.buffer.lines[editor.buffer.lineIndex].count
        return .succeeded(message: message)
    }
}

public struct SelectAllCommand: Command {
    public let id: CommandID = .selectAll
    public let name = "Select All"
    public let description = "Select all text in buffer"
    public let commandBarAliases = ["selectall", "select-all"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.buffer.lines.isEmpty else { return .noOp }
        if editor.isCanvasModeActive && !editor.isTableModeActive {
            let maxCol = editor.buffer.lines.map(\.displayWidth).max() ?? 0
            let lastLine = max(0, editor.buffer.lines.count - 1)
            let rightCol = max(0, maxCol > 0 ? maxCol - 1 : 0)
            editor.buffer.canvasBlockMark = (line: 0, visualColumn: 0)
            editor.buffer.canvasBlockMarkEnd = (line: lastLine, visualColumn: rightCol)
            editor.buffer.lineIndex = lastLine
            editor.canvasVisualColumn = rightCol
            editor.syncCanvasCursorToBuffer()
            return .succeeded(message: editor.l10n["status.mark_set"])
        } else {
            editor.buffer.selectionMark = (line: 0, column: 0)
            let lastLine = editor.buffer.lines.count - 1
            editor.buffer.lineIndex = lastLine
            editor.buffer.columnIndex = editor.buffer.lines[lastLine].count
            return .succeeded(message: editor.l10n["status.mark_set"])
        }
    }
}
