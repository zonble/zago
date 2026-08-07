import Foundation
import LogoEngine
import TextMetrics

// MARK: - Table Controller Operations & Cell Formatting Extensions

extension TableModeController {
    // MARK: - Table Mode Toggle & Enter

    /// Toggles Table Mode on/off.
    public func toggleTableMode() {
        guard let editor else { return }
        if editor.isTableModeActive {
            editor.isTableModeActive = false
            editor.currentTableCell = nil
            editor.overlayMode = .none
            editor.setStatusMessage(editor.l10n["status.table_mode_exited"])
            return
        }

        if let syntax = editor.activeLanguageSyntax, syntax.tableFormatter != nil,
            editor.buffer.lineIndex >= 0 && editor.buffer.lineIndex < editor.buffer.lines.count,
            editor.buffer.lines[editor.buffer.lineIndex].trimmingCharacters(in: CharacterSet.whitespaces).hasPrefix("|")
        {
            editor.setStatusMessage("[ Markdown/Org tables are edited in Text Mode (Tab / ^J) ]")
            return
        }

        let detector = TableCellDetector()
        if let cell = detector.detectCell(
            in: editor.buffer.lines, line: editor.buffer.lineIndex, col: editor.buffer.columnIndex)
        {
            enterTableMode(with: cell)
        } else {
            editor.promptTableDimensions()
        }
    }

    /// Enters Table Mode locked to target cell.
    public func enterTableMode(with cell: TableCell) {
        guard let editor else { return }
        editor.clearActiveMark()
        editor.isTableModeActive = true
        editor.overlayMode = .table
        editor.currentTableCell = cell
        let targetLine = max(cell.innerMinLine, min(editor.buffer.lineIndex, cell.innerMaxLine))
        editor.buffer.lineIndex = targetLine
        guard targetLine >= 0 && targetLine < editor.buffer.lines.count else { return }
        let line = editor.buffer.lines[targetLine]
        let (cellLeft, cellRight) = TableModeController.findCellHorizontalBorders(
            in: line, nearCol: cell.innerMinCol, cell: cell)
        if editor.buffer.columnIndex <= cellLeft || editor.buffer.columnIndex >= cellRight {
            editor.buffer.columnIndex = cellLeft + 1
        }
        clampTableModeCursor()
        editor.setStatusMessage(editor.l10n["status.table_mode_hint"])
    }

    // MARK: - Table Editing Operations

    /// Inserts LOGO output into the active table cell without shifting or overwriting borders.
    public func insertTextInCurrentTableCell(_ text: String) {
        guard let editor else { return }
        guard editor.isTableModeActive, let cell = editor.currentTableCell else {
            editor.buffer.insertString(text)
            return
        }

        for ch in text {
            if ch.isNewline {
                guard editor.buffer.lineIndex < cell.innerMaxLine else { break }
                moveToNextLineInCurrentTableCell(cell: cell)
                continue
            }

            if editor.buffer.lineIndex < cell.innerMinLine || editor.buffer.lineIndex > cell.innerMaxLine {
                break
            }

            let (_, rightBorder) = TableModeController.findCellHorizontalBorders(
                in: editor.buffer.lines[editor.buffer.lineIndex], nearCol: editor.buffer.columnIndex, cell: cell)
            if editor.buffer.columnIndex >= rightBorder {
                guard editor.buffer.lineIndex < cell.innerMaxLine else { break }
                moveToNextLineInCurrentTableCell(cell: cell)
            }

            guard insertCharacterInCurrentTableCell(ch, cell: cell) else { break }
        }

        clampTableModeCursor()
    }

