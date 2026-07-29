import Foundation
import TextMetrics

extension Editor {
    /// Intercepts and processes keyboard events when Table Mode is active.
    /// - Returns: `true` if key event was handled in Table Mode.
    func processTableModeKey(_ key: Key) -> Bool {
        guard isTableModeActive, let cell = currentTableCell else { return false }

        switch key {
        case .alt("t"), .alt("T"):
            toggleTableMode()
            return true

        case .tab:
            navigateNextTableCell()
            return true

        case .shiftArrowLeft:
            navigatePrevTableCell()
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
                navigatePrevTableCell()
            } else {
                buffer.columnIndex -= 1
            }
            clampTableModeCursor()
            return true

        case .arrowRight:
            if buffer.columnIndex == cell.innerMaxCol {
                navigateNextTableCell()
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
            if buffer.lineIndex < cell.innerMaxLine {
                buffer.lineIndex += 1
                buffer.columnIndex = cell.innerMinCol
            } else {
                navigateNextTableCell()
            }
            clampTableModeCursor()
            return true

        case .backspace:
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

        case .delete:
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
            let line = buffer.lines[buffer.lineIndex]
            let (leftBorder, rightBorder) = findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
            let innerMinCol = leftBorder + 1
            let innerMaxCol = rightBorder - 1

            let targetCol = max(innerMinCol, min(buffer.columnIndex, rightBorder))
            let dw = ch.displayWidth
            var lineChars = Array(line)

            // Check if cell has enough trailing spaces (each space is display width 1) to absorb `dw` columns
            var spaceIndices: [Int] = []
            for idx in stride(from: innerMaxCol, through: innerMinCol, by: -1) {
                if idx < lineChars.count && lineChars[idx] == " " {
                    spaceIndices.append(idx)
                    if spaceIndices.count == dw { break }
                }
            }

            // If not enough trailing spaces, BLOCK TYPING!
            guard spaceIndices.count == dw else {
                clampTableModeCursor()
                return true
            }

            saveUndoSnapshot()
            var insertIdx = min(targetCol, lineChars.count)
            for spaceIdx in spaceIndices.sorted(by: >) {
                if spaceIdx < lineChars.count {
                    lineChars.remove(at: spaceIdx)
                    if spaceIdx < insertIdx {
                        insertIdx = max(innerMinCol, insertIdx - 1)
                    }
                }
            }
            lineChars.insert(ch, at: insertIdx)
            buffer.lines[buffer.lineIndex] = String(lineChars)
            buffer.columnIndex = insertIdx + 1

            let (_, newRight) = findCellHorizontalBorders(in: buffer.lines[buffer.lineIndex], nearCol: buffer.columnIndex, cell: cell)
            if buffer.columnIndex >= newRight && buffer.lineIndex < cell.innerMaxLine {
                buffer.lineIndex += 1
                let (nextLineLeft, _) = findCellHorizontalBorders(in: buffer.lines[buffer.lineIndex], nearCol: 0, cell: cell)
                buffer.columnIndex = nextLineLeft + 1
            }

            clampTableModeCursor()
            return true

        default:
            return false
        }
    }

    // MARK: - Table Mode Methods

    /// Toggles Table Mode on/off.
    public func toggleTableMode() {
        if isTableModeActive {
            isTableModeActive = false
            currentTableCell = nil
            setStatusMessage("[ Table Mode Exited ]")
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
                buffer.lineIndex += 1
                let (nextLineLeft, _) = findCellHorizontalBorders(in: buffer.lines[buffer.lineIndex], nearCol: 0, cell: cell)
                buffer.columnIndex = nextLineLeft + 1
                continue
            }

            if buffer.lineIndex < cell.innerMinLine || buffer.lineIndex > cell.innerMaxLine {
                break
            }

            let (_, rightBorder) = findCellHorizontalBorders(in: buffer.lines[buffer.lineIndex], nearCol: buffer.columnIndex, cell: cell)
            if buffer.columnIndex >= rightBorder {
                guard buffer.lineIndex < cell.innerMaxLine else { break }
                buffer.lineIndex += 1
                let (nextLineLeft, _) = findCellHorizontalBorders(in: buffer.lines[buffer.lineIndex], nearCol: 0, cell: cell)
                buffer.columnIndex = nextLineLeft + 1
            }

            guard insertCharacterInCurrentTableCell(ch, cell: cell) else { break }
        }

