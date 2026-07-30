import Foundation

public struct DeleteLineCommand: Command {
    public let id: CommandID = .editDeleteLine
    public let name = "Delete Line"
    public let description = "Delete current line"
    public let keys: [Key] = [.ctrlBackspace, .ctrl("H"), .ctrl("h")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.saveUndoSnapshot()
        editor.deleteCurrentLine()
    }
}

public struct DeleteCharCommand: Command {
    public let id: CommandID = .editDelete
    public let name = "Delete"
    public let description = "Delete character under cursor"
    public let keys: [Key] = [.ctrl("D"), .delete]

    public init() {}

    public func execute(on editor: Editor) {
        editor.saveUndoSnapshot()
        if editor.isCanvasModeActive {
            editor.deleteCanvasCharacter()
            return
        }
        editor.buffer.delete()
    }
}

public struct ToggleMarkCommand: Command {
    public let id: CommandID = .editMark
    public let name = "Mark"
    public let description = "Set or unset selection mark"
    public let keys: [Key] = [.mark]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.selectionMark == nil {
            editor.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            editor.setStatusMessage(L10n["status.mark_set"])
        } else {
            editor.selectionMark = nil
            editor.setStatusMessage(L10n["status.mark_unset"])
        }
    }
}

public struct CutTextCommand: Command {
    public let id: CommandID = .editCut
    public let name = "Cut Text"
    public let description = "Cut selected text or line"
    public let keys: [Key] = [.ctrl("K"), .f9]

    public init() {}

    public func execute(on editor: Editor) {
        editor.saveUndoSnapshot()
        editor.buffer.clampCursor()
        if let mark = editor.selectionMark {
            let (start, end) = editor.getOrderedRange(
                mark1: mark, mark2: (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex))

            editor.clipboardText = editor.buffer.cutRange(
                start: (line: start.line, col: start.column), end: (line: end.line, col: end.column))
            editor.selectionMark = nil
            editor.setStatusMessage(L10n["status.cut_text"])
        } else {
            let currentLine = editor.buffer.lines[editor.buffer.lineIndex]
            editor.clipboardText = currentLine + "\n"
            if editor.buffer.lines.count > 1 {
                editor.buffer.lines.remove(at: editor.buffer.lineIndex)
            } else {
                editor.buffer.lines[0] = ""
            }
            editor.buffer.isModified = true
            editor.setStatusMessage(L10n["status.cut_one_line"])
        }
    }
}

public struct UncutTextCommand: Command {
    public let id: CommandID = .editUncut
    public let name = "UnCut Text"
    public let description = "Paste cut text"
    public let keys: [Key] = [.ctrl("U"), .f10]

    public init() {}

    public func execute(on editor: Editor) {
        if let text = editor.clipboardText, !text.isEmpty {
            editor.saveUndoSnapshot()
            if editor.isCanvasModeActive {
                editor.insertCanvasString(text)
            } else {
                editor.buffer.insertString(text)
            }
            editor.setStatusMessage(L10n["status.uncut_text"])
        } else {
            editor.setStatusMessage(L10n["status.clipboard_empty"])
        }
    }
}

public struct InsertTabCommand: Command {
    public let id: CommandID = .editTab
    public let name = "Insert Tab"
    public let description = "Insert tab spaces"
    public let keys: [Key] = [.tab, .ctrl("I"), .ctrl("i")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.saveUndoSnapshot()
        if editor.isCanvasModeActive {
            editor.insertCanvasString("    ")
        } else {
            editor.buffer.insertString("    ")
        }
    }
}

public struct UndoCommand: Command {
    public let id: CommandID = .editUndo
    public let name = "Undo"
    public let description = "Undo last edit"
    public let keys: [Key] = [.ctrl("Z")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.performUndo()
    }
}

public struct JustifyParagraphCommand: Command {
    public let id: CommandID = .editJustify
    public let name = "Justify"
    public let description = "Format paragraph width"
    public let keys: [Key] = [.ctrl("J")]

    public init() {}

    public func execute(on editor: Editor) {
        guard !editor.isCanvasModeActive else {
            editor.setStatusMessage("[ Justify disabled in Canvas Mode ]")
            return
        }
        editor.saveUndoSnapshot()
        let (_, cols) = editor.terminal.getWindowSize()
        let targetWidth = editor.layoutEngine.wrapColumn ?? max(20, cols - 5)
        editor.buffer.justifyParagraph(targetWidth: targetWidth)
        editor.setStatusMessage(L10n["status.justified_paragraph"])
    }
}

public struct SpellCheckCommand: Command {
    public let id: CommandID = .editSpell
    public let name = "To Spell"
    public let description = "Check spelling"
    public let keys: [Key] = [.ctrl("T"), .f12]

    public init() {}

    public func execute(on editor: Editor) {
        editor.promptSpellCheck()
    }
}

public struct EvalLogoCommand: Command {
    public let id: CommandID = .editEvalLogo
    public let name = "Eval LOGO Code"
    public let description = "Evaluate LOGO code at current line, selection, or code block"
    public let keys: [Key] = [.ctrl("Q"), .ctrl("q")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.evalLogoCode()
    }
}
