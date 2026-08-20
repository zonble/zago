import Foundation

struct SelectLeftCommand: Command {
    let id: CommandID = .selectLeft
    let name = "Select Left"
    let description = "Extend selection left"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
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

struct SelectRightCommand: Command {
    let id: CommandID = .selectRight
    let name = "Select Right"
    let description = "Extend selection right"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
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

struct SelectUpCommand: Command {
    let id: CommandID = .selectUp
    let name = "Select Up"
    let description = "Extend selection up"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        var message: String?
        if editor.buffer.selectionMark == nil {
            editor.buffer.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            message = editor.l10n["status.mark_set"]
        }
        editor.moveCursorVirtual(deltaRow: -1)
        return .succeeded(message: message)
    }
}

struct SelectDownCommand: Command {
    let id: CommandID = .selectDown
    let name = "Select Down"
    let description = "Extend selection down"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        var message: String?
        if editor.buffer.selectionMark == nil {
            editor.buffer.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            message = editor.l10n["status.mark_set"]
        }
        editor.moveCursorVirtual(deltaRow: 1)
        return .succeeded(message: message)
    }
}

struct SelectHomeCommand: Command {
    let id: CommandID = .selectHome
    let name = "Select Home"
    let description = "Extend selection to line start"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
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

struct SelectEndCommand: Command {
    let id: CommandID = .selectEnd
    let name = "Select End"
    let description = "Extend selection to line end"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
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

struct SelectPgupCommand: Command {
    let id: CommandID = .selectPgup
    let name = "Select Previous Page"
    let description = "Extend selection backward one page"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.isCanvasModeActive, !editor.isTableModeActive else { return .noOp }
        var message: String?
        if editor.buffer.selectionMark == nil {
            editor.buffer.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            message = editor.l10n["status.mark_set"]
        }
        let (rows, _) = editor.terminal.getWindowSize()
        let showRuler = editor.displayConfig.showRuler && !editor.buffer.isDirectoryBuffer
        let mainAreaHeight = max(1, rows - (showRuler ? 5 : 4))
        editor.moveCursorVirtual(deltaRow: -mainAreaHeight)
        return .succeeded(message: message)
    }
}

struct SelectPgdnCommand: Command {
    let id: CommandID = .selectPgdn
    let name = "Select Next Page"
    let description = "Extend selection forward one page"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.isCanvasModeActive, !editor.isTableModeActive else { return .noOp }
        var message: String?
        if editor.buffer.selectionMark == nil {
            editor.buffer.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            message = editor.l10n["status.mark_set"]
        }
        let (rows, _) = editor.terminal.getWindowSize()
        let showRuler = editor.displayConfig.showRuler && !editor.buffer.isDirectoryBuffer
        let mainAreaHeight = max(1, rows - (showRuler ? 5 : 4))
        editor.moveCursorVirtual(deltaRow: mainAreaHeight)
        return .succeeded(message: message)
    }
}

struct SelectAllCommand: Command {
    let id: CommandID = .selectAll
    let name = "Select All"
    let description = "Select all text in buffer"
    let commandBarAliases = ["selectall", "select-all"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
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