    /// Pastes text into the active table cell without shifting or overwriting borders.
    public func pasteTableCellText(_ text: String) {
        guard let editor, editor.isTableModeActive, let cell = editor.currentTableCell else { return }
        editor.saveUndoSnapshot()
        _ = deleteTableSelectionIfNeeded(cell: cell, updateClipboard: false)
        insertTextInCurrentTableCell(text)
        let line = editor.buffer.lines[editor.buffer.lineIndex]
        let (leftBorder, rightBorder) = TableModeController.findCellHorizontalBorders(
            in: line, nearCol: editor.buffer.columnIndex, cell: cell)
        if editor.buffer.columnIndex >= rightBorder {
            editor.buffer.columnIndex = max(leftBorder + 1, rightBorder - 1)
        }
    }

    public func moveToNextLineInCurrentTableCell(cell: TableCell) {
        guard let editor else { return }
        guard editor.buffer.lineIndex < cell.innerMaxLine else { return }
        editor.buffer.lineIndex += 1
        guard editor.buffer.lineIndex >= 0 && editor.buffer.lineIndex < editor.buffer.lines.count else { return }
        let (nextLineLeft, _) = TableModeController.findCellHorizontalBorders(
            in: editor.buffer.lines[editor.buffer.lineIndex],
            nearCol: cell.innerMinCol,
            cell: cell)
        editor.buffer.columnIndex = nextLineLeft + 1
        clampTableModeCursor()
    }

    public func insertCharacterInCurrentTableCell(_ ch: Character, cell: TableCell, saveSnapshot: Bool = false) -> Bool
    {
        guard let editor else { return false }
        guard editor.buffer.lineIndex >= cell.innerMinLine && editor.buffer.lineIndex <= cell.innerMaxLine else {
            return false
        }
        guard editor.buffer.lineIndex >= 0 && editor.buffer.lineIndex < editor.buffer.lines.count else { return false }
        let line = editor.buffer.lines[editor.buffer.lineIndex]
        let (leftBorder, rightBorder) = TableModeController.findCellHorizontalBorders(
            in: line, nearCol: editor.buffer.columnIndex, cell: cell)
        guard leftBorder >= 0 && rightBorder > leftBorder else { return false }

        let leftVisualCol = line.visualColumn(forCharacterOffset: leftBorder)
        let rightVisualCol = line.visualColumn(forCharacterOffset: rightBorder)
        let innerWidth = max(0, rightVisualCol - leftVisualCol - 1)
        guard innerWidth > 0 else { return false }

        let innerStartVisualCol = leftVisualCol + 1
        let cursorVisualCol = line.visualColumn(forCharacterOffset: editor.buffer.columnIndex)
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
            editor.saveUndoSnapshot()
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
        editor.buffer.lines[editor.buffer.lineIndex] = prefix + innerText + suffix
        editor.buffer.columnIndex = prefix.count + min(insertIdx + 1, innerText.count)
        editor.buffer.isModified = true
        return true
    }

    /// Generates a table at cursor position.
    public func createTable(
        rows: Int = 3,
        cols: Int = 3,
        cellWidth requestedCellWidth: Int? = nil,
        enterMode: Bool = false,
        saveSnapshot: Bool = true
    ) {
        guard let editor else { return }
        if saveSnapshot {
            editor.saveUndoSnapshot()
        }
        let origLine = editor.buffer.lineIndex
        let origCol = editor.buffer.columnIndex
        let style = editor.defaultBorderStyle
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

        editor.buffer.lineIndex = origLine + 1
        editor.buffer.columnIndex = origCol + 1
        editor.buffer.clampCursor()
        editor.buffer.isModified = true

        if enterMode {
            let detector = TableCellDetector()
            if let cell = detector.detectCell(
                in: editor.buffer.lines, line: editor.buffer.lineIndex, col: editor.buffer.columnIndex)
            {
                enterTableMode(with: cell)
            } else {
                let cell = TableCell(
                    minLine: origLine, maxLine: min(editor.buffer.lines.count - 1, origLine + 3), minCol: origCol,
                    maxCol: origCol + cellWidth,
                    style: style)
                enterTableMode(with: cell)
            }
        } else {
            editor.setStatusMessage(editor.l10n["status.table_created"])
        }
    }

