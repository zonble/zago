import Foundation

/// Border style configuration for table detection and generation.
public enum TableBorderStyle: String, CaseIterable, Sendable {
    case single = "single"  // ┌ ─ ┐ │ └ ┘ ├ ┤ ┬ ┴ ┼
    case double = "double"  // ╔ ═ ╗ ║ ╚ ╝ ╠ ╣ ╦ ╩ ╬
    case ascii = "ascii"  // + - |
    case markdown = "markdown"  // | --- |
}

/// Represents a detected rectangular cell boundary within a table.
public struct TableCell: Equatable, Sendable {
    public let minLine: Int
    public let maxLine: Int
    public let minCol: Int
    public let maxCol: Int
    public let style: TableBorderStyle

    public init(minLine: Int, maxLine: Int, minCol: Int, maxCol: Int, style: TableBorderStyle = .single) {
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
public final class TableCellDetector {
    public init() {}

    private static let verticalBorderChars: Set<Character> = [
        "│", "┌", "┐", "└", "┘", "├", "┤", "┬", "┴", "┼",
        "║", "╔", "╗", "╚", "╝", "╠", "╣", "╦", "╩", "╬",
        "|", "+",
    ]

    private static let horizontalBorderChars: Set<Character> = [
        "─", "═", "-", "+", "┌", "┐", "└", "┘", "├", "┤", "┬", "┴", "┼",
        "╔", "╗", "╚", "╝", "╠", "╣", "╦", "╩", "╬",
    ]

    /// Detects enclosing table cell around (line, col) in lines buffer.
    public func detectCell(in lines: [String], line cursorLine: Int, col cursorCol: Int) -> TableCell? {
        guard !lines.isEmpty, cursorLine >= 0, cursorLine < lines.count else { return nil }

        let currentLine = lines[cursorLine]
        let chars = Array(currentLine)

        // Scan Left for vertical border
        var minCol: Int? = nil
        var c = cursorCol - 1
        while c >= 0 {
            if c < chars.count && Self.verticalBorderChars.contains(chars[c]) {
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
            if Self.verticalBorderChars.contains(chars[cRight]) {
                maxCol = cRight
                break
            }
            cRight += 1
        }
        guard let rightCol = maxCol, rightCol > leftCol + 1 else { return nil }

        // Scan Up for horizontal border line
        var minLine: Int? = nil
        var lUp = cursorLine - 1
        while lUp >= 0 {
            let lChars = Array(lines[lUp])
            if isHorizontalBorderLine(lChars, leftCol: leftCol, rightCol: rightCol) {
                minLine = lUp
                break
            }
            if lUp == cursorLine - 1 && leftCol < lChars.count && lChars[leftCol] == "|" {
                // Markdown table header row above
            } else if !hasVerticalBorder(lChars, col: leftCol) {
                break
            }
            lUp -= 1
        }
        if minLine == nil && cursorLine > 0 {
            let prevChars = Array(lines[cursorLine - 1])
            if isHorizontalBorderLine(prevChars, leftCol: leftCol, rightCol: rightCol) {
                minLine = cursorLine - 1
            } else if leftCol < prevChars.count && prevChars[leftCol] == "|" {
                minLine = cursorLine - 1
            }
        }
        guard let topLine = minLine else { return nil }

        // Scan Down for horizontal border line
        var maxLine: Int? = nil
        var lDown = cursorLine + 1
        while lDown < lines.count {
            let lChars = Array(lines[lDown])
            if isHorizontalBorderLine(lChars, leftCol: leftCol, rightCol: rightCol) {
                maxLine = lDown
                break
            }
            if !hasVerticalBorder(lChars, col: leftCol) {
                maxLine = lDown
                break
            }
            lDown += 1
        }
        if maxLine == nil {
            maxLine = lines.count
        }
        guard let bottomLine = maxLine, bottomLine > topLine + 1 else { return nil }

        let detectedStyle = detectStyle(lines: lines, topLine: topLine, leftCol: leftCol)
        return TableCell(minLine: topLine, maxLine: bottomLine, minCol: leftCol, maxCol: rightCol, style: detectedStyle)
    }

    private func isHorizontalBorderLine(_ chars: [Character], leftCol: Int, rightCol: Int) -> Bool {
        guard !chars.isEmpty else { return false }
        let checkStart = min(max(0, leftCol + 1), chars.count - 1)
        let checkEnd = min(max(0, rightCol - 1), chars.count - 1)
        if checkStart > checkEnd { return false }

        var countBorder = 0
        for col in checkStart...checkEnd {
            if Self.horizontalBorderChars.contains(chars[col]) {
                countBorder += 1
            }
        }
        return countBorder >= max(1, (checkEnd - checkStart + 1) / 2)
    }

    private func hasVerticalBorder(_ chars: [Character], col: Int) -> Bool {
        guard col >= 0 && col < chars.count else { return false }
        return Self.verticalBorderChars.contains(chars[col])
    }

    private func detectStyle(lines: [String], topLine: Int, leftCol: Int) -> TableBorderStyle {
        guard topLine < lines.count else { return .single }
        let chars = Array(lines[topLine])
        guard leftCol < chars.count else { return .single }
        let ch = chars[leftCol]
        if ch == "║" || ch == "═" || ch == "╔" || ch == "╦" {
            return .double
        } else if ch == "+" {
            return .ascii
        } else if ch == "|" {
            return .markdown
        }
        return .single
    }
}
