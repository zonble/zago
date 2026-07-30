import Foundation
import TextMetrics

private enum TableLimits {
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
        case .alt("t"), .alt("T"):
            toggleTableMode()
            return true

        case .tab:
            navigateNextTableCell()
            return true

        case .shiftArrowLeft:
            extendTableSelectionLeft(cell: cell)
            return true

        case .shiftArrowRight:
            extendTableSelectionRight(cell: cell)
            return true

        case .arrowUp:
            if buffer.lineIndex == cell.innerMinLine {
                navigateUpTableCell()
            } else {
                let vCol = getVisualColumn(in: buffer.lines[buffer.lineIndex], col: buffer.columnIndex)
                buffer.lineIndex -= 1
                buffer.columnIndex = getCharIndexForVisualColumn(in: buffer.lines[buffer.lineIndex], targetVisualCol: vCol)
            }
            clampTableModeCursor()
            return true

        case .arrowDown:
            if buffer.lineIndex == cell.innerMaxLine {
                navigateDownTableCell()
            } else {
                let vCol = getVisualColumn(in: buffer.lines[buffer.lineIndex], col: buffer.columnIndex)
                buffer.lineIndex += 1
                buffer.columnIndex = getCharIndexForVisualColumn(in: buffer.lines[buffer.lineIndex], targetVisualCol: vCol)
            }
            clampTableModeCursor()
            return true

        case .arrowLeft:
            if buffer.columnIndex == cell.innerMinCol {
                navigateLeftAdjacentTableCell()
            } else {
                buffer.columnIndex -= 1
            }
            clampTableModeCursor()
            return true

        case .arrowRight:
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
            let line = buffer.lines[buffer.lineIndex]
            let (leftBorder, _) = findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
            buffer.columnIndex = leftBorder + 1
            clampTableModeCursor()
            return true

        case .end, .ctrl("e"), .ctrl("E"):
            let line = buffer.lines[buffer.lineIndex]
            let (leftBorder, rightBorder) = findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
            buffer.columnIndex = max(leftBorder + 1, rightBorder - 1)
            clampTableModeCursor()
            return true

        case .enter:
            moveToNextTableCellLineOrCell()
            return true

