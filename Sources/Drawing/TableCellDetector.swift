import Foundation
import TextMetrics

/// Represents a detected rectangular cell boundary within a table.
public struct TableCell: Equatable, Codable, Sendable {
    public let minLine: Int
    public let maxLine: Int
    public let minCol: Int
    public let maxCol: Int
    public let style: BorderStyle

    public init(minLine: Int, maxLine: Int, minCol: Int, maxCol: Int, style: BorderStyle = .single) {
        self.minLine = minLine
        self.maxLine = maxLine
        self.minCol = minCol
        self.maxCol = maxCol
        self.style = style
    }

    /// Inner editable text bounds
    public var innerMinLine: Int { minLine + 1 }
    public var innerMaxLine: Int { maxLine - 1 }
    public var innerMinCol: Int { minCol + 1 }
    public var innerMaxCol: Int { maxCol - 1 }

    public func contains(line: Int, col: Int) -> Bool {
        return line >= innerMinLine && line <= innerMaxLine && col >= innerMinCol && col <= innerMaxCol
    }
}

/// Engine to scan 4 directions for box and table cell borders (Unicode, ASCII, Markdown).
public final class TableCellDetector: Sendable {
    public init() {}

    /// Detects enclosing table cell around (line, col) in lines buffer.
    public func detectCell(in lines: [String], line cursorLine: Int, col cursorCol: Int) -> TableCell? {
        guard !lines.isEmpty, cursorLine >= 0, cursorLine < lines.count else { return nil }

        let currentLine = lines[cursorLine]
        let chars = Array(currentLine)

        // Scan Left for vertical border
        var minCol: Int? = nil
        var c = cursorCol - 1
        while c >= 0 {
            if c < chars.count && BorderCharacterSet.verticalBoundaryChars.contains(chars[c]) {
                minCol = c
                break
            }
            c -= 1
        }
        guard let leftCol = minCol else { return nil }

        // Scan Right for vertical border
        var maxCol: Int? = nil
        var cRight = max(0, cursorCol)
        while cRight < chars.count {
            if BorderCharacterSet.verticalBoundaryChars.contains(chars[cRight]) {
                maxCol = cRight
                break
            }
            cRight += 1
        }
        guard let rightCol = maxCol, rightCol > leftCol + 1 else { return nil }

        // A cursor on a vertical border is not inside the cell it appears to
        // enclose. Reject it before scanning for the horizontal bounds.
        if cursorCol == leftCol || cursorCol == rightCol {
            return nil
        }

        let leftVCol = currentLine.visualColumn(forCharacterOffset: leftCol)
        let rightVCol = currentLine.visualColumn(forCharacterOffset: rightCol)

        // The current row can itself be the top or bottom frame. It must not
        // be treated as a cell just because the scan below finds another row.
        if isHorizontalBorderLine(currentLine, leftVCol: leftVCol, rightVCol: rightVCol) {
            return nil
        }

        // Scan Up for horizontal border line
        var minLine: Int? = nil
        var lUp = cursorLine - 1
        while lUp >= 0 {
            let lStr = lines[lUp]
            if isHorizontalBorderLine(lStr, leftVCol: leftVCol, rightVCol: rightVCol) {
                minLine = lUp
                break
            }
            if lUp == cursorLine - 1 && isMarkdownPipeHeader(lStr, leftVCol: leftVCol) {
                // Markdown table header row above
            } else if !hasVerticalBorder(lStr, vCol: leftVCol) {
                break
            }
            lUp -= 1
        }
        if minLine == nil && cursorLine > 0 {
            let prevStr = lines[cursorLine - 1]
            if isHorizontalBorderLine(prevStr, leftVCol: leftVCol, rightVCol: rightVCol) {
                minLine = cursorLine - 1
            } else if isMarkdownPipeHeader(prevStr, leftVCol: leftVCol) {
                minLine = cursorLine - 1
            }
        }
        guard let topLine = minLine else { return nil }

        // Scan Down for horizontal border line
        var maxLine: Int? = nil
        var lDown = cursorLine + 1
        while lDown < lines.count {
            let lStr = lines[lDown]
            if isHorizontalBorderLine(lStr, leftVCol: leftVCol, rightVCol: rightVCol) {
                maxLine = lDown
                break
            }
            if !hasVerticalBorder(lStr, vCol: leftVCol) {
                maxLine = lDown
                break
            }
            lDown += 1
        }
        if maxLine == nil {
            maxLine = lines.count
        }
        guard let bottomLine = maxLine, bottomLine > topLine + 1 else { return nil }

        // The border rows themselves are drawing structure, not editable cell
        // content. This also handles a cursor rendered over a border glyph.
        guard cursorLine > topLine && cursorLine < bottomLine else { return nil }

        let detectedStyle = detectStyle(lines: lines, topLine: topLine, leftVCol: leftVCol)
        return TableCell(minLine: topLine, maxLine: bottomLine, minCol: leftVCol, maxCol: rightVCol, style: detectedStyle)
    }

    private func isHorizontalBorderLine(_ line: String, leftVCol: Int, rightVCol: Int) -> Bool {
        guard !line.isEmpty else { return false }
        let chars = Array(line)
        let leftCharIdx = line.characterOffset(forVisualColumn: leftVCol)
        let rightCharIdx = line.characterOffset(forVisualColumn: rightVCol)

        let checkStart = min(max(0, leftCharIdx + 1), chars.count - 1)
        let checkEnd = min(max(0, rightCharIdx - 1), chars.count - 1)
        if checkStart > checkEnd { return false }

        var countBorder = 0
        for col in checkStart...checkEnd {
            if BorderCharacterSet.horizontalBoundaryChars.contains(chars[col]) {
                countBorder += 1
            }
        }
        return countBorder >= max(1, (checkEnd - checkStart + 1) / 2)
    }

    private func hasVerticalBorder(_ line: String, vCol: Int) -> Bool {
        let charIdx = line.characterOffset(forVisualColumn: vCol)
        let chars = Array(line)
        guard charIdx >= 0 && charIdx < chars.count else { return false }
        guard line.visualColumn(forCharacterOffset: charIdx) == vCol else { return false }
        return BorderCharacterSet.verticalBoundaryChars.contains(chars[charIdx])
    }

    private func isMarkdownPipeHeader(_ line: String, leftVCol: Int) -> Bool {
        let charIdx = line.characterOffset(forVisualColumn: leftVCol)
        let chars = Array(line)
        guard charIdx >= 0 && charIdx < chars.count else { return false }
        return chars[charIdx] == "|"
    }

    private func detectStyle(lines: [String], topLine: Int, leftVCol: Int) -> BorderStyle {
        guard topLine < lines.count else { return .single }
        let line = lines[topLine]
        let chars = Array(line)
        let leftIdx = line.characterOffset(forVisualColumn: leftVCol)
        guard leftIdx < chars.count else { return .single }
        let ch = chars[leftIdx]
        if ch == "┏" || ch == "━" || ch == "┳" || ch == "┃" {
            return .heavy
        } else if ch == "║" || ch == "═" || ch == "╔" || ch == "╦" {
            return .double
        } else if ch == "╭" {
            if chars.contains("═") || chars.contains("╦") {
                return .double
            } else if chars.contains("━") || chars.contains("┳") || chars.contains("┃") {
                return .heavy
            } else {
                return .single
            }
        } else if ch == "+" || ch == "/" || ch == "-" {
            return .ascii
        } else if let dashedStyle = BorderStyle.allCases.first(where: {
            $0.isDashed && chars.contains($0.horizontalLineCharacter)
        }) {
            return dashedStyle
        }
        return .single
    }
}

