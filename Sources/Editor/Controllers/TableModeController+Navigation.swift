import Foundation
import LogoEngine
import TextMetrics

// MARK: - Table Controller Navigation & Selection Extensions

extension TableModeController {
    public func extendTableSelectionLeft(cell: TableCell) {
        guard let editor else { return }
        if editor.buffer.selectionMark == nil {
            editor.buffer.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            editor.setStatusMessage(editor.l10n["status.mark_set"])
        }

        let line = editor.buffer.lines[editor.buffer.lineIndex]
        let (leftBorder, _) = TableModeController.findCellHorizontalBorders(in: line, nearCol: editor.buffer.columnIndex, cell: cell)
        let innerMinCol = leftBorder + 1
        if editor.buffer.columnIndex > innerMinCol {
            editor.buffer.columnIndex -= 1
        } else if editor.buffer.lineIndex > cell.innerMinLine {
            editor.buffer.lineIndex -= 1
            let previousLine = editor.buffer.lines[editor.buffer.lineIndex]
            let (previousLeft, previousRight) = TableModeController.findCellHorizontalBorders(
                in: previousLine, nearCol: cell.innerMinCol, cell: cell)
            editor.buffer.columnIndex = max(previousLeft + 1, previousRight - 1)
        }
        clampTableModeCursor()
    }

    public func extendTableSelectionRight(cell: TableCell) {
        guard let editor else { return }
        if editor.buffer.selectionMark == nil {
            editor.buffer.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
            editor.setStatusMessage(editor.l10n["status.mark_set"])
        }

        let line = editor.buffer.lines[editor.buffer.lineIndex]
        let (_, rightBorder) = TableModeController.findCellHorizontalBorders(in: line, nearCol: editor.buffer.columnIndex, cell: cell)
        if editor.buffer.columnIndex < rightBorder {
            editor.buffer.columnIndex += 1
        } else if editor.buffer.lineIndex < cell.innerMaxLine {
            editor.buffer.lineIndex += 1
            let nextLine = editor.buffer.lines[editor.buffer.lineIndex]
            let (nextLeft, _) = TableModeController.findCellHorizontalBorders(in: nextLine, nearCol: cell.innerMinCol, cell: cell)
            editor.buffer.columnIndex = nextLeft + 1
        }
        clampTableModeCursor()
    }

    private struct TableSelectionSegment {
        let line: Int
        let startCol: Int
        let endCol: Int
    }