    private func insertTableLines(_ tableLines: [String], at startLine: Int, column: Int) {
        guard let editor else { return }
        guard !tableLines.isEmpty else { return }
        while editor.buffer.lines.count <= startLine {
            editor.buffer.lines.append("")
        }

        let currentLine = editor.buffer.lines[startLine]
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

        editor.buffer.lines.replaceSubrange(startLine...startLine, with: insertedLines)
    }

    /// Centers text inside each line of the current table cell.
    public func centerCellText() {
        guard let editor, let cell = editor.currentTableCell else { return }
        editor.saveUndoSnapshot()

        for lineIdx in cell.innerMinLine...cell.innerMaxLine {
            guard lineIdx < editor.buffer.lines.count else { continue }
            let fullLine = editor.buffer.lines[lineIdx]
            let lineChars = Array(fullLine)

            let (leftBorder, rightBorder) = TableModeController.findCellHorizontalBorders(
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

                editor.buffer.lines[lineIdx] = prefix + newCellText + suffix
            }
        }
        editor.setStatusMessage(editor.l10n["status.cell_text_centered"])
    }

    public func joinCurrentTableCellLine(separator: String) {
        guard let editor, editor.isTableModeActive, let cell = editor.currentTableCell else { return }
        clampTableModeCursor()
        guard editor.buffer.lineIndex < cell.innerMaxLine else { return }

        let currentText = tableCellInnerText(on: editor.buffer.lineIndex, cell: cell) ?? ""
        let nextText = tableCellInnerText(on: editor.buffer.lineIndex + 1, cell: cell) ?? ""
        let joinedText = currentText.trimmingTrailingWhitespace() + separator + nextText.trimmingLeadingWhitespace()

        replaceTableCellInnerText(on: editor.buffer.lineIndex, cell: cell, with: joinedText)

        let overflow = joinedText.dropDisplayWidth(tableCellInnerWidth(on: editor.buffer.lineIndex, cell: cell))
        replaceTableCellInnerText(on: editor.buffer.lineIndex + 1, cell: cell, with: overflow)

        let line = editor.buffer.lines[editor.buffer.lineIndex]
        let (_, rightBorder) = TableModeController.findCellHorizontalBorders(
            in: line, nearCol: cell.innerMinCol, cell: cell)
        editor.buffer.columnIndex = max(cell.innerMinCol, rightBorder - 1)
        editor.buffer.isModified = true
        clampTableModeCursor()
    }

