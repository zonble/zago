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
            menuBarController
        ]

        for handler in modeHandlers {
            if handler.handleKey(key, editor: self) {
                return
            }
        }

        if key == .f1 || key == .ctrl("M") {
            toggleMenuBar()
            return
        }

        if buffer.handleKey(key, editor: self) {
            return
        }

        if processTableModeKey(key) {
            return
        }

        if processCanvasDrawingKey(key) {
            return
        }

        if (key == .shiftHome || key == .shiftEnd) && (isCanvasModeActive || isTableModeActive) {
            return
        }

        if isCanvasModeActive {
            switch key {
            case .pageUp:
                saveUndoSnapshot()
                clearActiveMark()
                let pageStep = max(1, terminal.getWindowSize().rows - (displayConfig.showRuler ? 5 : 4))
                let originalCanvasColumn = canvasVisualColumn
                buffer.lineIndex = max(0, buffer.lineIndex - pageStep)
                canvasVisualColumn = originalCanvasColumn
                syncCanvasCursorToBuffer()
                return
            case .pageDown:
                saveUndoSnapshot()
                clearActiveMark()
                let pageStep = max(1, terminal.getWindowSize().rows - (displayConfig.showRuler ? 5 : 4))
                let targetLine = min(buffer.lines.count - 1, buffer.lineIndex + pageStep)
                let originalCanvasColumn = canvasVisualColumn
                buffer.lineIndex = max(0, targetLine)
                canvasVisualColumn = originalCanvasColumn
                syncCanvasCursorToBuffer()
                return
            default:
                break
            }
        }

        if commandRegistry.dispatch(key: key, editor: self) {
            if isTableModeActive {
                clampTableModeCursor()
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
                pasteTableCellText(pastedText)
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
