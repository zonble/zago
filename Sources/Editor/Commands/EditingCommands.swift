import Foundation

public struct DeleteLineCommand: Command {
    public let id: CommandID = .editDeleteLine
    public let name = "Delete Line"
    public let description = "Delete current line"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.saveUndoSnapshot()
        if !editor.isCanvasModeActive && editor.deleteTextSelectionIfNeeded(updateClipboard: false, saveSnapshot: false)
        {
            return .succeeded
        }
        editor.deleteCurrentLine()
        return .succeeded
    }
}

public struct DeleteCharCommand: Command {
    public let id: CommandID = .editDelete
    public let name = "Delete"
    public let description = "Delete character under cursor"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.saveUndoSnapshot()
        if !editor.isCanvasModeActive && editor.deleteTextSelectionIfNeeded(updateClipboard: false, saveSnapshot: false)
        {
            return .succeeded
        }
        if editor.isCanvasModeActive {
            editor.deleteCanvasCharacter()
            return .succeeded
        }
        editor.buffer.delete()
        return .succeeded
    }
}

public struct ToggleMarkCommand: Command {
    public let id: CommandID = .editMark
    public let name = "Mark"
    public let description = "Set or unset canvas block mark"
    public let commandBarAliases = ["mark", "mb"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
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

public struct CopyTextCommand: Command {
    public let id: CommandID = .editCopy
    public let name = "Copy Text"
    public let description = "Copy selected text or canvas block"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
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

public struct CancelSelectionCommand: Command {
    public let id: CommandID = .editCancelSelection
    public let name = "Cancel Selection"
    public let description = "Cancel active selection or mark"
    public let commandBarAliases = ["unmark", "cancelmark", "clearmark"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
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

public struct CutTextCommand: Command {
    public let id: CommandID = .editCut
    public let name = "Cut Text"
    public let description = "Cut selected text or line"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
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

public struct UncutTextCommand: Command {
    public let id: CommandID = .editUncut
    public let name = "UnCut Text"
    public let description = "Paste cut text"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
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

public struct InsertTabCommand: Command {
    public let id: CommandID = .editTab
    public let name = "Insert Tab"
    public let description = "Insert tab spaces or smart indent"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.saveUndoSnapshot()

        // 1. Grid Table Mode Navigation
        if editor.isTableModeActive {
            editor.tableModeController.navigateNextTableCell()
            return .succeeded
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
            return .succeeded
        }

        // 3. Selection Active -> Block Indent
        if editor.displayConfig.smartTab && editor.buffer.selectionMark != nil && !editor.isCanvasModeActive {
            editor.indentSelectedBlock(spaces: editor.displayConfig.tabSize)
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

            if editor.isListItemLine(at: lineIndex) {
                editor.indentLine(at: lineIndex, spaces: editor.displayConfig.listIndentSize)
                return .succeeded
            } else if col <= leadingSpaces {
                editor.indentLine(at: lineIndex, spaces: editor.displayConfig.tabSize)
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

public struct InsertBacktabCommand: Command {
    public let id: CommandID = .editBacktab
    public let name = "Insert Backtab"
    public let description = "Navigate to previous table cell or outdent"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.saveUndoSnapshot()

        // 1. Grid Table Mode Navigation
        if editor.isTableModeActive {
            editor.tableModeController.navigatePrevTableCell()
            return .succeeded
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
            return .succeeded
        }

        // 3. Selection Active -> Block Outdent
        if editor.displayConfig.smartTab && editor.buffer.selectionMark != nil && !editor.isCanvasModeActive {
            editor.outdentSelectedBlock(spaces: editor.displayConfig.tabSize)
            return .succeeded
        }

        // 4. Smart Tab Line Outdent
        if editor.displayConfig.smartTab {
            let lineIndex = editor.buffer.lineIndex
            let outdentSpaces =
                editor.isListItemLine(at: lineIndex)
                ? editor.displayConfig.listIndentSize : editor.displayConfig.tabSize
            editor.outdentLine(at: lineIndex, spaces: outdentSpaces)
            return .succeeded
        }

        // 5. Fallback Line Outdent
        editor.outdentLine(at: editor.buffer.lineIndex, spaces: editor.displayConfig.tabSize)
        return .succeeded
    }
}

public struct UndoCommand: Command {
    public let id: CommandID = .editUndo
    public let name = "Undo"
    public let description = "Undo last edit"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.performUndo()
        return .succeeded
    }
}

public struct RedoCommand: Command {
    public let id: CommandID = .editRedo
    public let name = "Redo"
    public let description = "Redo last undone edit"

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.performRedo()
        return .succeeded
    }
}

public struct JustifyCommand: Command {
    public let id: CommandID = .editJustify
    public let name = "Justify"
    public let description = "Justify paragraph text or format table"
    public let commandBarAliases = ["justify"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
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
        let (_, cols) = editor.terminal.getWindowSize()
        let targetWidth = editor.layoutEngine.wrapColumn ?? max(20, cols - 5)
        editor.buffer.justifyParagraph(targetWidth: targetWidth)
        return .succeeded(message: editor.l10n["status.justified_paragraph"])
    }
}

public struct SpellCheckCommand: Command {
    public let id: CommandID = .editSpell
    public let name = "To Spell"
    public let description = "Check spelling"
    public let commandBarAliases = ["spell-check"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.promptSpellCheck()
        return .prompting
    }
}

public struct EvalLogoCommand: Command {
    public let id: CommandID = .editEvalLogo
    public let name = "Eval Editor LOGO Code"
    public let description = "Evaluate Editor LOGO code at current line, selection, or code block"
    public let commandBarAliases = ["eval", "evallogo", "run-logo"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.evalLogoCode()
        return .succeeded
    }
}

public struct ToggleCommentCommand: Command {
    public let id: CommandID = .editToggleComment
    public let name = "Toggle Comment"
    public let description = "Comment or uncomment current line or selection"
    public let commandBarAliases = ["comment", "uncomment", "toggle-comment"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
        editor.toggleComment()
        return .succeeded
    }
}

public struct JoinLineCommand: Command {
    public let id: CommandID = .editJoinLine
    public let name = "Join Line"
    public let description = "Join next line with current line"
    public let commandBarAliases = ["joinline", "join"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
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

public struct SplitLineCommand: Command {
    public let id: CommandID = .editSplitLine
    public let name = "Split Line"
    public let description = "Split current line at cursor position"
    public let commandBarAliases = ["splitline", "split"]

    public init() {}

    @discardableResult
    public func execute(on editor: Editor) -> EditorOperationResult {
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
