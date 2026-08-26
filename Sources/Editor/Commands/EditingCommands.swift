import Foundation

struct DeleteLineCommand: Command {
    let id: CommandID = .editDeleteLine
    let name = "Delete Line"
    let description = "Delete current line"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.buffer.isReadOnly else {
            return .noOp(message: editor.l10n["status.read_only"])
        }
        editor.saveUndoSnapshot()
        if !editor.isCanvasModeActive && editor.deleteTextSelectionIfNeeded(updateClipboard: false, saveSnapshot: false)
        {
            return .succeeded
        }
        editor.deleteCurrentLine()
        return .succeeded
    }
}

struct DeleteCharCommand: Command {
    let id: CommandID = .editDelete
    let name = "Delete"
    let description = "Delete character under cursor"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.buffer.isReadOnly else {
            return .noOp(message: editor.l10n["status.read_only"])
        }
        editor.saveUndoSnapshot()
        if !editor.isCanvasModeActive && editor.deleteTextSelectionIfNeeded(updateClipboard: false, saveSnapshot: false)
        {
            return .succeeded
        }
        if editor.isCanvasModeActive {
            if editor.deleteCanvasBlockIfNeeded(saveSnapshot: false) {
                return .succeeded
            }
            editor.deleteCanvasCharacter()
            return .succeeded
        }
        editor.buffer.delete()
        return .succeeded
    }
}

struct ToggleMarkCommand: Command {
    let id: CommandID = .editMark
    let name = "Mark"
    let description = "Set or unset canvas block mark"
    let commandBarAliases = ["mark", "mb"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard editor.isCanvasModeActive && !editor.isTableModeActive else {
            return .noOp(message: editor.l10n["status.block_mark_canvas_only"])
        }

        let point = (line: editor.buffer.lineIndex, visualColumn: editor.canvasVisualColumn)
        if editor.buffer.canvasBlockMark == nil {
            editor.buffer.canvasBlockMark = point
            editor.buffer.canvasBlockMarkEnd = point
        } else if let mark = editor.buffer.canvasBlockMark,
            let end = editor.buffer.canvasBlockMarkEnd,
            end.line == mark.line && end.visualColumn == mark.visualColumn
        {
            editor.buffer.canvasBlockMarkEnd = point
        } else {
            editor.buffer.canvasBlockMark = point
            editor.buffer.canvasBlockMarkEnd = point
        }
        return .succeeded(message: editor.l10n["status.mark_set"])
    }
}

struct CopyTextCommand: Command {
    let id: CommandID = .editCopy
    let name = "Copy Text"
    let description = "Copy selected text or canvas block"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.buffer.clampCursor()
        if editor.isTableModeActive {
            if let cell = editor.currentTableCell {
                editor.tableModeController.copyTableCellText(cell: cell)
                return .succeeded
            }
        }
        if editor.isCanvasModeActive && !editor.isTableModeActive {
            _ = editor.copyCanvasBlock()
        } else if let mark = editor.buffer.selectionMark {
            let (start, end) = TextBuffer.getOrderedRange(
                mark1: mark, mark2: (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex))
            guard start.line != end.line || start.column != end.column else {
                return .noOp(message: editor.l10n["status.no_selection"])
            }
            editor.clipboardText = editor.buffer.textRange(
                start: (line: start.line, col: start.column),
                end: (line: end.line, col: end.column))
            return .succeeded(message: editor.l10n["status.copied_text"])
        } else {
            return .noOp(message: editor.l10n["status.no_selection"])
        }
        return .succeeded
    }
}

struct CancelSelectionCommand: Command {
    let id: CommandID = .editCancelSelection
    let name = "Cancel Selection"
    let description = "Cancel active selection or mark"
    let commandBarAliases = ["unmark", "cancelmark", "clearmark"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        if editor.searchController.clearActiveSearch() {
            return .succeeded
        }
        if editor.buffer.selectionMark != nil || editor.buffer.canvasBlockMark != nil {
            editor.clearActiveMark()
            return .succeeded(message: editor.l10n["status.mark_unset"])
        } else if editor.isCanvasModeActive {
            return .succeeded(message: editor.l10n["status.no_block_marked"])
        } else {
            return .succeeded(message: editor.l10n["status.no_selection"])
        }
    }
}

struct CutTextCommand: Command {
    let id: CommandID = .editCut
    let name = "Cut Text"
    let description = "Cut selected text or line"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.buffer.isReadOnly else {
            return .noOp(message: editor.l10n["status.read_only"])
        }
        if editor.isTableModeActive {
            if let cell = editor.currentTableCell {
                editor.tableModeController.cutTableCellText(cell: cell)
            }
            return .succeeded
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
            return .succeeded(message: editor.l10n["status.cut_text"])
        } else {
            let currentLine = editor.buffer.lines[editor.buffer.lineIndex]
            editor.clipboardText = currentLine + "\n"
            if editor.buffer.lines.count > 1 {
                editor.buffer.lines.remove(at: editor.buffer.lineIndex)
            } else {
                editor.buffer.lines[0] = ""
            }
            editor.buffer.isModified = true
            return .succeeded(message: editor.l10n["status.cut_one_line"])
        }
        return .succeeded
    }
}

