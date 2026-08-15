import Foundation

public struct BoxRegionBounds: Sendable {
    public let topLine: Int
    public let bottomLine: Int
    public let leftColumn: Int
    public let rightColumn: Int

    public init(topLine: Int, bottomLine: Int, leftColumn: Int, rightColumn: Int) {
        self.topLine = topLine
        self.bottomLine = bottomLine
        self.leftColumn = leftColumn
        self.rightColumn = rightColumn
    }

    public var isUsable: Bool {
        bottomLine > topLine + 1 && rightColumn > leftColumn + 1
    }
}

public enum BoxRegionDetector {
    public static func findBounds(
        in lines: [String],
        startLine: Int,
        startColumn: Int,
        maxColumn: Int = 200
    ) -> BoxRegionBounds? {
        guard startLine >= 0, startColumn >= 0 else { return nil }

        func character(line: Int, column: Int) -> Character {
            guard line >= 0, line < lines.count else { return " " }
            return DisplayText.character(atVisualColumn: column, in: lines[line])
        }

        let topLine = stride(from: startLine, through: 0, by: -1).first {
            BoxBorderCharacters.isTop(character(line: $0, column: startColumn))
        }
        let bottomLine = (startLine..<lines.count).first {
            BoxBorderCharacters.isBottom(character(line: $0, column: startColumn))
        }
        let leftColumn = stride(from: startColumn, through: 0, by: -1).first {
            BoxBorderCharacters.isSide(character(line: startLine, column: $0))
        }
        let rightColumn = (startColumn...maxColumn).first {
            BoxBorderCharacters.isSide(character(line: startLine, column: $0))
        }

        guard let topLine, let bottomLine, let leftColumn, let rightColumn else { return nil }
        return BoxRegionBounds(
            topLine: topLine, bottomLine: bottomLine,
            leftColumn: leftColumn, rightColumn: rightColumn)
    }
}
