import Foundation

public struct DeleteLineCommand: Command {
    public let id: CommandID = .editDeleteLine
    public let name = "Delete Line"
    public let description = "Delete current line"
    public let keys: [Key] = [.ctrlBackspace, .ctrl("H"), .ctrl("h")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.saveUndoSnapshot()
        if !editor.isCanvasModeActive && editor.deleteTextSelectionIfNeeded(updateClipboard: false, saveSnapshot: false)
        {
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
        if !editor.isCanvasModeActive && editor.deleteTextSelectionIfNeeded(updateClipboard: false, saveSnapshot: false)
        {
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
    public let keys: [Key] = [.mark, .alt("b"), .alt("B")]
    public let commandBarAliases = ["mark", "mb"]

    public init() {}

    public func execute(on editor: Editor) {
        guard editor.isCanvasModeActive && !editor.isTableModeActive else {
            editor.setStatusMessage(editor.l10n["status.block_mark_canvas_only"])
            return
        }

        let point = (line: editor.buffer.lineIndex, visualColumn: editor.canvasVisualColumn)
        if editor.buffer.canvasBlockMark == nil {
            editor.buffer.canvasBlockMark = point
            editor.buffer.canvasBlockMarkEnd = point
            editor.setStatusMessage(editor.l10n["status.mark_set"])
        } else if let mark = editor.buffer.canvasBlockMark,
            let end = editor.buffer.canvasBlockMarkEnd,
            end.line == mark.line && end.visualColumn == mark.visualColumn
        {
            editor.buffer.canvasBlockMarkEnd = point
            editor.setStatusMessage(editor.l10n["status.mark_set"])
        } else {
            editor.buffer.canvasBlockMark = point
            editor.buffer.canvasBlockMarkEnd = point
            editor.setStatusMessage(editor.l10n["status.mark_set"])
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
        } else if let mark = editor.buffer.selectionMark {
            let (start, end) = TextBuffer.getOrderedRange(
                mark1: mark, mark2: (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex))
            guard start.line != end.line || start.column != end.column else {
                editor.setStatusMessage(editor.l10n["status.no_selection"])
                return
            }
            editor.clipboardText = editor.buffer.textRange(
                start: (line: start.line, col: start.column),
                end: (line: end.line, col: end.column))
            editor.setStatusMessage(editor.l10n["status.copied_text"])
        } else {
            editor.setStatusMessage(editor.l10n["status.no_selection"])
        }
    }
}

public struct CancelSelectionCommand: Command {
    public let id: CommandID = .editCancelSelection
    public let name = "Cancel Selection"
    public let description = "Cancel active selection or mark"
    public let keys: [Key] = [.ctrl("G"), .alt("u"), .alt("U")]
    public let commandBarAliases = ["unmark", "cancelmark", "clearmark"]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.searchController.clearActiveSearch() {
            return
        }
        if editor.buffer.selectionMark != nil || editor.buffer.canvasBlockMark != nil {
            editor.clearActiveMark()
            editor.setStatusMessage(editor.l10n["status.mark_unset"])
        } else if editor.isCanvasModeActive {
            editor.setStatusMessage(editor.l10n["status.no_block_marked"])
        } else {
            editor.setStatusMessage(editor.l10n["status.no_selection"])
        }
    }
}

public struct CutTextCommand: Command {
    public let id: CommandID = .editCut
    public let name = "Cut Text"
    public let description = "Cut selected text or line"
    public let keys: [Key] = [.ctrl("K"), .ctrl("k"), .f9]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.isTableModeActive {
            if let cell = editor.currentTableCell {
                editor.tableModeController.cutTableCellText(cell: cell)
            }
            return
        }
        editor.saveUndoSnapshot()
        editor.buffer.clampCursor()
        if editor.isCanvasModeActive {
            editor.cutCanvasBlock()
        } else if let mark = editor.buffer.selectionMark {
            let (start, end) = TextBuffer.getOrderedRange(
                mark1: mark, mark2: (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex))

            editor.clipboardText = editor.buffer.cutRange(
                start: (line: start.line, col: start.column), end: (line: end.line, col: end.column))
            editor.buffer.selectionMark = nil
            editor.setStatusMessage(editor.l10n["status.cut_text"])
        } else {
            let currentLine = editor.buffer.lines[editor.buffer.lineIndex]
            editor.clipboardText = currentLine + "\n"
            if editor.buffer.lines.count > 1 {
                editor.buffer.lines.remove(at: editor.buffer.lineIndex)
            } else {
                editor.buffer.lines[0] = ""
            }
            editor.buffer.isModified = true
            editor.setStatusMessage(editor.l10n["status.cut_one_line"])
        }
    }
}

public struct UncutTextCommand: Command {
    public let id: CommandID = .editUncut
    public let name = "UnCut Text"
    public let description = "Paste cut text"
    public let keys: [Key] = [.ctrl("U"), .ctrl("u"), .f10]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.isTableModeActive {
            if let text = editor.clipboardText, !text.isEmpty {
                editor.tableModeController.pasteTableCellText(text)
                editor.setStatusMessage(editor.l10n["status.uncut_text"])
            } else {
                editor.setStatusMessage(editor.l10n["status.clipboard_empty"])
            }
        } else if editor.isCanvasModeActive {
            editor.pasteCanvasBlock()
        } else if let text = editor.clipboardText, !text.isEmpty {
            editor.saveUndoSnapshot()
            editor.buffer.insertString(text)
            editor.setStatusMessage(editor.l10n["status.uncut_text"])
        } else {
            editor.setStatusMessage(editor.l10n["status.clipboard_empty"])
        }
    }
}

