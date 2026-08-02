import Foundation
import LogoEngine
import TextMetrics

extension Editor {
    /// Finds the left and right vertical border character indices for the current cell on the given line string.
    public func findCellHorizontalBorders(in line: String, nearCol: Int, cell: TableCell) -> (left: Int, right: Int) {
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
}