        clampTableModeCursor()
    }

    private func insertCharacterInCurrentTableCell(_ ch: Character, cell: TableCell) -> Bool {
        guard buffer.lineIndex >= cell.innerMinLine && buffer.lineIndex <= cell.innerMaxLine else { return false }
        guard buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count else { return false }
        let line = buffer.lines[buffer.lineIndex]
        let (leftBorder, rightBorder) = findCellHorizontalBorders(in: line, nearCol: buffer.columnIndex, cell: cell)
        let innerMinCol = leftBorder + 1
        let innerMaxCol = rightBorder - 1

        guard buffer.columnIndex >= innerMinCol && buffer.columnIndex <= rightBorder else { return false }

        let targetCol = max(innerMinCol, min(buffer.columnIndex, rightBorder))
        let dw = ch.displayWidth
        var lineChars = Array(line)

        var spaceIndices: [Int] = []
        for idx in stride(from: innerMaxCol, through: innerMinCol, by: -1) {
            if idx < lineChars.count && lineChars[idx] == " " {
                spaceIndices.append(idx)
                if spaceIndices.count == dw { break }
            }
        }

        guard spaceIndices.count == dw else { return false }

        var insertIdx = min(targetCol, lineChars.count)
        for spaceIdx in spaceIndices.sorted(by: >) {
            if spaceIdx < lineChars.count {
                lineChars.remove(at: spaceIdx)
                if spaceIdx < insertIdx {
                    insertIdx = max(innerMinCol, insertIdx - 1)
                }
            }
        }
        lineChars.insert(ch, at: insertIdx)
        buffer.lines[buffer.lineIndex] = String(lineChars)
        buffer.columnIndex = insertIdx + 1
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
        enterMode: Bool = false,
        saveSnapshot: Bool = true
    ) {
        if saveSnapshot {
            saveUndoSnapshot()
        }
        let origLine = buffer.lineIndex
        let origCol = buffer.columnIndex
        let style = defaultTableBorderStyle
        let rowCount = max(1, min(rows, 50))
        let colCount = max(1, min(cols, 20))
        let cellWidth = 16

        if style == .markdown {
            let headerCells = (1...colCount).map { "Header \($0)".padding(toLength: cellWidth, withPad: " ", startingAt: 0) }
            var tableLines = ["| " + headerCells.joined(separator: " | ") + " |"]
            tableLines.append("|" + Array(repeating: String(repeating: "-", count: cellWidth + 2), count: colCount).joined(separator: "|") + "|")
            for _ in 0..<max(1, rowCount - 1) {
                tableLines.append("| " + Array(repeating: String(repeating: " ", count: cellWidth), count: colCount).joined(separator: " | ") + " |")
            }
            insertTableLines(tableLines, at: origLine, column: origCol)
        } else {
            let chars = tableBorderCharacters(for: style)
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
                    minLine: origLine, maxLine: min(buffer.lines.count - 1, origLine + 3), minCol: origCol, maxCol: origCol + 16,
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

    private func tableBorderCharacters(for style: TableBorderStyle) -> (
        topLeft: String, topJoin: String, topRight: String,
        midLeft: String, midJoin: String, midRight: String,
        bottomLeft: String, bottomJoin: String, bottomRight: String,
        horizontal: String, vertical: String
    ) {
        switch style {
        case .double:
            return ("╔", "╦", "╗", "╠", "╬", "╣", "╚", "╩", "╝", "═", "║")
        case .round:
            return ("╭", "┬", "╮", "├", "┼", "┤", "╰", "┴", "╯", "─", "│")
        case .ascii:
            return ("+", "+", "+", "+", "+", "+", "+", "+", "+", "-", "|")
        case .single, .markdown:
            return ("┌", "┬", "┐", "├", "┼", "┤", "└", "┴", "┘", "─", "│")
        }
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

    /// Returns visual display column width for a given character index in a line string.
    public func getVisualColumn(in line: String, col: Int) -> Int {
        let chars = Array(line)
        let limit = max(0, min(col, chars.count))
        var vCol = 0
        for i in 0..<limit {
            vCol += chars[i].displayWidth
        }
        return vCol
    }

    /// Returns Character array index in line string corresponding to target visual display column width.
    public func getCharIndexForVisualColumn(in line: String, targetVisualCol: Int) -> Int {
        let chars = Array(line)
        var curW = 0
        for (idx, ch) in chars.enumerated() {
            let w = ch.displayWidth
            if curW + w > targetVisualCol {
                return idx
            }
            curW += w
        }
        return chars.count
    }

    /// Navigates to table cell above (Up Arrow at top row of cell).
    public func navigateUpTableCell() {
        guard let cell = currentTableCell else { return }
        let currentLineText = buffer.lines[buffer.lineIndex]
        let currentVCol = getVisualColumn(in: currentLineText, col: buffer.columnIndex)
        let detector = TableCellDetector()

        for lineOffset in 1...3 {
            let targetLine = cell.minLine - lineOffset
            guard targetLine >= 0 else { break }
            let lineText = buffer.lines[targetLine]
            let charIdx = getCharIndexForVisualColumn(in: lineText, targetVisualCol: currentVCol)
            let safeCol = max(0, min(charIdx, lineText.count))

            var targetCell: TableCell? = detector.detectCell(in: buffer.lines, line: targetLine, col: safeCol)
            if targetCell == nil && safeCol > 0 {
                targetCell = detector.detectCell(in: buffer.lines, line: targetLine, col: safeCol - 1)
            }
            if targetCell == nil && safeCol + 1 < lineText.count {
                targetCell = detector.detectCell(in: buffer.lines, line: targetLine, col: safeCol + 1)
            }

            if let cellAbove = targetCell {
                enterTableMode(with: cellAbove)
                buffer.lineIndex = cellAbove.innerMaxLine
                let targetLineText = buffer.lines[buffer.lineIndex]
                buffer.columnIndex = getCharIndexForVisualColumn(in: targetLineText, targetVisualCol: currentVCol)
                clampTableModeCursor()
                return
            }
        }
    }

    /// Navigates to table cell below (Down Arrow at bottom row of cell).
    public func navigateDownTableCell() {
        guard let cell = currentTableCell else { return }
        let currentLineText = buffer.lines[buffer.lineIndex]
        let currentVCol = getVisualColumn(in: currentLineText, col: buffer.columnIndex)
        let detector = TableCellDetector()

        for lineOffset in 1...3 {
            let targetLine = cell.maxLine + lineOffset
            guard targetLine < buffer.lines.count else { break }
            let lineText = buffer.lines[targetLine]
            let charIdx = getCharIndexForVisualColumn(in: lineText, targetVisualCol: currentVCol)
            let safeCol = max(0, min(charIdx, lineText.count))

            var targetCell: TableCell? = detector.detectCell(in: buffer.lines, line: targetLine, col: safeCol)
            if targetCell == nil && safeCol > 0 {
                targetCell = detector.detectCell(in: buffer.lines, line: targetLine, col: safeCol - 1)
            }
            if targetCell == nil && safeCol + 1 < lineText.count {
                targetCell = detector.detectCell(in: buffer.lines, line: targetLine, col: safeCol + 1)
            }

            if let cellBelow = targetCell {
                enterTableMode(with: cellBelow)
                buffer.lineIndex = cellBelow.innerMinLine
                let targetLineText = buffer.lines[buffer.lineIndex]
                buffer.columnIndex = getCharIndexForVisualColumn(in: targetLineText, targetVisualCol: currentVCol)
                clampTableModeCursor()
                return
            }
        }
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
}