    /// Fills every editable row in the active table cell while preserving borders.
    public func fillCurrentTableCell(with fillText: String) -> Bool {
        guard let editor, editor.isTableModeActive, let cell = editor.currentTableCell else { return false }
        guard cell.innerMinLine <= cell.innerMaxLine else { return false }
        guard !fillText.isEmpty else {
            editor.setStatusMessage(editor.l10n["status.fill_text_required"])
            return true
        }

        editor.saveUndoSnapshot()
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
            editor.buffer.isModified = true
            editor.setStatusMessage(editor.l10n["status.filled_cell"])
            clampTableModeCursor()
        }
        return true
    }

    /// Deletes the current visual row inside the active cell without removing the buffer line or table borders.
    public func deleteCurrentTableCellLine() {
        guard let editor else { return }
        guard editor.isTableModeActive, let cell = editor.currentTableCell else {
            editor.buffer.deleteLine()
            return
        }

        clampTableModeCursor()
        let startLine = max(cell.innerMinLine, min(editor.buffer.lineIndex, cell.innerMaxLine))

        for lineIdx in startLine...cell.innerMaxLine {
            let sourceLine = lineIdx < cell.innerMaxLine ? lineIdx + 1 : nil
            let sourceText = sourceLine.flatMap { tableCellInnerText(on: $0, cell: cell) } ?? ""
            replaceTableCellInnerText(on: lineIdx, cell: cell, with: sourceText)
        }

        editor.buffer.lineIndex = startLine
        if editor.buffer.lineIndex < editor.buffer.lines.count {
            let line = editor.buffer.lines[editor.buffer.lineIndex]
            let (leftBorder, _) = TableModeController.findCellHorizontalBorders(
                in: line, nearCol: cell.innerMinCol, cell: cell)
            editor.buffer.columnIndex = leftBorder + 1
        }
        editor.buffer.isModified = true
        clampTableModeCursor()
    }

    private func tableCellInnerText(on lineIdx: Int, cell: TableCell) -> String? {
        guard let editor else { return nil }
        guard lineIdx >= 0 && lineIdx < editor.buffer.lines.count else { return nil }

        let fullLine = editor.buffer.lines[lineIdx]
        let lineChars = Array(fullLine)
        let (leftBorder, rightBorder) = TableModeController.findCellHorizontalBorders(
            in: fullLine, nearCol: cell.innerMinCol, cell: cell)
        let innerMinCol = leftBorder + 1
        let innerMaxCol = rightBorder - 1

        guard innerMinCol <= innerMaxCol, innerMaxCol < lineChars.count else { return "" }
        return String(lineChars[innerMinCol...innerMaxCol])
    }

    private func replaceTableCellInnerText(on lineIdx: Int, cell: TableCell, with text: String) {
        guard let editor else { return }
        guard lineIdx >= 0 && lineIdx < editor.buffer.lines.count else { return }

        let fullLine = editor.buffer.lines[lineIdx]
        let lineChars = Array(fullLine)
        let (leftBorder, rightBorder) = TableModeController.findCellHorizontalBorders(
            in: fullLine, nearCol: cell.innerMinCol, cell: cell)
        let innerMinCol = leftBorder + 1
        let innerMaxCol = rightBorder - 1

        guard innerMinCol <= innerMaxCol, rightBorder < lineChars.count else { return }

        let innerWidth = lineChars[innerMinCol...innerMaxCol].reduce(0) { $0 + $1.displayWidth }
        let newCellText = text.paddedToDisplayWidth(innerWidth)

        let prefix = String(lineChars[0...leftBorder])
        let suffix = String(lineChars[rightBorder..<lineChars.count])
        editor.buffer.lines[lineIdx] = prefix + newCellText + suffix
    }

    private func tableCellInnerWidth(on lineIdx: Int, cell: TableCell) -> Int {
        guard let editor else { return 0 }
        guard lineIdx >= 0 && lineIdx < editor.buffer.lines.count else { return 0 }
        let fullLine = editor.buffer.lines[lineIdx]
        let lineChars = Array(fullLine)
        let (leftBorder, rightBorder) = TableModeController.findCellHorizontalBorders(
            in: fullLine, nearCol: cell.innerMinCol, cell: cell)
        let innerMinCol = leftBorder + 1
        let innerMaxCol = rightBorder - 1
        guard innerMinCol <= innerMaxCol, innerMaxCol < lineChars.count else { return 0 }
        return lineChars[innerMinCol...innerMaxCol].reduce(0) { $0 + $1.displayWidth }
    }

    // MARK: - Table Resize Operations

    /// Resizes the column width of the active table cell (or standalone box) by delta (+1 or -1).
    public func resizeCurrentTableCellWidth(delta: Int) {
        guard let editor, editor.isTableModeActive, let cell = editor.currentTableCell else { return }
        let detector = TableCellDetector()
        let tableLines = detectTableLineRange(for: cell)

        let colLeft = cell.minCol
        let colRight = cell.maxCol
        let currentWidth = colRight - colLeft - 1

        let nextCellToRight = findNextCellToRight(of: cell, on: cell.innerMinLine, detector: detector)
        let isSameGridTable = (nextCellToRight != nil && nextCellToRight!.minCol == colRight)

        if delta < 0 {
            for lineIdx in tableLines {
                let line = editor.buffer.lines[lineIdx]
                let chars = Array(line)
                let (leftB, rightB) = TableModeController.findCellHorizontalBorders(
                    in: line, nearCol: cell.innerMinCol, cell: cell)
                if isTableBorderLine(chars, colLeft: leftB, colRight: rightB) {
                    continue
                }
                if leftB == colLeft && rightB == colRight {
                    if leftB + 1 < rightB {
                        let endIdx = min(rightB, chars.count)
                        let textInside = String(chars[(leftB + 1)..<endIdx]).trimmingTrailingWhitespace()
                        if textInside.displayWidth >= currentWidth {
                            editor.setStatusMessage(editor.l10n["status.cannot_shrink_width"])
                            return
                        }
                    }
                }
            }
            if currentWidth <= 1 {
                editor.setStatusMessage(editor.l10n["status.cannot_shrink_width"])
                return
            }
        } else if delta > 0 {
            for lineIdx in tableLines {
                let line = editor.buffer.lines[lineIdx]
                let chars = Array(line)
                let (leftB, rightB) = TableModeController.findCellHorizontalBorders(
                    in: line, nearCol: cell.innerMinCol, cell: cell)
                if leftB == colLeft && rightB == colRight {
                    let nextIdx = rightB + 1
                    if nextIdx < chars.count && BorderCharacterSet.verticalBoundaryChars.contains(chars[nextIdx]) {
                        if !isSameGridTable {
                            editor.setStatusMessage(editor.l10n["status.cannot_expand_width_collision"])
                            return
                        }
                    }
                }
            }
        }

        for lineIdx in tableLines {
            var chars = Array(editor.buffer.lines[lineIdx])
            if chars.count <= colLeft { continue }

            let (leftB, rightB) = TableModeController.findCellHorizontalBorders(
                in: editor.buffer.lines[lineIdx], nearCol: cell.innerMinCol, cell: cell)
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
            editor.buffer.lines[lineIdx] = String(chars)
        }

        editor.buffer.isModified = true

        if let newCell = detector.detectCell(
            in: editor.buffer.lines, line: editor.buffer.lineIndex, col: editor.buffer.columnIndex)
        {
            editor.currentTableCell = newCell
        }
        clampTableModeCursor()
    }

    /// Resizes the row height of the active table cell (or standalone box) by delta (+1 or -1).
    public func resizeCurrentTableCellHeight(delta: Int) {
        guard let editor, editor.isTableModeActive, let cell = editor.currentTableCell else { return }
        let detector = TableCellDetector()

        let minLine = cell.minLine
        let maxLine = cell.maxLine
        let currentHeight = maxLine - minLine - 1

        if delta < 0 {
            if currentHeight <= 1 {
                editor.setStatusMessage(editor.l10n["status.cannot_shrink_height"])
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
                editor.setStatusMessage(editor.l10n["status.cannot_shrink_height"])
                return
            }

            editor.buffer.lines.remove(at: removeLineIdx)
            if editor.buffer.lineIndex >= removeLineIdx && editor.buffer.lineIndex > minLine + 1 {
                editor.buffer.lineIndex -= 1
            }
        } else if delta > 0 {
            let templateLineIdx = minLine + 1
            let templateLine = (templateLineIdx < editor.buffer.lines.count) ? editor.buffer.lines[templateLineIdx] : ""
            var newLineChars = Array(templateLine)

            for c in 0..<newLineChars.count {
                if !BorderCharacterSet.verticalBoundaryChars.contains(newLineChars[c]) {
                    newLineChars[c] = " "
                }
            }
            let newLineStr = String(newLineChars)
            let insertLineIdx = maxLine
            editor.buffer.lines.insert(newLineStr, at: insertLineIdx)
        }

        editor.buffer.isModified = true

        if let newCell = detector.detectCell(
            in: editor.buffer.lines, line: editor.buffer.lineIndex, col: editor.buffer.columnIndex)
        {
            editor.currentTableCell = newCell
        }
        clampTableModeCursor()
    }

    private func isLineEmptyAcrossRow(_ lineIdx: Int) -> Bool {
        guard let editor else { return false }
        guard lineIdx >= 0 && lineIdx < editor.buffer.lines.count else { return false }
        let line = editor.buffer.lines[lineIdx]
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