        case .ctrl("k"), .ctrl("K"):
            cutTableCellText(cell: cell)
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
            if insertCharacterInCurrentTableCell(ch, cell: cell, saveSnapshot: true) {
                let (_, newRight) = findCellHorizontalBorders(in: buffer.lines[buffer.lineIndex], nearCol: buffer.columnIndex, cell: cell)
                if buffer.columnIndex >= newRight && buffer.lineIndex < cell.innerMaxLine {
                    moveToNextLineInCurrentTableCell(cell: cell)
                }
            } else if isCanvasModeActive && buffer.columnIndex >= cell.innerMaxCol && buffer.lineIndex < cell.innerMaxLine {
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
            let (previousLeft, previousRight) = findCellHorizontalBorders(in: previousLine, nearCol: cell.innerMinCol, cell: cell)
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

    private func deleteTableSelectionIfNeeded(cell: TableCell, updateClipboard: Bool) -> Bool {
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

    private func cutTableCellText(cell: TableCell) {
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

    // MARK: - Table Mode Methods

    /// Toggles Table Mode on/off.
    public func toggleTableMode() {
        if isTableModeActive {
            isTableModeActive = false
            currentTableCell = nil
            overlayMode = .none
            setStatusMessage("[ Table Mode Exited ]")
            return
        }

        if overlayMode == .frame {
            setStatusMessage("[ Table Mode disabled in Frame Mode ]")
            return
        }

        let detector = TableCellDetector()
        if let cell = detector.detectCell(in: buffer.lines, line: buffer.lineIndex, col: buffer.columnIndex) {
            enterTableMode(with: cell)
        } else {
            promptCreateTableConfirm()
        }
    }

    /// Enters Table Mode locked to target cell.
    public func enterTableMode(with cell: TableCell) {
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
        setStatusMessage("[ TABLE MODE ] (M+T to exit | Tab to navigate)")
    }

    /// Finds the left and right vertical border character indices for the current cell on the given line string.
    public func findCellHorizontalBorders(in line: String, nearCol: Int, cell: TableCell) -> (left: Int, right: Int) {
        let chars = Array(line)
        guard !chars.isEmpty else { return (0, 0) }

        let targetCol = max(cell.minCol, min(nearCol, cell.maxCol))
        var startSearch = max(0, min(targetCol, chars.count - 1))
        if startSearch > 0 && TableCellDetector.verticalBorderChars.contains(chars[startSearch]) {
            startSearch -= 1
        }

        var left = startSearch
        while left >= 0 {
            if TableCellDetector.verticalBorderChars.contains(chars[left]) {
                break
            }
            left -= 1
        }
        if left < 0 { left = 0 }

        var right = left + 1
        while right < chars.count {
            if TableCellDetector.verticalBorderChars.contains(chars[right]) {
                break
            }
            right += 1
        }
        if right >= chars.count { right = chars.count - 1 }

        return (left, right)
    }

    /// Clamps cursor position to inner bounds of current cell.
    public func clampTableModeCursor() {
        guard let cell = currentTableCell else { return }
        buffer.lineIndex = max(cell.innerMinLine, min(buffer.lineIndex, cell.innerMaxLine))
        guard buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count else { return }
        let line = buffer.lines[buffer.lineIndex]
        let (leftBorder, rightBorder) = findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
        let innerMinCol = leftBorder + 1
        let maxCol = min(rightBorder, line.count)
        buffer.columnIndex = max(innerMinCol, min(buffer.columnIndex, maxCol))
    }

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

            let (_, rightBorder) = findCellHorizontalBorders(in: buffer.lines[buffer.lineIndex], nearCol: buffer.columnIndex, cell: cell)
            if buffer.columnIndex >= rightBorder {
                guard buffer.lineIndex < cell.innerMaxLine else { break }
                moveToNextLineInCurrentTableCell(cell: cell)
            }

            guard insertCharacterInCurrentTableCell(ch, cell: cell) else { break }
        }

        clampTableModeCursor()
    }

    private func moveToNextLineInCurrentTableCell(cell: TableCell) {
        guard buffer.lineIndex < cell.innerMaxLine else { return }
        buffer.lineIndex += 1
        guard buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count else { return }
        let (nextLineLeft, _) = findCellHorizontalBorders(
            in: buffer.lines[buffer.lineIndex],
            nearCol: cell.innerMinCol,
            cell: cell)
        buffer.columnIndex = nextLineLeft + 1
        clampTableModeCursor()
    }

    private func insertCharacterInCurrentTableCell(_ ch: Character, cell: TableCell, saveSnapshot: Bool = false) -> Bool {
        guard buffer.lineIndex >= cell.innerMinLine && buffer.lineIndex <= cell.innerMaxLine else { return false }
        guard buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count else { return false }
        let line = buffer.lines[buffer.lineIndex]
        let (leftBorder, rightBorder) = findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
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

    /// Prompts user to confirm creating a 3x3 table when no cell is found.
    public func promptCreateTableConfirm() {
        currentPromptMode = .confirmCreateTable(completion: { [weak self] confirm in
            guard let self = self, let confirm = confirm else {
                self?.setStatusMessage("[ Table mode cancelled ]")
                return
            }
            if confirm {
                self.createDefaultTable()
            } else {
                self.setStatusMessage("[ Table mode cancelled ]")
            }
        })
    }

    /// Generates a default 3x3 table at cursor position and enters Table Mode.
    public func createDefaultTable() {
        createTable(rows: 3, cols: 3, enterMode: true, saveSnapshot: true)
    }

    /// Generates a table at cursor position.
    public func createTable(
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

        if style == .markdown {
            let headerCells = (1...colCount).map { "Header \($0)".padding(toLength: cellWidth, withPad: " ", startingAt: 0) }
            var tableLines = ["| " + headerCells.joined(separator: " | ") + " |"]
            tableLines.append("|" + Array(repeating: String(repeating: "-", count: cellWidth + 2), count: colCount).joined(separator: "|") + "|")
            for _ in 0..<max(1, rowCount - 1) {
                tableLines.append("| " + Array(repeating: String(repeating: " ", count: cellWidth), count: colCount).joined(separator: " | ") + " |")
            }
            insertTableLines(tableLines, at: origLine, column: origCol)
        } else {
            let chars = style.tableCharacters
            let h = String(repeating: chars.horizontal, count: cellWidth)
            let content = String(repeating: " ", count: cellWidth)
            var tableLines: [String] = []
            tableLines.append(chars.topLeft + Array(repeating: h, count: colCount).joined(separator: chars.topJoin) + chars.topRight)
            for row in 0..<rowCount {
                tableLines.append(chars.vertical + Array(repeating: content, count: colCount).joined(separator: chars.vertical) + chars.vertical)
                if row < rowCount - 1 {
                    tableLines.append(chars.midLeft + Array(repeating: h, count: colCount).joined(separator: chars.midJoin) + chars.midRight)
                }
            }
            tableLines.append(chars.bottomLeft + Array(repeating: h, count: colCount).joined(separator: chars.bottomJoin) + chars.bottomRight)
            insertTableLines(tableLines, at: origLine, column: origCol)
        }

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
                    minLine: origLine, maxLine: min(buffer.lines.count - 1, origLine + 3), minCol: origCol, maxCol: origCol + cellWidth,
                    style: style)
                enterTableMode(with: cell)
            }
        } else {
            setStatusMessage("[ Table created ]")
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

    /// Navigates to next table cell to the right or next row (Tab).
    public func navigateNextTableCell() {
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

    private func findNextCellToRight(
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

    private func navigateRightAdjacentTableCell() {
        guard let cell = currentTableCell else { return }
        let detector = TableCellDetector()
        guard let rightCell = detector.detectCell(in: buffer.lines, line: buffer.lineIndex, col: cell.maxCol + 1),
              rightCell.minLine == cell.minLine,
              rightCell.maxLine == cell.maxLine,
              rightCell.minCol == cell.maxCol
        else { return }

        enterTableMode(with: rightCell)
    }

    private func navigateLeftAdjacentTableCell() {
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
    public func getVisualColumn(in line: String, col: Int) -> Int {
        line.visualColumn(forCharacterOffset: col)
    }

    /// Returns Character array index in line string corresponding to target visual display column width.
    public func getCharIndexForVisualColumn(in line: String, targetVisualCol: Int) -> Int {
        line.characterOffset(forVisualColumn: targetVisualCol)
    }

    /// Navigates to table cell above (Up Arrow at top row of cell).
    public func navigateUpTableCell() {
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
    public func navigateDownTableCell() {
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
    public func navigatePrevTableCell() {
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

    /// Centers text inside each line of the current table cell.
    public func centerCellText() {
        guard let cell = currentTableCell else { return }
        saveUndoSnapshot()

        for lineIdx in cell.innerMinLine...cell.innerMaxLine {
            guard lineIdx < buffer.lines.count else { continue }
            let fullLine = buffer.lines[lineIdx]
            let lineChars = Array(fullLine)

            let (leftBorder, rightBorder) = findCellHorizontalBorders(in: fullLine, nearCol: cell.innerMinCol, cell: cell)
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
        setStatusMessage("[ Cell Text Centered (^J) ]")
    }

    public func moveToNextTableCellLineOrCell() {
        guard let cell = currentTableCell else { return }
        if buffer.lineIndex < cell.innerMaxLine {
            buffer.lineIndex += 1
            let line = buffer.lines[buffer.lineIndex]
            let (leftBorder, _) = findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
            buffer.columnIndex = leftBorder + 1
        } else {
            navigateNextTableCell()
        }
        clampTableModeCursor()
    }

    public func joinCurrentTableCellLine(separator: String) {
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
        let (_, rightBorder) = findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
        buffer.columnIndex = max(cell.innerMinCol, rightBorder - 1)
        buffer.isModified = true
        clampTableModeCursor()
    }

    /// Deletes the current visual row inside the active cell without removing the buffer line or table borders.
    public func deleteCurrentTableCellLine() {
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
            let (leftBorder, _) = findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
            buffer.columnIndex = leftBorder + 1
        }
        buffer.isModified = true
        clampTableModeCursor()
    }

    private func tableCellInnerText(on lineIdx: Int, cell: TableCell) -> String? {
        guard lineIdx >= 0 && lineIdx < buffer.lines.count else { return nil }

        let fullLine = buffer.lines[lineIdx]
        let lineChars = Array(fullLine)
        let (leftBorder, rightBorder) = findCellHorizontalBorders(in: fullLine, nearCol: cell.innerMinCol, cell: cell)
        let innerMinCol = leftBorder + 1
        let innerMaxCol = rightBorder - 1

        guard innerMinCol <= innerMaxCol, innerMaxCol < lineChars.count else { return "" }
        return String(lineChars[innerMinCol...innerMaxCol])
    }

    private func replaceTableCellInnerText(on lineIdx: Int, cell: TableCell, with text: String) {
        guard lineIdx >= 0 && lineIdx < buffer.lines.count else { return }

        let fullLine = buffer.lines[lineIdx]
        let lineChars = Array(fullLine)
        let (leftBorder, rightBorder) = findCellHorizontalBorders(in: fullLine, nearCol: cell.innerMinCol, cell: cell)
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
        let (leftBorder, rightBorder) = findCellHorizontalBorders(in: fullLine, nearCol: cell.innerMinCol, cell: cell)
        let innerMinCol = leftBorder + 1
        let innerMaxCol = rightBorder - 1
        guard innerMinCol <= innerMaxCol, innerMaxCol < lineChars.count else { return 0 }
        return lineChars[innerMinCol...innerMaxCol].reduce(0) { $0 + $1.displayWidth }
    }
}

private extension String {
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
