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
            editor.clampTableModeCursor()
            editor.syncCanvasCursorFromBuffer()
        }
        defer {
            if editor.isCanvasModeActive {
                editor.clampTableModeCursor()
                editor.syncCanvasCursorFromBuffer()
            }
        }

        switch key {
        case .alt("t"), .alt("T"), .f7:
            editor.clearActiveMark()
            editor.toggleTableMode()
            return true

        case .tab:
            editor.clearActiveMark()
            editor.navigateNextTableCell()
            return true

        case .shiftArrowLeft:
            editor.extendTableSelectionLeft(cell: cell)
            return true

        case .shiftArrowRight:
            editor.extendTableSelectionRight(cell: cell)
            return true

        case .ctrlShiftArrowRight:
            editor.saveUndoSnapshot()
            editor.resizeCurrentTableCellWidth(delta: 1)
            return true

        case .ctrlShiftArrowLeft:
            editor.saveUndoSnapshot()
            editor.resizeCurrentTableCellWidth(delta: -1)
            return true

        case .ctrlShiftArrowDown:
            editor.saveUndoSnapshot()
            editor.resizeCurrentTableCellHeight(delta: 1)
            return true

        case .ctrlShiftArrowUp:
            editor.saveUndoSnapshot()
            editor.resizeCurrentTableCellHeight(delta: -1)
            return true

        case .arrowUp:
            editor.clearActiveMark()
            if editor.buffer.lineIndex == cell.innerMinLine {
                editor.navigateUpTableCell()
            } else {
                let vCol = editor.getVisualColumn(in: editor.buffer.lines[editor.buffer.lineIndex], col: editor.buffer.columnIndex)
                editor.buffer.lineIndex -= 1
                editor.buffer.columnIndex = editor.getCharIndexForVisualColumn(
                    in: editor.buffer.lines[editor.buffer.lineIndex], targetVisualCol: vCol)
            }
            editor.clampTableModeCursor()
            return true

        case .arrowDown:
            editor.clearActiveMark()
            if editor.buffer.lineIndex == cell.innerMaxLine {
                editor.navigateDownTableCell()
            } else {
                let vCol = editor.getVisualColumn(in: editor.buffer.lines[editor.buffer.lineIndex], col: editor.buffer.columnIndex)
                editor.buffer.lineIndex += 1
                editor.buffer.columnIndex = editor.getCharIndexForVisualColumn(
                    in: editor.buffer.lines[editor.buffer.lineIndex], targetVisualCol: vCol)
            }
            editor.clampTableModeCursor()
            return true

        case .pageUp, .ctrl("y"), .ctrl("Y"):
            editor.clearActiveMark()
            let vCol = editor.getVisualColumn(in: editor.buffer.lines[editor.buffer.lineIndex], col: editor.buffer.columnIndex)
            editor.buffer.lineIndex = cell.innerMinLine
            editor.buffer.columnIndex = editor.getCharIndexForVisualColumn(
                in: editor.buffer.lines[editor.buffer.lineIndex], targetVisualCol: vCol)
            editor.clampTableModeCursor()
            return true

        case .pageDown, .ctrl("v"), .ctrl("V"):
            editor.clearActiveMark()
            let vCol = editor.getVisualColumn(in: editor.buffer.lines[editor.buffer.lineIndex], col: editor.buffer.columnIndex)
            editor.buffer.lineIndex = cell.innerMaxLine
            editor.buffer.columnIndex = editor.getCharIndexForVisualColumn(
                in: editor.buffer.lines[editor.buffer.lineIndex], targetVisualCol: vCol)
            editor.clampTableModeCursor()
            return true

        case .arrowLeft:
            editor.clearActiveMark()
            if editor.buffer.columnIndex == cell.innerMinCol {
                editor.navigateLeftAdjacentTableCell()
            } else {
                editor.buffer.columnIndex -= 1
            }
            editor.clampTableModeCursor()
            return true

        case .arrowRight:
            editor.clearActiveMark()
            if editor.buffer.columnIndex == cell.innerMaxCol {
                editor.navigateRightAdjacentTableCell()
            } else {
                editor.buffer.columnIndex += 1
            }
            editor.clampTableModeCursor()
            return true

        case .ctrl("j"), .ctrl("J"):
            editor.centerCellText()
            return true

        case .home, .ctrl("a"), .ctrl("A"):
            editor.clearActiveMark()
            let line = editor.buffer.lines[editor.buffer.lineIndex]
            let (leftBorder, _) = Editor.findCellHorizontalBorders(in: line, nearCol: editor.buffer.columnIndex, cell: cell)
            editor.buffer.columnIndex = leftBorder + 1
            editor.clampTableModeCursor()
            return true

        case .end, .ctrl("e"), .ctrl("E"):
            editor.clearActiveMark()
            let line = editor.buffer.lines[editor.buffer.lineIndex]
            let (leftBorder, rightBorder) = Editor.findCellHorizontalBorders(in: line, nearCol: editor.buffer.columnIndex, cell: cell)
            editor.buffer.columnIndex = max(leftBorder + 1, rightBorder - 1)
            editor.clampTableModeCursor()
            return true

        case .enter:
            editor.clearActiveMark()
            editor.moveToNextTableCellLineOrCell()
            return true

        case .ctrl("k"), .ctrl("K"), .f9:
            editor.cutTableCellText(cell: cell)
            return true

        case .ctrl("u"), .ctrl("U"), .f10:
            if let text = editor.clipboardText, !text.isEmpty {
                editor.pasteTableCellText(text)
                editor.setStatusMessage(editor.l10n["status.uncut_text"])
            } else {
                editor.setStatusMessage(editor.l10n["status.clipboard_empty"])
            }
            return true

        case .backspace:
            if editor.deleteTableSelectionIfNeeded(cell: cell, updateClipboard: false) {
                return true
            }
            let line = editor.buffer.lines[editor.buffer.lineIndex]
            let (leftBorder, rightBorder) = Editor.findCellHorizontalBorders(in: line, nearCol: editor.buffer.columnIndex, cell: cell)
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
            editor.clampTableModeCursor()
            return true

        case .delete, .ctrl("d"), .ctrl("D"):
            if editor.deleteTableSelectionIfNeeded(cell: cell, updateClipboard: false) {
                return true
            }
            let line = editor.buffer.lines[editor.buffer.lineIndex]
            let (leftBorder, rightBorder) = Editor.findCellHorizontalBorders(in: line, nearCol: editor.buffer.columnIndex, cell: cell)
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
            editor.clampTableModeCursor()
            return true

        case .char(let ch):
            _ = editor.deleteTableSelectionIfNeeded(cell: cell, updateClipboard: false)
            if editor.insertCharacterInCurrentTableCell(ch, cell: cell, saveSnapshot: true) {
                let (_, newRight) = Editor.findCellHorizontalBorders(
                    in: editor.buffer.lines[editor.buffer.lineIndex], nearCol: editor.buffer.columnIndex, cell: cell)
                if editor.buffer.columnIndex >= newRight && editor.buffer.lineIndex < cell.innerMaxLine {
                    editor.moveToNextLineInCurrentTableCell(cell: cell)
                }
            } else if editor.isCanvasModeActive && editor.buffer.columnIndex >= cell.innerMaxCol
                && editor.buffer.lineIndex < cell.innerMaxLine
            {
                editor.moveToNextLineInCurrentTableCell(cell: cell)
                _ = editor.insertCharacterInCurrentTableCell(ch, cell: cell, saveSnapshot: true)
            }

            editor.clampTableModeCursor()
            return true

        default:
            return false
        }
    }
}

