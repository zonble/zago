import Foundation
import LogoEngine
import TextMetrics

enum TableLimits {
    static let minRows = 1
    static let maxRows = 50
    static let minCols = 1
    static let maxCols = 20
    static let defaultCellWidth = 16
    static let minCellWidth = 1
    static let maxCellWidth = 40
}

/// Controller handling Table Mode keyboard events, navigation, and cell editing constraints.
public final class TableModeController: KeyInputHandler {
    public weak var editor: Editor?

    public init(editor: Editor? = nil) {
        self.editor = editor
    }

    /// KeyInputHandler protocol implementation.
    public func handleKey(_ key: Key) -> Bool {
        guard let editor, editor.isTableModeActive, let cell = editor.currentTableCell else { return false }

        if editor.isCanvasModeActive {
            editor.syncCanvasCursorToBuffer()
            clampTableModeCursor()
            editor.syncCanvasCursorFromBuffer()
        }
        defer {
            if editor.isCanvasModeActive {
                clampTableModeCursor()
                editor.syncCanvasCursorFromBuffer()
            }
        }

        switch key {
        case .alt("t"), .alt("T"), .f7:
            editor.clearActiveMark()
            toggleTableMode()
            return true

        case .tab:
            editor.clearActiveMark()
            navigateNextTableCell()
            return true

        case .shiftArrowLeft:
            extendTableSelectionLeft(cell: cell)
            return true

        case .shiftArrowRight:
            extendTableSelectionRight(cell: cell)
            return true

        case .ctrlShiftArrowRight:
            editor.saveUndoSnapshot()
            resizeCurrentTableCellWidth(delta: 1)
            return true

        case .ctrlShiftArrowLeft:
            editor.saveUndoSnapshot()
            resizeCurrentTableCellWidth(delta: -1)
            return true

        case .ctrlShiftArrowDown:
            editor.saveUndoSnapshot()
            resizeCurrentTableCellHeight(delta: 1)
            return true

        case .ctrlShiftArrowUp:
            editor.saveUndoSnapshot()
            resizeCurrentTableCellHeight(delta: -1)
            return true

        case .arrowUp:
            editor.clearActiveMark()
            if editor.buffer.lineIndex == cell.innerMinLine {
                navigateUpTableCell()
            } else {
                let vCol = getVisualColumn(
                    in: editor.buffer.lines[editor.buffer.lineIndex], col: editor.buffer.columnIndex)
                editor.buffer.lineIndex -= 1
                editor.buffer.columnIndex = getCharIndexForVisualColumn(
                    in: editor.buffer.lines[editor.buffer.lineIndex], targetVisualCol: vCol)
            }
            clampTableModeCursor()
            return true

        case .arrowDown:
            editor.clearActiveMark()
            if editor.buffer.lineIndex == cell.innerMaxLine {
                navigateDownTableCell()
            } else {
                let vCol = getVisualColumn(
                    in: editor.buffer.lines[editor.buffer.lineIndex], col: editor.buffer.columnIndex)
                editor.buffer.lineIndex += 1
                editor.buffer.columnIndex = getCharIndexForVisualColumn(
                    in: editor.buffer.lines[editor.buffer.lineIndex], targetVisualCol: vCol)
            }
            clampTableModeCursor()
            return true

        case .pageUp, .ctrl("y"), .ctrl("Y"):
            editor.clearActiveMark()
            let vCol = getVisualColumn(in: editor.buffer.lines[editor.buffer.lineIndex], col: editor.buffer.columnIndex)
            editor.buffer.lineIndex = cell.innerMinLine
            editor.buffer.columnIndex = getCharIndexForVisualColumn(
                in: editor.buffer.lines[editor.buffer.lineIndex], targetVisualCol: vCol)
            clampTableModeCursor()
            return true

        case .pageDown, .ctrl("v"), .ctrl("V"):
            editor.clearActiveMark()
            let vCol = getVisualColumn(in: editor.buffer.lines[editor.buffer.lineIndex], col: editor.buffer.columnIndex)
            editor.buffer.lineIndex = cell.innerMaxLine
            editor.buffer.columnIndex = getCharIndexForVisualColumn(
                in: editor.buffer.lines[editor.buffer.lineIndex], targetVisualCol: vCol)
            clampTableModeCursor()
            return true

        case .arrowLeft:
            editor.clearActiveMark()
            if editor.buffer.columnIndex == cell.innerMinCol {
                navigateLeftAdjacentTableCell()
            } else {
                editor.buffer.columnIndex -= 1
            }
            clampTableModeCursor()
            return true

        case .arrowRight:
            editor.clearActiveMark()
            if editor.buffer.columnIndex == cell.innerMaxCol {
                navigateRightAdjacentTableCell()
            } else {
                editor.buffer.columnIndex += 1
            }
            clampTableModeCursor()
            return true

        case .ctrl("j"), .ctrl("J"):
            centerCellText()
            return true

        case .home, .ctrl("a"), .ctrl("A"):
            editor.clearActiveMark()
            let line = editor.buffer.lines[editor.buffer.lineIndex]
            let (leftBorder, _) = TableModeController.findCellHorizontalBorders(
                in: line, nearCol: editor.buffer.columnIndex, cell: cell)
            editor.buffer.columnIndex = leftBorder + 1
            clampTableModeCursor()
            return true

        case .end, .ctrl("e"), .ctrl("E"):
            editor.clearActiveMark()
            let line = editor.buffer.lines[editor.buffer.lineIndex]
            let (leftBorder, rightBorder) = TableModeController.findCellHorizontalBorders(
                in: line, nearCol: editor.buffer.columnIndex, cell: cell)
            editor.buffer.columnIndex = max(leftBorder + 1, rightBorder - 1)
            clampTableModeCursor()
            return true

        case .enter:
            editor.clearActiveMark()
            moveToNextTableCellLineOrCell()
            return true

        case .ctrl("k"), .ctrl("K"), .f9:
            cutTableCellText(cell: cell)
            return true

        case .ctrl("u"), .ctrl("U"), .f10:
            if let text = editor.clipboardText, !text.isEmpty {
                pasteTableCellText(text)
                editor.setStatusMessage(editor.l10n["status.uncut_text"])
            } else {
                editor.setStatusMessage(editor.l10n["status.clipboard_empty"])
            }
            return true

        case .backspace:
            if deleteTableSelectionIfNeeded(cell: cell, updateClipboard: false) {
                return true
            }
            let line = editor.buffer.lines[editor.buffer.lineIndex]
            let (leftBorder, rightBorder) = TableModeController.findCellHorizontalBorders(
                in: line, nearCol: editor.buffer.columnIndex, cell: cell)
            let innerMinCol = leftBorder + 1

            if editor.buffer.columnIndex > innerMinCol {
                editor.saveUndoSnapshot()
                var lineChars = Array(line)
                let deleteIdx = editor.buffer.columnIndex - 1
                if deleteIdx >= innerMinCol && deleteIdx < lineChars.count {
                    let deletedChar = lineChars[deleteIdx]
                    let dw = deletedChar.displayWidth
                    lineChars.remove(at: deleteIdx)
                    let insertSpaceIdx = min(rightBorder - 1, lineChars.count)
                    for _ in 0..<dw {
                        lineChars.insert(" ", at: insertSpaceIdx)
                    }
                    editor.buffer.lines[editor.buffer.lineIndex] = String(lineChars)
                    editor.buffer.columnIndex = max(innerMinCol, deleteIdx)
                }
            }
            clampTableModeCursor()
            return true

        case .delete, .ctrl("d"), .ctrl("D"):
            if deleteTableSelectionIfNeeded(cell: cell, updateClipboard: false) {
                return true
            }
            let line = editor.buffer.lines[editor.buffer.lineIndex]
            let (leftBorder, rightBorder) = TableModeController.findCellHorizontalBorders(
                in: line, nearCol: editor.buffer.columnIndex, cell: cell)
            let innerMinCol = leftBorder + 1

            if editor.buffer.columnIndex < rightBorder {
                editor.saveUndoSnapshot()
                var lineChars = Array(line)
                let deleteIdx = editor.buffer.columnIndex
                if deleteIdx >= innerMinCol && deleteIdx < rightBorder && deleteIdx < lineChars.count {
                    let deletedChar = lineChars[deleteIdx]
                    let dw = deletedChar.displayWidth
                    lineChars.remove(at: deleteIdx)
                    let insertSpaceIdx = min(rightBorder - 1, lineChars.count)
                    for _ in 0..<dw {
                        lineChars.insert(" ", at: insertSpaceIdx)
                    }
                    editor.buffer.lines[editor.buffer.lineIndex] = String(lineChars)
                }
            }
            clampTableModeCursor()
            return true

        case .char(let ch):
            _ = deleteTableSelectionIfNeeded(cell: cell, updateClipboard: false)
            if insertCharacterInCurrentTableCell(ch, cell: cell, saveSnapshot: true) {
                let (_, newRight) = TableModeController.findCellHorizontalBorders(
                    in: editor.buffer.lines[editor.buffer.lineIndex], nearCol: editor.buffer.columnIndex, cell: cell)
                if editor.buffer.columnIndex >= newRight && editor.buffer.lineIndex < cell.innerMaxLine {
                    moveToNextLineInCurrentTableCell(cell: cell)
                }
            } else if editor.isCanvasModeActive && editor.buffer.columnIndex >= cell.innerMaxCol
                && editor.buffer.lineIndex < cell.innerMaxLine
            {
                moveToNextLineInCurrentTableCell(cell: cell)
                _ = insertCharacterInCurrentTableCell(ch, cell: cell, saveSnapshot: true)
            }

            clampTableModeCursor()
            return true

        default:
            return false
        }
    }
}
