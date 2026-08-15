import Foundation
import TextMetrics

/// Reads and edits strings using terminal display columns rather than String indices.
public enum DisplayText {
    public static func character(atVisualColumn column: Int, in line: String) -> Character {
        guard column >= 0 else { return " " }

        var currentColumn = 0
        for character in line {
            if currentColumn == column { return character }
            currentColumn += character.displayWidth
            if currentColumn > column { return " " }
        }
        return " "
    }

    public static func replacingColumns(
        in line: String,
        startCol: Int,
        width: Int,
        with replacement: String
    ) -> String {
        let prefix = prefix(of: line, before: startCol)
        let suffix = suffix(of: line, after: startCol + width)
        let paddedPrefix = prefix + String(repeating: " ", count: max(0, startCol - prefix.displayWidth))
        return paddedPrefix + replacement + suffix
    }

    private static func prefix(of line: String, before targetColumn: Int) -> String {
        var result = ""
        var currentColumn = 0
        for character in line {
            let nextColumn = currentColumn + character.displayWidth
            guard nextColumn <= targetColumn else { break }
            result.append(character)
            currentColumn = nextColumn
        }
        return result
    }

    private static func suffix(of line: String, after targetColumn: Int) -> String {
        var result = ""
        var currentColumn = 0
        for character in line {
            let nextColumn = currentColumn + character.displayWidth
            if currentColumn >= targetColumn {
                result.append(character)
            } else if nextColumn > targetColumn {
                result += String(repeating: " ", count: nextColumn - targetColumn)
            }
            currentColumn = nextColumn
        }
        return result
    }
}
