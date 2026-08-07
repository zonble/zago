import Foundation

extension Editor {
    /// Central key input processing entrypoint for the Editor event loop.
    func processKey(_ key: Key) {
        defer {
            if buffer.isModified {
                markGitDiffDirty()
            }
        }

        if key == .resize {
            terminal.clearScreen()
            return
        }

        // Priority-ordered mode handlers chain
        let modeHandlers: [KeyInputHandler] = [
            promptController,
            menuBarController,
            tableModeController,
            canvasModeController,
            searchController,
            documentOutlineController
        ]

        for handler in modeHandlers {
            if handler.handleKey(key) {
                return
            }
        }

        if key == .f1 || key == .ctrl("M") {
            menuBarController.toggle()
            return
        }

        if buffer.handleKey(key, editor: self) {
            return
        }

        if (key == .shiftHome || key == .shiftEnd) && (isCanvasModeActive || isTableModeActive) {
            return
        }

        if commandRegistry.dispatch(key: key, editor: self) {
            if isTableModeActive {
                tableModeController.clampTableModeCursor()
            } else if isCanvasModeActive {
                syncCanvasCursorToBuffer()
            } else {
                buffer.clampCursor()
            }
            return
        }

        switch key {
        case .backspace:
            if !isCanvasModeActive && deleteTextSelectionIfNeeded(updateClipboard: false) {
                break
            }
            saveUndoSnapshot()
            if isCanvasModeActive {
                backspaceCanvasCharacter()
            } else {
                buffer.backspace()
            }

        case .enter:
            if !isCanvasModeActive && deleteTextSelectionIfNeeded(updateClipboard: false) {
                buffer.insertNewline(enableListAutoIndent: isListAutoIndentSupportedBuffer)
                break
            }
            saveUndoSnapshot()
            if isCanvasModeActive {
                insertCanvasNewline()
            } else {
                buffer.insertNewline(enableListAutoIndent: isListAutoIndentSupportedBuffer)
            }

        case .char(let ch):
            let pastedText = terminal.readPendingText(firstChar: ch)
            let isMultiChar = (pastedText.count > 1)
            let now = Date()
            let replacedSelection = !isCanvasModeActive && buffer.selectionMark != nil

            let isCoalescedPaste =
                isMultiChar && lastIsPaste
                && (lastMutationTime != nil && now.timeIntervalSince(lastMutationTime!) < 0.5)

            if replacedSelection {
                _ = deleteTextSelectionIfNeeded(updateClipboard: false)
            } else if !isCoalescedPaste {
                saveUndoSnapshot()
            }

            if isTableModeActive {
                tableModeController.pasteTableCellText(pastedText)
            } else if isCanvasModeActive {
                insertCanvasString(pastedText)
            } else if !isMultiChar {
                buffer.insert(character: ch)
            } else {
                buffer.insertString(pastedText)
            }

            lastIsPaste = isMultiChar
            lastMutationTime = now

        case .unknown:
            break

        default:
            setStatusMessage(l10n["status.unknown_command"])
        }

        if isCanvasModeActive {
            syncCanvasCursorToBuffer()
        } else {
            buffer.clampCursor()
        }
    }
}
