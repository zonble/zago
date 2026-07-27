import Foundation

extension Editor {
    /// Registers default editor commands and keybindings.
    func setupDefaultCommands() {
        // Navigation Commands
        commandRegistry.register(Command(id: "move.right", name: "Forward", description: "Move forward a character", keys: [.ctrl("F"), .arrowRight]) { editor in
            let currentLineLength = editor.buffer.lines[editor.buffer.lineIndex].count
            if editor.buffer.columnIndex < currentLineLength {
                editor.buffer.columnIndex += 1
            } else if editor.buffer.lineIndex < editor.buffer.lines.count - 1 {
                editor.buffer.lineIndex += 1
                editor.buffer.columnIndex = 0
            }
        })

        commandRegistry.register(Command(id: "move.left", name: "Backward", description: "Move backward a character", keys: [.ctrl("B"), .arrowLeft]) { editor in
            if editor.buffer.columnIndex > 0 {
                editor.buffer.columnIndex -= 1
            } else if editor.buffer.lineIndex > 0 {
                editor.buffer.lineIndex -= 1
                editor.buffer.columnIndex = editor.buffer.lines[editor.buffer.lineIndex].count
            }
        })

        commandRegistry.register(Command(id: "move.up", name: "Previous Line", description: "Move to previous line", keys: [.ctrl("P"), .arrowUp]) { editor in
            editor.moveCursorVirtual(deltaRow: -1)
        })

        commandRegistry.register(Command(id: "move.down", name: "Next Line", description: "Move to next line", keys: [.ctrl("N"), .arrowDown]) { editor in
            editor.moveCursorVirtual(deltaRow: 1)
        })

        commandRegistry.register(Command(id: "move.home", name: "Beginning of Line", description: "Move to beginning of line", keys: [.ctrl("A"), .home]) { editor in
            let vLine = editor.getVirtualLineForCursor()
            editor.buffer.columnIndex = vLine.startCol
        })

        commandRegistry.register(Command(id: "move.end", name: "End of Line", description: "Move to end of line", keys: [.ctrl("E"), .end]) { editor in
            let vLine = editor.getVirtualLineForCursor()
            editor.buffer.columnIndex = vLine.endCol
        })

        commandRegistry.register(Command(id: "move.pgdn", name: "Next Page", description: "Move forward one page", keys: [.ctrl("V"), .f8, .pageDown]) { editor in
            let (rows, _) = editor.terminal.getWindowSize()
            let mainAreaHeight = max(1, rows - (editor.displayConfig.showRuler ? 5 : 4))
            editor.moveCursorVirtual(deltaRow: mainAreaHeight)
        })

        commandRegistry.register(Command(id: "move.pgup", name: "Previous Page", description: "Move backward one page", keys: [.ctrl("Y"), .f7, .pageUp]) { editor in
            let (rows, _) = editor.terminal.getWindowSize()
            let mainAreaHeight = max(1, rows - (editor.displayConfig.showRuler ? 5 : 4))
            editor.moveCursorVirtual(deltaRow: -mainAreaHeight)
        })

        // Selection Commands
        commandRegistry.register(Command(id: "select.left", name: "Select Left", description: "Extend selection left", keys: [.shiftArrowLeft]) { editor in
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
        })

        commandRegistry.register(Command(id: "select.right", name: "Select Right", description: "Extend selection right", keys: [.shiftArrowRight]) { editor in
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
        })

        commandRegistry.register(Command(id: "select.up", name: "Select Up", description: "Extend selection up", keys: [.shiftArrowUp]) { editor in
            if editor.selectionMark == nil {
                editor.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
                editor.setStatusMessage(L10n["status.mark_set"])
            }
            editor.moveCursorVirtual(deltaRow: -1)
        })

        commandRegistry.register(Command(id: "select.down", name: "Select Down", description: "Extend selection down", keys: [.shiftArrowDown]) { editor in
            if editor.selectionMark == nil {
                editor.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
                editor.setStatusMessage(L10n["status.mark_set"])
            }
            editor.moveCursorVirtual(deltaRow: 1)
        })

        // Editing Commands
        commandRegistry.register(Command(id: "edit.delete_line", name: "Delete Line", description: "Delete current line", keys: [.ctrlBackspace, .ctrl("H"), .ctrl("h")]) { editor in
            editor.saveUndoSnapshot()
            editor.deleteCurrentLine()
        })

        commandRegistry.register(Command(id: "edit.delete", name: "Delete", description: "Delete character under cursor", keys: [.ctrl("D"), .delete]) { editor in
            editor.saveUndoSnapshot()
            editor.buffer.delete()
        })

        commandRegistry.register(Command(id: "edit.mark", name: "Mark", description: "Set or unset selection mark", keys: [.mark]) { editor in
            if editor.selectionMark == nil {
                editor.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
                editor.setStatusMessage(L10n["status.mark_set"])
            } else {
                editor.selectionMark = nil
                editor.setStatusMessage(L10n["status.mark_unset"])
            }
        })

        commandRegistry.register(Command(id: "edit.cut", name: "Cut Text", description: "Cut selected text or line", keys: [.ctrl("K"), .f9]) { editor in
            editor.saveUndoSnapshot()
            editor.buffer.clampCursor()
            if let mark = editor.selectionMark {
                let (start, end) = editor.getOrderedRange(mark1: mark, mark2: (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex))

                editor.clipboardText = editor.buffer.cutRange(start: (line: start.line, col: start.column), end: (line: end.line, col: end.column))
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
        })

        commandRegistry.register(Command(id: "edit.uncut", name: "UnCut Text", description: "Paste cut text", keys: [.ctrl("U"), .f10]) { editor in
            if let text = editor.clipboardText, !text.isEmpty {
                editor.saveUndoSnapshot()
                editor.buffer.insertString(text)
                editor.setStatusMessage(L10n["status.uncut_text"])
            } else {
                editor.setStatusMessage(L10n["status.clipboard_empty"])
            }
        })

        commandRegistry.register(Command(id: "edit.tab", name: "Insert Tab", description: "Insert tab spaces", keys: [.tab]) { editor in
            editor.saveUndoSnapshot()
            editor.buffer.insertString("    ")
        })

        commandRegistry.register(Command(id: "edit.undo", name: "Undo", description: "Undo last edit", keys: [.ctrl("Z")]) { editor in
            editor.performUndo()
        })

        // Formatting & Search
        commandRegistry.register(Command(id: "edit.justify", name: "Justify", description: "Format paragraph width", keys: [.ctrl("J"), .f4]) { editor in
            editor.saveUndoSnapshot()
            let (_, cols) = editor.terminal.getWindowSize()
            let targetWidth = editor.layoutEngine.wrapColumn ?? max(20, cols - 5)
            editor.buffer.justifyParagraph(targetWidth: targetWidth)
            editor.setStatusMessage(L10n["status.justified_paragraph"])
        })

        commandRegistry.register(Command(id: "edit.spell", name: "To Spell", description: "Check spelling", keys: [.ctrl("T"), .f12]) { editor in
            editor.promptSpellCheck()
        })

        commandRegistry.register(Command(id: "search.whereis", name: "Where Is", description: "Search text", keys: [.ctrl("W"), .f6]) { editor in
            editor.promptSearch()
        })

        commandRegistry.register(Command(id: "cursor.goto_line", name: "Go To Line", description: "Jump to line and column number", keys: [.ctrl("/"), .ctrl("_"), .alt("g"), .alt("G"), .alt("/")]) { editor in
            editor.promptGotoLine()
        })

        commandRegistry.register(Command(id: "screen.refresh", name: "Refresh", description: "Refresh screen", keys: [.ctrl("L")]) { _ in })

        commandRegistry.register(Command(id: "cursor.pos", name: "Cur Pos", description: "Display cursor position", keys: [.ctrl("C"), .f11]) { editor in
            let currentLine = editor.buffer.lineIndex + 1
            let totalLines = editor.buffer.lines.count
            let percent = totalLines > 0 ? Int(Double(currentLine) / Double(totalLines) * 100) : 100
            let currentCol = editor.buffer.columnIndex + 1
            let totalCol = editor.buffer.lines[editor.buffer.lineIndex].count + 1
            editor.setStatusMessage(L10n.cursorInfo(currentLine: currentLine, totalLines: totalLines, percent: percent, currentCol: currentCol, totalCol: totalCol))
        })

        // File Operations & Exit
        commandRegistry.register(Command(id: "buffer.prev", name: "Previous Buffer", description: "Switch to previous open buffer", keys: [.alt(","), .alt("<"), .f12]) { editor in
            editor.prevBuffer()
        })

        commandRegistry.register(Command(id: "buffer.next", name: "Next Buffer", description: "Switch to next open buffer", keys: [.alt("."), .alt(">"), .f11]) { editor in
            editor.nextBuffer()
        })

        commandRegistry.register(Command(id: "buffer.new", name: "New Buffer", description: "Open a new buffer", keys: [.ctrl("N")]) { editor in
            editor.openNewBuffer()
        })

        commandRegistry.register(Command(id: "file.save", name: "WriteOut", description: "Save file", keys: [.ctrl("O"), .ctrl("S"), .f3]) { editor in
            editor.promptWriteFilePath()
        })

        commandRegistry.register(Command(id: "file.insert", name: "Read File", description: "Insert external file", keys: [.ctrl("R"), .f5]) { editor in
            editor.promptInsertFilePath()
        })

        commandRegistry.register(Command(id: "file.exit", name: "Exit", description: "Exit editor or close current buffer", keys: [.ctrl("X"), .f2]) { editor in
            if editor.buffer.isModified {
                editor.promptExitSaveConfirm()
            } else {
                editor.closeCurrentBuffer()
            }
        })

        commandRegistry.register(Command(id: "macro.logo", name: "LOGO Macro", description: "Execute LOGO macro script", keys: [.alt("l"), .alt("L"), .alt(":"), .char("¬"), .char("Ò"), .f8]) { editor in
            editor.promptLogoMacro()
        })

        commandRegistry.register(Command(id: "help.show", name: "Get Help", description: "Show full-screen help", keys: [.ctrl("G"), .f1]) { editor in
            let helpView = HelpView(terminal: editor.terminal)
            helpView.show()
        })
    }
}