public struct InsertTabCommand: Command {
    public let id: CommandID = .editTab
    public let name = "Insert Tab"
    public let description = "Insert tab spaces or smart indent"
    public let keys: [Key] = [.tab, .ctrl("I"), .ctrl("i")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.saveUndoSnapshot()

        // 1. Grid Table Mode Navigation
        if editor.isTableModeActive {
            editor.tableModeController.navigateNextTableCell()
            return
        }

        // 2. Markup Language Table Cell Navigation
        if let syntax = editor.activeLanguageSyntax,
            let navigator = syntax.tableNavigator,
            let result = navigator(editor.buffer.lines, editor.buffer.lineIndex, editor.buffer.columnIndex, true)
        {
            if let updatedLines = result.updatedLines {
                editor.buffer.lines = updatedLines
            }
            editor.buffer.lineIndex = result.newBufferLineIndex
            editor.buffer.columnIndex = result.newCursorColumn
            return
        }

        // 3. Selection Active -> Block Indent
        if editor.displayConfig.smartTab && editor.buffer.selectionMark != nil && !editor.isCanvasModeActive {
            editor.indentSelectedBlock(spaces: editor.displayConfig.tabSize)
            return
        }

        // 4. Canvas Mode
        if editor.isCanvasModeActive {
            editor.insertCanvasString(String(repeating: " ", count: editor.displayConfig.tabSize))
            return
        }

        // 5. Smart Tab (List Item line or Leading Whitespace or Word boundary)
        if editor.displayConfig.smartTab {
            let lineIndex = editor.buffer.lineIndex
            let line = editor.buffer.lines[lineIndex]
            let col = editor.buffer.columnIndex
            let leadingSpaces = line.prefix(while: { $0 == " " || $0 == "\t" }).count

            if editor.isListItemLine(at: lineIndex) {
                editor.indentLine(at: lineIndex, spaces: editor.displayConfig.listIndentSize)
                return
            } else if col <= leadingSpaces {
                editor.indentLine(at: lineIndex, spaces: editor.displayConfig.tabSize)
                return
            } else {
                let tabStop = editor.displayConfig.tabSize
                let remainder = col % tabStop
                let insertCount = (remainder == 0) ? tabStop : (tabStop - remainder)
                editor.buffer.insertString(String(repeating: " ", count: insertCount))
                return
            }
        }

        // 6. Fallback raw tab insertion
        editor.buffer.insertString(String(repeating: " ", count: editor.displayConfig.tabSize))
    }
}

public struct InsertBacktabCommand: Command {
    public let id: CommandID = .editBacktab
    public let name = "Insert Backtab"
    public let description = "Navigate to previous table cell or outdent"
    public let keys: [Key] = [.backtab]

