import Foundation

public struct DeleteLineCommand: Command {
    public let id: CommandID = .editDeleteLine
    public let name = "Delete Line"
    public let description = "Delete current line"
    public let keys: [Key] = [.ctrlBackspace, .ctrl("H"), .ctrl("h")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.saveUndoSnapshot()
        if !editor.isCanvasModeActive && editor.deleteTextSelectionIfNeeded(updateClipboard: false, saveSnapshot: false) {
            return
        }
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
        if !editor.isCanvasModeActive && editor.deleteTextSelectionIfNeeded(updateClipboard: false, saveSnapshot: false) {
            return
        }
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
    public let description = "Set or unset canvas block mark"
    public let keys: [Key] = [.mark]

    public init() {}

    public func execute(on editor: Editor) {
        guard editor.isCanvasModeActive && !editor.isTableModeActive else {
            editor.setStatusMessage(L10n["status.block_mark_canvas_only"])
            return
        }

        let point = (line: editor.buffer.lineIndex, visualColumn: editor.canvasVisualColumn)
        if editor.canvasBlockMark == nil {
            editor.canvasBlockMark = point
            editor.canvasBlockMarkEnd = point
            editor.setStatusMessage(L10n["status.mark_set"])
        } else if let mark = editor.canvasBlockMark,
                  let end = editor.canvasBlockMarkEnd,
                  end.line == mark.line && end.visualColumn == mark.visualColumn {
            editor.canvasBlockMarkEnd = point
            editor.setStatusMessage(L10n["status.mark_set"])
        } else {
            editor.canvasBlockMark = point
            editor.canvasBlockMarkEnd = point
            editor.setStatusMessage(L10n["status.mark_set"])
        }
    }
}

public struct CopyTextCommand: Command {
    public let id: CommandID = .editCopy
    public let name = "Copy Text"
    public let description = "Copy selected text or canvas block"
    public let keys: [Key] = [.alt("w"), .alt("W")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.buffer.clampCursor()
        if editor.isCanvasModeActive && !editor.isTableModeActive {
            _ = editor.copyCanvasBlock()
        } else if let mark = editor.selectionMark {
            let (start, end) = editor.getOrderedRange(
                mark1: mark, mark2: (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex))
            guard start.line != end.line || start.column != end.column else {
                editor.setStatusMessage(L10n["status.no_selection"])
                return
            }
            editor.clipboardText = editor.buffer.textRange(
                start: (line: start.line, col: start.column),
                end: (line: end.line, col: end.column))
            editor.setStatusMessage(L10n["status.copied_text"])
        } else {
            editor.setStatusMessage(L10n["status.no_selection"])
        }
    }
}

public struct CancelSelectionCommand: Command {
    public let id: CommandID = .editCancelSelection
    public let name = "Cancel Selection"
    public let description = "Cancel active selection or mark"
    public let keys: [Key] = [.ctrl("G")]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.selectionMark != nil || editor.canvasBlockMark != nil {
            editor.clearActiveMark()
            editor.setStatusMessage(L10n["status.mark_unset"])
        } else if editor.isCanvasModeActive {
            editor.setStatusMessage(L10n["status.no_block_marked"])
        } else {
            editor.setStatusMessage(L10n["status.no_selection"])
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
        if editor.isCanvasModeActive && !editor.isTableModeActive {
            editor.cutCanvasBlock()
        } else if let mark = editor.selectionMark {
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
        if editor.isTableModeActive {
            if let text = editor.clipboardText, !text.isEmpty {
                editor.pasteTableCellText(text)
                editor.setStatusMessage(L10n["status.uncut_text"])
            } else {
                editor.setStatusMessage(L10n["status.clipboard_empty"])
            }
        } else if editor.isCanvasModeActive {
            editor.pasteCanvasBlock()
        } else if let text = editor.clipboardText, !text.isEmpty {
            editor.saveUndoSnapshot()
            editor.buffer.insertString(text)
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
        if !editor.isCanvasModeActive && editor.deleteTextSelectionIfNeeded(updateClipboard: false, saveSnapshot: false) {
            editor.buffer.insertString("    ")
            return
        }
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
        if editor.isTableModeActive {
            editor.centerCellText()
            return
        }
        guard !editor.isCanvasModeActive else {
            editor.setStatusMessage(L10n["status.justify_disabled_in_canvas_mode"])
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