struct UncutTextCommand: Command {
    let id: CommandID = .editUncut
    let name = "UnCut Text"
    let description = "Paste cut text"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.buffer.isReadOnly else {
            return .noOp(message: editor.l10n["status.read_only"])
        }
        if editor.isTableModeActive {
            if let text = editor.clipboardText, !text.isEmpty {
                editor.tableModeController.pasteTableCellText(text)
                return .succeeded(message: editor.l10n["status.uncut_text"])
            } else {
                return .succeeded(message: editor.l10n["status.clipboard_empty"])
            }
        } else if editor.isCanvasModeActive {
            editor.pasteCanvasBlock()
        } else if let text = editor.clipboardText, !text.isEmpty {
            editor.saveUndoSnapshot()
            editor.buffer.insertString(text)
            return .succeeded(message: editor.l10n["status.uncut_text"])
        } else {
            return .noOp(message: editor.l10n["status.clipboard_empty"])
        }
        return .succeeded
    }
}

struct InsertTabCommand: Command {
    let id: CommandID = .editTab
    let name = "Insert Tab"
    let description = "Insert tab spaces or smart indent"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        // 1. Grid Table Mode Navigation
        if editor.isTableModeActive {
            editor.tableModeController.navigateNextTableCell()
            return .succeeded
        }

        guard !editor.buffer.isReadOnly else {
            return .noOp(message: editor.l10n["status.read_only"])
        }

        editor.saveUndoSnapshot()

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
            return .succeeded
        }

        // 3. Selection Active -> Block Indent
        if editor.displayConfig.smartTab && editor.buffer.selectionMark != nil && !editor.isCanvasModeActive {
            editor.buffer.indentSelectedBlock(spaces: editor.displayConfig.tabSize)
            return .succeeded
        }

        // 4. Canvas Mode
        if editor.isCanvasModeActive {
            editor.insertCanvasString(String(repeating: " ", count: editor.displayConfig.tabSize))
            return .succeeded
        }

        // 5. Smart Tab (List Item line or Leading Whitespace or Word boundary)
        if editor.displayConfig.smartTab {
            let lineIndex = editor.buffer.lineIndex
            let line = editor.buffer.lines[lineIndex]
            let col = editor.buffer.columnIndex
            let leadingSpaces = line.prefix(while: { $0 == " " || $0 == "\t" }).count

            if editor.buffer.isListItemLine(at: lineIndex) {
                editor.buffer.indentLine(at: lineIndex, spaces: editor.displayConfig.listIndentSize)
                return .succeeded
            } else if col <= leadingSpaces {
                editor.buffer.indentLine(at: lineIndex, spaces: editor.displayConfig.tabSize)
                return .succeeded
            } else {
                let tabStop = editor.displayConfig.tabSize
                let remainder = col % tabStop
                let insertCount = (remainder == 0) ? tabStop : (tabStop - remainder)
                editor.buffer.insertString(String(repeating: " ", count: insertCount))
                return .succeeded
            }
        }

        // 6. Fallback raw tab insertion
        editor.buffer.insertString(String(repeating: " ", count: editor.displayConfig.tabSize))
        return .succeeded
    }
}

struct InsertBacktabCommand: Command {
    let id: CommandID = .editBacktab
    let name = "Insert Backtab"
    let description = "Navigate to previous table cell or outdent"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        // 1. Grid Table Mode Navigation
        if editor.isTableModeActive {
            editor.tableModeController.navigatePrevTableCell()
            return .succeeded
        }

        guard !editor.buffer.isReadOnly else {
            return .noOp(message: editor.l10n["status.read_only"])
        }

        editor.saveUndoSnapshot()

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
            return .succeeded
        }

        // 3. Selection Active -> Block Outdent
        if editor.displayConfig.smartTab && editor.buffer.selectionMark != nil && !editor.isCanvasModeActive {
            editor.buffer.outdentSelectedBlock(spaces: editor.displayConfig.tabSize)
            return .succeeded
        }

        // 4. Smart Tab Line Outdent
        if editor.displayConfig.smartTab {
            let lineIndex = editor.buffer.lineIndex
            let outdentSpaces =
                editor.buffer.isListItemLine(at: lineIndex)
                ? editor.displayConfig.listIndentSize : editor.displayConfig.tabSize
            editor.buffer.outdentLine(at: lineIndex, spaces: outdentSpaces)
            return .succeeded
        }

        // 5. Fallback Line Outdent
        editor.buffer.outdentLine(at: editor.buffer.lineIndex, spaces: editor.displayConfig.tabSize)
        return .succeeded
    }
}

