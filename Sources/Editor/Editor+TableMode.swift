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

extension Editor {
    /// Intercepts and processes keyboard events when Table Mode is active.
    /// - Returns: `true` if key event was handled in Table Mode.
    func processTableModeKey(_ key: Key) -> Bool {
        guard isTableModeActive, let cell = currentTableCell else { return false }
        if isCanvasModeActive {
            syncCanvasCursorToBuffer()
            clampTableModeCursor()
            syncCanvasCursorFromBuffer()
        }
        defer {
            if isCanvasModeActive {
                clampTableModeCursor()
                syncCanvasCursorFromBuffer()
            }
        }

        switch key {
        case .alt("t"), .alt("T"), .f7:
            clearActiveMark()
            toggleTableMode()
            return true

        case .tab:
            clearActiveMark()
            navigateNextTableCell()
            return true

        case .shiftArrowLeft:
            extendTableSelectionLeft(cell: cell)
            return true

        case .shiftArrowRight:
            extendTableSelectionRight(cell: cell)
            return true

        case .ctrlShiftArrowRight:
            saveUndoSnapshot()
            resizeCurrentTableCellWidth(delta: 1)
            return true

        case .ctrlShiftArrowLeft:
            saveUndoSnapshot()
            resizeCurrentTableCellWidth(delta: -1)
            return true

        case .ctrlShiftArrowDown:
            saveUndoSnapshot()
            resizeCurrentTableCellHeight(delta: 1)
            return true

        case .ctrlShiftArrowUp:
            saveUndoSnapshot()
            resizeCurrentTableCellHeight(delta: -1)
            return true

        case .arrowUp:
            clearActiveMark()
            if buffer.lineIndex == cell.innerMinLine {
                navigateUpTableCell()
            } else {
                let vCol = getVisualColumn(in: buffer.lines[buffer.lineIndex], col: buffer.columnIndex)
                buffer.lineIndex -= 1
                buffer.columnIndex = getCharIndexForVisualColumn(
                    in: buffer.lines[buffer.lineIndex], targetVisualCol: vCol)
            }
            clampTableModeCursor()
            return true

        case .arrowDown:
            clearActiveMark()
            if buffer.lineIndex == cell.innerMaxLine {
                navigateDownTableCell()
            } else {
                let vCol = getVisualColumn(in: buffer.lines[buffer.lineIndex], col: buffer.columnIndex)
                buffer.lineIndex += 1
                buffer.columnIndex = getCharIndexForVisualColumn(
                    in: buffer.lines[buffer.lineIndex], targetVisualCol: vCol)
            }
            clampTableModeCursor()
            return true

        case .pageUp, .ctrl("y"), .ctrl("Y"):
            clearActiveMark()
            let vCol = getVisualColumn(in: buffer.lines[buffer.lineIndex], col: buffer.columnIndex)
            buffer.lineIndex = cell.innerMinLine
            buffer.columnIndex = getCharIndexForVisualColumn(
                in: buffer.lines[buffer.lineIndex], targetVisualCol: vCol)
            clampTableModeCursor()
            return true

        case .pageDown, .ctrl("v"), .ctrl("V"):
            clearActiveMark()
            let vCol = getVisualColumn(in: buffer.lines[buffer.lineIndex], col: buffer.columnIndex)
            buffer.lineIndex = cell.innerMaxLine
            buffer.columnIndex = getCharIndexForVisualColumn(
                in: buffer.lines[buffer.lineIndex], targetVisualCol: vCol)
            clampTableModeCursor()
            return true

        case .arrowLeft:
            clearActiveMark()
            if buffer.columnIndex == cell.innerMinCol {
                navigateLeftAdjacentTableCell()
            } else {
                buffer.columnIndex -= 1
            }
            clampTableModeCursor()
            return true

        case .arrowRight:
            clearActiveMark()
            if buffer.columnIndex == cell.innerMaxCol {
                navigateRightAdjacentTableCell()
            } else {
                buffer.columnIndex += 1
            }
            clampTableModeCursor()
            return true

        case .ctrl("j"), .ctrl("J"):
            centerCellText()
            return true

        case .home, .ctrl("a"), .ctrl("A"):
            clearActiveMark()
            let line = buffer.lines[buffer.lineIndex]
            let (leftBorder, _) = findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
            buffer.columnIndex = leftBorder + 1
            clampTableModeCursor()
            return true

        case .end, .ctrl("e"), .ctrl("E"):
            clearActiveMark()
            let line = buffer.lines[buffer.lineIndex]
            let (leftBorder, rightBorder) = findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
            buffer.columnIndex = max(leftBorder + 1, rightBorder - 1)
            clampTableModeCursor()
            return true

        case .enter:
            clearActiveMark()
            moveToNextTableCellLineOrCell()
            return true

        case .ctrl("k"), .ctrl("K"), .f9:
            cutTableCellText(cell: cell)
            return true

        case .ctrl("u"), .ctrl("U"), .f10:
            if let text = clipboardText, !text.isEmpty {
                pasteTableCellText(text)
                setStatusMessage(L10n["status.uncut_text"])
            } else {
                setStatusMessage(L10n["status.clipboard_empty"])
            }
            return true

        case .backspace:
            if deleteTableSelectionIfNeeded(cell: cell, updateClipboard: false) {
                return true
            }
            let line = buffer.lines[buffer.lineIndex]
            let (leftBorder, rightBorder) = findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
            let innerMinCol = leftBorder + 1

            if buffer.columnIndex > innerMinCol {
                saveUndoSnapshot()
                var lineChars = Array(line)
                let deleteIdx = buffer.columnIndex - 1
                if deleteIdx >= innerMinCol && deleteIdx < lineChars.count {
                    let deletedChar = lineChars[deleteIdx]
                    let dw = deletedChar.displayWidth
                    lineChars.remove(at: deleteIdx)
                    let insertSpaceIdx = min(rightBorder - 1, lineChars.count)
                    for _ in 0..<dw {
                        lineChars.insert(" ", at: insertSpaceIdx)
                    }
                    buffer.lines[buffer.lineIndex] = String(lineChars)
                    buffer.columnIndex = max(innerMinCol, deleteIdx)
                }
            }
            clampTableModeCursor()
            return true

        case .delete, .ctrl("d"), .ctrl("D"):
            if deleteTableSelectionIfNeeded(cell: cell, updateClipboard: false) {
                return true
            }
            let line = buffer.lines[buffer.lineIndex]
            let (leftBorder, rightBorder) = findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
            let innerMinCol = leftBorder + 1

            if buffer.columnIndex < rightBorder {
                saveUndoSnapshot()
                var lineChars = Array(line)
                let deleteIdx = buffer.columnIndex
                if deleteIdx >= innerMinCol && deleteIdx < rightBorder && deleteIdx < lineChars.count {
                    let deletedChar = lineChars[deleteIdx]
                    let dw = deletedChar.displayWidth
                    lineChars.remove(at: deleteIdx)
                    let insertSpaceIdx = min(rightBorder - 1, lineChars.count)
                    for _ in 0..<dw {
                        lineChars.insert(" ", at: insertSpaceIdx)
                    }
                    buffer.lines[buffer.lineIndex] = String(lineChars)
                }
            }
            clampTableModeCursor()
            return true

        case .char(let ch):
            _ = deleteTableSelectionIfNeeded(cell: cell, updateClipboard: false)
            if insertCharacterInCurrentTableCell(ch, cell: cell, saveSnapshot: true) {
                let (_, newRight) = findCellHorizontalBorders(
                    in: buffer.lines[buffer.lineIndex], nearCol: buffer.columnIndex, cell: cell)
                if buffer.columnIndex >= newRight && buffer.lineIndex < cell.innerMaxLine {
                    moveToNextLineInCurrentTableCell(cell: cell)
                }
            } else if isCanvasModeActive && buffer.columnIndex >= cell.innerMaxCol
                && buffer.lineIndex < cell.innerMaxLine
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

    private func extendTableSelectionLeft(cell: TableCell) {
        if selectionMark == nil {
            selectionMark = (line: buffer.lineIndex, column: buffer.columnIndex)
            setStatusMessage(L10n["status.mark_set"])
        }

        let line = buffer.lines[buffer.lineIndex]
        let (leftBorder, _) = findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
        let innerMinCol = leftBorder + 1
        if buffer.columnIndex > innerMinCol {
            buffer.columnIndex -= 1
        } else if buffer.lineIndex > cell.innerMinLine {
            buffer.lineIndex -= 1
            let previousLine = buffer.lines[buffer.lineIndex]
            let (previousLeft, previousRight) = findCellHorizontalBorders(
                in: previousLine, nearCol: cell.innerMinCol, cell: cell)
            buffer.columnIndex = max(previousLeft + 1, previousRight - 1)
        }
        clampTableModeCursor()
    }

    private func extendTableSelectionRight(cell: TableCell) {
        if selectionMark == nil {
            selectionMark = (line: buffer.lineIndex, column: buffer.columnIndex)
            setStatusMessage(L10n["status.mark_set"])
        }

        let line = buffer.lines[buffer.lineIndex]
        let (_, rightBorder) = findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
        if buffer.columnIndex < rightBorder {
            buffer.columnIndex += 1
        } else if buffer.lineIndex < cell.innerMaxLine {
            buffer.lineIndex += 1
            let nextLine = buffer.lines[buffer.lineIndex]
            let (nextLeft, _) = findCellHorizontalBorders(in: nextLine, nearCol: cell.innerMinCol, cell: cell)
            buffer.columnIndex = nextLeft + 1
        }
        clampTableModeCursor()
    }

    private struct TableSelectionSegment {
        let line: Int
        let startCol: Int
        let endCol: Int
    }

    private func tableSelectionSegments(cell: TableCell) -> [TableSelectionSegment] {
        guard let mark = selectionMark else { return [] }
        let cursor = (line: buffer.lineIndex, column: buffer.columnIndex)
        let (start, end) = getOrderedRange(mark1: mark, mark2: cursor)
        guard start.line != end.line || start.column != end.column else { return [] }

        var segments: [TableSelectionSegment] = []
        let startLine = max(cell.innerMinLine, start.line)
        let endLine = min(cell.innerMaxLine, end.line)
        guard startLine <= endLine else { return [] }

        for lineIndex in startLine...endLine {
            guard lineIndex >= 0 && lineIndex < buffer.lines.count else { continue }
            let line = buffer.lines[lineIndex]
            let (leftBorder, rightBorder) = findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
            let innerStart = leftBorder + 1
            let innerEnd = rightBorder
            let rawStart = lineIndex == start.line ? start.column : innerStart
            let rawEnd = lineIndex == end.line ? end.column : innerEnd
            let segmentStart = max(innerStart, min(rawStart, innerEnd))
            let segmentEnd = max(innerStart, min(rawEnd, innerEnd))
            if segmentStart < segmentEnd {
                segments.append(TableSelectionSegment(line: lineIndex, startCol: segmentStart, endCol: segmentEnd))
            }
        }
        return segments
    }

    private func selectedTableText(segments: [TableSelectionSegment]) -> String {
        segments.map { segment in
            let chars = Array(buffer.lines[segment.line])
            guard segment.startCol < chars.count else { return "" }
            let end = min(segment.endCol, chars.count)
            return String(chars[segment.startCol..<end])
        }.joined(separator: "\n")
    }

    private func clearTableSegments(_ segments: [TableSelectionSegment]) {
        for segment in segments {
            guard segment.line >= 0 && segment.line < buffer.lines.count else { continue }
            var chars = Array(buffer.lines[segment.line])
            guard segment.startCol < chars.count else { continue }
            let end = min(segment.endCol, chars.count)
            var replacement: [Character] = []
            for ch in chars[segment.startCol..<end] {
                replacement.append(contentsOf: Array(String(repeating: " ", count: ch.displayWidth)))
            }
            chars.replaceSubrange(segment.startCol..<end, with: replacement)
            buffer.lines[segment.line] = String(chars)
        }
        buffer.isModified = true
    }

    func deleteTableSelectionIfNeeded(cell: TableCell, updateClipboard: Bool) -> Bool {
        let segments = tableSelectionSegments(cell: cell)
        guard !segments.isEmpty else { return false }
        saveUndoSnapshot()
        if updateClipboard {
            clipboardText = selectedTableText(segments: segments)
        }
        clearTableSegments(segments)
        let first = segments[0]
        buffer.lineIndex = first.line
        buffer.columnIndex = first.startCol
        selectionMark = nil
        clampTableModeCursor()
        setStatusMessage(updateClipboard ? L10n["status.cut_text"] : "[ Deleted selection ]")
        return true
    }

    func cutTableCellText(cell: TableCell) {
        if deleteTableSelectionIfNeeded(cell: cell, updateClipboard: true) {
            return
        }

        let lineIndex = buffer.lineIndex
        guard lineIndex >= 0 && lineIndex < buffer.lines.count else { return }
        let line = buffer.lines[lineIndex]
        let (leftBorder, rightBorder) = findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
        let start = leftBorder + 1
        let end = rightBorder
        guard start < end else { return }

        saveUndoSnapshot()
        var chars = Array(line)
        clipboardText = String(chars[start..<min(end, chars.count)])
        let width = chars[start..<min(end, chars.count)].reduce(0) { $0 + $1.displayWidth }
        chars.replaceSubrange(start..<min(end, chars.count), with: Array(String(repeating: " ", count: width)))
        buffer.lines[lineIndex] = String(chars)
        buffer.columnIndex = start
        buffer.isModified = true
        selectionMark = nil
        clampTableModeCursor()
        setStatusMessage(L10n["status.cut_text"])
    }

    // MARK: - Table Mode Toggle & Enter

    /// Toggles Table Mode on/off.
    func toggleTableMode() {
        if isTableModeActive {
            isTableModeActive = false
            currentTableCell = nil
            overlayMode = .none
            setStatusMessage(L10n["status.table_mode_exited"])
            return
        }

        if let syntax = activeLanguageSyntax, syntax.tableFormatter != nil,
            buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count,
            buffer.lines[buffer.lineIndex].trimmingCharacters(in: CharacterSet.whitespaces).hasPrefix("|")
        {
            setStatusMessage("[ Markdown/Org tables are edited in Text Mode (Tab / ^J) ]")
            return
        }

        let detector = TableCellDetector()
        if let cell = detector.detectCell(in: buffer.lines, line: buffer.lineIndex, col: buffer.columnIndex) {
            enterTableMode(with: cell)
        } else {
            promptTableDimensions()
        }
    }

    /// Enters Table Mode locked to target cell.
    func enterTableMode(with cell: TableCell) {
        clearActiveMark()
        isTableModeActive = true
        overlayMode = .table
        currentTableCell = cell
        let targetLine = max(cell.innerMinLine, min(buffer.lineIndex, cell.innerMaxLine))
        buffer.lineIndex = targetLine
        guard targetLine >= 0 && targetLine < buffer.lines.count else { return }
        let line = buffer.lines[targetLine]
        let (cellLeft, cellRight) = findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
        if buffer.columnIndex <= cellLeft || buffer.columnIndex >= cellRight {
            buffer.columnIndex = cellLeft + 1
        }
        clampTableModeCursor()
        setStatusMessage(L10n["status.table_mode_hint"])
    }
}
