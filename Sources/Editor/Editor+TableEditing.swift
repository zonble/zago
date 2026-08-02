import Foundation
import LogoEngine
import TextMetrics

extension Editor {
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

            let (_, rightBorder) = findCellHorizontalBorders(
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
    }

    func moveToNextLineInCurrentTableCell(cell: TableCell) {
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

    func insertCharacterInCurrentTableCell(_ ch: Character, cell: TableCell, saveSnapshot: Bool = false) -> Bool
    {
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
            setStatusMessage(L10n["status.table_created"])
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

            let (leftBorder, rightBorder) = findCellHorizontalBorders(
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
        setStatusMessage(L10n["status.cell_text_centered"])
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
        let (_, rightBorder) = findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
        buffer.columnIndex = max(cell.innerMinCol, rightBorder - 1)
        buffer.isModified = true
        clampTableModeCursor()
    }

    /// Fills every editable row in the active table cell while preserving borders.
    func fillCurrentTableCell(with fillText: String) -> Bool {
        guard isTableModeActive, let cell = currentTableCell else { return false }
        guard cell.innerMinLine <= cell.innerMaxLine else { return false }
        guard !fillText.isEmpty else {
            setStatusMessage(L10n["status.fill_text_required"])
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
            setStatusMessage(L10n["status.filled_cell"])
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