    private func tableSelectionSegments(cell: TableCell) -> [TableSelectionSegment] {
        guard let editor, let mark = editor.buffer.selectionMark else { return [] }
        let cursor = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
        let (start, end) = TextBuffer.getOrderedRange(mark1: mark, mark2: cursor)
        guard start.line != end.line || start.column != end.column else { return [] }

        var segments: [TableSelectionSegment] = []
        let startLine = max(cell.innerMinLine, start.line)
        let endLine = min(cell.innerMaxLine, end.line)
        guard startLine <= endLine else { return [] }

        for lineIndex in startLine...endLine {
            guard lineIndex >= 0 && lineIndex < editor.buffer.lines.count else { continue }
            let line = editor.buffer.lines[lineIndex]
            let (leftBorder, rightBorder) = TableModeController.findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
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
        guard let editor else { return "" }
        return segments.map { segment in
            let chars = Array(editor.buffer.lines[segment.line])
            guard segment.startCol < chars.count else { return "" }
            let end = min(segment.endCol, chars.count)
            return String(chars[segment.startCol..<end])
        }.joined(separator: "\n")
    }

    private func clearTableSegments(_ segments: [TableSelectionSegment]) {
        guard let editor else { return }
        for segment in segments {
            guard segment.line >= 0 && segment.line < editor.buffer.lines.count else { continue }
            var chars = Array(editor.buffer.lines[segment.line])
            guard segment.startCol < chars.count else { continue }
            let end = min(segment.endCol, chars.count)
            var replacement: [Character] = []
            for ch in chars[segment.startCol..<end] {
                replacement.append(contentsOf: Array(String(repeating: " ", count: ch.displayWidth)))
            }
            chars.replaceSubrange(segment.startCol..<end, with: replacement)
            editor.buffer.lines[segment.line] = String(chars)
        }
        editor.buffer.isModified = true
    }

    @discardableResult
    public func deleteTableSelectionIfNeeded(cell: TableCell, updateClipboard: Bool) -> Bool {
        guard let editor else { return false }
        let segments = tableSelectionSegments(cell: cell)
        guard !segments.isEmpty else { return false }
        editor.saveUndoSnapshot()
        if updateClipboard {
            editor.clipboardText = selectedTableText(segments: segments)
        }
        clearTableSegments(segments)
        let first = segments[0]
        editor.buffer.lineIndex = first.line
        editor.buffer.columnIndex = first.startCol
        editor.buffer.selectionMark = nil
        clampTableModeCursor()
        editor.setStatusMessage(updateClipboard ? editor.l10n["status.cut_text"] : "[ Deleted selection ]")
        return true
    }

    public func cutTableCellText(cell: TableCell) {
        guard let editor else { return }
        if deleteTableSelectionIfNeeded(cell: cell, updateClipboard: true) {
            return
        }

        let lineIndex = editor.buffer.lineIndex
        guard lineIndex >= 0 && lineIndex < editor.buffer.lines.count else { return }
        let line = editor.buffer.lines[lineIndex]
        let (leftBorder, rightBorder) = TableModeController.findCellHorizontalBorders(in: line, nearCol: editor.buffer.columnIndex, cell: cell)
        let start = leftBorder + 1
        let end = rightBorder
        guard start < end else { return }

        editor.saveUndoSnapshot()
        var chars = Array(line)
        editor.clipboardText = String(chars[start..<min(end, chars.count)])
        let width = chars[start..<min(end, chars.count)].reduce(0) { $0 + $1.displayWidth }
        chars.replaceSubrange(start..<min(end, chars.count), with: Array(String(repeating: " ", count: width)))
        editor.buffer.lines[lineIndex] = String(chars)
        editor.buffer.columnIndex = start
        editor.buffer.isModified = true
        editor.buffer.selectionMark = nil
        clampTableModeCursor()
        editor.setStatusMessage(editor.l10n["status.cut_text"])
    }

    // MARK: - Table Navigation Operations

    /// Finds the left and right vertical border character indices for the current cell on the given line string.
    public static func findCellHorizontalBorders(in line: String, nearCol: Int, cell: TableCell) -> (left: Int, right: Int) {
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
        guard let editor, let cell = editor.currentTableCell else { return }
        editor.buffer.lineIndex = max(cell.innerMinLine, min(editor.buffer.lineIndex, cell.innerMaxLine))
        guard editor.buffer.lineIndex >= 0 && editor.buffer.lineIndex < editor.buffer.lines.count else { return }
        let line = editor.buffer.lines[editor.buffer.lineIndex]
        let (leftBorder, rightBorder) = TableModeController.findCellHorizontalBorders(in: line, nearCol: editor.buffer.columnIndex, cell: cell)
        let innerMinCol = leftBorder + 1
        let maxCol = min(rightBorder, line.count)
        editor.buffer.columnIndex = max(innerMinCol, min(editor.buffer.columnIndex, maxCol))
    }

    /// Navigates to next table cell to the right or next row (Tab).
    public func navigateNextTableCell() {
        guard let editor, let cell = editor.currentTableCell else { return }
        let detector = TableCellDetector()

        if let nextCell = findNextCellToRight(of: cell, on: editor.buffer.lineIndex, detector: detector) {
            enterTableMode(with: nextCell)
            return
        }

        // Scan for first cell in the next row below cell.maxLine
        for lineOffset in 1...3 {
            let targetLine = cell.maxLine + lineOffset
            guard targetLine < editor.buffer.lines.count else { break }
            let chars = Array(editor.buffer.lines[targetLine])
            for col in 0..<chars.count {
                if let nextRowCell = detector.detectCell(in: editor.buffer.lines, line: targetLine, col: col + 1) {
                    enterTableMode(with: nextRowCell)
                    return
                }
            }
        }
    }

    public func findNextCellToRight(
        of cell: TableCell, on targetLine: Int, detector: TableCellDetector
    ) -> TableCell? {
        guard let editor else { return nil }
        guard targetLine >= 0 && targetLine < editor.buffer.lines.count else { return nil }

        let chars = Array(editor.buffer.lines[targetLine])
        guard cell.maxCol + 1 < chars.count else { return nil }

        for col in (cell.maxCol + 1)..<chars.count {
            guard let candidate = detector.detectCell(in: editor.buffer.lines, line: targetLine, col: col) else {
                continue
            }
            if candidate.minCol >= cell.maxCol && candidate.maxCol > cell.maxCol {
                return candidate
            }
        }

        return nil
    }

    public func navigateRightAdjacentTableCell() {
        guard let editor, let cell = editor.currentTableCell else { return }
        let detector = TableCellDetector()
        guard let rightCell = detector.detectCell(in: editor.buffer.lines, line: editor.buffer.lineIndex, col: cell.maxCol + 1),
            rightCell.minLine == cell.minLine,
            rightCell.maxLine == cell.maxLine,
            rightCell.minCol == cell.maxCol
        else { return }

        enterTableMode(with: rightCell)
    }

    public func navigateLeftAdjacentTableCell() {
        guard let editor, let cell = editor.currentTableCell, cell.minCol > 0 else { return }
        let detector = TableCellDetector()
        guard let leftCell = detector.detectCell(in: editor.buffer.lines, line: editor.buffer.lineIndex, col: cell.minCol - 1),
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
        guard let editor, let cell = editor.currentTableCell else { return }
        let currentLineText = editor.buffer.lines[editor.buffer.lineIndex]
        let currentVCol = getVisualColumn(in: currentLineText, col: editor.buffer.columnIndex)
        let detector = TableCellDetector()
        let targetLine = cell.minLine - 1
        guard targetLine >= 0 else { return }
        let lineText = editor.buffer.lines[targetLine]
        let charIdx = getCharIndexForVisualColumn(in: lineText, targetVisualCol: currentVCol)
        let safeCol = max(0, min(charIdx, lineText.count))

        guard let cellAbove = detector.detectCell(in: editor.buffer.lines, line: targetLine, col: safeCol),
            cellAbove.maxLine == cell.minLine,
            cellAbove.minCol < cell.maxCol,
            cellAbove.maxCol > cell.minCol
        else { return }

        enterTableMode(with: cellAbove)
        editor.buffer.lineIndex = cellAbove.innerMaxLine
        let targetLineText = editor.buffer.lines[editor.buffer.lineIndex]
        editor.buffer.columnIndex = getCharIndexForVisualColumn(in: targetLineText, targetVisualCol: currentVCol)
        clampTableModeCursor()
    }

    /// Navigates to table cell below (Down Arrow at bottom row of cell).
    public func navigateDownTableCell() {
        guard let editor, let cell = editor.currentTableCell else { return }
        let currentLineText = editor.buffer.lines[editor.buffer.lineIndex]
        let currentVCol = getVisualColumn(in: currentLineText, col: editor.buffer.columnIndex)
        let detector = TableCellDetector()
        let targetLine = cell.maxLine + 1
        guard targetLine < editor.buffer.lines.count else { return }
        let lineText = editor.buffer.lines[targetLine]
        let charIdx = getCharIndexForVisualColumn(in: lineText, targetVisualCol: currentVCol)
        let safeCol = max(0, min(charIdx, lineText.count))

        guard let cellBelow = detector.detectCell(in: editor.buffer.lines, line: targetLine, col: safeCol),
            cellBelow.minLine == cell.maxLine,
            cellBelow.minCol < cell.maxCol,
            cellBelow.maxCol > cell.minCol
        else { return }

        enterTableMode(with: cellBelow)
        editor.buffer.lineIndex = cellBelow.innerMinLine
        let targetLineText = editor.buffer.lines[editor.buffer.lineIndex]
        editor.buffer.columnIndex = getCharIndexForVisualColumn(in: targetLineText, targetVisualCol: currentVCol)
        clampTableModeCursor()
    }

    /// Navigates to previous table cell to the left or previous row (Shift+Tab).
    public func navigatePrevTableCell() {
        guard let editor, let cell = editor.currentTableCell else { return }
        let prevCol = max(0, cell.minCol - 2)
        let detector = TableCellDetector()
        if let prevCell = detector.detectCell(in: editor.buffer.lines, line: cell.innerMinLine, col: prevCol) {
            enterTableMode(with: prevCell)
            return
        }

        // Scan for last cell in row above
        for lineOffset in 1...3 {
            let targetLine = cell.minLine - lineOffset
            guard targetLine >= 0 else { break }
            let chars = Array(editor.buffer.lines[targetLine])
            for col in stride(from: chars.count - 1, through: 0, by: -1) {
                if let prevRowCell = detector.detectCell(in: editor.buffer.lines, line: targetLine, col: col + 1) {
                    enterTableMode(with: prevRowCell)
                    return
                }
            }
        }
    }

    public func moveToNextTableCellLineOrCell() {
        guard let editor, let cell = editor.currentTableCell else { return }
        if editor.buffer.lineIndex < cell.innerMaxLine {
            editor.buffer.lineIndex += 1
            let line = editor.buffer.lines[editor.buffer.lineIndex]
            let (leftBorder, _) = TableModeController.findCellHorizontalBorders(in: line, nearCol: cell.innerMinCol, cell: cell)
            editor.buffer.columnIndex = leftBorder + 1
        } else {
            navigateNextTableCell()
        }
        clampTableModeCursor()
    }

    public func detectTableLineRange(for cell: TableCell) -> [Int] {
        guard let editor else { return [] }
        var start = cell.minLine
        var end = cell.maxLine
        let lines = editor.buffer.lines
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

    public func isTableBorderLine(_ chars: [Character], colLeft: Int, colRight: Int) -> Bool {
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

    public func isAnyBorderLine(_ line: String, colLeft: Int) -> Bool {
        let chars = Array(line)
        guard colLeft < chars.count else { return false }
        return BorderCharacterSet.verticalBoundaryChars.contains(chars[colLeft])
    }
}
