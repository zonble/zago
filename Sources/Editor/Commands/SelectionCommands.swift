import Foundation

public struct SelectLeftCommand: Command {
    public let id: CommandID = .selectLeft
    public let name = "Select Left"
    public let description = "Extend selection left"
    public let keys: [Key] = [.shiftArrowLeft]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.selectionMark == nil {
            editor.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            editor.setStatusMessage(L10n["status.mark_set"])
        }
        if editor.buffer.columnIndex > 0 {
            editor.buffer.columnIndex -= 1
        } else if editor.buffer.lineIndex > 0 {
            editor.buffer.lineIndex -= 1
            editor.buffer.columnIndex = editor.buffer.lines[editor.buffer.lineIndex].count
        }
    }
}

public struct SelectRightCommand: Command {
    public let id: CommandID = .selectRight
    public let name = "Select Right"
    public let description = "Extend selection right"
    public let keys: [Key] = [.shiftArrowRight]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.selectionMark == nil {
            editor.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            editor.setStatusMessage(L10n["status.mark_set"])
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

public struct SelectUpCommand: Command {
    public let id: CommandID = .selectUp
    public let name = "Select Up"
    public let description = "Extend selection up"
    public let keys: [Key] = [.shiftArrowUp]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.selectionMark == nil {
            editor.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            editor.setStatusMessage(L10n["status.mark_set"])
        }
        editor.moveCursorVirtual(deltaRow: -1)
    }
}

public struct SelectDownCommand: Command {
    public let id: CommandID = .selectDown
    public let name = "Select Down"
    public let description = "Extend selection down"
    public let keys: [Key] = [.shiftArrowDown]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.selectionMark == nil {
            editor.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            editor.setStatusMessage(L10n["status.mark_set"])
        }
        editor.moveCursorVirtual(deltaRow: 1)
    }
}
