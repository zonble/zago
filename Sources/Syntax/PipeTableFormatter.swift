import Foundation
import TextMetrics

/// Internal helper engine for formatting and navigating pipe-delimited text tables (Markdown GFM, Org-mode, RST Grid, AsciiDoc).
enum PipeTableFormatter {
    enum TableStyle {
        case markdown
        case orgMode
        case restGrid
        case asciiDoc
    }

    enum ColumnAlignment {
        case none
        case left
        case right
        case center
    }

    static func isTableLine(_ line: String, style: TableStyle) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        switch style {
        case .markdown, .orgMode:
            return (trimmed.hasPrefix("|") && trimmed.hasSuffix("|") && trimmed.count >= 2)
        case .asciiDoc:
            return trimmed.hasPrefix("|") || trimmed.hasPrefix("[cols=")
        case .restGrid:
            return (trimmed.hasPrefix("+") || trimmed.hasPrefix("|"))
                && (trimmed.hasSuffix("+") || trimmed.hasSuffix("|"))
        }
    }

    static func isDraftTableLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("|")
    }

    static func parseCells(line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed == "|===" { return [] }
        guard trimmed.hasPrefix("|") || trimmed.hasPrefix("+") else { return [] }

        var str = trimmed
        if str.hasPrefix("|") || str.hasPrefix("+") { str = String(str.dropFirst()) }
        if str.hasSuffix("|") || str.hasSuffix("+") { str = String(str.dropLast()) }

        let components = str.components(separatedBy: CharacterSet(charactersIn: "|+"))
        return components.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    static func findTableRange(in lines: [String], at lineIndex: Int, style: TableStyle) -> Range<Int>? {
        guard lineIndex >= 0 && lineIndex < lines.count else { return nil }

        if style == .asciiDoc {
            return findAsciiDocTableRange(in: lines, at: lineIndex)
        }

        let currentLine = lines[lineIndex]
        let isCurrentValid = isTableLine(currentLine, style: style)
        let isCurrentDraft = isDraftTableLine(currentLine)

        guard isCurrentValid || isCurrentDraft else { return nil }

        if isCurrentDraft && !isCurrentValid {
            if lineIndex > 0 && isTableLine(lines[lineIndex - 1], style: style) {
                var start = lineIndex - 1
                while start > 0 && isTableLine(lines[start - 1], style: style) {
                    start -= 1
                }
                return start..<(lineIndex + 1)
            } else if lineIndex < lines.count - 1 && isTableLine(lines[lineIndex + 1], style: style) {
                var end = lineIndex + 1
                while end < lines.count - 1 && isTableLine(lines[end + 1], style: style) {
                    end += 1
                }
                return lineIndex..<(end + 1)
            }
            return nil
        }

        var start = lineIndex
        while start > 0 && isTableLine(lines[start - 1], style: style) {
            start -= 1
        }

        var end = lineIndex
        while end < lines.count - 1 && isTableLine(lines[end + 1], style: style) {
            end += 1
        }

        return start..<(end + 1)
    }

    private static func findAsciiDocTableRange(in lines: [String], at lineIndex: Int) -> Range<Int>? {
        guard lineIndex >= 0 && lineIndex < lines.count else { return nil }

        var topFence: Int? = nil
        for i in (0...lineIndex).reversed() {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("|===") {
                topFence = i
                if i > 0 && lines[i - 1].trimmingCharacters(in: .whitespaces).hasPrefix("[cols=") {
                    topFence = i - 1
                }
                break
            } else if trimmed.hasPrefix("[cols=") {
                topFence = i
                break
            }
        }
        guard let start = topFence else { return nil }

        var bottomFence: Int? = nil
        let fenceStartLine = lines[start].trimmingCharacters(in: .whitespaces).hasPrefix("[cols=") ? start + 1 : start
        for i in (fenceStartLine + 1)..<lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("|===") {
                bottomFence = i
                break
            }
        }

        guard let end = bottomFence, lineIndex >= start && lineIndex <= end else { return nil }
        return start..<(end + 1)
    }

    static func formatTable(
        in lines: [String],
        at lineIndex: Int,
        cursorColumn: Int,
        style: TableStyle
    ) -> TableFormatResult? {
        guard let range = findTableRange(in: lines, at: lineIndex, style: style) else { return nil }

        let tableLines = Array(lines[range])
        guard !tableLines.isEmpty else { return nil }

        let contentLines = tableLines.filter { $0.trimmingCharacters(in: .whitespaces) != "|===" }
        var rows: [[String]] = contentLines.map { parseCells(line: $0) }
        var maxCols = 0
        for r in rows {
            maxCols = max(maxCols, r.count)
        }
        guard maxCols > 0 else { return nil }

        for i in 0..<rows.count {
            while rows[i].count < maxCols {
                rows[i].append("")
            }
        }

        if rows.count == 1 && (style == .markdown || style == .orgMode) {
            let emptySep = [String](repeating: "---", count: maxCols)
            let emptyData = [String](repeating: "", count: maxCols)
            rows.append(emptySep)
            rows.append(emptyData)
        }

        var alignments = [ColumnAlignment](repeating: .none, count: maxCols)
        if rows.count >= 2 && isSeparatorRow(rows[1], style: style) {
            for (cIdx, cell) in rows[1].enumerated() where cIdx < maxCols {
                let trimmed = cell.trimmingCharacters(in: .whitespaces)
                let hasLeft = trimmed.hasPrefix(":")
                let hasRight = trimmed.hasSuffix(":")
                if hasLeft && hasRight {
                    alignments[cIdx] = .center
                } else if hasLeft {
                    alignments[cIdx] = .left
                } else if hasRight {
                    alignments[cIdx] = .right
                } else {
                    alignments[cIdx] = .none
                }
            }
        }

        var colWidths = [Int](repeating: 3, count: maxCols)
        for row in rows {
            if isSeparatorRow(row, style: style) { continue }
            for (cIdx, cell) in row.enumerated() {
                colWidths[cIdx] = max(colWidths[cIdx], cell.displayWidth)
            }
        }

        var formattedLines: [String] = []
        if style == .asciiDoc { formattedLines.append("|===") }
        if style == .restGrid {
            formattedLines.append(
                buildSeparatorRow(colWidths: colWidths, alignments: alignments, style: style, isHeader: false))
        }

        for (rIdx, row) in rows.enumerated() {
            if isSeparatorRow(row, style: style) {
                let isHeader = (rIdx == 1)
                let containsEq = row.joined().contains("=")
                let sep = buildSeparatorRow(
                    colWidths: colWidths, alignments: alignments, style: style, isHeader: isHeader,
                    containsEquals: containsEq)
                formattedLines.append(sep)
            } else {
                var lineStr = "|"
                for (cIdx, cell) in row.enumerated() {
                    let w = colWidths[cIdx]
                    let align = alignments[cIdx]
                    let formattedCell = formatCell(cell, width: w, alignment: align)
                    lineStr += " \(formattedCell) |"
                }
                formattedLines.append(lineStr)
                if style == .restGrid {
                    let isLast = (rIdx == rows.count - 1)
                    if !isLast && (rIdx + 1 < rows.count) && !isSeparatorRow(rows[rIdx + 1], style: style) {
                        formattedLines.append(
                            buildSeparatorRow(
                                colWidths: colWidths, alignments: alignments, style: style, isHeader: false))
                    }
                }
            }
        }

        if style == .restGrid {
            formattedLines.append(
                buildSeparatorRow(colWidths: colWidths, alignments: alignments, style: style, isHeader: false))
        } else if style == .asciiDoc {
            formattedLines.append("|===")
        }

        let relativeLine = lineIndex - range.lowerBound
        let safeRelativeLine = min(relativeLine, formattedLines.count - 1)
        let newColumn = calculateNewColumn(
            originalLine: lines[lineIndex],
            formattedLine: formattedLines[safeRelativeLine],
            cursorColumn: cursorColumn
        )

        var newBufferLines = lines
        newBufferLines.replaceSubrange(range, with: formattedLines)

        return TableFormatResult(
            updatedLines: newBufferLines,
            startLineIndex: lineIndex,
            newCursorColumn: newColumn
        )
    }

    static func navigateTableCell(
        in lines: [String],
        at lineIndex: Int,
        column: Int,
        forward: Bool,
        style: TableStyle
    ) -> TableNavigationResult? {
        guard let range = findTableRange(in: lines, at: lineIndex, style: style) else { return nil }

        if style == .asciiDoc {
            if forward {
                var target = lineIndex + 1
                while target < range.upperBound {
                    let trimmed = lines[target].trimmingCharacters(in: .whitespaces)
                    if trimmed.hasPrefix("|") && !trimmed.hasPrefix("|===") {
                        let newCol = calculateCellStartColumn(line: lines[target], cellIndex: 0)
                        return TableNavigationResult(newBufferLineIndex: target, newCursorColumn: newCol)
                    }
                    target += 1
                }
                var newBufferLines = lines
                let insertIdx = range.upperBound - 1
                newBufferLines.insert("|", at: insertIdx)
                return TableNavigationResult(
                    newBufferLineIndex: insertIdx, newCursorColumn: 2, updatedLines: newBufferLines)
            } else {
                var target = lineIndex - 1
                while target >= range.lowerBound {
                    let trimmed = lines[target].trimmingCharacters(in: .whitespaces)
                    if trimmed.hasPrefix("|") && !trimmed.hasPrefix("|===") {
                        let newCol = calculateCellStartColumn(line: lines[target], cellIndex: 0)
                        return TableNavigationResult(newBufferLineIndex: target, newCursorColumn: newCol)
                    }
                    target -= 1
                }
                return TableNavigationResult(newBufferLineIndex: lineIndex, newCursorColumn: column)
            }
        }

        let relativeLine = lineIndex - range.lowerBound
        let tableLines = Array(lines[range])
        let contentLines = tableLines.filter { $0.trimmingCharacters(in: .whitespaces) != "|===" }
        var rows: [[String]] = contentLines.map { parseCells(line: $0) }

        var maxCols = 0
        for r in rows {
            maxCols = max(maxCols, r.count)
        }
        guard maxCols > 0 else { return nil }

        for i in 0..<rows.count {
            while rows[i].count < maxCols {
                rows[i].append("")
            }
        }

        let isDraftRow = (relativeLine == rows.count - 1 && !isTableLine(lines[lineIndex], style: style))

        if (rows.count == 1 || (rows.count == 2 && isDraftRow)) && (style == .markdown || style == .orgMode) {
            let headerRow = rows[0]
            let sepRow = [String](repeating: "---", count: maxCols)
            let dataRow = [String](repeating: "", count: maxCols)
            rows = [headerRow, sepRow, dataRow]
        }

        let currentCellIdx = findCellIndex(line: lines[lineIndex], cursorColumn: column, maxCols: maxCols)

        var targetLine = relativeLine
        var targetCell = currentCellIdx

        if isDraftRow {
            if relativeLine <= 1 && rows.count == 3 {
                targetLine = 2
            } else {
                targetLine = relativeLine
            }
            targetCell = 0
        } else if isSeparatorRow(rows[min(relativeLine, rows.count - 1)], style: style) {
            if forward {
                targetLine = relativeLine + 1
                targetCell = 0
                if targetLine < rows.count && isSeparatorRow(rows[targetLine], style: style) {
                    targetLine += 1
                }
            } else {
                targetLine = relativeLine - 1
                targetCell = maxCols - 1
                if targetLine >= 0 && isSeparatorRow(rows[targetLine], style: style) {
                    targetLine -= 1
                }
            }
        } else if forward {
            if currentCellIdx < maxCols - 1 {
                targetCell = currentCellIdx + 1
            } else {
                targetLine = relativeLine + 1
                targetCell = 0
                if targetLine < rows.count && isSeparatorRow(rows[targetLine], style: style) {
                    targetLine += 1
                }
            }
        } else {
            if currentCellIdx > 0 {
                targetCell = currentCellIdx - 1
            } else if relativeLine > 0 {
                targetLine = relativeLine - 1
                if targetLine >= 0 && isSeparatorRow(rows[targetLine], style: style) {
                    targetLine -= 1
                }
                targetCell = maxCols - 1
            }
        }

        if forward && targetLine >= rows.count {
            let newEmptyRow = [String](repeating: "", count: maxCols)
            rows.append(newEmptyRow)
            targetLine = rows.count - 1
            targetCell = 0
        }

        var colWidths = [Int](repeating: 3, count: maxCols)
        for row in rows {
            if isSeparatorRow(row, style: style) { continue }
            for (cIdx, cell) in row.enumerated() {
                colWidths[cIdx] = max(colWidths[cIdx], cell.displayWidth)
            }
        }

        var alignments = [ColumnAlignment](repeating: .none, count: maxCols)
        if rows.count >= 2 && isSeparatorRow(rows[1], style: style) {
            for (cIdx, cell) in rows[1].enumerated() where cIdx < maxCols {
                let trimmed = cell.trimmingCharacters(in: .whitespaces)
                let hasLeft = trimmed.hasPrefix(":")
                let hasRight = trimmed.hasSuffix(":")
                if hasLeft && hasRight {
                    alignments[cIdx] = .center
                } else if hasLeft {
                    alignments[cIdx] = .left
                } else if hasRight {
                    alignments[cIdx] = .right
                } else {
                    alignments[cIdx] = .none
                }
            }
        }

        var formattedLines: [String] = []
        if style == .asciiDoc { formattedLines.append("|===") }
        for (rIdx, row) in rows.enumerated() {
            if isSeparatorRow(row, style: style) {
                let containsEq = row.joined().contains("=")
                formattedLines.append(
                    buildSeparatorRow(
                        colWidths: colWidths, alignments: alignments, style: style, isHeader: (rIdx == 1),
                        containsEquals: containsEq))
            } else {
                var lineStr = "|"
                for (cIdx, cell) in row.enumerated() {
                    let w = colWidths[cIdx]
                    let align = alignments[cIdx]
                    let formattedCell = formatCell(cell, width: w, alignment: align)
                    lineStr += " \(formattedCell) |"
                }
                formattedLines.append(lineStr)
            }
        }
        if style == .asciiDoc { formattedLines.append("|===") }

        var newBufferLines = lines
        newBufferLines.replaceSubrange(range, with: formattedLines)

        let safeTargetLine = min(max(targetLine, 0), formattedLines.count - 1)
        let absLineIndex = range.lowerBound + safeTargetLine
        let targetFormattedLine = formattedLines[safeTargetLine]
        let newCol = calculateCellStartColumn(line: targetFormattedLine, cellIndex: targetCell)

        return TableNavigationResult(
            newBufferLineIndex: absLineIndex,
            newCursorColumn: newCol,
            updatedLines: newBufferLines
        )
    }

    private static func formatCell(_ cell: String, width: Int, alignment: ColumnAlignment) -> String {
        let textVisLen = cell.displayWidth
        if textVisLen >= width { return cell }
        let diff = width - textVisLen

        switch alignment {
        case .none, .left:
            return cell + String(repeating: " ", count: diff)
        case .right:
            return String(repeating: " ", count: diff) + cell
        case .center:
            let leftPad = diff / 2
            let rightPad = diff - leftPad
            return String(repeating: " ", count: leftPad) + cell + String(repeating: " ", count: rightPad)
        }
    }

    private static func isSeparatorRow(_ row: [String], style: TableStyle) -> Bool {
        guard !row.isEmpty else { return false }
        let joined = row.joined().trimmingCharacters(in: .whitespaces)
        guard !joined.isEmpty else { return false }
        guard joined.contains("-") || joined.contains("=") else { return false }

        switch style {
        case .markdown:
            return joined.allSatisfy { $0 == "-" || $0 == ":" || $0 == " " }
        case .orgMode, .restGrid:
            return joined.allSatisfy { $0 == "-" || $0 == "+" || $0 == "=" || $0 == " " }
        case .asciiDoc:
            return false
        }
    }

    private static func buildSeparatorRow(
        colWidths: [Int],
        alignments: [ColumnAlignment],
        style: TableStyle,
        isHeader: Bool = false,
        containsEquals: Bool = false
    ) -> String {
        switch style {
        case .markdown:
            var res = "|"
            for (cIdx, w) in colWidths.enumerated() {
                let align = alignments[cIdx]
                let targetWidth = max(3, w)
                let cellStr: String
                switch align {
                case .none:
                    cellStr = String(repeating: "-", count: targetWidth)
                case .left:
                    cellStr = ":" + String(repeating: "-", count: max(2, targetWidth - 1))
                case .right:
                    cellStr = String(repeating: "-", count: max(2, targetWidth - 1)) + ":"
                case .center:
                    cellStr = ":" + String(repeating: "-", count: max(1, targetWidth - 2)) + ":"
                }
                res += " \(cellStr) |"
            }
            return res
        case .orgMode:
            var res = "|"
            for (idx, w) in colWidths.enumerated() {
                let dashes = String(repeating: "-", count: max(3, w + 2))
                res += dashes + (idx == colWidths.count - 1 ? "|" : "+")
            }
            return res
        case .restGrid:
            var res = "+"
            let borderChar: Character = (isHeader || containsEquals) ? "=" : "-"
            for w in colWidths {
                res += String(repeating: borderChar, count: max(3, w + 2)) + "+"
            }
            return res
        case .asciiDoc:
            return "|==="
        }
    }

    private static func findCellIndex(line: String, cursorColumn: Int, maxCols: Int) -> Int {
        var pipes: [Int] = []
        for (idx, ch) in line.enumerated() {
            if ch == "|" || ch == "+" {
                pipes.append(idx)
            }
        }
        guard pipes.count >= 2 else { return 0 }

        for cIdx in 0..<(pipes.count - 1) {
            let leftPipe = pipes[cIdx]
            let rightPipe = pipes[cIdx + 1]
            if cursorColumn >= leftPipe && cursorColumn <= rightPipe {
                return min(cIdx, maxCols - 1)
            }
        }
        return min(pipes.count - 2, maxCols - 1)
    }

    private static func calculateCellStartColumn(line: String, cellIndex: Int) -> Int {
        var pipes: [Int] = []
        for (idx, ch) in line.enumerated() {
            if ch == "|" || ch == "+" {
                pipes.append(idx)
            }
        }
        guard cellIndex < pipes.count else { return 0 }
        let pipePos = pipes[cellIndex]
        return min(pipePos + 2, line.count)
    }

    private static func calculateNewColumn(originalLine: String, formattedLine: String, cursorColumn: Int) -> Int {
        var origPipes: [Int] = []
        for (idx, ch) in originalLine.enumerated() {
            if ch == "|" || ch == "+" { origPipes.append(idx) }
        }
        var newPipes: [Int] = []
        for (idx, ch) in formattedLine.enumerated() {
            if ch == "|" || ch == "+" { newPipes.append(idx) }
        }

        guard origPipes.count >= 2 && newPipes.count >= 2 else {
            return min(cursorColumn, formattedLine.count)
        }

        var targetCell = 0
        for cIdx in 0..<(origPipes.count - 1) {
            if cursorColumn >= origPipes[cIdx] && cursorColumn <= origPipes[cIdx + 1] {
                targetCell = cIdx
                break
            }
            if cursorColumn > origPipes[cIdx + 1] {
                targetCell = cIdx + 1
            }
        }

        let cellIdx = min(targetCell, newPipes.count - 2)
        let origCellStart = origPipes[cellIdx] + 2
        let newCellStart = newPipes[cellIdx] + 2
        let cellOffset = max(0, cursorColumn - origCellStart)

        let rightPipe = newPipes[min(cellIdx + 1, newPipes.count - 1)]
        let maxPos = max(newCellStart, rightPipe - 1)

        return min(newCellStart + cellOffset, maxPos)
    }
}
