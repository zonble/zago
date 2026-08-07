import Foundation

extension TextBuffer {
    /// Checks if a buffer character (line, col) is within the current linear selection range.
    public func isCharacterSelected(line: Int, col: Int) -> Bool {
        guard let mark = selectionMark else { return false }
        if isTableModeActive, let cell = currentTableCell {
            let cursor = (line: lineIndex, column: columnIndex)
            let (start, end) = TextBuffer.getOrderedRange(mark1: mark, mark2: cursor)
            guard line >= start.line && line <= end.line else {
                return false
            }
            guard line >= max(cell.innerMinLine, 0) && line <= min(cell.innerMaxLine, lines.count - 1) else {
                return false
            }
            let fullLine = lines[line]
            let (leftBorder, rightBorder) = TableModeController.findCellHorizontalBorders(
                in: fullLine, nearCol: cell.innerMinCol, cell: cell)
            let innerStart = leftBorder + 1
            let innerEnd = rightBorder
            guard col >= innerStart && col < innerEnd else {
                return false
            }
            let rawStart = line == start.line ? start.column : innerStart
            let rawEnd = line == end.line ? end.column : innerEnd
            let segStart = max(innerStart, min(rawStart, innerEnd))
            let segEnd = max(innerStart, min(rawEnd, innerEnd))
            return col >= segStart && col < segEnd
        }

        let (start, end) = TextBuffer.getOrderedRange(mark1: mark, mark2: (line: lineIndex, column: columnIndex))

        if line < start.line || line > end.line { return false }
        if line > start.line && line < end.line { return true }
        if start.line == end.line { return col >= start.column && col < end.column }
        if line == start.line { return col >= start.column }
        if line == end.line { return col < end.column }
        return false
    }

    public func isLineSelected(line: Int) -> Bool {
        guard let mark = selectionMark else { return false }
        let (start, end) = TextBuffer.getOrderedRange(mark1: mark, mark2: (line: lineIndex, column: columnIndex))
        if start.line == end.line {
            return line == start.line && start.column != end.column
        }
        return line >= start.line && line <= end.line
    }
}