    public init() {}

    public func execute(on editor: Editor) {
        editor.saveUndoSnapshot()

        // 1. Grid Table Mode Navigation
        if editor.isTableModeActive {
            editor.tableModeController.navigatePrevTableCell()
            return
        }

        // 2. Markup Language Table Cell Navigation
        if let syntax = editor.activeLanguageSyntax,
            let navigator = syntax.tableNavigator,
            let result = navigator(editor.buffer.lines, editor.buffer.lineIndex, editor.buffer.columnIndex, false)
        {
            if let updatedLines = result.updatedLines {
                editor.buffer.lines = updatedLines
            }
            editor.buffer.lineIndex = result.newBufferLineIndex
            editor.buffer.columnIndex = result.newCursorColumn
            return
        }

        // 3. Selection Active -> Block Outdent
        if editor.displayConfig.smartTab && editor.buffer.selectionMark != nil && !editor.isCanvasModeActive {
            editor.outdentSelectedBlock(spaces: editor.displayConfig.tabSize)
            return
        }

        // 4. Smart Tab Line Outdent
        if editor.displayConfig.smartTab {
            let lineIndex = editor.buffer.lineIndex
            let outdentSpaces =
                editor.isListItemLine(at: lineIndex)
                ? editor.displayConfig.listIndentSize : editor.displayConfig.tabSize
            editor.outdentLine(at: lineIndex, spaces: outdentSpaces)
            return
        }

        // 5. Fallback Line Outdent
        editor.outdentLine(at: editor.buffer.lineIndex, spaces: editor.displayConfig.tabSize)
    }
}

public struct UndoCommand: Command {
    public let id: CommandID = .editUndo
    public let name = "Undo"
    public let description = "Undo last edit"
    public let keys: [Key] = [.ctrl("Z"), .ctrl("z")]

    public init() {}

    public func execute(on editor: Editor) {
        editor.performUndo()
    }
}

public struct JustifyCommand: Command {
    public let id: CommandID = .editJustify
    public let name = "Justify"
    public let description = "Justify paragraph text or format table"
    public let keys: [Key] = [.ctrl("J"), .ctrl("j")]
    public let commandBarAliases = ["justify"]

    public init() {}

    public func execute(on editor: Editor) {
        if editor.isTableModeActive {
            editor.tableModeController.centerCellText()
            return
        }
        guard !editor.isCanvasModeActive else {
            editor.setStatusMessage(editor.l10n["status.justify_disabled_in_canvas_mode"])
            return
        }
        editor.saveUndoSnapshot()
        if let syntax = editor.activeLanguageSyntax,
            let formatter = syntax.tableFormatter,
            let result = formatter(editor.buffer.lines, editor.buffer.lineIndex, editor.buffer.columnIndex)
        {
            editor.buffer.lines = result.updatedLines
            editor.buffer.lineIndex = result.startLineIndex
            editor.buffer.columnIndex = result.newCursorColumn
            editor.setStatusMessage("[ Formatted Table ]")
            return
        }
        let (_, cols) = editor.terminal.getWindowSize()
        let targetWidth = editor.layoutEngine.wrapColumn ?? max(20, cols - 5)
        editor.buffer.justifyParagraph(targetWidth: targetWidth)
        editor.setStatusMessage(editor.l10n["status.justified_paragraph"])
    }
}

public struct SpellCheckCommand: Command {
    public let id: CommandID = .editSpell
    public let name = "To Spell"
    public let description = "Check spelling"
    public let keys: [Key] = [.ctrl("T"), .f12]
    public let commandBarAliases = ["spell-check"]

    public init() {}

    public func execute(on editor: Editor) {
        editor.promptSpellCheck()
    }
}

public struct EvalLogoCommand: Command {
    public let id: CommandID = .editEvalLogo
    public let name = "Eval Editor LOGO Code"
    public let description = "Evaluate Editor LOGO code at current line, selection, or code block"
    public let keys: [Key] = [.ctrl("Q"), .ctrl("q")]
    public let commandBarAliases = ["eval", "evallogo", "run-logo"]

    public init() {}

    public func execute(on editor: Editor) {
        editor.evalLogoCode()
    }
}