struct UndoCommand: Command {
    let id: CommandID = .editUndo
    let name = "Undo"
    let description = "Undo last edit"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.buffer.isReadOnly else {
            return .noOp(message: editor.l10n["status.read_only"])
        }
        editor.performUndo()
        return .succeeded
    }
}

struct RedoCommand: Command {
    let id: CommandID = .editRedo
    let name = "Redo"
    let description = "Redo last undone edit"

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.buffer.isReadOnly else {
            return .noOp(message: editor.l10n["status.read_only"])
        }
        editor.performRedo()
        return .succeeded
    }
}

struct JustifyCommand: Command {
    let id: CommandID = .editJustify
    let name = "Justify"
    let description = "Justify paragraph text or format table"
    let commandBarAliases = ["justify"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.buffer.isReadOnly else {
            return .noOp(message: editor.l10n["status.read_only"])
        }
        if editor.isTableModeActive {
            editor.tableModeController.centerCellText()
            return .succeeded
        }
        guard !editor.isCanvasModeActive else {
            return .noOp(message: editor.l10n["status.justify_disabled_in_canvas_mode"])
        }
        editor.saveUndoSnapshot()
        if let syntax = editor.activeLanguageSyntax,
            let formatter = syntax.tableFormatter,
            let result = formatter(editor.buffer.lines, editor.buffer.lineIndex, editor.buffer.columnIndex)
        {
            editor.buffer.lines = result.updatedLines
            editor.buffer.lineIndex = result.startLineIndex
            editor.buffer.columnIndex = result.newCursorColumn
            return .succeeded(message: editor.l10n["status.formatted_table"])
        }
        let targetWidth = editor.fillColumn
        editor.buffer.justifyParagraph(targetWidth: targetWidth)
        return .succeeded(message: editor.l10n["status.justified_paragraph"])
    }
}

struct SpellCheckCommand: Command {
    let id: CommandID = .editSpell
    let name = "To Spell"
    let description = "Check spelling"
    let commandBarAliases = ["spell-check"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.buffer.isReadOnly else {
            return .noOp(message: editor.l10n["status.read_only"])
        }
        editor.promptSpellCheck()
        return .prompting
    }
}

struct EvalLogoCommand: Command {
    let id: CommandID = .editEvalLogo
    let name = "Eval Editor LOGO Code"
    let description = "Evaluate Editor LOGO code at current line, selection, or code block"
    let commandBarAliases = ["eval", "evallogo", "run-logo"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        editor.evalLogoCode()
        return .succeeded
    }
}

struct ToggleCommentCommand: Command {
    let id: CommandID = .editToggleComment
    let name = "Toggle Comment"
    let description = "Comment or uncomment current line or selection"
    let commandBarAliases = ["comment", "uncomment", "toggle-comment"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.buffer.isReadOnly else {
            return .noOp(message: editor.l10n["status.read_only"])
        }
        editor.toggleComment()
        return .succeeded
    }
}

struct JoinLineCommand: Command {
    let id: CommandID = .editJoinLine
    let name = "Join Line"
    let description = "Join next line with current line"
    let commandBarAliases = ["joinline", "join"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.buffer.isReadOnly else {
            return .noOp(message: editor.l10n["status.read_only"])
        }
        editor.saveUndoSnapshot()
        guard editor.buffer.lineIndex + 1 < editor.buffer.lines.count else { return .noOp }

        let currentLine = editor.buffer.lines[editor.buffer.lineIndex]
        let nextLine = editor.buffer.lines.remove(at: editor.buffer.lineIndex + 1)
        let trimmedNext = nextLine.trimmingCharacters(in: .whitespaces)

        let separator = (currentLine.hasSuffix(" ") || currentLine.isEmpty || trimmedNext.isEmpty) ? "" : " "
        editor.buffer.lines[editor.buffer.lineIndex] = currentLine + separator + trimmedNext
        editor.buffer.columnIndex = currentLine.count + separator.count
        editor.buffer.isModified = true
        return .succeeded
    }
}

struct SplitLineCommand: Command {
    let id: CommandID = .editSplitLine
    let name = "Split Line"
    let description = "Split current line at cursor position"
    let commandBarAliases = ["splitline", "split"]

    init() {}

    @discardableResult
    func execute(on editor: Editor) -> EditorOperationResult {
        guard !editor.buffer.isReadOnly else {
            return .noOp(message: editor.l10n["status.read_only"])
        }
        editor.saveUndoSnapshot()
        let line = editor.buffer.lines[editor.buffer.lineIndex]
        let col = min(editor.buffer.columnIndex, line.count)
        let firstPart = String(line.prefix(col))
        let secondPart = String(line.dropFirst(col))

        editor.buffer.lines[editor.buffer.lineIndex] = firstPart
        editor.buffer.lines.insert(secondPart, at: editor.buffer.lineIndex + 1)
        editor.buffer.lineIndex += 1
        editor.buffer.columnIndex = 0
        editor.buffer.isModified = true
        return .succeeded
    }
}
