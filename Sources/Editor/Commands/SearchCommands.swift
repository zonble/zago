import Foundation

public struct WhereIsCommand: Command {
    public let id: CommandID = .searchWhereIs
    public let name = "Where Is"
    public let description = "Search text"
    public let keys: [Key] = [.ctrl("W"), .f6]

    public init() {}

    public func execute(on editor: Editor) {
        editor.promptSearch()
    }
}

public struct GotoLineCommand: Command {
    public let id: CommandID = .cursorGotoLine
    public let name = "Go To Line"
    public let description = "Jump to line and column number"
    public let keys: [Key] = [.ctrl("/"), .ctrl("_"), .alt("g"), .alt("G"), .alt("/")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.promptGotoLine()
    }
}

public struct RefreshScreenCommand: Command {
    public let id: CommandID = .screenRefresh
    public let name = "Refresh"
    public let description = "Refresh screen"
    public let keys: [Key] = [.ctrl("L")]

    public init() {}

    public func execute(on editor: Editor) {}
}

public struct ShowCursorPosCommand: Command {
    public let id: CommandID = .cursorPos
    public let name = "Cur Pos"
    public let description = "Display cursor position"
    public let keys: [Key] = [.ctrl("C"), .f11]

    public init() {}

    public func execute(on editor: Editor) {
        let currentLine = editor.buffer.lineIndex + 1
        let totalLines = editor.buffer.lines.count
        let percent = totalLines > 0 ? Int(Double(currentLine) / Double(totalLines) * 100) : 100
        let currentCol = editor.buffer.columnIndex + 1
        let totalCol = editor.buffer.lines[editor.buffer.lineIndex].count + 1
        editor.setStatusMessage(
            L10n.cursorInfo(
                currentLine: currentLine, totalLines: totalLines, percent: percent, currentCol: currentCol,
                totalCol: totalCol))
    }
}
