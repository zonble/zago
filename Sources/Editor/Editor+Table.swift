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
                buffer.lineIndex -= 1
            }
            clampTableModeCursor()
            return true

        case .arrowDown:
            if buffer.lineIndex == cell.innerMaxLine {
                navigateDownTableCell()
            } else {
                buffer.lineIndex += 1
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
            if buffer.columnIndex > cell.innerMinCol {
                saveUndoSnapshot()
                var lineChars = Array(buffer.lines[buffer.lineIndex])
                let deleteIdx = buffer.columnIndex - 1
                if deleteIdx >= cell.innerMinCol && deleteIdx < lineChars.count {
                    lineChars.remove(at: deleteIdx)
                    let insertSpaceIdx = min(cell.innerMaxCol, lineChars.count)
                    lineChars.insert(" ", at: insertSpaceIdx)
                    buffer.lines[buffer.lineIndex] = String(lineChars)
                    buffer.columnIndex = max(cell.innerMinCol, deleteIdx)
                }
            }
            clampTableModeCursor()
            return true

        case .delete:
            if buffer.columnIndex <= cell.innerMaxCol {
                saveUndoSnapshot()
                var lineChars = Array(buffer.lines[buffer.lineIndex])
                let deleteIdx = buffer.columnIndex
                if deleteIdx >= cell.innerMinCol && deleteIdx <= cell.innerMaxCol && deleteIdx < lineChars.count {
                    lineChars.remove(at: deleteIdx)
                    let insertSpaceIdx = min(cell.innerMaxCol, lineChars.count)
                    lineChars.insert(" ", at: insertSpaceIdx)
                    buffer.lines[buffer.lineIndex] = String(lineChars)
                }
            }
            clampTableModeCursor()
            return true

        case .char(let ch):
            if buffer.columnIndex <= cell.innerMaxCol {
                let dw = ch.displayWidth
                var lineChars = Array(buffer.lines[buffer.lineIndex])

                // Check if cell has enough trailing spaces to absorb `dw` characters
                var spaceIndices: [Int] = []
                for idx in stride(from: cell.innerMaxCol, through: cell.innerMinCol, by: -1) {
                    if idx < lineChars.count && lineChars[idx] == " " {
                        spaceIndices.append(idx)
                        if spaceIndices.count == dw { break }
                    }
                }

                // If not enough trailing spaces, BLOCK TYPING!
                if spaceIndices.count < dw {
                    return true
                }

                saveUndoSnapshot()
                for spaceIdx in spaceIndices {
                    if spaceIdx < lineChars.count {
                        lineChars.remove(at: spaceIdx)
                    }
                }
                lineChars.insert(ch, at: buffer.columnIndex)
                buffer.lines[buffer.lineIndex] = String(lineChars)
                buffer.columnIndex += 1

                if buffer.columnIndex > cell.innerMaxCol && buffer.lineIndex < cell.innerMaxLine {
                    buffer.lineIndex += 1
                    buffer.columnIndex = cell.innerMinCol
                }
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
        clampTableModeCursor()
        setStatusMessage("[ TABLE MODE ] (Alt+T to exit | Tab to navigate)")
    }

    /// Clamps cursor position to inner bounds of current cell.
    public func clampTableModeCursor() {
        guard let cell = currentTableCell else { return }
        buffer.lineIndex = max(cell.innerMinLine, min(buffer.lineIndex, cell.innerMaxLine))
        let line = buffer.lines[buffer.lineIndex]
        let maxCol = min(cell.innerMaxCol, line.count)
        buffer.columnIndex = max(cell.innerMinCol, min(buffer.columnIndex, maxCol))
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
                buffer.columnIndex = cell.innerMinCol
                continue
            }

            if buffer.lineIndex < cell.innerMinLine || buffer.lineIndex > cell.innerMaxLine {
                break
            }

            if buffer.columnIndex > cell.innerMaxCol {
                guard buffer.lineIndex < cell.innerMaxLine else { break }
                buffer.lineIndex += 1
                buffer.columnIndex = cell.innerMinCol
            }

            guard insertCharacterInCurrentTableCell(ch, cell: cell) else { break }
        }

        clampTableModeCursor()
    }

    private func insertCharacterInCurrentTableCell(_ ch: Character, cell: TableCell) -> Bool {
        guard buffer.lineIndex >= 0 && buffer.lineIndex < buffer.lines.count else { return false }
        guard buffer.columnIndex >= cell.innerMinCol && buffer.columnIndex <= cell.innerMaxCol else { return false }

        let displayWidth = ch.displayWidth
        var lineChars = Array(buffer.lines[buffer.lineIndex])
        guard cell.innerMaxCol < lineChars.count else { return false }

        var spaceIndices: [Int] = []
        for idx in stride(from: cell.innerMaxCol, through: cell.innerMinCol, by: -1) {
            if idx < lineChars.count && lineChars[idx] == " " {
                spaceIndices.append(idx)
                if spaceIndices.count == displayWidth { break }
            }
        }

        guard spaceIndices.count == displayWidth else { return false }

        for spaceIdx in spaceIndices {
            lineChars.remove(at: spaceIdx)
        }
        lineChars.insert(ch, at: buffer.columnIndex)
        buffer.lines[buffer.lineIndex] = String(lineChars)
        buffer.columnIndex += 1
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
        saveUndoSnapshot()
        let origLine = buffer.lineIndex
        let origCol = buffer.columnIndex
        let style = defaultTableBorderStyle

        if style == .markdown {
            let mdLines = [
                "| Header 1       | Header 2       | Header 3       |",
                "| -------------- | -------------- | -------------- |",
                "|                |                |                |",
                "|                |                |                |",
            ]
            for (idx, line) in mdLines.enumerated() {
                if origLine + idx < buffer.lines.count {
                    buffer.lines[origLine + idx] = line
                } else {
                    buffer.lines.append(line)
                }
            }
        } else if style == .ascii {
            let asciiLines = [
                "+----------------+----------------+----------------+",
                "|                |                |                |",
                "+----------------+----------------+----------------+",
                "|                |                |                |",
                "+----------------+----------------+----------------+",
                "|                |                |                |",
                "+----------------+----------------+----------------+",
            ]
            for (idx, line) in asciiLines.enumerated() {
                if origLine + idx < buffer.lines.count {
                    buffer.lines[origLine + idx] = line
                } else {
                    buffer.lines.append(line)
                }
            }
        } else if style == .double {
            let doubleLines = [
                "╔════════════════╦════════════════╦════════════════╗",
                "║                ║                ║                ║",
                "╠════════════════╬════════════════╬════════════════╣",
                "║                ║                ║                ║",
                "╠════════════════╬════════════════╬════════════════╣",
                "║                ║                ║                ║",
                "╚════════════════╩════════════════╩════════════════╝",
            ]
            for (idx, line) in doubleLines.enumerated() {
                if origLine + idx < buffer.lines.count {
                    buffer.lines[origLine + idx] = line
                } else {
                    buffer.lines.append(line)
                }
            }
        } else {
            let singleLines = [
                "┌────────────────┬────────────────┬────────────────┐",
                "│                │                │                │",
                "├────────────────┼────────────────┼────────────────┤",
                "│                │                │                │",
                "├────────────────┼────────────────┼────────────────┤",
                "│                │                │                │",
                "└────────────────┴────────────────┴────────────────┘",
            ]
            for (idx, line) in singleLines.enumerated() {
                if origLine + idx < buffer.lines.count {
                    buffer.lines[origLine + idx] = line
                } else {
                    buffer.lines.append(line)
                }
            }
        }

        buffer.lineIndex = origLine + 1
        buffer.columnIndex = origCol + 1
        buffer.clampCursor()

        let detector = TableCellDetector()
        if let cell = detector.detectCell(in: buffer.lines, line: buffer.lineIndex, col: buffer.columnIndex) {
            enterTableMode(with: cell)
        } else {
            // Fallback cell
            let cell = TableCell(
                minLine: origLine, maxLine: min(buffer.lines.count - 1, origLine + 3), minCol: 0, maxCol: 16,
                style: style)
            enterTableMode(with: cell)
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

    /// Navigates to table cell above (Up Arrow at top row of cell).
    public func navigateUpTableCell() {
        guard let cell = currentTableCell else { return }
        let detector = TableCellDetector()
        let targetCol = buffer.columnIndex
        for lineOffset in 1...3 {
            let targetLine = cell.minLine - lineOffset
            guard targetLine >= 0 else { break }
            if let cellAbove = detector.detectCell(in: buffer.lines, line: targetLine, col: targetCol) {
                enterTableMode(with: cellAbove)
                buffer.lineIndex = cellAbove.innerMaxLine
                clampTableModeCursor()
                return
            }
        }
    }

    /// Navigates to table cell below (Down Arrow at bottom row of cell).
    public func navigateDownTableCell() {
        guard let cell = currentTableCell else { return }
        let detector = TableCellDetector()
        let targetCol = buffer.columnIndex
        for lineOffset in 1...3 {
            let targetLine = cell.maxLine + lineOffset
            guard targetLine < buffer.lines.count else { break }
            if let cellBelow = detector.detectCell(in: buffer.lines, line: targetLine, col: targetCol) {
                enterTableMode(with: cellBelow)
                buffer.lineIndex = cellBelow.innerMinLine
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

            guard cell.innerMinCol <= cell.innerMaxCol && cell.innerMaxCol < lineChars.count else { continue }

            let cellContent = String(lineChars[cell.innerMinCol...cell.innerMaxCol])
            let trimmed = cellContent.trimmingCharacters(in: .whitespaces)

            let innerWidth = cell.innerMaxCol - cell.innerMinCol + 1
            let contentWidth = trimmed.displayWidth

            if contentWidth <= innerWidth {
                let totalPadding = innerWidth - contentWidth
                let leftPadding = totalPadding / 2
                let rightPadding = totalPadding - leftPadding

                let newCellText =
                    String(repeating: " ", count: leftPadding) + trimmed + String(repeating: " ", count: rightPadding)
                let prefix = String(lineChars[0..<cell.innerMinCol])
                let suffix = String(lineChars[(cell.innerMaxCol + 1)..<lineChars.count])

                buffer.lines[lineIdx] = prefix + newCellText + suffix
            }
        }
        setStatusMessage("[ Cell Text Centered (^J) ]")
    }
}