// MARK: - Editor Table Domain Extensions

extension Editor {
    func extendTableSelectionLeft(cell: TableCell) {
        if buffer.selectionMark == nil {
            buffer.selectionMark = (line: buffer.lineIndex, column: buffer.columnIndex)
            setStatusMessage(l10n["status.mark_set"])
        }

        let line = buffer.lines[buffer.lineIndex]
        let (leftBorder, _) = Editor.findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
        let innerMinCol = leftBorder + 1
        if buffer.columnIndex > innerMinCol {
            buffer.columnIndex -= 1
        } else if buffer.lineIndex > cell.innerMinLine {
            buffer.lineIndex -= 1
            let previousLine = buffer.lines[buffer.lineIndex]
            let (previousLeft, previousRight) = Editor.findCellHorizontalBorders(
                in: previousLine, nearCol: cell.innerMinCol, cell: cell)
            buffer.columnIndex = max(previousLeft + 1, previousRight - 1)
        }
        clampTableModeCursor()
    }

    func extendTableSelectionRight(cell: TableCell) {
        if buffer.selectionMark == nil {
            buffer.selectionMark = (line: buffer.lineIndex, column: buffer.columnIndex)
            setStatusMessage(l10n["status.mark_set"])
        }

        let line = buffer.lines[buffer.lineIndex]
        let (_, rightBorder) = Editor.findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
        if buffer.columnIndex < rightBorder {
            buffer.columnIndex += 1
        } else if buffer.lineIndex < cell.innerMaxLine {
            buffer.lineIndex += 1
            let nextLine = buffer.lines[buffer.lineIndex]
            let (nextLeft, _) = Editor.findCellHorizontalBorders(in: nextLine, nearCol: cell.innerMinCol, cell: cell)
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
        guard let mark = buffer.selectionMark else { return [] }
        let cursor = (line: buffer.lineIndex, column: buffer.columnIndex)
        let (start, end) = TextBuffer.getOrderedRange(mark1: mark, mark2: cursor)
        guard start.line != end.line || start.column != end.column else { return [] }

        var segments: [TableSelectionSegment] = []
        let startLine = max(cell.innerMinLine, start.line)
        let endLine = min(cell.innerMaxLine, end.line)
        guard startLine <= endLine else { return [] }

        for lineIndex in startLine...endLine {
            guard lineIndex >= 0 && lineIndex < buffer.lines.count else { continue }
            let line = buffer.lines[lineIndex]
            let (leftBorder, rightBorder) = Editor.findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
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
        buffer.selectionMark = nil
        clampTableModeCursor()
        setStatusMessage(updateClipboard ? l10n["status.cut_text"] : "[ Deleted selection ]")
        return true
    }

    func cutTableCellText(cell: TableCell) {
        if deleteTableSelectionIfNeeded(cell: cell, updateClipboard: true) {
            return
        }

        let lineIndex = buffer.lineIndex
        guard lineIndex >= 0 && lineIndex < buffer.lines.count else { return }
        let line = buffer.lines[lineIndex]
        let (leftBorder, rightBorder) = Editor.findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
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
        buffer.selectionMark = nil
        clampTableModeCursor()
        setStatusMessage(l10n["status.cut_text"])
    }

    // MARK: - Table Mode Toggle & Enter

    /// Toggles Table Mode on/off.
    func toggleTableMode() {
        if isTableModeActive {
            isTableModeActive = false
            currentTableCell = nil
            overlayMode = .none
            setStatusMessage(l10n["status.table_mode_exited"])
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
        let (cellLeft, cellRight) = Editor.findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
        if buffer.columnIndex <= cellLeft || buffer.columnIndex >= cellRight {
            buffer.columnIndex = cellLeft + 1
        }
        clampTableModeCursor()
        setStatusMessage(l10n["status.table_mode_hint"])
    }

    // MARK: - Table Editing Operations

    /// Inserts LOGO output into the active table cell without shifting or overwriting borders.
    func insertTextInCurrentTableCell(_ text: String) {
        guard isTableModeActive, let cell = currentTableCell else {
            buffer.insertString(text)
            return
        }

        for ch in text {
            if ch.isNewline {
                guard buffer.lineIndex < cell.innerMaxLine else { break }
                moveToNextLineInCurrentTableCell(cell: cell)
                continue
            }

            if buffer.lineIndex < cell.innerMinLine || buffer.lineIndex > cell.innerMaxLine {
                break
            }

            let (_, rightBorder) = Editor.findCellHorizontalBorders(
                in: buffer.lines[buffer.lineIndex], nearCol: buffer.columnIndex, cell: cell)
            if buffer.columnIndex >= rightBorder {
                guard buffer.lineIndex < cell.innerMaxLine else { break }
                moveToNextLineInCurrentTableCell(cell: cell)
            }

            guard insertCharacterInCurrentTableCell(ch, cell: cell) else { break }
        }

        clampTableModeCursor()
    }

    /// Pastes text into the active table cell without shifting or overwriting borders.
    func pasteTableCellText(_ text: String) {
        guard isTableModeActive, let cell = currentTableCell else { return }
        saveUndoSnapshot()
        _ = deleteTableSelectionIfNeeded(cell: cell, updateClipboard: false)
        insertTextInCurrentTableCell(text)
        let line = buffer.lines[buffer.lineIndex]
        let (leftBorder, rightBorder) = Editor.findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
        if buffer.columnIndex >= rightBorder {
            buffer.columnIndex = max(leftBorder + 1, rightBorder - 1)
        }
    }

    func moveToNextLineInCurrentTableCell(cell: TableCell) {
        guard buffer.lineIndex < cell.innerMaxLine else { return }
        buffer.lineIndex += 1
        guard buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count else { return }
        let (nextLineLeft, _) = Editor.findCellHorizontalBorders(
            in: buffer.lines[buffer.lineIndex],
            nearCol: cell.innerMinCol,
            cell: cell)
        buffer.columnIndex = nextLineLeft + 1
        clampTableModeCursor()
    }

    func insertCharacterInCurrentTableCell(_ ch: Character, cell: TableCell, saveSnapshot: Bool = false) -> Bool {
        guard buffer.lineIndex >= cell.innerMinLine && buffer.lineIndex <= cell.innerMaxLine else { return false }
        guard buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count else { return false }
        let line = buffer.lines[buffer.lineIndex]
        let (leftBorder, rightBorder) = Editor.findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
        guard leftBorder >= 0 && rightBorder > leftBorder else { return false }

        let leftVisualCol = line.visualColumn(forCharacterOffset: leftBorder)
        let rightVisualCol = line.visualColumn(forCharacterOffset: rightBorder)
        let innerWidth = max(0, rightVisualCol - leftVisualCol - 1)
        guard innerWidth > 0 else { return false }

        let innerStartVisualCol = leftVisualCol + 1
        let cursorVisualCol = line.visualColumn(forCharacterOffset: buffer.columnIndex)
        let targetVisualCol = max(innerStartVisualCol, min(cursorVisualCol, rightVisualCol))
        let innerTargetVisualCol = targetVisualCol - innerStartVisualCol
        let dw = ch.displayWidth
        guard dw <= innerWidth else { return false }

        var innerText = line.visualSlice(startVisualColumn: innerStartVisualCol, width: innerWidth).text
        var innerChars = Array(innerText)
        var spaceIndices: [Int] = []
        for idx in stride(from: innerChars.count - 1, through: 0, by: -1) {
            if innerChars[idx] == " " {
                spaceIndices.append(idx)
                if spaceIndices.count == dw { break }
            }
        }

        guard spaceIndices.count == dw else { return false }

        if saveSnapshot {
            saveUndoSnapshot()
        }

        var insertIdx = innerText.characterOffset(forVisualColumn: innerTargetVisualCol)
        for spaceIdx in spaceIndices.sorted(by: >) {
            if spaceIdx < innerChars.count {
                innerChars.remove(at: spaceIdx)
                if spaceIdx < insertIdx {
                    insertIdx = max(0, insertIdx - 1)
                }
            }
        }
        innerChars.insert(ch, at: min(insertIdx, innerChars.count))

        innerText = String(innerChars).paddedToDisplayWidth(innerWidth)

        let lineChars = Array(line)
        let prefix = String(lineChars[...leftBorder])
        let suffix = String(lineChars[rightBorder...])
        buffer.lines[buffer.lineIndex] = prefix + innerText + suffix
        buffer.columnIndex = prefix.count + min(insertIdx + 1, innerText.count)
        buffer.isModified = true
        return true
    }

    /// Generates a table at cursor position.
    func createTable(
        rows: Int = 3,
        cols: Int = 3,
        cellWidth requestedCellWidth: Int? = nil,
        enterMode: Bool = false,
        saveSnapshot: Bool = true
    ) {
        if saveSnapshot {
            saveUndoSnapshot()
        }
        let origLine = buffer.lineIndex
        let origCol = buffer.columnIndex
        let style = defaultBorderStyle
        let rowCount = max(TableLimits.minRows, min(rows, TableLimits.maxRows))
        let colCount = max(TableLimits.minCols, min(cols, TableLimits.maxCols))
        let cellWidth = max(
            TableLimits.minCellWidth,
            min(requestedCellWidth ?? TableLimits.defaultCellWidth, TableLimits.maxCellWidth)
        )

        let chars = style.tableCharacters
        let h = String(repeating: chars.horizontal, count: cellWidth)
        let content = String(repeating: " ", count: cellWidth)
        var tableLines: [String] = []
        tableLines.append(
            chars.topLeft + Array(repeating: h, count: colCount).joined(separator: chars.topJoin) + chars.topRight)
        for row in 0..<rowCount {
            tableLines.append(
                chars.vertical + Array(repeating: content, count: colCount).joined(separator: chars.vertical)
                    + chars.vertical)
            if row < rowCount - 1 {
                tableLines.append(
                    chars.midLeft + Array(repeating: h, count: colCount).joined(separator: chars.midJoin)
                        + chars.midRight)
            }
        }
        tableLines.append(
            chars.bottomLeft + Array(repeating: h, count: colCount).joined(separator: chars.bottomJoin)
                + chars.bottomRight)
        insertTableLines(tableLines, at: origLine, column: origCol)

        buffer.lineIndex = origLine + 1
        buffer.columnIndex = origCol + 1
        buffer.clampCursor()
        buffer.isModified = true

        if enterMode {
            let detector = TableCellDetector()
            if let cell = detector.detectCell(in: buffer.lines, line: buffer.lineIndex, col: buffer.columnIndex) {
                enterTableMode(with: cell)
            } else {
                let cell = TableCell(
                    minLine: origLine, maxLine: min(buffer.lines.count - 1, origLine + 3), minCol: origCol,
                    maxCol: origCol + cellWidth,
                    style: style)
                enterTableMode(with: cell)
            }
        } else {
            setStatusMessage(l10n["status.table_created"])
        }
    }

    private func insertTableLines(_ tableLines: [String], at startLine: Int, column: Int) {
        guard !tableLines.isEmpty else { return }
        while buffer.lines.count <= startLine {
            buffer.lines.append("")
        }

        let currentLine = buffer.lines[startLine]
        let splitColumn = max(0, min(column, currentLine.count))
        let splitIndex = currentLine.index(currentLine.startIndex, offsetBy: splitColumn)
        let prefix = String(currentLine[..<splitIndex])
        let suffix = String(currentLine[splitIndex...])
        let indent = String(repeating: " ", count: splitColumn)

        var insertedLines: [String] = []
        for (idx, line) in tableLines.enumerated() {
            insertedLines.append(idx == 0 ? prefix + line : indent + line)
        }
        if !suffix.isEmpty {
            insertedLines.append(suffix)
        }

        buffer.lines.replaceSubrange(startLine...startLine, with: insertedLines)
    }

    /// Centers text inside each line of the current table cell.
    func centerCellText() {
        guard let cell = currentTableCell else { return }
        saveUndoSnapshot()

        for lineIdx in cell.innerMinLine...cell.innerMaxLine {
            guard lineIdx < buffer.lines.count else { continue }
            let fullLine = buffer.lines[lineIdx]
            let lineChars = Array(fullLine)

            let (leftBorder, rightBorder) = Editor.findCellHorizontalBorders(
                in: fullLine, nearCol: cell.innerMinCol, cell: cell)
            let innerMinCol = leftBorder + 1
            let innerMaxCol = rightBorder - 1

            guard innerMinCol <= innerMaxCol && rightBorder < lineChars.count else { continue }

            let cellContent = String(lineChars[innerMinCol...innerMaxCol])
            let trimmed = cellContent.trimmingCharacters(in: .whitespaces)

            let innerWidth = lineChars[innerMinCol...innerMaxCol].reduce(0) { $0 + $1.displayWidth }
            let contentWidth = trimmed.displayWidth

            if contentWidth <= innerWidth {
                let totalPadding = innerWidth - contentWidth
                let leftPadding = totalPadding / 2
                let rightPadding = totalPadding - leftPadding

                let newCellText =
                    String(repeating: " ", count: leftPadding) + trimmed + String(repeating: " ", count: rightPadding)
                let prefix = String(lineChars[0...leftBorder])
                let suffix = String(lineChars[rightBorder..<lineChars.count])

                buffer.lines[lineIdx] = prefix + newCellText + suffix
            }
        }
        setStatusMessage(l10n["status.cell_text_centered"])
    }

    func joinCurrentTableCellLine(separator: String) {
        guard isTableModeActive, let cell = currentTableCell else { return }
        clampTableModeCursor()
        guard buffer.lineIndex < cell.innerMaxLine else { return }

        let currentText = tableCellInnerText(on: buffer.lineIndex, cell: cell) ?? ""
        let nextText = tableCellInnerText(on: buffer.lineIndex + 1, cell: cell) ?? ""
        let joinedText = currentText.trimmingTrailingWhitespace() + separator + nextText.trimmingLeadingWhitespace()

        replaceTableCellInnerText(on: buffer.lineIndex, cell: cell, with: joinedText)

        let overflow = joinedText.dropDisplayWidth(tableCellInnerWidth(on: buffer.lineIndex, cell: cell))
        replaceTableCellInnerText(on: buffer.lineIndex + 1, cell: cell, with: overflow)

        let line = buffer.lines[buffer.lineIndex]
        let (_, rightBorder) = Editor.findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
        buffer.columnIndex = max(cell.innerMinCol, rightBorder - 1)
        buffer.isModified = true
        clampTableModeCursor()
    }

    /// Fills every editable row in the active table cell while preserving borders.
    func fillCurrentTableCell(with fillText: String) -> Bool {
        guard isTableModeActive, let cell = currentTableCell else { return false }
        guard cell.innerMinLine <= cell.innerMaxLine else { return false }
        guard !fillText.isEmpty else {
            setStatusMessage(l10n["status.fill_text_required"])
            return true
        }

        saveUndoSnapshot()
        var didFill = false
        for lineIdx in cell.innerMinLine...cell.innerMaxLine {
            let width = tableCellInnerWidth(on: lineIdx, cell: cell)
            guard width > 0 else { continue }
            replaceTableCellInnerText(
                on: lineIdx,
                cell: cell,
                with: fillText.repeatedToDisplayWidth(width)
            )
            didFill = true
        }

        if didFill {
            buffer.isModified = true
            setStatusMessage(l10n["status.filled_cell"])
            clampTableModeCursor()
        }
        return true
    }

    /// Deletes the current visual row inside the active cell without removing the buffer line or table borders.
    func deleteCurrentTableCellLine() {
        guard isTableModeActive, let cell = currentTableCell else {
            buffer.deleteLine()
            return
        }

        clampTableModeCursor()
        let startLine = max(cell.innerMinLine, min(buffer.lineIndex, cell.innerMaxLine))

        for lineIdx in startLine...cell.innerMaxLine {
            let sourceLine = lineIdx < cell.innerMaxLine ? lineIdx + 1 : nil
            let sourceText = sourceLine.flatMap { tableCellInnerText(on: $0, cell: cell) } ?? ""
            replaceTableCellInnerText(on: lineIdx, cell: cell, with: sourceText)
        }

        buffer.lineIndex = startLine
        if buffer.lineIndex < buffer.lines.count {
            let line = buffer.lines[buffer.lineIndex]
            let (leftBorder, _) = Editor.findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
            buffer.columnIndex = leftBorder + 1
        }
        buffer.isModified = true
        clampTableModeCursor()
    }

    private func tableCellInnerText(on lineIdx: Int, cell: TableCell) -> String? {
        guard lineIdx >= 0 && lineIdx < buffer.lines.count else { return nil }

        let fullLine = buffer.lines[lineIdx]
        let lineChars = Array(fullLine)
        let (leftBorder, rightBorder) = Editor.findCellHorizontalBorders(in: fullLine, nearCol: cell.innerMinCol, cell: cell)
        let innerMinCol = leftBorder + 1
        let innerMaxCol = rightBorder - 1

        guard innerMinCol <= innerMaxCol, innerMaxCol < lineChars.count else { return "" }
        return String(lineChars[innerMinCol...innerMaxCol])
    }

    private func replaceTableCellInnerText(on lineIdx: Int, cell: TableCell, with text: String) {
        guard lineIdx >= 0 && lineIdx < buffer.lines.count else { return }

        let fullLine = buffer.lines[lineIdx]
        let lineChars = Array(fullLine)
        let (leftBorder, rightBorder) = Editor.findCellHorizontalBorders(in: fullLine, nearCol: cell.innerMinCol, cell: cell)
        let innerMinCol = leftBorder + 1
        let innerMaxCol = rightBorder - 1

        guard innerMinCol <= innerMaxCol, rightBorder < lineChars.count else { return }

        let innerWidth = lineChars[innerMinCol...innerMaxCol].reduce(0) { $0 + $1.displayWidth }
        let newCellText = text.paddedToDisplayWidth(innerWidth)

        let prefix = String(lineChars[0...leftBorder])
        let suffix = String(lineChars[rightBorder..<lineChars.count])
        buffer.lines[lineIdx] = prefix + newCellText + suffix
    }

    private func tableCellInnerWidth(on lineIdx: Int, cell: TableCell) -> Int {
        guard lineIdx >= 0 && lineIdx < buffer.lines.count else { return 0 }
        let fullLine = buffer.lines[lineIdx]
        let lineChars = Array(fullLine)
        let (leftBorder, rightBorder) = Editor.findCellHorizontalBorders(in: fullLine, nearCol: cell.innerMinCol, cell: cell)
        let innerMinCol = leftBorder + 1
        let innerMaxCol = rightBorder - 1
        guard innerMinCol <= innerMaxCol, innerMaxCol < lineChars.count else { return 0 }
        return lineChars[innerMinCol...innerMaxCol].reduce(0) { $0 + $1.displayWidth }
    }

    // MARK: - Table Navigation Operations

    /// Finds the left and right vertical border character indices for the current cell on the given line string.
    static func findCellHorizontalBorders(in line: String, nearCol: Int, cell: TableCell) -> (left: Int, right: Int) {
        let chars = Array(line)
        guard !chars.isEmpty else { return (0, 0) }

        let targetCol = max(cell.minCol, min(nearCol, cell.maxCol))
        var startSearch = max(0, min(targetCol, chars.count - 1))
        if startSearch > 0 && BorderCharacterSet.verticalBoundaryChars.contains(chars[startSearch]) {
            startSearch -= 1
        }

        var left = startSearch
        while left >= 0 {
            if BorderCharacterSet.verticalBoundaryChars.contains(chars[left]) {
                break
            }
            left -= 1
        }
        if left < 0 { left = 0 }

        var right = left + 1
        while right < chars.count {
            if BorderCharacterSet.verticalBoundaryChars.contains(chars[right]) {
                break
            }
            right += 1
        }
        if right >= chars.count { right = chars.count - 1 }

        return (left, right)
    }

    /// Clamps cursor position to inner bounds of current cell.
    func clampTableModeCursor() {
        guard let cell = currentTableCell else { return }
        buffer.lineIndex = max(cell.innerMinLine, min(buffer.lineIndex, cell.innerMaxLine))
        guard buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count else { return }
        let line = buffer.lines[buffer.lineIndex]
        let (leftBorder, rightBorder) = Editor.findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
        let innerMinCol = leftBorder + 1
        let maxCol = min(rightBorder, line.count)
        buffer.columnIndex = max(innerMinCol, min(buffer.columnIndex, maxCol))
    }

    /// Navigates to next table cell to the right or next row (Tab).
    func navigateNextTableCell() {
        guard let cell = currentTableCell else { return }
        let detector = TableCellDetector()

        if let nextCell = findNextCellToRight(of: cell, on: buffer.lineIndex, detector: detector) {
            enterTableMode(with: nextCell)
            return
        }

        // Scan for first cell in the next row below cell.maxLine
        for lineOffset in 1...3 {
            let targetLine = cell.maxLine + lineOffset
            guard targetLine < buffer.lines.count else { break }
            let chars = Array(buffer.lines[targetLine])
            for col in 0..<chars.count {
                if let nextRowCell = detector.detectCell(in: buffer.lines, line: targetLine, col: col + 1) {
                    enterTableMode(with: nextRowCell)
                    return
                }
            }
        }
    }

    func findNextCellToRight(
        of cell: TableCell, on targetLine: Int, detector: TableCellDetector
    ) -> TableCell? {
        guard targetLine >= 0 && targetLine < buffer.lines.count else { return nil }

        let chars = Array(buffer.lines[targetLine])
        guard cell.maxCol + 1 < chars.count else { return nil }

        for col in (cell.maxCol + 1)..<chars.count {
            guard let candidate = detector.detectCell(in: buffer.lines, line: targetLine, col: col) else {
                continue
            }
            if candidate.minCol >= cell.maxCol && candidate.maxCol > cell.maxCol {
                return candidate
            }
        }

        return nil
    }

    func navigateRightAdjacentTableCell() {
        guard let cell = currentTableCell else { return }
        let detector = TableCellDetector()
        guard let rightCell = detector.detectCell(in: buffer.lines, line: buffer.lineIndex, col: cell.maxCol + 1),
            rightCell.minLine == cell.minLine,
            rightCell.maxLine == cell.maxLine,
            rightCell.minCol == cell.maxCol
        else { return }

        enterTableMode(with: rightCell)
    }

    func navigateLeftAdjacentTableCell() {
        guard let cell = currentTableCell, cell.minCol > 0 else { return }
        let detector = TableCellDetector()
        guard let leftCell = detector.detectCell(in: buffer.lines, line: buffer.lineIndex, col: cell.minCol - 1),
            leftCell.minLine == cell.minLine,
            leftCell.maxLine == cell.maxLine,
            leftCell.maxCol == cell.minCol
        else { return }

        enterTableMode(with: leftCell)
    }

    /// Returns visual display column width for a given character index in a line string.
    func getVisualColumn(in line: String, col: Int) -> Int {
        line.visualColumn(forCharacterOffset: col)
    }

    /// Returns Character array index in line string corresponding to target visual display column width.
    func getCharIndexForVisualColumn(in line: String, targetVisualCol: Int) -> Int {
        line.characterOffset(forVisualColumn: targetVisualCol)
    }

    /// Navigates to table cell above (Up Arrow at top row of cell).
    func navigateUpTableCell() {
        guard let cell = currentTableCell else { return }
        let currentLineText = buffer.lines[buffer.lineIndex]
        let currentVCol = getVisualColumn(in: currentLineText, col: buffer.columnIndex)
        let detector = TableCellDetector()
        let targetLine = cell.minLine - 1
        guard targetLine >= 0 else { return }
        let lineText = buffer.lines[targetLine]
        let charIdx = getCharIndexForVisualColumn(in: lineText, targetVisualCol: currentVCol)
        let safeCol = max(0, min(charIdx, lineText.count))

        guard let cellAbove = detector.detectCell(in: buffer.lines, line: targetLine, col: safeCol),
            cellAbove.maxLine == cell.minLine,
            cellAbove.minCol < cell.maxCol,
            cellAbove.maxCol > cell.minCol
        else { return }

        enterTableMode(with: cellAbove)
        buffer.lineIndex = cellAbove.innerMaxLine
        let targetLineText = buffer.lines[buffer.lineIndex]
        buffer.columnIndex = getCharIndexForVisualColumn(in: targetLineText, targetVisualCol: currentVCol)
        clampTableModeCursor()
    }

    /// Navigates to table cell below (Down Arrow at bottom row of cell).
    func navigateDownTableCell() {
        guard let cell = currentTableCell else { return }
        let currentLineText = buffer.lines[buffer.lineIndex]
        let currentVCol = getVisualColumn(in: currentLineText, col: buffer.columnIndex)
        let detector = TableCellDetector()
        let targetLine = cell.maxLine + 1
        guard targetLine < buffer.lines.count else { return }
        let lineText = buffer.lines[targetLine]
        let charIdx = getCharIndexForVisualColumn(in: lineText, targetVisualCol: currentVCol)
        let safeCol = max(0, min(charIdx, lineText.count))

        guard let cellBelow = detector.detectCell(in: buffer.lines, line: targetLine, col: safeCol),
            cellBelow.minLine == cell.maxLine,
            cellBelow.minCol < cell.maxCol,
            cellBelow.maxCol > cell.minCol
        else { return }

        enterTableMode(with: cellBelow)
        buffer.lineIndex = cellBelow.innerMinLine
        let targetLineText = buffer.lines[buffer.lineIndex]
        buffer.columnIndex = getCharIndexForVisualColumn(in: targetLineText, targetVisualCol: currentVCol)
        clampTableModeCursor()
    }

    /// Navigates to previous table cell to the left or previous row (Shift+Tab).
    func navigatePrevTableCell() {
        guard let cell = currentTableCell else { return }
        let prevCol = max(0, cell.minCol - 2)
        let detector = TableCellDetector()
        if let prevCell = detector.detectCell(in: buffer.lines, line: cell.innerMinLine, col: prevCol) {
            enterTableMode(with: prevCell)
            return
        }

        // Scan for last cell in row above
        for lineOffset in 1...3 {
            let targetLine = cell.minLine - lineOffset
            guard targetLine >= 0 else { break }
            let chars = Array(buffer.lines[targetLine])
            for col in stride(from: chars.count - 1, through: 0, by: -1) {
                if let prevRowCell = detector.detectCell(in: buffer.lines, line: targetLine, col: col + 1) {
                    enterTableMode(with: prevRowCell)
                    return
                }
            }
        }
    }

    func moveToNextTableCellLineOrCell() {
        guard let cell = currentTableCell else { return }
        if buffer.lineIndex < cell.innerMaxLine {
            buffer.lineIndex += 1
            let line = buffer.lines[buffer.lineIndex]
            let (leftBorder, _) = Editor.findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
            buffer.columnIndex = leftBorder + 1
        } else {
            navigateNextTableCell()
        }
        clampTableModeCursor()
    }

    func detectTableLineRange(for cell: TableCell) -> [Int] {
        var start = cell.minLine
        var end = cell.maxLine
        let lines = buffer.lines
        let detector = TableCellDetector()

        while start > 0 {
            if detector.detectCell(in: lines, line: start - 1, col: cell.innerMinCol) != nil {
                start -= 1
            } else if isAnyBorderLine(lines[start - 1], colLeft: cell.minCol) {
                start -= 1
            } else {
                break
            }
        }

        while end < lines.count - 1 {
            if detector.detectCell(in: lines, line: end + 1, col: cell.innerMinCol) != nil {
                end += 1
            } else if isAnyBorderLine(lines[end + 1], colLeft: cell.minCol) {
                end += 1
            } else {
                break
            }
        }
        return Array(start...end)
    }

    func isTableBorderLine(_ chars: [Character], colLeft: Int, colRight: Int) -> Bool {
        guard colLeft + 1 < chars.count else { return false }
        let c = chars[colLeft + 1]
        if BorderCharacterSet.isHorizontal(c) {
            return true
        }
        if colLeft < chars.count && BorderCharacterSet.isJunction(chars[colLeft]) {
            return true
        }
        return false
    }

    func isAnyBorderLine(_ line: String, colLeft: Int) -> Bool {
        let chars = Array(line)
        guard colLeft < chars.count else { return false }
        return BorderCharacterSet.verticalBoundaryChars.contains(chars[colLeft])
    }

    // MARK: - Table Resize Operations

    /// Resizes the column width of the active table cell (or standalone box) by delta (+1 or -1).
    func resizeCurrentTableCellWidth(delta: Int) {
        guard isTableModeActive, let cell = currentTableCell else { return }
        let detector = TableCellDetector()
        let tableLines = detectTableLineRange(for: cell)

        let colLeft = cell.minCol
        let colRight = cell.maxCol
        let currentWidth = colRight - colLeft - 1

        let nextCellToRight = findNextCellToRight(of: cell, on: cell.innerMinLine, detector: detector)
        let isSameGridTable = (nextCellToRight != nil && nextCellToRight!.minCol == colRight)

        if delta < 0 {
            for lineIdx in tableLines {
                let line = buffer.lines[lineIdx]
                let chars = Array(line)
                let (leftB, rightB) = Editor.findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
                if isTableBorderLine(chars, colLeft: leftB, colRight: rightB) {
                    continue
                }
                if leftB == colLeft && rightB == colRight {
                    if leftB + 1 < rightB {
                        let endIdx = min(rightB, chars.count)
                        let textInside = String(chars[(leftB + 1)..<endIdx]).trimmingTrailingWhitespace()
                        if textInside.displayWidth >= currentWidth {
                            setStatusMessage(l10n["status.cannot_shrink_width"])
                            return
                        }
                    }
                }
            }
            if currentWidth <= 1 {
                setStatusMessage(l10n["status.cannot_shrink_width"])
                return
            }
        } else if delta > 0 {
            for lineIdx in tableLines {
                let line = buffer.lines[lineIdx]
                let chars = Array(line)
                let (leftB, rightB) = Editor.findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
                if leftB == colLeft && rightB == colRight {
                    let nextIdx = rightB + 1
                    if nextIdx < chars.count && BorderCharacterSet.verticalBoundaryChars.contains(chars[nextIdx]) {
                        if !isSameGridTable {
                            setStatusMessage(l10n["status.cannot_expand_width_collision"])
                            return
                        }
                    }
                }
            }
        }

        for lineIdx in tableLines {
            var chars = Array(buffer.lines[lineIdx])
            if chars.count <= colLeft { continue }

            let (leftB, rightB) = Editor.findCellHorizontalBorders(
                in: buffer.lines[lineIdx], nearCol: cell.innerMinCol, cell: cell)
            if leftB != colLeft { continue }

            if delta > 0 {
                let isBorderLine = isTableBorderLine(chars, colLeft: leftB, colRight: rightB)
                let horiz = cell.style.tableCharacters.horizontal.first ?? "─"
                let insertChar: Character = isBorderLine ? horiz : " "
                let insertIndex = min(rightB, chars.count)
                chars.insert(insertChar, at: insertIndex)

                if !isSameGridTable {
                    let connectorIdx = insertIndex + 2
                    if connectorIdx < chars.count {
                        let c = chars[connectorIdx]
                        if BorderCharacterSet.isHorizontal(c) || c == " " {
                            chars.remove(at: connectorIdx)
                        }
                    }
                }
            } else if delta < 0 {
                let removeIndex = rightB - 1
                if removeIndex > colLeft && removeIndex < chars.count {
                    chars.remove(at: removeIndex)
                }
            }
            buffer.lines[lineIdx] = String(chars)
        }

        buffer.isModified = true

        if let newCell = detector.detectCell(in: buffer.lines, line: buffer.lineIndex, col: buffer.columnIndex) {
            currentTableCell = newCell
        }
        clampTableModeCursor()
    }

    /// Resizes the row height of the active table cell (or standalone box) by delta (+1 or -1).
    func resizeCurrentTableCellHeight(delta: Int) {
        guard isTableModeActive, let cell = currentTableCell else { return }
        let detector = TableCellDetector()

        let minLine = cell.minLine
        let maxLine = cell.maxLine
        let currentHeight = maxLine - minLine - 1

        if delta < 0 {
            if currentHeight <= 1 {
                setStatusMessage(l10n["status.cannot_shrink_height"])
                return
            }

            var lineToRemove: Int? = nil
            for lineIdx in stride(from: maxLine - 1, through: minLine + 1, by: -1) {
                if isLineEmptyAcrossRow(lineIdx) {
                    lineToRemove = lineIdx
                    break
                }
            }

            guard let removeLineIdx = lineToRemove else {
                setStatusMessage(l10n["status.cannot_shrink_height"])
                return
            }

            buffer.lines.remove(at: removeLineIdx)
            if buffer.lineIndex >= removeLineIdx && buffer.lineIndex > minLine + 1 {
                buffer.lineIndex -= 1
            }
        } else if delta > 0 {
            let templateLineIdx = minLine + 1
            let templateLine = (templateLineIdx < buffer.lines.count) ? buffer.lines[templateLineIdx] : ""
            var newLineChars = Array(templateLine)

            for c in 0..<newLineChars.count {
                if !BorderCharacterSet.verticalBoundaryChars.contains(newLineChars[c]) {
                    newLineChars[c] = " "
                }
            }
            let newLineStr = String(newLineChars)
            let insertLineIdx = maxLine
            buffer.lines.insert(newLineStr, at: insertLineIdx)
        }

        buffer.isModified = true

        if let newCell = detector.detectCell(in: buffer.lines, line: buffer.lineIndex, col: buffer.columnIndex) {
            currentTableCell = newCell
        }
        clampTableModeCursor()
    }

    private func isLineEmptyAcrossRow(_ lineIdx: Int) -> Bool {
        guard lineIdx >= 0 && lineIdx < buffer.lines.count else { return false }
        let line = buffer.lines[lineIdx]
        let chars = Array(line)

        for c in chars {
            if BorderCharacterSet.verticalBoundaryChars.contains(c) {
                continue
            }
            if !c.isWhitespace {
                return false
            }
        }
        return true
    }
}

extension String {
    func trimmingLeadingWhitespace() -> String {
        String(drop(while: { $0.isWhitespace }))
    }

    func trimmingTrailingWhitespace() -> String {
        var result = self
        while result.last?.isWhitespace == true {
            result.removeLast()
        }
        return result
    }

    func dropDisplayWidth(_ width: Int) -> String {
        guard width > 0 else { return self }
        var result = ""
        var visualWidth = 0
        var isDropping = true

        for ch in self {
            let chWidth = ch.displayWidth
            if isDropping {
                if visualWidth + chWidth <= width {
                    visualWidth += chWidth
                    continue
                }
                isDropping = false
            }
            result.append(ch)
        }
        return result
    }
}

